import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
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
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/players.dart';
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

/// A team's Schedule tab (SCHED-1, SCHED-2): its own events as
/// [ScheduleTabs], and + for people allowed to make events (Q12), which
/// says why when storage is full (STORE-4).
class ScheduleScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    final me = ref.watch(myMembershipProvider(groupId));
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final canCreate =
        group != null && canCreateEvents(group, me, superAdmin: superAdmin);
    final full = group?.storageFull ?? false;
    // Import a schedule beside the +, for the team's admins (#22): coaches
    // coming from TeamSnap found it only in Team settings. Not while the
    // empty Upcoming offers it already (#3), so it's never there twice.
    final upcoming = ref.watch(teamEventsProvider(groupId, past: false));
    final filtered = ref.watch(
      scheduleViewProvider.select((o) => o.filters.isNotEmpty),
    );
    final emptyOffersImport =
        !filtered && upcoming.reachedEnd && upcoming.events.isEmpty;
    // Nor before the first page, so it doesn't come and go.
    final unknown = upcoming.loading && upcoming.events.isEmpty;
    // canCreate rules out an archived team.
    final canImport =
        canCreate && (me?.isAdmin ?? false) && !emptyOffersImport && !unknown;

    final c = GumdropColors.of(context);
    final plus = canCreate
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
                : unawaited(context.push('/g/${groupId.value}/schedule/new')),
            child: const Icon(AppIcons.add, size: 28, weight: 700),
          )
        : null;

    void openImport() => unawaited(
      context.push(
        '/g/${groupId.value}/import',
        extra: BackLabel(l10n.tabSchedule),
      ),
    );
    // With large text, or on a narrow phone, the words would crowd the +:
    // the icon alone then, with its name as the tooltip.
    final roomy =
        MediaQuery.sizeOf(context).width >= 340 &&
        MediaQuery.textScalerOf(context).scale(15) <= 15 * 1.3;
    final buttons = GumdropButtons.of(context);
    final onPage = WidgetStatePropertyAll(c.page);
    // Quiet: outlined, on the page's color, so it reads over the list
    // scrolling under it.
    final import = roomy
        ? OutlinedButton.icon(
            style: buttons
                .secondary(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                )
                .copyWith(backgroundColor: onPage),
            onPressed: openImport,
            icon: const Icon(AppIcons.download, size: 20),
            label: Text(
              l10n.scheduleImport,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : IconButton(
            style: buttons.icon(size: 44).copyWith(backgroundColor: onPage),
            tooltip: l10n.scheduleImport,
            onPressed: openImport,
            icon: const Icon(AppIcons.download, size: 22),
          );

    return Scaffold(
      floatingActionButton: plus == null || !canImport
          ? plus
          : Row(
              mainAxisSize: MainAxisSize.min,
              // Never past the screen's edge: the words give way first.
              children: [
                Flexible(child: import),
                const SizedBox(width: Space.md),
                plus,
              ],
            ),
      body: ScheduleTabs(groupId: groupId),
    );
  }
}

/// Upcoming (default), Past, and Calendar with the type filter beside them
/// (SCHED-1, SCHED-2): one team's events, or with no [groupId] those of
/// every team and group in Your schedule, each naming its team.
class ScheduleTabs extends ConsumerWidget {
  const new({this.groupId, super.key});

  /// Null is Your schedule (SCHED-2).
  final GroupId? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final filtered = ref.watch(
      scheduleViewProvider.select((o) => o.filters.isNotEmpty),
    );
    return DefaultTabController(
      length: 3,
      child: Column(
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
                        onPressed: () => unawaited(_openFilters(context)),
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
                                    // Coral: a setting of mine is on, not
                                    // a warning (SCHED-2).
                                    decoration: BoxDecoration(
                                      color: c.you.face,
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
    );
  }

  /// The filter sheet (SCHED-2): the type chips. Changes apply at once.
  Future<void> _openFilters(BuildContext context) => showCardSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerWidget {
  const new();

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
          ],
        ),
      ),
    );
  }
}

/// Upcoming, Past and Calendar (SPEC §7.3): Fredoka 600 17, left-aligned,
/// 24 px apart, the current one in the text color over a 4 px coral bar.
/// Each is at least 48 × 48 to tap, and the space between them is tappable
/// too. Labels shrink rather than run under the filter at large text sizes.
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
    // As a tab reads: its name, then "Tab 2 of 3".
    final where = MaterialLocalizations.of(context);
    String spoken(int i, String label) =>
        '$label, ${where.tabLabel(tabIndex: i + 1, tabCount: n)}';
    return Row(
      children: [
        for (final (i, label) in widget.labels.indexed)
          Flexible(
            child: Semantics(
              selected: controller.index == i,
              button: true,
              label: spoken(i, label),
              excludeSemantics: true,
              onTap: () => controller.animateTo(i),
              child: FocusRingInk(
                onTap: () => controller.animateTo(i),
                radius: BorderRadius.circular(8),
                // At least 48 × 48 to tap. The 24 between the words is
                // half each neighbor's, so a tap there counts too.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: i == 0 ? 0 : 12,
                      end: i == n - 1 ? 0 : 12,
                    ),
                    // The bar stays the word's width.
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
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
              ),
            ),
          ),
      ],
    );
  }
}

