// Repeating events (SCHED-3): expanding a series' rule into dates, and
// turning a date and a wall-clock time in an IANA zone into an instant.
// Pure functions with no Firestore, so the app's form preview (Dart) can
// match them through the shared vectors in test/unit/fixtures.
import { Limits } from '../shared/constants.js';

const DAY_MS = 86_400_000;

/** A series' rule (ARCH §6.2 eventSeries.recurrence). */
export interface Recurrence {
  freq: 'daily' | 'weekly';
  /** Every N days or weeks, 1 to Limits.seriesIntervalMax. */
  interval: number;
  /** ISO weekdays, Monday = 1; weekly only. */
  byWeekday: number[];
  startDate: string;
  /** Exactly one of untilDate and count is set. */
  untilDate: string | null;
  count: number | null;
  skipDates: string[];
}

// ---- Calendar dates ('YYYY-MM-DD', no time zone) --------------------------

const DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

/** Whether [s] is a real calendar date written 'YYYY-MM-DD'. */
export function isDate(s: string): boolean {
  const m = DATE_RE.exec(s);
  if (!m) return false;
  const d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3]));
  return d.getUTCFullYear() === +m[1] && d.getUTCMonth() === +m[2] - 1 && d.getUTCDate() === +m[3];
}

/** Days since 1970-01-01 for a 'YYYY-MM-DD' date. */
function dayNumber(date: string): number {
  const [y, m, d] = date.split('-').map(Number);
  return Math.round(Date.UTC(y, m - 1, d) / DAY_MS);
}

function dateOfDay(day: number): string {
  return new Date(day * DAY_MS).toISOString().slice(0, 10);
}

/** [date] moved by [days]. */
export function addDays(date: string, days: number): string {
  return dateOfDay(dayNumber(date) + days);
}

/** ISO weekday of [date]: Monday = 1 … Sunday = 7. */
export function isoWeekday(date: string): number {
  const dow = new Date(dayNumber(date) * DAY_MS).getUTCDay();
  return dow === 0 ? 7 : dow;
}

/**
 * The last date a series starting on [startDate] may reach (SCHED-3: no
 * more than 12 months out). Month-end days clamp: 2028-02-29 → 2029-02-28.
 */
export function lastAllowedDate(startDate: string): string {
  const [y, m, d] = startDate.split('-').map(Number);
  const targetYear = y + Math.floor((m - 1 + Limits.seriesMaxMonths) / 12);
  const targetMonth = (m - 1 + Limits.seriesMaxMonths) % 12;
  const lastDay = new Date(Date.UTC(targetYear, targetMonth + 1, 0)).getUTCDate();
  return dateOfDay(Math.round(Date.UTC(targetYear, targetMonth, Math.min(d, lastDay)) / DAY_MS));
}

/**
 * The dates a series produces (SCHED-3), in order. Walks from startDate:
 * daily every `interval` days; weekly on byWeekday days of every
 * `interval`-th week counted from the Monday of startDate's week, never
 * before startDate. Skip dates are dropped; `count` counts the dates kept.
 * Stops after untilDate, after `count` dates, 12 months after startDate,
 * or at Limits.seriesEventsMax dates, whichever comes first.
 */
export function expandDates(r: Recurrence): string[] {
  const start = dayNumber(r.startDate);
  const cap = dayNumber(lastAllowedDate(r.startDate));
  const end = r.untilDate ? Math.min(dayNumber(r.untilDate), cap) : cap;
  const max = Math.min(r.count ?? Limits.seriesEventsMax, Limits.seriesEventsMax);
  const skip = new Set(r.skipDates);
  const interval = Math.max(1, Math.floor(r.interval));
  const out: string[] = [];
  const keep = (day: number): boolean => {
    const date = dateOfDay(day);
    if (!skip.has(date)) out.push(date);
    return out.length < max;
  };
  if (r.freq === 'daily') {
    for (let day = start; day <= end; day += interval) if (!keep(day)) break;
    return out;
  }
  const weekdays = [...new Set(r.byWeekday)].filter((w) => w >= 1 && w <= 7).sort((a, b) => a - b);
  if (!weekdays.length) return out;
  const firstMonday = start - (isoWeekday(r.startDate) - 1);
  for (let monday = firstMonday; monday <= end; monday += 7 * interval) {
    for (const w of weekdays) {
      const day = monday + w - 1;
      if (day < start) continue;
      if (day > end) return out;
      if (!keep(day)) return out;
    }
  }
  return out;
}

