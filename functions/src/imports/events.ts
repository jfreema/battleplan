// Calendar entries to Battleplan events (SPEC IMPORT-4): a type, a title,
// the opponent and home or away for games, a place, and times in the
// event's own zone, with daily and weekly repeats expanded into dates.
// Pure functions with no Firestore.
import { createHash } from 'node:crypto';
import { Limits, type EventType, type HomeAway } from '../shared/constants.js';
import { addDays, dateInZone, isoWeekday, isTimeZone, wallTimeToMs, zoneOffsetMs } from '../schedule/recurrence.js';
import type { IcsCalendar, IcsEvent, IcsTime } from './ics.js';

const HOUR_MS = 3_600_000;
const DAY_MS = 86_400_000;

/** One event to add, in the events collection's terms (ARCH §6.2). */
export interface ImportedEvent {
  /** The feed's UID, with `#YYYY-MM-DD` on a repeating event's occurrence. */
  sourceId: string;
  type: EventType;
  title: string;
  description: string;
  location: { name: string; address: string } | null;
  allDay: boolean;
  startMs: number;
  endMs: number;
  /** All-day events only. */
  startDate: string | null;
  endDate: string | null;
  timeZone: string;
  opponent: string | null;
  homeAway: HomeAway | null;
}

export type SkipReason = 'canceled' | 'repeat' | 'unreadable';

/** Calendars whose titles start with the team's name. */
export type TitleStyle = 'gamechanger' | 'teamsnap';

export interface SkippedEntry {
  title: string;
  startMs: number | null;
  reason: SkipReason;
}

export interface ConvertOptions {
  /** For times with no zone of their own: the team's. */
  teamTimeZone: string;
  /**
   * Whose titles these are, when they start with the team's name (the
   * calendar's): GameChanger's ("Thunder Practice", "Thunder @ Eagles")
   * or TeamSnap's ("Thunder - Practice", "Thunder at Eagles"). Otherwise
   * read from the feed's PRODID.
   */
  titles?: TitleStyle;
  nowMs: number;
  /** False leaves out events that ended before [nowMs]. */
  includePast: boolean;
}

export interface Converted {
  events: ImportedEvent[];
  skipped: SkippedEntry[];
  /** Ended before now, and left out. */
  past: number;
}

// ---- Titles and places -------------------------------------------------------

/**
 * The type, title, opponent, and home or away a feed's title stands for.
 * "Thunder vs. Eagles" and "vs Eagles (Home)" are home games against the
 * Eagles; "@ Eagles" is away. Games take the app's own titles ("vs.
 * Eagles", "@ Eagles"). Words pick the other types; anything else is Other.
 */
export function classify(summary: string): {
  type: EventType;
  title: string;
  opponent: string | null;
  homeAway: HomeAway | null;
} {
  const s = summary.replace(/\s+/g, ' ').trim();
  const versus = /(?:^|\s)(?:vs\.?|versus|v\.)\s+(.+)$/i.exec(s);
  const at = /(?:^|\s)@\s*(.+)$/.exec(s);
  const match = versus ?? at;
  if (match) {
    let opponent = match[1].trim();
    let homeAway: HomeAway = versus ? 'home' : 'away';
    const side = /\s*\((home|away)\)\s*$/i.exec(opponent);
    if (side) {
      homeAway = side[1].toLowerCase() as HomeAway;
      opponent = opponent.slice(0, side.index).trim();
    }
    opponent = opponent.slice(0, Limits.opponentMax).trim();
    if (opponent) {
      return { type: 'game', title: `${homeAway === 'away' ? '@' : 'vs.'} ${opponent}`, opponent, homeAway };
    }
  }
  const title = (s || 'Event').slice(0, Limits.eventTitleMax).trim();
  const type: EventType = /\b(practice|training|workout|clinic|tryouts?)\b/i.test(s)
    ? 'practice'
    : /\b(games?|scrimmage|match|tournaments?|tourneys?|doubleheader|double header|playoffs?)\b/i.test(s)
      ? 'game'
      : /\bmeeting\b/i.test(s)
        ? 'meeting'
        : /\b(party|banquet|picnic|dinner|celebration|social|cookout|bbq|barbecue)\b/i.test(s)
          ? 'social'
          : 'other';
  return { type, title, opponent: null, homeAway: null };
}

/**
 * [summary] without the calendar's own name in front, which GameChanger
 * puts on every entry ("Thunder 12U Practice" in Thunder 12U's calendar is
 * "Practice"). A title that's only the name stays as it is. Only for
 * GameChanger's feeds (their PRODID says so).
 */
