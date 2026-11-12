import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// One event in a schedule list (SCHED-1), as an Open Field card: a 5 px
/// edge in the type's candy, the date column, the title with the type word
/// (left out when the title is the type's own name), the time and place,
/// the attendance ("7/12 going" with a mini bar, and who I answer for that
/// hasn't answered), and an RSVP row for each person I answer for. In Your
/// schedule it names the team beside its color (SCHED-2, PLAYER-9).
/// Canceled events are struck through with a badge (SCHED-7).
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
    this.padding = listPadding,
    super.key,
  });

  /// Around a card in a schedule list: its 16 px gutter, and 12 between
  /// cards.
  static const listPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 6);

  final Event event;

  /// The event's team, for Maybe and the team label.
  final Group? group;
  final String viewerZone;
  final VoidCallback onTap;

  /// The RSVP rows for each person I answer for, to answer without opening
  /// the event; null where I can't answer now (past, closed, or no RSVPs).
  final Widget? answerButtons;

  /// The day on the date column; the event's own day in the viewer's zone
  /// when null.
  final DateTime? day;

  /// Who I answer for on this team, and my answers by participant ID.
  final List<Participant> participants;
  final Map<String, Rsvp> answers;
  final bool showTeam;

  /// The team's active players, for "7/12 going" (PLAYER-6).
  final int playerCount;

  /// Around the card: [listPadding], or no gutter on Teams, whose own
  /// lines the cards up with the team cards (SCHED-2).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canceled = event.isCanceled;
    // A team counts players only; a group, everyone (PLAYER-6).
    final isTeam = group?.hasPlayers ?? true;
    final total = isTeam ? playerCount : group?.memberCount ?? 0;
    // The players I'm here for; my own player needs no name (PLAYER-9).
    final players = [
      for (final p in participants)
        if (p.isPlayer && !p.isMe) p,
    ];
    final date = day ?? dayOf(event, viewerZone);
    final buttons = event.takesRsvps && !canceled ? answerButtons : null;
    final accent = typeAccent(context, event.type);
    final type = typeLabel(l10n, event.type);
    final waiting = [
      for (final p in participants)
        if (answers[p.id] == null) p,
    ];

    return Padding(
      padding: padding,
      child: TapCard(
        onTap: onTap,
        edge: accent.face,
        footer: buttons,
        child: Builder(
          builder: (context) {
            final card = GumdropColors.of(context);
            final style = GumdropStyle.of(context);
            final muted = TextStyle(
              fontFamily: AppFonts.body,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              height: 19 / 15,
              letterSpacing: -0.2,
              color: card.textMuted,
            );
            final place = [
              timeRange(l10n, event, viewerZone),
              if (event.location case final loc?) loc.label,
            ].join(' · ');
            final count = event.takesRsvps
                ? eventCountsText(l10n, event, isTeam: isTeam, total: total)
                : null;
            // Only where the rows show (not past, ended, or canceled).
            final note = buttons != null ? unansweredText(l10n, waiting) : null;
            final typeText = typeAccent(context, event.type).text;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DateColumn(
                  day: date,
                  semanticLabel: '$type, ${dayLabel(l10n, date)}',
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
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                [
                                  group!.name,
                                  if (players.isNotEmpty)
                                    l10n.eventForPlayers(
                                      joinAnd(l10n, [
                                        for (final p in players) p.firstName,
                                      ]),
                                    ),
                                ].join(' · '),
                                maxLines: 1,
                                style: style.label(
                                  TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    height: 16 / 13,
                                    color: card.textMuted,
                                  ),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 22),
                        child: LayoutBuilder(
                          builder: (context, box) => Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    height: 22 / 18,
                                    color: card.textPrimary,
                                    decoration: canceled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (canceled) ...[
                                const SizedBox(width: 10),
                                const CanceledBadge(),
                              ],
                              // The type word, unless the title says it, at
                              // its own width and pushed right, so the title
                              // has the rest of the row before it's cut
                              // short. Never over half the row, so big text
                              // shortens it rather than overflowing.
                              if (!canceled &&
                                  event.title.trim().toLowerCase() !=
                                      type.toLowerCase()) ...[
                                const SizedBox(width: 10),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: box.maxWidth / 2,
                                  ),
                                  child: ExcludeSemantics(
                                    child: Text(
                                      type.toUpperCase(),
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                      style: style.label(
                                        TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          height: 16 / 13,
                                          letterSpacing: 13 * 0.1,
                                          color: typeText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        place,
                        style: muted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // "6:00 PM CDT · 7:00 PM your time" (SCHED-9).
                      if (otherZoneLine(l10n, event, viewerZone) case final z?)
                        Text(z, style: muted),
                      if (count != null) ...[
                        const SizedBox(height: 6),
                        EventAttendance(
                          count: count,
                          // In words for screen readers: "7 of 12 players
                          // going", not "7 slash 12".
                          spoken: isTeam
                              ? l10n.rsvpPlayersGoing(
                                  goingOf(event, isTeam: isTeam),
                                  total,
                                )
                              : l10n.rsvpMembersGoing(
                                  goingOf(event, isTeam: isTeam),
                                  total,
                                ),
                          fraction: total <= 0
                              ? 0
                              : goingOf(event, isTeam: isTeam) / total,
                          note: note,
                        ),
                      ],
                      SizedBox(height: buttons == null ? 8 : 2),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The attendance line on a card (SPEC §7.3): a 40 × 5 mini bar, "7/12
/// going", and, in the accent color, who I answer for that hasn't answered.
/// The schedule's cards and the chat's event cards share it. Screen
/// readers hear the count as [spoken].
class EventAttendance extends StatelessWidget {
  const new({
    required this.count,
    required this.spoken,
    required this.fraction,
    this.note,
    super.key,
  });

  final String count;
  final String spoken;
  final double fraction;
  final String? note;

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
    return Row(
      children: [
        GoingBar(fraction: fraction, width: 40, height: 5),
        const SizedBox(width: 8),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: count),
                if (note != null)
                  TextSpan(
                    text: ' · $note',
                    style: TextStyle(color: c.cherry.text),
                  ),
              ],
            ),
            semanticsLabel: [spoken, ?note].join(', '),
            style: style,
          ),
        ),
      ],
    );
  }
}

/// The label on one of my answers in a schedule row (PLAYER-9): "Emma"
/// for a player I'm here for, "You" for my own player. Null when it's only
/// me in a group.
String? answerLabel(
  AppLocalizations l10n,
  Participant p,
  List<Participant> participants,
) {
  if (!p.isPlayer) return participants.length > 1 ? l10n.eventYou : null;
  return p.isMe ? l10n.eventYou : p.firstName;
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
