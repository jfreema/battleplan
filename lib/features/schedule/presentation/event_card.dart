import 'dart:math' as math;

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/schedule_rules.dart';
import 'package:battleplan/features/schedule/presentation/event_details_screen.dart';
import 'package:battleplan/features/schedule/presentation/event_row.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/features/schedule/presentation/schedule_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// An event in the chat (CHAT-11): its type, title, day and time, and
/// place, kept live, so a canceled event shows struck through and a
/// deleted one says so. A series' card whose event is gone shows the
/// series' next event, or, with none left, the series as posted. While it
/// takes answers, it has Going / Maybe / Not going buttons (one set per
/// player for guardians) and the live counts, as in the chat mockup (SPEC
/// §5.4). Tapping elsewhere opens the event (SCHED-4). A card posted again
/// by hand says it's a reminder and how many players haven't answered
/// (SCHED-8).
class EventCard extends ConsumerWidget {
  const new({
    required this.eventId,
    required this.groupId,
    this.seriesId,
    this.text = '',
    this.reminder = false,
    super.key,
  });

  final EventId eventId;
  final GroupId groupId;

  /// The series a series' card was posted for.
  final String? seriesId;

  /// The card's one-line summary, as the server wrote it.
  final String text;

  /// Posted again by hand as a reminder (SCHED-8).
  final bool reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final style = GumdropStyle.of(context);
    var async = ref.watch(eventProvider(eventId));
    final zone = ref.watch(viewerTimeZoneProvider).value;
    // A card in the chat (design §3.5): the surface and its outline.
    final outline = c.surfaceBorderWidth == 0
        ? BorderSide.none
        : BorderSide(color: c.surfaceBorder, width: c.surfaceBorderWidth);
    final frame = style.cardDecoration(c.surface, Corners.panel, side: outline);
    // The card's event is gone, but its series goes on.
    var seriesLeft = false;
    if (seriesId case final s? when async.hasValue && async.value == null) {
      async = ref.watch(nextSeriesEventProvider(groupId, s));
      final series = ref.watch(eventSeriesProvider(s));
      seriesLeft = series.value != null;
      if (async.hasValue && async.value == null && series.isLoading) {
        async = const AsyncLoading();
      }
    }
    final event = async.value;
    if (event == null || zone == null) {
      return Container(
        width: 320,
        padding: const EdgeInsets.all(Space.md),
        decoration: frame,
        child: GumdropSurface(
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return async.isLoading || zone == null
                  ? const LinearProgressIndicator()
                  : seriesLeft && text.isNotEmpty
                  ? Text(text, style: theme.textTheme.bodyMedium)
                  : Text(
                      l10n.eventCardDeleted,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: GumdropColors.of(context).textMuted,
                      ),
                    );
            },
          ),
        ),
      );
    }
    final accent = typeAccent(context, event.type);
    return GumdropSurface(
      child: Material(
        color: c.surface,
        shape: style.cardShape(Corners.panel, side: outline),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openEvent(context, event),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final card = GumdropColors.of(context);
                final muted = theme.textTheme.bodyMedium?.copyWith(
                  color: card.textMuted,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // The type as a tag chip in its candy (design §3.6).
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.face,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                typeIcon(event.type),
                                size: 14,
                                color: card.ink,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                typeLabel(l10n, event.type),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: card.ink,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (reminder)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppIcons.notifications,
                                size: 16,
                                color: card.textPrimary,
                              ),
                              const SizedBox(width: Space.xs),
                              Text(
                                l10n.eventCardReminder,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: card.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        if (event.isCanceled) const CanceledBadge(),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 19,
                        height: 1.2,
                        color: card.textPrimary,
                        decoration: event.isCanceled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      timeRange(l10n, event, zone, withDay: true),
                      style: muted,
                    ),
                    if (otherZoneLine(l10n, event, zone) case final z?)
                      Text(z, style: muted),
                    if (event.location case final loc?)
                      Text(loc.label, style: muted),
                    _CardRsvps(
                      event: event,
                      groupId: groupId,
                      zone: zone,
                      reminder: reminder,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The card's answer buttons, one set per person I answer for (PLAYER-6),
/// while I can still answer, and the live counts (CHAT-11, SPEC §5.4,
/// §7.5, SCHED-5): the same answers as the event's page, without the
/// notes. Canceled and started events take no answers.
class _CardRsvps extends ConsumerWidget {
  const new({
    required this.event,
    required this.groupId,
    required this.zone,
    this.reminder = false,
  });

  final Event event;
  final GroupId groupId;
  final String zone;

  /// A reminder's card also says how many players haven't answered.
  final bool reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!event.rsvpEnabled) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    if (group == null) return const SizedBox.shrink();
    final me = ref.watch(myMembershipProvider(groupId));
    final now = DateTime.now();
    final open =
        !event.startedBefore(now) && canAnswerNow(event, group, me, now);
    final mine = open
        ? ref.watch(myParticipantsProvider(groupId))
        : const <Participant>[];
    // My answers from today on, one listener for every card in the chat.
    final answers = mine.isEmpty
        ? const <String, Rsvp>{}
        : ref
                  .watch(myRsvpsProvider(groupId, from: startOfDay(zone, now)))
                  .value?[event.id.value] ??
              const <String, Rsvp>{};
    // A basic group's members answer for themselves (TEAM-14): who hasn't
    // answered is out of everyone, not the players.
    final players = group.hasPlayers
        ? ref.watch(playersProvider(groupId)).value?.length ?? 0
        : 0;
    final allowMaybe = group.settings.allowMaybe;
    final unanswered = group.hasPlayers
        ? math.max(0, players - event.rsvpCounts.answered)
        : math.max(
            0,
            group.memberCount - (event.rsvpCounts + event.staffCounts).answered,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // One answer for all my players first (PLAYER-11).
        if (mine.where((p) => p.isPlayer).length > 1)
          Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: SameAnswerButtons(
              event: event,
              players: [
                for (final p in mine)
                  if (p.isPlayer) p,
              ],
              answerOf: (id) => answers[id],
              enabled: true,
              allowMaybe: allowMaybe,
              compact: true,
            ),
          ),
        for (final p in mine)
          Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: RsvpButtons(
              event: event,
              participant: p,
              answer: answers[p.id],
              label: rsvpRowLabel(l10n, p, mine.length),
              enabled: true,
              allowMaybe: allowMaybe,
              compact: true,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: Space.xs),
          child: Text(
            [
              eventCountsText(
                l10n,
                event,
                players: players,
                allowMaybe: allowMaybe,
              ),
              if (reminder && unanswered > 0) l10n.rsvpNotAnswered(unanswered),
            ].join(' · '),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
