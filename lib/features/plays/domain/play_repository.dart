import 'dart:typed_data';

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

  /// Shares a play by a public link (BOARD-6), with [image], a PNG of its
  /// last step, for the link's preview. Returns the link's ID, the same
  /// each time for the same play.
  Future<String> share(PlayId id, {Uint8List? image});

  /// Takes a play's link down.
  Future<void> stopSharing(PlayId id);

  /// A shared play by its link's ID, signed in or not; null if it isn't
  /// shared (anymore).
  Future<PlayDraft?> sharedPlay(String shareId);
}
