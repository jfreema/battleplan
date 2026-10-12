import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import 'package:battleplan/core/services/calendar.dart';

/// iOS and Android: the system's new-event sheet, filled in.
Future<bool> addToCalendar(CalendarEntry e) => cal.Add2Calendar.addEvent2Cal(
  cal.Event(
    title: e.title,
    description: e.description,
    location: e.location,
    startDate: e.allDay && e.startDate != null
        ? DateTime(e.startDate!.year, e.startDate!.month, e.startDate!.day)
        : e.start.toLocal(),
    // The calendar's all-day end is the last day itself.
    endDate: e.allDay && e.endDate != null
        ? DateTime(e.endDate!.year, e.endDate!.month, e.endDate!.day - 1)
        : e.end.toLocal(),
    timeZone: e.allDay ? null : e.timeZone,
    allDay: e.allDay,
    iosParams: cal.IOSParams(url: e.url?.toString()),
  ),
);
