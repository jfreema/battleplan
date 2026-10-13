// Schedule domain service: owns eventSeries, events, rsvps (ARCH §6.2).
import { FieldValue, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { db } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections } from '../shared/constants.js';
import { groupMemberId, rsvpId } from '../shared/ids.js';
import { chunk, trySend } from '../notify/service.js';
import { addDays, dateInZone, type Recurrence } from './recurrence.js';

const MINUTE_MS = 60_000;

/** gRPC ALREADY_EXISTS, what Firestore's create() throws when the doc is there. */
const ALREADY_EXISTS = 6;

/**
 * How late the events trigger still counts a reminder as ahead: one tick.
 * An edit just after a reminder fell due doesn't skip it; the dedupe key
 * keeps it from going twice.
 */
export const REMINDER_GRACE_MS = 5 * MINUTE_MS;

// ---- Counts (SCHED-1, PLAYER-6) -------------------------------------------

/** Going / Maybe / Not going counts (ARCH §6.2 events.rsvpCounts). */
export interface RsvpCounts {
  going: number;
  maybe: number;
  notGoing: number;
}

export const ZERO_COUNTS: RsvpCounts = { going: 0, maybe: 0, notGoing: 0 };

/** The parts of an RSVP that counting reads. */
export interface RsvpRow {
  participantType?: unknown;
  participantId?: unknown;
  status?: unknown;
}

/**
 * Counts an event's answers, the same on every team (SCHED-5, PLAYER-6):
 * rsvpCounts counts players, staffCounts everyone answering for themselves
 * ("coaches and others", D34). An old event's rsvpFor is ignored.
 */
export function countsOf(rsvps: RsvpRow[]): { rsvpCounts: RsvpCounts; staffCounts: RsvpCounts } {
  const rsvpCounts = { ...ZERO_COUNTS };
  const staffCounts = { ...ZERO_COUNTS };
  for (const r of rsvps) {
    const counts = r.participantType === 'player' ? rsvpCounts : r.participantType === 'member' ? staffCounts : null;
    if (!counts) continue;
    if (r.status === 'going') counts.going++;
    else if (r.status === 'maybe') counts.maybe++;
    else if (r.status === 'not_going') counts.notGoing++;
  }
  return { rsvpCounts, staffCounts };
}

function sameCounts(a: RsvpCounts, b: unknown): boolean {
  const c = (b ?? {}) as Partial<RsvpCounts>;
  return a.going === c.going && a.maybe === c.maybe && a.notGoing === c.notGoing;
}

/**
 * rsvps written → the event's counts (ARCH §6.4 trigger map). Recounts
 * every answer in a transaction, like recountPoll, so a trigger that runs
 * twice or out of order still leaves the right numbers. An event has at
 * most 500 members and 200 players answering.
 */
export async function recountEventRsvps(eventId: string): Promise<void> {
  const eventRef = db().collection(Collections.events).doc(eventId);
  const rsvps = db().collection(Collections.rsvps).where('eventId', '==', eventId);
  await db().runTransaction(async (tx) => {
    const event = await tx.get(eventRef);
    if (!event.exists) return; // Deleted; its RSVPs go with it.
    const snap = await tx.get(rsvps);
    const { rsvpCounts, staffCounts } = countsOf(snap.docs.map((d) => d.data()));
    if (sameCounts(rsvpCounts, event.get('rsvpCounts')) && sameCounts(staffCounts, event.get('staffCounts'))) return;
    tx.update(eventRef, { rsvpCounts, staffCounts });
  });
}

/** Whether an RSVP write changes what it counts: its status or who it's for. */
export function rsvpCountChanged(before: DocumentData | undefined, after: DocumentData | undefined): boolean {
  if (!before || !after) return true;
  return before.status !== after.status || before.participantType !== after.participantType;
}

// ---- Wording (NOTIF-5) ----------------------------------------------------

/** What the wording reads of an event. */
export interface EventView {
  title: string;
  allDay: boolean;
  startMs: number;
  endMs: number;
  /** All-day events: the first date, which never shifts (SCHED-9). */
  startDate: string | null;
  timeZone: string;
  location: { name?: string; address?: string } | null;
  reminderOffsets: number[];
  canceled: boolean;
  /** game, practice, meeting, social, or other; read by the new-event line. */
  type?: string;
}

