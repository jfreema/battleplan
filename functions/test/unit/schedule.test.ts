// Repeating events, wording, reminders, and who hears about an event
// (SPEC SCHED-3, SCHED-6 to SCHED-9, PLAYER-6, PLAYER-7, NOTIF-5).
import { Timestamp } from 'firebase-admin/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { lastMessagePreviewOf } from '../../src/chat/service.js';
import {
  addDays,
  dateInZone,
  expandDates,
  isDate,
  isoWeekday,
  lastAllowedDate,
  occurrenceOn,
  wallTimeToMs,
  type OccurrenceTimes,
  type Recurrence,
} from '../../src/schedule/recurrence.js';
import { followingRule, normalizeTemplate, SaveSeriesInput } from '../../src/schedule/series.js';
import {
  audienceOf,
  countsOf,
  dueReminderOffset,
  eventCanceledBody,
  eventCardText,
  eventChangedBody,
  eventCreatedBody,
  eventNeedsFollowUp,
  eventView,
  nextReminderAtMs,
  reminderBody,
  reminderDedupeKey,
  rsvpCountChanged,
  seriesCanceledBody,
  seriesChangedBody,
  seriesCreatedBody,
  seriesSummary,
  type EventView,
} from '../../src/schedule/service.js';

const rec = (r: Partial<Recurrence> & { startDate: string }): Recurrence => ({
  freq: 'weekly',
  interval: 1,
  byWeekday: [],
  untilDate: null,
  count: null,
  skipDates: [],
  ...r,
});
const iso = (ms: number) => new Date(ms).toISOString();
const CHI = 'America/Chicago';
const LON = 'Europe/London';

interface Vector {
  name: string;
  recurrence: Recurrence;
  times: OccurrenceTimes;
  expected: { date: string; startAt: string; endAt: string; startDate: string | null; endDate: string | null }[];
}

describe('shared series vectors (fixtures/series_vectors.json)', () => {
  const file = JSON.parse(readFileSync(resolve(process.cwd(), 'test/unit/fixtures/series_vectors.json'), 'utf8')) as {
    vectors: Vector[];
  };

  it('has vectors', () => expect(file.vectors.length).toBeGreaterThanOrEqual(8));

  for (const v of file.vectors) {
    it(v.name, () => {
      const got = expandDates(v.recurrence).map((date) => {
        const o = occurrenceOn(date, v.times);
        return { date, startAt: iso(o.startMs), endAt: iso(o.endMs), startDate: o.startDate, endDate: o.endDate };
      });
      expect(got).toEqual(v.expected);
    });
  }
});

describe('calendar dates', () => {
  it('validates, moves, and names weekdays', () => {
    expect(isDate('2026-02-29')).toBe(false);
    expect(isDate('2028-02-29')).toBe(true);
    expect(isDate('2026-1-01')).toBe(false);
    expect(addDays('2026-12-31', 1)).toBe('2027-01-01');
    expect(addDays('2026-03-01', -1)).toBe('2026-02-28');
    expect(isoWeekday('2026-10-12')).toBe(1); // Monday
    expect(isoWeekday('2026-10-18')).toBe(7); // Sunday
  });

  it('caps a series 12 months out, clamping month ends', () => {
    expect(lastAllowedDate('2026-10-13')).toBe('2027-10-13');
    expect(lastAllowedDate('2028-02-29')).toBe('2029-02-28');
    expect(lastAllowedDate('2026-01-31')).toBe('2027-01-31');
  });
});

