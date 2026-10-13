import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';

/// How far back a player's RSVP history can look, in months (PLAYER-11).
/// The first is the default.
const rsvpHistoryMonths = [3, 6, 12];

/// One past event in a player's RSVP history (PLAYER-11), with the
/// player's answer, or null for no answer.
typedef RsvpHistoryEntry = ({Event event, Rsvp? answer});

/// A player's answers on a team's past events (PLAYER-11), newest first.
/// Canceled events are listed but not counted.
class RsvpHistory {
  const new(this.entries);

  final List<RsvpHistoryEntry> entries;

  /// The events that count: past, taking answers, not canceled.
  int get eventCount => entries.where((e) => !e.event.isCanceled).length;

  /// How many counted events had [status], or no answer for null.
  int count(RsvpStatus? status) => entries
      .where((e) => !e.event.isCanceled && e.answer?.status == status)
      .length;
}

/// [events] that a player could have answered by [now], newest first, each
/// with its answer from [answers] (by event ID): those that took RSVPs and
/// started before [now], and, when the player joined the roster at
/// [since], not before then, so a player added mid-season isn't shown
/// missing earlier events.
RsvpHistory rsvpHistoryOf({
  required List<Event> events,
  required Map<String, Rsvp> answers,
  required DateTime now,
  DateTime? since,
}) {
  final past = [
    for (final e in events)
      if (e.rsvpEnabled &&
          e.startedBefore(now) &&
          (since == null || !e.startAt.isBefore(since)))
        e,
  ]..sort((a, b) => b.startAt.compareTo(a.startAt));
  return RsvpHistory([
    for (final e in past) (event: e, answer: answers[e.id.value]),
  ]);
}
