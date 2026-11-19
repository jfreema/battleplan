// Notification pipeline (ARCH §6.5). The only code that writes
// notifications, calls FCM, or removes devices from the server: every domain
// calls send() (rule 5, ARCH §6.4).
import { FieldValue, Timestamp, type DocumentReference } from 'firebase-admin/firestore';
import type { BaseMessage, BatchResponse, TokenMessage } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions/v2';
import { appUrl } from '../links/service.js';
import { db, messaging } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections, ID_SEPARATOR, Limits, NOTIFY_KINDS, type NotifyKind } from '../shared/constants.js';
import { groupMemberId } from '../shared/ids.js';
import { TtlCache } from '../shared/ttl_cache.js';

const DAY_MS = 86_400_000;
const MINUTE_MS = 60_000;

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
  /** Pre-rendered English (NOTIF-5). A function gives each person their own (players named per person, PLAYER-7). */
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

/** FCM's errors that pass on their own: the same token may go through a little later (#41). */
const BRIEF_CODES = new Set([
  'messaging/internal-error',
  'messaging/server-unavailable',
  'messaging/unknown-error',
  'messaging/message-rate-exceeded',
  'messaging/quota-exceeded',
]);

/**
 * Whether a token that failed with [code] is worth sending again: FCM's
 * brief errors, and any unavailable or deadline error. Dead tokens never
 * are (shouldDeleteToken).
 */
export function isBriefFailure(code: string | undefined): boolean {
  if (!code) return false;
  return BRIEF_CODES.has(code) || /unavailable|deadline/i.test(code);
}

/**
 * How brief failures are sent again: the waits before each of the three
 * retries, and how long after the send started a retry may still begin.
 * Callables and triggers get 60 seconds, so 40 keeps the whole send well
 * inside that. Tests shorten the waits.
 */
export const pushRetry = {
  waitsMs: [1_000, 4_000, 15_000],
  budgetMs: 40_000,
  now: (): number => Date.now(),
  sleep: (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms)),
};

/** What one run of pushes did, for the log. */
export interface PushOutcome {
  sent: number;
  /** Tokens that never went through: refused, dead, or still failing when the retries ran out. */
  failed: number;
  /** Resends of tokens that failed with a brief error. */
  retried: number;
  /** Tokens still failing briefly when the retries ran out. */
  gaveUp: number;
  /** Positions in [messages] whose tokens should be forgotten. */
  dead: number[];
}

/**
 * Sends [messages], then sends again only the ones that failed with a
 * brief error, up to three more times, after the waits in [pushRetry], so
 * long as a retry can begin within its budget of [startedAt]. A token that
 * went through is never sent again, so nobody gets the same push twice,
 * and a dead one is never retried.
 */
export async function sendWithRetries(
  messages: TokenMessage[],
  sendEach: (messages: TokenMessage[]) => Promise<Pick<BatchResponse, 'responses' | 'successCount'>>,
  startedAt: number,
): Promise<PushOutcome> {
  const out: PushOutcome = { sent: 0, failed: 0, retried: 0, gaveUp: 0, dead: [] };
  let pending = messages.map((_, i) => i);
  for (let attempt = 0; ; attempt++) {
    const res = await sendEach(pending.map((i) => messages[i]));
    out.sent += res.successCount;
    out.dead.push(...tokensToDelete(res.responses).map((j) => pending[j]));
    const brief: number[] = [];
    res.responses.forEach((r, j) => {
      if (r.success) return;
      if (isBriefFailure(r.error?.code)) brief.push(pending[j]);
      else out.failed++;
    });
    if (!brief.length) return out;
    const wait = pushRetry.waitsMs[attempt];
    if (wait === undefined || pushRetry.now() + wait - startedAt > pushRetry.budgetMs) {
      out.failed += brief.length;
      out.gaveUp = brief.length;
      return out;
    }
    await pushRetry.sleep(wait);
    out.retried += brief.length;
    pending = brief;
  }
}

