import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/rsvp_history.dart';
import 'package:battleplan/features/schedule/schedule.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// PLAYER-11 at `/g/:groupId/roster/players/:playerId/history`: a player's
/// answers on the team's past events over the last 3, 6, or 12 months,
/// newest first, with totals out of the events that took RSVPs since the
/// player was added (canceled ones are listed but not counted). Each opens
/// its event. Only the player's linked members, the team's admins, and
/// super admins see it, as on the player card.
class PlayerRsvpHistoryScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, required this.playerId, super.key});

  final GroupId groupId;
  final PlayerId playerId;

  @override
  ConsumerState<PlayerRsvpHistoryScreen> createState() =>
      _PlayerRsvpHistoryScreenState();
}

class _PlayerRsvpHistoryScreenState
    extends ConsumerState<PlayerRsvpHistoryScreen> {
  /// Fixed while the screen is open, so the window's reads stay put.
  final DateTime _now = DateTime.now();
  int _months = rsvpHistoryMonths.first;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authUserProvider).value;
    final links =
        ref.watch(guardianLinksProvider(widget.groupId)).value ??
        const <GuardianLink>[];
    final allowed =
        (user?.isSuperAdmin ?? false) ||
        seesPlayerDetails(
          user?.uid,
          widget.playerId,
          teamAdmin:
              ref.watch(myMembershipProvider(widget.groupId))?.isAdmin ?? false,
          links: links,
        );
    final player = ref
        .watch(playersProvider(widget.groupId))
        .value
        ?.where((p) => p.id == widget.playerId)
        .firstOrNull;
    final from = DateTime(_now.year, _now.month - _months, _now.day);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rsvpHistoryTitle)),
      body: !allowed
          ? EmptyState(
              icon: AppIcons.history,
              message: l10n.rsvpHistoryNotYours,
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: Space.lg),
              children: [
                if (player != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                    child: Text(
                      player.label,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      for (final m in rsvpHistoryMonths)
                        ButtonSegment(
                          value: m,
                          label: Text(l10n.rsvpHistoryMonths(m)),
                        ),
                    ],
                    selected: {_months},
                    onSelectionChanged: (s) =>
                        setState(() => _months = s.first),
                  ),
                ),
                ...switch (ref.watch(
                  playerRsvpHistoryProvider(
                    widget.groupId,
                    widget.playerId,
                    from,
                    _now,
                  ),
                )) {
                  AsyncData(:final value) => _history(context, value),
                  AsyncError() => [
                    Padding(
                      padding: const EdgeInsets.all(Space.lg),
                      child: Text(l10n.loadError),
                    ),
                  ],
                  _ => [
                    const Padding(
                      padding: EdgeInsets.all(Space.xl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                },
              ],
            ),
    );
  }

  /// The totals, then each event with the player's answer.
  List<Widget> _history(BuildContext context, RsvpHistory history) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final zone = ref.watch(viewerTimeZoneProvider).value ?? 'UTC';
    final allowMaybe =
        ref.watch(groupProvider(widget.groupId)).value?.settings.allowMaybe ??
        true;
    if (history.entries.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Text(l10n.rsvpHistoryEmpty(_months)),
        ),
      ];
    }
    final totals = [
      (RsvpStatus.going, history.count(RsvpStatus.going)),
      if (allowMaybe || history.count(RsvpStatus.maybe) > 0)
        (RsvpStatus.maybe, history.count(RsvpStatus.maybe)),
      (RsvpStatus.notGoing, history.count(RsvpStatus.notGoing)),
    ];
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        child: Text(
          l10n.rsvpHistoryOf(history.eventCount),
          style: theme.textTheme.titleSmall,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
        child: Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final (status, n) in totals)
              Chip(
                avatar: Icon(
                  statusIcon(status),
                  color: statusColor(context, status),
                ),
                label: Text('${statusLabel(l10n, status)} · $n'),
              ),
            Chip(
              avatar: Icon(AppIcons.rsvp, color: scheme.outline),
              label: Text('${l10n.rsvpNoAnswer} · ${history.count(null)}'),
            ),
          ],
        ),
      ),
      const SizedBox(height: Space.md),
      for (final (:event, :answer) in history.entries)
        ListTile(
          title: Text(
            event.title,
            style: event.isCanceled
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: Text(timeRange(l10n, event, zone, withDay: true)),
          trailing: Text(
            event.isCanceled
                ? l10n.eventCanceled
                : answer == null
                ? l10n.rsvpNoAnswer
                : statusLabel(l10n, answer.status),
            style: TextStyle(
              color: event.isCanceled || answer == null
                  ? scheme.onSurfaceVariant
                  : statusColor(context, answer.status),
            ),
          ),
          onTap: () => context.push(
            '/g/${widget.groupId.value}/schedule/e/${event.id.value}',
          ),
        ),
    ];
  }
}
