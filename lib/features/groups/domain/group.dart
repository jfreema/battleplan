import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';

/// A team's member permissions and defaults (TEAM-5).
@freezed
abstract class GroupSettings with _$GroupSettings {
  const factory({
    @Default(false) bool membersCanCreateEvents,
    @Default(true) bool membersCanCreatePolls,
    @Default(true) bool membersCanUploadDocs,
    @Default(true) bool membersCanInvite,
    @Default(true) bool allowMaybe,

    /// Minutes before an event (1440 = 1 day).
    @Default(<int>[1440]) List<int> defaultReminderOffsets,
  }) = _GroupSettings;
}

/// The chat background choices (CHAT-18).
enum ChatBackground { plain, pattern, photo }

/// A team's chat look (CHAT-18), chosen by its admins for everyone.
@freezed
abstract class ChatTheme with _$ChatTheme {
  const factory({
    /// ARGB from the team palette; null uses the team's own color.
    int? bubbleColor,
    @Default(ChatBackground.plain) ChatBackground background,
    String? backgroundPath,
  }) = _ChatTheme;
}

/// Bytes in a megabyte, as the storage limits count them (ARCH §6.11).
const int bytesPerMb = 1024 * 1024;

/// Where a team's storage stands (ARCH §6.11 warning levels).
enum StorageLevel {
  ok,

  /// At or past 90% (STORE-3): amber, and admins are warned.
  nearlyFull,

  /// At or past the limit (STORE-4): no uploads, attachments, or new
  /// events. The same test as the rules' `hasRoom`.
  full,
}

/// [used] against [quota]. No quota (only a team read without one) is
/// never full.
StorageLevel storageLevelOf(int used, int quota) {
  if (quota <= 0) return StorageLevel.ok;
  if (used >= quota) return StorageLevel.full;
  if (used * 100 >= quota * Limits.storageWarnPercent) {
    return StorageLevel.nearlyFull;
  }
  return StorageLevel.ok;
}

/// A team (ARCH §6.2 `groups`).
@freezed
abstract class Group with _$Group {
  const factory({
    required GroupId id,
    required String name,
    required Sport sport,
    required int memberCount,

    /// One kind of team (TEAM-1); a missing kind reads as a team, so a
    /// basic group can be added later (TEAM-14).
    @Default(GroupKind.team) GroupKind kind,
    String? description,

    /// ARGB team color (one of `teamColorValues`).
    int? color,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    DateTime? archivedAt,
    DateTime? suspendedAt,
    String? ownerId,
    String? photoPath,
    @Default('America/Chicago') String timeZone,
    @Default(GroupSettings()) GroupSettings settings,

    /// Bytes stored under `groups/{id}/`, kept by the Storage triggers.
    @Default(0) int storageBytes,

    /// The team's limit: 500 MB unless a super admin changed it (STORE-1,
    /// STORE-6). The data layer fills in the default when it's missing.
    @Default(0) int storageQuotaBytes,
    ChatTheme? chatTheme,

    /// The chat's pinned messages, oldest pin first, at most
    /// [Limits.pinnedMessagesMax] (CHAT-15). Only the server changes them.
    @Default(<String>[]) List<String> pinnedMessageIds,
  }) = _Group;

  const new _();

  bool get isArchived => archivedAt != null;

  StorageLevel get storageLevel =>
      storageLevelOf(storageBytes, storageQuotaBytes);

  /// At or past 90% of the limit (STORE-3), full included.
  bool get storageNearlyFull => storageLevel != StorageLevel.ok;

  /// At or past the limit (STORE-4). M6's New event checks this too.
  bool get storageFull => storageLevel == StorageLevel.full;
}
