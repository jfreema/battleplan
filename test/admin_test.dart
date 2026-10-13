// The God admin panel (SPEC ADMIN-1 to ADMIN-8, STORE-6, SAFE-4) and what
// it changes elsewhere: the announcement banner everyone sees, and a super
// admin viewing a team's tabs.
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/composer.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const boss = AuthUser(
    uid: 'boss',
    email: 'boss@example.com',
    displayName: 'Bea Boss',
    emailVerified: true,
    isSuperAdmin: true,
  );
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const wide = Size(1280, 1000);
  // Long forms fit without scrolling.
  const tall = Size(1280, 2400);
  final now = DateTime.now();

  AdminTeamRow row(
    String id,
    String name, {
    int members = 5,
    int mb = 10,
    int ageDays = 1,
    TeamStatus status = TeamStatus.active,
    String owner = 'Olive Owner',
  }) => AdminTeamRow(
    id: GroupId(id),
    name: name,
    sport: Sport.soccer,
    ownerName: owner,
    memberCount: members,
    storageBytes: mb * bytesPerMb,
    storageQuotaBytes: 500 * bytesPerMb,
    status: status,
    createdAt: now.subtract(Duration(days: ageDays)),
    lastMessageAt: now.subtract(Duration(hours: ageDays)),
  );

  /// Thunder (newest, 12 members), Lightning (8 members, most storage),
  /// and Hail (suspended, oldest).
  List<AdminTeamRow> teamRows() => [
    row('t1', 'Thunder', members: 12),
    row('t2', 'Lightning', members: 8, mb: 300, ageDays: 3),
    row('t3', 'Hail', members: 2, ageDays: 9, status: TeamStatus.suspended),
  ];

  /// Pumps the app signed in as [user] (on team "a"), then goes to [path].
  Future<void> open(
    WidgetTester tester,
    String path, {
    AuthUser user = boss,
    FakeAdminRepository? admin,
    FakeGroupRepository? groupRepo,
    FakeMemberRepository? memberRepo,
    FakeMessageRepository? messageRepo,
    FakePollRepository? pollRepo,
    FakeDocumentRepository? documentRepo,
    FakePlayerRepository? playerRepo,
    FakeInviteRepository? invites,
    Size size = wide,
  }) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: user),
      admin: admin,
      groupRepo:
          groupRepo ??
          FakeGroupRepository({
            'a': testGroup('a', 'Home team'),
            't1': testGroup('t1', 'Thunder'),
          }),
      memberRepo:
          memberRepo ??
          FakeMemberRepository([
            testMembership('a', user.uid, role: MemberRole.owner),
          ]),
      messageRepo: messageRepo,
      pollRepo: pollRepo,
      documentRepo: documentRepo,
      playerRepo: playerRepo,
      invites: invites,
      size: size,
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
  }

  group('access (ADMIN)', () {
    testWidgets('only super admins get in; others go back to their team', (
      tester,
    ) async {
      await open(tester, '/admin', user: coach);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Home team'), findsWidgets);

      await open(tester, '/admin/teams', user: coach);
      expect(find.text('Search teams by name'), findsNothing);
    });

    testWidgets('the account menu shows Admin panel only to super admins', (
      tester,
    ) async {
      await open(tester, '/', user: coach, size: const Size(400, 900));
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Admin panel'), findsNothing);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      final admin = FakeAdminRepository(
        totalsValue: const AdminTotals(users: 42),
      );
      await open(tester, '/', admin: admin, size: const Size(400, 900));
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin panel'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('42'), findsOneWidget);
    });
  });

  testWidgets('a super admin on no team gets in from Settings', (tester) async {
    Future<void> welcome(AuthUser user) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: user),
        admin: FakeAdminRepository(totalsValue: const AdminTotals(users: 42)),
        size: const Size(400, 1000),
      );
      expect(find.text('Welcome to Battleplan'), findsOneWidget);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
    }

    await welcome(coach);
    expect(find.text('Admin panel'), findsNothing);

    await welcome(boss);
    await tester.tap(find.text('Admin panel'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('the dashboard shows every total and opens reports (ADMIN-1)', (
    tester,
  ) async {
    final admin = FakeAdminRepository(
      totalsValue: const AdminTotals(
        users: 1234,
        teams: 87,
        newTeams: 6,
        activeTeams: 40,
        messages: 5321,
        storageBytes: 3 * 1024 * bytesPerMb,
        openReports: 2,
      ),
    );
    await open(tester, '/admin', admin: admin);
    for (final (label, value) in [
      ('Users', '1,234'),
      ('Teams', '87'),
      ('New teams this week', '6'),
      ('Active teams (7 days)', '40'),
      ('Messages (7 days)', '5,321'),
      ('Total storage', '3.0 GB'),
      ('Open reports', '2'),
    ]) {
      expect(find.bySemanticsLabel('$label: $value'), findsOneWidget);
    }
    await tester.tap(find.bySemanticsLabel('Open reports: 2'));
    await tester.pumpAndSettle();
    expect(find.text('No open reports.'), findsOneWidget);
  });

  group('teams (ADMIN-2)', () {
    List<String> shownNames(WidgetTester tester) =>
        [
          for (final name in ['Thunder', 'Lightning', 'Hail'])
            if (find.text(name).evaluate().isNotEmpty) name,
        ]..sort(
          (a, b) => tester
              .getTopLeft(find.text(a))
              .dy
              .compareTo(tester.getTopLeft(find.text(b)).dy),
        );

    testWidgets('a table on wide screens: search, sort, and filter', (
      tester,
    ) async {
      final admin = FakeAdminRepository(teams: teamRows());
      await open(tester, '/admin/teams', admin: admin);
      expect(find.byType(DataTable), findsOneWidget);
      // Newest first, with every column.
      expect(shownNames(tester), ['Thunder', 'Lightning', 'Hail']);
      expect(find.text('Olive Owner'), findsNWidgets(3));
      expect(find.text('300 MB'), findsOneWidget);
      expect(find.text('Suspended'), findsWidgets);

      await tester.tap(find.text('Newest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Most storage').last);
      await tester.pumpAndSettle();
      expect(shownNames(tester), ['Lightning', 'Thunder', 'Hail']);
      expect(admin.teamQueries.last.sort, AdminTeamSort.storage);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Suspended'));
      await tester.pumpAndSettle();
      expect(shownNames(tester), ['Hail']);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'li');
      // The search waits for typing to pause.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(shownNames(tester), ['Lightning']);
      expect(admin.teamQueries.last.query, 'li');
    });

    testWidgets('a list on phones, paged with Load more', (tester) async {
      final admin = FakeAdminRepository(teams: teamRows(), pageSize: 2);
      await open(
        tester,
        '/admin/teams',
        admin: admin,
        size: const Size(400, 1000),
      );
      expect(find.byType(DataTable), findsNothing);
      expect(find.widgetWithText(ListTile, 'Thunder'), findsOneWidget);
      expect(find.text('Hail'), findsNothing);
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Hail'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('a status filter keeps looking past an empty page', (
      tester,
    ) async {
      // The server looks through 2 teams per page; Hail, the only
      // suspended one, is third, so the first page comes back empty.
      final admin = FakeAdminRepository(teams: teamRows(), teamScan: 2);
      await open(tester, '/admin/teams', admin: admin);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Suspended'));
      await tester.pumpAndSettle();
      expect(find.text('No teams match.'), findsNothing);
      expect(shownNames(tester), isEmpty);
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(shownNames(tester), ['Hail']);
      expect(find.text('Load more'), findsNothing);
    });
  });

  group('team detail (ADMIN-3)', () {
    Future<(FakeAdminRepository, FakeMemberRepository)> openTeam(
      WidgetTester tester, {
      Group? group,
      FakeMessageRepository? messageRepo,
    }) async {
      final admin = FakeAdminRepository(
        teams: teamRows(),
        teamDetails: {
          't1': AdminTeamDetail(
            id: const GroupId('t1'),
            ownerName: 'Olive Owner',
            createdAt: now.subtract(const Duration(days: 30)),
            members: [
              testMembership(
                't1',
                'olive',
                role: MemberRole.owner,
                name: 'Olive Owner',
              ),
              testMembership('t1', 'sam', name: 'Sam Rivera'),
            ],
            invites: const [AdminInvite(code: 'K7XPM2QR', useCount: 3)],
            recentMessages: [
              AdminMessage(
                id: 'm1',
                authorName: 'Sam Rivera',
                text: 'Buy cheap pills here',
                createdAt: now.subtract(const Duration(hours: 1)),
              ),
              const AdminMessage(
                id: 'm2',
                authorName: 'Olive Owner',
                photoCount: 2,
              ),
            ],
            eventCount: 4,
            documentCount: 2,
            pollCount: 1,
          ),
        },
      );
      final members = FakeMemberRepository([
        testMembership('a', 'boss', role: MemberRole.owner),
      ]);
      await open(
        tester,
        '/admin/teams/t1',
        admin: admin,
        memberRepo: members,
        messageRepo: messageRepo,
        groupRepo: FakeGroupRepository({
          'a': testGroup('a', 'Home team'),
          't1':
              group ??
              testGroup('t1', 'Thunder').copyWith(
                storageBytes: 212 * bytesPerMb,
                storageQuotaBytes: 500 * bytesPerMb,
              ),
        }),
      );
      return (admin, members);
    }

    testWidgets('shows the team, its people, invites, and content', (
      tester,
    ) async {
      await openTeam(tester);
      expect(find.text('Owner: Olive Owner'), findsOneWidget);
      expect(find.text('Sam Rivera'), findsOneWidget);
      expect(find.text('K7XPM2QR · Used 3 times'), findsOneWidget);
      expect(find.text('4 events · 2 documents · 1 poll'), findsOneWidget);
      expect(find.text('212 MB of 500 MB used'), findsOneWidget);
    });

    testWidgets('recent messages can be reviewed and deleted after asking', (
      tester,
    ) async {
      final messages = FakeMessageRepository();
      await openTeam(tester, messageRepo: messages);
      final pills = find.text('Buy cheap pills here');
      await tester.scrollUntilVisible(pills, 200);
      expect(pills, findsOneWidget);
      expect(find.text('2 photos'), findsOneWidget);

      final delete = find.byTooltip('Delete message from Sam Rivera');
      await tester.ensureVisible(delete);
      await tester.pumpAndSettle();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(messages.deleted, isEmpty);

      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(messages.deleted, ['m1']);
      expect(find.text('Message deleted.'), findsOneWidget);
    });

    testWidgets('archive and suspend ask first, and canceling does nothing', (
      tester,
    ) async {
      final (admin, _) = await openTeam(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Archive team'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(admin.calls, isEmpty);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Archive team'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Archive team'));
      await tester.pumpAndSettle();
      expect(admin.calls, ['archive t1 true']);
      expect(find.text('Team archived.'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Suspend'));
      await tester.pumpAndSettle();
      expect(find.text('Suspend Thunder?'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Spam ring',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
      await tester.pumpAndSettle();
      expect(admin.calls.last, 'suspend t1 true Spam ring');
      expect(find.text('Team suspended.'), findsOneWidget);
    });

    testWidgets('a suspended team offers Unsuspend', (tester) async {
      final (admin, _) = await openTeam(
        tester,
        group: testGroup('t1', 'Thunder').copyWith(suspendedAt: now),
      );
      expect(find.text('Suspended'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Unsuspend'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Unsuspend'));
      await tester.pumpAndSettle();
      expect(admin.calls, ['suspend t1 false']);
    });

    testWidgets('delete needs the name typed', (tester) async {
      final (admin, _) = await openTeam(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete team'));
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(FilledButton, 'Delete team');
      final field = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.enterText(field, 'Thunde');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.enterText(field, 'Thunder');
      await tester.pump();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(admin.calls, ['delete t1 Thunder']);
      // Back to the teams list.
      expect(find.text('Search teams by name'), findsOneWidget);
    });

    testWidgets('people: roles and removal, removal asking first', (
      tester,
    ) async {
      final (_, members) = await openTeam(tester);
      await tester.tap(find.byTooltip('Actions for Sam Rivera'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Make admin'));
      await tester.pumpAndSettle();
      expect(members.calls, ['update sam admin']);

      await tester.tap(find.byTooltip('Actions for Sam Rivera'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from team'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Sam Rivera from the team?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Remove from team'));
      await tester.pumpAndSettle();
      expect(members.calls.last, 'remove sam');

      // The owner can't be removed here; ownership moves by transfer.
      await tester.tap(find.byTooltip('Actions for Olive Owner'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from team'), findsNothing);
      expect(find.text('Transfer ownership'), findsNothing);
    });

    testWidgets('storage limit and View team (STORE-6)', (tester) async {
      final groups = FakeGroupRepository({
        'a': testGroup('a', 'Home team'),
        't1': testGroup('t1', 'Thunder'),
      });
      await open(tester, '/admin/teams/t1', groupRepo: groups);
      await tester.tap(find.text('Change storage limit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '2048',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(groups.updates, ['quota t1 2048']);
    });
  });

  group("a super admin on a team they aren't on (ADMIN-3)", () {
    FakeGroupRepository youthTeam() => FakeGroupRepository({
      'a': testGroup('a', 'Home team'),
      't1': testGroup('t1', 'Thunder'),
    });
    FakeMemberRepository thunderPeople() => FakeMemberRepository([
      testMembership('a', 'boss', role: MemberRole.owner),
      testMembership('t1', 'olive', role: MemberRole.owner, name: 'Olive'),
      testMembership('t1', 'sam', name: 'Sam Rivera'),
    ]);
    FakePlayerRepository emma() => FakePlayerRepository([
      const Player(
        id: PlayerId('emma'),
        groupId: GroupId('t1'),
        displayName: 'Emma Rodriguez',
        jerseyNumber: '7',
      ),
    ]);

    testWidgets('Roster and Member card: owner powers', (tester) async {
      final members = thunderPeople();
      await open(
        tester,
        '/g/t1/roster',
        groupRepo: youthTeam(),
        memberRepo: members,
        playerRepo: emma(),
      );
      expect(find.text('Add players'), findsOneWidget);
      await tester.tap(find.text('Sam Rivera'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from team'), findsOneWidget);
      await tester.tap(find.text('Make admin'));
      await tester.pumpAndSettle();
      expect(members.calls, ['update sam admin']);
    });

    testWidgets('Invite: reset the link', (tester) async {
      final invites = FakeInviteRepository();
      await open(
        tester,
        '/g/t1/invite',
        memberRepo: thunderPeople(),
        invites: invites,
        size: tall,
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reset link'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reset link'));
      await tester.pumpAndSettle();
      expect(invites.resets, 1);
    });

    testWidgets('Player card: edits go through the audited callable', (
      tester,
    ) async {
      final admin = FakeAdminRepository();
      final players = emma();
      await open(
        tester,
        '/g/t1/roster/players/emma',
        admin: admin,
        groupRepo: youthTeam(),
        memberRepo: thunderPeople(),
        playerRepo: players,
      );
      expect(find.text('Remove player'), findsOneWidget);
      expect(find.text('Add a guardian'), findsOneWidget);
      await tester.tap(find.byTooltip('Edit player'));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'Emma Rodríguez');
      await tester.enterText(fields.at(2), 'Keeper');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(admin.calls, ['player emma Emma Rodríguez #7 Keeper']);
      expect(players.calls, isEmpty);

      // A team admin still writes the player directly.
      final own = FakeAdminRepository();
      await open(
        tester,
        '/g/t1/roster/players/emma',
        admin: own,
        groupRepo: youthTeam(),
        memberRepo: FakeMemberRepository([
          testMembership('a', 'boss', role: MemberRole.owner),
          testMembership('t1', 'boss', role: MemberRole.admin),
        ]),
        playerRepo: players,
      );
      await tester.tap(find.byTooltip('Edit player'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(players.calls, ['update emma Emma Rodriguez']);
      expect(own.calls, isEmpty);
    });

    testWidgets('Team settings: edits go through the audited callable', (
      tester,
    ) async {
      final admin = FakeAdminRepository();
      final groups = youthTeam();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: boss),
        admin: admin,
        groupRepo: groups,
        memberRepo: thunderPeople(),
        photoPicker: FakePhotoPicker([
          (bytes: tinyPng, contentType: 'image/png'),
        ])..profilePhoto = tinyPng,
        size: tall,
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/g/t1/settings');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Storm');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(admin.calls.last, 'team t1 name=Storm description=');

      await tester.tap(find.text('Change logo'));
      await tester.pumpAndSettle();
      expect(admin.calls.last, 'team t1 photoPath=groups/t1/avatar/logo0.jpg');
      expect(groups.logosUploaded, 0);

      await tester.tap(find.text('Pattern'));
      await tester.pumpAndSettle();
      expect(admin.calls.last, 'team t1 chatTheme=pattern');
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();
      expect(
        admin.calls.last,
        'team t1 chatTheme=photo:groups/t1/theme/bg.jpg',
      );

      final allowMaybe = find.text('Allow "Maybe" RSVPs');
      await tester.ensureVisible(allowMaybe);
      await tester.tap(allowMaybe);
      await tester.pumpAndSettle();
      expect(admin.calls.last, 'team t1 settings');

      // Nothing was written to the team directly, which the rules refuse.
      expect(groups.updates, isEmpty);
      expect(groups.savedTheme, isNull);
    });
  });

  group('users (ADMIN-4)', () {
    AdminUserRow person(
      String uid,
      String name, {
      UserStatus status = UserStatus.active,
      bool superAdmin = false,
    }) => AdminUserRow(
      uid: UserId(uid),
      displayName: name,
      email: '$uid@example.com',
      status: status,
      superAdmin: superAdmin,
      createdAt: now.subtract(const Duration(days: 40)),
    );

    FakeAdminRepository people() => FakeAdminRepository(
      teams: teamRows(),
      users: [
        person('boss', 'Bea Boss', superAdmin: true),
        person('sam', 'Sam Rivera'),
        person('ann', 'Ann Added', status: UserStatus.provisioned),
        person('dan', 'Dan Disabled', status: UserStatus.disabled),
      ],
      userDetails: {
        'sam': AdminUserDetail(
          user: person('sam', 'Sam Rivera'),
          signInMethods: const ['password', 'google.com'],
          teams: const [
            AdminUserTeam(
              groupId: GroupId('t1'),
              name: 'Thunder',
              role: MemberRole.admin,
            ),
          ],
        ),
      },
    );

    testWidgets('search and filter', (tester) async {
      await open(tester, '/admin/users', admin: people());
      expect(find.text('Sam Rivera'), findsOneWidget);
      expect(find.text('Dan Disabled'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Added'));
      await tester.pumpAndSettle();
      expect(find.text('Ann Added'), findsOneWidget);
      expect(find.text('Sam Rivera'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Super admin'));
      await tester.pumpAndSettle();
      expect(find.text('Bea Boss'), findsOneWidget);
      expect(find.text('Ann Added'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'dan@');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Dan Disabled'), findsOneWidget);
      expect(find.text('Sam Rivera'), findsNothing);
    });

    testWidgets('details, and every action asks first where it takes away', (
      tester,
    ) async {
      final admin = people();
      await open(tester, '/admin/users/sam', admin: admin);
      expect(
        find.text('Signs in with: Email and password, Google'),
        findsOneWidget,
      );
      expect(find.text('Thunder'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);

      Future<void> act(String button, String confirm) async {
        await tester.tap(find.widgetWithText(OutlinedButton, button));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, confirm));
        await tester.pumpAndSettle();
      }

      await act('Send password reset', 'Send reset link');
      expect(admin.calls, ['reset sam']);
      expect(find.text('Password reset email sent.'), findsOneWidget);

      await act('Sign out of all devices', 'Sign out of all devices');
      expect(admin.calls.last, 'signOut sam');

      await act('Disable', 'Disable');
      expect(admin.calls.last, 'disable sam true');
      // It reloads: now disabled, with Enable.
      expect(find.widgetWithText(OutlinedButton, 'Enable'), findsOneWidget);

      await act('Make super admin', 'Make super admin');
      expect(admin.calls.last, 'superAdmin sam true');
      expect(find.text('Sam Rivera is now a super admin.'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Edit name'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Samantha Rivera',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(admin.calls.last, 'rename sam Samantha Rivera');

      await tester.tap(find.widgetWithText(OutlinedButton, 'Add to a team'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lightning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin').last);
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      expect(admin.calls.last, 'addToTeam sam t2 admin');

      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(admin.calls.last, isNot('deleteUser sam'));
      await act('Delete account', 'Delete account');
      expect(admin.calls.last, 'deleteUser sam');
      expect(find.text('Search by name or email'), findsOneWidget);
    });

    testWidgets("the server's last-super-admin refusal is explained", (
      tester,
    ) async {
      final admin = people()
        ..failWith = const LastSuperAdmin('last-super-admin');
      await open(tester, '/admin/users/boss', admin: admin);
      // Nobody deletes their own account from here.
      expect(
        find.widgetWithText(OutlinedButton, 'Delete account'),
        findsNothing,
      );
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Remove super admin'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remove super admin from Bea Boss?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Remove super admin'));
      await tester.pumpAndSettle();
      expect(admin.calls, isEmpty);
      expect(
        find.text(
          'There must always be at least one super admin. Make someone else '
          'a super admin first.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('revoking your own super admin reports it, then signs out', (
      tester,
    ) async {
      final admin = people();
      admin.users.add(person('ada', 'Ada Admin', superAdmin: true));
      // The server revokes your session with the claim, so the refresh
      // that follows fails and the session ends.
      final auth = FakeAuthRepository(user: boss)..reloadEndsSession = true;
      await pumpApp(
        tester,
        auth: auth,
        admin: admin,
        groups: {'a': testGroup('a', 'Home team')},
        memberships: [testMembership('a', 'boss', role: MemberRole.owner)],
        size: wide,
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/admin/users/boss');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Remove super admin'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove super admin'));
      await tester.pumpAndSettle();
      expect(admin.calls, ['superAdmin boss false']);
      expect(find.text('Bea Boss is no longer a super admin.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('Continue with email'), findsOneWidget);
    });

    testWidgets('create a user with a team and role', (tester) async {
      final admin = people();
      await open(tester, '/admin/users', admin: admin);
      await tester.tap(find.text('Create user').first);
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      // Name and a valid email first.
      await tester.tap(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(FilledButton, 'Create user'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enter your name.'), findsOneWidget);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      final fields = find.descendant(
        of: dialog,
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'Nina New');
      await tester.enterText(fields.at(1), 'nina@example.com');
      await tester.tap(find.text('Add to a team (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thunder').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<MemberRole>),
          matching: find.text('Admin'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(FilledButton, 'Create user'),
        ),
      );
      await tester.pumpAndSettle();
      expect(admin.calls, ['create nina@example.com Nina New t1 admin']);
      // The new person's page opens.
      expect(find.text('Nina New'), findsWidgets);
      expect(find.text('Added'), findsOneWidget);
    });
  });

  group('reports (ADMIN-5)', () {
    AdminReport report(
      String id, {
      ReportTargetType type = ReportTargetType.message,
    }) => AdminReport(
      id: id,
      groupId: const GroupId('t1'),
      groupName: 'Thunder',
      targetType: type,
      targetId: 'm1',
      reason: ReportReason.harassment,
      subjectId: 'sam',
      subjectName: 'Sam Rivera',
      excerpt: 'You are all terrible',
      reporterId: 'pat',
      reporterName: 'Pat Kim',
      createdAt: now,
    );

    testWidgets('every team, with a required note for each resolution', (
      tester,
    ) async {
      final admin = FakeAdminRepository(
        reports: [
          report('r1'),
          report('r2', type: ReportTargetType.user),
        ],
      );
      await open(tester, '/admin/reports', admin: admin);
      expect(find.text('You are all terrible'), findsNWidgets(2));
      expect(find.text('Reported by Pat Kim'), findsNWidgets(2));
      expect(find.text('Thunder'), findsNWidgets(2));
      // A reported person has no content to delete.
      expect(find.text('Delete message'), findsOneWidget);

      await tester.tap(find.text('Suspend team').first);
      await tester.pumpAndSettle();
      final confirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Suspend team'),
      );
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Repeated abuse',
      );
      await tester.pump();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(admin.calls, ['resolve r1 suspendTeam Repeated abuse']);
      expect(find.text('Report closed.'), findsOneWidget);
      expect(find.text('Delete message'), findsNothing);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Not abuse',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Dismiss'));
      await tester.pumpAndSettle();
      expect(admin.calls.last, 'resolve r2 dismiss Not abuse');
      expect(find.text('No open reports.'), findsOneWidget);

      // Closed ones keep their note.
      await tester.tap(find.text('Actioned'));
      await tester.pumpAndSettle();
      expect(find.text('Note: Repeated abuse'), findsOneWidget);
    });
  });

  testWidgets('the audit log filters by person, action, and team (ADMIN-6)', (
    tester,
  ) async {
    AuditEntry entry(String id, String actor, String action, {String? group}) =>
        AuditEntry(
          id: id,
          actorId: actor,
          action: action,
          groupId: group == null ? null : GroupId(group),
          targetType: 'group',
          targetId: group ?? '',
          before: const {'suspended': false},
          after: const {'suspended': true},
          createdAt: now,
        );
    final admin = FakeAdminRepository(
      audit: [
        entry('1', 'boss', 'suspendGroup', group: 't1'),
        entry('2', 'boss', 'viewGroup', group: 't2'),
        entry('3', 'zed', 'deleteMessage', group: 't1'),
      ],
    );
    await open(tester, '/admin/audit', admin: admin);
    expect(find.text('suspendGroup'), findsOneWidget);
    expect(find.text('deleteMessage'), findsOneWidget);

    Future<void> filter(String label, String value) async {
      await tester.enterText(find.widgetWithText(TextField, label), value);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
    }

    await filter('Action', 'suspendGroup');
    expect(find.text('deleteMessage'), findsNothing);
    expect(find.text('viewGroup'), findsNothing);
    expect(admin.auditFilters.last.action, 'suspendGroup');

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    await filter('Team (team ID)', 't1');
    expect(find.text('suspendGroup'), findsOneWidget);
    expect(find.text('deleteMessage'), findsOneWidget);
    expect(find.text('viewGroup'), findsNothing);

    await filter('Person (user ID)', 'zed');
    expect(find.text('deleteMessage'), findsOneWidget);
    expect(find.text('suspendGroup'), findsNothing);
    expect(
      admin.auditFilters.last,
      const AuditFilter(actorId: 'zed', groupId: GroupId('t1')),
    );

    // An entry opens with its before and after values.
    await tester.tap(find.text('deleteMessage'));
    await tester.pumpAndSettle();
    expect(find.text('Before'), findsOneWidget);
    expect(find.textContaining('"suspended": true'), findsOneWidget);

    // A person's page links here filtered to them.
    await open(tester, '/admin/audit?actor=boss', admin: admin);
    expect(admin.auditFilters.last.actorId, 'boss');
    expect(find.text('deleteMessage'), findsNothing);
  });

  group('platform settings (ADMIN-7)', () {
    testWidgets('checks the ranges, then saves', (tester) async {
      final admin = FakeAdminRepository(
        config: AppConfig(
          supportEmail: 'help@getbattleplan.app',
          announcementBanner: Announcement(
            text: 'Maintenance Sunday',
            severity: BannerSeverity.warning,
            expiresAt: now.add(const Duration(days: 3)),
          ),
        ),
      );
      await open(tester, '/admin/settings', admin: admin, size: tall);
      expect(find.widgetWithText(TextField, '500'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Maintenance Sunday'),
        findsOneWidget,
      );

      await tester.enterText(find.widgetWithText(TextField, '10'), '20');
      await tester.enterText(
        find.widgetWithText(TextField, 'help@getbattleplan.app'),
        'nope',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a whole number from 1 to 10.'), findsOneWidget);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(admin.calls, isEmpty);

      await tester.enterText(find.widgetWithText(TextField, '20'), '8');
      await tester.enterText(
        find.widgetWithText(TextField, 'nope'),
        'support@getbattleplan.app',
      );
      await tester.tap(find.text('Anyone can create teams'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Maintenance Sunday'),
        'Maintenance Saturday',
      );
      await tester.tap(find.text('Critical'));
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      final saved = admin.savedConfigs.single;
      expect(saved.maxUploadMb, 8);
      expect(saved.supportEmail, 'support@getbattleplan.app');
      expect(saved.allowUserGroupCreation, isFalse);
      expect(saved.announcementBanner?.text, 'Maintenance Saturday');
      expect(saved.announcementBanner?.severity, BannerSeverity.critical);
      expect(find.text('Settings saved.'), findsOneWidget);
    });

    testWidgets('a banner needs text, and turning it off removes it', (
      tester,
    ) async {
      final admin = FakeAdminRepository(
        config: const AppConfig(supportEmail: 'help@getbattleplan.app'),
      );
      await open(tester, '/admin/settings', admin: admin, size: tall);
      await tester.tap(find.text('Show a banner to everyone'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter the banner text, up to 280 characters.'),
        findsOneWidget,
      );
      expect(
        find.text('Choose when the banner ends, in the future.'),
        findsOneWidget,
      );
      expect(admin.calls, isEmpty);

      await tester.tap(find.text('Show a banner to everyone'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(admin.savedConfigs.single.announcementBanner, isNull);
    });

    testWidgets('the upload limit and support address take effect', (
      tester,
    ) async {
      final admin = FakeAdminRepository(
        config: const AppConfig(
          maxUploadMb: 2,
          supportEmail: 'help@club.example',
        ),
      );
      final big = Uint8List(3 * bytesPerMb);
      final picker = FakePhotoPicker([
        (bytes: tinyPng, contentType: 'image/png'),
        (bytes: big, contentType: 'image/jpeg'),
      ])..profilePhoto = big;
      final messages = FakeMessageRepository();
      final docs = FakeDocumentRepository([]);
      final groups = FakeGroupRepository({'a': testGroup('a', 'Thunder')});
      final opener = FakeLinkOpener();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        admin: admin,
        groupRepo: groups,
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
        messageRepo: messages,
        documentRepo: docs,
        photoPicker: picker,
        fileChooser: FakeFileChooser(
          next: pickedFile('Roster.pdf', 3 * bytesPerMb),
        ),
        linkOpener: opener,
      );
      const tooBig = 'That file is 3.0 MB. Files can be up to 2 MB.';
      Future<void> snackBarGone() async {
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }

      // Chat: the photo under the limit goes; the big one is left out.
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo library'));
      await tester.pumpAndSettle();
      expect(find.text(tooBig), findsOneWidget);
      expect(messages.photoBatches, [1]);
      await snackBarGone();

      // Documents.
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add a file or link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload file'));
      await tester.pumpAndSettle();
      expect(find.text(tooBig), findsOneWidget);
      expect(docs.upload, isNull);
      await snackBarGone();

      // The team logo.
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/g/a/settings');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change logo'));
      await tester.pumpAndSettle();
      expect(find.text(tooBig), findsOneWidget);
      expect(groups.logosUploaded, 0);

      // Settings names the support address and writes to it.
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/settings');
      await tester.pumpAndSettle();
      expect(find.text('help@club.example'), findsOneWidget);
      await tester.tap(find.text('Contact support'));
      expect(opener.opened.single, Uri.parse('mailto:help@club.example'));
    });

    testWidgets('a disabled account is told where to write', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        users: FakeUserRepository(status: UserStatus.disabled),
        admin: FakeAdminRepository(
          config: const AppConfig(supportEmail: 'help@club.example'),
        ),
      );
      expect(
        find.text(
          'This account has been disabled. For help, write to '
          'help@club.example.',
        ),
        findsOneWidget,
      );
    });

    test('configProblems matches the server ranges', () {
      final ok = AppConfig(
        supportEmail: 'a@b.co',
        announcementBanner: Announcement(
          text: 'Hi',
          severity: BannerSeverity.info,
          expiresAt: now.add(const Duration(hours: 1)),
        ),
      );
      expect(configProblems(ok, now), isEmpty);
      expect(
        configProblems(
          ok.copyWith(
            maxGroupsCreatedPerUserPerDay: 101,
            defaultStorageQuotaMb: 0,
            maxUploadMb: 11,
            supportEmail: 'x',
            announcementBanner: Announcement(
              text: 'x' * 281,
              severity: BannerSeverity.info,
              expiresAt: now,
            ),
          ),
          now,
        ),
        ConfigProblem.values.toSet(),
      );
    });
  });

  group('announcement banner (ADMIN-7)', () {
    Future<FakeAdminRepository> openWithBanner(
      WidgetTester tester, {
      BannerSeverity severity = BannerSeverity.info,
      Duration lasts = const Duration(days: 2),
    }) async {
      final admin = FakeAdminRepository(
        config: AppConfig(
          announcementBanner: Announcement(
            text: 'Scheduled maintenance tonight',
            severity: severity,
            expiresAt: DateTime.now().add(lasts),
          ),
        ),
      );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        admin: admin,
        groups: {'a': testGroup('a', 'Home team')},
        memberships: [testMembership('a', 'coach')],
      );
      return admin;
    }

    testWidgets('everyone signed in sees it, colored by severity', (
      tester,
    ) async {
      await openWithBanner(tester, severity: BannerSeverity.critical);
      expect(find.text('Scheduled maintenance tonight'), findsOneWidget);
      expect(find.byIcon(AppIcons.error), findsOneWidget);
      final banner = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Scheduled maintenance tonight'),
              matching: find.byType(Material),
            )
            .last,
      );
      final scheme = Theme.of(
        tester.element(find.text('Scheduled maintenance tonight')),
      ).colorScheme;
      expect(banner.color, scheme.errorContainer);

      await openWithBanner(tester, severity: BannerSeverity.warning);
      expect(find.byIcon(AppIcons.warning), findsOneWidget);
    });

    testWidgets('Dismiss hides it for the session', (tester) async {
      final admin = await openWithBanner(tester);
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Scheduled maintenance tonight'), findsNothing);
      // A new announcement shows again.
      admin.config = AppConfig(
        announcementBanner: Announcement(
          text: 'Back up and running',
          severity: BannerSeverity.info,
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Back up and running'), findsOneWidget);
    });

    testWidgets('it goes away when it ends, and an ended one never shows', (
      tester,
    ) async {
      await openWithBanner(tester, lasts: const Duration(seconds: 5));
      expect(find.text('Scheduled maintenance tonight'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('Scheduled maintenance tonight'), findsNothing);

      await openWithBanner(tester, lasts: const Duration(seconds: -1));
      expect(find.text('Scheduled maintenance tonight'), findsNothing);
    });
  });

  group('View team (ADMIN-3)', () {
    Message message(String id, String text) => Message(
      id: id,
      groupId: const GroupId('t1'),
      authorId: 'sam',
      authorName: 'Sam Rivera',
      type: MessageType.text,
      text: text,
      createdAt: now.subtract(const Duration(minutes: 5)),
    );

    testWidgets('read-only with the banner, moderation, and an audit entry', (
      tester,
    ) async {
      final admin = FakeAdminRepository();
      final messages = FakeMessageRepository([
        message('m1', 'Buy cheap pills'),
      ]);
      await open(
        tester,
        '/admin/teams/t1',
        admin: admin,
        messageRepo: messages,
        size: const Size(400, 1000),
      );
      await tester.tap(find.text('View team'));
      await tester.pumpAndSettle();

      expect(
        find.text('Viewing as super admin. Read-only, with moderation.'),
        findsOneWidget,
      );
      expect(admin.opened, ['t1']);
      expect(find.text('Buy cheap pills'), findsOneWidget);
      expect(find.byType(Composer), findsNothing);
      expect(
        find.text(
          "You're viewing this team as a super admin. You can delete "
          'messages, but not post.',
        ),
        findsOneWidget,
      );
      // No switcher or team menu: this isn't one of their teams.
      expect(find.byTooltip('Team menu'), findsNothing);

      // The menu offers moderation only.
      await tester.longPress(find.text('Buy cheap pills'));
      await tester.pumpAndSettle();
      expect(find.text('Reply'), findsNothing);
      expect(find.text('Report'), findsNothing);
      expect(find.text('Copy text'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete message'));
      await tester.pumpAndSettle();
      expect(messages.deleted, ['m1']);

      // Documents: no adding, but deleting any.
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(admin.opened, ['t1']);

      // Back to the team's admin page.
      await tester.tap(find.text('Back to admin panel'));
      await tester.pumpAndSettle();
      expect(find.text('View team'), findsOneWidget);
    });

    testWidgets('polls show results without voting; nothing is marked read', (
      tester,
    ) async {
      final polls = FakePollRepository()
        ..put(
          const Poll(
            id: PollId('p1'),
            groupId: GroupId('t1'),
            createdBy: 'sam',
            question: 'Saturday or Sunday?',
            options: [
              PollOption(id: '0', text: 'Saturday'),
              PollOption(id: '1', text: 'Sunday'),
            ],
          ),
        );
      final messages = FakeMessageRepository([
        Message(
          id: 'p1',
          groupId: const GroupId('t1'),
          authorId: 'sam',
          authorName: 'Sam Rivera',
          type: MessageType.poll,
          text: 'Saturday or Sunday?',
          pollId: 'p1',
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
      ]);
      final members = FakeMemberRepository([
        testMembership('a', 'boss', role: MemberRole.owner),
      ]);
      await open(
        tester,
        '/g/t1/chat',
        messageRepo: messages,
        pollRepo: polls,
        memberRepo: members,
        size: const Size(400, 1000),
      );
      expect(find.textContaining('Viewing as super admin'), findsOneWidget);
      // The newest message is on screen, which marks a member's chat read
      // (CHAT-9); a super admin has no marker on this team.
      expect(find.text('Saturday or Sunday?'), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(members.reads, isEmpty);

      await tester.tap(find.text('Sunday'));
      await tester.pumpAndSettle();
      expect(polls.votes, isEmpty);
    });

    testWidgets('documents can be deleted, not added', (tester) async {
      final docs = FakeDocumentRepository([
        Document(
          id: const DocumentId('d1'),
          groupId: const GroupId('t1'),
          kind: DocumentKind.link,
          name: 'Bad link',
          url: 'https://spam.example.com',
          uploadedBy: 'sam',
          uploaderName: 'Sam Rivera',
          createdAt: now,
        ),
      ]);
      await open(tester, '/g/t1/documents', documentRepo: docs);
      expect(find.textContaining('Viewing as super admin'), findsOneWidget);
      expect(find.text('Bad link'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.byTooltip('Document actions'));
      await tester.pumpAndSettle();
      expect(find.text('Report'), findsNothing);
      expect(find.text('Pin'), findsNothing);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete document'));
      await tester.pumpAndSettle();
      expect(find.text('Bad link'), findsNothing);
    });

    testWidgets("members of a suspended team are told so; they can't read it", (
      tester,
    ) async {
      await open(
        tester,
        '/g/t9/chat',
        user: coach,
        memberRepo: FakeMemberRepository([
          testMembership('a', 'coach'),
          testMembership('t9', 'coach'),
        ]),
      );
      expect(find.text('This team has been suspended.'), findsOneWidget);
    });

    testWidgets('a suspended team is never a dead end: other teams, Settings, '
        'and Sign out are there, and the app opens on a readable team', (
      tester,
    ) async {
      final memberRepo = FakeMemberRepository([
        testMembership('a', 'coach'),
        testMembership('t9', 'coach'),
      ]);
      await open(tester, '/g/t9/chat', user: coach, memberRepo: memberRepo);
      expect(find.text('This team has been suspended.'), findsOneWidget);
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home team'));
      await tester.pumpAndSettle();
      expect(find.text('This team has been suspended.'), findsNothing);
      expect(find.text('Home team'), findsWidgets);

      // Remembered on the suspended team: '/' skips it.
      final prefs = FakeLocalPrefs()..lastTeamRoute = '/g/t9/schedule';
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        prefs: prefs,
        groupRepo: FakeGroupRepository({'a': testGroup('a', 'Home team')}),
        memberRepo: FakeMemberRepository([
          testMembership('a', 'coach'),
          testMembership('t9', 'coach'),
        ]),
        size: wide,
      );
      await tester.pumpAndSettle();
      expect(find.text('This team has been suspended.'), findsNothing);
      expect(
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        '/g/a/chat',
      );
    });

    testWidgets('members see the team again once it is unsuspended', (
      tester,
    ) async {
      Future<FakeGroupRepository> suspended() async {
        final groups = FakeGroupRepository({'a': testGroup('a', 'Home team')});
        await open(
          tester,
          '/g/t9/chat',
          user: coach,
          groupRepo: groups,
          memberRepo: FakeMemberRepository([
            testMembership('a', 'coach'),
            testMembership('t9', 'coach'),
          ]),
        );
        expect(find.text('This team has been suspended.'), findsOneWidget);
        // Lifted. Nothing tells members' devices: their read was refused
        // and ended.
        groups.groups['t9'] = testGroup('t9', 'Storm');
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('This team has been suspended.'), findsOneWidget);
        return groups;
      }

      // It's read again after a wait...
      await suspended();
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('This team has been suspended.'), findsNothing);
      expect(find.text('Storm'), findsWidgets);

      // ...or when the app comes back to the foreground.
      await suspended();
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pumpAndSettle();
      expect(find.text('This team has been suspended.'), findsNothing);
      expect(find.text('Storm'), findsWidgets);
    });

    testWidgets("members and other users don't get it", (tester) async {
      await open(tester, '/g/t1/chat', user: coach);
      expect(find.text("You're not a member of this team."), findsOneWidget);
      expect(find.textContaining('Viewing as super admin'), findsNothing);
    });
  });
}
