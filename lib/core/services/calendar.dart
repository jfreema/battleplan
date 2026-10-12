/// An event as a calendar app takes it (SCHED-10).
class CalendarEntry {
  const new({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.timeZone,
    this.description = '',
    this.location = '',
    this.allDay = false,
    this.startDate,
    this.endDate,
    this.url,
  });

  /// Stable across adds, so a calendar can tell it's the same event.
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime start;
  final DateTime end;
  final String timeZone;
  final bool allDay;

  /// All-day events: the first day and the day after the last, as dates
  /// that never shift (SCHED-9).
  final DateTime? startDate;
  final DateTime? endDate;

  /// A link back to the event in the app.
  final Uri? url;
}

/// Adds an event to the person's calendar (ARCH §5.2 rule 8): the native
/// sheet on iOS and Android, an .ics download on the web (SCHED-10).
/// Returns false if nothing could be offered here.
abstract interface class CalendarAdder {
  Future<bool> add(CalendarEntry entry);
}

class NoopCalendarAdder implements CalendarAdder {
  const new();

  @override
  Future<bool> add(CalendarEntry entry) async => false;
}

/// An iCalendar file (RFC 5545) with one event, for the web download.
/// Timed events are in UTC; all-day events use dates.
String buildIcs(CalendarEntry e, {required DateTime now}) {
  String two(int n) => n.toString().padLeft(2, '0');
  String date(DateTime d) => '${d.year}${two(d.month)}${two(d.day)}';
  String stamp(DateTime d) {
    final u = d.toUtc();
    return '${date(u)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
  }

  String text(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll(RegExp(r'\r?\n'), r'\n');

  final allDay = e.allDay && e.startDate != null && e.endDate != null;
  final lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Battleplan//Schedule//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    'UID:${e.id}@getbattleplan.app',
    'DTSTAMP:${stamp(now)}',
    if (allDay) ...[
      'DTSTART;VALUE=DATE:${date(e.startDate!)}',
      'DTEND;VALUE=DATE:${date(e.endDate!)}',
    ] else ...[
      'DTSTART:${stamp(e.start)}',
      'DTEND:${stamp(e.end)}',
    ],
    'SUMMARY:${text(e.title)}',
    if (e.description.isNotEmpty) 'DESCRIPTION:${text(e.description)}',
    if (e.location.isNotEmpty) 'LOCATION:${text(e.location)}',
    if (e.url != null) 'URL:${e.url}',
    'END:VEVENT',
    'END:VCALENDAR',
  ];
  // Lines end in CRLF (RFC 5545 §3.1).
  return '${lines.join('\r\n')}\r\n';
}
