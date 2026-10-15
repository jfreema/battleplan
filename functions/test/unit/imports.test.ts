// Importing events from a calendar (SPEC IMPORT-1 to IMPORT-5): reading
// iCalendar, turning entries into events, and which links may be fetched.
import { describe, expect, it } from 'vitest';
import { calendarUrl, fetchCalendar, isPublicAddress } from '../../src/imports/fetch.js';
import { classify, eventsFromIcs, ianaZone, parseRule, ruleDates, splitLocation } from '../../src/imports/events.js';
import { parseDuration, parseIcs, parseIcsTime, unescapeText } from '../../src/imports/ics.js';
import { addDays } from '../../src/schedule/recurrence.js';

const CHI = 'America/Chicago';
const NOW = Date.parse('2030-10-10T12:00:00Z');

/** A season as a GameChanger-style feed might give it. */
const FEED = [
  'BEGIN:VCALENDAR',
  'VERSION:2.0',
  'PRODID:-//GameChanger//Team Schedule//EN',
  'X-WR-CALNAME:Thunder 12U',
  'X-WR-TIMEZONE:America/Chicago',
  'BEGIN:VTIMEZONE',
  'TZID:America/Chicago',
  'BEGIN:STANDARD',
  'DTSTART:19701101T020000',
  'TZOFFSETFROM:-0500',
  'TZOFFSETTO:-0600',
  'END:STANDARD',
  'END:VTIMEZONE',
  'BEGIN:VEVENT',
  'UID:game-1@gc.com',
  'DTSTART;TZID=America/Chicago:20301017T100000',
  'DTEND;TZID=America/Chicago:20301017T113000',
  'SUMMARY:Thunder 12U vs. Eagles',
  'LOCATION:Riverside Park\\, Field 3\\, 100 River Rd\\, Austin\\, TX',
  'DESCRIPTION:Arrive 45 minutes early.\\nWear white.',
  'BEGIN:VALARM',
  'TRIGGER:-PT1H',
  'DESCRIPTION:Reminder',
  'END:VALARM',
  'END:VEVENT',
  'BEGIN:VEVENT',
  'UID:game-2@gc.com',
  'DTSTART:20301024T160000Z',
  'DURATION:PT2H',
  'SUMMARY:@ Comets',
  'LOCATION:Lakeview Fields',
  'END:VEVENT',
  'BEGIN:VEVENT',
  'UID:practice@gc.com',
  'DTSTART;TZID=America/Chicago:20301014T180000',
  'DTEND;TZID=America/Chicago:20301014T193000',
  'RRULE:FREQ=WEEKLY;BYDAY=MO,WE;UNTIL=20301106T235959Z',
  'EXDATE;TZID=America/Chicago:20301021T180000',
  'SUMMARY:Practice',
  'LOCATION:123 Main St',
  'END:VEVENT',
  'BEGIN:VEVENT',
  'UID:practice@gc.com',
  'RECURRENCE-ID;TZID=America/Chicago:20301016T180000',
  'DTSTART;TZID=America/Chicago:20301016T190000',
  'DTEND;TZID=America/Chicago:20301016T203000',
  'SUMMARY:Practice (late)',
  'END:VEVENT',
  'BEGIN:VEVENT',
  'UID:bbq@gc.com',
  'DTSTART;VALUE=DATE:20301026',
  'DTEND;VALUE=DATE:20301027',
  'SUMMARY:Season kickoff BBQ',
  'END:VEVENT',
  'BEGIN:VEVENT',
  'UID:rained-out@gc.com',
  'DTSTART;TZID=America/Chicago:20301018T100000',
  'SUMMARY:vs. Hawks',
  'STATUS:CANCELLED',
  'END:VEVENT',
  'BEGIN:VEVENT',
  'UID:monthly@gc.com',
  'DTSTART;TZID=America/Chicago:20301101T180000',
  'RRULE:FREQ=MONTHLY;BYMONTHDAY=1',
  'SUMMARY:Parents meeting',
  'END:VEVENT',
  'BEGIN:VEVENT',
  'UID:old@gc.com',
  'DTSTART;TZID=America/Chicago:20300901T100000',
  'SUMMARY:vs. Old Team',
  'END:VEVENT',
  'BEGIN:VEVENT',
  'SUMMARY:No start',
  'END:VEVENT',
  'END:VCALENDAR',
].join('\r\n');

