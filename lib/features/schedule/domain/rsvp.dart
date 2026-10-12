import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rsvp.freezed.dart';

/// One answer to an event (`rsvps/{eventId}_{participantId}`, SCHED-5).
/// There's exactly one per event and participant: on youth teams both
/// parents write the same player's record, and the latest answer counts
/// (PLAYER-6). No record means "No response".
@freezed
abstract class Rsvp with _$Rsvp {
  const factory({
    required EventId eventId,
    required GroupId groupId,
    required ParticipantType participantType,

    /// A uid for members, a player ID for players.
    required String participantId,
    required String participantName,
    required RsvpStatus status,
    @Default('') String note,

    /// Who gave the answer: "Answered by Maria" (PLAYER-6).
    @Default('') String respondedBy,
    DateTime? eventStartAt,
    DateTime? updatedAt,

    /// True until the server has it (SCHED-5 works offline).
    @Default(false) bool pending,
  }) = _Rsvp;
}

/// Someone an RSVP can be given for: a member, or a player on a youth
/// team (PLAYER-6).
@freezed
abstract class Participant with _$Participant {
  const factory({
    required ParticipantType type,
    required String id,

    /// The member's display name, or the player's.
    required String name,

    /// "Emma #7" for a player (PLAYER-8).
    String? label,
  }) = _Participant;

  const new _();

  bool get isPlayer => type == ParticipantType.player;

  String get shownName => label ?? name;
}

/// An answer about to be written (SCHED-4, SCHED-5).
@freezed
abstract class RsvpAnswer with _$RsvpAnswer {
  const factory({
    required Participant participant,
    required RsvpStatus status,
    @Default('') String note,
  }) = _RsvpAnswer;
}
