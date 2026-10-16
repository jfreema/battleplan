import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';

/// Someone on a team's roster (PLAYER-1). Every team has players. A member
/// can be a player themselves (a `self` link), and players others answer
/// for, such as kids, never have accounts. The record holds only a name
/// and number (PLAYER-10); older records may still carry a position, which
/// the app no longer shows.
@freezed
abstract class Player with _$Player {
  const factory({
    required PlayerId id,
    required GroupId groupId,
    required String displayName,
    String? jerseyNumber,

    /// The song played as they come up (PLAYER-2), "Thunderstruck, AC/DC":
    /// the whole team sees it, up to [Limits.walkUpSongMax] characters.
    String? walkUpSong,

    /// Pending until a team admin approves a member's new player
    /// (PLAYER-4). Players without a status are active.
    @Default(PlayerStatus.active) PlayerStatus status,

    /// Who added it, and how they said they're linked (PLAYER-4).
    String? proposedBy,
    PlayerRelation? proposedRelation,

    /// When it was added to the roster, so its RSVP history starts there
    /// (PLAYER-11). Null on records read without it.
    DateTime? addedAt,
  }) = _Player;

  const new _();

  bool get isPending => status == PlayerStatus.pending;

  /// "Emma #7", or "Emma" without a number (PLAYER-8).
  String get label {
    final first = displayName.trim().split(RegExp(r'\s+')).first;
    return jerseyNumber == null || jerseyNumber!.isEmpty
        ? first
        : '$first #$jerseyNumber';
  }
}

/// A member linked to a player (`playerGuardians`, "player links"): as the
/// player (`self`) or as a parent or guardian. Old links without a
/// relation are guardians.
@freezed
abstract class GuardianLink with _$GuardianLink {
  const factory({
    required PlayerId playerId,
    required GroupId groupId,
    required UserId uid,
    @Default(PlayerRelation.guardian) PlayerRelation relation,
  }) = _GuardianLink;

  const new _();

  /// The member is this player ("I am this player").
  bool get isSelf => relation == PlayerRelation.self;
}

/// [uid]'s links on a team, as the player or a guardian.
List<GuardianLink> linksOf(UserId uid, Iterable<GuardianLink> links) => [
  for (final l in links)
    if (l.uid == uid) l,
];

/// The member who is [playerId], if anyone claimed it (PLAYER-3: at most
/// one per player).
GuardianLink? selfLinkOf(PlayerId playerId, Iterable<GuardianLink> links) =>
    links.where((l) => l.playerId == playerId && l.isSelf).firstOrNull;

/// Whether [uid] may still say "I am this player" on a team (PLAYER-3).
/// A member is one player at most, so not when they're linked as a player
/// already, have a claim as the player waiting, or added themselves as a
/// player who is still waiting for approval: approving both would leave
/// one of the two players without them.
bool canStillBeAPlayer(
  UserId uid, {
  Iterable<GuardianLink> links = const [],
  Iterable<GuardianRequest> requests = const [],
  Iterable<Player> pendingPlayers = const [],
}) =>
    !links.any((l) => l.uid == uid && l.isSelf) &&
    !requests.any(
      (r) =>
          r.uid == uid &&
          r.relation == PlayerRelation.self &&
          r.status == GuardianRequestStatus.pending,
    ) &&
    !pendingPlayers.any(
      (p) =>
          p.isPending &&
          p.proposedBy == uid.value &&
          p.proposedRelation == PlayerRelation.self,
    );

/// How many guardians [playerId] has; the player's own link doesn't count
/// toward the 4 (PLAYER-3).
int guardianCountOf(PlayerId playerId, Iterable<GuardianLink> links) =>
    links.where((l) => l.playerId == playerId && !l.isSelf).length;

/// One player to add (PLAYER-1): a name, and optionally a number and a
/// date of birth. Who's linked to the player comes later, from claims
/// (PLAYER-3).
@freezed
abstract class NewPlayer with _$NewPlayer {
  const factory({
    required String name,
    String? jerseyNumber,

    /// 'YYYY-MM-DD' (optional): saved in the player's details, never on
    /// the roster (PLAYER-10, PLAYER-12).
    String? dateOfBirth,
  }) = _NewPlayer;
}

/// Where a claim stands (PLAYER-4).
enum GuardianRequestStatus { pending, approved, declined }

/// A member claiming a player (`guardianRequests`, "player claims",
/// PLAYER-3): as the player or as a parent or guardian.
@freezed
abstract class GuardianRequest with _$GuardianRequest {
  const factory({
    required PlayerId playerId,
    required GroupId groupId,
    required UserId uid,
    required GuardianRequestStatus status,
    @Default(PlayerRelation.guardian) PlayerRelation relation,
  }) = _GuardianRequest;
}

/// What a claim did (PLAYER-3): linked at once (an admin's), or sent to
/// the admins.
enum ClaimOutcome { linked, requested }
