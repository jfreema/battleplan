import 'dart:math' as math;

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
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
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
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
    final frame = style.cardDecoration(c.surface, 18, side: outline);
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
    final type = typeLabel(l10n, event.type);
    // The schedule's card (SPEC §7.3): the type's edge, the title and its
    // type word, the time and place, then the answers and counts.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: TapCard(
        edge: accent.face,
        padding: const EdgeInsets.fromLTRB(15, 10, 12, 10),
        onTap: () => openEvent(
          context,
          event,
          from: AppLocalizations.of(context).tabChat,
        ),
        child: Builder(
          builder: (context) {
            final card = GumdropColors.of(context);
            final muted = TextStyle(
              fontFamily: AppFonts.body,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              height: 19 / 15,
              letterSpacing: -0.2,
              color: card.textMuted,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reminder || event.isCanceled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Wrap(
                      spacing: Space.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
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
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: card.textPrimary),
                              ),
                            ],
                          ),
                        if (event.isCanceled) const CanceledBadge(),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          height: 22 / 18,
                          color: card.textPrimary,
                          decoration: event.isCanceled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (event.title.trim().toLowerCase() != type.toLowerCase())
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          type.toUpperCase(),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: GumdropStyle.of(context).label(
                            TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              height: 16 / 13,
                              letterSpacing: 13 * 0.1,
                              color: typeAccent(context, event.type).text,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(timeRange(l10n, event, zone, withDay: true), style: muted),
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
    );
  }
}

/// The card's attendance line and answer buttons, as the schedule's card
/// has them (CHAT-11, SPEC §5.4.6, §7.5, SCHED-5): the mini bar, "2/4
/// going" and who I answer for that hasn't answered, then one set of
/// buttons per person I answer for (PLAYER-6) while I can still answer:
/// the same answers as the event's page, without the notes. Canceled and
/// started events take no answers.
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
    final mineAnswered = mine.isEmpty
        ? null
        : ref
              .watch(myRsvpsProvider(groupId, from: startOfDay(zone, now)))
              .value;
    final answers = mineAnswered?[event.id.value] ?? const <String, Rsvp>{};
    // A basic group's members answer for themselves (TEAM-14): who hasn't
    // answered is out of everyone, not the players.
    final players = group.hasPlayers
        ? ref.watch(playersProvider(groupId)).value?.length ?? 0
        : 0;
    final allowMaybe = group.settings.allowMaybe;
    final total = group.hasPlayers ? players : group.memberCount;
    final count = eventCountsText(
      l10n,
      event,
      isTeam: group.hasPlayers,
      total: total,
    );
    // Only while the buttons show, and once my answers have loaded.
    final note = mineAnswered == null
        ? null
        : unansweredText(l10n, [
            for (final p in mine)
              if (answers[p.id] == null) p,
          ]);
    final unanswered = group.hasPlayers
        ? math.max(0, players - event.rsvpCounts.answered)
        : math.max(
            0,
            group.memberCount - (event.rsvpCounts + event.staffCounts).answered,
          );
    final muted = TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w700,
      fontSize: 14,
      height: 18 / 14,
      color: GumdropColors.of(context).textMuted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (count != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: EventAttendance(
              count: count,
              spoken: group.hasPlayers
                  ? l10n.rsvpPlayersGoing(goingOf(event, isTeam: true), total)
                  : l10n.rsvpMembersGoing(goingOf(event, isTeam: false), total),
              fraction: total <= 0
                  ? 0
                  : goingOf(event, isTeam: group.hasPlayers) / total,
              note: note,
            ),
          ),
        // A reminder also says how many on the team haven't answered
        // (SCHED-8).
        if (reminder && unanswered > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(l10n.rsvpNotAnswered(unanswered), style: muted),
          ),
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
              label: cardRsvpLabel(l10n, p),
              enabled: true,
              allowMaybe: allowMaybe,
              compact: true,
            ),
          ),
      ],
    );
  }
}
