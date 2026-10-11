import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/settings/domain/local_prefs_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores device-local preferences in SharedPreferences (localStorage on
/// web). Owns no Firestore data.
class SharedPrefsRepository implements LocalPrefsRepository {
  new(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const _themeKey = 'themePreference';
  static const _lastRouteKey = 'lastTeamRoute';
  static const _pendingEmailKey = 'pendingSignInEmail';

  /// Every key this repository uses. The cache in bootstrap only loads
  /// these, so stray keys from other code are never read.
  static const Set<String> keys = {_themeKey, _lastRouteKey, _pendingEmailKey};

  @override
  ThemePreference get themePreference =>
      ThemePreference.tryParse(_prefs.getString(_themeKey)) ??
      ThemePreference.system;

  @override
  Future<void> setThemePreference(ThemePreference value) =>
      _prefs.setString(_themeKey, value.value);

  @override
  String? get lastTeamRoute => _prefs.getString(_lastRouteKey);

  @override
  Future<void> setLastTeamRoute(String route) =>
      _prefs.setString(_lastRouteKey, route);

  @override
  String? get pendingSignInEmail => _prefs.getString(_pendingEmailKey);

  @override
  Future<void> setPendingSignInEmail(String? email) => email == null
      ? _prefs.remove(_pendingEmailKey)
      : _prefs.setString(_pendingEmailKey, email);
}