describe('expandDates (SCHED-3)', () => {
  it('walks weekly days, never before the start date', () => {
    expect(expandDates(rec({ byWeekday: [2, 4], startDate: '2026-10-15', untilDate: '2026-10-22' }))).toEqual([
      '2026-10-15',
      '2026-10-20',
      '2026-10-22',
    ]);
  });

  it('counts every other week from the Monday of the first week', () => {
    // Starts on a Thursday; the Tuesday of week 1 is before the start.
    expect(expandDates(rec({ interval: 2, byWeekday: [2, 4], startDate: '2026-10-15', count: 5 }))).toEqual([
      '2026-10-15',
      '2026-10-27',
      '2026-10-29',
      '2026-11-10',
      '2026-11-12',
    ]);
  });

  it('ends on untilDate, inclusive', () => {
    const dates = expandDates(rec({ freq: 'daily', interval: 2, startDate: '2026-10-01', untilDate: '2026-10-09' }));
    expect(dates).toEqual(['2026-10-01', '2026-10-03', '2026-10-05', '2026-10-07', '2026-10-09']);
  });

  it('counts only kept dates, after skip dates', () => {
    const dates = expandDates(rec({ freq: 'daily', startDate: '2026-12-22', count: 3, skipDates: ['2026-12-24', '2026-12-25'] }));
    expect(dates).toEqual(['2026-12-22', '2026-12-23', '2026-12-26']);
  });

  it('drops skip dates with an end date too', () => {
    const dates = expandDates(rec({ byWeekday: [4], startDate: '2026-11-19', untilDate: '2026-12-03', skipDates: ['2026-11-26'] }));
    expect(dates).toEqual(['2026-11-19', '2026-12-03']);
  });

  it('stops 12 months after the start, whatever untilDate or count says', () => {
    const daily = expandDates(rec({ freq: 'daily', startDate: '2026-10-13', untilDate: '2028-01-01' }));
    expect(daily.at(-1)).toBe('2027-10-13');
    expect(daily).toHaveLength(366);
    const counted = expandDates(rec({ byWeekday: [1, 2, 3, 4, 5, 6, 7], startDate: '2026-10-13', count: 400 }));
    expect(counted).toHaveLength(366);
    expect(counted.at(-1)).toBe('2027-10-13');
  });

  it('produces nothing for a weekly rule without days, or an end before the start', () => {
    expect(expandDates(rec({ startDate: '2026-10-13', count: 3 }))).toEqual([]);
    expect(expandDates(rec({ freq: 'daily', startDate: '2026-10-13', untilDate: '2026-10-12' }))).toEqual([]);
  });
});

describe('wall-clock times across daylight saving (SCHED-3, SCHED-9)', () => {
  it('keeps 6 PM at 6 PM in Chicago when DST ends and starts', () => {
    expect(iso(wallTimeToMs('2026-10-29', '18:00', CHI))).toBe('2026-10-29T23:00:00.000Z'); // CDT
    expect(iso(wallTimeToMs('2026-11-03', '18:00', CHI))).toBe('2026-11-04T00:00:00.000Z'); // CST
    expect(iso(wallTimeToMs('2027-03-13', '18:00', CHI))).toBe('2027-03-14T00:00:00.000Z');
    expect(iso(wallTimeToMs('2027-03-15', '18:00', CHI))).toBe('2027-03-15T23:00:00.000Z');
  });

  it('keeps 6 PM at 6 PM in London when BST ends and starts', () => {
    expect(iso(wallTimeToMs('2026-10-24', '18:00', LON))).toBe('2026-10-24T17:00:00.000Z');
    expect(iso(wallTimeToMs('2026-10-26', '18:00', LON))).toBe('2026-10-26T18:00:00.000Z');
    expect(iso(wallTimeToMs('2027-03-27', '18:00', LON))).toBe('2027-03-27T18:00:00.000Z');
    expect(iso(wallTimeToMs('2027-03-29', '18:00', LON))).toBe('2027-03-29T17:00:00.000Z');
  });

  it('takes the first of a repeated hour and moves a skipped one ahead', () => {
    expect(iso(wallTimeToMs('2026-11-01', '01:30', CHI))).toBe('2026-11-01T06:30:00.000Z'); // 1:30 CDT
    expect(iso(wallTimeToMs('2026-10-25', '01:30', LON))).toBe('2026-10-25T00:30:00.000Z'); // 1:30 BST
    expect(iso(wallTimeToMs('2027-03-14', '02:30', CHI))).toBe('2027-03-14T08:30:00.000Z'); // 3:30 CDT
    expect(iso(wallTimeToMs('2027-03-28', '01:30', LON))).toBe('2027-03-28T01:30:00.000Z'); // 2:30 BST
  });

  it('reads the date back in the zone', () => {
    expect(dateInZone(Date.parse('2026-11-04T00:00:00Z'), CHI)).toBe('2026-11-03');
    expect(dateInZone(Date.parse('2026-11-04T00:00:00Z'), LON)).toBe('2026-11-04');
  });

  it('runs all-day events midnight to midnight, and late events into the next day', () => {
    const allDay = occurrenceOn('2026-11-01', { allDay: true, startTime: null, endTime: null, timeZone: CHI });
    expect(iso(allDay.startMs)).toBe('2026-11-01T05:00:00.000Z');
    expect(iso(allDay.endMs)).toBe('2026-11-02T06:00:00.000Z'); // 25 hours: DST ended
    expect([allDay.startDate, allDay.endDate]).toEqual(['2026-11-01', '2026-11-01']);
    const late = occurrenceOn('2026-10-13', { allDay: false, startTime: '22:00', endTime: '22:00', timeZone: CHI });
    expect(late.endMs - late.startMs).toBe(86_400_000);
  });
});

