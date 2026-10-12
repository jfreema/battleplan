import 'dart:async';
import 'dart:js_interop';

import 'package:battleplan/core/services/calendar.dart';
import 'package:web/web.dart' as web;

/// Browsers: downloads an .ics file the calendar app opens.
Future<bool> addToCalendar(CalendarEntry e) async {
  final ics = buildIcs(e, now: DateTime.now());
  final blob = web.Blob(
    [ics.toJS].toJS,
    web.BlobPropertyBag(type: 'text/calendar;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final name = e.title.replaceAll(RegExp(r'[^\w\- ]+'), '').trim();
  web.HTMLAnchorElement()
    ..href = url
    ..download = '${name.isEmpty ? 'event' : name}.ics'
    ..click();
  // Some browsers start the download after click() returns.
  unawaited(
    Future<void>.delayed(
      const Duration(seconds: 5),
      () => web.URL.revokeObjectURL(url),
    ),
  );
  return true;
}
