import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/haptics.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/schedule/application/next_up.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/presentation/event_details_screen.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/features/schedule/presentation/schedule_screen.dart';
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// What the next event is, in a few words (#43): its title, with its type
/// in front of a "vs." title ("Game vs. Hornets"); the type alone when the
/// title is the type's name ("Practice").
String nextUpWhat(AppLocalizations l10n, Event e) {
  final type = typeLabel(l10n, e.type);
  final title = e.title.trim();
  if (title.isEmpty || title.toLowerCase() == type.toLowerCase()) return type;
  if (title.toLowerCase().startsWith('vs')) return '$type $title';
  return title;
}

/// When it starts, in the viewer's zone (#43): "Today 4:00 PM", "Tomorrow
/// 4:00 PM", "Sat 4:00 PM" this week, "Sat, Nov 28 4:00 PM" after; an
/// all-day event says "All day" for its time. [spoken] spells the day out
/// for screen readers ("Saturday 4:00 PM").
String nextUpWhen(
  AppLocalizations l10n,
  Event e,
  String zone,
  DateTime now, {
  bool spoken = false,
}) {
  final day = dayOf(e, zone);
  final wall = ZonedTime.wallClock(zone, now);
  final today = DateTime.utc(wall.year, wall.month, wall.day);
  final ahead = day.difference(today).inDays;
  final locale = l10n.localeName;
  final String dayWord;
  if (ahead <= 0) {
    dayWord = l10n.today;
  } else if (ahead == 1) {
    dayWord = l10n.nextUpTomorrow;
  } else if (ahead < 7) {
    dayWord = (spoken ? DateFormat.EEEE(locale) : DateFormat.E(locale)).format(
      day,
    );
  } else {
    dayWord = (spoken ? DateFormat.MMMMEEEEd(locale) : DateFormat.MMMEd(locale))
        .format(day);
  }
  final time = e.allDay ? l10n.eventAllDay : timeIn(l10n, e.startAt, zone);
  return '$dayWord $time';
}

/// The Next up strip at the top of a team's chat (#43, SPEC CHAT-21): one
/// slim row under the header, above the pinned row, naming the team's next
/// event in the next two weeks (what, when, where). While it needs my
/// answer and I answer for one person, Going and Not going right on it (a
/// tap saves, as the schedule's buttons do); for several people, a coral
/// dot and "Answer for Noah and Leo", which opens the event. Answered, the
/// answer as a flat tag. A tap anywhere else opens the event. It's never a
/// message: nothing is posted, and it's gone while the keyboard is up.
class NextUpStrip extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<NextUpStrip> createState() => _NextUpStripState();
}

class _NextUpStripState extends ConsumerState<NextUpStrip>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The keyboard coming up or going changes the view's insets.
  @override
  void didChangeMetrics() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId;
    // Out of the way while typing. The view's own insets: the chat's
    // Scaffold takes the keyboard out of its body's MediaQuery.
    if (View.of(context).viewInsets.bottom > 0) {
      return const SizedBox.shrink();
    }
    final next = ref.watch(nextUpProvider(groupId)).value;
    final zone = ref.watch(viewerTimeZoneProvider).value;
    if (next == null || zone == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final event = next.event;
    final now = ref.watch(minuteClockProvider);
    final what = nextUpWhat(l10n, event);
    final when = nextUpWhen(l10n, event, zone, now);
    final place = event.location?.label;
    void open() => openEvent(context, event, from: l10n.tabChat);

    // What goes at the end: the answer buttons, the answer, "Answer for…",
    // or Canceled.
    final single = next.people.length == 1;
    final pills = single && next.needsAnswer;
    final several = !single && next.needsAnswer;
    final answer = next.myAnswer?.status;
    final Widget? end;
    if (event.isCanceled) {
      end = _QuietTag(label: l10n.eventCanceled);
    } else if (pills) {
      end = RsvpChoice(
        statuses: const [RsvpStatus.going, RsvpStatus.notGoing],
        current: null,
        compact: true,
        onChanged: (s) {
          Haptics.selection();
          unawaited(
            setRsvpWithFeedback(
              context,
              ref,
              event,
              RsvpAnswer(participant: next.people.single, status: s),
            ),
          );
        },
      );
    } else if (answer != null) {
      end = _AnswerTag(status: answer);
    } else {
      end = null;
    }

    // What a screen reader hears, before the buttons.
    final state = several || pills
        ? l10n.nextUpNeedsAnswer
        : answer != null
        ? l10n.nextUpYourAnswer(statusLabel(l10n, answer))
        : event.isCanceled
        ? l10n.eventCanceled
        : null;
    final spoken = [
      l10n.nextUpSpoken(what, nextUpWhen(l10n, event, zone, now, spoken: true)),
      ?place,
    ].join(', ');
    final label = state == null ? '$spoken.' : '$spoken. $state.';

    final muted = c.textMutedOnPage;
    final line = Text.rich(
      TextSpan(
        children: [
          // A small label in the plain face's capitals (Team Shirt, #104).
          TextSpan(
            text: '${l10n.nextUpLabel.toUpperCase()}  ',
            style: GumdropStyle.caps(TextStyle(fontSize: 11, color: muted)),
          ),
          TextSpan(
            text: what,
            style: TextStyle(
              fontWeight: AppFonts.bold,
              color: c.textOnPage,
              decoration: event.isCanceled ? TextDecoration.lineThrough : null,
            ),
          ),
          TextSpan(text: ' · $when'),
          if (place != null) TextSpan(text: ' · $place'),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: AppFonts.body,
        fontWeight: AppFonts.reading,
        fontSize: 15,
        height: 20 / 15,
        color: c.textOnPage,
      ),
    );
    final tappable = Semantics(
      button: true,
      label: label,
      onTap: open,
      excludeSemantics: true,
      child: InkWell(
        onTap: open,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(AppIcons.schedule, size: 20, color: muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      line,
                      if (several)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: _AnswerFor(next: next),
                        ),
                    ],
                  ),
                ),
                if (!pills && end == null || several)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      AppIcons.chevronRight,
                      size: 20,
                      weight: 700,
                      color: muted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final Widget body;
    if (end == null) {
      body = tappable;
    } else {
      // The buttons at the end of the line on a wide screen; under it on a
      // phone or with large text, where they'd squeeze it.
      body = LayoutBuilder(
        builder: (context, box) {
          final beside = box.maxWidth >= (pills ? 600 : 360) && scale <= 1.3;
          if (beside) {
            return Row(
              children: [
                Expanded(child: tappable),
                const SizedBox(width: Space.sm),
                if (pills) SizedBox(width: 220, child: end) else end!,
              ],
            );
          }
          // Under the line the buttons get room for large text.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tappable,
              Padding(
                padding: EdgeInsets.only(left: pills ? 0 : 30, bottom: 6),
                child: pills
                    ? SizedBox(width: box.maxWidth.clamp(0, 340), child: end)
                    : end,
              ),
            ],
          );
        },
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: body,
      ),
    );
  }
}

