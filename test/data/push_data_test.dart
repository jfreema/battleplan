// Data-layer tests (SPEC §8.1): push registration through FCM.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/notifications/data/fcm_push_repository.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationSettings _settings(AuthorizationStatus status) =>
    NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      authorizationStatus: status,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      sound: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
    );

class _FakeMessaging implements FirebaseMessaging {
  AuthorizationStatus status = AuthorizationStatus.notDetermined;
  AuthorizationStatus afterRequest = AuthorizationStatus.authorized;
  bool fail = false;
  RemoteMessage? initial;
  int deletes = 0;
  final refreshes = StreamController<String>.broadcast();

  void _maybeFail() {
    if (fail) throw Exception('unavailable');
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    _maybeFail();
    return _settings(status);
  }

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    _maybeFail();
    status = afterRequest;
    return _settings(status);
  }

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async {
    if (fail) throw Exception('no APNs');
    return 'token-1';
  }

  @override
  Stream<String> get onTokenRefresh => refreshes.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    _maybeFail();
    return initial;
  }

  @override
  Future<void> deleteToken() async {
    _maybeFail();
    deletes++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeMessaging messaging;
  late FcmPushRepository repo;

  setUp(() {
    messaging = _FakeMessaging();
    repo = FcmPushRepository(messaging);
  });

  test('asks for permission and only then gets a token (NOTIF-9)', () async {
    expect(repo.platform, DevicePlatform.android);
    expect(await repo.permissionStatus(), PushPermission.notDetermined);
    expect(await repo.currentToken(), isNull);
    expect(await repo.requestPermission(), PushPermission.authorized);
    expect(await repo.currentToken(), 'token-1');
    messaging.status = AuthorizationStatus.provisional;
    expect(await repo.permissionStatus(), PushPermission.authorized);
    messaging.status = AuthorizationStatus.denied;
    expect(await repo.permissionStatus(), PushPermission.denied);
    messaging.status = AuthorizationStatus.deniedPermanently;
    expect(await repo.permissionStatus(), PushPermission.denied);
  });

  test('reads the launch notification and token refreshes', () async {
    expect(await repo.initialMessage(), isNull);
    messaging.initial = const RemoteMessage(
      notification: RemoteNotification(title: 'Thunder', body: 'Alex: hi'),
      data: {'route': '/g/g1/chat'},
    );
    final m = (await repo.initialMessage())!;
    expect(m.title, 'Thunder');
    expect(m.body, 'Alex: hi');
    expect(m.data['route'], '/g/g1/chat');
    final next = repo.tokenRefreshes().first;
    messaging.refreshes.add('token-2');
    expect(await next, 'token-2');
  });

  test('deletes the token, and reports when it cannot (NOTIF-10)', () async {
    expect(await repo.deleteToken(), isTrue);
    expect(messaging.deletes, 1);
    messaging.fail = true;
    expect(await repo.deleteToken(), isFalse);
  });

  test('treats a failing push service as unavailable', () async {
    messaging
      ..status = AuthorizationStatus.authorized
      ..fail = true;
    expect(await repo.permissionStatus(), PushPermission.unavailable);
    expect(await repo.requestPermission(), PushPermission.unavailable);
    expect(await repo.currentToken(), isNull);
    expect(await repo.initialMessage(), isNull);
  });

  test('the emulator stand-in has no push service', () async {
    const none = UnavailablePushRepository();
    expect(none.platform, DevicePlatform.android);
    expect(await none.permissionStatus(), PushPermission.unavailable);
    expect(await none.requestPermission(), PushPermission.unavailable);
    expect(await none.currentToken(), isNull);
    expect(await none.tokenRefreshes().isEmpty, isTrue);
    expect(await none.foregroundMessages().isEmpty, isTrue);
    expect(await none.openedMessages().isEmpty, isTrue);
    expect(await none.initialMessage(), isNull);
    expect(await none.deleteToken(), isTrue);
    expect(pushWorkerPath(isWeb: true), 'firebase-messaging-sw.js');
    expect(pushWorkerPath(isWeb: false), isNull);
  });
}
