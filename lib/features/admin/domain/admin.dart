import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin.freezed.dart';

/// The longest announcement banner (ADMIN-7).
const int announcementTextMax = Limits.announcementBannerMax;

/// The longest note a report resolution saves (ADMIN-5).
const int reportNoteMax = Limits.reportNoteMax;

/// The most rows one admin list call returns (ADMIN-2, ADMIN-4, ADMIN-5).
const int adminPageSize = 50;

/// A page of admin rows and where the next one starts (ARCH §5.3).
typedef AdminPage<T> = ({List<T> items, PageCursor? next});

/// ADMIN-1: the platform's totals, from count and sum aggregations.
@freezed
abstract class AdminTotals with _$AdminTotals {
  const factory({
    @Default(0) int users,
    @Default(0) int teams,

    /// Teams created in the last 7 days.
    @Default(0) int newTeams,

    /// Teams with a message in the last 7 days.
    @Default(0) int activeTeams,

    /// Messages sent in the last 7 days.
    @Default(0) int messages,

    /// Bytes stored across every team.
    @Default(0) int storageBytes,
    @Default(0) int openReports,
  }) = _AdminTotals;
}

/// How the teams list is ordered (ADMIN-2), newest or largest first.
enum AdminTeamSort { created, activity, members, storage }

/// A team's state in the admin panel (ADMIN-2). Suspended wins over
/// archived, as the server decides it.
enum TeamStatus { active, archived, suspended }

/// The teams list's search, sort, and filter (ADMIN-2).
@freezed
abstract class AdminTeamQuery with _$AdminTeamQuery {
  const factory({
    /// A name prefix; blank lists every team.
    @Default('') String query,
    @Default(AdminTeamSort.created) AdminTeamSort sort,

    /// Null shows every status.
    TeamStatus? status,
  }) = _AdminTeamQuery;
}

/// One row of the teams list (ADMIN-2).
@freezed
abstract class AdminTeamRow with _$AdminTeamRow {
  const factory({
    required GroupId id,
    required String name,
    @Default(Sport.other) Sport sport,
    @Default(TeamType.adult) TeamType teamType,
    String? ownerId,
    @Default('') String ownerName,
    @Default(0) int memberCount,
    DateTime? lastMessageAt,
    @Default(0) int storageBytes,
    @Default(0) int storageQuotaBytes,
    @Default(TeamStatus.active) TeamStatus status,
    DateTime? createdAt,
  }) = _AdminTeamRow;
}

/// An invite that still works, on a team's admin page (ADMIN-3).
@freezed
abstract class AdminInvite with _$AdminInvite {
  const factory({
    required String code,

    /// True for the team's reusable link, false for an email invite.
    @Default(true) bool isLink,
    String? email,
    @Default(0) int useCount,
    int? maxUses,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) = _AdminInvite;
}

/// ADMIN-3: what the team's own documents don't say. The team itself is
/// read live from `groups`.
@freezed
abstract class AdminTeamDetail with _$AdminTeamDetail {
  const factory({
    required GroupId id,
    @Default('') String ownerName,
    @Default(TeamStatus.active) TeamStatus status,
    DateTime? createdAt,

    /// Everyone on the team, with their roles.
    @Default(<Membership>[]) List<Membership> members,

    /// Youth teams: the players and who guards them.
    @Default(<Player>[]) List<Player> players,
    @Default(<GuardianLink>[]) List<GuardianLink> guardians,
    @Default(<AdminInvite>[]) List<AdminInvite> invites,
    @Default(0) int eventCount,
    @Default(0) int documentCount,
    @Default(0) int pollCount,
  }) = _AdminTeamDetail;
}

/// The users list's filters (ADMIN-4). "Added" is an account someone
/// added by email that hasn't signed in yet.
enum AdminUserFilter { added, active, disabled, superAdmin }

/// The users list's search and filter (ADMIN-4).
@freezed
abstract class AdminUserQuery with _$AdminUserQuery {
  const factory({
    /// A name or email prefix; blank lists everyone.
    @Default('') String query,
    AdminUserFilter? filter,
  }) = _AdminUserQuery;
}

/// One row of the users list (ADMIN-4).
@freezed
abstract class AdminUserRow with _$AdminUserRow {
  const factory({
    required UserId uid,
    @Default('') String displayName,
    String? email,
    @Default(UserStatus.active) UserStatus status,
    @Default(false) bool superAdmin,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) = _AdminUserRow;
}

/// One of a person's teams, with their role there (ADMIN-4).
@freezed
abstract class AdminUserTeam with _$AdminUserTeam {
  const factory({
    required GroupId groupId,
    @Default('') String name,
    @Default(MemberRole.member) MemberRole role,
  }) = _AdminUserTeam;
}

/// ADMIN-4 details: the profile, how they sign in, and their teams.
@freezed
abstract class AdminUserDetail with _$AdminUserDetail {
  const factory({
    required AdminUserRow user,

    /// `password`, `google.com`, `apple.com`.
    @Default(<String>[]) List<String> signInMethods,
    @Default(<AdminUserTeam>[]) List<AdminUserTeam> teams,
  }) = _AdminUserDetail;
}

/// A report in the super-admin queue (ADMIN-5): what was reported, by
/// whom, and on which team.
@freezed
abstract class AdminReport with _$AdminReport {
  const factory({
    required String id,
    required GroupId groupId,
    @Default('') String groupName,
    @Default(ReportTargetType.message) ReportTargetType targetType,
    @Default('') String targetId,
    @Default(ReportReason.other) ReportReason reason,

    /// The person it's about, and a copy of what was reported.
    @Default('') String subjectId,
    @Default('') String subjectName,
    @Default('') String excerpt,
    String? details,
    @Default('') String reporterId,
    @Default('') String reporterName,
    @Default(ReportStatus.open) ReportStatus status,

    /// How it was closed, and the super admin's note.
    String? resolution,
    String? note,
    DateTime? createdAt,
  }) = _AdminReport;
}

/// What a super admin does about a report (ADMIN-5). Each saves a note.
enum AdminReportAction {
  /// The reported message or document. Not for a reported person.
  deleteContent,
  removeMember,
  disableUser,
  suspendTeam,
  dismiss,
}

/// The actions that fit [report]: a reported person has no content to
/// delete.
List<AdminReportAction> reportActionsFor(AdminReport report) => [
  for (final a in AdminReportAction.values)
    if (a != AdminReportAction.deleteContent ||
        report.targetType != ReportTargetType.user)
      a,
];

/// One audit log entry (ADMIN-6): who did what, on which team, when, and
/// the values before and after.
@freezed
abstract class AuditEntry with _$AuditEntry {
  const factory({
    required String id,
    required String actorId,
    required String action,
    GroupId? groupId,
    @Default('') String targetType,
    @Default('') String targetId,
    Map<String, Object?>? before,
    Map<String, Object?>? after,
    DateTime? createdAt,
  }) = _AuditEntry;
}

/// The audit log's filters (ADMIN-6). Each one left empty matches all.
@freezed
abstract class AuditFilter with _$AuditFilter {
  const factory({
    String? actorId,
    String? action,
    GroupId? groupId,

    /// From the start of [from] through the end of [until], local days.
    DateTime? from,
    DateTime? until,
  }) = _AuditFilter;

