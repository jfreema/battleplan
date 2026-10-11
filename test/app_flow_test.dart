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

  testWidgets('signed out lands on sign-in with Google, Apple, and email', (
    tester,
  ) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsNothing);
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
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
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
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
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

  testWidgets('creating an account signs the person in', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Sam Rivera');
    await tester.enterText(find.byType(TextField).at(1), 'sam@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'longenough');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Battleplan'), findsOneWidget);
    // AUTH-3: the new email account sees the verification banner.
    expect(find.textContaining('Verify your email'), findsOneWidget);
  });

  testWidgets('password reset always shows the same confirmation', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, auth: auth);
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'nobody@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset password'), findsOneWidget);
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(auth.resetEmails, ['nobody@example.com']);
    expect(find.textContaining('If an account exists'), findsOneWidget);
  });

  testWidgets('a short password is caught before sending', (tester) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, auth: auth);
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Sam Rivera');
    await tester.enterText(find.byType(TextField).at(1), 'sam@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('at least 8 characters'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('an email that already has an account says so', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Jordan');
    await tester.enterText(find.byType(TextField).at(1), 'coach@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'longenough');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('already an account'), findsOneWidget);
  });

  testWidgets('first-run setup comes first and needs both confirmations', (
    tester,
  ) async {
    final users = FakeUserRepository(needsSetup: true);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      users: users,
    );
    expect(find.textContaining('set up your profile'), findsOneWidget);
    final next = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.tap(find.text("I'm 18 or older"));
    await tester.tap(find.textContaining('I agree to the Terms'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(users.savedName, 'Jordan Coach');
    expect(find.text('Welcome to Battleplan'), findsOneWidget);
  });

  testWidgets('creating a team from the welcome screen', (tester) async {
    final groupRepo = FakeGroupRepository({});
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groupRepo,
    );
    await tester.tap(find.text('Create a team'));
    await tester.pumpAndSettle();
    expect(find.text('Team type'), findsOneWidget);
    await tester.tap(find.text('Youth team'));
    await tester.enterText(find.byType(TextFormField).first, 'Thunder U14');
    await tester.pumpAndSettle();
    final create = find.widgetWithText(FilledButton, 'Create a team');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(groupRepo.created, ['Thunder U14']);
  });

  testWidgets('a team needs a name', (tester) async {
    final groupRepo = FakeGroupRepository({});
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groupRepo,
    );
    await tester.tap(find.text('Create a team'));
    await tester.pumpAndSettle();
    final create = find.widgetWithText(FilledButton, 'Create a team');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text('Enter a team name.'), findsOneWidget);
    expect(groupRepo.created, isEmpty);
  });

  testWidgets('wrong password shows an error and stays put', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'coach@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'nope');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
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

  testWidgets('signing out of all devices asks first, then signs out', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: coach);
    final push = FakePushRepository();
    await pumpApp(tester, auth: auth, push: push);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sign out of all devices'), 100);
    await tester.tap(find.text('Sign out of all devices'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out of all devices?'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Sign out of all devices'),
    );
    await tester.pumpAndSettle();
    expect(auth.signedOutEverywhere, isTrue);
    expect(push.unregistered, 1);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('sign-in methods: the only method cannot be removed', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: coach.copyWith(providerIds: ['google.com']),
    );
    await pumpApp(tester, auth: auth);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign-in methods'));
    await tester.pumpAndSettle();
    final remove = find.widgetWithText(TextButton, 'Remove');
    expect(tester.widget<TextButton>(remove).onPressed, isNull);
    expect(find.textContaining("can't be removed"), findsOneWidget);
  });

  testWidgets('linking Google asks for a fresh sign-in, then links', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: coach.copyWith(providerIds: ['password']),
    )..needsRecentLogin = true;
    await pumpApp(tester, auth: auth);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign-in methods'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Link'));
    await tester.pumpAndSettle();
    // Linking Google needed a fresh sign-in: the password prompt appears.
    expect(find.text("Confirm it's you"), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(auth.reauthedWith, 'password');
    expect(auth.currentUser!.providerIds, contains('google.com'));
    expect(find.text('Google linked.'), findsOneWidget);
  });

  testWidgets('deleting the account confirms, signs in again, then deletes', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: coach.copyWith(providerIds: ['google.com']),
    )..needsRecentLogin = true;
    await pumpApp(tester, auth: auth);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete account'), 100);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(auth.reauthedWith, 'google.com');
    expect(auth.deleted, isTrue);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('the theme switch applies at once and is remembered', (
    tester,
  ) async {
    final users = FakeUserRepository();
    final prefs = await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      users: users,
    );
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(prefs.themePreference, ThemePreference.dark);
    expect(users.themeMode, ThemePreference.dark);
  });
}