// ---- Wall-clock time in a zone --------------------------------------------

const formatters = new Map<string, Intl.DateTimeFormat>();

function partsFormatter(timeZone: string): Intl.DateTimeFormat {
  let f = formatters.get(timeZone);
  if (!f) {
    f = new Intl.DateTimeFormat('en-US', {
      timeZone,
      hourCycle: 'h23',
      year: 'numeric',
      month: 'numeric',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
      second: 'numeric',
    });
    formatters.set(timeZone, f);
  }
  return f;
}

/** Whether [timeZone] is an IANA zone this runtime knows. */
export function isTimeZone(timeZone: string): boolean {
  try {
    partsFormatter(timeZone);
    return true;
  } catch {
    return false;
  }
}

/** The zone's offset from UTC at [ms], in milliseconds (Chicago in summer: -5 h). */
export function zoneOffsetMs(ms: number, timeZone: string): number {
  const parts = Object.fromEntries(
    partsFormatter(timeZone)
      .formatToParts(new Date(ms))
      .filter((p) => p.type !== 'literal')
      .map((p) => [p.type, Number(p.value)]),
  );
  const asUtc = Date.UTC(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute, parts.second);
  return asUtc - Math.floor(ms / 1000) * 1000;
}

/**
 * The instant at which clocks in [timeZone] read [time] ('HH:mm') on [date]
 * (SCHED-3: 6 PM stays 6 PM across daylight saving). A time that happens
 * twice when clocks fall back is the first one; a time that never happens
 * when they spring forward moves ahead by the gap (2:30 AM → 3:30 AM).
 * The Dart side follows the same rule.
 */
export function wallTimeToMs(date: string, time: string, timeZone: string): number {
  const [y, mo, d] = date.split('-').map(Number);
  const [h, mi] = time.split(':').map(Number);
  const local = Date.UTC(y, mo - 1, d, h, mi);
  // The offsets a day either side; between them they cover any change.
  const before = zoneOffsetMs(local - DAY_MS, timeZone);
  const after = zoneOffsetMs(local + DAY_MS, timeZone);
  const fits = [before, after].map((o) => local - o).filter((ms) => local - zoneOffsetMs(ms, timeZone) === ms);
  if (fits.length) return Math.min(...fits);
  return local - before; // In the spring-forward gap.
}

/** The 'YYYY-MM-DD' date clocks in [timeZone] show at [ms]. */
export function dateInZone(ms: number, timeZone: string): string {
  return new Date(ms + zoneOffsetMs(ms, timeZone)).toISOString().slice(0, 10);
}

/** When one occurrence starts and ends. */
export interface Occurrence {
  date: string;
  startMs: number;
  endMs: number;
  /** All-day events only: the dates, which never shift (SCHED-9). */
  startDate: string | null;
  endDate: string | null;
}

/** The times a series template gives each occurrence. */
export interface OccurrenceTimes {
  allDay: boolean;
  startTime: string | null;
  endTime: string | null;
  timeZone: string;
}

/**
 * One occurrence on [date]. Timed: the start and end wall-clock times in the
 * zone, ending the next day when the end isn't after the start. All day:
 * midnight to the next midnight in the zone (ARCH §6.2 rule).
 */
export function occurrenceOn(date: string, t: OccurrenceTimes): Occurrence {
  if (t.allDay) {
    return {
      date,
      startMs: wallTimeToMs(date, '00:00', t.timeZone),
      endMs: wallTimeToMs(addDays(date, 1), '00:00', t.timeZone),
      startDate: date,
      endDate: date,
    };
  }
  const start = t.startTime ?? '00:00';
  const end = t.endTime ?? start;
  const endDate = end <= start ? addDays(date, 1) : date;
  return {
    date,
    startMs: wallTimeToMs(date, start, t.timeZone),
    endMs: wallTimeToMs(endDate, end, t.timeZone),
    startDate: null,
    endDate: null,
  };
}
