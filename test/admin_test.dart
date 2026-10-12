// The God admin panel (SPEC ADMIN-1 to ADMIN-8, STORE-6, SAFE-4) and what
// it changes elsewhere: the announcement banner everyone sees, and a super
// admin viewing a team's tabs.
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
    FakeDocumentRepository? documentRepo,
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
      documentRepo: documentRepo,
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
  });

  group('team detail (ADMIN-3)', () {
    Future<(FakeAdminRepository, FakeMemberRepository)> openTeam(
      WidgetTester tester, {
      Group? group,
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
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
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
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
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

    testWidgets("members and other users don't get it", (tester) async {
      await open(tester, '/g/t1/chat', user: coach);
      expect(find.text("You're not a member of this team."), findsOneWidget);
      expect(find.textContaining('Viewing as super admin'), findsNothing);
    });
  });
}
