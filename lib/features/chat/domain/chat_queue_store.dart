import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_queue_store.freezed.dart';

/// A text message waiting in the send queue (CHAT-4), with whom it names
/// (CHAT-14) and whether it's an announcement (CHAT-15).
@freezed
abstract class SavedText with _$SavedText {
  const factory({
    required String id,
    required String text,
    String? replyToId,
    @Default(<String>[]) List<String> mentions,
    @Default(false) bool mentionsEveryone,
    @Default(false) bool announcement,
  }) = _SavedText;
}

/// Keeps the send queue on the device, so text messages typed offline
/// survive the app being closed and go out when it next opens the chat
/// (CHAT-4, SPEC §8.1 "Nothing is lost on flaky connections").
abstract interface class ChatQueueStore {
  /// The saved queue for a team, oldest first.
  List<SavedText> load(GroupId groupId);

  /// Replaces the saved queue for a team; empty clears it.
  Future<void> save(GroupId groupId, List<SavedText> items);
}

/// Keeps the queue in memory only: for tests, and where nothing else is
/// wired.
class MemoryChatQueueStore implements ChatQueueStore {
  final Map<GroupId, List<SavedText>> _queues = {};

  @override
  List<SavedText> load(GroupId groupId) => [...?_queues[groupId]];

  @override
  Future<void> save(GroupId groupId, List<SavedText> items) async {
    if (items.isEmpty) {
      _queues.remove(groupId);
    } else {
      _queues[groupId] = [...items];
    }
  }
}
