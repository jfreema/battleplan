import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';

/// Owns `rsvps` (ARCH §5.2). Answers are written straight to
/// `rsvps/{eventId}_{participantId}`; the rules check them and a trigger
/// counts them.
abstract interface class RsvpRepository {
  /// My answers on a team's events starting in [from, until), for me and
  /// my players ([participantIds]), live (ARCH §6.2 "My RSVPs"): all of
  /// them, so callers keep the window to the events they show.
  Stream<List<Rsvp>> watchMine(
    GroupId groupId,
    List<String> participantIds, {
    DateTime? from,
    DateTime? until,
  });

  /// Everyone's answers on an event, live (SCHED-4 attendee lists).
  Stream<List<Rsvp>> watchForEvent(GroupId groupId, EventId eventId);

  /// Writes an answer (SCHED-5). It shows at once, offline too, and goes
  /// out when the connection allows; throws if the rules refuse it.
  Future<void> setRsvp(Event event, RsvpAnswer answer, {required UserId by});

  /// Writes several answers on one event in one batch, so they all save or
  /// none do: "Same answer for all my players" (PLAYER-11).
  Future<void> setRsvps(
    Event event,
    List<RsvpAnswer> answers, {
    required UserId by,
  });
}
