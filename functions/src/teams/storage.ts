// Per-team storage accounting (ARCH §6.11, D16). Storage rules stop uploads
// once groups.storageBytes reaches storageQuotaBytes (STORE-4). Triggers keep
// the number current as files come and go, and dailyCleanup recomputes it
// from the bucket so any drift (a missed event, a retried trigger) heals.
// After every change, updateStorageAlert tells admins when the team crosses
// 90% or fills up (STORE-3, STORE-4).
import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { HttpsError } from 'firebase-functions/v2/https';
import { trySend } from '../notify/service.js';
import { forEachPage } from '../shared/batch.js';
import { db, storage } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { teamStatus } from './status.js';

export const MB = 1024 * 1024;

/** The team a Storage path belongs to: `groups/{groupId}/...`, or null. */
export function groupIdFromPath(path: string | undefined): string | null {
  const match = /^groups\/([^/]+)\/.+/.exec(path ?? '');
  return match ? match[1] : null;
}

/**
 * Adds [delta] bytes to a team's storage total. Files removed after their
 * team was deleted have no team to update, so a missing team is ignored.
 */
export async function addStorageBytes(groupId: string, delta: number): Promise<void> {
  if (!delta) return;
  await db()
    .collection(Collections.groups)
    .doc(groupId)
    .update({ storageBytes: FieldValue.increment(delta) })
    .catch((e: { code?: number }) => {
      if (e.code !== 5) throw e; // 5 = NOT_FOUND
    });
}

/**
 * The largest upload platform settings allow, in bytes (ADMIN-7
 * maxUploadMb): never over Limits.maxUploadMb (STORE-1), which
 * storage.rules enforce themselves.
 */
export async function maxUploadBytes(): Promise<number> {
  const mb = (await db().collection(Collections.config).doc('app').get()).get('maxUploadMb') as unknown;
  const valid = typeof mb === 'number' && Number.isInteger(mb) && mb >= 1 && mb <= Limits.maxUploadMb;
  return (valid ? mb : Limits.maxUploadMb) * MB;
}

/**
 * Deletes an upload larger than platform settings allow (ADMIN-7). The app
 * checks the limit before uploading; this holds it on the server for any
 * client that doesn't (storage.rules can't read config/app: their two
 * Firestore lookups go to the membership and the team). Only people's
 * uploads are checked: `groups/` and `users/` files. Returns whether the
 * file was deleted; its delete trigger then stops counting it.
 */
export async function enforceUploadLimit(path: string | undefined, size: number): Promise<boolean> {
  if (!path || !(path.startsWith('groups/') || path.startsWith('users/'))) return false;
  const max = await maxUploadBytes();
  if (size <= max) return false;
  await storage().bucket().file(path).delete({ ignoreNotFound: true });
  logger.warn('upload_over_limit', { path, size, max });
  return true;
}

/** Sums every file under `groups/{groupId}/` and stores the total. */
export async function recomputeStorageBytes(groupId: string): Promise<number> {
  const [files] = await storage().bucket().getFiles({ prefix: `groups/${groupId}/` });
  const total = files.reduce((sum, f) => sum + Number(f.metadata.size ?? 0), 0);
  await db()
    .collection(Collections.groups)
    .doc(groupId)
    .update({ storageBytes: total })
    .catch((e: { code?: number }) => {
      if (e.code !== 5) throw e;
    });
  return total;
}

/**
 * Recomputes every team's storage total, a page of teams at a time, and
 * brings each team's warning up to date (ARCH §6.4 dailyCleanup).
 */
