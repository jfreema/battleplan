// The top of the app and a team's way back to it (SPEC §5.1, §5.2):
// Teams and Profile with their tabs, the back arrow on a team's page, and
// Team settings and the Team tab in place of the team and account menus.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/presentation/composer.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/shell_parts.dart';
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
  final teams = {
    'a': testGroup(
      'a',
      'Thunder',
      lastMessageAt: DateTime(2026, 10, 20),
    ).copyWith(lastMessagePreview: 'Sam: Field 3 is open'),
    'b': testGroup('b', 'Cyclone'),
  };
  final memberships = [
    testMembership('a', 'coach', role: MemberRole.admin),
    testMembership('b', 'coach'),
  ];

  Future<void> go(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
  }

  testWidgets("a team's back arrow goes to Teams, which lists my teams and "
      'opens one where I left it', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams,
      memberships: memberships,
    );
    // In a team: its schedule.
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Teams'), findsWidgets);
    expect(find.text('Thunder'), findsOneWidget);
    expect(find.text('Cyclone'), findsOneWidget);
    expect(find.text('Sam: Field 3 is open'), findsOneWidget);
    expect(find.text('Join a Team or Group'), findsOneWidget);
    expect(find.text('Create a Team'), findsOneWidget);
    // The inbox and notifications cover every team, so they're here too.
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.byType(OpenFieldTabBar), findsOneWidget);

    // Thunder opens where I was; Cyclone at its chat.
    await tester.tap(find.text('Thunder'));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(Scaffold).first)).state.uri.path,
      '/g/a/schedule',
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cyclone'));
    await tester.pumpAndSettle();
    expect(find.byType(Composer), findsOneWidget);
  });

  testWidgets("inside a tab, the page's own back button is the only one", (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams,
      memberships: memberships,
    );
    expect(find.byTooltip('Back'), findsOneWidget);
    await go(tester, '/g/a/plays/saved');
    expect(find.text('Saved plays'), findsOneWidget);
    // Saved plays' own, back to the whiteboard.
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Saved plays'), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('the app opens on Teams when I left it there, else in my '
      'last team', (tester) async {
    final prefs = FakeLocalPrefs()..lastTeamRoute = '/teams';
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams,
      memberships: memberships,
      prefs: prefs,
    );
    expect(find.text('Join a Team or Group'), findsOneWidget);
    await tester.tap(find.text('Cyclone'));
    await tester.pumpAndSettle();
    expect(prefs.lastTeamRoute, '/g/b/chat');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    // Profile counts as Teams.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(prefs.lastTeamRoute, '/teams');
  });

  testWidgets('archived teams wait under Archived, which opens and closes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {
        ...teams,
        'c': testGroup(
          'c',
          'Spring Storm',
        ).copyWith(archivedAt: DateTime(2026, 6)),
      },
      memberships: [...memberships, testMembership('c', 'coach')],
    );
    await go(tester, '/teams');
    expect(find.text('Thunder'), findsOneWidget);
    expect(find.text('Spring Storm'), findsNothing);
    // How many, and that it opens.
    expect(
      tester.getSemantics(find.text('Archived')),
      isSemantics(
        label: 'Archived\n1',
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
      ),
    );
    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(find.text('Spring Storm'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Archived')),
      isSemantics(hasExpandedState: true, isExpanded: true),
    );
    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(find.text('Spring Storm'), findsNothing);
    handle.dispose();
  });

  testWidgets('Teams welcomes someone with no team yet', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository(user: coach));
    expect(find.text('Welcome to Battleplan'), findsOneWidget);
    expect(find.text('Join a Team or Group'), findsOneWidget);
    expect(find.text('Create a Team'), findsOneWidget);
    // The old welcome page's address lands here too.
    await go(tester, '/welcome');
    expect(find.text('Welcome to Battleplan'), findsOneWidget);
    await tester.tap(find.text('Create a Team'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateTeamScreen), findsOneWidget);
  });

  testWidgets("Team settings takes the team menu's place, and the account "
      'button is gone: Profile has what it held', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams,
      memberships: memberships,
    );
    expect(find.byTooltip('Team menu'), findsNothing);
    expect(find.byTooltip('Account'), findsNothing);
    // The header's gear, not an ⓘ.
    expect(
      find.descendant(
        of: find.byTooltip('Team settings'),
        matching: find.byIcon(AppIcons.settings),
      ),
      findsOneWidget,
    );
    await openTeamSettings(tester);
    expect(find.text('Team settings'), findsOneWidget);
    expect(find.text('Soccer · 3 members'), findsOneWidget);
    for (final row in [
      'Just for you',
      'Notifications for this team',
      'Color scheme',
      'Calendar link',
      'For admins',
      'Admin settings',
      'Media',
      'Reports',
      'Import',
    ]) {
      expect(find.text(row), findsOneWidget, reason: row);
    }
    // Only settings: the roster, Invite and Dues are on the Team tab.
    for (final row in ['Roster', 'Invite', 'Dues']) {
      expect(find.text(row), findsNothing, reason: row);
    }
    // The team's own settings, behind Admin settings.
    await tester.tap(find.text('Admin settings'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Admin settings'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await openTeamTab(tester);
    expect(find.text('TEAM ROSTER'), findsOneWidget);
    expect(find.text('Invite'), findsOneWidget);
    expect(find.text('Dues'), findsOneWidget);
  });

  testWidgets("a member's Team settings has no admin rows", (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams,
      memberships: memberships,
      prefs: FakeLocalPrefs()..lastTeamRoute = '/g/b/chat',
    );
    await openTeamSettings(tester);
    expect(find.text('Just for you'), findsOneWidget);
    expect(find.text('Notifications for this team'), findsOneWidget);
    expect(find.text('For admins'), findsNothing);
    expect(find.text('Admin settings'), findsNothing);
    expect(find.text('Media'), findsNothing);
  });

  testWidgets('Profile: Your icon, Name in a dialog, Time zone, Settings, '
      'and Sign out, as rows', (tester) async {
    final users = FakeUserRepository();
    final auth = FakeAuthRepository(user: coach);
    await pumpApp(
      tester,
      auth: auth,
      groups: teams,
      memberships: memberships,
      users: users,
    );
    await openProfile(tester);
    expect(find.text('Your icon'), findsOneWidget);
    expect(find.text('Themes'), findsNothing);
    expect(find.text('Admin panel'), findsNothing);
    // The name my teams see, in a dialog, saved when it changes.
    await tester.tap(find.text('Your name'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Save');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Coach Jordan');
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(users.savedName, 'Coach Jordan');
    expect(find.text('Profile saved.'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-in methods'), findsOneWidget);
    expect(find.text('Appearance'), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
  });

  testWidgets('Your icon saves a color, and shows the hashed one as picked '
      'until then (SET-8)', (tester) async {
    final users = FakeUserRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams,
      memberships: memberships,
      users: users,
    );
    await openProfile(tester);
    await tester.tap(find.text('Your icon'));
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    // Exactly one color shows as picked: the hashed one.
    const colors = [
      'Blue raspberry',
      'Lemon',
      'Mint',
      'Grape',
      'Bubblegum',
      'Tangerine',
      'Cherry',
    ];
    final picked = [
      for (final name in colors)
        if (tester
                .getSemantics(find.bySemanticsLabel(name))
                .flagsCollection
                .isSelected
                .toBoolOrNull() ==
            true)
          name,
    ];
    expect(picked, hasLength(1));
    await tester.tap(find.bySemanticsLabel('Grape'));
    await tester.pumpAndSettle();
    expect(users.avatarColor, AvatarColor.grape);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Grape')),
      isSemantics(isSelected: true, isButton: true),
    );
    // The preview in chat, and Profile's row, say so too.
    expect(find.text('See everyone Saturday!'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Grape'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets("Your icon's colors keep their 48 px tap areas on any phone: "
      'one row reaching into the gutters, or two rows', (tester) async {
    for (final (width, rows) in [(390.0, 1), (360.0, 1), (320.0, 2)]) {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: memberships,
        users: FakeUserRepository(),
        size: Size(width, 780),
      );
      await go(tester, '/profile/icon');
      final rects = [
        for (final name in ['Blue raspberry', 'Mint', 'Cherry'])
          tester.getRect(find.bySemanticsLabel(name)),
      ];
      for (final r in rects) {
        expect(r.width, moreOrLessEquals(48), reason: '$width');
        expect(r.height, moreOrLessEquals(48), reason: '$width');
        // Inside the screen, 8 px or more from its edges.
        expect(r.left, greaterThanOrEqualTo(8), reason: '$width');
        expect(r.right, lessThanOrEqualTo(width - 8), reason: '$width');
      }
      final tops = {for (final r in rects) r.top};
      expect(tops, hasLength(rows), reason: '$width');
    }
  });

  testWidgets('Your icon adds a photo, then changes or removes it (SET-1)', (
    tester,
  ) async {
    final users = FakeUserRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams,
      memberships: memberships,
      users: users,
    );
    await openProfile(tester);
    await tester.tap(find.text('Your icon'));
    await tester.pumpAndSettle();
    expect(find.text('Add a photo'), findsOneWidget);
    expect(find.text('Remove photo'), findsNothing);
    users
      ..photoPath = 'users/coach/avatar/1.jpg'
      ..changed();
    await tester.pumpAndSettle();
    expect(find.text('Change photo'), findsOneWidget);
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    expect(users.photosRemoved, 1);
    expect(find.text('Add a photo'), findsOneWidget);
  });

  // The God admin panel one tap from where a super admin is (SPEC §6.11
  // Access, owner's request 2026-11-07), and nothing new for anyone else.
  group('the Admin panel', () {
    final boss = coach.copyWith(isSuperAdmin: true);
    const wide = Size(1280, 800);
    String path(WidgetTester tester) =>
        GoRouter.of(tester.element(find.byType(Scaffold).first)).state.uri.path;
    Future<void> pump(WidgetTester tester, AuthUser user, {Size? size}) =>
        pumpApp(
          tester,
          auth: FakeAuthRepository(user: user),
          groups: teams,
          memberships: memberships,
          size: size ?? const Size(400, 1600),
        );

    testWidgets("on a phone it's in a team's header on every tab, before "
        'Messages, and opens over the team', (tester) async {
      await pump(tester, boss);
      for (final tab in ['Chat', 'Schedule', 'Documents', 'Plays']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        final button = find.byTooltip('Admin panel');
        expect(button, findsOneWidget, reason: tab);
        expect(
          tester.getCenter(button).dx,
          lessThan(tester.getCenter(find.byTooltip('Messages')).dx),
          reason: tab,
        );
        // A 48 px tap target, as the header's other icons.
        expect(tester.getSize(button), const Size(48, 48), reason: tab);
      }
      await tester.tap(find.text('Chat').last);
      await tester.pumpAndSettle();

      // One tap: the dashboard, over the team.
      await tester.tap(find.byTooltip('Admin panel'));
      await tester.pumpAndSettle();
      expect(path(tester), '/admin');
      expect(find.text('Dashboard'), findsWidgets);
      // Back (the system's) comes back to the team.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(path(tester), '/g/a/chat');
    });

    testWidgets("on a phone it's in the Teams header, and still on Profile", (
      tester,
    ) async {
      await pump(tester, boss);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(path(tester), '/teams');
      final button = find.byTooltip('Admin panel');
      expect(button, findsOneWidget);
      expect(
        tester.getCenter(button).dx,
        lessThan(tester.getCenter(find.byTooltip('Messages')).dx),
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(path(tester), '/admin');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(path(tester), '/teams');

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Admin panel'), findsOneWidget);
      await tester.tap(find.text('Admin panel'));
      await tester.pumpAndSettle();
      expect(path(tester), '/admin');
    });

    testWidgets("on a wide screen it's at the rail's foot instead, on a "
        "team's tabs, Teams, and Profile", (tester) async {
      await pump(tester, boss, size: wide);
      // Not in the header: the rail has it.
      expect(find.byTooltip('Admin panel'), findsNothing);
      final rail = find.byType(OpenFieldRail);
      final link = find.descendant(
        of: rail,
        matching: find.text('Admin panel'),
      );
      expect(link, findsOneWidget);
      // Below the tabs.
      expect(
        tester.getCenter(link).dy,
        greaterThan(
          tester
              .getCenter(
                find.descendant(of: rail, matching: find.text('Plays')),
              )
              .dy,
        ),
      );
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(path(tester), '/admin');
      expect(find.text('Dashboard'), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(path(tester), '/g/a/chat');

      for (final top in ['/teams', '/profile']) {
        await go(tester, top);
        expect(find.byTooltip('Admin panel'), findsNothing, reason: top);
        final link = find.descendant(
          of: find.byType(OpenFieldRail),
          matching: find.text('Admin panel'),
        );
        expect(link, findsOneWidget, reason: top);
        await tester.tap(link);
        await tester.pumpAndSettle();
        expect(path(tester), '/admin', reason: top);
      }
    });

    testWidgets('everyone else sees none of it, on a phone or a wide screen', (
      tester,
    ) async {
      for (final size in [const Size(400, 1600), wide]) {
        await pump(tester, coach, size: size);
        for (final at in ['/g/a/chat', '/g/a/schedule', '/teams', '/profile']) {
          await go(tester, at);
          expect(find.byTooltip('Admin panel'), findsNothing, reason: at);
          expect(find.text('Admin panel'), findsNothing, reason: at);
          expect(find.byIcon(AppIcons.admin), findsNothing, reason: at);
        }
      }
    });
  });

  testWidgets("Settings' old profile page is Profile now", (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams,
      memberships: memberships,
    );
    await go(tester, '/settings/profile');
    expect(find.text('Your icon'), findsOneWidget);
    expect(find.byType(OpenFieldTabBar), findsOneWidget);
  });
}
