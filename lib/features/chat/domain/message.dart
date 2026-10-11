import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';

/// One chat message (ARCH §6.2 `messages`). The author fields are a snapshot
/// of the sender's membership when they posted.
@freezed
abstract class Message with _$Message {
  const factory({
    required String id,
    required GroupId groupId,
    required String authorId,
    required String authorName,
    required MessageType type,
    @Default('') String text,
    String? authorPhotoPath,

    /// "Emma #7, Liam #23" for a guardian on a youth team (PLAYER-8).
    String? authorPlayerSummary,
    String? replyToId,
    @Default(<String, Reaction>{}) Map<String, Reaction> reactions,
    DateTime? deletedAt,

    /// When the server stamped it. Null while a sent message is still local.
    DateTime? createdAt,

    /// True until the server has the message (CHAT-4 "sending").
    @Default(false) bool pending,
  }) = _Message;

  const new _();

  bool get isSystem => type == MessageType.system;
}

/// Where a page of messages ends, for loading the next one (ARCH §5.3).
/// Opaque to screens; the data layer keeps whatever it needs inside.
class PageCursor {
  const new(this.handle);

  final Object handle;
}

/// A page of older or newer messages, newest first.
@freezed
abstract class MessagePage with _$MessagePage {
  const factory({required List<Message> messages, PageCursor? next}) =
      _MessagePage;

  const new _();

  /// False once the start of the chat is reached.
  bool get hasMore => next != null;
}
