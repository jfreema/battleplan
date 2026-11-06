// My time zone (SET-7): times show in the zone the person picked, which
// stays put while they travel, or in the device's (Automatic).
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/services/time_zone_names.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
import 'package:battleplan/features/admin/presentation/audit_screen.dart'
    show auditRange;
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/chat_screen.dart'
    show dayLabel;
import 'package:battleplan/features/notifications/presentation/notification_labels.dart';
import 'package:battleplan/features/polls/presentation/poll_card.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/l10n/gen/app_localizations_en.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// A device in [zone] that lists [zones].
class _Zones implements TimeZones {
  const new(this.zone, this.zones);

  final String zone;
  final List<String> zones;

  @override
  Future<String> deviceTimeZone() async => zone;

  @override
  Future<List<String>> available() async => zones;
}

/// A device that travels: its zone changes when a test says so.
class _Traveling implements TimeZones {
  new(this.zone);

  String zone;

  @override
  Future<String> deviceTimeZone() async => zone;

  @override
  Future<List<String>> available() async => [zone];
}

void main() {
  // The device's zone is asked again on each return to the app.
  TestWidgetsFlutterBinding.ensureInitialized();
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const zones = _Zones('America/Chicago', [
    'America/Chicago',
    'America/New_York',
    'Asia/Tokyo',
  ]);

  group("the viewer's zone", () {
    Future<ProviderContainer> container(FakeUserRepository users) async {
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(user: coach),
          ),
          userRepositoryProvider.overrideWithValue(users),
          timeZonesProvider.overrideWithValue(zones),
        ],
      );
      addTearDown(c.dispose);
      c.listen(myProfileProvider, (_, _) {});
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return c;
    }

    test("is the device's on Automatic, and the picked one once set", () async {
      final users = FakeUserRepository();
      final c = await container(users);
      expect(await c.read(viewerTimeZoneProvider.future), 'America/Chicago');
      await users.setTimeZone('coach', 'Asia/Tokyo');
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(await c.read(viewerTimeZoneProvider.future), 'Asia/Tokyo');
      await users.setTimeZone('coach', null);
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(await c.read(viewerTimeZoneProvider.future), 'America/Chicago');
    });

    test("falls back to the device's for a zone it doesn't know", () async {
      final users = FakeUserRepository()..timeZone = 'Mars/Olympus_Mons';
      final c = await container(users);
      expect(await c.read(viewerTimeZoneProvider.future), 'America/Chicago');
    });

    test("is one with the device's offsets, not UTC, for a device zone the "
        "database doesn't know", () async {
      final c = ProviderContainer(
        overrides: [
          timeZonesProvider.overrideWithValue(
            const _Zones('Etc/Unknown', ['Etc/Unknown']),
          ),
        ],
      );
      addTearDown(c.dispose);
      final zone = await c.read(deviceTimeZoneProvider.future);
      expect(ZonedTime.isKnown(zone), isTrue);
      final now = DateTime.now();
      final later = now.add(const Duration(days: 182));
      expect(ZonedTime.offsetAt(zone, now), now.timeZoneOffset);
      expect(ZonedTime.offsetAt(zone, later), later.timeZoneOffset);
    });

    test('stands in for an unknown device zone with one that has its offset '
        'every day of the year', () {
      final now = DateTime.utc(2026, 11, 2);
      Duration Function(DateTime) like(String zone) =>
          (t) => ZonedTime.offsetAt(zone, t);
      expect(
        zoneLikeDevice(now, offsetAt: like('America/Chicago')),
        'America/Chicago',
      );
      // Cairo and Athens share an offset most of the year, but not their
      // daylight saving dates.
      expect(
        zoneLikeDevice(now, offsetAt: like('Africa/Cairo')),
        'Africa/Cairo',
      );
    });

    testWidgets('on Automatic, follows a trip taken while the app was in the '
        'background', (tester) async {
      final device = _Traveling('America/Chicago');
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        overrides: [timeZonesProvider.overrideWithValue(device)],
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/profile');
      await tester.pumpAndSettle();
      expect(find.text('Automatic: Central Time (Chicago)'), findsOneWidget);

      device.zone = 'America/New_York';
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pumpAndSettle();
      expect(find.text('Automatic: Eastern Time (New York)'), findsOneWidget);
      // Every time on screen follows: they read the viewer's zone.
      expect(
        ViewerZone.read(tester.element(find.byType(Scaffold).first)),
        'America/New_York',
      );
    });

    testWidgets('on Automatic, follows a trip taken with the app on screen', (
      tester,
    ) async {
      final device = _Traveling('America/Chicago');
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        overrides: [timeZonesProvider.overrideWithValue(device)],
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/profile');
      await tester.pumpAndSettle();

      device.zone = 'America/Denver';
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('Automatic: Mountain Time (Denver)'), findsOneWidget);
      expect(
        ViewerZone.read(tester.element(find.byType(Scaffold).first)),
        'America/Denver',
      );
    });
  });

  test("the zone list leaves out zones the app can't apply", () {
    // Europe/Atlantis looks like a zone, but the database has no such one.
    expect(
      TimeZoneNames.ordered([
        'Europe/Atlantis',
        'Europe/Amsterdam',
        'UTC',
      ], at: DateTime.utc(2026, 7)),
      ['UTC', 'Europe/Amsterdam'],
    );
  });

  test('the zone list keeps places a list has only under old names', () {
    // Browsers list Asia/Calcutta and Europe/Kiev, not their current names.
    expect(
      TimeZoneNames.ordered([
        'Asia/Calcutta',
        'Europe/Kiev',
        'Europe/Kyiv',
      ], at: DateTime.utc(2026, 7)),
      ['Europe/Kyiv', 'Asia/Kolkata'],
    );
  });

  group("labels in the picked zone, whatever the device's", () {
    setUpAll(() => initializeDateFormatting('en'));
    final l10n = AppLocalizationsEn();
    // 6:00 PM UTC on Wed, Jul 1: 1:00 PM in Chicago, 3:00 AM Thursday in
    // Tokyo.
    final at = DateTime.utc(2026, 7, 1, 18);
    final now = DateTime.utc(2026, 7, 1, 12);

    test("a poll's close time", () {
      // Formats put a narrow space before AM and PM.
      String label(String zone) =>
          closesLabel(l10n, at, now, zone: zone).replaceAll('\u202f', ' ');
      expect(label('America/Chicago'), '1:00 PM');
      expect(label('Asia/Tokyo'), 'Thu 3:00 AM');
    });

    test("a list row's date, a week on", () {
      final later = at.add(const Duration(days: 9));
      expect(relativeTime(l10n, at, later, zone: 'America/Chicago'), 'Jul 1');
      expect(relativeTime(l10n, at, later, zone: 'Asia/Tokyo'), 'Jul 2');
    });

    test("wallClockIn uses the device's zone until one is known", () {
      expect(wallClockIn(null, at), at.toLocal());
      expect(wallClockIn('Asia/Tokyo', at).hour, 3);
    });

    test('a day that is 23 hours long still counts as one', () {
      // Clocks go forward in Chicago on Sun, Mar 8, 2026. Day math with the
      // device's midnights fails this only on a machine whose zone has
      // daylight saving, such as one in Chicago.
      const chicago = 'America/Chicago';
      final sunday = ZonedTime.instantOf(
        chicago,
        DateTime.utc(2026, 3, 8),
        720,
      );
      final monday = ZonedTime.instantOf(
        chicago,
        DateTime.utc(2026, 3, 9),
        1020,
      );
      expect(
        closesLabel(
          l10n,
          monday,
          sunday,
          zone: chicago,
        ).replaceAll('\u202f', ' '),
        'Mon 5:00 PM',
      );
      expect(
        dayLabel(l10n, DateTime(2026, 3, 8, 9), DateTime(2026, 3, 9, 10)),
        'Yesterday',
      );
    });

    test("the audit log's dates are whole days in the viewer's zone", () {
      final days = DateTimeRange(
        start: DateTime(2026, 10, 6),
        end: DateTime(2026, 10, 10),
      );
      final berlin = auditRange(days, 'Europe/Berlin');
      expect(berlin.from, DateTime.utc(2026, 10, 5, 22));
      expect(berlin.until, DateTime.utc(2026, 10, 10, 22));
      // Clocks go back in Chicago on Nov 1, so that day is 25 hours long.
      final fallBack = auditRange(
        DateTimeRange(start: DateTime(2026, 10, 31), end: DateTime(2026, 11)),
        'America/Chicago',
      );
      expect(fallBack.from, DateTime.utc(2026, 10, 31, 5));
      expect(fallBack.until, DateTime.utc(2026, 11, 2, 6));
      // While the zone loads, this device's days.
      final device = auditRange(days, null);
      expect(device.from, DateTime(2026, 10, 6));
      expect(device.until, DateTime(2026, 10, 11));
    });
  });

  testWidgets('Profile → Time zone starts on Automatic, saves a picked zone, '
      'and goes back to Automatic', (tester) async {
    final users = FakeUserRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      users: users,
      overrides: [timeZonesProvider.overrideWithValue(zones)],
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/profile');
    await tester.pumpAndSettle();
    expect(find.text('Automatic: Central Time (Chicago)'), findsOneWidget);

    await tester.tap(find.text('Time zone'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Times show in this zone wherever you are. Automatic follows this '
        'device as you travel.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Eastern Time (New York)'));
    await tester.pumpAndSettle();
    expect(users.timeZone, 'America/New_York');
    expect(find.text('Eastern Time (New York)'), findsOneWidget);

    await tester.tap(find.text('Time zone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic: Central Time (Chicago)'));
    await tester.pumpAndSettle();
    expect(users.timeZone, isNull);
    expect(find.text('Automatic: Central Time (Chicago)'), findsOneWidget);
  });

  testWidgets("a chat message's time shows in the picked zone, not the "
      "device's", (tester) async {
    // 6:00 PM UTC: 1:00 PM on a Chicago device, 3:00 AM in Tokyo.
    final message = Message(
      id: 'm1',
      groupId: const GroupId('a'),
      authorId: 'sam',
      authorName: 'Sam Rivera',
      type: MessageType.text,
      text: 'Hello from the road',
      createdAt: DateTime.utc(2026, 7, 1, 18),
    );
    Future<void> open(String? picked) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        users: FakeUserRepository()..timeZone = picked,
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [
          testMembership('a', 'coach'),
          testMembership('a', 'sam', name: 'Sam Rivera'),
        ],
        messageRepo: FakeMessageRepository([message]),
        overrides: [timeZonesProvider.overrideWithValue(zones)],
      );
      await tester.pumpAndSettle();
    }

    // Formats put a narrow space before AM and PM; the time is rich text.
    bool shows(String time) => find
        .textContaining(RegExp(time.replaceAll(' ', r'\s')), findRichText: true)
        .evaluate()
        .isNotEmpty;

    // The day line gains the year once the message is from an earlier one.
    await open(null);
    expect(shows('1:00 PM'), isTrue);
    expect(find.textContaining('Wed, Jul 1'), findsOneWidget);
    // In Tokyo it's the next morning: the time and the day both move.
    await open('Asia/Tokyo');
    expect(shows('3:00 AM'), isTrue);
    expect(shows('1:00 PM'), isFalse);
    expect(find.textContaining('Thu, Jul 2'), findsOneWidget);
  });

  testWidgets("the event page's Today and Tomorrow count days in the picked "
      'zone', (tester) async {
    // A zone whose date isn't the device's right now, so counting from the
    // device's date would be off by a day. One of these always is: they're
    // UTC+14 and UTC-11.
    final now = DateTime.now();
    final zone = [
      'Pacific/Kiritimati',
      'Pacific/Pago_Pago',
    ].firstWhere((z) => ZonedTime.wallClock(z, now).day != now.day);
    final there = ZonedTime.wallClock(zone, now);
    final start = ZonedTime.instantOf(
      zone,
      DateTime.utc(there.year, there.month, there.day + 1),
      12 * 60,
    );
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      users: FakeUserRepository()..timeZone = zone,
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach')],
      eventRepo: FakeEventRepository([
        Event(
          id: const EventId('e1'),
          groupId: const GroupId('a'),
          type: EventType.practice,
          title: 'Practice',
          startAt: start,
          endAt: start.add(const Duration(minutes: 90)),
          timeZone: 'America/Chicago',
          createdBy: 'coach',
        ),
      ]),
      overrides: [timeZonesProvider.overrideWithValue(zones)],
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .go('/g/a/schedule/e/e1');
    await tester.pumpAndSettle();
    expect(find.text('Tomorrow'), findsOneWidget);
  });
}
