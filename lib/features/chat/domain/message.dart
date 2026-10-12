import 'dart:typed_data';

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

    /// The poll a poll message shows; it has the message's ID (POLL-1).
    String? pollId,

    /// The quote a reply shows, written by the server (CHAT-13, D25).
    ReplyPreview? replyPreview,

    /// Photos, up to 10 (CHAT-3).
    @Default(<Attachment>[]) List<Attachment> attachments,
    @Default(<String, Reaction>{}) Map<String, Reaction> reactions,
    DateTime? deletedAt,

    /// Set when the author edited the text (CHAT-15); shows "edited".
    DateTime? editedAt,

    /// Who deleted it: the author ("This message was deleted") or an admin
    /// ("Removed by a team admin") (CHAT-8).
    String? deletedReason,

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

/// A photo in a message, stored at `groups/{g}/messages/{id}/{n}.jpg`.
@freezed
abstract class Attachment with _$Attachment {
  const factory({
    required String path,
    @Default('image/jpeg') String contentType,
    @Default(0) int width,
    @Default(0) int height,
    @Default(0) int size,
  }) = _Attachment;

  const new _();

  /// Width over height, or 1 when unknown.
  double get aspectRatio => width > 0 && height > 0 ? width / height : 1;
}

/// A photo about to be sent, already resized.
typedef NewPhoto = ({Uint8List bytes, String contentType});

/// Photos already in Storage for a message that isn't posted yet.
typedef UploadedPhotos = ({String messageId, List<Attachment> attachments});

/// What a reply shows of the message it answers.
@freezed
abstract class ReplyPreview with _$ReplyPreview {
  const factory({
    required String authorName,
    required String text,
    @Default(MessageType.text) MessageType type,
    @Default(false) bool deleted,
  }) = _ReplyPreview;
}