  const new _();

  bool get isEmpty =>
      actorId == null &&
      action == null &&
      groupId == null &&
      from == null &&
      until == null;
}

/// How loud the announcement banner is (ADMIN-7).
enum BannerSeverity { info, warning, critical }

/// A message for everyone at the top of the app until [expiresAt]
/// (ADMIN-7).
@freezed
abstract class Announcement with _$Announcement {
  const factory({
    required String text,
    required BannerSeverity severity,
    required DateTime expiresAt,
  }) = _Announcement;

  const new _();

  /// Still to be shown at [now].
  bool isLiveAt(DateTime now) =>
      text.trim().isNotEmpty && expiresAt.isAfter(now);
}

/// Platform settings (ADMIN-7, ARCH §6.2 `config/app`). A missing field
/// reads as the shared default.
@freezed
abstract class AppConfig with _$AppConfig {
  const factory({
    @Default(true) bool allowUserGroupCreation,
    @Default(Limits.groupsCreatedPerUserPerDay)
    int maxGroupsCreatedPerUserPerDay,
    @Default(Limits.defaultStorageQuotaMb) int defaultStorageQuotaMb,
    @Default(Limits.maxUploadMb) int maxUploadMb,
    @Default('') String supportEmail,
    Announcement? announcementBanner,
  }) = _AppConfig;
}

/// What's wrong with a settings form (ADMIN-7), checked before saving; the
/// server checks the same ranges.
enum ConfigProblem {
  /// Teams per person per day: 1 to [Limits.groupsPerUserMax].
  groupsPerDay,

  /// 1 to [Limits.storageQuotaMaxMb] MB.
  defaultQuota,

  /// 1 to [Limits.maxUploadMb] MB: the storage rules refuse bigger files
  /// whatever this says.
  maxUpload,
  supportEmail,

  /// 1 to [announcementTextMax] characters.
  bannerText,

  /// The banner's end must be in the future.
  bannerExpiry,
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// The problems with [config] at [now], none when it can be saved.
Set<ConfigProblem> configProblems(AppConfig config, DateTime now) {
  final banner = config.announcementBanner;
  return {
    if (config.maxGroupsCreatedPerUserPerDay < 1 ||
        config.maxGroupsCreatedPerUserPerDay > Limits.groupsPerUserMax)
      ConfigProblem.groupsPerDay,
    if (config.defaultStorageQuotaMb < 1 ||
        config.defaultStorageQuotaMb > Limits.storageQuotaMaxMb)
      ConfigProblem.defaultQuota,
    if (config.maxUploadMb < 1 || config.maxUploadMb > Limits.maxUploadMb)
      ConfigProblem.maxUpload,
    if (!_email.hasMatch(config.supportEmail.trim()))
      ConfigProblem.supportEmail,
    if (banner != null &&
        (banner.text.trim().isEmpty ||
            banner.text.trim().length > announcementTextMax))
      ConfigProblem.bannerText,
    if (banner != null && !banner.expiresAt.isAfter(now))
      ConfigProblem.bannerExpiry,
  };
}
