// Notification pipeline (ARCH §6.5). The only code that writes
// notifications, calls FCM, or removes devices from the server: every domain
// calls send() (rule 5, ARCH §6.4).
import { FieldValue, Timestamp, type DocumentReference } from 'firebase-admin/firestore';
import type { BaseMessage } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions/v2';
import { appUrl } from '../links/service.js';
import { db, messaging } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections, ID_SEPARATOR, Limits, NOTIFY_KINDS, type NotifyKind } from '../shared/constants.js';
import { groupMemberId } from '../shared/ids.js';

const DAY_MS = 86_400_000;

/** gRPC ALREADY_EXISTS, what Firestore's create() throws when the doc is there. */
const ALREADY_EXISTS = 6;

/** Who a notification is for: the whole team, its admins, or listed people. */
export type Recipients = { members: true } | { admins: true } | { uids: string[] };

export interface NotifyInput {
  kind: NotifyKind;
  groupId: string;
  recipients: Recipients;
  /** Left out even when [recipients] matches them, e.g. the reporter and the reported person. */
  exclude?: string[];
  /**
   * Who did it. They aren't told about their own action, and people who
   * blocked them aren't told either (NOTIF-11). Null hides the actor, so
   * admins aren't shown who reported (SAFE-1).
   */
  actor: { uid: string; name: string } | null;
  target: { type: string; id: string };
  /** Where a tap goes (NOTIF-6), e.g. /g/{g}/chat/m/{messageId}. */
  route: string;
  params: Record<string, string>;
  /** Pre-rendered English (NOTIF-5). A function gives each person their own (youth teams, M6). */
  body: string | ((uid: string) => string);
  /**
   * One per action. Triggers pass the triggering doc's ID so a retried
   * trigger can't notify twice; callables pass a random or natural key.
   */
  dedupeKey: string;
  /** The team name, when the caller already read the group. */
  teamName?: string;
}

/** A recipient's settings for this team (NOTIF-3), from their membership. */
export interface MemberSettings {
  uid: string;
  level: string;
  mutedUntilMs: number | null;
}

/** The parts of a profile the pipeline reads: account status and the global switches (NOTIF-4). */
export interface Profile {
  status?: unknown;
  notificationPrefs?: Record<string, unknown>;
}

/** A notification-center item's ID. The app computes its own as `${nkey}_${myUid}`. */
export function centerItemId(dedupeKey: string, uid: string): string {
  return `${dedupeKey}${ID_SEPARATOR}${uid}`;
}

/** A membership's level and mute; a missing level is All activity. */
export function memberSettingsOf(uid: string, data: Record<string, unknown> | undefined): MemberSettings {
  const muted = data?.mutedUntil;
  return {
    uid,
    level: typeof data?.notificationLevel === 'string' ? data.notificationLevel : 'all',
    mutedUntilMs: muted instanceof Timestamp ? muted.toMillis() : null,
  };
}

/**
 * Whether the team's settings let [kind] push (NOTIF-3): a mute still ahead
 * drops everything (including "until unmuted", Limits.mutedForeverMs), Off
 * drops everything, Important only keeps the important kinds (NOTIF-2).
 */
export function levelAllowsPush(kind: NotifyKind, member: Omit<MemberSettings, 'uid'>, nowMs: number): boolean {
  if (member.mutedUntilMs !== null && member.mutedUntilMs > nowMs) return false;
  if (member.level === 'none') return false;
  if (member.level === 'important') return NOTIFY_KINDS[kind].important;
  return true;
}

/**
 * Whether the person's global switch for [kind] is on (NOTIF-4). A missing
 * key is on. New events and Event changes used to be one 'events' switch:
 * while the new key is missing, an old 'events: false' still turns them off.
 */
export function prefAllowsPush(kind: NotifyKind, prefs: Record<string, unknown> | undefined): boolean {
  const key = NOTIFY_KINDS[kind].pref;
  if (!key || !prefs) return true;
  if (prefs[key] !== undefined) return prefs[key] !== false;
  if (key === 'eventsNew' || key === 'eventsChanged') return prefs.events !== false;
  return true;
}

/** Both push checks together (ARCH §6.5 step 3). */
export function pushAllowed(
  kind: NotifyKind,
  member: Omit<MemberSettings, 'uid'>,
  prefs: Record<string, unknown> | undefined,
  nowMs: number,
): boolean {
  return levelAllowsPush(kind, member, nowMs) && prefAllowsPush(kind, prefs);
}

/** Whether an account can be notified: it exists and isn't disabled (ARCH §6.5 step 1). */
export function canReceive(profile: Profile | undefined): boolean {
  return profile !== undefined && profile.status !== 'disabled';
}

