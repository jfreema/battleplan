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
}