/// "Answer for Noah and Leo" with the coral dot (§7.2: coral is "do
/// this"), when I answer for more than one person; "for 3 people" past two.
class _AnswerFor extends StatelessWidget {
  const new({required this.next});

  final NextUp next;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final waiting = next.waiting;
    final text = waiting.length <= 2
        ? l10n.nextUpAnswerFor(
            joinAnd(l10n, [for (final p in waiting) _firstName(l10n, p)]),
          )
        : l10n.nextUpAnswerForCount(waiting.length);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dot(context, 14, 18 / 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontWeight: AppFonts.bold,
              fontSize: 14,
              height: 18 / 14,
              color: c.textOnPage,
            ),
          ),
        ),
      ],
    );
  }
}

/// The coral dot, centered on the first line of text [fontSize] and
/// [height] beside it, so it stays by the first line when the text wraps.
Widget _dot(BuildContext context, double fontSize, double height) {
  final line = MediaQuery.textScalerOf(context).scale(fontSize) * height;
  return Padding(
    padding: EdgeInsets.only(top: ((line - 8) / 2).clamp(0, 40)),
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: GumdropColors.of(context).you.face,
        shape: BoxShape.circle,
      ),
    ),
  );
}

/// A person's first name, or "you" for myself.
String _firstName(AppLocalizations l10n, Participant p) =>
    p.isPlayer && !p.isMe ? p.firstName : l10n.eventYou.toLowerCase();

/// An answer given, as one flat tag in its color with its icon (#53).
class _AnswerTag extends StatelessWidget {
  const new({required this.status});

  final RsvpStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final accent = statusAccent(context, status);
    final ink = c.inkOn(accent);
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: accent.face,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: 16, weight: 700, color: ink),
          const SizedBox(width: 6),
          Text(
            statusLabel(l10n, status),
            // The plain face's Black, as a small answer button (#104).
            style: GumdropStyle.of(context)
                .label(TextStyle(fontSize: 13.5, height: 1.2, color: ink)),
          ),
        ],
      ),
    );
  }
}

/// A quiet outlined tag: Canceled on the strip.
class _QuietTag extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: c.outline, width: 1.5)),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: GumdropStyle.of(context).label(
            TextStyle(fontSize: 13.5, height: 1.2, color: c.textMutedOnPage),
          ),
        ),
      ),
    );
  }
}

/// The Next line on a team's card on Teams (#43): "Next: Practice · Sat
/// 4:00 PM", muted, with a coral dot in front and "· Needs your answer"
/// while something waits on me. Nothing with no event in two weeks. No
/// buttons: the card stays one target, and answering is in Your schedule
/// under the cards or the team's Next up strip.
class TeamCardNextLine extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The same list Your schedule under the cards listens to: no listener
    // of its own.
    final next = ref.watch(nextUpProvider(groupId, onTeams: true)).value;
    final zone = ref.watch(viewerTimeZoneProvider).value;
    if (next == null || zone == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final now = ref.watch(minuteClockProvider);
    final event = next.event;
    final what = nextUpWhat(l10n, event);
    final needs = next.needsAnswer;
    final tail = [
      if (event.isCanceled) l10n.eventCanceled,
      if (needs) l10n.nextUpNeedsAnswer,
    ];
    final spoken = [
      l10n.teamCardNextSpoken(
        what,
        nextUpWhen(l10n, event, zone, now, spoken: true),
      ),
      for (final t in tail) t.toLowerCase(),
    ].join(', ');
    final muted = TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: AppFonts.reading,
      fontSize: 15,
      height: 19 / 15,
      letterSpacing: -0.2,
      color: c.textMuted,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (needs) ...[_dot(context, 15, 19 / 15), const SizedBox(width: 6)],
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l10n.teamCardNext(
                      what,
                      nextUpWhen(l10n, event, zone, now),
                    ),
                  ),
                  if (event.isCanceled)
                    TextSpan(text: ' · ${l10n.eventCanceled}'),
                  if (needs)
                    TextSpan(
                      text: ' · ${l10n.nextUpNeedsAnswer}',
                      style: TextStyle(
                        fontWeight: AppFonts.bold,
                        color: c.textPrimary,
                      ),
                    ),
                ],
              ),
              semanticsLabel: spoken,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
          ),
        ],
      ),
    );
  }
}