function msOf(v: unknown): number {
  if (v instanceof Timestamp) return v.toMillis();
  if (v instanceof Date) return v.getTime();
  return typeof v === 'number' ? v : 0;
}

/** An event document as the wording and reminder code read it. */
export function eventView(d: DocumentData): EventView {
  return {
    title: String(d.title ?? '').trim() || 'Event',
    allDay: d.allDay === true,
    startMs: msOf(d.startAt),
    endMs: msOf(d.endAt),
    startDate: typeof d.startDate === 'string' ? d.startDate : null,
    timeZone: typeof d.timeZone === 'string' && d.timeZone ? d.timeZone : 'UTC',
    location: d.location && typeof d.location === 'object' ? (d.location as EventView['location']) : null,
    reminderOffsets: Array.isArray(d.reminderOffsets) ? d.reminderOffsets.filter((o): o is number => typeof o === 'number') : [],
    canceled: Boolean(d.canceledAt),
    type: typeof d.type === 'string' ? d.type : 'other',
  };
}

const formatters = new Map<string, Intl.DateTimeFormat>();

/** Intl output with plain spaces (newer ICU puts U+202F before "PM"). */
function format(ms: number, timeZone: string, options: Intl.DateTimeFormatOptions): string {
  const key = `${timeZone}|${JSON.stringify(options)}`;
  let f = formatters.get(key);
  if (!f) {
    f = new Intl.DateTimeFormat('en-US', { timeZone, ...options });
    formatters.set(key, f);
  }
  return f.format(new Date(ms)).replace(/[  ]/g, ' ');
}

function dateMs(date: string): number {
  const [y, m, d] = date.split('-').map(Number);
  return Date.UTC(y, m - 1, d);
}

/** "6:00 PM", in the event's own zone (SCHED-9). */
export function timeLabel(ms: number, timeZone: string): string {
  return format(ms, timeZone, { hour: 'numeric', minute: '2-digit' });
}

/** "Tue, Oct 13", in the event's own zone. */
export function dayLabel(ms: number, timeZone: string): string {
  return format(ms, timeZone, { weekday: 'short', month: 'short', day: 'numeric' });
}

/** "Oct 13". */
function shortDate(date: string): string {
  return format(dateMs(date), 'UTC', { month: 'short', day: 'numeric' });
}

/** "Tue". */
function weekdayName(isoWeekday: number): string {
  // 2024-01-01 was a Monday.
  return format(Date.UTC(2024, 0, isoWeekday), 'UTC', { weekday: 'short' });
}

/** The event's day: all-day dates never shift (SCHED-9). */
function eventDay(e: EventView): string {
  return e.allDay && e.startDate ? format(dateMs(e.startDate), 'UTC', { weekday: 'short', month: 'short', day: 'numeric' }) : dayLabel(e.startMs, e.timeZone);
}

/** "Tue, Oct 13 at 6:00 PM", or "Sat, Oct 17" for an all-day event. */
export function whenLabel(e: EventView): string {
  return e.allDay ? eventDay(e) : `${eventDay(e)} at ${timeLabel(e.startMs, e.timeZone)}`;
}

/** The place's name, or its address when it has no name. */
export function locationLabel(location: EventView['location']): string {
  return (location?.name ?? '').trim() || (location?.address ?? '').trim();
}

/** "game", "practice", "meeting", or "event" for the new-event line. */
function typeWord(type: string | undefined): string {
  return type === 'game' || type === 'practice' || type === 'meeting' ? type : 'event';
}

/**
 * "New game: vs. Eagles · Sat Oct 18, 10:00 AM" (NOTIF-5, NOTIF-2
 * eventCreated), or "New event: Tournament · Sat Oct 17" all day.
 */
export function eventCreatedBody(e: EventView): string {
  const day = eventDay(e).replace(',', '');
  const when = e.allDay ? day : `${day}, ${timeLabel(e.startMs, e.timeZone)}`;
  return `New ${typeWord(e.type)}: ${e.title} · ${when}`;
}

/** "Canceled: Practice, Tue, Oct 13 at 6:00 PM" (SCHED-7). */
export function eventCanceledBody(e: EventView): string {
  return `Canceled: ${e.title}, ${whenLabel(e)}`;
}