export async function reconcileAllStorage(): Promise<number> {
  let teams = 0;
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  for (;;) {
    let page = db().collection(Collections.groups).orderBy('__name__').limit(200);
    if (last) page = page.startAfter(last);
    const snap = await page.get();
    for (const team of snap.docs) {
      const before = (team.get('storageBytes') as number | undefined) ?? 0;
      const after = await recomputeStorageBytes(team.id);
      if (before !== after) logger.warn('storage_drift', { groupId: team.id, before, after });
      // Teams made before groups.status existed get it here (ADMIN-2).
      const status = teamStatus(team.data());
      if (team.get('status') !== status) {
        await team.ref.update({ status }).catch((e: { code?: number }) => {
          if (e.code !== 5) throw e; // 5 = NOT_FOUND
        });
      }
      // One team's failed warning mustn't stop the rest of the recount.
      await updateStorageAlert(team.id).catch((e) =>
        logger.error('storage_alert_failed', { groupId: team.id, error: String(e) }),
      );
      teams++;
    }
    if (snap.size < 200) break;
    last = snap.docs[snap.docs.length - 1];
  }
  return teams;
}

/** Which storage warning a team is at (ARCH §6.2 groups.storageAlert). */
export type StorageAlert = 'none' | 'warn' | 'full';

const ALERT_RANK: Record<StorageAlert, number> = { none: 0, warn: 1, full: 2 };

/**
 * How full a team's storage is: full at the limit (STORE-4), warn from
 * Limits.storageWarnPercent (90%, STORE-3), otherwise none. A limit of zero
 * or less is always full, matching the rules' `storageBytes < storageQuotaBytes`.
 */
export function storageAlertLevel(bytes: number, quotaBytes: number): StorageAlert {
  if (bytes >= quotaBytes) return 'full';
  if (bytes * 100 >= quotaBytes * Limits.storageWarnPercent) return 'warn';
  return 'none';
}

/** The push and center-item wording for a storage warning (STORE-3, STORE-4). */
export function storageAlertBody(level: Exclude<StorageAlert, 'none'>): string {
  return level === 'warn'
    ? `Storage is ${Limits.storageWarnPercent}% full. Free up space in Media.`
    : 'Storage is full. Uploads, attachments, and scheduling new events are disabled until storage is freed up.';
}

/** The built-in default until 2026-10-15: teams still on it follow the default now. */
const LEGACY_DEFAULT_MB = 500;

/**
 * The limit for teams without their own, in MB (STORE-1, ADMIN-7): config/app's
 * defaultStorageQuotaMb in [config], else the built-in default, never over the
 * largest limit.
 */
export function defaultQuotaMbOf(config: FirebaseFirestore.DocumentData | undefined): number {
  const mb = config?.defaultStorageQuotaMb;
  return Math.min(typeof mb === 'number' && mb > 0 ? mb : Limits.defaultStorageQuotaMb, Limits.storageQuotaMaxMb);
}

/** [defaultQuotaMbOf] for the platform settings as they are now. */
export async function defaultQuotaMb(): Promise<number> {
  return defaultQuotaMbOf((await db().collection(Collections.config).doc('app').get()).data());
}

/** A team's limit in bytes; teams written before the limit existed get the default (STORE-1). */
export function quotaBytesOf(data: FirebaseFirestore.DocumentData | undefined): number {
  const quota = data?.storageQuotaBytes;
  return typeof quota === 'number' ? quota : Limits.defaultStorageQuotaMb * MB;
}

/** A team's usage, the level it last recorded, and the level its usage is at now. */
function alertLevels(group: FirebaseFirestore.DocumentSnapshot): {
  bytes: number;
  before: StorageAlert;
  after: StorageAlert;
} {
  const bytes = Number(group.get('storageBytes') ?? 0);
  return {
    bytes,
    before: (group.get('storageAlert') as StorageAlert | undefined) ?? 'none',
    after: storageAlertLevel(bytes, quotaBytesOf(group.data())),
  };
}

/**
 * Records a team's storage warning level and tells its admins when it rises
 * (ARCH §6.11): none → warn at 90%, → full at the limit. A fall lowers the
 * level silently, so the next rise notifies again. The level is compared
 * and written in a transaction, so concurrent or retried triggers notify
 * once per rise. Returns the new level when it changed, else null.
 */