// ---- Wording ---------------------------------------------------------------

const view = (over: Partial<EventView> = {}): EventView => ({
  title: 'Practice',
  allDay: false,
  startMs: Date.parse('2026-10-13T23:00:00Z'), // Tue, Oct 13, 6:00 PM CDT
  endMs: Date.parse('2026-10-14T00:30:00Z'),
  startDate: null,
  timeZone: CHI,
  location: { name: 'Riverside Park', address: '1 River Rd' },
  reminderOffsets: [60, 1440],
  canceled: false,
  ...over,
});

describe('notification wording (NOTIF-5)', () => {
  it('words new, canceled, and card lines in the event zone', () => {
    expect(eventCreatedBody(view({ type: 'practice' }))).toBe('New practice: Practice · Tue Oct 13, 6:00 PM');
    expect(eventCanceledBody(view())).toBe('Canceled: Practice, Tue, Oct 13 at 6:00 PM');
    expect(eventCardText(view())).toBe('Practice · Tue, Oct 13 at 6:00 PM · Riverside Park');
    expect(eventCreatedBody(view({ timeZone: LON }))).toBe('New event: Practice · Wed Oct 14, 12:00 AM');
    // The SPEC's own example (NOTIF-5).
    const game = view({ type: 'game', title: 'vs. Eagles', startMs: Date.parse('2026-10-17T15:00:00Z') });
    expect(eventCreatedBody(game)).toBe('New game: vs. Eagles · Sat Oct 17, 10:00 AM');
  });

  it('never shifts an all-day event to another day', () => {
    const tournament = view({ title: 'Tournament', allDay: true, startDate: '2026-10-17', startMs: Date.parse('2026-10-17T05:00:00Z') });
    expect(eventCreatedBody(tournament)).toBe('New event: Tournament · Sat Oct 17');
  });

  it('says what changed (SCHED-6), or nothing for other edits', () => {
    const later = view({ startMs: Date.parse('2026-10-13T23:30:00Z'), endMs: Date.parse('2026-10-14T01:00:00Z') });
    expect(eventChangedBody(view(), later)).toBe('Practice moved to Tue, Oct 13 at 6:30 PM');
    const elsewhere = view({ location: { name: '', address: '9 Elm St' } });
    expect(eventChangedBody(view(), elsewhere)).toBe('Practice location changed: 9 Elm St');
    expect(eventChangedBody(view(), view({ location: null }))).toBe('Practice location removed');
    expect(eventChangedBody(view(), { ...later, location: { name: 'Field 3' } })).toBe(
      'Practice moved to Tue, Oct 13 at 6:30 PM · Field 3',
    );
    expect(eventChangedBody(view(), view({ endMs: Date.parse('2026-10-14T01:00:00Z') }))).toBe('Practice now ends at 8:00 PM');
    expect(eventChangedBody(view(), view({ title: 'Practice!' }))).toBeNull();
    expect(eventChangedBody(view(), view({ canceled: true }))).toBe('Canceled: Practice, Tue, Oct 13 at 6:00 PM');
    expect(eventChangedBody(view({ canceled: true }), view({ canceled: true, location: null }))).toBeNull();
  });

  it('words reminders as today, tomorrow, or the day, naming players for guardians (SCHED-8, PLAYER-7)', () => {
    const noon = Date.parse('2026-10-13T17:00:00Z');
    expect(reminderBody(view(), noon)).toBe('Reminder: Practice today at 6:00 PM · Riverside Park');
    expect(reminderBody(view(), noon - 86_400_000)).toBe('Reminder: Practice tomorrow at 6:00 PM · Riverside Park');
    expect(reminderBody(view(), noon - 3 * 86_400_000)).toBe('Reminder: Practice on Tue, Oct 13 at 6:00 PM · Riverside Park');
    expect(reminderBody(view({ location: null }), noon, ['Emma', 'Liam'])).toBe('Emma, Liam: Practice today at 6:00 PM');
    // 11 PM Monday in Chicago is already Tuesday in UTC; the day follows the event zone.
    expect(reminderBody(view(), Date.parse('2026-10-13T04:00:00Z'))).toContain('tomorrow');
  });

  it('sums up a series (SCHED-3)', () => {
    const times = { allDay: false, startTime: '18:00', timeZone: CHI };
    const dates = expandDates(rec({ byWeekday: [2, 4], startDate: '2026-10-13', untilDate: '2026-12-17' }));
    const summary = seriesSummary({ freq: 'weekly', interval: 1, byWeekday: [4, 2] }, times, dates);
    expect(summary).toBe('Tue and Thu at 6:00 PM, Oct 13 – Dec 17');
    expect(seriesCreatedBody('Practice', summary)).toBe('New: Practice, Tue and Thu at 6:00 PM, Oct 13 – Dec 17');
    expect(seriesChangedBody('Practice', summary)).toBe('Practice changed: Tue and Thu at 6:00 PM, Oct 13 – Dec 17');
    expect(seriesSummary({ freq: 'weekly', interval: 2, byWeekday: [1, 3, 5] }, times, ['2026-10-12', '2026-10-30'])).toBe(
      'Mon, Wed, and Fri every 2 weeks at 6:00 PM, Oct 12 – Oct 30',
    );
    expect(seriesSummary({ freq: 'daily', interval: 1, byWeekday: [] }, { ...times, startTime: '09:00' }, ['2026-07-06', '2026-07-10'])).toBe(
      'daily at 9:00 AM, Jul 6 – Jul 10',
    );
    expect(seriesSummary({ freq: 'daily', interval: 3, byWeekday: [] }, { allDay: true, startTime: null, timeZone: CHI }, ['2026-07-06', '2026-07-12'])).toBe(
      'every 3 days, Jul 6 – Jul 12',
    );
    expect(seriesSummary({ freq: 'daily', interval: 1, byWeekday: [] }, times, ['2026-10-13'])).toBe('Tue, Oct 13 at 6:00 PM');
    expect(seriesCanceledBody(view(), 9)).toBe('Canceled: Practice, 9 events from Tue, Oct 13');
    expect(seriesCanceledBody(view(), 1)).toBe('Canceled: Practice, Tue, Oct 13 at 6:00 PM');
  });

  it('previews an event card in the switcher', () => {
    expect(lastMessagePreviewOf({ authorName: 'Alex', type: 'event', text: 'Practice · Tue, Oct 13 at 6:00 PM' }).text).toBe(
      'Event: Practice · Tue, Oct 13 at 6:00 PM',
    );
    expect(lastMessagePreviewOf({ authorName: 'Alex', type: 'event', text: '' }).text).toBe('Event');
  });

  it('reads an event document', () => {
    const v = eventView({
      title: ' ',
      startAt: Timestamp.fromMillis(1000),
      endAt: Timestamp.fromMillis(2000),
      canceledAt: Timestamp.now(),
      reminderOffsets: [15, 'x'],
    });
    expect(v).toMatchObject({ title: 'Event', startMs: 1000, endMs: 2000, canceled: true, reminderOffsets: [15], timeZone: 'UTC' });
  });
});