/** An event card's line in chat (CHAT-11): "Practice · Tue, Oct 13 at 6:00 PM". */
export function eventCardText(e: EventView): string {
  const place = locationLabel(e.location);
  return `${e.title} · ${whenLabel(e)}${place ? ` · ${place}` : ''}`;
}

function sameLocation(a: EventView['location'], b: EventView['location']): boolean {
  return (a?.name ?? '') === (b?.name ?? '') && (a?.address ?? '') === (b?.address ?? '');
}

/** Whether the date, time, or place changed (SCHED-6: those notify). */
export function timeOrPlaceChanged(before: EventView, after: EventView): boolean {
  return (
    before.startMs !== after.startMs ||
    before.endMs !== after.endMs ||
    before.allDay !== after.allDay ||
    !sameLocation(before.location, after.location)
  );
}

/**
 * The eventChanged line for an edit (SCHED-6, SCHED-7), or null when the
 * edit doesn't notify: "Practice moved to Tue, Oct 13 at 6:30 PM",
 * "Practice location changed: Riverside Park", "Canceled: Practice, …".
 */
export function eventChangedBody(before: EventView, after: EventView): string | null {
  if (!before.canceled && after.canceled) return eventCanceledBody(after);
  if (after.canceled) return null;
  const moved = before.startMs !== after.startMs || before.allDay !== after.allDay;
  const endMoved = before.endMs !== after.endMs;
  const placeChanged = !sameLocation(before.location, after.location);
  const place = locationLabel(after.location);
  if (moved) return `${after.title} moved to ${whenLabel(after)}${placeChanged && place ? ` · ${place}` : ''}`;
  if (endMoved && !after.allDay) {
    const ends = `${after.title} now ends at ${timeLabel(after.endMs, after.timeZone)}`;
    return placeChanged && place ? `${ends} · ${place}` : ends;
  }
  if (endMoved) return `${after.title} now ends ${dayLabel(after.endMs - 1, after.timeZone)}`;
  if (placeChanged) return place ? `${after.title} location changed: ${place}` : `${after.title} location removed`;
  return null;
}

/**
 * "today", "tomorrow", or "on Sat, Oct 17": the event's day as seen from
 * [nowMs], in the event's zone.
 */
export function relativeDay(e: EventView, nowMs: number): string {
  // Tomorrow by the calendar, not now + 24 h: days around a clock change
  // are 23 or 25 hours long.
  const today = dateInZone(nowMs, e.timeZone);
  const tomorrow = addDays(today, 1);
  const day = e.allDay && e.startDate ? e.startDate : dateInZone(e.startMs, e.timeZone);
  if (day === today) return 'today';
  if (day === tomorrow) return 'tomorrow';
  return `on ${eventDay(e)}`;
}

/**
 * A reminder (SCHED-8): "Reminder: Practice today at 6:00 PM · Riverside
 * Park". A guardian's names their players instead (PLAYER-7): "Emma,
 * Liam: Practice today at 6:00 PM · Riverside Park". A member who is the
 * player gets the plain reminder.
 */
export function reminderBody(e: EventView, nowMs: number, playerNames: string[] = []): string {
  const time = e.allDay ? '' : ` at ${timeLabel(e.startMs, e.timeZone)}`;
  const place = locationLabel(e.location);
  const core = `${e.title} ${relativeDay(e, nowMs)}${time}${place ? ` · ${place}` : ''}`;
  return withPlayers(playerNames, core, 'Reminder: ');
}

/** "Emma, Liam: …" for a guardian (PLAYER-7), else [prefix] + the line. */
export function withPlayers(playerNames: string[], line: string, prefix = ''): string {
  return playerNames.length ? `${playerNames.join(', ')}: ${line}` : `${prefix}${line}`;
}

/** "Tue and Thu", "Mon, Wed, and Fri". */
function weekdaysPhrase(weekdays: number[]): string {
  const names = [...new Set(weekdays)].sort((a, b) => a - b).map(weekdayName);
  if (names.length <= 1) return names[0] ?? '';
  if (names.length === 2) return `${names[0]} and ${names[1]}`;
  return `${names.slice(0, -1).join(', ')}, and ${names.at(-1)}`;
}

