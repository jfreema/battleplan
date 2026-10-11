import 'package:battleplan/core/logging.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase Cloud Messaging behind [PushRepository]: APNs on iOS, FCM on
/// Android, and Web Push in browsers (through web/firebase-messaging-sw.js).
class FcmPushRepository implements PushRepository {
  new(this._messaging, {this.vapidKey});

  final FirebaseMessaging _messaging;

  /// The web push key. Null uses Firebase's default key, which is enough for
  /// testing (M0 spike 3); a project key replaces it before launch.
  final String? vapidKey;

  @override
  Future<String?> requestPermissionAndGetToken() async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      return await _messaging.getToken(vapidKey: vapidKey);
    } on Object catch (e) {
      // Unsupported browser, no APNs on the simulator, and so on.
      Log.warn('Push registration failed', e);
      return null;
    }
  }

  @override
  Future<void> unregister() async {
    try {
      await _messaging.deleteToken();
    } on Object catch (e) {
      Log.warn('Could not delete the push token', e);
    }
  }

  @override
  Stream<PushMessage> foregroundMessages() => FirebaseMessaging.onMessage.map(
    (m) => PushMessage(
      title: m.notification?.title,
      body: m.notification?.body,
      data: m.data,
    ),
  );
}

/// Used with the emulators, which have no push service.
class UnavailablePushRepository implements PushRepository {
  const new();

  @override
  Future<String?> requestPermissionAndGetToken() async => null;

  @override
  Future<void> unregister() async {}

  @override
  Stream<PushMessage> foregroundMessages() => const Stream.empty();
}
