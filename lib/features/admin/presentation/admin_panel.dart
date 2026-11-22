/// The God admin panel's screens (SPEC §6.11). The router imports this
/// library deferred, so on the web regular users never download it
/// (ARCH §5.6); everything else in the app stays out of it.
library;

export 'admin_reports_screen.dart' show AdminReportsScreen;
export 'audit_screen.dart' show AdminAuditScreen;
export 'dashboard_screen.dart' show AdminDashboardScreen;
export 'platform_settings_screen.dart' show PlatformSettingsScreen;
export 'team_detail_screen.dart' show AdminTeamScreen;
export 'teams_screen.dart' show AdminTeamsScreen;
export 'user_detail_screen.dart' show AdminUserScreen;
export 'users_screen.dart' show AdminUsersScreen;