/**
 * [devices] in runs of at most [size] tokens, each person's devices in the
 * same run, so a notification can note who has been pushed after each run.
 */
export function chunkByPerson<T extends { uid: string }>(devices: T[], size: number): T[][] {
  const byPerson = new Map<string, T[]>();
  for (const d of devices) byPerson.set(d.uid, [...(byPerson.get(d.uid) ?? []), d]);
  const out: T[][] = [];
  let run: T[] = [];
  for (const own of byPerson.values()) {
    if (run.length && run.length + own.length > size) {
      out.push(run);
      run = [];
    }
    // Nobody has more devices than a run holds, but never send more than FCM takes.
    for (const part of chunk(own, size)) {
      if (run.length + part.length > size) {
        out.push(run);
        run = [];
      }
      run.push(...part);
    }
  }
  if (run.length) out.push(run);
  return out;
}

/**
 * How long a send may hold a notification's marker (its lease) before
 * another may pick the notification up: longer than any send runs.
 */
const LEASE_MS = 2 * MINUTE_MS;

/** A push more than this late ("Practice moved to 5:00") is worse than none (#41). */
export const NOTIFY_GIVE_UP_MS = 10 * MINUTE_MS;

/** How many times retryNotifications tries one notification before giving up. */
export const NOTIFY_RETRY_TRIES = 5;

/** How many waiting notifications retryNotifications takes a minute. */
const RETRY_BATCH = 50;

/**
 * What a send learned before it failed, so the retry starts from there
 * (#41): the team name, who it's for, and who the push is for.
 */
interface Progress {
  teamName?: string;
  /** The recipients, less the actor, the excluded, and people who blocked the actor. */
  uids?: string[];
  pushTo?: string[];
  /** This send holds the marker's lease, so a failure hands it back. */
  leased?: boolean;
}

/**
 * What a send found and did: it sent (or there was nothing to send),
 * someone else finished it, someone else is on it now, or it was too late.
 */
type Outcome = 'sent' | 'stopped' | 'busy' | 'gaveUp';

type Claim =
  | { kind: 'go'; resumed: boolean; centerDone: boolean; pushed: Set<string> }
  | { kind: Exclude<Outcome, 'sent'> };

/**
 * Step 0, the marker (ARCH §6.5). A new key creates `notifyLog/{key}` in
 * the `sending` state, holding its lease. A key already there was sent
 * (`done`, or an older marker with no state), gave up, is being sent now
 * (its lease is held), or stopped partway: then this send takes the lease
 * and finishes it, unless it started 10 minutes ago or more.
 */
async function claimMarker(marker: DocumentReference, input: NotifyInput, now: number): Promise<Claim> {
  try {
    await marker.create({
      kind: input.kind,
      groupId: input.groupId,
      state: 'sending',
      startedAt: Timestamp.fromMillis(now),
      leaseUntil: Timestamp.fromMillis(now + LEASE_MS),
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(now + Limits.notifyLogTtlDays * DAY_MS),
    });
    return { kind: 'go', resumed: false, centerDone: false, pushed: new Set() };
  } catch (e) {
    if ((e as { code?: unknown }).code !== ALREADY_EXISTS) throw e;
  }
  // Only the rare second send of a key gets here, so the usual send stays
  // one write.
  return db().runTransaction(async (tx): Promise<Claim> => {
    const snap = await tx.get(marker);
    const data = snap.data() ?? {};
    if (!snap.exists || data.state !== 'sending') return { kind: 'stopped' };
    const started = (data.startedAt as Timestamp | undefined)?.toMillis() ?? 0;
    if (now - started >= NOTIFY_GIVE_UP_MS) {
      tx.update(marker, { state: 'gaveUp', leaseUntil: FieldValue.delete(), pushed: FieldValue.delete() });
      return { kind: 'gaveUp' };
    }
    if (((data.leaseUntil as Timestamp | undefined)?.toMillis() ?? 0) > now) return { kind: 'busy' };
    tx.update(marker, { leaseUntil: Timestamp.fromMillis(now + LEASE_MS) });
    return {
      kind: 'go',
      resumed: true,
      centerDone: data.centerDone === true,
      pushed: new Set((data.pushed as string[] | undefined) ?? []),
    };
  });
}

