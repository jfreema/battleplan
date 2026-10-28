import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// One event in a schedule list (SCHED-1): the date block on the day's
/// first row, the type's color and icon, the title, time, and place, my
/// answer (one per player I answer for), and the counts. In "All my
/// teams" it also names the team and, for guardians, their players
/// (SCHED-2, PLAYER-9). Canceled events are struck through with a badge (SCHED-7).
/// Where I can answer now, Going, Maybe, and Not going sit under the
/// counts across the card ([answerButtons]), and the rest of the card
/// opens the event.
class EventRow extends StatelessWidget {
  const new({
    required this.event,
    required this.group,
    required this.viewerZone,
    required this.onTap,
    this.answerButtons,
    this.day,
    this.participants = const [],
    this.answers = const {},
    this.showTeam = false,
    this.playerCount = 0,
    super.key,
  });

  final Event event;

  /// The event's team, for Maybe and the team label.
  final Group? group;
  final String viewerZone;
  final VoidCallback onTap;

  /// The answer buttons for each person I answer for, to answer without
  /// opening the event; null where I can't answer now (past, closed, or no
  /// RSVPs), and then my answers show as discs.
  final Widget? answerButtons;

  /// The day on the date block; the event's own day in the viewer's zone
  /// when null.
  final DateTime? day;

  /// Who I answer for on this team, and my answers by participant ID.
  final List<Participant> participants;
  final Map<String, Rsvp> answers;
  final bool showTeam;

  /// The team's active players, for "12 of 15 players going" (PLAYER-6).
  final int playerCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canceled = event.isCanceled;
    final allowMaybe = group?.settings.allowMaybe ?? true;
    // The players I'm here for; my own player needs no name (PLAYER-9).
    final players = [
      for (final p in participants)
        if (p.isPlayer && !p.isMe) p,
    ];
    final date = day ?? dayOf(event, viewerZone);
    // Just me, with no name to show: my answer is the disc at the end.
    final soloLabel = participants.length == 1
        ? answerLabel(l10n, participants.single, participants)
        : '';
    final buttons = event.takesRsvps ? answerButtons : null;
    final solo = event.takesRsvps && soloLabel == null && buttons == null;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Space.gutter(MediaQuery.sizeOf(context).width),
        vertical: 5,
      ),
      child: TapCard(
        onTap: onTap,
        footer: buttons,
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final card = GumdropColors.of(context);
            final muted = theme.textTheme.bodyMedium?.copyWith(
              color: card.textMuted,
              fontWeight: FontWeight.w700,
            );
            return Row(
              children: [
                // The type is read out with the day, as it isn't written
                // on the card.
                DateBlock(
                  day: date,
                  accent: typeAccent(context, event.type),
                  semanticLabel:
                      '${typeLabel(l10n, event.type)}, ${dayLabel(l10n, date)}',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showTeam && group != null)
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: group!.color == null
                                    ? AppTokens.brand
                                    : Color(group!.color!),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: Space.xs),
                            Flexible(
                              child: Text(
                                [
                                  group!.name,
                                  if (players.isNotEmpty)
                                    l10n.eventForPlayers(
                                      joinAnd(l10n, [
                                        for (final p in players)
                                          p.name.split(' ').first,
                                      ]),
                                    ),
                                ].join(' · '),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: card.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              event.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 19,
                                height: 1.2,
                                color: card.textPrimary,
                                decoration: canceled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (canceled) ...[
                            const SizedBox(width: Space.sm),
                            const CanceledBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(timeRange(l10n, event, viewerZone), style: muted),
                      // "6:00 PM CDT · 7:00 PM your time" (SCHED-9).
                      if (otherZoneLine(l10n, event, viewerZone) case final z?)
                        Text(z, style: muted),
                      if (event.location case final loc?)
                        Text(
                          loc.label,
                          style: muted,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (event.takesRsvps) ...[
                        if (participants.isNotEmpty && !solo && buttons == null)
                          Padding(
                            padding: const EdgeInsets.only(top: Space.xs),
                            child: Wrap(
                              spacing: Space.md,
                              runSpacing: Space.xs,
                              children: [
                                for (final p in participants)
                                  _MyAnswer(
                                    label: answerLabel(l10n, p, participants),
                                    status: answers[p.id]?.status,
                                  ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: _GoingRow(
                            text: eventCountsText(
                              l10n,
                              event,
                              players: playerCount,
                              allowMaybe: allowMaybe,
                            ),
                            going: playerCount > 0
                                ? event.rsvpCounts.going
                                : (event.rsvpCounts + event.staffCounts).going,
                            of: playerCount > 0
                                ? playerCount
                                : group?.memberCount ?? 0,
                            color: card.mint.text,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (solo) ...[
                  const SizedBox(width: 12),
                  _SoloAnswer(status: answers[participants.single.id]?.status),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The going bar and "7 of 12 going" beside it (design §3.15).
class _GoingRow extends StatelessWidget {
  const new({
    required this.text,
    required this.going,
    required this.of,
    required this.color,
  });

  final String text;
  final int going;
  final int of;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontSize: 13,
        color: going > 0 ? color : GumdropColors.of(context).textMuted,
      ),
    );
    if (of <= 0) return label;
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(child: GoingBar(fraction: going / of)),
          const SizedBox(width: Space.sm),
          ConstrainedBox(
            // The counts take what they need, leaving the bar 40 px.
            constraints: BoxConstraints(
              maxWidth: math.max(0, constraints.maxWidth - 48),
            ),
            child: label,
          ),
        ],
      ),
    );
  }
}

/// My answer as the card's trailing disc (design §3.15), with the answer
/// in words under it for anyone who doesn't see the color.
class _SoloAnswer extends StatelessWidget {
  const new({required this.status});

  final RsvpStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final s = status;
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnswerDisc(status: s),
            const SizedBox(height: 3),
            Text(
              s == null ? l10n.rsvpNoResponse : statusLabel(l10n, s),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: c.textMuted, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}

/// The label on one of my answers in a schedule row (PLAYER-9): "Emma"
/// for a player I'm here for, "You" for me or my own player, and "Jared #12
/// (you)" for my own player beside an answer of my own as a member, so the
/// two never read the same. Null when it's only me as a member.
String? answerLabel(
  AppLocalizations l10n,
  Participant p,
  List<Participant> participants,
) {
  if (!p.isPlayer) return participants.length > 1 ? l10n.eventYou : null;
  if (!p.isMe) return p.name.split(' ').first;
  return participants.any((o) => !o.isPlayer)
      ? l10n.eventYouAsPlayer(p.shownName)
      : l10n.eventYou;
}

/// My answer on a row: "Emma: Going", or "No response", after its disc.
class _MyAnswer extends StatelessWidget {
  const new({required this.label, required this.status});

  final String? label;
  final RsvpStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = GumdropColors.of(context);
    final s = status;
    final text = s == null ? l10n.rsvpNoResponse : statusLabel(l10n, s);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnswerDisc(status: s, size: 18),
        const SizedBox(width: 5),
        // Wraps rather than overflowing with large text (SPEC §7.6).
        Flexible(
          child: Text(
            label == null ? text : '$label: $text',
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 13,
              color: s == null ? c.textMuted : c.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The red "Canceled" badge (SCHED-7): a cherry tag chip with ink text
/// (design §3.6).
class CanceledBadge extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.cherry.face,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        AppLocalizations.of(context).eventCanceled,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: c.ink, letterSpacing: 0.4),
      ),
    );
  }
}