/** The times a series template sets. */
export interface SeriesTimes {
  allDay: boolean;
  startTime: string | null;
  timeZone: string;
}

/** "6:00 PM" from 'HH:mm'. */
function clockLabel(hhmm: string): string {
  const [h, m] = hhmm.split(':').map(Number);
  return format(Date.UTC(2024, 0, 1, h, m), 'UTC', { hour: 'numeric', minute: '2-digit' });
}

/**
 * A series in a few words (SCHED-3): "Tue and Thu at 6:00 PM, Oct 13 –
 * Dec 17", "daily at 9:00 AM, Jul 6 – Jul 10", "Tue every 2 weeks …".
 * [dates] are the dates it produces.
 */
export function seriesSummary(r: Pick<Recurrence, 'freq' | 'interval' | 'byWeekday'>, t: SeriesTimes, dates: string[]): string {
  const time = t.allDay || !t.startTime ? '' : ` at ${clockLabel(t.startTime)}`;
  if (dates.length === 1) {
    const day = format(dateMs(dates[0]), 'UTC', { weekday: 'short', month: 'short', day: 'numeric' });
    return `${day}${time}`;
  }
  const days =
    r.freq === 'daily'
      ? r.interval > 1
        ? `every ${r.interval} days`
        : 'daily'
      : `${weekdaysPhrase(r.byWeekday)}${r.interval > 1 ? ` every ${r.interval} weeks` : ''}`;
  const range = dates.length ? `, ${shortDate(dates[0])} – ${shortDate(dates[dates.length - 1])}` : '';
  return `${days}${time}${range}`;
}

/** "New: Practice, Tue and Thu at 6:00 PM, Oct 13 – Dec 17" (SCHED-3). */
export function seriesCreatedBody(title: string, summary: string): string {
  return `New: ${title.trim() || 'Event'}, ${summary}`;
}

/** "Practice changed: Mon and Wed at 6:00 PM, Oct 19 – Dec 16" (SCHED-6). */
export function seriesChangedBody(title: string, summary: string): string {
  return `${title.trim() || 'Event'} changed: ${summary}`;
}

/** "Canceled: Practice, 9 events from Tue, Oct 13" (SCHED-7). */
export function seriesCanceledBody(first: EventView, count: number): string {
  return count === 1 ? eventCanceledBody(first) : `Canceled: ${first.title}, ${count} events from ${eventDay(first)}`;
}

// ---- Reminders (SCHED-8) --------------------------------------------------

/**
 * When the next reminder is due: the earliest reminder time still after
 * [nowMs] - [graceMs], or null when the event is canceled, has no
 * reminders, or they've all passed.
 */
export function nextReminderAtMs(e: EventView, nowMs: number, graceMs = 0): number | null {
  if (e.canceled) return null;
  const times = e.reminderOffsets.map((o) => e.startMs - o * MINUTE_MS).filter((t) => t > nowMs - graceMs);
  return times.length ? Math.min(...times) : null;
}

/**
 * The reminder to send now: the latest one whose time has come, while the
 * event hasn't started. Older missed ones aren't sent on top of it.
 */
export function dueReminderOffset(e: EventView, nowMs: number): number | null {
  if (e.canceled || e.startMs <= nowMs) return null;
  const due = e.reminderOffsets.filter((o) => e.startMs - o * MINUTE_MS <= nowMs);
  return due.length ? Math.min(...due) : null;
}

/** One reminder per event, offset, and start time: moving the event allows it again. */
export function reminderDedupeKey(eventId: string, offset: number, startMs: number): string {
  return `${eventId}_r${offset}_${Math.floor(startMs / 1000)}`;
}

// ---- Who hears about an event (SCHED-6, SCHED-8, PLAYER-7) ----------------

/** What choosing an event's audience reads. */
export interface AudienceInput {
  members: { uid: string; admin: boolean }[];
  /** Player links; a missing relation is a guardian's. */
  links: { uid: string; playerId: string; relation?: string }[];
  /** Active players on the team, by ID (pending ones aren't on the roster). */
  playerNames: Map<string, string>;
  /** Each participant's answer, by participant ID. */
  statuses: Map<string, string>;
  /** 'change': the team minus Not going. 'reminder': only those taking part. */
  mode: 'change' | 'reminder';
}