describe('reading iCalendar (RFC 5545)', () => {
  it('unfolds long lines, unescapes text, and reads quoted parameters', () => {
    const cal = parseIcs(
      [
        'BEGIN:VCALENDAR',
        'BEGIN:VEVENT',
        'UID:a',
        'DTSTART;TZID="America/Chicago":20301017T100000',
        'SUMMARY:A very long',
        '  title that wraps',
        'DESCRIPTION:One\\, two\\; three\\\\four\\Nfive',
        'END:VEVENT',
        'END:VCALENDAR',
      ].join('\n'),
    );
    expect(cal.events).toHaveLength(1);
    expect(cal.events[0].summary).toBe('A very long title that wraps');
    expect(cal.events[0].description).toBe('One, two; three\\four\nfive');
    expect(cal.events[0].start).toEqual({ kind: 'local', date: '2030-10-17', time: '10:00', tzid: 'America/Chicago' });
    expect(unescapeText('a\\nb')).toBe('a\nb');
  });

  it('reads dates, UTC times, local times, and durations', () => {
    expect(parseIcsTime('20301026', { VALUE: 'DATE' })).toEqual({ kind: 'date', date: '2030-10-26' });
    expect(parseIcsTime('20301026', {})).toEqual({ kind: 'date', date: '2030-10-26' });
    expect(parseIcsTime('20301024T160000Z', {})).toEqual({ kind: 'utc', ms: Date.parse('2030-10-24T16:00:00Z') });
    expect(parseIcsTime('20301024T1600', {})).toEqual({ kind: 'local', date: '2030-10-24', time: '16:00', tzid: null });
    expect(parseIcsTime('20300230T100000', {})).toBeNull();
    expect(parseIcsTime('soon', {})).toBeNull();
    expect(parseDuration('PT1H30M')).toBe(5_400_000);
    expect(parseDuration('P1D')).toBe(86_400_000);
    expect(parseDuration('P2W')).toBe(14 * 86_400_000);
    expect(parseDuration('-PT15M')).toBe(-900_000);
    expect(parseDuration('P')).toBeNull();
    expect(parseDuration('1 hour')).toBeNull();
  });

  it('keeps the feed zone, skips alarms and time zone blocks, and counts what it cannot read', () => {
    const cal = parseIcs(FEED);
    expect(cal.timeZone).toBe(CHI);
    expect(cal.events.map((e) => e.uid)).toEqual([
      'game-1@gc.com',
      'game-2@gc.com',
      'practice@gc.com',
      'practice@gc.com',
      'bbq@gc.com',
      'rained-out@gc.com',
      'monthly@gc.com',
      'old@gc.com',
    ]);
    expect(cal.events[0].description).toBe('Arrive 45 minutes early.\nWear white.');
    expect(cal.events[2].exdates).toEqual([{ kind: 'local', date: '2030-10-21', time: '18:00', tzid: CHI }]);
    expect(cal.unreadable).toBe(1);
  });
});

