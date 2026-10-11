// Per-team storage accounting (ARCH §6.3, D16). Storage rules stop uploads
// once groups.storageBytes reaches storageQuotaBytes. Triggers keep the
// number current as files come and go, and dailyCleanup recomputes it from
// the bucket so any drift (a missed event, a retried trigger) heals.
import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { db, storage } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';

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

/** Recomputes every team's storage total, a page of teams at a time. */
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
      teams++;
    }
    if (snap.size < 200) break;
    last = snap.docs[snap.docs.length - 1];
  }
  return teams;
}
