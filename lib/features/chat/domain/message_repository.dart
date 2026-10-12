import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
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

  /// A fresh message ID, so a queued message keeps one identity from the
  /// moment it's typed until the server has it.
  String newMessageId();

  /// Sends a text message as the signed-in person (CHAT-2). It appears in
  /// [watchNewest] at once as pending; the future completes when the server
  /// has it (offline, when the connection returns) and throws if the server
  /// refuses it.
  Future<void> sendText(
    GroupId groupId,
    UserId uid,
    String text, {
    String? id,
    String? replyToId,
  });

  /// Uploads up to 10 photos for a new message (CHAT-3). [onProgress] gets
  /// 0 to 1 as bytes upload. Needs a connection; photos don't queue offline
  /// (CHAT-4).
  Future<UploadedPhotos> uploadPhotos(
    GroupId groupId,
    List<NewPhoto> photos, {
    void Function(double progress)? onProgress,
  });

  /// Posts uploaded photos as one message, with an optional caption.
  Future<void> sendPhotos(
    GroupId groupId,
    UserId uid,
    UploadedPhotos photos, {
    String caption = '',
    String? replyToId,
  });

  /// A URL to show a message photo.
  Future<String?> attachmentUrl(String path);

  /// A message photo's bytes, for sharing or saving.
  Future<Uint8List?> attachmentBytes(String path);

  /// How many messages arrived after [since], up to [cap] (CHAT-9). One
  /// aggregate read, not one read per message.
  Future<int> countUnread(GroupId groupId, DateTime since, {int cap = 100});

  /// Deletes a message through the `deleteMessage` callable (CHAT-8): the
  /// author, a team admin, or a super admin.
  Future<void> deleteMessage(String messageId);

  /// Replaces the text of the person's own message (CHAT-15).
  Future<void> editText(String messageId, String text);

  /// Sets or clears the person's one reaction on a message (CHAT-6).
  Future<void> setReaction(String messageId, UserId uid, Reaction? reaction);
}
