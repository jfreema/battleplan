// Basic groups beside teams (SPEC TEAM-14): picked when one is created,
// with every feature but players, guardians, coaches, and Plays, and
// everyone answering for themselves.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  final club = testGroup(
    'c',
    'Book club',
  ).copyWith(kind: GroupKind.group, sport: Sport.other);
  final memberships = [
    testMembership('c', 'coach', role: MemberRole.owner, name: 'Coach Lee'),
    testMembership('c', 'sam', name: 'Sam Rivera'),
  ];

  Future<void> go(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
  }

  String path(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Scaffold).first)).state.uri.path;

  testWidgets('Create a Group, below Create a Team, asks only for a name '
      'and a color', (tester) async {
    final groupRepo = FakeGroupRepository({});
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groupRepo,
    );
    expect(find.text('Join a Team or Group'), findsOneWidget);
    final team = tester.getTopLeft(find.text('Create a Team')).dy;
    expect(
      tester.getTopLeft(find.text('Create a Group')).dy,
      greaterThan(team),
    );
    await tester.tap(find.text('Create a Group'));
    await tester.pumpAndSettle();
    expect(find.text('Create a Group'), findsNWidgets(2));
    expect(find.text('GROUP NAME'), findsOneWidget);
    expect(find.text('Color'), findsOneWidget);
    // The rest waits for Group admin; the time zone is the device's.
    for (final field in ['SPORT', 'TIME ZONE', 'DESCRIPTION (OPTIONAL)']) {
      expect(find.text(field), findsNothing, reason: field);
    }
    expect(find.text('Add logo'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, 'Book club');
    await tester.pumpAndSettle();
    final create = find.widgetWithText(FilledButton, 'Create a Group');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(groupRepo.created, ['Book club']);
    expect(groupRepo.createdKinds, [GroupKind.group]);
    expect(groupRepo.groups.values.single.sport, Sport.other);
  });

  testWidgets('a group has Chat, Schedule, and Documents, but no Plays; its '
      'Plays and "Who are you here for" go to its chat', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'c': club},
      memberships: memberships,
      size: const Size(1024, 1366),
    );
    expect(find.text('Chat'), findsWidgets);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Plays'), findsNothing);
    for (final p in ['/g/c/plays', '/g/c/who', '/g/c/players/add']) {
      await go(tester, p);
      expect(path(tester), '/g/c/chat', reason: p);
    }
  });

  testWidgets('its people are admins and members: no players, coaches, or '
      'guardians', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'c': club},
      memberships: memberships,
      // A stray player can't show in a group.
      playerRepo: FakePlayerRepository(const [
        Player(id: PlayerId('p1'), groupId: GroupId('c'), displayName: 'Emma'),
      ]),
    );
    await tester.tap(find.byTooltip('Team info'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Group info'), findsOneWidget);
    expect(find.text('Group admin'), findsOneWidget);
    expect(find.text('Group · 3 members'), findsOneWidget);
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'People'), findsOneWidget);
    expect(find.text('Players'), findsNothing);
    expect(find.text('Emma'), findsNothing);
    expect(find.text('Coaches'), findsNothing);
    expect(find.text('Add players'), findsNothing);
    expect(find.text('Who are you here for?'), findsNothing);
    expect(find.text('Admins'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    // The owner isn't a coach here.
    await tester.tap(find.text('Coach Lee'));
    await tester.pumpAndSettle();
    expect(find.text('Coach'), findsNothing);
  });

  testWidgets("a group's admin settings have no sport", (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'c': club},
      memberships: memberships,
    );
    await go(tester, '/g/c/settings');
    expect(find.text('Book club'), findsWidgets);
    expect(find.text('SPORT'), findsNothing);
  });

  testWidgets('everyone answers for themselves, and counts are of members', (
    tester,
  ) async {
    const zone = 'America/Chicago';
    final w = ZonedTime.wallClock(zone, DateTime.now());
    final start = ZonedTime.instantOf(
      zone,
      DateTime.utc(w.year, w.month, w.day + 1),
      18 * 60,
    );
    final events = FakeEventRepository([
      Event(
        id: const EventId('e1'),
        groupId: const GroupId('c'),
        type: EventType.other,
        title: 'Meeting',
        startAt: start,
        endAt: start.add(const Duration(minutes: 90)),
        timeZone: zone,
        createdBy: 'coach',
        staffCounts: const RsvpCounts(going: 1),
      ),
    ]);
    final rsvps = FakeRsvpRepository(events);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'c': club},
      memberships: memberships,
      rsvpRepo: rsvps,
      // Even if a player were linked to them, it wouldn't count here.
      playerRepo:
          FakePlayerRepository(const [
              Player(
                id: PlayerId('p1'),
                groupId: GroupId('c'),
                displayName: 'Emma',
              ),
            ])
            ..links.add(
              const GuardianLink(
                playerId: PlayerId('p1'),
                groupId: GroupId('c'),
                uid: UserId('coach'),
              ),
            ),
    );
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    // One set of buttons, mine, unnamed.
    expect(find.byType(RsvpChoice), findsOneWidget);
    expect(find.text('Emma'), findsNothing);
    expect(find.text('1 going'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(RsvpChoice),
        matching: find.text('Going'),
      ),
    );
    await tester.pumpAndSettle();
    expect(rsvps.rsvps.single.participantType, ParticipantType.member);
    expect(rsvps.rsvps.single.participantId, 'coach');
  });

  testWidgets('joining a group goes to its chat, not "Who are you here '
      'for?"', (tester) async {
    final invites = FakeInviteRepository()
      ..previewed = const InvitePreview(
        groupId: 'c',
        name: 'Book club',
        sport: Sport.other,
        kind: GroupKind.group,
        memberCount: 8,
      );
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      invites: invites,
    );
    await tester.tap(find.text('Join a Team or Group'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'k7xp-m2qr');
    await tester.tap(find.widgetWithText(FilledButton, 'Join team'));
    await tester.pumpAndSettle();
    expect(find.text('8 members'), findsOneWidget);
    expect(find.textContaining('Other'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Join group'));
    await tester.pumpAndSettle();
    expect(invites.redeemed, ['K7XPM2QR']);
    expect(find.text('Who are you here for?'), findsNothing);
  });

  testWidgets("a group's owner makes it a team, with a sport; then it has "
      'Plays and players', (tester) async {
    final groupRepo = FakeGroupRepository({'c': club});
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groupRepo,
      memberships: memberships,
      size: const Size(1024, 1366),
    );
    expect(find.text('Plays'), findsNothing);
    await go(tester, '/g/c/settings');
    expect(find.widgetWithText(AppBar, 'Group admin'), findsOneWidget);
    final make = find.text('Make it a team');
    await tester.ensureVisible(make);
    await tester.tap(make);
    await tester.pumpAndSettle();
    expect(find.text('Make Book club a team?'), findsOneWidget);
    // Cancel changes nothing.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(groupRepo.updates, isEmpty);
    await tester.tap(make);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baseball').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Soccer').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Make it a team'));
    await tester.pumpAndSettle();
    expect(groupRepo.updates, ['convert soccer']);
    expect(find.text('Book club is a team now.'), findsOneWidget);
    // Team admin now, with its sport, and no way back.
    expect(find.widgetWithText(AppBar, 'Team admin'), findsOneWidget);
    expect(find.text('SPORT'), findsOneWidget);
    expect(find.text('Make it a team'), findsNothing);
    await go(tester, '/g/c/chat');
    expect(find.text('Plays'), findsOneWidget);
  });

  testWidgets("a group's admin who isn't its owner can't make it a team", (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'c': club},
      memberships: [
        testMembership('c', 'coach', role: MemberRole.admin, name: 'Coach Lee'),
      ],
    );
    await go(tester, '/g/c/settings');
    expect(find.text('Make it a team'), findsNothing);
  });
}