/**
 * One line of at most [max] characters (ARCH §6.5: ~140), with an ellipsis
 * when cut. Counts code points, so an emoji is never split into a broken
 * half that FCM would refuse.
 */
export function truncate(text: string, max: number = Limits.notificationBodyMax): string {
  const chars = [...text.replace(/\s+/g, ' ').trim()];
  return chars.length > max ? `${chars.slice(0, max - 1).join('').trimEnd()}…` : chars.join('');
}

/** [items] in runs of at most [size]. */
export function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

export interface PushContent {
  teamName: string;
  body: string;
  route: string;
  groupId: string;
  kind: NotifyKind;
  /** The dedupe key; the app finds its center item at notifications/{nkey}_{myUid}. */
  nkey: string;
}

/**
 * The FCM message for one push, without its tokens (ARCH §6.5 payload). The
 * title is always the team name (NOTIF-5). iOS stacks by team with
 * thread-id (NOTIF-8); Android and web get no tag, because a tag replaces
 * the previous notification instead of stacking.
 */
export function buildPayload(c: PushContent): BaseMessage {
  return {
    notification: { title: c.teamName, body: truncate(c.body) },
    data: { route: c.route, groupId: c.groupId, kind: c.kind, nkey: c.nkey },
    apns: { payload: { aps: { 'thread-id': c.groupId, sound: 'default' } } },
    android: { priority: 'high', notification: { channelId: NOTIFY_KINDS[c.kind].channel } },
    webpush: {
      notification: { icon: appUrl('/icons/Icon-192.png') },
      // The web SDK opens this on click; web has no getInitialMessage.
      fcmOptions: { link: appUrl(c.route) },
    },
  };
}

const GONE_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/**
 * Whether a token that failed with [code] should be forgotten. Unregistered
 * and malformed tokens always are. invalid-argument only counts when other
 * tokens in the same batch went through: a bad payload fails every token
 * with it, and must not wipe everyone's devices.
 */
export function shouldDeleteToken(code: string | undefined, othersSucceeded: boolean): boolean {
  if (!code) return false;
  if (GONE_TOKEN_CODES.has(code)) return true;
  return code === 'messaging/invalid-argument' && othersSucceeded;
}

/** The positions in one send batch whose tokens should be forgotten. */
export function tokensToDelete(responses: { success: boolean; error?: { code: string } }[]): number[] {
  const anySucceeded = responses.some((r) => r.success);
  return responses.flatMap((r, i) => (!r.success && shouldDeleteToken(r.error?.code, anySucceeded) ? [i] : []));
}

/**
 * Sends one notification (ARCH §6.5): dedupes, resolves who gets it, writes
 * their notification-center items, then pushes to those whose settings
 * allow it. Returns who the push was for (whether or not they have a
 * device), so a caller can keep a second push from reaching them. Throws on
 * failure; callers use [trySend].
 */
export async function send(input: NotifyInput): Promise<string[]> {
  const info = NOTIFY_KINDS[input.kind];
  const now = Date.now();

  // 0. Dedupe: a retried trigger finds the marker and stops.
  try {
    await db()
      .collection(Collections.notifyLog)
      .doc(input.dedupeKey)
      .create({
        kind: input.kind,
        groupId: input.groupId,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: Timestamp.fromMillis(now + Limits.notifyLogTtlDays * DAY_MS),
      });
  } catch (e) {
    if ((e as { code?: unknown }).code === ALREADY_EXISTS) return [];
    throw e;
  }

  // 1. Recipients, minus the actor, the excluded, and people who blocked the actor.
  const teamName = input.teamName ?? (await teamNameOf(input.groupId));
  if (teamName === null) return []; // the team is gone
  const dropped = new Set(input.exclude ?? []);
  if (input.actor) {
    dropped.add(input.actor.uid);
    for (const uid of await blockersOf(input.actor.uid)) dropped.add(uid);
  }
  let members = (await resolveRecipients(input.groupId, input.recipients)).filter((m) => !dropped.has(m.uid));
  if (!members.length) return [];

  // Profiles are read once, and only as far as needed. Center kinds read
  // every recipient's, so disabled accounts get no items; others read only
  // those whose team settings let the push through (for chat messages,
  // the busiest kind, that skips muted and Off members).
  let profiles: Map<string, Profile> | undefined;
  if (info.center) {
    const loaded = await readProfiles(members.map((m) => m.uid));
    profiles = loaded;
    members = members.filter((m) => canReceive(loaded.get(m.uid)));
    // 2. Center items, written even when the push is muted or off (NOTIF-3, NOTIF-11).
    await writeCenterItems(input, members.map((m) => m.uid), teamName, now);
  }

  // 3. Push filter: team level and mute, then account status and the global switch.
  let pushTo = members.filter((m) => levelAllowsPush(input.kind, m, now));
  if (!pushTo.length) return [];
  const known = profiles ?? (await readProfiles(pushTo.map((m) => m.uid)));
  pushTo = pushTo.filter((m) => {
    const p = known.get(m.uid);
    return canReceive(p) && prefAllowsPush(input.kind, p?.notificationPrefs);
  });
  if (!pushTo.length) return [];

  // 4. Deliver.
  const uids = pushTo.map((m) => m.uid);
  await deliver(input, uids, teamName);
  return uids;
}

