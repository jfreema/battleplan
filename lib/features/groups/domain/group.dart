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

/// A team's plan, cached from its license by the server (ARCH §6.11).
@freezed
abstract class GroupPlan with _$GroupPlan {
  const factory({
    @Default(PlanTier.free) PlanTier tier,
    DateTime? endsAt,
    String? licenseId,

    /// Who holds the license and can move it (PLAN-3).
    String? holderId,
  }) = _GroupPlan;

  const new _();

  /// Plus right now: the tier, and an end date still ahead (the same test
  /// the security rules make).
  bool isPlusAt(DateTime now) =>
      tier == PlanTier.plus && endsAt != null && endsAt!.isAfter(now);
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
    @Default(GroupPlan()) GroupPlan plan,
  }) = _Group;

  const new _();

  bool get isArchived => archivedAt != null;

  /// On Plus right now (PLAN-1).
  bool get isPlus => plan.isPlusAt(DateTime.now());

  /// Whether a Plus feature is live on this team; Free teams show the Plus
  /// badge instead (PLAN-4). Every feature in [PlanFeature] is Plus-only.
  bool has(PlanFeature feature) => isPlus;
}