describe('titles and places', () => {
  it('reads games, their opponents, and home or away', () => {
    expect(classify('Thunder 12U vs. Eagles')).toEqual({ type: 'game', title: 'vs. Eagles', opponent: 'Eagles', homeAway: 'home' });
    expect(classify('vs Eagles (Away)')).toEqual({ type: 'game', title: '@ Eagles', opponent: 'Eagles', homeAway: 'away' });
    expect(classify('Thunder @ Comets')).toEqual({ type: 'game', title: '@ Comets', opponent: 'Comets', homeAway: 'away' });
    expect(classify('@Comets')).toMatchObject({ type: 'game', opponent: 'Comets' });
    expect(classify('Thunder versus Hawks (Home)')).toMatchObject({ title: 'vs. Hawks', homeAway: 'home' });
  });

  it('picks the other types from words, and keeps the title', () => {
    expect(classify('Practice')).toEqual({ type: 'practice', title: 'Practice', opponent: null, homeAway: null });
    expect(classify('Batting practice at the cages')).toMatchObject({ type: 'practice', title: 'Batting practice at the cages' });
    expect(classify('Fall tournament')).toMatchObject({ type: 'game', opponent: null });
    expect(classify('Parents meeting')).toMatchObject({ type: 'meeting' });
    expect(classify('Season kickoff BBQ')).toMatchObject({ type: 'social' });
    expect(classify('Picture day')).toMatchObject({ type: 'other' });
    expect(classify('  ')).toMatchObject({ type: 'other', title: 'Event' });
    expect(classify('x'.repeat(150)).title).toHaveLength(100);
  });

  it('splits a place into its name and its address', () => {
    expect(splitLocation('Riverside Park, Field 3, 100 River Rd, Austin, TX')).toEqual({
      name: 'Riverside Park, Field 3',
      address: '100 River Rd, Austin, TX',
    });
    expect(splitLocation('Lakeview Fields, Austin, TX')).toEqual({ name: 'Lakeview Fields', address: 'Austin, TX' });
    expect(splitLocation('Lakeview Fields')).toEqual({ name: 'Lakeview Fields', address: '' });
    expect(splitLocation('123 Main St\nAustin TX')).toEqual({ name: '', address: '123 Main St, Austin TX' });
    expect(splitLocation('  ')).toBeNull();
  });
});

describe('time zones', () => {
  it('takes IANA names, Windows names, and paths that end in one', () => {
    expect(ianaZone(CHI)).toBe(CHI);
    expect(ianaZone('Central Standard Time')).toBe(CHI);
    expect(ianaZone('/mozilla.org/20050126_1/America/New_York')).toBe('America/New_York');
    expect(ianaZone('Somewhere/Else')).toBeNull();
    expect(ianaZone(null)).toBeNull();
  });
});

describe('repeats', () => {
  it('takes daily and weekly rules, and nothing it cannot expand faithfully', () => {
    expect(parseRule('FREQ=WEEKLY;BYDAY=MO,WE;UNTIL=20301106T235959Z')).toMatchObject({ freq: 'WEEKLY', byDay: [1, 3], interval: 1 });
    expect(parseRule('FREQ=DAILY;INTERVAL=2;COUNT=5')).toMatchObject({ freq: 'DAILY', interval: 2, count: 5 });
    for (const r of ['FREQ=MONTHLY;BYMONTHDAY=1', 'FREQ=WEEKLY;BYDAY=1MO', 'FREQ=WEEKLY;BYSETPOS=1', 'FREQ=WEEKLY;WKST=SU', 'FREQ=DAILY;BYDAY=MO']) {
      expect(parseRule(r), r).toBeNull();
    }
  });

  it('counts COUNT from the first date and stops at the last date', () => {
    const weekly = parseRule('FREQ=WEEKLY;BYDAY=TU,TH;COUNT=3')!;
    expect(ruleDates(weekly, '2030-10-15', '2031-12-31', null, () => 0)).toEqual(['2030-10-15', '2030-10-17', '2030-10-22']);
    const daily = parseRule('FREQ=DAILY;INTERVAL=2')!;
    expect(ruleDates(daily, '2030-10-15', '2030-10-20', null, () => 0)).toEqual(['2030-10-15', '2030-10-17', '2030-10-19']);
    // A weekly rule starting midweek skips the earlier days of that week.
    const midweek = parseRule('FREQ=WEEKLY;BYDAY=MO,FR;COUNT=2')!;
    expect(ruleDates(midweek, addDays('2030-10-14', 2), '2031-12-31', null, () => 0)).toEqual(['2030-10-18', '2030-10-21']);
  });
});

