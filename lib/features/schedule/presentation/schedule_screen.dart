import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
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
    final filtered = options.filters.isNotEmpty || options.allTeams;

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
                shape: full ? const GumdropShape() : null,
                onPressed: () => full
                    ? showStorageFull(context)
                    : unawaited(
                        context.push('/g/${groupId.value}/schedule/new'),
                      ),
                child: const Icon(AppIcons.add, size: 28, weight: 700),
              )
            : null,
        body: Column(
          children: [
            // Upcoming, Past, Calendar, and the filter, on a hairline.
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.divider)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _Segments(
                        labels: [
                          l10n.scheduleUpcoming,
                          l10n.schedulePast,
                          l10n.scheduleCalendar,
                        ],
                      ),
                    ),
                    MergeSemantics(
                      child: Semantics(
                        value: filtered ? l10n.scheduleFilterOn : null,
                        child: IconButton(
                          tooltip: l10n.scheduleFilter,
                          constraints: const BoxConstraints.tightFor(
                            width: 48,
                            height: 48,
                          ),
                          padding: EdgeInsets.zero,
                          color: c.textOnPage,
                          onPressed: () =>
                              unawaited(_openFilters(context, teamCount)),
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(AppIcons.filter, size: 24),
                              if (filtered)
                                Positioned(
                                  top: -2,
                                  right: -3,
                                  child: Container(
                                    width: 13,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: c.page,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: c.cherry.face,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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

  /// The filter sheet (SCHED-2): the type chips and, with more than one
  /// team, All my teams. Changes apply at once.
  Future<void> _openFilters(BuildContext context, int teamCount) =>
      showCardSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _FilterSheet(teamCount: teamCount),
      );
}

class _FilterSheet extends ConsumerWidget {
  const new({required this.teamCount});

  final int teamCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final options = ref.watch(scheduleViewProvider);
    final notifier = ref.read(scheduleViewProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(l10n.scheduleFilter),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in EventFilter.values)
                  FilterChip(
                    label: Text(filterLabel(l10n, f)),
                    selected: options.filters.contains(f),
                    showCheckmark: false,
                    onSelected: (_) => notifier.toggleFilter(f),
                  ),
              ],
            ),
            if (teamCount > 1) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.scheduleAllTeams),
                value: options.allTeams,
                onChanged: (on) => notifier.setAllTeams(on: on),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Upcoming, Past and Calendar (SPEC §7.3): Fredoka 600 17, left-aligned,
/// 24 px apart, the current one in the text color over a 4 px coral bar.
/// Labels shrink rather than run under the filter at large text sizes.
class _Segments extends StatefulWidget {
  const new({required this.labels});

  final List<String> labels;

  @override
  State<_Segments> createState() => _SegmentsState();
}

class _SegmentsState extends State<_Segments> {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = DefaultTabController.of(context);
    if (next != _controller) {
      _controller?.removeListener(_changed);
      _controller = next..addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _controller?.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final controller = _controller!;
    final style = GumdropStyle.of(context);
    final n = widget.labels.length;
    return Row(
      children: [
        for (final (i, label) in widget.labels.indexed) ...[
          Flexible(
            child: Semantics(
              selected: controller.index == i,
              button: true,
              label: MaterialLocalizations.of(context)
                  .tabLabel(tabIndex: i + 1, tabCount: n),
              child: FocusRingInk(
                onTap: () => controller.animateTo(i),
                radius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: style.label(
                            TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: controller.index == i
                                  ? c.textOnPage
                                  : c.textMutedOnPage,
                            ),
                          ),
                        ),
                      ),
                      if (controller.index == i)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -2,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: c.you.face,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (i < n - 1) const SizedBox(width: 24),
        ],
      ],
    );
  }
}

/// Opens an event's details (SCHED-4).
/// [from] is the opener's name, for the event screen's back label.
void openEvent(BuildContext context, Event e, {String? from}) => unawaited(
  context.push(
    '/g/${e.groupId.value}/schedule/e/${e.id.value}',
    extra: BackLabel(from),
  ),
);

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
      // Clear of the + button and the tab bar.
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: events.length + (more ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == events.length) {
          return Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Center(
              child: state.loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      style: GumdropButtons.of(context).link(),
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
    // A basic group counts its members (TEAM-14).
    final players = (group?.hasPlayers ?? true)
        ? ref.watch(playersProvider(g)).value?.length ?? 0
        : 0;
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
    final upcoming =
        group != null &&
        participants.isNotEmpty &&
        event.takesRsvps &&
        !event.isCanceled &&
        event.endAt.isAfter(now);
    // Closed (past the deadline, say): the rows stay, to show my answers,
    // but can't change.
    final canAnswer =
        upcoming &&
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
      onTap: () => openEvent(
        context,
        event,
        from: AppLocalizations.of(context).tabSchedule,
      ),
      answerButtons: upcoming
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in participants)
                  RsvpButtons(
                    event: event,
                    participant: p,
                    answer: answers[p.id],
                    label: cardRsvpLabel(AppLocalizations.of(context), p),
                    enabled: canAnswer,
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
