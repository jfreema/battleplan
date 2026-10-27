import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/polls/domain/poll.dart';

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

  /// The [limit] messages after [after], or after [cursor] (a newer page's
  /// [MessagePage.next]), newest first, for opening a chat at its first
  /// unread message and scrolling down from there (CHAT-1). Its `next` is
  /// null once the newest message is reached; its `older` continues older.
  Future<MessagePage> loadNewer(
    GroupId groupId, {
    DateTime? after,
    PageCursor? cursor,
    int limit = 50,
  });

  /// The team's photo messages, newest first, [limit] at a time from
  /// [before] (a page's [MessagePage.next]), for the Photos gallery
  /// (DOC-7).
  Future<MessagePage> photoMessages(
    GroupId groupId, {
    PageCursor? before,
    int limit = 30,
  });

  /// A fresh message ID, so a queued message keeps one identity from the
  /// moment it's typed until the server has it.
  String newMessageId();

  /// Sends a text message as the signed-in person (CHAT-2). It appears in
  /// [watchNewest] at once as pending; the future completes when the server
  /// has it (offline, when the connection returns) and throws if the server
  /// refuses it. [mentions] are the people it names with @, and
  /// [mentionsEveryone] an admin's @everyone (CHAT-14); [announcement]
  /// makes it an admin's announcement (CHAT-15).
  Future<void> sendText(
    GroupId groupId,
    UserId uid,
    String text, {
    String? id,
    String? replyToId,
    List<String> mentions = const [],
    bool mentionsEveryone = false,
    bool announcement = false,
  });

  /// One message, live, for the pinned bar (CHAT-15). Null once it's gone
  /// or can't be read.
  Stream<Message?> watchMessage(GroupId groupId, String messageId);

  /// Pins or unpins a message through the `pinMessage` callable (CHAT-15):
  /// team admins and super admins. Throws `InvalidInput('too-many-pins')`
  /// when the bar is full.
  Future<void> setPinned(String messageId, {required bool pinned});

  /// Uploads up to 10 photos for a new message (CHAT-3). [onProgress] gets
  /// 0 to 1 as bytes upload. Needs a connection; photos don't queue offline
  /// (CHAT-4).
  Future<UploadedPhotos> uploadPhotos(
    GroupId groupId,
    List<NewPhoto> photos, {
    void Function(double progress)? onProgress,
  });

  /// Posts uploaded photos as one message, with an optional caption.
  /// [playId] makes it a posted play, whose picture opens that saved play
  /// (BOARD-5).
  Future<void> sendPhotos(
    GroupId groupId,
    UserId uid,
    UploadedPhotos photos, {
    String caption = '',
    String? replyToId,
    String? playId,
  });

  /// Posts a poll and its chat message together (POLL-1); they share an ID,
  /// [id] or a new one. Like text, it shows once written and goes out when
  /// the connection allows.
  Future<void> sendPoll(
    GroupId groupId,
    UserId uid,
    NewPoll poll, {
    String? id,
  });

  /// A URL to show a message photo.
  Future<String?> attachmentUrl(String path);

  /// A message photo's bytes, for sharing or saving.
  Future<Uint8List?> attachmentBytes(String path);

  /// How many messages arrived after [since], up to [cap] (CHAT-9): people's
  /// messages, not system lines ("Sam joined"), and not from [skipAuthors]
  /// (people I blocked, CHAT-12). Aggregate reads, not one per message.
  Future<int> countUnread(
    GroupId groupId,
    DateTime since, {
    int cap = 100,
    Set<String> skipAuthors = const {},
  });

  /// Deletes a message through the `deleteMessage` callable (CHAT-8): the
  /// author, a team admin, or a super admin.
  Future<void> deleteMessage(String messageId);

  /// Replaces the text of the person's own message (CHAT-15).
  Future<void> editText(String messageId, String text);

  /// Sets or clears the person's one reaction on a message (CHAT-6).
  Future<void> setReaction(String messageId, UserId uid, Reaction? reaction);
}
