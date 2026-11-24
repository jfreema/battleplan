import 'dart:math' as math;

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/camo.dart';
import 'package:battleplan/core/widgets/camp_lettering.dart';
import 'package:battleplan/core/widgets/candy_sprinkles.dart';
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
import 'package:intl/intl.dart';
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
    final day = ZonedTime.wallClock(zone, event.startAt);
    final where = event.location?.label;
    // Boot Camp Mix's event panel (#85, SPEC §5.4): a header in the event's
    // color under a halftone, with the date on a starburst and the kind on
    // a mustard tag over the title in outlined stencil; then the time and
    // place, and the answers.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: TapCard(
        padding: EdgeInsets.zero,
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
              fontWeight: AppFonts.reading,
              fontSize: 14.5,
              height: 20 / 14.5,
              color: card.textMuted,
            );
            final strong = muted.copyWith(
              fontSize: 15.5,
              height: 20 / 15.5,
              color: card.textPrimary,
            );
            final stencil = TextStyle(
              fontFamily: AppFonts.stencil,
              fontWeight: FontWeight.w900,
              color: card.ink,
            );
            final header = DecoratedBox(
              decoration: BoxDecoration(
                color: accent.face,
                border: Border(bottom: BorderSide(color: card.ink, width: 3)),
              ),
              child: CustomPaint(
                // Sugar Rush's candy stripes under the halftone (#98).
                painter: card.roles.palette.touches.stripes
                    ? const CandyStripesPainter()
                    : null,
                child: CustomPaint(
                  painter: DotGridPainter(
                    color: const Color(0x2B17131C),
                    radius: 1.5,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(9, 5, 10, 4),
                    child: Row(
                      children: [
                        // The date's burst, with two twinkles, inside the
                        // card's edge (#98).
                        Twinkled(
                          spots: const [
                            TwinkleSpot(size: 20, right: -10, top: -4),
                            TwinkleSpot(
                              size: 14,
                              right: -16,
                              top: 17,
                              second: true,
                            ),
                          ],
                          child: Starburst(
                            points: 12,
                            inner: 0.8,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${DateFormat.E(l10n.localeName).format(day)} · '
                                  '${DateFormat.MMM(l10n.localeName).format(day)}',
                                  maxLines: 1,
                                  textScaler: TextScaler.noScaling,
                                  style: stencil.copyWith(
                                    fontSize: 10.5,
                                    height: 12 / 10.5,
                                    letterSpacing: 10.5 * 0.07,
                                  ),
                                ),
                                Text(
                                  '${day.day}',
                                  maxLines: 1,
                                  textScaler: TextScaler.noScaling,
                                  style: stencil.copyWith(
                                    fontSize: 24.5,
                                    height: 1,
                                    letterSpacing: 24.5 * 0.02,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CampTag(eventKindLabel(l10n, event)),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: OutlinedText(
                                  event.title,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppFonts.stencil,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 31.5,
                                    height: 37 / 31.5,
                                    letterSpacing: 31.5 * 0.04,
                                    decoration: event.isCanceled
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: card.ink,
                                    decorationThickness: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 6, 11, 11),
                  child: Column(
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(color: card.textPrimary),
                                    ),
                                  ],
                                ),
                              if (event.isCanceled) const CanceledBadge(),
                            ],
                          ),
                        ),
                      // The time, and the place beside it in muted type.
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: timeRange(l10n, event, zone),
                              style: strong,
                            ),
                            if (where != null) TextSpan(text: '  · $where'),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                      if (otherZoneLine(l10n, event, zone) case final z?)
                        Text(z, style: muted),
                      _CardRsvps(
                        event: event,
                        groupId: groupId,
                        zone: zone,
                        reminder: reminder,
                      ),
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

/// The card's question and answer buttons (CHAT-11, SPEC §5.4.6, §7.5,
/// SCHED-5; Boot Camp Mix, #85): "IS NOAH GOING?" with "2/4 going" beside
/// it, then one set of push buttons per person I answer for (PLAYER-6)
/// while I can still answer: the same answers as the event's page, without
/// the notes. Canceled and started events take no answers.
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
    final unanswered = group.hasPlayers
        ? math.max(0, players - event.rsvpCounts.answered)
        : math.max(
            0,
            group.memberCount - (event.rsvpCounts + event.staffCounts).answered,
          );
    final muted = TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: AppFonts.reading,
      fontSize: 14,
      height: 18 / 14,
      color: GumdropColors.of(context).textMuted,
    );
    // Boot Camp Mix (#85): the question in stencil ("IS NOAH GOING?") with
    // the count beside it, then push buttons across the panel, a row for
    // each player I answer for (PLAYER-11).
    final card = GumdropColors.of(context);
    final ask = mine.isEmpty ? null : rsvpHeading(l10n, mine);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ask != null || count != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            // The count wraps under the question where both don't fit.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: Space.sm,
              children: [
                if (ask != null)
                  Text(
                    ask,
                    style: TextStyle(
                      fontFamily: AppFonts.stencil,
                      fontWeight: FontWeight.w900,
                      fontSize: 16.5,
                      height: 22 / 16.5,
                      letterSpacing: 16.5 * 0.045,
                      color: card.textPrimary,
                    ),
                  ),
                if (count != null)
                  Semantics(
                    label: group.hasPlayers
                        ? l10n.rsvpPlayersGoing(
                            goingOf(event, isTeam: true),
                            total,
                          )
                        : l10n.rsvpMembersGoing(
                            goingOf(event, isTeam: false),
                            total,
                          ),
                    excludeSemantics: true,
                    child: Text(count, style: muted.copyWith(fontSize: 13.5)),
                  ),
              ],
            ),
          ),
        // A reminder also says how many on the team haven't answered
        // (SCHED-8).
        if (reminder && unanswered > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(l10n.rsvpNotAnswered(unanswered), style: muted),
          ),
        for (final p in mine)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RsvpButtons(
              event: event,
              participant: p,
              answer: answers[p.id],
              // The question names one person; several each get a name.
              label: mine.length > 1 ? cardRsvpLabel(l10n, p) : null,
              enabled: true,
              allowMaybe: allowMaybe,
              compact: true,
            ),
          ),
      ],
    );
  }
}