/**
 * Sends one notification (ARCH §6.5): dedupes, resolves who gets it, writes
 * their notification-center items, then pushes to those whose settings
 * allow it. Returns who the push was for (whether or not they have a
 * device), so a caller can keep a second push from reaching them. Throws on
 * failure; callers use [trySend].
 */
export async function send(input: NotifyInput): Promise<string[]> {
  return (await run(input, {}, Date.now())).uids;
}

async function run(
  input: NotifyInput,
  progress: Progress,
  startedAt: number,
): Promise<{ outcome: Outcome; uids: string[] }> {
  const info = NOTIFY_KINDS[input.kind];
  const now = startedAt;
  const marker = db().collection(Collections.notifyLog).doc(input.dedupeKey);

  // 0. Dedupe: a second send of the key stops, or finishes what the first
  // couldn't, never repeating what it did.
  const claim = await claimMarker(marker, input, now);
  if (claim.kind !== 'go') {
    if (claim.kind === 'gaveUp') logGaveUp(input, 'late');
    return { outcome: claim.kind, uids: [] };
  }
  progress.leased = true;
  const finish = async (uids: string[]) => {
    progress.leased = false;
    await noteProgress(marker, { state: 'done', leaseUntil: FieldValue.delete(), pushed: FieldValue.delete() });
    return { outcome: 'sent' as const, uids };
  };

  // 1. Recipients, minus the actor, the excluded, and people who blocked the actor.
  const teamName = input.teamName ?? (await teamNameOf(input.groupId));
  if (teamName === null) return finish([]); // the team is gone
  progress.teamName = teamName;
  let members = await recipientsOf(input);
  progress.uids = members.map((m) => m.uid);
  if (!members.length) return finish([]);

  // Profiles are read once, and only as far as needed. Center kinds read
  // every recipient's, so disabled accounts get no items; others read only
  // those whose team settings let the push through (for chat messages,
  // the busiest kind, that skips muted and Off members).
  let profiles: Map<string, Profile> | undefined;
  if (info.center) {
    const loaded = await readProfiles(members.map((m) => m.uid));
    profiles = loaded;
    members = members.filter((m) => canReceive(loaded.get(m.uid)));
  }

  // 3. Push filter: team level and mute, then account status and the global switch.
  let pushTo = members.filter((m) => levelAllowsPush(input.kind, m, now));
  if (pushTo.length) {
    const known = profiles ?? (await readProfiles(pushTo.map((m) => m.uid)));
    pushTo = pushTo.filter((m) => {
      const p = known.get(m.uid);
      return canReceive(p) && prefAllowsPush(input.kind, p?.notificationPrefs);
    });
  }
  const uids = pushTo.map((m) => m.uid);
  progress.pushTo = uids;

  // 2. Center items, written even when the push is muted or off (NOTIF-3,
  // NOTIF-11). Finishing a send, only the ones not written yet, so nobody's
  // read item turns unread.
  if (info.center && !claim.centerDone) {
    await writeCenterItems(input, members.map((m) => m.uid), teamName, now, claim.resumed);
    if (uids.length) await noteProgress(marker, { centerDone: true });
  }

  // 4. Deliver, to the people not pushed yet.
  const waiting = uids.filter((uid) => !claim.pushed.has(uid));
  if (waiting.length) await deliver(input, waiting, teamName, marker, startedAt);
  return finish(uids);
}

/**
 * Notes a send's progress on its marker. A note that fails is logged, not
 * thrown: what it notes is already done, and a retry would only repeat it.
 */
async function noteProgress(marker: DocumentReference, fields: Record<string, unknown>): Promise<void> {
  await marker.update(fields).catch((e) => logger.warn('notify_marker_not_noted', { id: marker.id, error: String(e) }));
}

