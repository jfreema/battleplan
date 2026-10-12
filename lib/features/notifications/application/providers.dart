import 'dart:async';

import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/notifications/domain/device_repository.dart';
import 'package:battleplan/features/notifications/domain/notification_repository.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
PushRepository pushRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
DeviceRepository deviceRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// This build's version, stored on the `devices` doc. Overridden in
/// app/providers.dart, since features can't import app/ (ARCH §5.2).
@Riverpod(keepAlive: true)
String deviceAppVersion(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// Whether notifications are allowed on this device. Screens invalidate it
/// on resume, since the person can change it in system settings.
@riverpod
Future<PushPermission> pushPermission(Ref ref) =>
    ref.watch(pushRepositoryProvider).permissionStatus();

/// Unread notification-center items for the bell, up to 100 (NOTIF-11).
/// A one-time count, not a listener (ARCH §10.2): refreshed on resume, on
/// every foreground push, and after marking read.
@riverpod
Future<int> unreadNotificationCount(Ref ref) async {
  final uid = ref.watch(authUserProvider.select((a) => a.value?.uid));
  if (uid == null) return 0;
  return await ref
      .watch(notificationRepositoryProvider)
      .countUnread(UserId(uid));
}

/// The in-app banner for a push that arrives while the app is open
/// (NOTIF-7): the message, or null when nothing is showing.
@Riverpod(keepAlive: true)
class PushBanner extends _$PushBanner {
  /// How long a banner stays before it hides itself.
  static const showFor = Duration(seconds: 6);

  Timer? _hide;

  @override
  PushMessage? build() {
    ref.onDispose(() => _hide?.cancel());
    return null;
  }

  void show(PushMessage message) {
    _hide?.cancel();
    _hide = Timer(showFor, dismiss);
    state = message;
  }

  void dismiss() {
    _hide?.cancel();
    _hide = null;
    state = null;
  }
}
