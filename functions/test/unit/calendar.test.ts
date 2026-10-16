// Calendar links' iCalendar (SPEC SCHED-11, ARCH §6.15): text escapes,
// line folding, times and all-day dates, titles and notes, and a round trip
// through the import parser, plus which event changes refresh a team's copy.
import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';
import {
  buildCalendar,
  feedNotes,
  feedPlace,
  feedTitle,
  foldLine,
  icsDate,
  icsText,
  icsTime,
  type FeedEvent,
} from '../../src/calendar/ics.js';
import {
  CALENDAR_TOKEN,
  calendarChanged,
  calendarEventOf,
  feedToken,
  newCalendarToken,
} from '../../src/calendar/service.js';
import { parseIcs } from '../../src/imports/ics.js';

const START = Date.UTC(2026, 9, 21, 23, 0); // Wed Oct 21, 6:00 PM in Chicago
const event = (extra: Partial<FeedEvent> = {}): FeedEvent => ({
  id: 'e1',
  title: 'Practice',
  type: 'practice',
  allDay: false,
  startMs: START,
  endMs: START + 90 * 60_000,
  startDate: null,
  endDate: null,
  location: { name: 'Riverside Park', address: '1 Park Rd, Springfield' },
  description: '',
  arriveMinutesBefore: null,
  canceled: false,
  updatedMs: Date.UTC(2026, 9, 1, 12, 0),
  team: null,
  url: 'https://getbattleplan.app/app/g/t1/schedule/e/e1',
  ...extra,
});

describe('iCalendar text', () => {
  it('escapes what RFC 5545 reserves', () => {
    expect(icsText('Bring cones, balls; and\\ water\nAt 6')).toBe('Bring cones\\, balls\\; and\\\\ water\\nAt 6');
  });

  it('folds long lines at 75 octets without splitting a character', () => {
    const short = 'SUMMARY:Practice';
    expect(foldLine(short)).toBe(short);
    const long = `DESCRIPTION:${'é'.repeat(60)}🏟️${'x'.repeat(40)}`;
    const folded = foldLine(long);
    const pieces = folded.split('\r\n');
    expect(pieces.length).toBeGreaterThan(1);
    pieces.forEach((p, i) => {
      expect(Buffer.byteLength(p, 'utf8')).toBeLessThanOrEqual(75);
      if (i > 0) expect(p.startsWith(' ')).toBe(true);
    });
    // Unfolding gives back the line, every character whole.
    expect(pieces.map((p, i) => (i === 0 ? p : p.slice(1))).join('')).toBe(long);
  });

  it('writes UTC times and dates, the day after the last as an all-day end', () => {
    expect(icsTime(START)).toBe('20261021T230000Z');
    expect(icsDate('2026-12-31')).toBe('20261231');
    expect(icsDate('2026-12-31', 1)).toBe('20270101');
  });
});

describe('what an event shows', () => {
  it('marks canceled events, and puts the team first on a link for all teams', () => {
    expect(feedTitle(event())).toBe('Practice');
    expect(feedTitle(event({ canceled: true }))).toBe('Canceled: Practice');
    expect(feedTitle(event({ team: 'Thunder', title: 'vs. Eagles' }))).toBe('Thunder · vs. Eagles');
    expect(feedTitle(event({ team: 'Thunder', canceled: true }))).toBe('Canceled: Thunder · Practice');
  });

  it("gives the place's name and address once", () => {
    expect(feedPlace(null)).toBe('');
    expect(feedPlace({ name: 'Riverside Park', address: '' })).toBe('Riverside Park');
    expect(feedPlace({ name: '', address: '1 Park Rd' })).toBe('1 Park Rd');
    expect(feedPlace({ name: 'Riverside Park', address: '1 Park Rd' })).toBe('Riverside Park, 1 Park Rd');
    expect(feedPlace({ name: 'Riverside Park', address: 'Riverside Park, 1 Park Rd' })).toBe('Riverside Park, 1 Park Rd');
  });

  it('notes the arrival time for games, the notes, and the way back to the app', () => {
    expect(feedNotes(event({ type: 'game', arriveMinutesBefore: 45, description: 'White jerseys.' }))).toBe(
      'Arrive 45 minutes early.\n\nWhite jerseys.\n\nOpen in Battleplan: https://getbattleplan.app/app/g/t1/schedule/e/e1',
    );
    expect(feedNotes(event())).toBe('Open in Battleplan: https://getbattleplan.app/app/g/t1/schedule/e/e1');
  });
});

