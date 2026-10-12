import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/groups/domain/group.dart';

/// Owns `auditLogs`, `config`, and the admin callables (ARCH §5.2). Every
/// call but [watchConfig] is for super admins only; the server checks the
/// `superAdmin` claim and writes the audit entries (ADMIN-8).
abstract interface class AdminRepository {
  /// ADMIN-1 totals.
  Future<AdminTotals> totals();

  /// A page of teams (ADMIN-2), after [after] when given.
  Future<AdminPage<AdminTeamRow>> listTeams(
    AdminTeamQuery query, {
    PageCursor? after,
    int limit,
  });

  /// ADMIN-3: the team's people, players, live invites, and content counts.
  Future<AdminTeamDetail> team(GroupId id);

  /// Records that a super admin opened the team's tabs ("Viewing as super
  /// admin", ADMIN-3) in the audit log.
  Future<void> openGroup(GroupId id);

  /// Suspends the team (members see "This team has been suspended") or
  /// lifts it (ADMIN-3).
  Future<void> setGroupSuspended(
    GroupId id, {
    required bool suspended,
    String? note,
  });

  /// Archives (read-only) or restores the team (ADMIN-3, TEAM-9).
  Future<void> setGroupArchived(GroupId id, {required bool archived});

  /// Permanently deletes the team; [confirmName] must match its name.
  Future<void> deleteGroup(GroupId id, String confirmName);

  /// Edits the profile, settings, or chat look of a team the super admin
  /// isn't an admin of (ADMIN-3, TEAM-5, CHAT-18), with the limits its own
  /// admins have, and audited. [photoPath] names a logo already uploaded to
  /// the team's `avatar/` folder; a chat background photo is in
  /// [chatTheme], uploaded to its `theme/` folder.
  Future<void> updateGroup(
    GroupId id, {
    String? name,
    String? description,
    String? color,
    Sport? sport,
    String? timeZone,
    GroupSettings? settings,
    ChatTheme? chatTheme,
    String? photoPath,
  });

  /// Edits a player's name, number, and position on a team the super admin
  /// isn't an admin of (ADMIN-3, PLAYER-2), audited. A blank number or
  /// position clears it.
  Future<void> updatePlayer(
    PlayerId id, {
    required String name,
    String? jerseyNumber,
    String? position,
  });

  /// A page of people (ADMIN-4), after [after] when given.
  Future<AdminPage<AdminUserRow>> listUsers(
    AdminUserQuery query, {
    PageCursor? after,
    int limit,
  });

  /// ADMIN-4 details for one person.
  Future<AdminUserDetail> user(UserId uid);

  /// Creates an account and sends its setup email (AUTH-6), optionally
  /// adding it to [groupId] as [role]. Returns the new uid.
  Future<UserId> createUser({
    required String email,
    required String displayName,
    GroupId? groupId,
    MemberRole? role,
  });

  /// Renames the person everywhere (SET-1).
  Future<void> renameUser(UserId uid, String displayName);

  /// Adds the person to a team as [role] (member or admin).
  Future<void> addUserToGroup(UserId uid, GroupId groupId, MemberRole role);

  /// Disables (and signs out) or enables an account (AUTH-11).
  Future<void> setUserDisabled(UserId uid, {required bool disabled});

  /// Signs the person out on every device.
  Future<void> revokeSessions(UserId uid);

  /// Emails a password reset link. Nobody ever sees or sets the password
  /// (AUTH-6, ADMIN-8).
  Future<void> sendPasswordReset(UserId uid);

  /// Deletes the account as AUTH-10 does. Throws LastSuperAdmin for the
  /// last super admin, InvalidInput for yourself.
  Future<void> deleteUser(UserId uid);

  /// Grants or revokes super admin. Throws LastSuperAdmin when revoking
  /// the last one.
  Future<void> setSuperAdmin(UserId uid, {required bool superAdmin});

  /// A page of reports from every team (ADMIN-5), newest first.
  Future<AdminPage<AdminReport>> listReports(
    ReportStatus status, {
    PageCursor? after,
    int limit,
  });

  /// Acts on a report and closes it with [note] (ADMIN-5).
  Future<void> resolveReport(
    String reportId,
    AdminReportAction action,
    String note,
  );

  /// A page of the audit log, newest first (ADMIN-6).
  Future<AdminPage<AuditEntry>> auditLog(
    AuditFilter filter, {
    PageCursor? after,
    int limit,
  });

  /// Platform settings, live. Everyone signed in reads them, for the
  /// announcement banner (ADMIN-7).
  Stream<AppConfig> watchConfig();

  /// Saves platform settings (ADMIN-7).
  Future<void> updateConfig(AppConfig config);
}