export function withoutCalendarName(summary: string, calendarName: string | null): string {
  const name = (calendarName ?? '').replace(/\s+/g, ' ').trim();
  const s = summary.replace(/\s+/g, ' ').trim();
  if (name.length < 3 || !s.toLowerCase().startsWith(name.toLowerCase())) return summary;
  const rest = s.slice(name.length);
  if (!/^[\s:\-–—|]/.test(rest)) return summary;
  const trimmed = rest.replace(/^[\s:\-–—|]+/, '').trim();
  return trimmed || summary;
}

/**
 * A title from a calendar that puts the team's name first, without it.
 * TeamSnap writes games as "Thunder at Eagles" (or "Thunder Playoff Game
 * #1 at Eagles"), which are away games ("@ Eagles"), and other events as
 * "Thunder - Team dinner at Joe's", whose "at" is just a word.
 */
export function teamTitle(summary: string, calendarName: string | null, style: TitleStyle): string {
  const rest = withoutCalendarName(summary, calendarName);
  if (rest === summary || style !== 'teamsnap') return rest;
  const name = (calendarName ?? '').replace(/\s+/g, ' ').trim();
  const dashed = /^\s*[:\-–—|]/.test(summary.replace(/\s+/g, ' ').trim().slice(name.length));
  if (dashed) return rest;
  const at = /^(.*?)\s*\bat\s+(.+)$/i.exec(rest);
  return at ? `${at[1]} @ ${at[2]}`.trim() : rest;
}

/**
 * The place's name from notes that start with it, as TeamSnap's do
 * ("Location: Riverside Park"), and the notes without that line.
 */
export function placeFromNotes(notes: string): { name: string | null; notes: string } {
  const lines = notes.split(/\r?\n/);
  const first = /^\s*Location:\s*(.+?)\s*$/i.exec(lines[0] ?? '');
  if (!first) return { name: null, notes };
  return { name: first[1].slice(0, Limits.locationNameMax).trim(), notes: lines.slice(1).join('\n').trim() };
}

/**
 * A place as the app keeps it: the name is everything before the street
 * address, the first part that starts with a number ("Riverside Park,
 * Field 3, 100 River Rd, Austin" is "Riverside Park, Field 3" at "100 River
 * Rd, Austin"). With no number, the first part is the name and the rest the
 * address; a place that starts with a number is just an address.
 */
export function splitLocation(raw: string): { name: string; address: string } | null {
  const parts = raw
    .split(/\r?\n|,/)
    .map((p) => p.replace(/\s+/g, ' ').trim())
    .filter(Boolean);
  if (!parts.length) return null;
  const street = parts.findIndex((p) => /^\d/.test(p));
  const cut = street >= 0 ? street : 1;
  return {
    name: parts.slice(0, cut).join(', ').slice(0, Limits.locationNameMax).trim(),
    address: parts.slice(cut).join(', ').slice(0, Limits.locationAddressMax).trim(),
  };
}

// ---- Time zones ----------------------------------------------------------------

/** Windows zone names some feeds use, to IANA. */
const WINDOWS_ZONES: Record<string, string> = {
  'Eastern Standard Time': 'America/New_York',
  'Central Standard Time': 'America/Chicago',
  'Mountain Standard Time': 'America/Denver',
  'US Mountain Standard Time': 'America/Phoenix',
  'Pacific Standard Time': 'America/Los_Angeles',
  'Alaskan Standard Time': 'America/Anchorage',
  'Hawaiian Standard Time': 'Pacific/Honolulu',
  'Atlantic Standard Time': 'America/Halifax',
  'GMT Standard Time': 'Europe/London',
  'UTC': 'UTC',
};

/** An IANA zone for a TZID: as it is, from Windows' name, or the end of a path like `/mozilla.org/…/America/Chicago`. */
export function ianaZone(tzid: string | null): string | null {
  if (!tzid) return null;
  const t = tzid.trim();
  if (isTimeZone(t)) return t;
  if (WINDOWS_ZONES[t]) return WINDOWS_ZONES[t];
  const parts = t.split('/').filter(Boolean);
  for (let n = Math.min(3, parts.length); n >= 2; n--) {
    const tail = parts.slice(-n).join('/');
    if (isTimeZone(tail)) return tail;
  }
  return null;
}

/** The wall-clock 'HH:mm' in [timeZone] at [ms]. */
function wallTime(ms: number, timeZone: string): string {
  return new Date(ms + zoneOffsetMs(ms, timeZone)).toISOString().slice(11, 16);
}

