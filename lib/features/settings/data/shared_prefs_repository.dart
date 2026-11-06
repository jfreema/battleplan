import 'dart:convert';
import 'dart:math';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/scheme_defaults.dart';
import 'package:battleplan/features/settings/domain/local_prefs_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores device-local preferences in SharedPreferences (localStorage on
/// web). Owns no Firestore data.
class SharedPrefsRepository implements LocalPrefsRepository {
  new(this._prefs);

  final SharedPreferencesWithCache _prefs;

  /// The old theme setting, read once to seed the default scheme.
  static const _themeKey = 'themePreference';
  static const _defaultSchemeKey = 'defaultColorScheme';
  static const _teamSchemesKey = 'teamColorSchemes';
  static const _lastRouteKey = 'lastTeamRoute';
  static const _pendingEmailKey = 'pendingSignInEmail';
  static const _pendingLinkKey = 'pendingLink';
  static const _installIdKey = 'installId';
  static const _prePromptKey = 'pushPrePromptShown';
  static const _deviceKey = 'deviceRegistration';
  static const _passwordSetKey = 'passwordSetUids';

  /// Every key this repository uses. The cache in bootstrap only loads
  /// these, so stray keys from other code are never read.
  static const Set<String> keys = {
    _themeKey,
    _defaultSchemeKey,
    _teamSchemesKey,
    _lastRouteKey,
    _pendingEmailKey,
    _pendingLinkKey,
    _installIdKey,
    _prePromptKey,
    _deviceKey,
    _passwordSetKey,
  };

  static const _idAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  /// Stored as `uid scheme`; neither has a space.
  @override
  TeamScheme defaultScheme({String? uid}) {
    final parts = _prefs.getString(_defaultSchemeKey)?.split(' ');
    if (parts != null &&
        parts.length == 2 &&
        (uid == null || parts[0] == uid)) {
      final saved = TeamScheme.tryParse(parts[1]);
      if (saved != null) return saved;
    }
    final old = ThemePreference.tryParse(_prefs.getString(_themeKey));
    return schemeForThemeMode(old);
  }

  @override
  Future<void> setDefaultScheme(String uid, TeamScheme scheme) =>
      _prefs.setString(_defaultSchemeKey, '$uid ${scheme.value}');

  /// Stored as JSON: `{"uid": "...", "schemes": {"<groupId>": "navy"}}`.
  @override
  TeamScheme? teamScheme(String groupId, {String? uid}) {
    final raw = _prefs.getString(_teamSchemesKey);
    if (raw == null) return null;
    final Object? saved;
    try {
      saved = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (saved is! Map<String, dynamic>) return null;
    if (uid != null && saved['uid'] != uid) return null;
    final schemes = saved['schemes'];
    final value = schemes is Map<String, dynamic> ? schemes[groupId] : null;
    return value is String ? TeamScheme.tryParse(value) : null;
  }

  @override
  Future<void> setTeamSchemes(String uid, Map<String, TeamScheme> schemes) =>
      _prefs.setString(
        _teamSchemesKey,
        jsonEncode({
          'uid': uid,
          'schemes': {for (final e in schemes.entries) e.key: e.value.value},
        }),
      );

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
  bool passwordSet(String uid) =>
      _prefs.getStringList(_passwordSetKey)?.contains(uid) ?? false;

  @override
  Future<void> setPasswordSet(String uid, {required bool value}) {
    final uids = {...?_prefs.getStringList(_passwordSetKey)};
    if (value) {
      uids.add(uid);
    } else {
      uids.remove(uid);
    }
    return _prefs.setStringList(_passwordSetKey, uids.toList());
  }

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
