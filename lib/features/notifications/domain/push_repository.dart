/// A push notification as the app sees it (ARCH §6.5).
class PushMessage {
  const new({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// Includes `route` and `groupId` once the notify pipeline sends them.
  final Map<String, Object?> data;
}

/// Push registration on this device: permission, the FCM token, and
/// messages that arrive while the app is open. Device docs (`devices`) and
/// the server pipeline arrive in M4.
abstract interface class PushRepository {
  /// Asks for permission if needed, then returns this device's token, or
  /// null if the person declined or push isn't available here.
  Future<String?> requestPermissionAndGetToken();

  /// Messages received while the app is in the foreground.
  Stream<PushMessage> foregroundMessages();
}