/**
 * The event's zone: its own TZID, then the feed's, then the team's. A feed
 * that says UTC usually means it didn't say: teams play where they are.
 */
function zoneOf(e: IcsEvent, feedZone: string | null, teamZone: string): string {
  const own = e.start.kind === 'local' ? ianaZone(e.start.tzid) : null;
  const feed = ianaZone(feedZone);
  return own ?? (feed && !/^(Etc\/)?(UTC|GMT|UCT|Zulu|Universal)$/i.test(feed) ? feed : null) ?? teamZone;
}

/** The instant [t] stands for in [zone]: a date is its midnight there. */
function instant(t: IcsTime, zone: string): number {
  if (t.kind === 'utc') return t.ms;
  if (t.kind === 'date') return wallTimeToMs(t.date, '00:00', zone);
  return wallTimeToMs(t.date, t.time, ianaZone(t.tzid) ?? zone);
}

/** The date [t] is on in [zone]. */
function dateOf(t: IcsTime, zone: string): string {
  return t.kind === 'utc' ? dateInZone(t.ms, zone) : t.date;
}

// ---- Repeats --------------------------------------------------------------------

interface Rule {
  freq: 'DAILY' | 'WEEKLY';
  interval: number;
  /** ISO weekdays, Monday = 1; weekly only. */
  byDay: number[];
  count: number | null;
  until: IcsTime | null;
}

const WEEKDAYS: Record<string, number> = { MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6, SU: 7 };

/** A daily or weekly RRULE; null for anything else, which isn't imported. */
export function parseRule(rrule: string): Rule | null {
  const parts = Object.fromEntries(
    rrule.split(';').map((p) => {
      const eq = p.indexOf('=');
      return [p.slice(0, eq).trim().toUpperCase(), p.slice(eq + 1).trim().toUpperCase()];
    }),
  );
  const known = new Set(['FREQ', 'INTERVAL', 'BYDAY', 'COUNT', 'UNTIL', 'WKST']);
  if (Object.keys(parts).some((k) => !known.has(k))) return null;
  if (parts.FREQ !== 'DAILY' && parts.FREQ !== 'WEEKLY') return null;
  if (parts.WKST && parts.WKST !== 'MO') return null;
  const interval = parts.INTERVAL ? Number(parts.INTERVAL) : 1;
  if (!Number.isInteger(interval) || interval < 1 || interval > 52) return null;
  const byDay: number[] = [];
  if (parts.BYDAY) {
    if (parts.FREQ !== 'WEEKLY') return null;
    for (const d of parts.BYDAY.split(',')) {
      if (!WEEKDAYS[d]) return null; // "1MO" and the like are monthly rules.
      byDay.push(WEEKDAYS[d]);
    }
  }
  const count = parts.COUNT ? Number(parts.COUNT) : null;
  if (count !== null && (!Number.isInteger(count) || count < 1)) return null;
  let until: IcsTime | null = null;
  if (parts.UNTIL) {
    until = parseUntil(parts.UNTIL);
    if (!until) return null;
  }
  return { freq: parts.FREQ, interval, byDay: [...new Set(byDay)].sort(), count, until };
}

function parseUntil(v: string): IcsTime | null {
  const m = /^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$/.exec(v);
  if (!m) return null;
  const date = `${m[1]}-${m[2]}-${m[3]}`;
  if (!m[4]) return { kind: 'date', date };
  if (m[7]) return { kind: 'utc', ms: Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]) };
  return { kind: 'local', date, time: `${m[4]}:${m[5]}`, tzid: null };
}

/**
 * The dates a rule gives, from [startDate] through [lastDate], counting
 * COUNT from the first one (RFC 5545: before EXDATE takes any away).
 */
export function ruleDates(rule: Rule, startDate: string, lastDate: string, untilMs: number | null, startMsOf: (date: string) => number): string[] {
  const out: string[] = [];
  let made = 0;
  const done = (date: string) =>
    (rule.count !== null && made >= rule.count) || date > lastDate || (untilMs !== null && startMsOf(date) > untilMs);
  if (rule.freq === 'DAILY') {
    for (let k = 0; k < 2000; k++) {
      const date = addDays(startDate, k * rule.interval);
      if (done(date)) break;
      out.push(date);
      made++;
    }
    return out;
  }
  const days = rule.byDay.length ? rule.byDay : [isoWeekday(startDate)];
  const monday = addDays(startDate, 1 - isoWeekday(startDate));
  for (let w = 0; w < 600; w++) {
    const week = addDays(monday, w * 7 * rule.interval);
    for (const d of days) {
      const date = addDays(week, d - 1);
      if (date < startDate) continue;
      if (done(date)) return out;
      out.push(date);
      made++;
    }
  }
  return out;
}

