import 'package:battleplan/core/constants.g.dart';

/// Preferences kept on this device (SPEC SET-2, §5.2 "Memory"). The theme
/// also syncs to the profile once `users` exists (M1).
abstract interface class LocalPrefsRepository {
  ThemePreference get themePreference;

  Future<void> setThemePreference(ThemePreference value);

  /// The last team and tab used on this device, as a route like
  /// `/g/abc/schedule`.
  String? get lastTeamRoute;

  Future<void> setLastTeamRoute(String route);

  /// The email a sign-in link was just sent to, so opening the link on this
  /// device can finish without asking again. Cleared after use.
  String? get pendingSignInEmail;

  Future<void> setPendingSignInEmail(String? email);
}
