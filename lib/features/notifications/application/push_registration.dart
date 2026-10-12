import 'dart:async';

import 'package:battleplan/core/logging.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_registration.g.dart';

/// Keeps this install's `devices` doc current while someone is signed in
/// and notifications are allowed (NOTIF-10, ARCH §6.5): written after
/// sign-in, again whenever FCM rotates the token, and at least daily on
/// start or return to the app so the 60-day device prune never removes a
/// device in use. Started from app.dart; SessionService removes the doc at
/// sign-out.
@Riverpod(keepAlive: true)
class PushRegistration extends _$PushRegistration {
  /// The doc is rewritten for the same person and token only if the last
  /// write is older.
  static const refreshAfter = Duration(days: 1);

  /// Set while SessionService signs out. A token FCM issues once the old
  /// one is deleted, or a start-up write still on its way, must not put
  /// back the doc sign-out just removed.
  bool _paused = false;

  @override
  void build() {
    // Runs again only when the signed-in person changes, which ends any
    // sign-out that paused it.
    _paused = false;
    final auth = ref.watch(
      authUserProvider.select(
        (a) => (settled: a.hasValue || a.hasError, uid: a.value?.uid),
      ),
    );
    final uid = auth.uid;
    if (uid == null) {
      // Signed out without SessionService finishing the job: the server
      // ended the session (password change, Sign out everywhere elsewhere),
      // or sign-out ran offline. This install's token still reaches the
      // account, so delete it now and on each return to the app until it
      // works (NOTIF-10). FCM then refuses it and the server drops the doc.
      if (auth.settled) {
        final lifecycle = AppLifecycleListener(
          onResume: () => unawaited(_forgetStaleToken()),
        );
        ref.onDispose(lifecycle.dispose);
        unawaited(_forgetStaleToken());
      }
      return;
    }
    // iOS reports the token at every start; the freshness check in _write
    // keeps that from costing a write each time.
    final sub = ref
        .watch(pushRepositoryProvider)
        .tokenRefreshes()
        .listen((token) => unawaited(_write(uid, token, force: false)));
    // Notifications turned on in the system settings while the app was in
    // the background (the help Settings shows, NOTIF-1) take effect on
    // return, not at the next cold start.
    final lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_registerIfAllowed(uid)),
    );
    ref.onDispose(() {
      unawaited(sub.cancel());
      lifecycle.dispose();
    });
    unawaited(_registerIfAllowed(uid));
  }

  /// Deletes the token of a registration left over from a session that
  /// ended without SessionService, and forgets the registration once it's
  /// gone, so the next sign-in always writes a fresh device doc.
  Future<void> _forgetStaleToken() async {
    final prefs = ref.read(localPrefsRepositoryProvider);
    if (prefs.deviceRegistration == null) return;
    if (await ref.read(pushRepositoryProvider).deleteToken()) {
      await prefs.setDeviceRegistration(null);
    }
  }

  /// Stops writing the device doc until sign-out finishes or [restore]
  /// runs. SessionService calls it before removing the doc.
  void pause() => _paused = true;

  /// Shows the system prompt, then registers this device if allowed (the
  /// pre-prompt's Allow and Settings' Turn on, NOTIF-1). Returns the result.
  Future<PushPermission> requestAndRegister() async {
    final status = await ref.read(pushRepositoryProvider).requestPermission();
    if (!ref.mounted) return status;
    final uid = ref.read(authUserProvider).value?.uid;
    if (status == PushPermission.authorized && uid != null) {
      await _registerIfAllowed(uid, force: true);
    }
    return status;
  }

  /// Writes the device doc again now, if push is allowed: after a sign-out
  /// or account deletion that didn't go through, which removed it first.
  Future<void> restore() async {
    _paused = false;
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid != null) await _registerIfAllowed(uid, force: true);
  }

  Future<void> _registerIfAllowed(String uid, {bool force = false}) async {
    final push = ref.read(pushRepositoryProvider);
    if (await push.permissionStatus() != PushPermission.authorized) return;
    final token = await push.currentToken();
    if (token == null || !ref.mounted) return;
    await _write(uid, token, force: force);
  }

  Future<void> _write(String uid, String token, {required bool force}) async {
    // They may have signed out, or begun to, while the token was on its way.
    if (!ref.mounted ||
        _paused ||
        ref.read(authUserProvider).value?.uid != uid) {
      return;
    }
    final prefs = ref.read(localPrefsRepositoryProvider);
    final last = prefs.deviceRegistration;
    final now = DateTime.now();
    final fresh =
        last != null &&
        last.uid == uid &&
        last.token == token &&
        now.difference(last.at) < refreshAfter;
    if (fresh && !force) return;
    try {
      await ref
          .read(deviceRepositoryProvider)
          .register(
            prefs.installId,
            uid: uid,
            token: token,
            platform: ref.read(pushRepositoryProvider).platform,
            appVersion: ref.read(deviceAppVersionProvider),
          );
      // Sign-out began meanwhile: it removes the doc after this write, and
      // its cleared record must stay cleared.
      if (_paused) return;
      await prefs.setDeviceRegistration((uid: uid, token: token, at: now));
    } on Object catch (e) {
      // Tried again on the next start, return to the app, or token change.
      Log.warn('Could not register this device for push', e);
    }
  }
}
