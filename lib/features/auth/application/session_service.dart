import 'dart:async';

import 'package:battleplan/core/logging.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/domain/auth_repository.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/application/push_registration.dart';
import 'package:battleplan/features/notifications/domain/device_repository.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/features/settings/domain/local_prefs_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_service.g.dart';

/// Signing out (AUTH-9) touches several repositories: this device stops
/// getting pushes, then the session ends. Screens call this, never the
/// repositories directly, so the order is always right.
class SessionService {
  const new(
    this._auth,
    this._push,
    this._devices,
    this._prefs, {
    required this._pausePush,
    required this._restorePush,
  });

  final AuthRepository _auth;
  final PushRepository _push;
  final DeviceRepository _devices;
  final LocalPrefsRepository _prefs;

  /// Stops the app writing the device doc again while signing out.
  final void Function() _pausePush;

  /// Registers this device again when ending the session fails.
  final Future<void> Function() _restorePush;

  /// Removing the device doc needs the server; offline, sign-out doesn't
  /// wait for it. The token is deleted too (now, or by PushRegistration
  /// once back online), and the server drops the doc when FCM refuses it.
  static const _removeTimeout = Duration(seconds: 5);

  /// Signs out on this device and stops its push notifications.
  Future<void> signOut() => _endSession(_auth.signOut);

  /// Deletes the account (AUTH-10), handing each team in [newOwners] to the
  /// member the owner picked. The caller wraps this in withFreshSignIn,
  /// since the server needs a recent sign-in.
  Future<void> deleteAccount({Map<String, String> newOwners = const {}}) =>
      _endSession(() => _auth.deleteAccount(newOwners: newOwners));

  /// Ends every session for this account at once, then signs out here. The
  /// server removes the other devices' docs and stamps the profile, which
  /// signs them out ([sessionRevocationWatcher]).
  Future<void> signOutEverywhere() => _endSession(_auth.signOutEverywhere);

  Future<void> _endSession(Future<void> Function() end) async {
    _pausePush();
    await _stopPushHere();
    try {
      await end();
    } on Object {
      // Still signed in (a fresh sign-in is needed, or it failed), so this
      // device keeps getting pushes.
      unawaited(_restorePush());
      rethrow;
    }
  }

  /// NOTIF-10: the device doc goes first, while still signed in (rules
  /// only let its owner delete it), then the local token.
  Future<void> _stopPushHere() async {
    try {
      await _devices.remove(_prefs.installId).timeout(_removeTimeout);
    } on Object catch (e) {
      // No doc (push was never allowed here), offline, or refused.
      Log.warn('Could not remove this device', e);
    }
    // The registration record stays until the token is really gone, so
    // PushRegistration keeps trying while signed out (NOTIF-10).
    if (await _push.deleteToken()) await _prefs.setDeviceRegistration(null);
  }
}

@Riverpod(keepAlive: true)
SessionService sessionService(Ref ref) => SessionService(
  ref.watch(authRepositoryProvider),
  ref.watch(pushRepositoryProvider),
  ref.watch(deviceRepositoryProvider),
  ref.watch(localPrefsRepositoryProvider),
  pausePush: () => ref.read(pushRegistrationProvider.notifier).pause(),
  restorePush: () => ref.read(pushRegistrationProvider.notifier).restore(),
);

/// Whether a session that signed in at [authTime] was ended by "Sign out of
/// all devices" at [revokedAt] (AUTH-9). Compared in whole seconds, like
/// Firebase's own token check, since auth_time has no milliseconds.
bool sessionRevoked(DateTime? authTime, DateTime? revokedAt) {
  if (authTime == null || revokedAt == null) return false;
  int seconds(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;
  return seconds(authTime) < seconds(revokedAt);
}

/// AUTH-9: "Sign out of all devices" ends every session at once. Revoking
/// refresh tokens alone would leave other devices signed in until their
/// ID token expires (up to an hour), so the server also stamps
/// `users.sessionsRevokedAt`; this device signs out as soon as it sees a
/// stamp newer than its own sign-in. The app watches it while running.
@Riverpod(keepAlive: true)
void sessionRevocationWatcher(Ref ref) {
  ref.listen(myProfileProvider, (_, next) {
    final user = ref.read(authUserProvider).value;
    if (sessionRevoked(user?.authTime, next.value?.sessionsRevokedAt)) {
      Log.debug('Signed out: every session was ended from another device');
      unawaited(ref.read(sessionServiceProvider).signOut());
    }
  }, fireImmediately: true);
}
