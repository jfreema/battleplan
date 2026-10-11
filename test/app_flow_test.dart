import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
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

  testWidgets('signed out lands on sign-in with the four options', (
    tester,
  ) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
  });

  testWidgets(
    'email sign-in reaches the welcome screen when there are no teams',
    (tester) async {
      await pumpApp(tester, auth: FakeAuthRepository());
      await tester.tap(find.text('Continue with email'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'coach@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Battleplan'), findsOneWidget);
    },
  );

  testWidgets('email sign-in opens the team when there is one', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach')],
    );
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'coach@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Thunder'), findsOneWidget);
    expect(find.text('Welcome to Battleplan'), findsNothing);
  });

  testWidgets('Google sign-in reaches the app', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Battleplan'), findsOneWidget);
  });

  testWidgets('cancelling Google sign-in stays on sign-in with no error', (
    tester,
  ) async {
    await pumpApp(tester, auth: FakeAuthRepository()..googleCancels = true);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.textContaining('went wrong'), findsNothing);
  });

  testWidgets('wrong password shows an error and stays put', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'coach@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'nope');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.textContaining("don't match"), findsOneWidget);
  });

  testWidgets('a member opens their most recent team on the Chat tab', (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {
        'a': testGroup('a', 'Thunder', lastMessageAt: DateTime(2026, 10)),
        'b': testGroup('b', 'Lightning U10', lastMessageAt: DateTime(2026, 9)),
      },
      memberships: [
        testMembership('b', 'coach'),
        testMembership('a', 'coach', role: MemberRole.owner),
      ],
    );
    expect(find.text('Thunder'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(
      find.text('Messages for this team will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('switching teams keeps the current tab', (tester) async {
    final prefs = await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {
        'a': testGroup('a', 'Thunder', lastMessageAt: DateTime(2026, 10)),
        'b': testGroup('b', 'Lightning U10', lastMessageAt: DateTime(2026, 9)),
      },
      memberships: [testMembership('a', 'coach'), testMembership('b', 'coach')],
    );
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(prefs.lastTeamRoute, '/g/a/schedule');

    await tester.tap(find.text('Thunder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lightning U10'));
    await tester.pumpAndSettle();
    expect(prefs.lastTeamRoute, '/g/b/schedule');
    expect(
      find.text('Practices, games, and RSVPs will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('the theme switch applies at once and is remembered', (
    tester,
  ) async {
    final prefs = await pumpApp(tester, auth: FakeAuthRepository(user: coach));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(prefs.themePreference, ThemePreference.dark);
  });
}
