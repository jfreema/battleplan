import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/team_dot.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// One event in a schedule list (SCHED-1), as a Boot Camp Mix panel (#85,
/// SPEC §7.4): the date pennant in the event's color down its left side,
/// the title in stencil, the time, the place and "7/12 going", my answer
/// stamped at the top right, and under a rule an answer row for each
/// person I answer for ("NOAH?" and push buttons); for someone not linked
/// to a player yet, a line that says how to get them (PLAYER-3). In Your
/// schedule it names the team beside its color (SCHED-2, PLAYER-9).
/// Canceled events are struck through with a badge (SCHED-7).
class EventRow extends StatelessWidget {
  const new({
    required this.event,
    required this.group,
    required this.viewerZone,
    required this.onTap,
    this.answerButtons,
    this.hint,
    this.day,
    this.participants = const [],
    this.answers = const {},
    this.showTeam = false,
    this.playerCount = 0,
    this.padding = listPadding,
    this.twinkle = false,
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

  /// In place of [answerButtons] where I have none because I'm not linked
  /// to a player yet (PLAYER-3): "Pick your player to answer", or who I'm
  /// waiting on. Under the card's text, outside what a tap opens.
  final Widget? hint;

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

  /// Whether a Going! stamp on it has a twinkle (#98): the list's first
  /// card's.
  final bool twinkle;

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
    final footer = buttons ?? (event.takesRsvps && !canceled ? hint : null);
    final accent = typeAccent(context, event.type);
    final type = typeLabel(l10n, event.type);

    // My answer, stamped, where everyone I answer for gave the same one.
    final given = {for (final p in participants) answers[p.id]?.status};
    final stamp = participants.isNotEmpty && given.length == 1
        ? given.single
        : null;

    return Padding(
      padding: padding,
      child: TapCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        footer: footer,
        footerBand: buttons == null
            ? null
            : GumdropColors.of(context).roles.palette.answerRow,
        child: Builder(
          builder: (context) {
            final card = GumdropColors.of(context);
            final style = GumdropStyle.of(context);
            final muted = TextStyle(
              fontFamily: AppFonts.body,
              fontWeight: AppFonts.reading,
              fontSize: 13.5,
              height: 17 / 13.5,
              color: card.textMuted,
            );
            final count = event.takesRsvps
                ? eventCountsText(l10n, event, isTeam: isTeam, total: total)
                : null;
            final where = [
              if (event.location case final loc?) loc.label,
              ?count,
            ].join(' · ');
            return IntrinsicHeight(
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DatePennant(
                        day: date,
                        color: accent.face,
                        semanticLabel: '$type, ${dayLabel(l10n, date)}',
                      ),
                      const SizedBox(
                        width: DatePennant.textStart - DatePennant.width,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            top: 5,
                            bottom: footer == null ? 8 : 6,
                            // Clear of the stamp.
                            end: stamp == null ? 10 : 96,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (showTeam && group != null)
                                Row(
                                  children: [
                                    // The team's true color, ringed where
                                    // it would vanish into the card (#36).
                                    TeamDot(
                                      color: group!.color == null
                                          ? AppTokens.brand
                                          : Color(group!.color!),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        [
                                          group!.name,
                                          if (players.isNotEmpty)
                                            l10n.eventForPlayers(
                                              joinAnd(l10n, [
                                                for (final p in players)
                                                  p.firstName,
                                              ]),
                                            ),
                                        ].join(' · '),
                                        maxLines: 1,
                                        style: style.label(
                                          TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12.5,
                                            height: 16 / 12.5,
                                            color: card.textMuted,
                                          ),
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppFonts.stencil,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                        height: 24 / 20,
                                        letterSpacing: 20 * 0.045,
                                        color: card.textPrimary,
                                        decoration: canceled
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (canceled) ...[
                                    const SizedBox(width: 8),
                                    const CanceledBadge(),
                                  ],
                                ],
                              ),
                              Text(
                                timeRange(l10n, event, viewerZone),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: muted.copyWith(
                                  fontSize: 15,
                                  height: 18 / 15,
                                  color: card.textPrimary,
                                ),
                              ),
                              // "6:00 PM CDT · 7:00 PM your time" (SCHED-9).
                              if (otherZoneLine(l10n, event, viewerZone)
                                  case final z?)
                                Text(z, style: muted),
                              if (where.isNotEmpty)
                                Text(
                                  where,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: muted,
                                  // "7 of 12 players going", not "7 slash
                                  // 12".
                                  semanticsLabel: count == null
                                      ? null
                                      : [
                                          if (event.location case final loc?)
                                            loc.label,
                                          if (isTeam)
                                            l10n.rsvpPlayersGoing(
                                              goingOf(event, isTeam: isTeam),
                                              total,
                                            )
                                          else
                                            l10n.rsvpMembersGoing(
                                              goingOf(event, isTeam: isTeam),
                                              total,
                                            ),
                                        ].join(' · '),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (stamp != null && !canceled)
                    PositionedDirectional(
                      end: 9,
                      top: 8,
                      child: ExcludeSemantics(
                        child: AnswerStamp(status: stamp, twinkle: twinkle),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
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

/// The red "Canceled" badge (SCHED-7): a tag chip in the warning red,
/// with its white text (design §3.6).
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
            ?.copyWith(color: c.inkOn(c.cherry), letterSpacing: 0.4),
      ),
    );
  }
}
