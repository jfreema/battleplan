import 'dart:convert';
import 'dart:math';

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
  static const _pendingLinkKey = 'pendingLink';
  static const _installIdKey = 'installId';
  static const _prePromptKey = 'pushPrePromptShown';
  static const _deviceKey = 'deviceRegistration';

  /// Every key this repository uses. The cache in bootstrap only loads
  /// these, so stray keys from other code are never read.
  static const Set<String> keys = {
    _themeKey,
    _lastRouteKey,
    _pendingEmailKey,
    _pendingLinkKey,
    _installIdKey,
    _prePromptKey,
    _deviceKey,
  };

  static const _idAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

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

  /// Stored as `providerId email`; neither has a space.
  @override
  PendingLink? get pendingLink {
    final parts = _prefs.getString(_pendingLinkKey)?.split(' ');
    if (parts == null || parts.length != 2) return null;
    return (providerId: parts[0], email: parts[1]);
  }

  @override
  Future<void> setPendingLink(PendingLink? value) => value == null
      ? _prefs.remove(_pendingLinkKey)
      : _prefs.setString(_pendingLinkKey, '${value.providerId} ${value.email}');

  @override
  String get installId {
    final existing = _prefs.getString(_installIdKey);
    if (existing != null) return existing;
    // 24 characters from 62 is about 143 random bits: unguessable, which
    // the devices rules rely on (ARCH §6.3).
    final random = Random.secure();
    final id = String.fromCharCodes([
      for (var i = 0; i < 24; i++)
        _idAlphabet.codeUnitAt(random.nextInt(_idAlphabet.length)),
    ]);
    // The cache updates at once, so later reads get the same ID even before
    // the platform write finishes.
    _prefs.setString(_installIdKey, id).ignore();
    return id;
  }

  @override
  bool get pushPrePromptShown => _prefs.getBool(_prePromptKey) ?? false;

  @override
  Future<void> setPushPrePromptShown() => _prefs.setBool(_prePromptKey, true);

  @override
  DeviceRegistration? get deviceRegistration {
    final raw = _prefs.getString(_deviceKey);
    if (raw == null) return null;
    try {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      return (
        uid: d['uid'] as String,
        token: d['token'] as String,
        at: DateTime.fromMillisecondsSinceEpoch((d['at'] as num).toInt()),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> setDeviceRegistration(DeviceRegistration? value) => value == null
      ? _prefs.remove(_deviceKey)
      : _prefs.setString(
          _deviceKey,
          jsonEncode({
            'uid': value.uid,
            'token': value.token,
            'at': value.at.millisecondsSinceEpoch,
          }),
        );
}