/**
 * Who hears about an event, each with the players to name (PLAYER-7), the
 * same on every team. A member linked to players hears for the ones who
 * didn't say Not going: a guardian named per player, the player themselves
 * plainly ("You" when they're also a guardian there). Admins and members
 * not linked to any player go by their own answer (no answer counts).
 * Linked members all of whose players said Not going hear nothing, unless
 * they're admins who didn't say Not going themselves. [mode] is kept for
 * callers; both modes pick the same people now that everyone has an
 * answer of their own or their players'.
 */
export function audienceOf(a: AudienceInput): Map<string, string[]> {
  const out = new Map<string, string[]>();
  const live = (id: string) => a.statuses.get(id) !== 'not_going';
  const linksOf = new Map<string, { playerId: string; self: boolean }[]>();
  for (const l of a.links) {
    if (!a.playerNames.has(l.playerId)) continue;
    linksOf.set(l.uid, [...(linksOf.get(l.uid) ?? []), { playerId: l.playerId, self: l.relation === 'self' }]);
  }
  for (const m of a.members) {
    const links = linksOf.get(m.uid) ?? [];
    const liveLinks = links.filter((l) => live(l.playerId));
    const self = liveLinks.some((l) => l.self);
    const names = liveLinks
      .filter((l) => !l.self)
      .map((l) => a.playerNames.get(l.playerId)!)
      .sort((x, y) => x.localeCompare(y));
    if (names.length) out.set(m.uid, self ? ['You', ...names] : names);
    else if (self) out.set(m.uid, []);
    else if ((m.admin || !links.length) && live(m.uid)) out.set(m.uid, []);
  }
  return out;
}

/** First names, as the roster labels players (PLAYER-8). */
function firstName(name: string): string {
  return name.trim().split(/\s+/)[0] ?? name;
}

/** Reads what [audienceOf] needs for one event. */
export async function eventAudience(
  groupId: string,
  eventId: string,
  mode: AudienceInput['mode'],
): Promise<Map<string, string[]>> {
  const [members, rsvps, links, players] = await Promise.all([
    db().collection(Collections.groupMembers).where('groupId', '==', groupId).select('uid', 'role').get(),
    db().collection(Collections.rsvps).where('eventId', '==', eventId).select('participantId', 'status').get(),
    db().collection(Collections.playerGuardians).where('groupId', '==', groupId).select('uid', 'playerId', 'relation').get(),
    db().collection(Collections.players).where('groupId', '==', groupId).select('displayName', 'status').get(),
  ]);
  return audienceOf({
    mode,
    members: members.docs.map((d) => ({
      uid: String(d.get('uid')),
      admin: ['owner', 'admin'].includes(String(d.get('role'))),
    })),
    statuses: new Map(rsvps.docs.map((d) => [String(d.get('participantId')), String(d.get('status'))])),
    links: links.docs.map((d) => ({
      uid: String(d.get('uid')),
      playerId: String(d.get('playerId')),
      relation: d.get('relation') === 'self' ? 'self' : 'guardian',
    })),
    playerNames: new Map(
      players.docs
        .filter((d) => d.get('status') !== 'pending')
        .map((d) => [d.id, firstName(String(d.get('displayName') ?? ''))]),
    ),
  });
}

/** Where an event's notifications go (NOTIF-6). */
export function eventRoute(groupId: string, eventId: string): string {
  return `/g/${groupId}/schedule/e/${eventId}`;
}

/**
 * Sends [kind] about one event to its audience, naming each guardian's
 * players (PLAYER-7). [line] is the plain wording; [prefix] goes before it
 * for people with no players named.
 */
export async function notifyEventAudience(input: {
  kind: 'eventChanged' | 'eventReminder';
  groupId: string;
  eventId: string;
  event: EventView;
  mode: AudienceInput['mode'];
  line: (names: string[]) => string;
  actor: { uid: string; name: string } | null;
  dedupeKey: string;
}): Promise<string[]> {
  return trySend(async () => {
    const audience = await eventAudience(input.groupId, input.eventId, input.mode);
    if (!audience.size) return null;
    return {
      kind: input.kind,
      groupId: input.groupId,
      recipients: { uids: [...audience.keys()] },
      actor: input.actor,
      target: { type: 'event', id: input.eventId },
      route: eventRoute(input.groupId, input.eventId),
      params: { title: input.event.title },
      body: (uid: string) => input.line(audience.get(uid) ?? []),
      dedupeKey: input.dedupeKey,
    };
  });
}

