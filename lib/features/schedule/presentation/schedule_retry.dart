import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Try again for the schedule's lists (#40): what each one listens to,
// started over, so it subscribes again and its placeholder rows show
// meanwhile. Invalidating a list made of others alone wouldn't: they keep
// their failure.

/// Starts Your schedule's lists over (#40): each team's, which are what
/// listen.
void retryYourSchedule(WidgetRef ref, {required bool past, int limit = 50}) {
  for (final g in ref.read(yourScheduleTeamsProvider)) {
    ref.invalidate(teamEventsProvider(g.id, past: past, limit: limit));
  }
}

/// Reads a month of the calendar again (#40): the two lists it's made of.
void retryMonth(WidgetRef ref, GroupId? groupId, DateTime month) {
  final zone = ref.read(viewerTimeZoneProvider).value;
  if (zone == null) return;
  final w = calendarWindow(zone, month);
  final teams = switch (groupId) {
    final team? => [team],
    null => [for (final g in ref.read(yourScheduleTeamsProvider)) g.id],
  };
  for (final team in teams) {
    ref
      ..invalidate(eventsInRangeProvider(team, w.from, w.until))
      ..invalidate(eventsBeforeProvider(team, w.from));
  }
}
