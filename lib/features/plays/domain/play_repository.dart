import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/plays/domain/play.dart';

/// Owns `plays` (ARCH §6.14, SPEC BOARD-4). Plays are written directly
/// under the rules: the team's admins write them, and everyone on the team
/// reads them.
abstract interface class PlayRepository {
  /// The team's plays, most recently changed first, live.
  Stream<List<Play>> watchPlays(GroupId groupId);

  /// One play, live; null once it's deleted.
  Stream<Play?> watchPlay(PlayId id);

  /// Saves a new play by [uid] and returns its ID.
  Future<PlayId> create(GroupId groupId, UserId uid, PlayDraft draft);

  /// Saves changes to a play.
  Future<void> update(PlayId id, PlayDraft draft);

  Future<void> delete(PlayId id);
}