/**
 * [send], logging instead of throwing: a failed notification never fails or
 * undoes the action that caused it. Pass a function when the input needs
 * reads of its own (names for the body), so those failures are caught too;
 * it returns null when there's nothing to send. Returns who the push was
 * for, or nobody when it failed.
 */
export async function trySend(input: NotifyInput | (() => Promise<NotifyInput | null>)): Promise<string[]> {
  let resolved: NotifyInput | null = null;
  try {
    resolved = typeof input === 'function' ? await input() : input;
    return resolved ? await send(resolved) : [];
  } catch (e) {
    logger.error('notify_failed', {
      kind: resolved?.kind ?? null,
      groupId: resolved?.groupId ?? null,
      dedupeKey: resolved?.dedupeKey ?? null,
      error: String(e),
    });
    return [];
  }
}

async function teamNameOf(groupId: string): Promise<string | null> {
  const group = await db().collection(Collections.groups).doc(groupId).get();
  return group.exists ? ((group.get('name') as string | undefined) ?? '') : null;
}

/** The people who blocked [uid]; they never hear about what [uid] does. */
async function blockersOf(uid: string): Promise<string[]> {
  const snap = await db()
    .collection(Collections.userBlocks)
    .where('blockedUid', '==', uid)
    .select('uid')
    .limit(500)
    .get();
  return snap.docs.map((d) => d.get('uid') as string);
}

const MEMBER_FIELDS = ['uid', 'notificationLevel', 'mutedUntil'];

/**
 * The recipients' memberships, which carry each person's level and mute
 * for this team. Listed people who aren't on the team are left out.
 */
async function resolveRecipients(groupId: string, recipients: Recipients): Promise<MemberSettings[]> {
  if ('uids' in recipients) {
    const uids = [...new Set(recipients.uids)];
    const refs = uids.map((uid) => db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid)));
    const snaps = await getAllMasked(refs, MEMBER_FIELDS);
    return snaps.flatMap((s, i) => (s.exists ? [memberSettingsOf(uids[i], s.data())] : []));
  }
  let query = db().collection(Collections.groupMembers).where('groupId', '==', groupId);
  if ('admins' in recipients) query = query.where('role', 'in', ['owner', 'admin']);
  // Page through the whole team: nothing caps team size, and a single
  // capped read would silently leave the rest out.
  const out: MemberSettings[] = [];
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  for (;;) {
    let page = query.select(...MEMBER_FIELDS).orderBy('__name__').limit(Limits.membersPerGroupMax);
    if (last) page = page.startAfter(last);
    const snap = await page.get();
    out.push(...snap.docs.map((d) => memberSettingsOf(d.get('uid') as string, d.data())));
    if (snap.size < Limits.membersPerGroupMax) break;
    last = snap.docs[snap.docs.length - 1];
  }
  return out;
}

async function readProfiles(uids: string[]): Promise<Map<string, Profile>> {
  const refs = uids.map((uid) => db().collection(Collections.users).doc(uid));
  const snaps = await getAllMasked(refs, ['status', 'notificationPrefs']);
  const profiles = new Map<string, Profile>();
  snaps.forEach((s, i) => {
    if (s.exists) profiles.set(uids[i], s.data() as Profile);
  });
  return profiles;
}

/** getAll with a field mask, in runs of 100, in the order of [refs]. */
async function getAllMasked(
  refs: DocumentReference[],
  fields: string[],
): Promise<FirebaseFirestore.DocumentSnapshot[]> {
  const out: FirebaseFirestore.DocumentSnapshot[] = [];
  for (const part of chunk(refs, 100)) {
    out.push(...(await db().getAll(...part, { fieldMask: fields })));
  }
  return out;
}

function bodyFor(input: NotifyInput, uid: string): string {
  return typeof input.body === 'string' ? input.body : input.body(uid);
}

async function writeCenterItems(input: NotifyInput, uids: string[], teamName: string, now: number): Promise<void> {
  const expiresAt = Timestamp.fromMillis(now + Limits.notificationTtlDays * DAY_MS);
  for (const part of chunk(uids, 400)) {
    const batch = db().batch();
    for (const uid of part) {
      batch.set(db().collection(Collections.notifications).doc(centerItemId(input.dedupeKey, uid)), {
        uid,
        groupId: input.groupId,
        type: input.kind,
        params: input.params,
        title: teamName,
        body: truncate(bodyFor(input, uid)),
        route: input.route,
        actorId: input.actor?.uid ?? null,
        targetType: input.target.type,
        targetId: input.target.id,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt,
      });
    }
    await batch.commit();
  }
}

