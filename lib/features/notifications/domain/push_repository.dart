import 'package:battleplan/core/constants.g.dart';

/// A push notification as the app sees it (ARCH §6.5).
class PushMessage {
  const new({this.title, this.body, this.data = const {}});

  /// The team name (NOTIF-5).
  final String? title;
  final String? body;

  /// `{route, groupId, kind, nkey}`, all strings, from the notify pipeline.
  final Map<String, Object?> data;

  /// Where a tap goes, like `/g/abc/chat/m/xyz` (NOTIF-6).
  String? get route => _string('route');

  String? get groupId => _string('groupId');

  NotifyKind? get kind => NotifyKind.tryParse(_string('kind'));

  /// The send's dedupe key. This person's notification-center item for it
  /// is `notifications/{nkey}_{uid}`, so one multicast serves everyone.
  String? get nkey => _string('nkey');

  String? _string(String key) => switch (data[key]) {
    final String s when s.isNotEmpty => s,
    _ => null,
  };
}

/// Whether this device may show notifications.
enum PushPermission {
  /// Never asked. Asking is the pre-prompt's job (NOTIF-1).
  notDetermined,

  /// Allowed (including iOS's quiet "provisional" permission).
  authorized,

  /// Declined. iOS never asks again; Settings explains how to turn it on.
  denied,

  /// No push here: the emulators, or a browser without web push (on
  /// iPhone and iPad, Safari outside Add to Home Screen, NOTIF-9).
  unavailable,
}

/// Push on this device: permission, the FCM token, and messages that arrive
/// or are tapped. The `devices` doc is written by the registration
/// controller through DeviceRepository.
abstract interface class PushRepository {
  /// This device's platform, as stored on its `devices` doc.
  DevicePlatform get platform;

  /// Whether notifications are allowed, without asking.
  Future<PushPermission> permissionStatus();

  /// Shows the system permission prompt if it can, and returns the result.
  Future<PushPermission> requestPermission();

  /// This device's FCM token, or null when push isn't allowed or available.
  /// Only asks for a token once permission is granted, because on web
  /// getting a token itself shows the browser's prompt.
  Future<String?> currentToken();

  /// New tokens when FCM rotates this device's token.
  Stream<String> tokenRefreshes();

  /// Messages received while the app is in the foreground (NOTIF-7).
  Stream<PushMessage> foregroundMessages();

  /// Notifications tapped while the app was in the background (NOTIF-6).
  Stream<PushMessage> openedMessages();

  /// The notification whose tap launched the app, if any (NOTIF-6).
  Future<PushMessage?> initialMessage();

  /// Forgets this device's token, so it stops getting pushes (sign-out,
  /// NOTIF-10).
  Future<void> deleteToken();
}
