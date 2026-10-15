import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/plays/domain/play.dart';

/// The whiteboard's drawing on this device, one per team (SPEC BOARD-2):
/// like a real whiteboard, it stays until it's cleared. It's never sent
/// anywhere; saving a play is what shares it with the team (BOARD-4).
abstract interface class WhiteboardStore {
  PlayDraft? load(GroupId groupId);

  Future<void> save(GroupId groupId, PlayDraft draft);
}

/// A whiteboard store that forgets when the app closes: for tests, and
/// until the device's is wired in.
class MemoryWhiteboardStore implements WhiteboardStore {
  final Map<GroupId, PlayDraft> _boards = {};

  @override
  PlayDraft? load(GroupId groupId) => _boards[groupId];

  @override
  Future<void> save(GroupId groupId, PlayDraft draft) async =>
      _boards[groupId] = draft;
}
