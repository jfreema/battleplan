import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/presentation/schedule_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Your schedule on Teams (SCHED-2), under my teams: what's next across
/// every active team and group I'm on, soonest first, as the schedule's
/// cards, each naming its team (and my player, PLAYER-9) and answered
/// right there (SCHED-4). The next [yourScheduleShown] that aren't over,
/// then See all, which opens [YourScheduleScreen].
///
/// Teams is the app's home, so it listens lightly (ARCH §10.2): each
/// team's next [yourScheduleLive] events, my answers on the ones shown,
/// and nothing once a team opens, which disposes every provider here.
class YourScheduleSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only whether there's a team: the list itself changes with every
    // message in any of them.
    if (ref.watch(yourScheduleTeamsProvider.select((t) => t.isEmpty))) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final zone = ref.watch(viewerTimeZoneProvider).value;
    final state = ref.watch(
      yourScheduleEventsProvider(past: false, limit: yourScheduleLive),
    );
    // What's next: an event that's over today is left to the page's
    // Upcoming, which runs from the start of today as a team's does.
    final now = ref.watch(minuteClockProvider);
    final shown = [
      for (final e in state.events)
        if (e.endAt.isAfter(now)) e,
    ].take(yourScheduleShown).toList();
    // The cards wait for who I answer for on each team shown, so they
    // arrive whole rather than growing their RSVP rows a moment later.
    var ready = !state.loading;
    for (final g in {for (final e in shown) e.groupId}) {
      if (!ref.watch(myParticipantsReadyProvider(g))) ready = false;
    }
    final range = _range(shown);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        // On the rows' 20 px gutter; the cards reach 4 px past it, in line
        // with the team cards.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: PageHeading(l10n.yourSchedule),
        ),
        const SizedBox(height: 4),
        if (zone != null && ready && shown.isNotEmpty)
          for (final e in shown)
            ScheduleEventRow(
              key: ValueKey(e.id.value),
              event: e,
              viewerZone: zone,
              day: dayOf(e, zone),
              showTeam: true,
              openedFrom: l10n.tabTeams,
              padding: const EdgeInsets.symmetric(vertical: 6),
              rsvpRange: range,
            )
        // Said only once every team has answered with nothing to come.
        else if (ready && state.reachedEnd)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            child: Text(
              l10n.scheduleEmptyUpcoming,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: GumdropColors.of(context).textMutedOnPage,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: PageRow(
            icon: AppIcons.schedule,
            title: l10n.yourScheduleSeeAll,
            semanticsLabel: l10n.yourScheduleSeeAllLabel,
            onTap: () => unawaited(context.push('/teams/schedule')),
          ),
        ),
      ],
    );
  }

  /// The window "My RSVPs" reads on each team shown (ARCH §6.2): from the
  /// earliest card's start to just past the latest's, so Teams reads my
  /// answers on these events and no others. By start, not by place in the
  /// list, which is in day order with all-day events first.
  ({DateTime? from, DateTime? until}) _range(List<Event> shown) {
    DateTime? first;
    DateTime? last;
    for (final e in shown) {
      if (first == null || e.startAt.isBefore(first)) first = e.startAt;
      if (last == null || e.startAt.isAfter(last)) last = e.startAt;
    }
    return (from: first, until: last?.add(const Duration(milliseconds: 1)));
  }
}

/// Your schedule at `/teams/schedule` (SCHED-2), from See all on Teams:
/// Upcoming, Past, and Calendar across every active team and group I'm
/// on, each event naming its team and opening in it, in my default color
/// scheme. No +: events are made in a team.
class YourScheduleScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: l10n.yourSchedule,
        backLabel: l10n.tabTeams,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.contentMax),
          child: const ScheduleTabs(),
        ),
      ),
    );
  }
}
