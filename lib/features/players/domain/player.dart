import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';

/// Someone on a team's roster (PLAYER-1). Every team has players. A member
/// can be a player themselves (a `self` link), and players others answer
/// for, such as kids, never have accounts. The record holds only a name,
/// number, and position (PLAYER-10).
@freezed
abstract class Player with _$Player {
  const factory({
    required PlayerId id,
    required GroupId groupId,
    required String displayName,
    String? jerseyNumber,
    String? position,

    /// Pending until a team admin approves a member's new player
    /// (PLAYER-4). Players without a status are active.
    @Default(PlayerStatus.active) PlayerStatus status,

    /// Who added it, and how they said they're linked (PLAYER-4).
    String? proposedBy,
    PlayerRelation? proposedRelation,
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

/// One guardian when adding players.
@freezed
abstract class NewGuardian with _$NewGuardian {
  const factory({String? name, String? email}) = _NewGuardian;
}

/// One player to add (PLAYER-1). [email] is the player's own, for an
/// adult player: that account is linked as the player, not a guardian.
@freezed
abstract class NewPlayer with _$NewPlayer {
  const factory({
    required String name,
    String? jerseyNumber,
    String? position,
    String? email,
    @Default(<NewGuardian>[]) List<NewGuardian> guardians,
  }) = _NewPlayer;
}

/// What happened when adding players (PLAYER-1 results screen).
@freezed
abstract class AddPlayersResult with _$AddPlayersResult {
  const factory({
    required int playersAdded,
    required int guardiansLinked,
    required int guardiansInvited,

    /// Players linked as themselves by their own email: to an account they
    /// had, or a new one that got a setup email (PLAYER-1).
    @Default(0) int playersLinked,
    @Default(0) int playersInvited,

    /// Guardians given a name and no email, "Emma: Maria R.": nobody can be
    /// linked without an email, so they're listed instead (PLAYER-1).
    @Default(<String>[]) List<String> guardiansWithoutEmail,

    /// "Emma: maria@example.com", with the reason when there is one, such
    /// as " (too-many-teams)" for someone on 100 teams already (TEAM-2) or
    /// " (already-a-player)" (PLAYER-3); see describeAddProblem.
    @Default(<String>[]) List<String> problems,
  }) = _AddPlayersResult;
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
