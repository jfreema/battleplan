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
  /// wait for it. The server drops the doc once its token stops working.
  static const _removeTimeout = Duration(seconds: 5);

  /// Signs out on this device and stops its push notifications.
  Future<void> signOut() => _endSession(_auth.signOut);

  /// Deletes the account (AUTH-10). The caller wraps this in
  /// withFreshSignIn, since the server needs a recent sign-in.
  Future<void> deleteAccount() => _endSession(_auth.deleteAccount);

  /// Ends every session for this account (other devices within an hour),
  /// then signs out here. The server removes the other devices' docs.
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
    await _prefs.setDeviceRegistration(null);
    await _push.deleteToken();
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
