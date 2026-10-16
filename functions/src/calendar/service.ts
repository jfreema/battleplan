// Calendar links (SPEC SCHED-11, ARCH §6.15, D66): a private link per
// person, for one team or all their teams, that calendar apps read on their
// own schedule. The feed carries no personal data, so one cached copy of a
// team's events (`teamCalendars`) serves every link to it.
import { randomBytes } from 'node:crypto';
import { FieldValue, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { HttpsError } from 'firebase-functions/v2/https';
import { db } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { appUrl } from '../links/service.js';
import { TEAM_ROLES, requireOpenTeam, roleOf, teamMembershipsOf } from '../shared/roles.js';
import { buildCalendar, type CalendarEvent, type FeedEvent } from './ics.js';

const HOUR_MS = 3_600_000;
const DAY_MS = 24 * HOUR_MS;

/** What setCalendarLink does: make the link (or return it), make a new one, or remove it. */
export type CalendarLinkAction = 'make' | 'reset' | 'off';

/** A link token: 32 random bytes in base64url (43 characters), never a reserved `__…__` ID. */
export function newCalendarToken(): string {
  for (;;) {
    const token = randomBytes(32).toString('base64url');
    if (!/^__.*__$/.test(token)) return token;
  }
}

/** A token as links carry it. */
export const CALENDAR_TOKEN = /^[A-Za-z0-9_-]{43}$/;

function msOf(v: unknown): number {
  if (v instanceof Timestamp) return v.toMillis();
  return typeof v === 'number' ? v : 0;
}

/** The person's link for [groupId], or for all their teams when null. */
async function linksOf(uid: string, groupId: string | null) {
  const snap = await db()
    .collection(Collections.calendarLinks)
    .where('uid', '==', uid)
    .where('groupId', '==', groupId)
    .limit(10)
    .get();
  return snap.docs;
}

/**
 * Makes, resets, or turns off [uid]'s link for [groupId] (one team, which
 * they must be on and which takes changes) or for all their teams (null).
 * Returns the link's token, or null once it's off.
 */
export async function setCalendarLink(
  uid: string,
  groupId: string | null,
  action: CalendarLinkAction,
): Promise<{ token: string | null }> {
  if (groupId !== null) {
    const role = await roleOf(groupId, uid);
    if (role === null || !TEAM_ROLES.includes(role)) {
      throw new HttpsError('permission-denied', 'Only people on the team have its calendar link.');
    }
    await requireOpenTeam(groupId, false);
  }
  const existing = await linksOf(uid, groupId);
  if (action === 'make' && existing.length) return { token: existing[0].id };
  const batch = db().batch();
  for (const doc of existing) batch.delete(doc.ref);
  let token: string | null = null;
  if (action !== 'off') {
    token = newCalendarToken();
    batch.create(db().collection(Collections.calendarLinks).doc(token), {
      uid,
      groupId,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  return { token };
}

/**
 * Deletes [uid]'s calendar links: every one (their account is going), or
 * only the one for [groupId] (they left the team or were removed).
 */
export async function deleteCalendarLinksOf(uid: string, groupId?: string): Promise<void> {
  let query = db().collection(Collections.calendarLinks).where('uid', '==', uid);
  if (groupId !== undefined) query = query.where('groupId', '==', groupId);
  const snap = await query.limit(500).get();
  if (snap.empty) return;
  const batch = db().batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
}

/** Calendar link cleanup that only logs if it fails, for callers mid-way through bigger work. */
export async function tryDeleteCalendarLinksOf(uid: string, groupId?: string): Promise<void> {
  await deleteCalendarLinksOf(uid, groupId).catch((e) =>
    logger.warn('calendar_links_cleanup_failed', { uid, groupId: groupId ?? null, error: String(e) }),
  );
}

// ---- A team's cached calendar ------------------------------------------------------

/** The event fields a feed prints: a change to any of them refreshes the team's copy. */
const FEED_FIELDS = new Set([
  'title',
  'type',
  'allDay',
  'startAt',
  'endAt',
  'startDate',
  'endDate',
  'location',
  'description',
  'arriveMinutesBefore',
  'canceledAt',
]);

function sameValue(a: unknown, b: unknown): boolean {
  if (a instanceof Timestamp || b instanceof Timestamp) {
    return a instanceof Timestamp && b instanceof Timestamp && a.isEqual(b);
  }
  return JSON.stringify(a ?? null) === JSON.stringify(b ?? null);
}

/**
 * Whether an events write changes what the team's feed prints: an event
 * added or deleted, or a printed field changed (not counts or reminder
 * times). Series events and imports are left to saveEventSeries and
 * importEvents, which write many at once and mark the team once.
 */
export function calendarChanged(
  eventId: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): boolean {
  if (before?.seriesId || after?.seriesId) return false;
  // Imported events' IDs start "imp-" (IMPORT-5).
  if (!before) return !!after && !eventId.startsWith('imp-');
  if (!after) return true;
  for (const k of FEED_FIELDS) if (!sameValue(before[k], after[k])) return true;
  return false;
}

/**
 * Marks [groupId]'s cached calendar out of date, so the next feed request
 * rebuilds it. A team with no cache yet has nothing to mark; a failure only
 * logs, since the cache rebuilds within hours anyway.
 */
export async function markTeamCalendarChanged(groupId: string): Promise<void> {
  await db()
    .collection(Collections.teamCalendars)
    .doc(groupId)
    .update({ changedAt: FieldValue.serverTimestamp() })
    .catch((e: { code?: number }) => {
      // 5 is NOT_FOUND: no cache yet.
      if (e.code !== 5) logger.warn('team_calendar_mark_failed', { groupId, error: String(e) });
    });
}

/** An events document as a feed prints it. */
export function calendarEventOf(id: string, d: DocumentData): CalendarEvent {
  const location = d.location && typeof d.location === 'object' ? (d.location as Record<string, unknown>) : null;
  const arrive = typeof d.arriveMinutesBefore === 'number' ? d.arriveMinutesBefore : null;
  return {
    id,
    title: String(d.title ?? '').trim() || 'Event',
    type: typeof d.type === 'string' ? d.type : 'other',
    allDay: d.allDay === true,
    startMs: msOf(d.startAt),
    endMs: msOf(d.endAt),
    startDate: typeof d.startDate === 'string' ? d.startDate : null,
    endDate: typeof d.endDate === 'string' ? d.endDate : null,
    location: location ? { name: String(location.name ?? ''), address: String(location.address ?? '') } : null,
    description: String(d.description ?? ''),
    arriveMinutesBefore: d.type === 'game' ? arrive : null,
    canceled: d.canceledAt != null,
    updatedMs: msOf(d.updatedAt),
  };
}

/**
 * [groupId]'s events for a feed, from its cached copy, rebuilt when an
 * event changed since it was built, when it's over
 * `Limits.calendarCacheHours` old, or when there's none: the events from
 * `calendarPastDays` back to `calendarFutureDays` ahead, at most
 * `calendarEventsMax`.
 */
export async function teamCalendarEvents(groupId: string, nowMs: number): Promise<CalendarEvent[]> {
  const ref = db().collection(Collections.teamCalendars).doc(groupId);
  const cached = await ref.get();
  const builtMs = msOf(cached.get('builtAt'));
  const changedMs = msOf(cached.get('changedAt'));
  if (cached.exists && builtMs >= changedMs && nowMs - builtMs < Limits.calendarCacheHours * HOUR_MS) {
    return (cached.get('events') as CalendarEvent[] | undefined) ?? [];
  }
  const snap = await db()
    .collection(Collections.events)
    .where('groupId', '==', groupId)
    .where('startAt', '>=', Timestamp.fromMillis(nowMs - Limits.calendarPastDays * DAY_MS))
    .where('startAt', '<', Timestamp.fromMillis(nowMs + Limits.calendarFutureDays * DAY_MS))
    .orderBy('startAt')
    .limit(Limits.calendarEventsMax)
    .get();
  const events = snap.docs.map((d) => calendarEventOf(d.id, d.data()));
  // builtAt is when the events were read, so a change after it rebuilds
  // again. Merge, so a change marked meanwhile isn't overwritten.
  await ref
    .set({ groupId, events, builtAt: snap.readTime }, { merge: true })
    .catch((e) => logger.warn('team_calendar_save_failed', { groupId, error: String(e) }));
  return events;
}

// ---- The feed --------------------------------------------------------------------------

export interface FeedResponse {
  status: 200 | 404;
  body: string;
  /** The file name calendar apps see, for a 200. */
  filename?: string;
}

const NOT_FOUND: FeedResponse = { status: 404, body: 'This calendar link was turned off or reset.' };

/** The token in a feed path: /cal/<token>.ics, or /<token> when called directly. */
export function feedToken(path: string): string | null {
  const match = /^\/(?:cal\/)?([A-Za-z0-9_-]{43})(?:\.ics)?\/?$/.exec(path);
  return match ? match[1] : null;
}

function fileName(name: string): string {
  const slug = name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  return `${slug || 'battleplan'}.ics`;
}

/**
 * The calendar for the link in [path]: 404 for an unknown token or a
 * disabled or deleted account; the person's open teams' events otherwise,
 * with an empty calendar for a team they've left or that's archived,
 * suspended, or gone, so calendar apps drop its events.
 */
export async function calendarFeed(path: string, nowMs = Date.now()): Promise<FeedResponse> {
  const token = feedToken(path);
  if (!token) return NOT_FOUND;
  const linkRef = db().collection(Collections.calendarLinks).doc(token);
  const link = await linkRef.get();
  if (!link.exists) return NOT_FOUND;
  const uid = String(link.get('uid'));
  const groupId = (link.get('groupId') as string | null | undefined) ?? null;
  const user = await db().collection(Collections.users).doc(uid).get();
  if (!user.exists || user.get('status') === 'disabled') return NOT_FOUND;

  // The teams whose events it shows: the one it's for while they're on it,
  // or every team they're on.
  let groupIds: string[];
  let theirs: Set<string>;
  if (groupId !== null) {
    groupIds = [groupId];
    const role = await roleOf(groupId, uid);
    theirs = new Set(role !== null && TEAM_ROLES.includes(role) ? [groupId] : []);
  } else {
    const memberships = await teamMembershipsOf(uid).limit(Limits.groupsPerUserMax).get();
    groupIds = memberships.docs.map((d) => String(d.get('groupId')));
    theirs = new Set(groupIds);
  }
  const groups = groupIds.length
    ? await db().getAll(...groupIds.map((g) => db().collection(Collections.groups).doc(g)))
    : [];
  const open = groups.filter(
    (g) =>
      theirs.has(g.id) &&
      g.exists &&
      g.get('kind') !== 'direct' &&
      g.get('archivedAt') == null &&
      g.get('suspendedAt') == null,
  );

  const events: FeedEvent[] = [];
  for (const g of open) {
    const team = String(g.get('name') ?? '').trim();
    for (const e of await teamCalendarEvents(g.id, nowMs)) {
      events.push({ ...e, team: groupId === null ? team : null, url: appUrl(`/g/${g.id}/schedule/e/${e.id}`) });
    }
  }
  events.sort((a, b) => a.startMs - b.startMs || a.id.localeCompare(b.id));

  // A team link is named for the team, even once it's empty.
  let name = 'Battleplan';
  if (groupId !== null) {
    const team = groups[0]?.exists ? String(groups[0].get('name') ?? '').trim() : '';
    if (team) name = team;
  }

  // When a calendar last read the link, for the app's sheet: at most hourly.
  if (nowMs - msOf(link.get('fetchedAt')) >= Limits.calendarFetchedEveryMinutes * 60_000) {
    await linkRef
      .update({ fetchedAt: FieldValue.serverTimestamp() })
      .catch((e) => logger.warn('calendar_fetched_at_failed', { error: String(e) }));
  }
  return { status: 200, body: buildCalendar(name, events, nowMs), filename: fileName(name) };
}
