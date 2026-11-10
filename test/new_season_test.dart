// Starting a new season from a team (SPEC TEAM-16): the owner's, from Team
// admin; who comes along, counted the way the server sorts people and all
// checked to start; the documents and plays when asked; then the new
// team's chat, and the old team's archived chat pointing to it.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/domain/season.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const owner = AuthUser(
    uid: 'pat',
    email: 'pat@example.com',
    emailVerified: true,
  );
  final fall = testGroup('fall', 'Thunder Fall');

  // Pat owns it; Ada is an admin and Cole coaches; Sam is Emma's parent;
  // Una is here for no player.
  List<Membership> people([String g = 'fall']) => [
    testMembership(g, 'pat', role: MemberRole.owner, name: 'Pat'),
    testMembership(g, 'ada', role: MemberRole.admin, name: 'Ada'),
    testMembership(g, 'cole', name: 'Cole').copyWith(coach: true),
    testMembership(g, 'sam', name: 'Sam'),
    testMembership(g, 'una', name: 'Una'),
  ];
  FakePlayerRepository players() =>
      FakePlayerRepository([
          const Player(
            id: PlayerId('emma'),
            groupId: GroupId('fall'),
            displayName: 'Emma',
            jerseyNumber: '7',
          ),
          // Waiting for approval: it doesn't come.
          const Player(
            id: PlayerId('max'),
            groupId: GroupId('fall'),
            displayName: 'Max',
            status: PlayerStatus.pending,
          ),
        ])
        ..links.add(
          const GuardianLink(
            playerId: PlayerId('emma'),
            groupId: GroupId('fall'),
            uid: UserId('sam'),
          ),
        );

  Future<void> go(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
  }

  String path(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Scaffold).first)).state.uri.path;

  Future<void> openFromAdminSettings(WidgetTester tester) async {
    await go(tester, '/g/fall/settings');
    final row = find.text('Start a new season');
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Start the new season');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  test('people are sorted as the server sorts them', () {
    Membership m(MemberRole role, {bool? coach}) =>
        testMembership('g', 'x', role: role).copyWith(coach: coach);
    expect(seasonGroupOf(m(MemberRole.owner), linked: true), SeasonGroup.owner);
    expect(seasonGroupOf(m(MemberRole.admin), linked: true), SeasonGroup.staff);
    expect(
      seasonGroupOf(m(MemberRole.member, coach: true), linked: false),
      SeasonGroup.staff,
    );
    expect(
      seasonGroupOf(m(MemberRole.member), linked: true),
      SeasonGroup.players,
    );
    expect(
      seasonGroupOf(m(MemberRole.member, coach: false), linked: false),
      SeasonGroup.others,
    );
  });

  testWidgets('the owner starts one in Admin settings and lands in its chat', (
    tester,
  ) async {
    final groupRepo = FakeGroupRepository({'fall': fall});
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: owner),
      groupRepo: groupRepo,
      memberships: people(),
      playerRepo: players(),
      size: const Size(1024, 1366),
    );
    await openFromAdminSettings(tester);
    expect(find.widgetWithText(AppBar, 'Start a new season'), findsOneWidget);
    // Everyone comes to start, counted; the copies are the owner's to add.
    expect(
      find.text('1 player. Parents keep answering for them.'),
      findsOneWidget,
    );
    expect(find.text('2 people'), findsOneWidget);
    expect(find.text('1 person'), findsOneWidget);
    final boxes = tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(boxes.map((b) => b.value), [true, true, true, false, false]);

    // It needs a name of its own.
    await start(tester);
    expect(find.text('Give the new season a name of its own.'), findsOneWidget);
    expect(groupRepo.seasons, isEmpty);
    await tester.enterText(find.byType(TextFormField), 'Thunder Spring');
    // The staff stay behind; the documents come.
    await tester.tap(find.text('Coaches and admins'));
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    await start(tester);
    expect(find.text('Start Thunder Spring?'), findsOneWidget);
    expect(
      find.text(
        'Thunder Fall will be archived: read-only, with its chat, photos, '
        'schedule, and results kept.',
      ),
      findsOneWidget,
    );
    // Cancel starts nothing.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(groupRepo.seasons, isEmpty);
    await start(tester);
    await tester.tap(find.text('Start season'));
    await tester.pumpAndSettle();
    expect(groupRepo.seasons, [
      (
        from: 'fall',
        name: 'Thunder Spring',
        choices: const SeasonChoices(staff: false, documents: true),
      ),
    ]);
    expect(path(tester), '/g/season1/chat');
    expect(find.text('Thunder Spring is ready.'), findsOneWidget);
  });

  testWidgets("an admin who isn't the owner doesn't see it", (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: owner),
      groups: {'fall': fall},
      memberships: [
        testMembership('fall', 'pat', role: MemberRole.admin, name: 'Pat'),
      ],
      size: const Size(1024, 1366),
    );
    await go(tester, '/g/fall/settings');
    expect(find.text('Owner actions'), findsNothing);
    expect(find.text('Start a new season'), findsNothing);
  });

  testWidgets("an archived team's owner restores it instead", (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: owner),
      groups: {'fall': fall.copyWith(archivedAt: DateTime(2026, 10))},
      memberships: people(),
      size: const Size(1024, 1366),
    );
    await go(tester, '/g/fall/settings');
    expect(find.text('Restore team'), findsOneWidget);
    expect(find.text('Start a new season'), findsNothing);
  });

  testWidgets('a group brings its admins and everyone else, no players', (
    tester,
  ) async {
    final groupRepo = FakeGroupRepository({
      'fall': fall.copyWith(kind: GroupKind.group, sport: Sport.other),
    });
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: owner),
      groupRepo: groupRepo,
      memberships: people(),
      size: const Size(1024, 1366),
    );
    await openFromAdminSettings(tester);
    expect(find.text('Players and their parents'), findsNothing);
    expect(find.text('Saved plays'), findsNothing);
    expect(find.text('Admins'), findsOneWidget);
    // Sam has no player to be here for in a group.
    expect(find.text('2 people'), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField), 'Book club 2027');
    await start(tester);
    await tester.tap(find.text('Start season'));
    await tester.pumpAndSettle();
    expect(
      groupRepo.seasons.single.choices,
      const SeasonChoices(players: false),
    );
  });

  testWidgets("says what went wrong, and who couldn't come", (tester) async {
    final groupRepo = FakeGroupRepository({'fall': fall})
      ..seasonFailure = const TooManyTeams('too-many-teams');
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: owner),
      groupRepo: groupRepo,
      memberships: people(),
      playerRepo: players(),
      size: const Size(1024, 1366),
    );
    await openFromAdminSettings(tester);
    await tester.enterText(find.byType(TextFormField), 'Thunder Spring');
    await start(tester);
    await tester.tap(find.text('Start season'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "You're on 100 teams, the most allowed. Leave a team to create a new "
        'one.',
      ),
      findsOneWidget,
    );
    expect(path(tester), '/g/fall/season');
    groupRepo
      ..seasonFailure = null
      ..seasonLeftOut = 2;
    await start(tester);
    await tester.tap(find.text('Start season'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Thunder Spring is ready. 2 people are on 100 teams and couldn't "
        'come along.',
      ),
      findsOneWidget,
    );
  });

  testWidgets("an archived team's chat goes to its next season, when I'm "
      'on it', (tester) async {
    final groupRepo = FakeGroupRepository({
      'fall': fall.copyWith(
        archivedAt: DateTime(2026, 11),
        nextSeasonId: const GroupId('spring'),
      ),
    });
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: owner),
      groupRepo: groupRepo,
      memberships: [...people(), ...people('spring')],
    );
    await go(tester, '/g/fall/chat');
    expect(
      find.text('This team is archived. Its chat is read-only.'),
      findsOneWidget,
    );
    // Not on it, or it's gone: nothing to go to.
    expect(find.textContaining('Go to'), findsNothing);
    groupRepo.setGroup(testGroup('spring', 'Thunder Spring'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to Thunder Spring'));
    await tester.pumpAndSettle();
    expect(path(tester), '/g/spring/chat');
  });
}