function logGaveUp(input: Pick<NotifyInput, 'kind' | 'groupId' | 'dedupeKey'>, reason: 'late' | 'tries'): void {
  logger.error('notify_gave_up', { kind: input.kind, groupId: input.groupId, dedupeKey: input.dedupeKey, reason });
}

/** Hands back a failed send's lease, so the next minute's retry can start at once. */
async function releaseLease(dedupeKey: string, progress: Progress): Promise<void> {
  if (!progress.leased) return;
  await db()
    .collection(Collections.notifyLog)
    .doc(dedupeKey)
    .update({ leaseUntil: Timestamp.fromMillis(0) })
    .catch(() => undefined); // it runs out in two minutes anyway
}

/**
 * [send], logging instead of throwing: a failed notification never fails or
 * undoes the action that caused it. Pass a function when the input needs
 * reads of its own (names for the body), so those failures are caught too;
 * it returns null when there's nothing to send. Returns who the push was
 * for. A send that fails is queued in `notifyRetries` for
 * retryNotifications to finish (#41); then it returns who the push will be
 * for, as far as it knows, so the caller's next push leaves them out.
 */
export async function trySend(input: NotifyInput | (() => Promise<NotifyInput | null>)): Promise<string[]> {
  let resolved: NotifyInput | null = null;
  const progress: Progress = {};
  try {
    resolved = typeof input === 'function' ? await input() : input;
    return resolved ? (await run(resolved, progress, Date.now())).uids : [];
  } catch (e) {
    logger.error('notify_failed', {
      kind: resolved?.kind ?? null,
      groupId: resolved?.groupId ?? null,
      dedupeKey: resolved?.dedupeKey ?? null,
      error: String(e),
    });
    // The caller's own reads failed: there's nothing to send again.
    if (!resolved) return [];
    await releaseLease(resolved.dedupeKey, progress);
    try {
      await queueRetry(resolved, progress, Date.now());
    } catch (q) {
      logger.error('notify_retry_not_queued', { dedupeKey: resolved.dedupeKey, error: String(q) });
      return [];
    }
    return progress.pushTo ?? listedUids(resolved);
  }
}

/** The people [input] names, less the actor and the excluded; a whole team or its admins name nobody. */
function listedUids(input: NotifyInput): string[] {
  if (!('uids' in input.recipients)) return [];
  const dropped = new Set([...(input.exclude ?? []), ...(input.actor ? [input.actor.uid] : [])]);
  return input.recipients.uids.filter((uid) => !dropped.has(uid));
}

/**
 * Queues a failed send in `notifyRetries/{dedupeKey}` (Functions only). It
 * keeps what the retry needs: the recipients as resolved, when the send got
 * that far, and the body rendered for each of them when it's per person,
 * since a function can't be stored. A key already queued stays as it is.
 */
async function queueRetry(input: NotifyInput, progress: Progress, now: number): Promise<void> {
  let uids = progress.uids;
  // Per-person bodies need their people: worked out here when the send
  // failed before it got that far.
  if (typeof input.body === 'function' && !uids) uids = (await recipientsOf(input)).map((m) => m.uid);
  const body = input.body;
  const doc = {
    kind: input.kind,
    groupId: input.groupId,
    recipients: uids ? { uids } : input.recipients,
    exclude: uids ? [] : (input.exclude ?? []),
    actor: input.actor,
    target: input.target,
    route: input.route,
    params: input.params,
    body: typeof body === 'string' ? body : null,
    bodies: typeof body === 'function' ? Object.fromEntries((uids ?? []).map((uid) => [uid, truncate(body(uid))])) : null,
    teamName: progress.teamName ?? input.teamName ?? null,
    tries: 0,
    nextAt: Timestamp.fromMillis(now),
    createdAt: Timestamp.fromMillis(now),
    expiresAt: Timestamp.fromMillis(now + DAY_MS),
  };
  try {
    await db().collection(Collections.notifyRetries).doc(input.dedupeKey).create(doc);
  } catch (e) {
    if ((e as { code?: unknown }).code !== ALREADY_EXISTS) throw e;
  }
}