describe('a whole calendar', () => {
  const now = Date.UTC(2026, 9, 16, 15, 0);
  const text = buildCalendar(
    'Thunder',
    [
      event(),
      event({
        id: 'e2',
        title: 'Tournament, day one; bring lunch',
        allDay: true,
        startDate: '2026-11-07',
        endDate: '2026-11-08',
        location: null,
        canceled: true,
      }),
    ],
    now,
  );

  it('is RFC 5545: CRLF lines, a named calendar that asks for hourly checks', () => {
    expect(text.endsWith('\r\n')).toBe(true);
    expect(text.split('\r\n').every((l) => Buffer.byteLength(l, 'utf8') <= 75)).toBe(true);
    expect(text).toContain('X-WR-CALNAME:Thunder\r\n');
    expect(text).toContain('REFRESH-INTERVAL;VALUE=DURATION:PT1H\r\n');
    expect(text).toContain('X-PUBLISHED-TTL:PT1H\r\n');
    expect(text).toContain('UID:e1@getbattleplan.app\r\n');
    expect(text).toContain('DTSTART;VALUE=DATE:20261107\r\n');
    expect(text).toContain('DTEND;VALUE=DATE:20261109\r\n');
    expect(text).toContain('STATUS:CANCELLED\r\n');
  });

  it('reads back as written', () => {
    const cal = parseIcs(text);
    expect(cal.name).toBe('Thunder');
    expect(cal.events).toHaveLength(2);
    const [practice, tournament] = cal.events;
    expect(practice.summary).toBe('Practice');
    expect(practice.location).toBe('Riverside Park, 1 Park Rd, Springfield');
    expect(practice.start).toEqual({ kind: 'utc', ms: START });
    expect(practice.end).toEqual({ kind: 'utc', ms: START + 90 * 60_000 });
    expect(practice.status).toBe('CONFIRMED');
    expect(tournament.summary).toBe('Canceled: Tournament, day one; bring lunch');
    expect(tournament.start).toEqual({ kind: 'date', date: '2026-11-07' });
    expect(tournament.end).toEqual({ kind: 'date', date: '2026-11-09' });
    expect(tournament.status).toBe('CANCELLED');
  });

  it('is an empty calendar with no events, so calendars drop a team you left', () => {
    const empty = parseIcs(buildCalendar('Thunder', [], now));
    expect(empty.events).toHaveLength(0);
    expect(empty.name).toBe('Thunder');
  });
});

describe('links and the team copy', () => {
  it('makes 43-character base64url tokens and finds them in the path', () => {
    const token = newCalendarToken();
    expect(token).toMatch(CALENDAR_TOKEN);
    expect(feedToken(`/cal/${token}.ics`)).toBe(token);
    expect(feedToken(`/cal/${token}`)).toBe(token);
    expect(feedToken(`/${token}.ics`)).toBe(token);
    expect(feedToken('/cal/short.ics')).toBeNull();
    expect(feedToken(`/cal/${token}.ics/extra`)).toBeNull();
  });

  it('refreshes for added, deleted, and printed changes, not counts or series or imports', () => {
    const base = { groupId: 't1', title: 'Practice', startAt: Timestamp.fromMillis(START), rsvpCounts: { going: 1 } };
    expect(calendarChanged('e1', undefined, base)).toBe(true);
    expect(calendarChanged('e1', base, undefined)).toBe(true);
    expect(calendarChanged('e1', base, { ...base, title: 'Late practice' })).toBe(true);
    expect(calendarChanged('e1', base, { ...base, startAt: Timestamp.fromMillis(START + 3_600_000) })).toBe(true);
    expect(calendarChanged('e1', base, { ...base, canceledAt: Timestamp.now() })).toBe(true);
    expect(calendarChanged('e1', base, { ...base, rsvpCounts: { going: 2 }, nextReminderAt: Timestamp.now() })).toBe(false);
    expect(calendarChanged('e1', { ...base, seriesId: 's1' }, { ...base, seriesId: 's1', title: 'Moved' })).toBe(false);
    expect(calendarChanged('imp-abc', undefined, base)).toBe(false);
    expect(calendarChanged('imp-abc', base, { ...base, title: 'Edited after import' })).toBe(true);
  });

  it("keeps what a feed prints, and a game's arrival time only", () => {
    const doc = {
      title: ' vs. Eagles ',
      type: 'game',
      allDay: false,
      startAt: Timestamp.fromMillis(START),
      endAt: Timestamp.fromMillis(START + 7_200_000),
      location: { name: 'Field 3', address: '' },
      description: 'White jerseys',
      arriveMinutesBefore: 30,
      canceledAt: null,
      updatedAt: Timestamp.fromMillis(START - 1000),
      rsvpCounts: { going: 4 },
    };
    expect(calendarEventOf('e9', doc)).toEqual({
      id: 'e9',
      title: 'vs. Eagles',
      type: 'game',
      allDay: false,
      startMs: START,
      endMs: START + 7_200_000,
      startDate: null,
      endDate: null,
      location: { name: 'Field 3', address: '' },
      description: 'White jerseys',
      arriveMinutesBefore: 30,
      canceled: false,
      updatedMs: START - 1000,
    });
    expect(calendarEventOf('e9', { ...doc, type: 'practice' }).arriveMinutesBefore).toBeNull();
  });
});
