// iCalendar (RFC 5545) for imports (SPEC IMPORT-4): the part of the format
// that calendar feeds such as GameChanger's schedule link use. Pure
// functions with no Firestore.

/** When an event starts or ends, as the feed wrote it. */
export type IcsTime =
  /** A date with no time (`VALUE=DATE`): all day. */
  | { kind: 'date'; date: string }
  /** An instant in UTC (`...Z`). */
  | { kind: 'utc'; ms: number }
  /** A wall-clock time, in `tzid` or, with none, wherever the reader is. */
  | { kind: 'local'; date: string; time: string; tzid: string | null };

/** One VEVENT. Text is unescaped; anything missing is ''. */
export interface IcsEvent {
  uid: string;
  summary: string;
  description: string;
  location: string;
  start: IcsTime;
  end: IcsTime | null;
  /** DURATION, when there's no DTEND. */
  durationMs: number | null;
  /** The RRULE as written, `FREQ=WEEKLY;BYDAY=TU,TH`, or null. */
  rrule: string | null;
  exdates: IcsTime[];
  /** On a changed occurrence of a repeating event: which one it replaces. */
  recurrenceId: IcsTime | null;
  /** CONFIRMED, TENTATIVE, CANCELLED, or ''. */
  status: string;
}

export interface IcsCalendar {
  /** X-WR-TIMEZONE, the zone a feed's floating times are in, if it says. */
  timeZone: string | null;
  /** X-WR-CALNAME, the calendar's name: GameChanger's is the team's. */
  name: string | null;
  /** PRODID, the app that made it ("-//com.gc/NONSGML GameChanger…"). */
  producer: string | null;
  events: IcsEvent[];
  /** VEVENTs that couldn't be read (no start, or a start in no format). */
  unreadable: number;
}

interface Property {
  name: string;
  params: Record<string, string>;
  value: string;
}

/** Splits `NAME;P=1;Q="a:b":value` at the first colon outside quotes. */
function parseProperty(line: string): Property | null {
  let quoted = false;
  let colon = -1;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (c === '"') quoted = !quoted;
    else if (c === ':' && !quoted) {
      colon = i;
      break;
    }
  }
  if (colon < 0) return null;
  const [name, ...rawParams] = splitOutsideQuotes(line.slice(0, colon), ';');
  const params: Record<string, string> = {};
  for (const p of rawParams) {
    const eq = p.indexOf('=');
    if (eq > 0) params[p.slice(0, eq).toUpperCase()] = p.slice(eq + 1).replace(/^"|"$/g, '');
  }
  return { name: name.toUpperCase(), params, value: line.slice(colon + 1) };
}

function splitOutsideQuotes(s: string, sep: string): string[] {
  const out: string[] = [];
  let quoted = false;
  let start = 0;
  for (let i = 0; i < s.length; i++) {
    if (s[i] === '"') quoted = !quoted;
    else if (s[i] === sep && !quoted) {
      out.push(s.slice(start, i));
      start = i + 1;
    }
  }
  out.push(s.slice(start));
  return out;
}

/** TEXT values: `\n` and `\N` are line breaks; `\,`, `\;`, and `\\` stand for themselves. */
export function unescapeText(value: string): string {
  return value.replace(/\\([nN,;\\])/g, (_, c: string) => (c === 'n' || c === 'N' ? '\n' : c));
}

/** A DATE or DATE-TIME value: 20261020, 20261020T180000, or 20261020T230000Z. */
export function parseIcsTime(value: string, params: Record<string, string>): IcsTime | null {
  const m = /^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$/.exec(value.trim());
  if (!m) return null;
  const [, y, mo, d, h, mi, s, z] = m;
  const date = `${y}-${mo}-${d}`;
  if (!validDate(+y, +mo, +d)) return null;
  if (h === undefined || params.VALUE === 'DATE') return { kind: 'date', date };
  if (+h > 23 || +mi > 59) return null;
  if (z) return { kind: 'utc', ms: Date.UTC(+y, +mo - 1, +d, +h, +mi, +(s ?? 0)) };
  return { kind: 'local', date, time: `${h}:${mi}`, tzid: params.TZID ?? null };
}