describe('reminders (SCHED-8)', () => {
  const start = view().startMs;
  const min = 60_000;

  it('finds the next reminder still ahead', () => {
    expect(nextReminderAtMs(view(), start - 2 * 86_400_000)).toBe(start - 1440 * min);
    expect(nextReminderAtMs(view(), start - 1440 * min)).toBe(start - 60 * min);
    expect(nextReminderAtMs(view(), start - 30 * min)).toBeNull();
    expect(nextReminderAtMs(view({ canceled: true }), start - 2 * 86_400_000)).toBeNull();
    expect(nextReminderAtMs(view({ reminderOffsets: [] }), 0)).toBeNull();
  });

  it('keeps a just-due reminder within the grace', () => {
    expect(nextReminderAtMs(view(), start - 58 * min, 5 * min)).toBe(start - 60 * min);
    expect(nextReminderAtMs(view(), start - 50 * min, 5 * min)).toBeNull();
  });

  it('sends the latest due reminder, only before the start', () => {
    expect(dueReminderOffset(view(), start - 2000 * min)).toBeNull();
    expect(dueReminderOffset(view(), start - 1440 * min)).toBe(1440);
    expect(dueReminderOffset(view(), start - 10 * min)).toBe(60);
    expect(dueReminderOffset(view(), start)).toBeNull();
    expect(dueReminderOffset(view({ canceled: true }), start - 10 * min)).toBeNull();
  });

  it("says tomorrow by the calendar, the evening before a spring-forward day", () => {
    // Sun, Mar 8, 2026 is 23 hours long in Chicago: 1:00 AM CST is 07:00Z.
    const early = view({ startMs: Date.parse('2026-03-08T07:00:00Z'), endMs: Date.parse('2026-03-08T08:00:00Z'), location: null });
    // Sat, Mar 7, 11:00 PM CST: now + 24 h is already Mar 9.
    expect(reminderBody(early, Date.parse('2026-03-08T05:00:00Z'))).toBe('Reminder: Practice tomorrow at 1:00 AM');
    // And the evening before a fall-back day (25 hours long).
    const fall = view({ startMs: Date.parse('2026-11-01T23:30:00Z'), endMs: Date.parse('2026-11-02T00:30:00Z'), location: null });
    expect(reminderBody(fall, Date.parse('2026-11-01T04:30:00Z'))).toBe('Reminder: Practice tomorrow at 5:30 PM');
  });

  it('dedupes per offset and start time', () => {
    expect(reminderDedupeKey('e1', 60, 1_700_000_000_500)).toBe('e1_r60_1700000000');
  });
});

