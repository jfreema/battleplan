import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/settings/domain/local_prefs_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsRepository implements LocalPrefsRepository {
  new(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const _themeKey = 'themePreference';
  static const _lastRouteKey = 'lastTeamRoute';
  static const Set<String> keys = {_themeKey, _lastRouteKey};

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
}
