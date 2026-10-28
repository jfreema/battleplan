import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
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
import 'package:battleplan/features/schedule/presentation/event_details_screen.dart';
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

    final c = GumdropColors.of(context);
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);

    Widget filter({
      required String label,
      required bool selected,
      required GumdropAccent accent,
      required ValueChanged<bool> onSelected,
      bool? lit,
    }) {
      // The filter's own candy while its events show (design §3.7): when
      // it's on, and for every kind while none is picked (all show).
      // [selected] alone stays the chip's state for screen readers.
      final on = lit ?? selected;
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        showCheckmark: false,
        labelStyle: TextStyle(color: on ? c.ink : c.textPrimary),
        side: on ? BorderSide.none : null,
        color: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? c.well
              : on
              ? accent.face
              : c.raisedFace,
        ),
        shape: WidgetStateOutlinedBorder.resolveWith(
          (s) => GumdropStyle.of(context).styled(
            GumdropShape(
              lip: 3,
              lipColor: on ? accent.lip : c.raisedLip,
              highlight: on ? 2 : 1.5,
              highlightColor: on
                  ? GumdropColors.accentHighlight
                  : c.raisedHighlight,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(11, 5, 11, 8),
        labelPadding: EdgeInsets.zero,
      );
    }

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
                // stays, flat in the well's color, to say why.
                backgroundColor: full ? c.well : null,
                foregroundColor: full ? c.textMuted : null,
                shape: full
                    ? GumdropStyle.of(context).styled(const GumdropShape())
                    : null,
                onPressed: () => full
                    ? showStorageFull(context)
                    : unawaited(
                        context.push('/g/${groupId.value}/schedule/new'),
                      ),
                child: const Icon(AppIcons.add, weight: 700),
              )
            : null,
        body: Column(
          children: [
            // Upcoming, Past, Calendar: a well with the chosen view as a
            // gumdrop in it (design §3.7). Each tab stays 48 tall to tap.
            Container(
              margin: EdgeInsets.fromLTRB(gutter, 14, gutter, 0),
              decoration: BoxDecoration(
                color: c.well,
                borderRadius: BorderRadius.circular(23),
              ),
              child: TabBar(
                tabs: [
                  for (final label in [
                    l10n.scheduleUpcoming,
                    l10n.schedulePast,
                    l10n.scheduleCalendar,
                  ])
                    Tab(
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(label),
                      ),
                    ),
                ],
                indicator: ShapeDecoration(
                  color: c.you.face,
                  shape: GumdropStyle.of(context)
                      .styled(GumdropShape(lip: 3, lipColor: c.you.lip)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.fromLTRB(4, 4, 4, 3),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelColor: c.ink,
                unselectedLabelColor: c.textMuted,
                dividerHeight: 0,
                splashBorderRadius: BorderRadius.circular(23),
              ),
            ),
            // The filters wrap onto a second line rather than hiding off
            // the edge with large text.
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 0),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final f in EventFilter.values)
                      filter(
                        label: filterLabel(l10n, f),
                        selected: options.filters.contains(f),
                        lit:
                            options.filters.isEmpty ||
                            options.filters.contains(f),
                        accent: filterAccent(context, f),
                        onSelected: (_) => ref
                            .read(scheduleViewProvider.notifier)
                            .toggleFilter(f),
                      ),
                    if (teamCount > 1)
                      filter(
                        label: l10n.scheduleAllTeams,
                        selected: options.allTeams,
                        accent: c.you,
                        onSelected: (on) => ref
                            .read(scheduleViewProvider.notifier)
                            .setAllTeams(on: on),
                      ),
                  ],
                ),
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

/// Upcoming or Past (SCHED-1) for this team or all my teams, in day order,
/// each event a card with its date block.
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
    final days = [for (final e in events) dayOf(e, zone)];
    final more = !state.reachedEnd;
    // Built as they scroll into view, so a long list (or one with more
    // pages loaded) doesn't build every row and its RSVP lookups at once
    // (SPEC §8.1).
    return ListView.builder(
      padding: const EdgeInsets.only(top: 5, bottom: Space.xxxl * 2),
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
          // Every card has its date block (SCHED-1, design §3.15).
          day: days[i],
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
    // Upcoming events I can answer now: Going, Maybe, and Not going on the
    // card for each person I answer for, and a second tap on the chosen
    // one clears it (owner's request 2026-10-28).
    final now = DateTime.now();
    final me = ref.watch(myMembershipProvider(g));
    final canAnswer =
        group != null &&
        participants.isNotEmpty &&
        !event.startedBefore(now) &&
        canAnswerNow(event, group, me, now);
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
      answerButtons: canAnswer
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in participants)
                  RsvpButtons(
                    event: event,
                    participant: p,
                    answer: answers[p.id],
                    // Named only beside someone else's.
                    label: participants.length == 1
                        ? null
                        : answerLabel(
                            AppLocalizations.of(context),
                            p,
                            participants,
                          ),
                    enabled: true,
                    allowMaybe: group.settings.allowMaybe,
                    compact: true,
                    clearOnRepeat: true,
                  ),
              ],
            )
          : null,
    );
  }
}
