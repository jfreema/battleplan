// Importing a team's schedule from another app (SPEC IMPORT-1 to IMPORT-5,
// ARCH §6.13). GameChanger first: its schedule's calendar link, or a
// calendar file saved from it. Events only; RSVPs and attendance stay
// behind.
import { createHash } from 'node:crypto';
import { Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { audit } from '../audit/service.js';
import { chunk } from '../notify/service.js';
import { db } from '../shared/admin.js';
import { Collections, REMINDER_OFFSETS_MINUTES } from '../shared/constants.js';
import { consumeRateLimits } from '../shared/rate_limit.js';
import { requireTeamAdmin } from '../shared/roles.js';
import { isTimeZone } from '../schedule/recurrence.js';
import { REMINDER_GRACE_MS, ZERO_COUNTS, eventView, nextReminderAtMs } from '../schedule/service.js';
import { quotaBytesOf } from '../teams/storage.js';
import { eventsFromIcs, eventsFromList, type ImportedEvent, type ListedEvent, type SkippedEntry } from './events.js';
import { fetchCalendar } from './fetch.js';
import { parseIcs } from './ics.js';

/**
 * The apps events can come from: calendar links (IMPORT-7, IMPORT-8), and
 * GroupMe's export, which the app reads and sends as a list (IMPORT-9).
 */
export const importSources = ['gamechanger', 'teamreach', 'groupme'] as const;
export type ImportSource = (typeof importSources)[number];

/** At most this many new events in one import. */
export const MAX_IMPORTED_EVENTS = 500;
/** Imports (previews included) per team per day: each may fetch a link. */
export const IMPORTS_PER_TEAM_PER_DAY = 30;
/** Preview and report sizes. */
const SAMPLE = 50;
const SKIPPED_LISTED = 20;

export interface EventImportInput {
  groupId: string;
  source: ImportSource;
  /** The calendar link, or [ics]: the calendar file's text, or [events]. */
  url?: string;
  ics?: string;
  events?: ListedEvent[];
  includePast: boolean;
  /** Counts and samples, writing nothing (IMPORT-3). */
  dryRun: boolean;
}

export interface EventSample {
  title: string;
  type: string;
  allDay: boolean;
  startMs: number;
  startDate: string | null;
  timeZone: string;
  place: string;
}

export interface EventImportResult {
  /** New events: to add on a dry run, added otherwise. */
  added: number;
  /** Already brought in by an earlier import, left as they are. */
  alreadyImported: number;
  /** Ended before now, left out unless includePast. */
  past: number;
  skippedCount: number;
  skipped: { title: string; startMs: number | null; reason: string }[];
  /** The new events' first start and last start. */
  firstMs: number | null;
  lastMs: number | null;
  sample: EventSample[];
}

export interface Caller {
  uid: string;
  superAdmin: boolean;
}

/**
 * The event's ID in Battleplan: the same for the same team, source, and
 * entry, so importing again adds only what's new (IMPORT-5).
 */
export function importedEventId(groupId: string, source: ImportSource, sourceId: string): string {
  return 'imp-' + createHash('sha256').update(`${groupId}\n${source}\n${sourceId}`).digest('hex').slice(0, 28);
}

/**
 * The events collection's fields for an imported event, as the app writes
 * a new one-off event, with no chat card and no "new event" notification
 * (IMPORT-5): a season's worth at once would flood the chat. Reminders run
 * as for any event.
 */
export function eventDoc(e: ImportedEvent, groupId: string, createdBy: string, reminderOffsets: number[], nowMs: number): DocumentData {
  const now = Timestamp.fromMillis(nowMs);
  const data: DocumentData = {
    groupId,
    type: e.type,
    title: e.title,
    description: e.description,
    location: e.location,
    allDay: e.allDay,
    startAt: Timestamp.fromMillis(e.startMs),
    endAt: Timestamp.fromMillis(e.endMs),
    startDate: e.startDate,
    endDate: e.endDate,
    timeZone: e.timeZone,
    arriveMinutesBefore: null,
    opponent: e.opponent,
    homeAway: e.homeAway,
    rsvpEnabled: true,
    rsvpDeadline: null,
    reminderOffsets,
    notifyTeam: false,
    postToChat: false,
    rsvpCounts: ZERO_COUNTS,
    staffCounts: ZERO_COUNTS,
    seriesId: null,
    seriesDate: null,
    messageId: null,
    canceledAt: null,
    canceledBy: null,
    createdBy,
    createdAt: now,
    updatedAt: now,
  };
  const next = nextReminderAtMs(eventView(data), nowMs, REMINDER_GRACE_MS);
  return { ...data, nextReminderAt: next === null ? null : Timestamp.fromMillis(next) };
}

function placeOf(e: ImportedEvent): string {
  if (!e.location) return '';
  return [e.location.name, e.location.address].filter(Boolean).join(', ');
}

/** The team's own default reminders, if they're ones the app offers. */
function teamReminders(team: DocumentData | undefined): number[] {
  const offsets = team?.settings?.defaultReminderOffsets;
  if (!Array.isArray(offsets)) return [];
  const allowed = new Set<number>(REMINDER_OFFSETS_MINUTES);
  return [...new Set(offsets.filter((o): o is number => typeof o === 'number' && allowed.has(o)))].sort((a, b) => a - b);
}

/**
 * Previews ([EventImportInput.dryRun]) or imports a team's events from a
 * calendar link or file. Team admins (and super admins) only, on an open
 * team with room (STORE-4, as for any new event).
 */
export async function importEvents(
  input: EventImportInput,
  caller: Caller,
  nowMs = Date.now(),
  fetchText: (url: string) => Promise<string> = fetchCalendar,
): Promise<EventImportResult> {
  await requireTeamAdmin(input.groupId, caller.uid, caller.superAdmin);
  const teamRef = db().collection(Collections.groups).doc(input.groupId);
  const team = (await teamRef.get()).data();
  await consumeRateLimits([{ key: input.groupId, action: 'importEvents', max: IMPORTS_PER_TEAM_PER_DAY }]);

  const teamZone = typeof team?.timeZone === 'string' && isTimeZone(team.timeZone) ? team.timeZone : 'America/Chicago';
  const options = { teamTimeZone: teamZone, nowMs, includePast: input.includePast };
  let converted;
  if (input.events !== undefined) {
    converted = eventsFromList(input.events, options);
  } else {
    const text = input.url !== undefined ? await fetchText(input.url) : (input.ics ?? '');
    if (!/BEGIN:VCALENDAR/i.test(text)) throw new HttpsError('failed-precondition', 'not-a-calendar');
    converted = eventsFromIcs(parseIcs(text), options);
  }
  const { events, skipped, past } = converted;

  // Already here from an earlier import: by ID, so a repeat adds nothing twice.
  const refs = events.map((e) => db().collection(Collections.events).doc(importedEventId(input.groupId, input.source, e.sourceId)));
  const exists = new Set<string>();
  for (const part of chunk(refs, 300)) {
    const snaps = await db().getAll(...part);
    snaps.filter((s) => s.exists).forEach((s) => exists.add(s.id));
  }
  const fresh = events.filter((_, i) => !exists.has(refs[i].id));
  if (fresh.length > MAX_IMPORTED_EVENTS) throw new HttpsError('invalid-argument', 'too-many-events');

  const result: EventImportResult = {
    added: fresh.length,
    alreadyImported: events.length - fresh.length,
    past,
    skippedCount: skipped.length,
    skipped: skipped.slice(0, SKIPPED_LISTED).map((s: SkippedEntry) => ({ title: s.title, startMs: s.startMs, reason: s.reason })),
    firstMs: fresh.length ? fresh[0].startMs : null,
    lastMs: fresh.length ? fresh[fresh.length - 1].startMs : null,
    sample: fresh.slice(0, SAMPLE).map((e) => ({
      title: e.title,
      type: e.type,
      allDay: e.allDay,
      startMs: e.startMs,
      startDate: e.startDate,
      timeZone: e.timeZone,
      place: placeOf(e),
    })),
  };
  if (input.dryRun || !fresh.length) return result;

  // STORE-4: a full team can't schedule new events.
  if (!(Number(team?.storageBytes ?? 0) < quotaBytesOf(team))) throw new HttpsError('failed-precondition', 'storage-full');
  const reminders = teamReminders(team);
  for (const part of chunk(fresh, 400)) {
    const batch = db().batch();
    for (const e of part) {
      const ref = db().collection(Collections.events).doc(importedEventId(input.groupId, input.source, e.sourceId));
      batch.set(ref, eventDoc(e, input.groupId, caller.uid, reminders, nowMs));
    }
    await batch.commit();
  }
  await audit({
    actorId: caller.uid,
    action: 'importEvents',
    groupId: input.groupId,
    targetType: 'group',
    targetId: input.groupId,
    after: {
      source: input.source,
      from: input.url !== undefined ? 'link' : input.events !== undefined ? 'export' : 'file',
      added: result.added,
      alreadyImported: result.alreadyImported,
      past: result.past,
      skipped: result.skippedCount,
    },
  });
  return result;
}