/** A queued notification as [run] takes it. */
export function inputFromRetry(dedupeKey: string, d: Record<string, unknown>): NotifyInput {
  const bodies = d.bodies as Record<string, string> | null | undefined;
  return {
    kind: d.kind as NotifyKind,
    groupId: d.groupId as string,
    recipients: d.recipients as Recipients,
    exclude: (d.exclude as string[] | undefined) ?? [],
    actor: (d.actor as NotifyInput['actor']) ?? null,
    target: d.target as NotifyInput['target'],
    route: d.route as string,
    params: (d.params as Record<string, string> | undefined) ?? {},
    body: bodies ? (uid: string) => bodies[uid] ?? '' : String(d.body ?? ''),
    dedupeKey,
    ...(typeof d.teamName === 'string' ? { teamName: d.teamName } : {}),
  };
}

/**
 * retryNotifications, every minute (#41): finishes up to 50 queued
 * notifications whose time has come, oldest first, through [run], so only
 * what wasn't done gets done. Each is deleted once sent (or found sent);
 * one another send holds is left for the next minute; one 10 minutes old,
 * or failing a fifth time, gives up. With none queued, which is almost
 * always, it's one empty read.
 */
export async function retryDueNotifications(
  nowMs = Date.now(),
  // Stops taking new ones a minute before the job's five run out.
  stopAtMs = nowMs + 4 * MINUTE_MS,
): Promise<{ sent: number; gaveUp: number; waiting: number }> {
  const due = await db()
    .collection(Collections.notifyRetries)
    .where('nextAt', '<=', Timestamp.fromMillis(nowMs))
    .orderBy('nextAt')
    .limit(RETRY_BATCH)
    .get();
  const out = { sent: 0, gaveUp: 0, waiting: 0 };
  for (const doc of due.docs) {
    if (pushRetry.now() >= stopAtMs) break; // the rest wait for the next minute
    const input = inputFromRetry(doc.id, doc.data());
    const createdMs = (doc.get('createdAt') as Timestamp | undefined)?.toMillis() ?? 0;
    if (nowMs - createdMs >= NOTIFY_GIVE_UP_MS) {
      logGaveUp(input, 'late');
      await giveUp(doc.ref, doc.id);
      out.gaveUp++;
      continue;
    }
    const progress: Progress = {};
    try {
      const { outcome } = await run(input, progress, pushRetry.now());
      if (outcome === 'busy') {
        out.waiting++;
        continue;
      }
      await doc.ref.delete();
      if (outcome === 'gaveUp') out.gaveUp++;
      else out.sent++;
    } catch (e) {
      await releaseLease(doc.id, progress);
      const tries = ((doc.get('tries') as number | undefined) ?? 0) + 1;
      if (tries >= NOTIFY_RETRY_TRIES) {
        logGaveUp(input, 'tries');
        await giveUp(doc.ref, doc.id);
        out.gaveUp++;
      } else {
        logger.warn('notify_retry_failed', { dedupeKey: doc.id, tries, error: String(e) });
        await doc.ref.update({ tries, nextAt: Timestamp.fromMillis(nowMs + MINUTE_MS) });
        out.waiting++;
      }
    }
  }
  return out;
}