function validDate(y: number, mo: number, d: number): boolean {
  const t = new Date(Date.UTC(y, mo - 1, d));
  return t.getUTCFullYear() === y && t.getUTCMonth() === mo - 1 && t.getUTCDate() === d;
}

/** A DURATION such as PT1H30M, P1D, or P2W, in milliseconds; null if unreadable. */
export function parseDuration(value: string): number | null {
  const m = /^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/.exec(value.trim());
  if (!m || value.trim() === 'P' || value.trim().endsWith('T')) return null;
  const [, sign, w, d, h, mi, s] = m;
  const ms = ((+(w ?? 0) * 7 + +(d ?? 0)) * 86_400 + +(h ?? 0) * 3600 + +(mi ?? 0) * 60 + +(s ?? 0)) * 1000;
  return sign === '-' ? -ms : ms;
}

/** Reads a calendar's events. Unknown properties and components are ignored. */
export function parseIcs(text: string): IcsCalendar {
  // Long lines continue on lines that start with a space or a tab.
  const lines = text.replace(/\r?\n[ \t]/g, '').split(/\r?\n/);
  const events: IcsEvent[] = [];
  let timeZone: string | null = null;
  let name: string | null = null;
  let producer: string | null = null;
  let unreadable = 0;
  // The components we're inside, innermost last.
  const stack: string[] = [];
  let props: Property[] = [];
  for (const line of lines) {
    if (!line.trim()) continue;
    const p = parseProperty(line);
    if (!p) continue;
    if (p.name === 'BEGIN') {
      stack.push(p.value.trim().toUpperCase());
      if (stack.at(-1) === 'VEVENT') props = [];
      continue;
    }
    if (p.name === 'END') {
      const ended = stack.pop();
      if (ended === 'VEVENT') {
        const event = toEvent(props);
        if (event) events.push(event);
        else unreadable++;
      }
      continue;
    }
    const inside = stack.at(-1);
    if (inside === 'VEVENT') props.push(p);
    else if (inside === 'VCALENDAR' && p.name === 'X-WR-TIMEZONE') timeZone = p.value.trim() || null;
    else if (inside === 'VCALENDAR' && p.name === 'X-WR-CALNAME') name = unescapeText(p.value).trim() || null;
    else if (inside === 'VCALENDAR' && p.name === 'PRODID') producer = p.value.trim() || null;
  }
  return { timeZone, name, producer, events, unreadable };
}

function toEvent(props: Property[]): IcsEvent | null {
  const one = (name: string) => props.find((p) => p.name === name);
  const text = (name: string) => unescapeText(one(name)?.value ?? '').trim();
  const dtstart = one('DTSTART');
  const start = dtstart ? parseIcsTime(dtstart.value, dtstart.params) : null;
  if (!start) return null;
  const dtend = one('DTEND');
  const end = dtend ? parseIcsTime(dtend.value, dtend.params) : null;
  const duration = one('DURATION');
  const recurrence = one('RECURRENCE-ID');
  const exdates: IcsTime[] = [];
  for (const p of props.filter((q) => q.name === 'EXDATE')) {
    for (const v of p.value.split(',')) {
      const t = parseIcsTime(v, p.params);
      if (t) exdates.push(t);
    }
  }
  return {
    uid: (one('UID')?.value ?? '').trim(),
    summary: text('SUMMARY'),
    description: text('DESCRIPTION'),
    location: text('LOCATION'),
    start,
    end,
    durationMs: duration ? parseDuration(duration.value) : null,
    rrule: one('RRULE')?.value.trim() || null,
    exdates,
    recurrenceId: recurrence ? parseIcsTime(recurrence.value, recurrence.params) : null,
    status: (one('STATUS')?.value ?? '').trim().toUpperCase(),
  };
}
