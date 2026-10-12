import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging behind [PushRepository]: APNs on iOS, FCM on
/// Android, and Web Push in browsers (through web/firebase-messaging-sw.js).
class FcmPushRepository implements PushRepository {
  new(this._messaging, {this.vapidKey});

  final FirebaseMessaging _messaging;

  /// The web push key. Null uses Firebase's default key, which is enough for
  /// testing (M0 spike 3); a project key replaces it before launch.
  final String? vapidKey;

  @override
  DevicePlatform get platform => currentDevicePlatform();

  @override
  Future<PushPermission> permissionStatus() async {
    try {
      return _permissionOf(await _messaging.getNotificationSettings());
    } on Object catch (e) {
      // Browsers without web push (iOS Safari outside Add to Home Screen).
      Log.warn('Push permission unavailable', e);
      return PushPermission.unavailable;
    }
  }

  @override
  Future<PushPermission> requestPermission() async {
    try {
      return _permissionOf(await _messaging.requestPermission());
    } on Object catch (e) {
      Log.warn('Push permission request failed', e);
      return PushPermission.unavailable;
    }
  }

  @override
  Future<String?> currentToken() async {
    // On web, getToken shows the browser's prompt when permission is
    // undecided, so never ask for a token before permission is granted.
    if (await permissionStatus() != PushPermission.authorized) return null;
    try {
      return await _messaging.getToken(
        vapidKey: vapidKey,
        serviceWorkerScriptPath: pushWorkerPath(isWeb: kIsWeb),
      );
    } on Object catch (e) {
      // No APNs on the simulator, no network, and so on.
      Log.warn('Could not get a push token', e);
      return null;
    }
  }

  @override
  Stream<String> tokenRefreshes() => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> foregroundMessages() =>
      FirebaseMessaging.onMessage.map(_message);

  @override
  Stream<PushMessage> openedMessages() =>
      FirebaseMessaging.onMessageOpenedApp.map(_message);

  @override
  Future<PushMessage?> initialMessage() async {
    try {
      final m = await _messaging.getInitialMessage();
      return m == null ? null : _message(m);
    } on Object catch (e) {
      Log.warn('Could not read the launch notification', e);
      return null;
    }
  }

  @override
  Future<bool> deleteToken() async {
    try {
      // On web, register our push worker first: without a registration the
      // SDK looks for one at the domain root, where the website is (D40).
      if (kIsWeb) await currentToken();
      await _messaging.deleteToken();
      return true;
    } on Object catch (e) {
      Log.warn('Could not delete the push token', e);
      return false;
    }
  }
}

/// Used with the emulators, which have no push service.
class UnavailablePushRepository implements PushRepository {
  const new();

  @override
  DevicePlatform get platform => currentDevicePlatform();

  @override
  Future<PushPermission> permissionStatus() async => PushPermission.unavailable;

  @override
  Future<PushPermission> requestPermission() async =>
      PushPermission.unavailable;

  @override
  Future<String?> currentToken() async => null;

  @override
  Stream<String> tokenRefreshes() => const Stream.empty();

  @override
  Stream<PushMessage> foregroundMessages() => const Stream.empty();

  @override
  Stream<PushMessage> openedMessages() => const Stream.empty();

  @override
  Future<PushMessage?> initialMessage() async => null;

  @override
  Future<bool> deleteToken() async => true;
}

/// The web push worker, relative to the page's base href. Under `/app/`
/// (D40) the browser registers `/app/firebase-messaging-sw.js` with the
/// `/app/` scope; Firebase's default is `/firebase-messaging-sw.js`, which
/// the web app doesn't serve. Null on phones.
@visibleForTesting
String? pushWorkerPath({required bool isWeb}) =>
    isWeb ? 'firebase-messaging-sw.js' : null;

/// Platform checks live in implementations (ARCH §5.2 rule 8).
DevicePlatform currentDevicePlatform() => kIsWeb
    ? DevicePlatform.web
    : switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS => DevicePlatform.ios,
        _ => DevicePlatform.android,
      };

PushPermission _permissionOf(NotificationSettings s) =>
    switch (s.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => PushPermission.authorized,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently => PushPermission.denied,
      AuthorizationStatus.notDetermined => PushPermission.notDetermined,
    };

PushMessage _message(RemoteMessage m) => PushMessage(
  title: m.notification?.title,
  body: m.notification?.body,
  data: m.data,
);
