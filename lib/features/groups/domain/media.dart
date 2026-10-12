import 'package:freezed_annotation/freezed_annotation.dart';

part 'media.freezed.dart';

/// What a stored file belongs to (STORE-5, ARCH §6.11): a chat photo, the
/// team logo, the chat background, a document (M7), or nothing.
enum MediaKind { chatPhoto, logo, background, document, other }

/// One file under `groups/{g}/`, as `listTeamMedia` reports it (STORE-5).
@freezed
abstract class MediaItem with _$MediaItem {
  const factory({
    /// The Storage path, which `deleteTeamMedia` takes.
    required String path,
    required int size,
    required MediaKind kind,
    String? contentType,
    DateTime? createdAt,

    /// A chat photo's message and its author.
    String? messageId,
    String? authorName,

    /// A document's record and its name (M7), while the record exists.
    /// [authorName] is then who added it.
    String? documentId,
    String? documentName,

    /// For a logo or background: whether the team still uses it. An older
    /// one left behind reads as false.
    bool? current,
  }) = _MediaItem;

  const new _();

  bool get isImage => contentType?.startsWith('image/') ?? false;
}

/// The team's files with its usage, read together so they agree.
@freezed
abstract class TeamMedia with _$TeamMedia {
  const factory({
    /// Largest first.
    required List<MediaItem> items,
    required int storageBytes,
    required int storageQuotaBytes,

    /// The server left out the smallest files of a very large team; deleting
    /// some brings the rest in.
    @Default(false) bool truncated,
  }) = _TeamMedia;
}
