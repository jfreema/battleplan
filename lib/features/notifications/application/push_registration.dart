import 'dart:async';

import 'package:battleplan/core/logging.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_registration.g.dart';

/// Keeps this install's `devices` doc current while someone is signed in
/// and notifications are allowed (NOTIF-10, ARCH §6.5): written after
/// sign-in, again whenever FCM rotates the token, and at least daily on
/// start so the 60-day device prune never removes a device in use. Started
/// from app.dart; SessionService removes the doc at sign-out.
@Riverpod(keepAlive: true)
class PushRegistration extends _$PushRegistration {
  /// On start, the doc is rewritten only if the last write is older.
  static const refreshAfter = Duration(days: 1);

  @override
  void build() {
    final uid = ref.watch(authUserProvider.select((a) => a.value?.uid));
    if (uid == null) return;
    final sub = ref
        .watch(pushRepositoryProvider)
        .tokenRefreshes()
        .listen((token) => unawaited(_write(uid, token, force: true)));
    ref.onDispose(() => unawaited(sub.cancel()));
    unawaited(_registerIfAllowed(uid));
  }

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
    // They may have signed out while the token was on its way.
    if (!ref.mounted || ref.read(authUserProvider).value?.uid != uid) return;
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
      await prefs.setDeviceRegistration((uid: uid, token: token, at: now));
    } on Object catch (e) {
      // Tried again on the next start or token change.
      Log.warn('Could not register this device for push', e);
    }
  }
}