describe('counts (SCHED-1, PLAYER-6)', () => {
  const rows = [
    { participantType: 'member', status: 'going' },
    { participantType: 'member', status: 'maybe' },
    { participantType: 'player', status: 'going' },
    { participantType: 'player', status: 'not_going' },
    { participantType: 'player', status: 'bogus' },
  ];

  it('counts players, and everyone else apart, on every event (D34)', () => {
    expect(countsOf(rows)).toEqual({
      rsvpCounts: { going: 1, maybe: 0, notGoing: 1 },
      staffCounts: { going: 1, maybe: 1, notGoing: 0 },
    });
  });

  it('counts members apart on an old adult event too: rsvpFor is gone', () => {
    // An old 'members' event's answers are all members' own: "others".
    expect(countsOf(rows.filter((r) => r.participantType === 'member'))).toEqual({
      rsvpCounts: { going: 0, maybe: 0, notGoing: 0 },
      staffCounts: { going: 1, maybe: 1, notGoing: 0 },
    });
  });

  it('recounts only when the answer changed', () => {
    const r = { status: 'going', participantType: 'member', note: '' };
    expect(rsvpCountChanged(r, { ...r, note: 'Late' })).toBe(false);
    expect(rsvpCountChanged(r, { ...r, eventStartAt: 1 })).toBe(false);
    expect(rsvpCountChanged(r, { ...r, status: 'maybe' })).toBe(true);
    expect(rsvpCountChanged(undefined, r)).toBe(true);
    expect(rsvpCountChanged(r, undefined)).toBe(true);
  });
});