// ---- Event cards in chat (CHAT-11) ----------------------------------------

/** A member's name and photo as messages carry them. */
export async function authorSnapshot(
  groupId: string,
  uid: string,
): Promise<{ authorName: string; authorPhotoPath: string | null; authorPlayerSummary: string | null }> {
  const m = await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid)).get();
  return {
    authorName: m.exists ? String(m.get('displayName') ?? '') : '',
    authorPhotoPath: m.exists ? ((m.get('photoPath') as string | null | undefined) ?? null) : null,
    authorPlayerSummary: m.exists ? ((m.get('playerSummary') as string | null | undefined) ?? null) : null,
  };
}

/**
 * Posts an event card in the team's chat, from the event's creator, with
 * the ID [messageId] (the event's or series' own ID), so a retried trigger
 * can't post twice. Message type 'event' carries eventId, and seriesId for
 * a series card. Returns false when it was already there.
 */
export async function postEventCard(card: {
  messageId: string;
  groupId: string;
  authorId: string;
  text: string;
  eventId: string;
  seriesId: string | null;
}): Promise<boolean> {
  const author = await authorSnapshot(card.groupId, card.authorId);
  try {
    await db()
      .collection(Collections.messages)
      .doc(card.messageId)
      .create({
        groupId: card.groupId,
        authorId: card.authorId,
        ...author,
        type: 'event',
        text: card.text,
        eventId: card.eventId,
        seriesId: card.seriesId,
        attachments: [],
        reactions: {},
        createdAt: FieldValue.serverTimestamp(),
      });
    return true;
  } catch (e) {
    if ((e as { code?: unknown }).code === ALREADY_EXISTS) return false;
    throw e;
  }
}

// ---- The events trigger ---------------------------------------------------

/** Fields whose change alone needs no follow-up: Functions write them. */
const QUIET_FIELDS = new Set(['rsvpCounts', 'staffCounts', 'nextReminderAt', 'messageId', 'updatedAt']);

function sameValue(a: unknown, b: unknown): boolean {
  if (a instanceof Timestamp || b instanceof Timestamp) {
    return a instanceof Timestamp && b instanceof Timestamp && a.isEqual(b);
  }
  return JSON.stringify(a ?? null) === JSON.stringify(b ?? null);
}

/** The fields that differ between two versions of a document. */
export function changedFields(before: DocumentData, after: DocumentData): string[] {
  const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
  return [...keys].filter((k) => !sameValue(before[k], after[k]));
}

/**
 * Whether an events write needs the trigger (ARCH §6.4 trigger map): not
 * when only counts, the reminder time, the card, or updatedAt changed, and
 * not for series events, which saveEventSeries follows up itself.
 * Deletes always do (their RSVPs go).
 */
export function eventNeedsFollowUp(before: DocumentData | undefined, after: DocumentData | undefined): boolean {
  if (!after) return before !== undefined;
  if (after.seriesId) return false;
  if (!before) return true;
  return changedFields(before, after).some((k) => !QUIET_FIELDS.has(k));
}

/** Deletes an event's RSVPs (the event was deleted). */
export async function deleteEventRsvps(eventIds: string[]): Promise<number> {
  let total = 0;
  for (const part of chunk(eventIds, 30)) {
    total += await forEachPage(db().collection(Collections.rsvps).where('eventId', 'in', part), (b, d) =>
      b.delete(d.ref),
    );
  }
  return total;
}

/** How many RSVPs [eventIds] have, for saveEventSeries' confirmation. */
export async function countEventRsvps(eventIds: string[]): Promise<number> {
  let total = 0;
  for (const part of chunk(eventIds, 30)) {
    const snap = await db().collection(Collections.rsvps).where('eventId', 'in', part).count().get();
    total += snap.data().count;
  }
  return total;
}