describe('a feed to events', () => {
  const { events, skipped, past } = eventsFromIcs(parseIcs(FEED), { teamTimeZone: 'America/New_York', nowMs: NOW, includePast: false });
  const at = (iso: string) => Date.parse(iso);

  it('expands weekly practices, skipping excluded dates and moving changed ones', () => {
    const practices = events.filter((e) => e.type === 'practice');
    expect(practices.map((p) => [p.sourceId, p.startMs])).toEqual([
      ['practice@gc.com#2030-10-14', at('2030-10-14T23:00:00Z')],
      // Changed to 7 PM.
      ['practice@gc.com#2030-10-16', at('2030-10-17T00:00:00Z')],
      ['practice@gc.com#2030-10-23', at('2030-10-23T23:00:00Z')],
      ['practice@gc.com#2030-10-28', at('2030-10-28T23:00:00Z')],
      ['practice@gc.com#2030-10-30', at('2030-10-30T23:00:00Z')],
      // 6 PM after clocks fall back is midnight UTC; Wednesday's would be
      // past UNTIL.
      ['practice@gc.com#2030-11-04', at('2030-11-05T00:00:00Z')],
    ]);
    expect(practices[1].title).toBe('Practice (late)');
    expect(practices[0].endMs - practices[0].startMs).toBe(90 * 60_000);
    expect(practices[0].location).toEqual({ name: '', address: '123 Main St' });
    expect(practices[0].timeZone).toBe(CHI);
  });

  it('reads games, all-day events, and UTC times in the feed zone', () => {
    const eagles = events.find((e) => e.sourceId === 'game-1@gc.com')!;
    expect(eagles).toMatchObject({
      type: 'game',
      title: 'vs. Eagles',
      opponent: 'Eagles',
      homeAway: 'home',
      allDay: false,
      startMs: at('2030-10-17T15:00:00Z'),
      endMs: at('2030-10-17T16:30:00Z'),
      timeZone: CHI,
      description: 'Arrive 45 minutes early.\nWear white.',
      location: { name: 'Riverside Park, Field 3', address: '100 River Rd, Austin, TX' },
    });
    const comets = events.find((e) => e.sourceId === 'game-2@gc.com')!;
    expect(comets).toMatchObject({ title: '@ Comets', homeAway: 'away', timeZone: CHI, endMs: at('2030-10-24T18:00:00Z') });
    const bbq = events.find((e) => e.sourceId === 'bbq@gc.com')!;
    expect(bbq).toMatchObject({ allDay: true, startDate: '2030-10-26', endDate: '2030-10-26', type: 'social' });
    expect(bbq.startMs).toBe(at('2030-10-26T05:00:00Z'));
    expect(bbq.endMs).toBe(at('2030-10-27T05:00:00Z'));
  });

  it('lists what it skips and why, sorts by start, and leaves the past out', () => {
    expect(skipped).toEqual([
      { title: '', startMs: null, reason: 'unreadable' },
      { title: 'vs. Hawks', startMs: at('2030-10-18T15:00:00Z'), reason: 'canceled' },
      { title: 'Parents meeting', startMs: at('2030-11-01T23:00:00Z'), reason: 'repeat' },
    ]);
    expect(past).toBe(1);
    expect(events).toHaveLength(9);
    expect(events.map((e) => e.startMs)).toEqual([...events.map((e) => e.startMs)].sort((a, b) => a - b));
    const withPast = eventsFromIcs(parseIcs(FEED), { teamTimeZone: CHI, nowMs: NOW, includePast: true });
    expect(withPast.past).toBe(0);
    expect(withPast.events[0].title).toBe('vs. Old Team');
  });

  it('uses the team zone for floating times, and an hour when nothing says how long', () => {
    const { events: [e] } = eventsFromIcs(
      parseIcs(['BEGIN:VCALENDAR', 'BEGIN:VEVENT', 'UID:x', 'DTSTART:20301020T180000', 'SUMMARY:Scrimmage', 'END:VEVENT', 'END:VCALENDAR'].join('\n')),
      { teamTimeZone: 'America/Denver', nowMs: NOW, includePast: false },
    );
    expect(e).toMatchObject({ timeZone: 'America/Denver', startMs: at('2030-10-21T00:00:00Z'), endMs: at('2030-10-21T01:00:00Z'), type: 'game' });
  });

  it("takes the team's zone when the feed says only UTC", () => {
    const {
      events: [timed, allDay],
    } = eventsFromIcs(
      parseIcs(
        [
          'BEGIN:VCALENDAR',
          'X-WR-TIMEZONE:UTC',
          'BEGIN:VEVENT',
          'UID:a',
          'DTSTART:20301020T230000Z',
          'SUMMARY:Practice',
          'END:VEVENT',
          'BEGIN:VEVENT',
          'UID:b',
          'DTSTART;VALUE=DATE:20301026',
          'SUMMARY:Picture day',
          'END:VEVENT',
          'END:VCALENDAR',
        ].join('\n'),
      ),
      { teamTimeZone: CHI, nowMs: NOW, includePast: false },
    );
    expect(timed).toMatchObject({ timeZone: CHI, startMs: at('2030-10-20T23:00:00Z') });
    expect(allDay).toMatchObject({ timeZone: CHI, startDate: '2030-10-26', startMs: at('2030-10-26T05:00:00Z') });
  });

  it('gives an entry with no UID the same ID every time', () => {
    const text = ['BEGIN:VCALENDAR', 'BEGIN:VEVENT', 'DTSTART:20301020T180000Z', 'SUMMARY:Team photo', 'END:VEVENT', 'END:VCALENDAR'].join('\n');
    const a = eventsFromIcs(parseIcs(text), { teamTimeZone: CHI, nowMs: NOW, includePast: false }).events[0].sourceId;
    const b = eventsFromIcs(parseIcs(text), { teamTimeZone: CHI, nowMs: NOW, includePast: false }).events[0].sourceId;
    expect(a).toMatch(/^nouid-/);
    expect(a).toBe(b);
  });
});