describe('events trigger early exit (ARCH §6.4)', () => {
  const base = { groupId: 'g', title: 'Practice', startAt: Timestamp.fromMillis(1000), rsvpCounts: { going: 0 } };

  it('skips changes only Functions make', () => {
    expect(eventNeedsFollowUp(base, { ...base, rsvpCounts: { going: 1 } })).toBe(false);
    expect(eventNeedsFollowUp(base, { ...base, staffCounts: { going: 1 }, nextReminderAt: Timestamp.now() })).toBe(false);
    expect(eventNeedsFollowUp(base, { ...base, messageId: 'e1', updatedAt: Timestamp.now() })).toBe(false);
    expect(eventNeedsFollowUp(base, { ...base, startAt: Timestamp.fromMillis(1000) })).toBe(false);
  });

  it('follows up creates, real edits, and deletes', () => {
    expect(eventNeedsFollowUp(undefined, base)).toBe(true);
    expect(eventNeedsFollowUp(base, { ...base, title: 'Scrimmage' })).toBe(true);
    expect(eventNeedsFollowUp(base, { ...base, startAt: Timestamp.fromMillis(2000) })).toBe(true);
    expect(eventNeedsFollowUp(base, undefined)).toBe(true);
    expect(eventNeedsFollowUp(undefined, undefined)).toBe(false);
  });

  it('leaves series events to saveEventSeries', () => {
    const series = { ...base, seriesId: 's1' };
    expect(eventNeedsFollowUp(undefined, series)).toBe(false);
    expect(eventNeedsFollowUp(series, { ...series, title: 'Scrimmage' })).toBe(false);
  });
});