interface Device {
  uid: string;
  token: string;
  refs: DocumentReference[];
}

/** Every device of [uids], one entry per token. */
async function devicesOf(uids: string[]): Promise<Device[]> {
  const snaps = await Promise.all(
    chunk(uids, 30).map((part) =>
      db().collection(Collections.devices).where('uid', 'in', part).select('uid', 'token').get(),
    ),
  );
  const byToken = new Map<string, Device>();
  for (const d of snaps.flatMap((s) => s.docs)) {
    const token = d.get('token') as string | undefined;
    if (!token) continue;
    const known = byToken.get(token);
    if (known) known.refs.push(d.ref);
    else byToken.set(token, { uid: d.get('uid') as string, token, refs: [d.ref] });
  }
  return [...byToken.values()];
}

async function deliver(input: NotifyInput, uids: string[], teamName: string): Promise<void> {
  const devices = await devicesOf(uids);
  const payload = (body: string) =>
    buildPayload({
      teamName,
      body,
      route: input.route,
      groupId: input.groupId,
      kind: input.kind,
      nkey: input.dedupeKey,
    });
  // The emulators have no FCM: log what would go out, like email does.
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    logger.info('push_not_sent_emulator', {
      kind: input.kind,
      groupId: input.groupId,
      route: input.route,
      title: teamName,
      body: truncate(bodyFor(input, uids[0])),
      recipients: uids.length,
      devices: devices.length,
    });
    return;
  }
  let sent = 0;
  let failed = 0;
  let removed = 0;
  // One message per token, so per-person bodies need no second path.
  // (sendEachForMulticast does the same underneath, and its token form is
  // deprecated in firebase-admin 14.)
  for (const part of chunk(devices, Limits.pushTokensPerSend)) {
    const res = await messaging().sendEach(part.map((d) => ({ ...payload(bodyFor(input, d.uid)), token: d.token })));
    sent += res.successCount;
    failed += res.failureCount;
    const dead = tokensToDelete(res.responses).flatMap((i) => part[i].refs);
    for (const refs of chunk(dead, 400)) {
      const batch = db().batch();
      refs.forEach((ref) => batch.delete(ref));
      await batch.commit();
    }
    removed += dead.length;
  }
  logger.info('push_sent', { kind: input.kind, groupId: input.groupId, sent, failed, removed });
}

/** Signing out everywhere (AUTH-9, NOTIF-10) or deleting the account stops every device's pushes. */
export async function removeDevices(uid: string): Promise<number> {
  return forEachPage(db().collection(Collections.devices).where('uid', '==', uid), (b, d) => b.delete(d.ref));
}

/**
 * Deletes devices not updated in Limits.deviceStaleDays (dailyCleanup). The
 * app rewrites its device at least daily, so only abandoned installs go.
 */
export async function pruneDevices(now = new Date()): Promise<number> {
  const cutoff = Timestamp.fromMillis(now.getTime() - Limits.deviceStaleDays * DAY_MS);
  return forEachPage(db().collection(Collections.devices).where('updatedAt', '<', cutoff), (b, d) =>
    b.delete(d.ref),
  );
}

/** Someone removed from a team, or leaving it, loses that team's center items (ARCH §6.5). */
export async function removeTeamNotifications(groupId: string, uid: string): Promise<number> {
  return forEachPage(
    db().collection(Collections.notifications).where('uid', '==', uid).where('groupId', '==', groupId),
    (b, d) => b.delete(d.ref),
  );
}

/**
 * Erasing a message or deleting a document takes the center items about it
 * too: their bodies quote it (CHAT-8, DOC-5). Only this service touches
 * `notifications` (ENG-4).
 */
export async function removeTargetNotifications(targetType: 'message' | 'document', targetId: string): Promise<number> {
  return forEachPage(
    db().collection(Collections.notifications).where('targetType', '==', targetType).where('targetId', '==', targetId),
    (b, d) => b.delete(d.ref),
  );
}

/**
 * Deletes a deleted account's devices and notification-center items, and
 * other people's items about something they did: those name them in the
 * body ("Alex: Field 3 is open"), and they're shown from "Deleted user"
 * now (AUTH-10).
 */
export async function removeAccountNotifications(uid: string): Promise<void> {
  await removeDevices(uid);
  for (const field of ['uid', 'actorId']) {
    await forEachPage(db().collection(Collections.notifications).where(field, '==', uid), (b, d) => b.delete(d.ref));
  }
}