/// "Sync to my calendar" at the top of Upcoming (SCHED-11, #22): a quiet
/// row, muted, that opens the calendar link which keeps Google, Apple or
/// Outlook Calendar up to date, for this team or, on Your schedule, for
/// every team. People who live in their phone's calendar found it only in
/// Team settings. Nothing for someone not on the team (a super admin
/// viewing it) or with no team.
class _SyncRow extends ConsumerWidget {
  const new({required this.groupId});

  /// The team; null on Your schedule.
  final GroupId? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final team = groupId;
    final shown = team == null
        ? ref.watch(yourScheduleTeamsProvider).isNotEmpty
        : ref.watch(myMembershipProvider(team).select((m) => m != null));
    if (!shown) return const SizedBox(height: 8);
    void open() => unawaited(
      team == null
          ? context.push('/teams/calendar', extra: BackLabel(l10n.yourSchedule))
          : context.push(
              '/g/${team.value}/calendar',
              extra: BackLabel(l10n.tabSchedule),
            ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
      child: FocusRingInk(
        onTap: open,
        radius: BorderRadius.circular(12),
        child: Semantics(
          button: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    AppIcons.calendarLink,
                    size: 20,
                    color: c.textMutedOnPage,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.scheduleSyncCalendar,
                      style: GumdropStyle.of(context).label(
                        TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.textMutedOnPage,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    AppIcons.chevronRight,
                    size: 18,
                    weight: 700,
                    color: c.textMutedOnPage,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A team's empty Upcoming (SCHED-1, #3): **Add an event** for whoever can
/// make events, doing what the + does (full storage says why, STORE-4),
/// and for the team's admins a quiet **Import a schedule** under it. People
/// who can't make events are told who will: the coaches, or a group's
/// admins (TEAM-14). An archived team just has nothing coming up.
class _EmptyUpcoming extends ConsumerWidget {
  const new({required this.groupId});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    final me = ref.watch(myMembershipProvider(groupId));
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final id = groupId.value;
    if (group == null || group.isArchived) {
      return EmptyState(
        icon: AppIcons.schedule,
        message: l10n.scheduleEmptyUpcoming,
      );
    }
    if (!canCreateEvents(group, me, superAdmin: superAdmin)) {
      return EmptyState(
        icon: AppIcons.schedule,
        message: group.isGroup
            ? l10n.scheduleEmptyAdmins
            : l10n.scheduleEmptyCoaches,
      );
    }
    // Import is the team admins' (Team settings, For admins).
    final admin = me?.isAdmin ?? false;
    return EmptyState(
      icon: AppIcons.schedule,
      message: l10n.scheduleEmptyUpcoming,
      actionLabel: l10n.scheduleAddEvent,
      onAction: () => group.storageFull
          ? showStorageFull(context)
          : unawaited(context.push('/g/$id/schedule/new')),
      linkLabel: admin ? l10n.scheduleImport : null,
      onLink: admin
          ? () => unawaited(
              context.push('/g/$id/import', extra: BackLabel(l10n.tabSchedule)),
            )
          : null,
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

/// Upcoming or Past (SCHED-1) for one team, or with no [groupId] for Your
/// schedule (SCHED-2), in day order, each event a card with its date block.
class EventList extends ConsumerWidget {
  const new({required this.past, this.groupId, super.key});

  /// Null is Your schedule: every active team's, each card naming its team.
  final GroupId? groupId;
  final bool past;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final options = ref.watch(scheduleViewProvider);
    final zone = ref.watch(viewerTimeZoneProvider).value;
    final team = groupId;
    final state = team == null
        ? ref.watch(yourScheduleEventsProvider(past: past))
        : ref.watch(teamEventsProvider(team, past: past));
    if (zone == null || (state.loading && state.events.isEmpty)) {
      return const SkeletonList();
    }
    final events = [
      for (final e in state.events)
        if (options.shows(e)) e,
    ];
    if (events.isEmpty && state.reachedEnd) {
      // A team's Upcoming with nothing coming up and no filter on: its one
      // next step (#3). Past, a filtered view and Your schedule just say
      // there's nothing.
      final empty = team != null && !past && options.filters.isEmpty
          ? _EmptyUpcoming(groupId: team)
          : EmptyState(
              icon: AppIcons.schedule,
              message: past
                  ? l10n.scheduleEmptyPast
                  : l10n.scheduleEmptyUpcoming,
            );
      if (past) return empty;
      // Sync to my calendar stays at the top (#22).
      return Column(
        children: [
          _SyncRow(groupId: team),
          Expanded(child: empty),
        ],
      );
    }
    final range = _range(state.events, zone);
    final days = [for (final e in events) dayOf(e, zone)];
    final more = !state.reachedEnd;
    // Built as they scroll into view, so a long list (or one with more
    // pages loaded) doesn't build every row and its RSVP lookups at once
    // (SPEC §8.1).
    // Upcoming starts with Sync to my calendar (#22), which scrolls away
    // with the list.
    final sync = past ? 0 : 1;
    return ListView.builder(
      // Clear of the + button and the tab bar; Your schedule has neither.
      padding: EdgeInsets.only(
        top: past ? 8 : 0,
        bottom: team == null ? Space.xl : 96,
      ),
      itemCount: sync + events.length + (more ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < sync) return _SyncRow(groupId: team);
        final i = index - sync;
        if (i == events.length) {
          return Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Center(
              child: state.loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      style: GumdropButtons.of(context).link(),
                      onPressed: () => unawaited(_loadMore(ref)),
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
          showTeam: team == null,
          openedFrom: team == null ? l10n.yourSchedule : null,
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

  Future<void> _loadMore(WidgetRef ref) async {
    final teams = switch (groupId) {
      final team? => [team],
      null => [for (final g in ref.read(yourScheduleTeamsProvider)) g.id],
    };
    for (final id in teams) {
      await ref.read(teamEventsProvider(id, past: past).notifier).loadMore();
    }
  }
}

/// An [EventRow] with its team, my players, and my answers looked up, by
/// the event's own team, so it works in a team's schedule and in Your
/// schedule alike (SCHED-2).
class ScheduleEventRow extends ConsumerWidget {
  const new({
    required this.event,
    required this.viewerZone,
    required this.rsvpRange,
    this.day,
    this.showTeam = false,
    this.openedFrom,
    this.padding = EventRow.listPadding,
    super.key,
  });

  final Event event;
  final String viewerZone;
  final DateTime? day;
  final bool showTeam;

  /// What the event's back row says: where the card is, when that isn't a
  /// team's Schedule tab ("Teams", "Your schedule").
  final String? openedFrom;

  /// Around the card (see [EventRow.padding]).
  final EdgeInsetsGeometry padding;

  /// Which "My RSVPs" window holds this event's answers.
  final ({DateTime? from, DateTime? until}) rsvpRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
    // Not linked to a player yet (PLAYER-3): a card that shows a count and
    // no buttons says how to get them, or who I'm waiting on (owner's go
    // 2026-11-16). Only where answers are still to come, on a team with
    // players to pick from.
    final pick = ref.watch(myPlayerPickProvider(g));
    final open =
        group != null &&
        participants.isEmpty &&
        event.takesRsvps &&
        !event.isCanceled &&
        event.endAt.isAfter(now);
    final hint = !open
        ? null
        : pick.stage == PlayerPickStage.waiting
        ? _PlayerPickHint(waiting: playerPickWaitingText(l10n, pick))
        : pick.stage == PlayerPickStage.ask && players > 0
        ? _PlayerPickHint(onPick: () => openPlayerPick(context, g))
        : null;
    return EventRow(
      event: event,
      group: group,
      viewerZone: viewerZone,
      day: day,
      participants: participants,
      answers: answers,
      showTeam: showTeam,
      playerCount: players,
      padding: padding,
      hint: hint,
      onTap: () =>
          openEvent(context, event, from: openedFrom ?? l10n.tabSchedule),
      answerButtons: upcoming
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in participants)
                  RsvpButtons(
                    event: event,
                    participant: p,
                    answer: answers[p.id],
                    label: cardRsvpLabel(l10n, p),
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

/// The line on a schedule card for someone not linked to a player yet
/// (PLAYER-3), where the RSVP buttons would be: the link "Pick your player
/// to answer" ([onPick]), or, once they've asked, who they're waiting on
/// ([waiting]).
class _PlayerPickHint extends StatelessWidget {
  const new({this.onPick, this.waiting});

  final VoidCallback? onPick;
  final String? waiting;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final style = TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w700,
      fontSize: 14,
      height: 18 / 14,
      color: c.textMuted,
    );
    // Under the card's text, past its date column (38 wide, and 12 more).
    if (waiting case final text?) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: 50, top: 2, bottom: 8),
        child: Text(text, style: style),
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        // The quiet link, whose own padding is 8, at the text's edge.
        padding: const EdgeInsetsDirectional.only(start: 42),
        child: TextButton(
          style: GumdropButtons.of(context).link(textStyle: style),
          onPressed: onPick,
          child: Text(AppLocalizations.of(context).playerPickHint),
        ),
      ),
    );
  }
}