// ---- The conversion ------------------------------------------------------------

/** A stable ID for an entry with no UID: its title and start. */
function fallbackUid(e: IcsEvent): string {
  return 'nouid-' + createHash('sha256').update(`${e.summary}\n${JSON.stringify(e.start)}`).digest('hex').slice(0, 16);
}

/** How long an entry lasts: its end, its DURATION, or an hour (a day if all day). */
function lengthMs(e: IcsEvent, zone: string, startMs: number): number {
  if (e.end) {
    const ms = instant(e.end, zone) - startMs;
    if (ms > 0) return ms;
  }
  if (e.durationMs && e.durationMs > 0) return e.durationMs;
  return e.start.kind === 'date' ? DAY_MS : HOUR_MS;
}

/** One occurrence, on [date] for a repeat or as written for a one-off. */
function occurrence(e: IcsEvent, zone: string, date: string | null, sourceId: string): ImportedEvent {
  const what = classify(e.summary);
  // TeamSnap names the place in the notes and puts its address in LOCATION.
  const fromNotes = placeFromNotes(e.description);
  const place = splitLocation(e.location);
  const location =
    fromNotes.name && (!place || !place.name)
      ? { name: fromNotes.name, address: place?.address ?? '' }
      : place;
  const base = {
    sourceId,
    ...what,
    description: (fromNotes.name ? fromNotes.notes : e.description).slice(0, Limits.eventNotesMax).trim(),
    location,
    timeZone: zone,
  };
  const firstStart = instant(e.start, zone);
  const length = lengthMs(e, zone, firstStart);
  if (e.start.kind === 'date') {
    const startDate = date ?? e.start.date;
    // DTEND is the day after the last; a last day before the first is the first.
    const days = Math.max(1, Math.round(length / DAY_MS));
    const endDate = addDays(startDate, days - 1);
    return {
      ...base,
      allDay: true,
      startMs: wallTimeToMs(startDate, '00:00', zone),
      endMs: wallTimeToMs(addDays(endDate, 1), '00:00', zone),
      startDate,
      endDate,
    };
  }
  // A repeat keeps its wall-clock start across daylight saving.
  const startMs = date === null ? firstStart : wallTimeToMs(date, wallTime(firstStart, zone), zone);
  return { ...base, allDay: false, startMs, endMs: startMs + length, startDate: null, endDate: null };
}

/**
 * The events a calendar holds, oldest first. Repeats expand through a year
 * from now (SCHED-3's limit), and a year back when past events are wanted;
 * an occurrence a feed changed or canceled (RECURRENCE-ID) replaces the one
 * it names. Canceled entries, repeats other than daily or weekly, and
 * unreadable entries are skipped with the reason.
 */
