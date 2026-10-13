import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/data/firestore_user_repository.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/composer.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/notifications/domain/notification_item.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const installId = 'test-install-0000000000000';

  final teams = {
    'a': testGroup('a', 'Thunder', lastMessageAt: DateTime(2026, 10)),
    'b': testGroup('b', 'Lightning', lastMessageAt: DateTime(2026, 9)),
  };
  List<Membership> mine() => [
    testMembership('a', 'coach', role: MemberRole.owner),
    testMembership('b', 'coach'),
  ];

  Message msg(int i) => Message(
    id: 'm$i',
    groupId: const GroupId('a'),
    authorId: 'sam',
    authorName: 'Sam Rivera',
    type: MessageType.text,
    text: 'Message $i',
    createdAt: DateTime.now().subtract(Duration(minutes: 200 - i)),
  );

  NotificationItem item(
    String id, {
    NotifyKind kind = NotifyKind.reply,
    String title = 'Thunder',
    String body = 'Sam replied to you: Sounds good',
    String route = '/g/a/chat',
    String? actorId = 'sam',
    bool read = false,
    Duration age = const Duration(minutes: 5),
    DateTime? expiresAt,
  }) => NotificationItem(
    id: id,
    groupId: const GroupId('a'),
    kind: kind,
    title: title,
    body: body,
    route: route,
    actorId: actorId,
    read: read,
    createdAt: DateTime.now().subtract(age),
    expiresAt: expiresAt,
  );

  Finder bellBadge(String label) => find.descendant(
    of: find.byTooltip('Notifications'),
    matching: find.text(label),
  );

  /// The app goes to the background and comes back.
  Future<void> leaveAndReturn(WidgetTester tester) async {
    [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ].forEach(tester.binding.handleAppLifecycleStateChanged);
    await tester.pumpAndSettle();
  }

  Future<void> openNotificationSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
  }

  group('device registration (NOTIF-10)', () {
    testWidgets('a signed-in device with permission writes its doc', (
      tester,
    ) async {
      final devices = FakeDeviceRepository();
      final prefs = await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        devices: devices,
      );
      expect(devices.docs[installId]?.uid, 'coach');
      expect(devices.docs[installId]?.token, 'fcm-token-1');
      expect(devices.docs[installId]?.platform, DevicePlatform.android);
      expect(prefs.deviceRegistration?.uid, 'coach');
    });

    testWidgets('rewrites at most daily on start, and on a new token', (
      tester,
    ) async {
      final devices = FakeDeviceRepository();
      final push = FakePushRepository();
      final prefs = FakeLocalPrefs()
        ..deviceRegistration = (
          uid: 'coach',
          token: 'fcm-token-1',
          at: DateTime.now().subtract(const Duration(hours: 3)),
        );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        prefs: prefs,
        push: push,
        devices: devices,
      );
      expect(devices.writes, 0);
      // iOS reports the same token at every start.
      push.refreshes.add('fcm-token-1');
      await tester.pumpAndSettle();
      expect(devices.writes, 0);
      push.refreshes.add('fcm-token-2');
      await tester.pumpAndSettle();
      expect(devices.writes, 1);
      expect(devices.docs[installId]?.token, 'fcm-token-2');
    });

    testWidgets('a write older than a day is refreshed on start', (
      tester,
    ) async {
      final devices = FakeDeviceRepository();
      final prefs = FakeLocalPrefs()
        ..deviceRegistration = (
          uid: 'coach',
          token: 'fcm-token-1',
          at: DateTime.now().subtract(const Duration(days: 2)),
        );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        prefs: prefs,
        devices: devices,
      );
      expect(devices.writes, 1);
    });

    testWidgets('no permission, no device doc', (tester) async {
      final devices = FakeDeviceRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        push: FakePushRepository(permission: PushPermission.denied),
        devices: devices,
      );
      expect(devices.docs, isEmpty);
    });

    testWidgets(
      'allowing notifications in system settings registers on return',
      (tester) async {
        final devices = FakeDeviceRepository();
        final push = FakePushRepository(permission: PushPermission.denied);
        await pumpApp(
          tester,
          auth: FakeAuthRepository(user: coach),
          push: push,
          devices: devices,
        );
        expect(devices.docs, isEmpty);
        push.permission = PushPermission.authorized;
        await leaveAndReturn(tester);
        expect(devices.docs[installId]?.uid, 'coach');
      },
    );

    testWidgets('a token issued during sign-out does not register again', (
      tester,
    ) async {
      final devices = FakeDeviceRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        push: FakePushRepository(tokenAfterDelete: 'fcm-token-2'),
        devices: devices,
      );
      expect(devices.docs, isNotEmpty);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Sign out'), 100);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(devices.docs, isEmpty);
    });

    testWidgets('sign-out removes the device, then the token, then signs out', (
      tester,
    ) async {
      final log = <String>[];
      final prefs = await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach, log: log),
        push: FakePushRepository(log: log),
        devices: FakeDeviceRepository(log: log),
      );
      expect(log, ['device register $installId']);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Sign out'), 100);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(log, [
        'device register $installId',
        'device remove $installId',
        'push deleteToken',
        'auth signOut',
      ]);
      expect(prefs.deviceRegistration, isNull);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets(
      'a session ended elsewhere deletes the token; signing back in registers',
      (tester) async {
        final devices = FakeDeviceRepository();
        final push = FakePushRepository();
        final auth = FakeAuthRepository(user: coach);
        final prefs = await pumpApp(
          tester,
          auth: auth,
          push: push,
          devices: devices,
        );
        expect(prefs.deviceRegistration?.uid, 'coach');
        // A password change elsewhere: the session ends without SessionService.
        auth.endSessionElsewhere();
        await tester.pumpAndSettle();
        expect(push.tokensDeleted, 1);
        expect(prefs.deviceRegistration, isNull);
        // The server deleted the device meanwhile (Sign out everywhere).
        devices.docs.clear();
        await auth.signInWithEmail(
          email: FakeAuthRepository.knownEmail,
          password: FakeAuthRepository.password,
        );
        await tester.pumpAndSettle();
        expect(devices.docs[installId]?.uid, isNotNull);
      },
    );

    testWidgets('an offline sign-out keeps trying to delete the token', (
      tester,
    ) async {
      final push = FakePushRepository()..deleteFails = true;
      final prefs = await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        push: push,
        devices: FakeDeviceRepository(),
      );
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Sign out'), 100);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Continue with Google'), findsOneWidget);
      // Not gone yet, so it's still on record to retry.
      expect(prefs.deviceRegistration, isNotNull);
      push.deleteFails = false;
      await leaveAndReturn(tester);
      expect(push.tokensDeleted, 1);
      expect(prefs.deviceRegistration, isNull);
    });

    testWidgets('a cancelled account deletion keeps this device registered', (
      tester,
    ) async {
      final devices = FakeDeviceRepository();
      final auth = FakeAuthRepository(
        user: coach.copyWith(providerIds: ['password']),
      )..needsRecentLogin = true;
      await pumpApp(tester, auth: auth, devices: devices);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Delete account'), 100);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
      await tester.pumpAndSettle();
      // The password prompt for a fresh sign-in; cancelling it.
      expect(find.text("Confirm it's you"), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(auth.deleted, isFalse);
      expect(devices.docs[installId]?.uid, 'coach');
    });
  });

  group('asking permission (NOTIF-1)', () {
    testWidgets('the pre-prompt appears once, and Allow registers', (
      tester,
    ) async {
      final push = FakePushRepository(permission: PushPermission.notDetermined);
      final devices = FakeDeviceRepository();
      final prefs = await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        push: push,
        devices: devices,
      );
      expect(find.text('Turn on notifications?'), findsOneWidget);
      expect(
        find.text(
          'Get notified about messages, schedule changes, and reminders.',
        ),
        findsOneWidget,
      );
      expect(devices.docs, isEmpty);
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();
      expect(push.permissionRequests, 1);
      expect(devices.docs[installId]?.uid, 'coach');
      expect(prefs.pushPrePromptShown, isTrue);

      // Switching teams doesn't ask again.
      await tester.tap(find.text('Thunder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lightning').last);
      await tester.pumpAndSettle();
      expect(find.text('Turn on notifications?'), findsNothing);
    });

    testWidgets('Not now asks nothing, and it never comes back', (
      tester,
    ) async {
      final push = FakePushRepository(permission: PushPermission.notDetermined);
      final prefs = await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        push: push,
      );
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(push.permissionRequests, 0);
      expect(prefs.pushPrePromptShown, isTrue);

      // A later launch on this install.
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        push: push,
        prefs: prefs,
      );
      expect(find.text('Turn on notifications?'), findsNothing);
    });

    testWidgets('never before the first team', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        push: FakePushRepository(permission: PushPermission.notDetermined),
      );
      expect(find.text('Welcome to Battleplan'), findsOneWidget);
      expect(find.text('Turn on notifications?'), findsNothing);
    });

    testWidgets('iPhone browsers get the Add to Home Screen tip (NOTIF-9)', (
      tester,
    ) async {
      final push = FakePushRepository(permission: PushPermission.unavailable);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        push: push,
        browser: const FakeBrowserInfo(pushNeedsHomeScreen: true),
      );
      expect(find.text('Notifications on iPhone and iPad'), findsOneWidget);
      expect(find.textContaining('Add to Home Screen'), findsOneWidget);
      expect(find.text('Get the iPhone app'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(push.permissionRequests, 0);
      expect(find.text('Notifications on iPhone and iPad'), findsNothing);
    });

    testWidgets('the tip links to the App Store app (NOTIF-9)', (tester) async {
      final opener = FakeLinkOpener();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        push: FakePushRepository(permission: PushPermission.unavailable),
        browser: const FakeBrowserInfo(pushNeedsHomeScreen: true),
        linkOpener: opener,
      );
      await tester.tap(find.text('Get the iPhone app'));
      await tester.pumpAndSettle();
      expect(opener.opened.single.path, '/ios');
      expect(find.text('Notifications on iPhone and iPad'), findsNothing);
    });
  });

  group('settings (NOTIF-3, NOTIF-4, SET-3)', () {
    testWidgets('the global switches save to the profile', (tester) async {
      final users = FakeUserRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        users: users,
      );
      await openNotificationSettings(tester);
      expect(find.text('Notifications are on'), findsOneWidget);
      for (final label in [
        'Messages',
        'Replies',
        'Polls',
        'New events',
        'Event changes',
        'Reminders',
        'Documents',
      ]) {
        expect(find.widgetWithText(SwitchListTile, label), findsOneWidget);
      }
      // Mentions arrive in v1.1.
      expect(find.text('Mentions'), findsNothing);

      final polls = find.widgetWithText(SwitchListTile, 'Polls');
      expect(tester.widget<SwitchListTile>(polls).value, isTrue);
      await tester.tap(polls);
      await tester.pumpAndSettle();
      expect(users.notificationPrefs, {NotificationPref.polls: false});
      expect(tester.widget<SwitchListTile>(polls).value, isFalse);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Event changes'));
      await tester.pumpAndSettle();
      expect(users.notificationPrefs[NotificationPref.eventsChanged], isFalse);
    });

    testWidgets('lists my teams with their level, opening each team', (
      tester,
    ) async {
      final members = FakeMemberRepository([
        testMembership('a', 'coach', role: MemberRole.owner),
        testMembership(
          'b',
          'coach',
        ).copyWith(notificationLevel: NotificationLevel.important),
      ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberRepo: members,
      );
      await openNotificationSettings(tester);
      await tester.scrollUntilVisible(find.text('Important only'), 200);
      expect(find.text('All activity'), findsOneWidget);
      expect(find.text('Important only'), findsOneWidget);
      await tester.tap(find.text('Lightning'));
      await tester.pumpAndSettle();
      expect(find.text('Notifications for this team'), findsOneWidget);
    });

    testWidgets('blocked notifications explain how to turn them on', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        push: FakePushRepository(permission: PushPermission.denied),
      );
      await openNotificationSettings(tester);
      expect(find.text('Notifications are blocked'), findsOneWidget);
      expect(
        find.textContaining("open your device's Settings"),
        findsOneWidget,
      );
    });

    testWidgets('Turn on asks, then registers this device', (tester) async {
      final push = FakePushRepository(permission: PushPermission.notDetermined);
      final devices = FakeDeviceRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        push: push,
        devices: devices,
        prefs: FakeLocalPrefs()..pushPrePromptShown = true,
      );
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Notifications are off'), findsOneWidget);
      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();
      expect(push.permissionRequests, 1);
      expect(devices.docs[installId]?.uid, 'coach');
      expect(find.text('Notifications are on'), findsOneWidget);
    });

    testWidgets('a team: level, mute for a while, until unmuted, unmute', (
      tester,
    ) async {
      final members = FakeMemberRepository(mine());
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberRepo: members,
      );
      await tester.tap(find.byTooltip('Team menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notifications for this team'));
      await tester.pumpAndSettle();
      expect(find.text('Not muted'), findsOneWidget);

      await tester.tap(find.text('Important only'));
      await tester.pumpAndSettle();
      expect(members.calls, ['level a important']);
      expect(
        tester
            .widget<RadioGroup<NotificationLevel>>(
              find.byType(RadioGroup<NotificationLevel>),
            )
            .groupValue,
        NotificationLevel.important,
      );

      final before = DateTime.now();
      await tester.tap(find.text('For 1 hour'));
      await tester.pumpAndSettle();
      expect(members.calls.last, 'mute a on');
      final until = members.mutedUntil!;
      expect(until.difference(before).inMinutes, inInclusiveRange(59, 60));
      expect(find.textContaining('Muted until '), findsOneWidget);

      await tester.tap(find.text('Until I unmute'));
      await tester.pumpAndSettle();
      expect(members.mutedUntil!.millisecondsSinceEpoch, Limits.mutedForeverMs);
      expect(find.text('Muted until you unmute'), findsOneWidget);

      await tester.tap(find.text('Unmute'));
      await tester.pumpAndSettle();
      expect(members.calls.last, 'mute a off');
      expect(members.mutedUntil, isNull);
      expect(find.text('Not muted'), findsOneWidget);
    });
  });

  group('notification center and bell (NOTIF-11)', () {
    testWidgets('the bell counts unread items', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        notifications: FakeNotificationRepository([
          item('n1'),
          item('n2'),
          item('n3', read: true),
        ]),
      );
      expect(bellBadge('2'), findsOneWidget);
    });

    testWidgets('more than 99 shows 99+', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        notifications: FakeNotificationRepository([
          for (var i = 0; i < 120; i++) item('n$i'),
        ]),
      );
      expect(bellBadge('99+'), findsOneWidget);
    });

    testWidgets('lists items; a tap marks it read and opens it', (
      tester,
    ) async {
      final notifications = FakeNotificationRepository([
        item('r1_coach', route: '/g/a/chat/m/m1'),
        item(
          'add1_coach',
          kind: NotifyKind.addedToTeam,
          title: 'Lightning',
          body: 'Alex added you to Lightning',
          route: '/g/b/chat',
          read: true,
          age: const Duration(hours: 3),
        ),
        item(
          'expired_coach',
          body: 'Old news',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        item('blocked_coach', body: 'From someone blocked', actorId: 'troll'),
      ]);
      final safety = FakeSafetyRepository()
        ..blocks.add(const BlockedPerson(uid: UserId('troll'), name: 'Troll'));
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        messageRepo: FakeMessageRepository([msg(2), msg(1)]),
        notifications: notifications,
        safety: safety,
      );
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Sam replied to you: Sounds good'), findsOneWidget);
      expect(find.text('Alex added you to Lightning'), findsOneWidget);
      expect(find.text('5m'), findsOneWidget);
      expect(find.text('3h'), findsOneWidget);
      // Expired, and from someone I blocked: hidden.
      expect(find.text('Old news'), findsNothing);
      expect(find.text('From someone blocked'), findsNothing);

      // The hidden unread ones are marked read, so the bell matches.
      expect(
        notifications.markedRead,
        unorderedEquals(['expired_coach', 'blocked_coach']),
      );
      await tester.tap(find.text('Sam replied to you: Sounds good'));
      await tester.pumpAndSettle();
      expect(notifications.markedRead.last, 'r1_coach');
      // The chat, at the message.
      expect(find.text('Message 1'), findsOneWidget);
      expect(find.byType(Composer), findsOneWidget);
    });

    testWidgets('Mark all as read clears the rest', (tester) async {
      final notifications = FakeNotificationRepository([
        item('n1'),
        item('n2', body: 'Second'),
      ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        notifications: notifications,
      );
      expect(bellBadge('2'), findsOneWidget);
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();
      expect(notifications.markAllCalls, 1);
      expect(find.text('Mark all as read'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(bellBadge('2'), findsNothing);
    });

    testWidgets('opening an item in a team tab lowers the bell', (
      tester,
    ) async {
      final notifications = FakeNotificationRepository([
        // Opens Thunder's chat, a team tab.
        item('n1'),
        item('n2', body: 'Second'),
      ])..writeDelay = const Duration(seconds: 1);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        notifications: notifications,
      );
      expect(bellBadge('2'), findsOneWidget);
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      // The chat replaces the center before the write is done.
      await tester.tap(find.text('Sam replied to you: Sounds good'));
      await tester.pumpAndSettle();
      expect(find.byType(Composer), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(bellBadge('1'), findsOneWidget);
    });

    testWidgets('older items load past a hidden page, with Retry on failure', (
      tester,
    ) async {
      // A full first page from someone I blocked, then one I can see.
      final notifications = FakeNotificationRepository([
        for (var i = 0; i < 30; i++)
          item('t$i', body: 'Troll $i', actorId: 'troll'),
        item('old', body: 'Older reply', age: const Duration(days: 1)),
      ])..failLoadOlder = true;
      final safety = FakeSafetyRepository()
        ..blocks.add(const BlockedPerson(uid: UserId('troll'), name: 'Troll'));
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        notifications: notifications,
        safety: safety,
      );
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      // One failed try, not a loop, and not the empty state.
      expect(notifications.loadOlderCalls, 1);
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.text('Activity from all your teams will appear here.'),
        findsNothing,
      );

      notifications.failLoadOlder = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Older reply'), findsOneWidget);
      expect(find.textContaining('Troll'), findsNothing);
    });

    testWidgets('unread items the center hides stop counting on the bell', (
      tester,
    ) async {
      final notifications = FakeNotificationRepository([
        item('blocked_coach', body: 'From someone blocked', actorId: 'troll'),
      ]);
      final safety = FakeSafetyRepository()
        ..blocks.add(const BlockedPerson(uid: UserId('troll'), name: 'Troll'));
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        notifications: notifications,
        safety: safety,
      );
      expect(bellBadge('1'), findsOneWidget);
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('From someone blocked'), findsNothing);
      expect(notifications.markedRead, ['blocked_coach']);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(bellBadge('1'), findsNothing);
    });

    testWidgets('a short cached page first still lets older items load', (
      tester,
    ) async {
      final all = [
        for (var i = 0; i < 40; i++)
          item(
            'n${i}_coach',
            body: 'Item $i',
            age: Duration(minutes: i),
          ),
      ];
      final notifications = FakeNotificationRepository(all)
        ..cachedFirst = all.skip(30).toList();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        notifications: notifications,
      );
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Item 32'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      expect(notifications.loadOlderCalls, greaterThan(0));
      expect(find.text('Item 32'), findsOneWidget);
    });

    testWidgets('an empty center says what will appear', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
      );
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(
        find.text('Activity from all your teams will appear here.'),
        findsOneWidget,
      );
    });
  });

  group('pushes in the app (NOTIF-6, NOTIF-7)', () {
    PushMessage push(String groupId, String body, {String? route}) =>
        PushMessage(
          title: groupId == 'a' ? 'Thunder' : 'Lightning',
          body: body,
          data: {
            'groupId': groupId,
            'route': route ?? '/g/$groupId/chat/m/x',
            'kind': 'message',
            'nkey': 'x',
          },
        );

    testWidgets('a banner outside that team chat, nothing inside it', (
      tester,
    ) async {
      final pushes = FakePushRepository();
      final notifications = FakeNotificationRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        push: pushes,
        notifications: notifications,
      );
      // On Thunder's chat: a Thunder message shows no banner.
      pushes.foreground.add(push('a', 'Sam: in this chat'));
      await tester.pump();
      expect(find.text('Sam: in this chat'), findsNothing);

      // A Lightning reply shows one, and the bell count refreshes.
      notifications.items.add(item('r9_coach', route: '/g/b/chat'));
      pushes.foreground.add(
        push('b', 'Alex replied to you: Yes', route: '/g/b/chat'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alex replied to you: Yes'), findsOneWidget);
      expect(find.text('Lightning'), findsWidgets);
      expect(bellBadge('1'), findsOneWidget);

      // It hides itself after a few seconds.
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.text('Alex replied to you: Yes'), findsNothing);
    });

    testWidgets("the banner's Open switches to that team", (tester) async {
      final pushes = FakePushRepository();
      final prefs = await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        push: pushes,
      );
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      // Outside any chat, even this team's message gets a banner.
      pushes.foreground.add(
        push('b', 'Alex: Practice moved', route: '/g/b/chat'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(prefs.lastTeamRoute, '/g/b/chat');
      expect(find.text('Alex: Practice moved'), findsNothing);
    });

    testWidgets('tapping a push opens the chat at that message', (
      tester,
    ) async {
      final pushes = FakePushRepository();
      final notifications = FakeNotificationRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        push: pushes,
        notifications: notifications,
        messageRepo: FakeMessageRepository([
          for (var i = 120; i > 0; i--) msg(i),
        ]),
      );
      expect(find.text('Message 2'), findsNothing);
      pushes.opened.add(
        const PushMessage(
          title: 'Thunder',
          body: 'Sam replied to you: Message 2',
          data: {
            'groupId': 'a',
            'route': '/g/a/chat/m/m2',
            'kind': 'reply',
            'nkey': 'm2_reply',
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      final row = find.text('Message 2');
      expect(row, findsOneWidget);
      expect(tester.getCenter(row).dy, inInclusiveRange(0, 1600));
      // Replies have a center item, which the tap marks read.
      expect(notifications.markedRead, ['m2_reply_coach']);
    });

    testWidgets(
      "a push for another team opens that team's chat at the message",
      (tester) async {
        final pushes = FakePushRepository();
        Message bMsg(int i) => msg(i).copyWith(
          id: 'b$i',
          groupId: const GroupId('b'),
          text: 'Lightning $i',
        );
        final prefs = await pumpApp(
          tester,
          auth: FakeAuthRepository(user: coach),
          groups: teams,
          memberships: mine(),
          push: pushes,
          messageRepo: FakeMessageRepository([
            for (var i = 120; i > 0; i--) msg(i),
            for (var i = 120; i > 0; i--) bMsg(i),
          ]),
        );
        PushMessage open(String g, String m) => PushMessage(
          title: 'Team',
          body: 'Reply',
          data: {
            'groupId': g,
            'route': '/g/$g/chat/m/$m',
            'kind': 'reply',
            'nkey': '${m}_reply',
          },
        );
        pushes.opened.add(open('a', 'm2'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.text('Message 2'), findsOneWidget);
        // The last team is remembered as Thunder's chat tab.
        expect(prefs.lastTeamRoute, '/g/a/chat');
        pushes.opened.add(open('b', 'b3'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.text('Lightning 3'), findsOneWidget);
        expect(prefs.lastTeamRoute, '/g/b/chat');
      },
    );

    testWidgets('a push that launched the app opens its route', (tester) async {
      final notifications = FakeNotificationRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        notifications: notifications,
        push: FakePushRepository(
          launchMessage: const PushMessage(
            data: {
              'groupId': 'b',
              'route': '/g/b/chat',
              'kind': 'message',
              'nkey': 'm7',
            },
          ),
        ),
      );
      expect(find.text('Lightning'), findsOneWidget);
      // Plain messages have no center item to mark.
      expect(notifications.markedRead, isEmpty);
    });

    testWidgets('routes outside the app are ignored', (tester) async {
      final pushes = FakePushRepository();
      final prefs = await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: mine(),
        push: pushes,
      );
      pushes.opened.add(
        const PushMessage(data: {'route': 'https://example.com/g/a'}),
      );
      await tester.pumpAndSettle();
      expect(prefs.lastTeamRoute, '/g/a/chat');
      expect(find.text('Thunder'), findsOneWidget);
    });
  });

  group('helpers', () {
    test('only team and center routes are allowed', () {
      expect(isAllowedNotificationRoute('/g/a/chat/m/m1'), isTrue);
      expect(isAllowedNotificationRoute('/g/a/roster'), isTrue);
      expect(isAllowedNotificationRoute('/notifications'), isTrue);
      expect(isAllowedNotificationRoute('/settings'), isFalse);
      expect(isAllowedNotificationRoute('/g'), isFalse);
      expect(isAllowedNotificationRoute('//evil.example/g/a'), isFalse);
      expect(isAllowedNotificationRoute('https://evil.example/g/a'), isFalse);
      expect(isAllowedNotificationRoute(null), isFalse);
    });

    test("a team's chat path, and nothing else", () {
      expect(isTeamChatPath('/g/a/chat', 'a'), isTrue);
      expect(isTeamChatPath('/g/a/chat/m/x', 'a'), isTrue);
      expect(isTeamChatPath('/g/ab/chat', 'a'), isFalse);
      expect(isTeamChatPath('/g/a/schedule', 'a'), isFalse);
      expect(isTeamChatPath('/notifications', 'a'), isFalse);
    });

    test('center item IDs keep separators in the dedupe key', () {
      expect(notificationIdFor('m1_reply', const UserId('u1')), 'm1_reply_u1');
    });

    test("prefs: unset is on, and the old 'events' key covers both", () {
      expect(notificationPrefsFromFirestore(null), isEmpty);
      expect(notificationPrefsFromFirestore({'events': false, 'polls': true}), {
        NotificationPref.eventsNew: false,
        NotificationPref.eventsChanged: false,
        NotificationPref.polls: true,
      });
      expect(
        notificationPrefsFromFirestore({'events': false, 'eventsNew': true}),
        {
          NotificationPref.eventsNew: true,
          NotificationPref.eventsChanged: false,
        },
      );
      expect(notificationPrefsFromFirestore({'bogus': false}), isEmpty);
    });
  });
}
