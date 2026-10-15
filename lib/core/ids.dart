import 'package:battleplan/core/constants.g.dart';

/// ID value types (ARCH §5.3). Wrapping strings keeps a group ID from being
/// passed where a user ID belongs.
extension type const UserId(String value);

extension type const GroupId(String value);

extension type const PlayerId(String value);

extension type const MessageId(String value);

extension type const EventId(String value);

extension type const PollId(String value);

extension type const DocumentId(String value);

/// A play drawn on a team's whiteboard (`plays`, SPEC BOARD-4).
extension type const PlayId(String value);

/// Builds the composite document IDs from ARCH §6.2. This is the only place
/// they're built; Functions use the same separator from shared/constants.json.
abstract final class CompositeIds {
  static String groupMember(GroupId groupId, UserId uid) =>
      _join(groupId.value, uid.value);

  static String playerGuardian(PlayerId playerId, UserId uid) =>
      _join(playerId.value, uid.value);

  static String guardianRequest(PlayerId playerId, UserId uid) =>
      _join(playerId.value, uid.value);

  static String pollVote(PollId pollId, UserId uid) =>
      _join(pollId.value, uid.value);

  /// [participantId] is a uid for a member answering for themselves and a
  /// player ID for a player (PLAYER-6).
  static String rsvp(EventId eventId, String participantId) =>
      _join(eventId.value, participantId);

  static String userBlock(UserId uid, UserId blockedUid) =>
      _join(uid.value, blockedUid.value);

  static String _join(String a, String b) {
    assert(
      !a.contains(idSeparator) && !b.contains(idSeparator),
      'IDs in a composite key must not contain "$idSeparator"',
    );
    return '$a$idSeparator$b';
  }
}