/** Keeps rsvps.eventStartAt (cache ← events) in step with moved events. */
export async function refreshRsvpStartTimes(startAtById: Map<string, Timestamp>): Promise<void> {
  for (const part of chunk([...startAtById.keys()], 30)) {
    const snap = await db().collection(Collections.rsvps).where('eventId', 'in', part).get();
    const stale = snap.docs.filter((d) => !sameValue(d.get('eventStartAt'), startAtById.get(String(d.get('eventId')))));
    for (const docs of chunk(stale, 400)) {
      const batch = db().batch();
      docs.forEach((d) => batch.update(d.ref, { eventStartAt: startAtById.get(String(d.get('eventId'))) }));
      await batch.commit();
    }
  }
}

/**
 * events written → the follow-up for one-off events (ARCH §6.4): on
 * create, the chat card (postToChat) and eventCreated (notifyTeam); on a
 * time or place change or a cancel, eventChanged to everyone but Not
 * going; on any change, nextReminderAt; on delete, the RSVPs. The card
 * stays when an event is deleted; the app shows it as deleted.
 */
export async function followUpEventWrite(
  eventId: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
  nowMs = Date.now(),
): Promise<void> {
  if (!eventNeedsFollowUp(before, after)) return;
  if (!after) {
    await deleteEventRsvps([eventId]);
    return;
  }
  const groupId = String(after.groupId);
  const view = eventView(after);
  const updates: Record<string, unknown> = {};
  if (!before) {
    const author = String(after.createdBy ?? '');
    if (after.postToChat !== false && !after.messageId && author) {
      await postEventCard({ messageId: eventId, groupId, authorId: author, text: eventCardText(view), eventId, seriesId: null });
      updates.messageId = eventId;
    }
    if (after.notifyTeam !== false && !view.canceled) {
      await trySend(async () => ({
        kind: 'eventCreated',
        groupId,
        recipients: { members: true },
        actor: { uid: author, name: (await authorSnapshot(groupId, author)).authorName },
        target: { type: 'event', id: eventId },
        route: eventRoute(groupId, eventId),
        params: { title: view.title },
        body: eventCreatedBody(view),
        dedupeKey: `${eventId}_created`,
      }));
    }
  } else {
    const was = eventView(before);
    if (was.startMs !== view.startMs && after.startAt instanceof Timestamp) {
      await refreshRsvpStartTimes(new Map([[eventId, after.startAt]]));
    }
    const line = eventChangedBody(was, view);
    if (line) {
      const canceledBy = typeof after.canceledBy === 'string' && view.canceled && !was.canceled ? after.canceledBy : null;
      await notifyEventAudience({
        kind: 'eventChanged',
        groupId,
        eventId,
        event: view,
        mode: 'change',
        line: (names) => withPlayers(names, line),
        actor: canceledBy ? { uid: canceledBy, name: '' } : null,
        dedupeKey: `${eventId}_changed_${msOf(after.updatedAt) || nowMs}`,
      });
    }
  }
  const ref = db().collection(Collections.events).doc(eventId);
  if (Object.keys(updates).length) {
    await ref.update(updates).catch((e) => logger.warn('event_follow_up_update_failed', { eventId, error: String(e) }));
  }
  await settleNextReminder(ref, null, nowMs, REMINDER_GRACE_MS).catch((e) =>
    logger.warn('event_follow_up_update_failed', { eventId, error: String(e) }),
  );
}

/**
 * Writes an event's nextReminderAt from a fresh read, in a transaction, so
 * a trigger that runs late or a tick racing an edit never stores a time
 * worked out from old data. [handled] is the version the tick just sent a
 * reminder for: when the start, reminders, or cancel have changed since,
 * the edit's own write already set the time, and this leaves it alone.
 */
export async function settleNextReminder(
  ref: FirebaseFirestore.DocumentReference,
  handled: EventView | null,
  nowMs: number,
  graceMs: number,
): Promise<void> {
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const data = snap.data()!;
    const view = eventView(data);
    if (handled && !sameReminderInputs(handled, view)) return;
    const next = nextReminderAtMs(view, nowMs, graceMs);
    if (msOf(data.nextReminderAt) === (next ?? 0)) return;
    tx.update(ref, { nextReminderAt: next === null ? null : Timestamp.fromMillis(next) });
  });
}

