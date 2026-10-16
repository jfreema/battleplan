import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/schedule_rules.dart';
import 'package:battleplan/features/schedule/presentation/calendar_view.dart';
import 'package:battleplan/features/schedule/presentation/event_row.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The Schedule tab (SCHED-1, SCHED-2): Upcoming (default), Past, and
/// Calendar; the All my teams toggle and the type filter; and + for
/// people allowed to make events (Q12), which says why when storage is
/// full (STORE-4).
class ScheduleScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    final me = ref.watch(myMembershipProvider(groupId));
    final options = ref.watch(scheduleViewProvider);
    final teamCount = ref.watch(scheduleTeamsProvider).length;
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final canCreate =
        group != null && canCreateEvents(group, me, superAdmin: superAdmin);
    final full = group?.storageFull ?? false;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButton: canCreate
            ? FloatingActionButton(
                // The team's tabs stay built side by side, and Documents
                // has one too: no shared hero tag between them.
                heroTag: null,
                tooltip: l10n.eventNew,
                // Full storage stops new events (STORE-4); the button
                // stays, greyed, to say why.
                backgroundColor: full
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
                onPressed: () => full
                    ? showStorageFull(context)
                    : unawaited(
                        context.push('/g/${groupId.value}/schedule/new'),
                      ),
                child: const Icon(AppIcons.add),
              )
            : null,
        body: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: l10n.scheduleUpcoming),
                Tab(text: l10n.schedulePast),
                Tab(text: l10n.scheduleCalendar),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: Space.gutter(MediaQuery.sizeOf(context).width),
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  if (teamCount > 1) ...[
                    FilterChip(
                      avatar: const Icon(AppIcons.group, size: 18),
                      label: Text(l10n.scheduleAllTeams),
                      selected: options.allTeams,
                      onSelected: (on) => ref
                          .read(scheduleViewProvider.notifier)
                          .setAllTeams(on: on),
                    ),
                    const SizedBox(width: Space.md),
                  ],
                  for (final f in EventFilter.values) ...[
                    FilterChip(
                      label: Text(filterLabel(l10n, f)),
                      selected: options.filters.contains(f),
                      onSelected: (_) => ref
                          .read(scheduleViewProvider.notifier)
                          .toggleFilter(f),
                    ),
                    const SizedBox(width: Space.sm),
                  ],
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  EventList(groupId: groupId, past: false),
                  EventList(groupId: groupId, past: true),
                  CalendarView(groupId: groupId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens an event's details (SCHED-4).
void openEvent(BuildContext context, Event e) =>
    unawaited(context.push('/g/${e.groupId.value}/schedule/e/${e.id.value}'));

/// Upcoming or Past (SCHED-1) for this team or all my teams, grouped by
/// day with a date block on each day's first row.
class EventList extends ConsumerWidget {
  const new({required this.groupId, required this.past, super.key});

  final GroupId groupId;
  final bool past;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final options = ref.watch(scheduleViewProvider);
    final zone = ref.watch(viewerTimeZoneProvider).value;
    final state = options.allTeams
        ? ref.watch(allTeamsEventsProvider(past: past))
        : ref.watch(teamEventsProvider(groupId, past: past));
    if (zone == null || (state.loading && state.events.isEmpty)) {
      return const SkeletonList();
    }
    final events = [
      for (final e in state.events)
        if (options.shows(e)) e,
    ];
    if (events.isEmpty && state.reachedEnd) {
      return EmptyState(
        icon: AppIcons.schedule,
        message: past ? l10n.scheduleEmptyPast : l10n.scheduleEmptyUpcoming,
      );
    }
    final range = _range(state.events, zone);
    // Each row's date block shows only on the first event of its day.
    final days = [for (final e in events) dayOf(e, zone)];
    final more = !state.reachedEnd;
    // Built as they scroll into view, so a long list (or one with more
    // pages loaded) doesn't build every row and its RSVP lookups at once
    // (SPEC §8.1).
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: Space.xxxl * 2),
      itemCount: events.length + (more ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == events.length) {
          return Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Center(
              child: state.loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: () => unawaited(_loadMore(ref, options)),
                      child: Text(l10n.scheduleLoadMore),
                    ),
            ),
          );
        }
        final e = events[i];
        return ScheduleEventRow(
          key: ValueKey(e.id.value),
          event: e,
          viewerZone: zone,
          day: i > 0 && days[i] == days[i - 1] ? null : days[i],
          showTeam: options.allTeams,
          rsvpRange: range,
        );
      },
    );
  }

  /// The window "My RSVPs" reads (ARCH §6.2): Upcoming from today on;
  /// Past, from the oldest event shown up to today, so it reads the
  /// answers on the events shown rather than the oldest ones. Either
  /// stretches to take in all-day events, which go by their own dates and
  /// can start the other side of today (SCHED-9).
  ({DateTime? from, DateTime? until}) _range(List<Event> shown, String zone) {
    final today = startOfDay(zone, DateTime.now());
    DateTime? first;
    DateTime? last;
    for (final e in shown) {
      if (first == null || e.startAt.isBefore(first)) first = e.startAt;
      if (last == null || e.startAt.isAfter(last)) last = e.startAt;
    }
    if (!past) {
      return (
        from: first != null && first.isBefore(today) ? first : today,
        until: null,
      );
    }
    final end = last?.add(const Duration(milliseconds: 1));
    return (
      from: first ?? today,
      until: end != null && end.isAfter(today) ? end : today,
    );
  }

  Future<void> _loadMore(WidgetRef ref, ScheduleOptions options) async {
    final teams = options.allTeams
        ? [for (final g in ref.read(scheduleTeamsProvider)) g.id]
        : [groupId];
    for (final id in teams) {
      await ref.read(teamEventsProvider(id, past: past).notifier).loadMore();
    }
  }
}

/// An [EventRow] with its team, my players, and my answers looked up.
class ScheduleEventRow extends ConsumerWidget {
  const new({
    required this.event,
    required this.viewerZone,
    required this.rsvpRange,
    this.day,
    this.showTeam = false,
    super.key,
  });

  final Event event;
  final String viewerZone;
  final DateTime? day;
  final bool showTeam;

  /// Which "My RSVPs" window holds this event's answers.
  final ({DateTime? from, DateTime? until}) rsvpRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = event.groupId;
    final group = ref.watch(groupProvider(g)).value;
    final participants = ref.watch(myParticipantsProvider(g));
    final players = ref.watch(playersProvider(g)).value?.length ?? 0;
    final answers =
        ref
            .watch(
              myRsvpsProvider(g, from: rsvpRange.from, until: rsvpRange.until),
            )
            .value?[event.id.value] ??
        const {};
    // Signed-out moments while the app tears down show nothing.
    if (ref.watch(authUserProvider).value == null) {
      return const SizedBox.shrink();
    }
    return EventRow(
      event: event,
      group: group,
      viewerZone: viewerZone,
      day: day,
      participants: participants,
      answers: answers,
      showTeam: showTeam,
      playerCount: players,
      onTap: () => openEvent(context, event),
    );
  }
}
