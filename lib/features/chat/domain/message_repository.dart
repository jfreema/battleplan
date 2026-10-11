import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/domain/message.dart';

/// Owns `messages` (ARCH §5.3). The newest page is live; older pages are
/// one-shot reads, so a chat with years of history opens as fast as a new
/// one (CHAT-1).
abstract interface class MessageRepository {
  /// The newest [limit] messages, newest first, kept live. The cursor points
  /// past the oldest of them, for [loadOlder].
  Stream<MessagePage> watchNewest(GroupId groupId, {int limit = 50});

  /// The [limit] messages before [before], newest first.
  Future<MessagePage> loadOlder(
    GroupId groupId,
    PageCursor before, {
    int limit = 50,
  });

  /// Sends a text message as the signed-in person (CHAT-2). It appears in
  /// [watchNewest] at once as pending; the future completes when the server
  /// has it (offline, when the connection returns).
  Future<void> sendText(GroupId groupId, UserId uid, String text);
}