export function eventsFromIcs(feed: IcsCalendar, opts: ConvertOptions): Converted {
  // GameChanger and TeamSnap put the team's name on every title; other
  // calendars' titles are people's own. The fallback ID stays the
  // original title's.
  const producer = feed.producer ?? '';
  const style = opts.titles ?? (/gamechanger/i.test(producer) ? 'gamechanger' : /teamsnap/i.test(producer) ? 'teamsnap' : null);
  const cal = {
    ...feed,
    events: feed.events.map((e) => ({
      ...e,
      uid: e.uid || fallbackUid(e),
      summary: style ? teamTitle(e.summary, feed.name, style) : e.summary,
    })),
  };
  const events: ImportedEvent[] = [];
  const skipped: SkippedEntry[] = [];
  for (let i = 0; i < cal.unreadable; i++) skipped.push({ title: '', startMs: null, reason: 'unreadable' });
  let past = 0;
  const lastDate = dateInZone(opts.nowMs + 366 * DAY_MS, opts.teamTimeZone);
  const firstDate = dateInZone(opts.nowMs - 366 * DAY_MS, opts.teamTimeZone);

  // Changed occurrences of repeats, by UID and the date they replace.
  const changes = new Map<string, IcsEvent>();
  const repeating = new Set(cal.events.filter((e) => e.rrule && !e.recurrenceId).map((e) => e.uid || fallbackUid(e)));
  for (const e of cal.events) {
    if (!e.recurrenceId) continue;
    const uid = e.uid || fallbackUid(e);
    if (!repeating.has(uid)) continue;
    const zone = zoneOf(e, cal.timeZone, opts.teamTimeZone);
    changes.set(`${uid}#${dateOf(e.recurrenceId, zone)}`, e);
  }

  const add = (e: IcsEvent, ev: ImportedEvent) => {
    if (e.status === 'CANCELLED') skipped.push({ title: ev.title, startMs: ev.startMs, reason: 'canceled' });
    else if (!opts.includePast && ev.endMs <= opts.nowMs) past++;
    else events.push(ev);
  };

  for (const e of cal.events) {
    const uid = e.uid || fallbackUid(e);
    const zone = zoneOf(e, cal.timeZone, opts.teamTimeZone);
    if (e.recurrenceId) {
      // A change to a repeat is handled with its repeat; one on its own is a one-off.
      if (!repeating.has(uid)) add(e, occurrence(e, zone, null, `${uid}#${dateOf(e.recurrenceId, zone)}`));
      continue;
    }
    if (!e.rrule) {
      add(e, occurrence(e, zone, null, uid));
      continue;
    }
    const rule = parseRule(e.rrule);
    if (!rule) {
      skipped.push({ title: classify(e.summary).title, startMs: instant(e.start, zone), reason: 'repeat' });
      continue;
    }
    const start = dateOf(e.start, zone);
    const time = e.start.kind === 'date' ? '00:00' : wallTime(instant(e.start, zone), zone);
    const untilMs = rule.until ? (rule.until.kind === 'date' ? wallTimeToMs(addDays(rule.until.date, 1), '00:00', zone) - 1 : instant(rule.until, zone)) : null;
    const excluded = new Set(e.exdates.map((x) => dateOf(x, zone)));
    for (const date of ruleDates(rule, start, lastDate, untilMs, (d) => wallTimeToMs(d, time, zone))) {
      if (date < firstDate || excluded.has(date)) continue;
      const id = `${uid}#${date}`;
      const changed = changes.get(id);
      add(changed ?? e, changed ? occurrence(changed, zone, null, id) : occurrence(e, zone, date, id));
    }
  }
  events.sort((a, b) => a.startMs - b.startMs);
  return { events, skipped, past };
}

// ---- Events another app listed -----------------------------------------------

/** An event as an app's own data has it, not a calendar (GroupMe's). */
export interface ListedEvent {
  sourceId: string;
  title: string;
  description: string;
  /** A place as one line: a name, then the street address. */
  location: string;
  allDay: boolean;
  startMs: number;
  /** Null when it has no end. */
  endMs: number | null;
  /** IANA; null for the team's. */
  timeZone: string | null;
  canceled: boolean;
}

/**
 * The events an app listed, oldest first, as eventsFromIcs gives them: the
 * same titles, types, and places, in the event's zone or else the team's.
 * All-day events keep their dates in that zone. Canceled ones are skipped,
 * and past ones counted and left out unless asked for.
 */
export function eventsFromList(list: ListedEvent[], opts: ConvertOptions): Converted {
  const events: ImportedEvent[] = [];
  const skipped: SkippedEntry[] = [];
  let past = 0;
  for (const e of list) {
    const zone = e.timeZone && isTimeZone(e.timeZone) ? e.timeZone : opts.teamTimeZone;
    const what = classify(e.title);
    const base = {
      sourceId: e.sourceId,
      ...what,
      description: e.description.slice(0, Limits.eventNotesMax).trim(),
      location: splitLocation(e.location),
      timeZone: zone,
    };
    const ends = e.endMs !== null && e.endMs > e.startMs;
    let ev: ImportedEvent;
    if (e.allDay) {
      const startDate = dateInZone(e.startMs, zone);
      // An end at midnight is the day before's end.
      const endDate = ends ? dateInZone(e.endMs! - 1, zone) : startDate;
      ev = {
        ...base,
        allDay: true,
        startMs: wallTimeToMs(startDate, '00:00', zone),
        endMs: wallTimeToMs(addDays(endDate < startDate ? startDate : endDate, 1), '00:00', zone),
        startDate,
        endDate: endDate < startDate ? startDate : endDate,
      };
    } else {
      ev = { ...base, allDay: false, startMs: e.startMs, endMs: ends ? e.endMs! : e.startMs + HOUR_MS, startDate: null, endDate: null };
    }
    if (e.canceled) skipped.push({ title: ev.title, startMs: ev.startMs, reason: 'canceled' });
    else if (!opts.includePast && ev.endMs <= opts.nowMs) past++;
    else events.push(ev);
  }
  events.sort((a, b) => a.startMs - b.startMs);
  return { events, skipped, past };
}