describe('who hears about an event (SCHED-6, SCHED-8, PLAYER-7, Q14)', () => {
  const members = [
    { uid: 'coach', coach: true },
    { uid: 'maria', coach: false },
    { uid: 'dan', coach: false },
    { uid: 'aunt', coach: false },
  ];
  const links = [
    { uid: 'maria', playerId: 'emma' },
    { uid: 'maria', playerId: 'liam', relation: 'guardian' },
    { uid: 'dan', playerId: 'ava' },
  ];
  const playerNames = new Map([['emma', 'Emma'], ['liam', 'Liam'], ['ava', 'Ava']]);
  const sorted = (m: Map<string, string[]>) => Object.fromEntries([...m.entries()].sort());

  it('with no player links: everyone but Not going, no answer counting', () => {
    const statuses = new Map([['maria', 'not_going'], ['dan', 'maybe']]);
    for (const mode of ['change', 'reminder'] as const) {
      expect(sorted(audienceOf({ members, links: [], playerNames, statuses, mode }))).toEqual({
        aunt: [],
        coach: [],
        dan: [],
      });
    }
  });

  it('guardians named per player still coming; coaches and unlinked members by their own answer', () => {
    const statuses = new Map([['liam', 'not_going'], ['ava', 'not_going'], ['coach', 'going']]);
    for (const mode of ['change', 'reminder'] as const) {
      // Dan's only player said Not going; the aunt isn't linked and didn't say Not going.
      expect(sorted(audienceOf({ members, links, playerNames, statuses, mode }))).toEqual({
        aunt: [],
        coach: [],
        maria: ['Emma'],
      });
    }
    expect(audienceOf({ members, links, playerNames, statuses: new Map([['aunt', 'not_going']]), mode: 'reminder' }).has('aunt')).toBe(false);
  });

  it('a member who is the player hears plainly, by the player\'s answer, not their own', () => {
    const asPlayer = [...links, { uid: 'aunt', playerId: 'zoe', relation: 'self' }];
    const names = new Map([...playerNames, ['zoe', 'Zoe']]);
    expect(audienceOf({ members, links: asPlayer, playerNames: names, statuses: new Map(), mode: 'reminder' }).get('aunt')).toEqual([]);
    // Zoe said Not going: the aunt hears nothing, whatever she said herself.
    const out = audienceOf({
      members,
      links: asPlayer,
      playerNames: names,
      statuses: new Map([['zoe', 'not_going'], ['aunt', 'going']]),
      mode: 'change',
    });
    expect(out.has('aunt')).toBe(false);
  });

  it('a player who is also a guardian hears "You" and their players', () => {
    const both = [...links, { uid: 'dan', playerId: 'dad', relation: 'self' }];
    const names = new Map([...playerNames, ['dad', 'Dan']]);
    expect(audienceOf({ members, links: both, playerNames: names, statuses: new Map(), mode: 'reminder' }).get('dan')).toEqual(['You', 'Ava']);
  });

  it('ignores links to players not on the roster (pending or removed)', () => {
    const pending = [{ uid: 'aunt', playerId: 'pending1', relation: 'self' }];
    // The aunt counts as unlinked, so her own answer decides.
    expect(audienceOf({ members, links: pending, playerNames, statuses: new Map(), mode: 'reminder' }).get('aunt')).toEqual([]);
  });

  it('leaves out a coach who said Not going, unless they guard a player who is coming', () => {
    const statuses = new Map([['coach', 'not_going']]);
    const asGuardian = [...links, { uid: 'coach', playerId: 'ava' }];
    expect(audienceOf({ members, links, playerNames, statuses, mode: 'change' }).has('coach')).toBe(false);
    expect(audienceOf({ members, links: asGuardian, playerNames, statuses, mode: 'reminder' }).get('coach')).toEqual(['Ava']);
  });

  it("a parent who isn't a coach goes by their players only, even an admin (PLAYER-6)", () => {
    // Maria's players both said Not going: she hears nothing, whatever her
    // role, as she has no answer of her own to give.
    const statuses = new Map([['emma', 'not_going'], ['liam', 'not_going']]);
    expect(audienceOf({ members, links, playerNames, statuses, mode: 'reminder' }).has('maria')).toBe(false);
    // Made a coach, she goes by her own answer too.
    const asCoach = members.map((m) => (m.uid === 'maria' ? { ...m, coach: true } : m));
    expect(audienceOf({ members: asCoach, links, playerNames, statuses, mode: 'reminder' }).get('maria')).toEqual([]);
  });

  it('names both players with no answers yet, alphabetically', () => {
    const out = audienceOf({ members, links, playerNames, statuses: new Map(), mode: 'reminder' });
    expect(out.get('maria')).toEqual(['Emma', 'Liam']);
  });
});

