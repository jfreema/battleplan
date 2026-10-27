// The top of the app and a team's way back to it (SPEC §5.1, §5.2):
// Teams and Profile with their tabs, the back arrow on a team's page, and
// Team info in place of the team and account menus.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/presentation/composer.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
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
    expect(find.text('Join a team'), findsOneWidget);
    expect(find.text('Create a team'), findsOneWidget);
    // The inbox and notifications cover every team, so they're here too.
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

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
    expect(find.text('Join a team'), findsOneWidget);
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

  testWidgets('Teams welcomes someone with no team yet', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository(user: coach));
    expect(find.text('Welcome to Battleplan'), findsOneWidget);
    expect(find.text('Join a team'), findsOneWidget);
    expect(find.text('Create a team'), findsOneWidget);
    // The old welcome page's address lands here too.
    await go(tester, '/welcome');
    expect(find.text('Welcome to Battleplan'), findsOneWidget);
    await tester.tap(find.text('Create a team'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateTeamScreen), findsOneWidget);
  });

  testWidgets("Team info takes the team menu's place, and the account "
      'button is gone: Profile has what it held', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams,
      memberships: memberships,
    );
    expect(find.byTooltip('Team menu'), findsNothing);
    expect(find.byTooltip('Account'), findsNothing);
    await tester.tap(find.byTooltip('Team info'));
    await tester.pumpAndSettle();
    expect(find.text('Team info'), findsOneWidget);
    expect(find.text('Soccer · 3 members'), findsOneWidget);
    for (final row in [
      'Roster',
      'Invite',
      'Notifications for this team',
      'Calendar link',
      'Team admin',
      'Media',
      'Reports',
      'Import',
    ]) {
      expect(find.text(row), findsOneWidget, reason: row);
    }
    // Team settings is Team admin now, its page too.
    await tester.tap(find.text('Team admin'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Team admin'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roster'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Roster'), findsOneWidget);
  });

  testWidgets("a member's Team info has no admin rows", (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams,
      memberships: memberships,
      prefs: FakeLocalPrefs()..lastTeamRoute = '/g/b/chat',
    );
    await tester.tap(find.byTooltip('Team info'));
    await tester.pumpAndSettle();
    expect(find.text('Roster'), findsOneWidget);
    expect(find.text('For admins'), findsNothing);
    expect(find.text('Team admin'), findsNothing);
    expect(find.text('Media'), findsNothing);
  });

  testWidgets('Profile: my photo and name, then Themes, Settings, and Sign '
      'out, each its own card', (tester) async {
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
    expect(find.text('Change photo'), findsOneWidget);
    expect(find.text('Admin panel'), findsNothing);
    // The name my teams see, saved when it changes.
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
    // Themes and the photo moved out of Settings.
    expect(find.text('Appearance'), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
  });

  testWidgets('super admins find the Admin panel on Profile', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach.copyWith(isSuperAdmin: true)),
      groups: teams,
      memberships: memberships,
    );
    await openProfile(tester);
    expect(find.text('Admin panel'), findsOneWidget);
  });

  testWidgets("Settings' old profile page is Profile now", (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams,
      memberships: memberships,
    );
    await go(tester, '/settings/profile');
    expect(find.text('Change photo'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
