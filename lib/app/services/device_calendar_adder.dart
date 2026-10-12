import 'package:battleplan/app/services/calendar_native.dart'
    if (dart.library.js_interop) 'package:battleplan/app/services/calendar_web.dart'
    as platform;
import 'package:battleplan/core/services/calendar.dart';

/// The platform's way of adding an event behind [CalendarAdder]
/// (SCHED-10): `add_2_calendar`'s native sheet on iOS and Android, an .ics
/// download in the browser.
class DeviceCalendarAdder implements CalendarAdder {
  const new();

  @override
  Future<bool> add(CalendarEntry entry) async {
    try {
      return await platform.addToCalendar(entry);
    } on Object {
      return false;
    }
  }
}