describe('saveEventSeries input', () => {
  const template = {
    type: 'practice',
    title: 'Practice',
    allDay: false,
    startTime: '18:00',
    endTime: '19:30',
    timeZone: CHI,
    reminderOffsets: [60],
  };
  const recurrence = { freq: 'weekly', interval: 1, byWeekday: [2, 4], startDate: '2026-10-13', untilDate: '2026-12-17' };
  const ok = (data: unknown) => SaveSeriesInput.safeParse(data).success;

  it('takes a create with defaults filled in', () => {
    const parsed = SaveSeriesInput.parse({ action: 'create', groupId: 'g', recurrence, template });
    expect(parsed).toMatchObject({ dryRun: false, template: { notifyTeam: true, postToChat: true, description: '' } });
  });

  it('refuses bad rules and templates', () => {
    expect(ok({ action: 'create', groupId: 'g', recurrence: { ...recurrence, count: 5 }, template })).toBe(false);
    expect(ok({ action: 'create', groupId: 'g', recurrence: { ...recurrence, untilDate: null }, template })).toBe(false);
    expect(ok({ action: 'create', groupId: 'g', recurrence: { ...recurrence, byWeekday: [] }, template })).toBe(false);
    expect(ok({ action: 'create', groupId: 'g', recurrence: { ...recurrence, interval: 9 }, template })).toBe(false);
    expect(ok({ action: 'create', groupId: 'g', recurrence: { ...recurrence, startDate: '2026-02-30' }, template })).toBe(false);
    expect(ok({ action: 'create', groupId: 'g', recurrence: { ...recurrence, untilDate: '2026-10-01' }, template })).toBe(false);
    expect(ok({ action: 'create', groupId: 'g', recurrence, template: { ...template, timeZone: 'Mars/Base' } })).toBe(false);
    expect(ok({ action: 'create', groupId: 'g', recurrence, template: { ...template, reminderOffsets: [30] } })).toBe(false);
    expect(ok({ action: 'create', groupId: 'g', recurrence, template: { ...template, reminderOffsets: [60, 60] } })).toBe(false);
    expect(ok({ action: 'create', groupId: 'g', recurrence, template: { ...template, endTime: null } })).toBe(false);
    expect(ok({ action: 'create', groupId: 'g', recurrence, template: { ...template, title: '  ' } })).toBe(false);
    expect(ok({ action: 'create', groupId: 'g', recurrence, template: { ...template, location: { name: '', address: '' } } })).toBe(false);
    expect(ok({ action: 'cancel', eventId: 'e1', scope: 'all' })).toBe(false);
    expect(ok({ action: 'delete', eventId: 'e1', scope: 'following', dryRun: true })).toBe(true);
  });

  it('keeps game fields to games and times off all-day events', () => {
    const parsed = SaveSeriesInput.parse({
        action: 'create',
        groupId: 'g',
        recurrence,
      template: { ...template, allDay: true, opponent: 'Eagles', homeAway: 'home', arriveMinutesBefore: 30 },
    });
    if (parsed.action !== 'create') throw new Error('expected a create');
    const t = normalizeTemplate(parsed.template);
    expect(t).toMatchObject({ startTime: null, endTime: null, opponent: null, homeAway: null, arriveMinutesBefore: null });
  });
});

describe('"This and following" on a series that ends after N events (SCHED-6)', () => {
  // Daily from Oct 1, 10 events: Oct 1 to Oct 10.
  const old = rec({ freq: 'daily', startDate: '2026-10-01', count: 10 });

  it('keeps the total the app sends: N minus the dates before the edit', () => {
    const r = followingRule(old, { ...old, startDate: '2026-10-05' }, '2026-10-05');
    expect(r).toMatchObject({ startDate: '2026-10-05', count: 6 });
    expect(expandDates(r)).toEqual(['2026-10-05', '2026-10-06', '2026-10-07', '2026-10-08', '2026-10-09', '2026-10-10']);
  });

  it('counts the old dates after skip dates, and with no rule sent', () => {
    // Oct 3 was deleted, so the series runs to Oct 10 with count 9.
    const skipped = { ...old, count: 9, skipDates: ['2026-10-03'] };
    expect(followingRule(skipped, { ...skipped, startDate: '2026-10-05' }, '2026-10-05').count).toBe(6);
    expect(followingRule(skipped, undefined, '2026-10-05')).toMatchObject({ startDate: '2026-10-05', count: 6 });
  });

  it('applies the rest to a new rule, never below 1, and leaves end dates alone', () => {
    const weekly = rec({ startDate: '2026-10-05', byWeekday: [1, 3], count: 10 });
    expect(followingRule(old, weekly, '2026-10-05').count).toBe(6);
    expect(followingRule(old, { ...old, count: 2 }, '2026-10-08').count).toBe(1);
    const until = rec({ freq: 'daily', startDate: '2026-10-01', untilDate: '2026-10-20' });
    expect(followingRule(old, until, '2026-10-05')).toMatchObject({ startDate: '2026-10-05', untilDate: '2026-10-20', count: null });
  });
});