export async function updateStorageAlert(groupId: string): Promise<StorageAlert | null> {
  const ref = db().collection(Collections.groups).doc(groupId);
  // Nearly every file leaves the level where it was. A plain read settles
  // those, so each upload doesn't lock the team's document (busy with chat)
  // in a transaction. Each trigger reads after its own change, so a rise
  // is never missed.
  const peek = await ref.get();
  if (!peek.exists) return null;
  const now = alertLevels(peek);
  if (now.after === now.before) return null;
  const change = await db().runTransaction(async (tx) => {
    const group = await tx.get(ref);
    if (!group.exists) return null;
    const { bytes, before, after } = alertLevels(group);
    if (after === before) return null;
    tx.update(ref, { storageAlert: after });
    return {
      before,
      after,
      bytes,
      teamName: (group.get('name') as string | undefined) ?? '',
      // The version this rise was read from: a retry of the same rise makes
      // the same key, and no two rises share one.
      version: group.updateTime?.toMillis() ?? Date.now(),
    };
  });
  if (!change) return null;
  if (change.after !== 'none' && ALERT_RANK[change.after] > ALERT_RANK[change.before]) {
    await trySend({
      kind: 'storageWarning',
      groupId,
      recipients: { admins: true },
      actor: null,
      target: { type: 'group', id: groupId },
      route: `/g/${groupId}/media`,
      params: { level: change.after },
      body: storageAlertBody(change.after),
      dedupeKey: `storage_${groupId}_${change.after}_${change.bytes}_${change.version}`,
      teamName: change.teamName,
    });
  }
  return change.after;
}

/**
 * Gives one team its own storage limit (STORE-6, super admins), or with a
 * null [quotaMb] puts it back on the default (ADMIN-7). Its own limit is
 * marked (storageQuotaCustom), so a change to the default leaves it alone.
 * Returns the limit before and after, in bytes, for the audit log; the
 * caller then updates the team's warning.
 */
export async function setGroupQuota(
  groupId: string,
  quotaMb: number | null,
): Promise<{ before: number; after: number; custom: boolean }> {
  const ref = db().collection(Collections.groups).doc(groupId);
  const custom = quotaMb !== null;
  const after = (quotaMb ?? (await defaultQuotaMb())) * MB;
  return db().runTransaction(async (tx) => {
    const group = await tx.get(ref);
    if (!group.exists) throw new HttpsError('not-found', 'No such team.');
    tx.update(ref, { storageQuotaBytes: after, storageQuotaCustom: custom, updatedAt: FieldValue.serverTimestamp() });
    return { before: quotaBytesOf(group.data()), after, custom };
  });
}

/**
 * Puts every team without its own limit on [defaultMb] (STORE-1, ADMIN-7),
 * when platform settings are saved, so the default is every such team's
 * limit, not only new ones'. A team has its own limit when a super admin
 * set it (storageQuotaCustom); one set before that mark existed, neither
 * [previousDefaultMb] nor the old built-in 500 MB, keeps its limit and
 * gets the mark. A team already using more than the new limit is full
 * until it frees space, and its admins are told, as at any limit
 * (STORE-3, STORE-4). Returns how many teams' limits changed.
 */
export async function applyDefaultQuota(defaultMb: number, previousDefaultMb: number): Promise<number> {
  const target = defaultMb * MB;
  const onDefault = new Set([previousDefaultMb * MB, LEGACY_DEFAULT_MB * MB, target]);
  const changed: string[] = [];
  await forEachPage(
    db().collection(Collections.groups).select('storageQuotaBytes', 'storageQuotaCustom'),
    (batch, team) => {
      if (team.get('storageQuotaCustom') === true) return;
      const quota = team.get('storageQuotaBytes') as unknown;
      if (typeof quota === 'number' && !onDefault.has(quota)) {
        batch.update(team.ref, { storageQuotaCustom: true });
        return;
      }
      if (quota === target) return;
      batch.update(team.ref, { storageQuotaBytes: target, updatedAt: FieldValue.serverTimestamp() });
      changed.push(team.id);
    },
  );
  for (const groupId of changed) await updateStorageAlert(groupId);
  if (changed.length) logger.info('default_quota_applied', { defaultMb, teams: changed.length });
  return changed.length;
}