/** Drops a queued notification and marks its marker, so nothing picks it up again. */
async function giveUp(retry: DocumentReference, dedupeKey: string): Promise<void> {
  await db()
    .collection(Collections.notifyLog)
    .doc(dedupeKey)
    .update({ state: 'gaveUp', leaseUntil: FieldValue.delete(), pushed: FieldValue.delete() })
    .catch(() => undefined); // no marker: the send failed before it
  await retry.delete();
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

/** [input]'s recipients with their team settings, less the actor, the excluded, and people who blocked the actor. */
async function recipientsOf(input: NotifyInput): Promise<MemberSettings[]> {
  const dropped = new Set(input.exclude ?? []);
  if (input.actor) {
    dropped.add(input.actor.uid);
    for (const uid of await blockersOf(input.actor.uid)) dropped.add(uid);
  }
  return (await resolveRecipients(input.groupId, input.recipients)).filter((m) => !dropped.has(m.uid));
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

/**
 * Recipients' status and switches, kept a minute per instance, so a busy
 * chat's pushes don't read every recipient's profile per message (ARCH
 * §10.2). A switch turned off can let a push through for that minute.
 */
const profileCache = new TtlCache<Profile>();

async function readProfiles(uids: string[]): Promise<Map<string, Profile>> {
  return profileCache.getMany(uids, async (missing) => {
    const refs = missing.map((uid) => db().collection(Collections.users).doc(uid));
    const snaps = await getAllMasked(refs, ['status', 'notificationPrefs']);
    const profiles = new Map<string, Profile>();
    snaps.forEach((s, i) => {
      if (s.exists) profiles.set(missing[i], s.data() as Profile);
    });
    return profiles;
  });
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

/**
 * One notification-center item per person, in batches. Finishing a send
 * ([onlyMissing]), the ones already there are left as they are, read or
 * not.
 */
async function writeCenterItems(
  input: NotifyInput,
  uids: string[],
  teamName: string,
  now: number,
  onlyMissing: boolean,
): Promise<void> {
  const expiresAt = Timestamp.fromMillis(now + Limits.notificationTtlDays * DAY_MS);
  const ref = (uid: string) => db().collection(Collections.notifications).doc(centerItemId(input.dedupeKey, uid));
  for (const part of chunk(uids, 400)) {
    let todo = part;
    if (onlyMissing) {
      const there = await getAllMasked(todo.map(ref), ['uid']);
      todo = todo.filter((_, i) => !there[i].exists);
      if (!todo.length) continue;
    }
    const batch = db().batch();
    for (const uid of todo) {
      const item = {
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
      };
      // create, finishing a send: an item that appeared meanwhile fails the
      // batch, and the retry reads again, rather than overwrite it.
      if (onlyMissing) batch.create(ref(uid), item);
      else batch.set(ref(uid), item);
    }
    await batch.commit();
  }
}

interface Device {
  uid: string;
  token: string;
  refs: DocumentReference[];
}

/**
 * Every device of [uids], one entry per token. Always read fresh, unlike
 * profiles: signing out everywhere deletes devices, and a cached one could
 * still get a preview for a minute.
 */
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

/**
 * Pushes to every device of [uids] (ARCH §6.5 step 4), each person's
 * devices in one run of up to 500, resending brief failures
 * (sendWithRetries) and forgetting dead tokens. After each run but the
 * last, the marker notes who has been pushed, so a send that fails partway
 * is finished without pushing anyone twice; the last is noted by the
 * marker's `done`.
 */
async function deliver(
  input: NotifyInput,
  uids: string[],
  teamName: string,
  marker: DocumentReference,
  startedAt: number,
): Promise<void> {
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
  const total = { sent: 0, failed: 0, removed: 0, retried: 0, gaveUp: 0 };
  // One message per token, so per-person bodies need no second path.
  // (sendEachForMulticast does the same underneath, and its token form is
  // deprecated in firebase-admin 14.)
  const runs = chunkByPerson(devices, Limits.pushTokensPerSend);
  for (const [n, part] of runs.entries()) {
    const res = await sendWithRetries(
      part.map((d) => ({ ...payload(bodyFor(input, d.uid)), token: d.token })),
      (messages) => messaging().sendEach(messages),
      startedAt,
    );
    total.sent += res.sent;
    total.failed += res.failed;
    total.retried += res.retried;
    total.gaveUp += res.gaveUp;
    const dead = res.dead.flatMap((i) => part[i].refs);
    for (const refs of chunk(dead, 400)) {
      const batch = db().batch();
      refs.forEach((ref) => batch.delete(ref));
      await batch.commit();
    }
    total.removed += dead.length;
    if (n < runs.length - 1) {
      await noteProgress(marker, { pushed: FieldValue.arrayUnion(...new Set(part.map((d) => d.uid))) });
    }
  }
  logger.info('push_sent', { kind: input.kind, groupId: input.groupId, ...total });
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
