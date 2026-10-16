// The iCalendar text a calendar link serves (SPEC SCHED-11, ARCH §6.15):
// RFC 5545, written by hand like the app's own .ics for Add to calendar
// (lib/core/services/calendar.dart). Times are UTC; all-day events are
// dates, the day after the last as the end.

/** An event as a team's cached calendar keeps it (`teamCalendars`). */
export interface CalendarEvent {
  id: string;
  title: string;
  type: string;
  allDay: boolean;
  startMs: number;
  endMs: number;
  /** All-day events: the first and last day, YYYY-MM-DD, which never shift (SCHED-9). */
  startDate: string | null;
  endDate: string | null;
  location: { name: string; address: string } | null;
  description: string;
  /** Games: how early to arrive, in minutes. */
  arriveMinutesBefore: number | null;
  canceled: boolean;
  updatedMs: number;
}

/** An event as a link prints it. */
export interface FeedEvent extends CalendarEvent {
  /** The team's name, before the title on a link for all one's teams. */
  team: string | null;
  /** Where the event opens in Battleplan. */
  url: string;
}

/** A TEXT value with RFC 5545's escapes (§3.3.11). */
export function icsText(value: string): string {
  return value
    .replace(/\\/g, '\\\\')
    .replace(/;/g, '\\;')
    .replace(/,/g, '\\,')
    .replace(/\r\n|\r|\n/g, '\\n');
}

/**
 * [line] folded at 75 octets (§3.1): each later piece starts with a space,
 * and a UTF-8 character is never split.
 */
export function foldLine(line: string): string {
  const bytes = Buffer.from(line, 'utf8');
  if (bytes.length <= 75) return line;
  const pieces: string[] = [];
  let start = 0;
  let room = 75;
  while (start < bytes.length) {
    let end = Math.min(start + room, bytes.length);
    // Back up to the first byte of a character.
    while (end < bytes.length && (bytes[end] & 0xc0) === 0x80) end--;
    pieces.push(bytes.subarray(start, end).toString('utf8'));
    start = end;
    room = 74;
  }
  return pieces.join('\r\n ');
}

function two(n: number): string {
  return String(n).padStart(2, '0');
}

/** A UTC DATE-TIME: 20261018T150000Z. */
export function icsTime(ms: number): string {
  const d = new Date(ms);
  return (
    `${d.getUTCFullYear()}${two(d.getUTCMonth() + 1)}${two(d.getUTCDate())}` +
    `T${two(d.getUTCHours())}${two(d.getUTCMinutes())}${two(d.getUTCSeconds())}Z`
  );
}

/** A DATE from YYYY-MM-DD, [plusDays] later: 20261018. */
export function icsDate(date: string, plusDays = 0): string {
  const [y, m, d] = date.split('-').map(Number);
  const day = new Date(Date.UTC(y, m - 1, d + plusDays));
  return `${day.getUTCFullYear()}${two(day.getUTCMonth() + 1)}${two(day.getUTCDate())}`;
}

/** The title a calendar shows: "Canceled: " first, then the team on a link for all teams. */
export function feedTitle(e: FeedEvent): string {
  return `${e.canceled ? 'Canceled: ' : ''}${e.team ? `${e.team} · ` : ''}${e.title}`;
}

/** The place, as one line: its name and its address. */
export function feedPlace(location: CalendarEvent['location']): string {
  if (!location) return '';
  const name = location.name.trim();
  const address = location.address.trim();
  if (!name) return address;
  if (!address || address.toLowerCase().includes(name.toLowerCase())) return address || name;
  return `${name}, ${address}`;
}

/** The notes: arrival time for games, the event's own notes, and the way back to it. */
export function feedNotes(e: FeedEvent): string {
  const arrive = e.arriveMinutesBefore && e.arriveMinutesBefore > 0 ? `Arrive ${e.arriveMinutesBefore} minutes early.` : '';
  return [arrive, e.description.trim(), `Open in Battleplan: ${e.url}`].filter(Boolean).join('\n\n');
}

function eventLines(e: FeedEvent, stamp: string): string[] {
  const allDay = e.allDay && e.startDate !== null && e.endDate !== null;
  const place = feedPlace(e.location);
  return [
    'BEGIN:VEVENT',
    `UID:${e.id}@getbattleplan.app`,
    `DTSTAMP:${stamp}`,
    ...(e.updatedMs > 0 ? [`LAST-MODIFIED:${icsTime(e.updatedMs)}`] : []),
    ...(allDay
      ? [`DTSTART;VALUE=DATE:${icsDate(e.startDate!)}`, `DTEND;VALUE=DATE:${icsDate(e.endDate!, 1)}`]
      : [`DTSTART:${icsTime(e.startMs)}`, `DTEND:${icsTime(Math.max(e.endMs, e.startMs))}`]),
    `SUMMARY:${icsText(feedTitle(e))}`,
    ...(place ? [`LOCATION:${icsText(place)}`] : []),
    `DESCRIPTION:${icsText(feedNotes(e))}`,
    `URL:${e.url}`,
    `STATUS:${e.canceled ? 'CANCELLED' : 'CONFIRMED'}`,
    'TRANSP:OPAQUE',
    'END:VEVENT',
  ];
}

/**
 * A whole calendar named [name] with [events]. It asks calendar apps to
 * check again hourly (REFRESH-INTERVAL, RFC 7986, and Outlook's
 * X-PUBLISHED-TTL); Google Calendar keeps its own schedule.
 */
export function buildCalendar(name: string, events: FeedEvent[], nowMs: number): string {
  const stamp = icsTime(nowMs);
  const lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Battleplan//Schedule//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    `NAME:${icsText(name)}`,
    `X-WR-CALNAME:${icsText(name)}`,
    'REFRESH-INTERVAL;VALUE=DURATION:PT1H',
    'X-PUBLISHED-TTL:PT1H',
    ...events.flatMap((e) => eventLines(e, stamp)),
    'END:VCALENDAR',
  ];
  // Lines end in CRLF (§3.1).
  return `${lines.map(foldLine).join('\r\n')}\r\n`;
}
