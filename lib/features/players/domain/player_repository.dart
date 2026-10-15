import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';

/// Owns `players`, `playerGuardians` (player links), `guardianRequests`
/// (player claims), and `playerDetails` (ARCH §5.2).
abstract interface class PlayerRepository {
  /// A team's active players, the roster everyone sees (PLAYER-4).
  Stream<List<Player>> watchPlayers(GroupId groupId);

  /// A team's pending players (PLAYER-4). Admins only.
  Stream<List<Player>> watchPendingPlayers(GroupId groupId);

  /// The pending players [uid] added on a team (PLAYER-4).
  Stream<List<Player>> watchMyPendingPlayers(GroupId groupId, UserId uid);

  Stream<List<GuardianLink>> watchGuardianLinks(GroupId groupId);

  /// Adds players (PLAYER-1), active at once, and returns how many were
  /// added. Admins only. Parents, guardians, and adult players link
  /// themselves by claiming them (PLAYER-3).
  Future<int> addPlayers(GroupId groupId, List<NewPlayer> players);

  /// Edits a player's name or number (PLAYER-2). Linked members and
  /// admins.
  Future<void> updatePlayer(
    PlayerId id, {
    required String name,
    String? jerseyNumber,
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
    String? dateOfBirth,
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

  /// Makes someone already on the team a guardian (PLAYER-5), with no
  /// email. Linked members (the player themselves included) and admins.
  Future<void> addTeamMemberAsGuardian(
    GroupId groupId,
    PlayerId playerId,
    UserId uid,
  );

  /// Removes a link from a player (PLAYER-2). Admins, or the linked
  /// member themselves.
  Future<void> removeGuardian(GroupId groupId, PlayerId playerId, UserId uid);

  /// A player's details (PLAYER-12), or null when there are none. Only the
  /// team's admins and the members linked to the player may ask.
  Stream<PlayerDetails?> watchPlayerDetails(PlayerId playerId);

  /// Every player's details on a team, for their ages on the roster
  /// (PLAYER-12). Admins only.
  Stream<List<PlayerDetails>> watchTeamPlayerDetails(GroupId groupId);

  /// Saves a player's details as [by] (PLAYER-12). [stored] is what was
  /// there, which decides the medical consent ([medicalConsentFor]): new
  /// or changed medical notes record it, and clearing them clears it.
  /// Admins and linked members, while the team isn't archived.
  Future<void> savePlayerDetails(
    PlayerDetails details, {
    required UserId by,
    PlayerDetails? stored,
  });

  /// Removes a player's details (PLAYER-12). Admins and linked members.
  Future<void> deletePlayerDetails(PlayerId playerId);
}