function sameReminderInputs(a: EventView, b: EventView): boolean {
  return a.startMs === b.startMs && a.canceled === b.canceled && JSON.stringify(a.reminderOffsets) === JSON.stringify(b.reminderOffsets);
}

/**
 * Sends the reminders that are due (SCHED-8), for the `tick` job. Reads
 * only due events through the nextReminderAt index (ARCH §10.2 rule 11),
 * then moves each one's nextReminderAt on to its next reminder, so it
 * leaves the query. Returns how many reminders went out.
 */
export async function sendDueReminders(now = Timestamp.now()): Promise<number> {
  const nowMs = now.toMillis();
  let sent = 0;
  for (;;) {
    const due = await db()
      .collection(Collections.events)
      .where('nextReminderAt', '<=', now)
      .orderBy('nextReminderAt')
      .limit(100)
      .get();
    for (const doc of due.docs) {
      try {
        const data = doc.data();
        const view = eventView(data);
        const offset = dueReminderOffset(view, nowMs);
        if (offset !== null) {
          await notifyEventAudience({
            kind: 'eventReminder',
            groupId: String(data.groupId),
            eventId: doc.id,
            event: view,
            mode: 'reminder',
            line: (names) => reminderBody(view, nowMs, names),
            actor: null,
            dedupeKey: reminderDedupeKey(doc.id, offset, view.startMs),
          });
          sent++;
        }
        await settleNextReminder(doc.ref, view, nowMs, 0);
      } catch (e) {
        logger.error('event_reminder_failed', { eventId: doc.id, error: String(e) });
        return sent; // Try the rest on the next tick rather than loop on it.
      }
    }
    if (due.size < 100) return sent;
  }
}

/**
 * A participant's RSVPs for upcoming events go; past ones stay: a deleted
 * account (AUTH-10) or a removed player (PLAYER-2). The RSVP trigger then
 * recounts each event.
 */
export async function removeUpcomingRsvps(participantId: string): Promise<void> {
  await forEachPage(
    db()
      .collection(Collections.rsvps)
      .where('participantId', '==', participantId)
      .where('eventStartAt', '>=', Timestamp.now()),
    (b, d) => b.delete(d.ref),
  );
}

/**
 * A member who becomes linked as a player answers on their player's row
 * from then on (PLAYER-6: the app stops offering them a Me row). Each of
 * their own answers ('member') to upcoming events on [groupId] moves to the
 * player's row when that row is empty, and is dropped when the player
 * already has an answer. Each changed event is recounted at once (the RSVP
 * trigger does it too). Returns how many answers were moved or dropped.
 */
export async function moveMemberRsvpsToPlayer(
  groupId: string,
  uid: string,
  player: { id: string; name: string },
): Promise<number> {
  const own = await db()
    .collection(Collections.rsvps)
    .where('groupId', '==', groupId)
    .where('participantId', '==', uid)
    .where('eventStartAt', '>=', Timestamp.now())
    .get();
  const events = new Set<string>();
  for (const answer of own.docs) {
    if (answer.get('participantType') !== 'member') continue;
    const eventId = String(answer.get('eventId'));
    const playerRef = db().collection(Collections.rsvps).doc(rsvpId(eventId, player.id));
    await db().runTransaction(async (tx) => {
      const [mine, theirs] = await Promise.all([tx.get(answer.ref), tx.get(playerRef)]);
      if (!mine.exists) return;
      if (!theirs.exists) {
        tx.set(playerRef, {
          ...mine.data(),
          participantType: 'player',
          participantId: player.id,
          participantName: player.name,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
      tx.delete(answer.ref);
    });
    events.add(eventId);
  }
  for (const eventId of events) await recountEventRsvps(eventId);
  return events.size;
}

/** Keeps rsvps.participantName (cache ← players) in step with a renamed player, on upcoming events. */
export async function renameUpcomingRsvps(participantId: string, name: string): Promise<void> {
  await forEachPage(
    db()
      .collection(Collections.rsvps)
      .where('participantId', '==', participantId)
      .where('eventStartAt', '>=', Timestamp.now()),
    (b, d) => {
      if (d.get('participantName') !== name) b.update(d.ref, { participantName: name });
    },
  );
}
