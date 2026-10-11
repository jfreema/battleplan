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

/// A team (ARCH §6.2 `groups`).
@freezed
abstract class Group with _$Group {
  const factory({
    required GroupId id,
    required String name,
    required Sport sport,
    required TeamType teamType,
    required int memberCount,
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
    @Default(0) int storageBytes,
    @Default(0) int storageQuotaBytes,
  }) = _Group;

  const new _();

  bool get isArchived => archivedAt != null;
}
