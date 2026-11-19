import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/schedule_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'next_up.g.dart';

/// How far ahead Next up looks (#43): an event further off isn't "next" in
/// a way worth a line at the top of the chat.
const nextUpDays = 14;

/// A team's next event, as the top of its chat and its card on Teams show
/// it (#43, SPEC CHAT-21): the event, the people I answer for with their
/// answers, and whether I can answer it now.
class NextUp {
  const new({
    required this.event,
    required this.people,
    required this.answers,
    required this.canAnswer,
    required this.answersKnown,
  });

  final Event event;

  /// The people I answer for (PLAYER-6): none for a coach or a member not
  /// linked to a player yet.
  final List<Participant> people;

  /// Their answers on [event], by participant ID.
  final Map<String, Rsvp> answers;

  /// It takes answers now and I may give them: not canceled, not started,
  /// before the deadline (or I'm an admin), a team that isn't archived, and
  /// I'm on it (a super admin viewing isn't), with someone to answer for.
  final bool canAnswer;

  /// My people and their answers have arrived, so [needsAnswer] can be
  /// trusted and the dot never flashes on and off.
  final bool answersKnown;

  /// The people who haven't answered yet.
  List<Participant> get waiting => [
    for (final p in people)
      if (answers[p.id] == null) p,
  ];

  /// Someone I answer for hasn't, and I can still answer: the coral dot.
  bool get needsAnswer => canAnswer && answersKnown && waiting.isNotEmpty;

  /// The one answer to show when I answer for one person and they have.
  Rsvp? get myAnswer => people.length == 1 ? answers[people.single.id] : null;
}

/// The next few events from the start of today, for the chat's strip: one
/// small listener, five events at most.
@riverpod
Stream<List<Event>> _soonestEvents(Ref ref, GroupId groupId, DateTime from) =>
    ref
        .watch(eventRepositoryProvider)
        .watchUpcoming(groupId, from, limit: 5)
        .map((page) => page.events);

/// [groupId]'s next event that hasn't ended, within [nextUpDays] (#43), with
/// my answers to it: one source for the chat's Next up strip and the line on
/// the team's card on Teams, from the same reads as the Schedule, so they
/// agree. [onTeams] reads Your schedule's own list of the team's next ten,
/// already open under the cards, and only my answers on that one event;
/// the chat reads the next five, and the answers its event cards already
/// listen to. Null with none coming up, and on an archived team, which gets
/// no listener.
@riverpod
AsyncValue<NextUp?> nextUp(Ref ref, GroupId groupId, {bool onTeams = false}) {
  final group = ref.watch(groupProvider(groupId)).value;
  final zone = ref.watch(viewerTimeZoneProvider).value;
  final today = ref.watch(viewerTodayProvider);
  if (group == null || zone == null || today == null) {
    return const AsyncLoading();
  }
  if (group.isArchived) return const AsyncData(null);
  final now = ref.watch(minuteClockProvider);
  final List<Event> list;
  if (onTeams) {
    final shared = ref.watch(
      teamEventsProvider(groupId, past: false, limit: yourScheduleLive),
    );
    // Loading, or a list that failed (Your schedule says so): no line.
    if (shared.events.isEmpty) {
      return shared.loading ? const AsyncLoading() : const AsyncData(null);
    }
    list = shared.events;
  } else {
    final soonest = ref.watch(_soonestEventsProvider(groupId, today));
    if (soonest.value == null) {
      return soonest.hasError ? const AsyncData(null) : const AsyncLoading();
    }
    list = soonest.value!;
  }
  final horizon = now.add(const Duration(days: nextUpDays));
  final event = list
      .where(
        (e) =>
            !e.endedBefore(now) &&
            isUpcoming(e, zone, now) &&
            e.startAt.isBefore(horizon),
      )
      .firstOrNull;
  if (event == null) return const AsyncData(null);
  final me = ref.watch(myMembershipProvider(groupId));
  final open = !event.startedBefore(now) && canAnswerNow(event, group, me, now);
  // Read even when it's locked, so the strip can show the answer given.
  final people = me == null || !event.takesRsvps
      ? const <Participant>[]
      : ref.watch(myParticipantsProvider(groupId));
  final ready = ref.watch(myParticipantsReadyProvider(groupId));
  final mine = people.isEmpty
      ? null
      : (onTeams
                ? ref.watch(
                    myRsvpsProvider(
                      groupId,
                      from: event.startAt,
                      until: event.startAt.add(const Duration(milliseconds: 1)),
                    ),
                  )
                : ref.watch(myRsvpsProvider(groupId, from: today)))
            .value;
  return AsyncData(
    NextUp(
      event: event,
      people: people,
      answers: mine?[event.id.value] ?? const {},
      canAnswer: open && people.isNotEmpty,
      answersKnown: ready && (people.isEmpty || mine != null),
    ),
  );
}