describe('which calendar links may be fetched (ARCH §6.13)', () => {
  it('takes https and webcal on the standard port, and nothing else', () => {
    expect(calendarUrl('webcal://api.team-manager.gc.com/ics/team.ics').href).toBe('https://api.team-manager.gc.com/ics/team.ics');
    expect(calendarUrl(' https://example.com/a.ics?x=1 ').href).toBe('https://example.com/a.ics?x=1');
    for (const bad of [
      'http://example.com/a.ics',
      'ftp://example.com/a.ics',
      'https://user:pass@example.com/a.ics',
      'https://example.com:8443/a.ics',
      'https://127.0.0.1/a.ics',
      'https://169.254.169.254/computeMetadata/v1/',
      'https://[::1]/a.ics',
      'https://10.0.0.5/a.ics',
      'not a link',
    ]) {
      expect(() => calendarUrl(bad), bad).toThrow(/bad-link/);
    }
  });

  it('knows public addresses from private ones', () => {
    for (const ip of ['8.8.8.8', '151.101.1.69', '2607:f8b0:4004:c07::64']) expect(isPublicAddress(ip), ip).toBe(true);
    for (const ip of [
      '127.0.0.1',
      '10.1.2.3',
      '172.16.0.1',
      '172.31.255.255',
      '192.168.1.1',
      '169.254.169.254',
      '100.64.0.1',
      '0.0.0.0',
      '224.0.0.1',
      '::1',
      'fd00::1',
      'fe80::1',
      '::ffff:127.0.0.1',
      'nonsense',
    ]) {
      expect(isPublicAddress(ip), ip).toBe(false);
    }
  });

  it('refuses a name that resolves to a private address, before connecting', async () => {
    await expect(fetchCalendar('https://localhost/a.ics')).rejects.toMatchObject({ message: 'bad-link' });
  });
});
