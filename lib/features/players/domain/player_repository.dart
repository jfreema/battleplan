import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/domain/player.dart';

/// Owns `players`, `playerGuardians`, and `guardianRequests` (ARCH §5.2).
abstract interface class PlayerRepository {
  Stream<List<Player>> watchPlayers(GroupId groupId);

  Stream<List<GuardianLink>> watchGuardianLinks(GroupId groupId);

  /// Adds players with their guardians (PLAYER-1). Admins only.
  Future<AddPlayersResult> addPlayers(GroupId groupId, List<NewPlayer> players);

  /// Edits a player's name, number, or position (PLAYER-2). Guardians and
  /// admins.
  Future<void> updatePlayer(
    PlayerId id, {
    required String name,
    String? jerseyNumber,
    String? position,
  });

  /// Removes a player (PLAYER-2). Admins only.
  Future<void> removePlayer(GroupId groupId, PlayerId id);

  /// A team's pending guardian requests (PLAYER-4). Admins only.
  Stream<List<GuardianRequest>> watchPendingRequests(GroupId groupId);

  /// The signed-in person's own requests on a team (PLAYER-3).
  Stream<List<GuardianRequest>> watchMyRequests(GroupId groupId, UserId uid);

  /// "Who are you here for?": asks admins to link you (PLAYER-3).
  Future<void> requestGuardianLink(GroupId groupId, List<PlayerId> players);

  /// Approves or declines a request (PLAYER-4). Admins only.
  Future<void> resolveGuardianRequest(
    GroupId groupId,
    PlayerId playerId,
    UserId uid, {
    required bool approve,
  });

  /// Adds your own player who isn't listed, with you as guardian (PLAYER-3).
  Future<void> addMyPlayer(
    GroupId groupId, {
    required String name,
    String? jerseyNumber,
  });

  /// Adds a co-parent by email (PLAYER-5). Guardians and admins. Returns
  /// true if they got a setup email for a new account.
  Future<bool> inviteGuardian(
    GroupId groupId,
    PlayerId playerId, {
    required String email,
    String? name,
  });

  /// Removes a guardian from a player (PLAYER-2). Admins, or the guardian.
  Future<void> removeGuardian(GroupId groupId, PlayerId playerId, UserId uid);
}
