import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// How the schedule writes events: type names, colors, and icons, times
/// in the viewer's zone (SCHED-9), counts, and series lines.

String typeLabel(AppLocalizations l10n, EventType type) => switch (type) {
  EventType.game => l10n.eventTypeGame,
  EventType.practice => l10n.eventTypePractice,
  EventType.meeting => l10n.eventTypeMeeting,
  EventType.social => l10n.eventTypeSocial,
  EventType.other => l10n.eventTypeOther,
};

/// The event-type color from the theme (ARCH §5.5).
Color typeColor(BuildContext context, EventType type) {
  final c = AppColors.of(context);
  return switch (type) {
    EventType.game => c.game,
    EventType.practice => c.practice,
    EventType.meeting => c.meeting,
    EventType.social => c.social,
    EventType.other => c.otherEvent,
  };
}

IconData typeIcon(EventType type) => switch (type) {
  EventType.game => AppIcons.game,
  EventType.practice => AppIcons.practice,
  EventType.meeting => AppIcons.meeting,
  EventType.social => AppIcons.social,
  EventType.other => AppIcons.event,
};

String filterLabel(AppLocalizations l10n, EventFilter f) => switch (f) {
  EventFilter.games => l10n.eventFilterGames,
  EventFilter.practices => l10n.eventFilterPractices,
  EventFilter.other => l10n.eventFilterOther,
};

String statusLabel(AppLocalizations l10n, RsvpStatus s) => switch (s) {
  RsvpStatus.going => l10n.rsvpGoing,
  RsvpStatus.maybe => l10n.rsvpMaybe,
  RsvpStatus.notGoing => l10n.rsvpNotGoing,
};

Color statusColor(BuildContext context, RsvpStatus s) {
  final c = AppColors.of(context);
  return switch (s) {
    RsvpStatus.going => c.going,
    RsvpStatus.maybe => c.maybe,
    RsvpStatus.notGoing => c.notGoing,
  };
}

IconData statusIcon(RsvpStatus s) => switch (s) {
  RsvpStatus.going => AppIcons.going,
  RsvpStatus.maybe => AppIcons.maybe,
  RsvpStatus.notGoing => AppIcons.notGoing,
};

/// "12 going · 3 maybe · 2 no" (SCHED-1), leaving out what's zero, and
/// Maybe when the team turned it off. On youth events these count players.
String countsText(
  AppLocalizations l10n,
  RsvpCounts counts, {
  bool allowMaybe = true,
}) {
  final parts = [
    if (counts.going > 0) l10n.rsvpCountGoing(counts.going),
    if (allowMaybe && counts.maybe > 0) l10n.rsvpCountMaybe(counts.maybe),
    if (counts.notGoing > 0) l10n.rsvpCountNo(counts.notGoing),
  ];
  return parts.isEmpty ? l10n.rsvpNoAnswers : parts.join(' · ');
}

/// "12 of 15 players going · 2 coaches" on youth events (PLAYER-6).
String playerCountsText(
  AppLocalizations l10n,
  Event event, {
  required int players,
}) => [
  l10n.rsvpPlayersGoing(event.rsvpCounts.going, players),
  if (event.staffCounts.going > 0) l10n.rsvpCoaches(event.staffCounts.going),
].join(' · ');

/// "6:00 PM" in [zone].
String timeIn(AppLocalizations l10n, DateTime instant, String zone) =>
    DateFormat.jm(l10n.localeName).format(ZonedTime.wallClock(zone, instant));

/// "Tue, Oct 13".
String dayLabel(AppLocalizations l10n, DateTime date) =>
    DateFormat.MMMEd(l10n.localeName).format(date);

/// "Oct 13".
String shortDate(AppLocalizations l10n, DateTime date) =>
    DateFormat.MMMd(l10n.localeName).format(date);

/// When an event happens, in the viewer's zone (SCHED-9): "6:00 PM –
/// 7:30 PM", or "All day". Without [withDay] the day is left to the row's
/// date block.
String timeRange(
  AppLocalizations l10n,
  Event e,
  String viewerZone, {
  bool withDay = false,
}) {
  if (e.allDay) {
    final first = e.startDate == null ? null : parseDateKey(e.startDate!);
    final last = e.endDate == null ? null : parseDateKey(e.endDate!);
    if (!withDay || first == null) return l10n.eventAllDay;
    if (last == null || last == first) {
      return '${dayLabel(l10n, first)} · ${l10n.eventAllDay}';
    }
    return '${dayLabel(l10n, first)} – ${dayLabel(l10n, last)} · '
        '${l10n.eventAllDay}';
  }
  final start = ZonedTime.wallClock(viewerZone, e.startAt);
  final end = ZonedTime.wallClock(viewerZone, e.endAt);
  final sameDay =
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  final range = sameDay
      ? '${timeIn(l10n, e.startAt, viewerZone)} – '
            '${timeIn(l10n, e.endAt, viewerZone)}'
      : '${timeIn(l10n, e.startAt, viewerZone)} – '
            '${dayLabel(l10n, end)} ${timeIn(l10n, e.endAt, viewerZone)}';
  return withDay ? '${dayLabel(l10n, start)} · $range' : range;
}

