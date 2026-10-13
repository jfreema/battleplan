import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/domain/player.dart';

/// Owns `players`, `playerGuardians` (player links), and
/// `guardianRequests` (player claims) (ARCH §5.2).
abstract interface class PlayerRepository {
  /// A team's active players, the roster everyone sees (PLAYER-4).
  Stream<List<Player>> watchPlayers(GroupId groupId);

  /// A team's pending players (PLAYER-4). Admins only.
  Stream<List<Player>> watchPendingPlayers(GroupId groupId);

  /// The pending players [uid] added on a team (PLAYER-4).
  Stream<List<Player>> watchMyPendingPlayers(GroupId groupId, UserId uid);

  Stream<List<GuardianLink>> watchGuardianLinks(GroupId groupId);

  /// Adds players with their own emails and their guardians (PLAYER-1),
  /// active at once. Admins only.
  Future<AddPlayersResult> addPlayers(GroupId groupId, List<NewPlayer> players);

  /// Edits a player's name, number, or position (PLAYER-2). Linked members
  /// and admins.
  Future<void> updatePlayer(
    PlayerId id, {
    required String name,
    String? jerseyNumber,
    String? position,
  });

  /// Removes a player (PLAYER-2). Admins only.
  Future<void> removePlayer(GroupId groupId, PlayerId id);

  /// A team's pending claims (PLAYER-4). Admins only.
  Stream<List<GuardianRequest>> watchPendingRequests(GroupId groupId);

  /// The signed-in person's own claims on a team (PLAYER-3).
  Stream<List<GuardianRequest>> watchMyRequests(GroupId groupId, UserId uid);

  /// Claims a player as [relation] (PLAYER-3): approved at once for
  /// admins (super admins on the team included), otherwise sent to the
  /// admins.
  Future<ClaimOutcome> claimPlayer(
    GroupId groupId,
    PlayerId playerId,
    PlayerRelation relation,
  );

  /// Approves or declines a claim (PLAYER-4). Admins only.
  Future<void> resolvePlayerClaim(
    GroupId groupId,
    PlayerId playerId,
    UserId uid, {
    required bool approve,
  });

  /// Adds a player who isn't listed, linked to the caller as [relation]
  /// (PLAYER-4). Pending until an admin approves, unless the caller is an
  /// admin. Returns the new player's status.
  Future<PlayerStatus> proposePlayer(
    GroupId groupId, {
    required String name,
    required PlayerRelation relation,
    String? jerseyNumber,
    String? position,
  });

  /// Approves or declines a pending player (PLAYER-4); declining deletes
  /// it. Admins only. Returns whether the member who added it is now
  /// linked to it: false after declining, or when they couldn't be (they
  /// left, or are a player on the team already).
  Future<bool> resolvePendingPlayer(
    GroupId groupId,
    PlayerId playerId, {
    required bool approve,
  });

  /// Adds a guardian by email (PLAYER-5). Linked members (the player
  /// themselves included) and admins. Returns
  /// true if they got a setup email for a new account.
  Future<bool> inviteGuardian(
    GroupId groupId,
    PlayerId playerId, {
    required String email,
    String? name,
  });

  /// Removes a link from a player (PLAYER-2). Admins, or the linked
  /// member themselves.
  Future<void> removeGuardian(GroupId groupId, PlayerId playerId, UserId uid);
}