/// "6:00 PM CDT · 7:00 PM your time" when the event's zone shows a
/// different clock than the viewer's; null when they agree or it's all
/// day (SCHED-9).
String? otherZoneLine(AppLocalizations l10n, Event e, String viewerZone) {
  if (e.allDay) return null;
  if (ZonedTime.offsetAt(e.timeZone, e.startAt) ==
      ZonedTime.offsetAt(viewerZone, e.startAt)) {
    return null;
  }
  final theirs =
      '${timeIn(l10n, e.startAt, e.timeZone)} '
      '${ZonedTime.abbreviation(e.timeZone, e.startAt)}';
  return '$theirs · ${l10n.eventYourTime(timeIn(l10n, e.startAt, viewerZone))}';
}

/// "Tue and Thu", "Mon, Wed, and Fri".
String joinAnd(AppLocalizations l10n, List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.single;
  if (items.length == 2) return l10n.listTwo(items[0], items[1]);
  // gen-l10n orders the arguments by name: last, then rest.
  return l10n.listMany(
    items.last,
    items.sublist(0, items.length - 1).join(', '),
  );
}

/// "Tue" for ISO weekday [day] (Monday = 1).
String weekdayShort(AppLocalizations l10n, int day) =>
    // 2024-01-01 was a Monday.
    DateFormat.E(l10n.localeName).format(DateTime(2024, 1, day));

String weekdaysText(AppLocalizations l10n, List<int> days) => joinAnd(l10n, [
  for (final d in [...days]..sort()) weekdayShort(l10n, d),
]);

/// "24 practices", "1 game" (SCHED-3).
String eventCount(AppLocalizations l10n, EventType type, int count) =>
    switch (type) {
      EventType.game => l10n.countGames(count),
      EventType.practice => l10n.countPractices(count),
      EventType.meeting => l10n.countMeetings(count),
      EventType.social => l10n.countSocials(count),
      EventType.other => l10n.countEvents(count),
    };

/// The rule part of a series: "Tue and Thu", "Every 2 weeks on Tue",
/// "Every day", "Every 3 days".
String ruleText(AppLocalizations l10n, Recurrence r) => switch (r.freq) {
  RepeatFreq.daily =>
    r.interval == 1 ? l10n.repeatEveryDay : l10n.repeatEveryNDays(r.interval),
  RepeatFreq.weekly =>
    r.interval == 1
        ? weekdaysText(l10n, r.byWeekday)
        : l10n.repeatEveryNWeeksOn(r.interval, weekdaysText(l10n, r.byWeekday)),
};

/// The form's line under Repeat: "24 practices · Tue and Thu · Oct 13 –
/// Dec 17" (SCHED-3).
String seriesSummary(
  AppLocalizations l10n,
  EventType type,
  Recurrence rule,
  List<String> dates,
) {
  if (dates.isEmpty) return l10n.repeatNoDates;
  final first = shortDate(l10n, parseDateKey(dates.first));
  final last = shortDate(l10n, parseDateKey(dates.last));
  return [
    eventCount(l10n, type, dates.length),
    ruleText(l10n, rule),
    if (dates.length == 1) first else '$first – $last',
  ].join(' · ');
}

/// "Repeats weekly on Tue and Thu until Dec 17" (SCHED-4).
String repeatsLine(AppLocalizations l10n, Recurrence r) {
  final rule = switch (r.freq) {
    RepeatFreq.daily =>
      r.interval == 1 ? l10n.repeatsDaily : l10n.repeatsEveryNDays(r.interval),
    RepeatFreq.weekly =>
      r.interval == 1
          ? l10n.repeatsWeekly(weekdaysText(l10n, r.byWeekday))
          : l10n.repeatsEveryNWeeks(
              r.interval,
              weekdaysText(l10n, r.byWeekday),
            ),
  };
  if (r.untilDate != null) {
    // Arguments by name: date, then rule.
    return l10n.repeatsUntil(shortDate(l10n, parseDateKey(r.untilDate!)), rule);
  }
  if (r.count != null) return l10n.repeatsTimes(r.count!, rule);
  return rule;
}

/// "15 min", "1 h", "1 day", "1 week" before (SCHED-3).
String reminderLabel(AppLocalizations l10n, int minutes) {
  if (minutes % 10080 == 0) return l10n.reminderWeeks(minutes ~/ 10080);
  if (minutes % 1440 == 0) return l10n.reminderDays(minutes ~/ 1440);
  if (minutes % 60 == 0) return l10n.reminderHours(minutes ~/ 60);
  return l10n.reminderMinutes(minutes);
}
