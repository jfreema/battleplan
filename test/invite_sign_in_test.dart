import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/presentation/sign_in_screen.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

// Sign-in that shows the team you're joining (#24; SPEC AUTH-1, AUTH-5,
// INV-5 step 2).
void main() {
  Future<void> go(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
  }

  const signInLine = 'Join Thunder: sign in or create a free account';

  test("the invite code comes out of sign-in's way back to an invite", () {
    expect(inviteCodeFromReturn('/join/K7XPM2QR?join=1'), 'K7XPM2QR');
    expect(inviteCodeFromReturn('/join/K7XPM2QR'), 'K7XPM2QR');
    // The code box, anywhere else, or nothing: no invite.
    expect(inviteCodeFromReturn('/join'), isNull);
    expect(inviteCodeFromReturn('/g/a/chat'), isNull);
    expect(inviteCodeFromReturn('/join/K7XPM2QR/more'), isNull);
    expect(inviteCodeFromReturn(null), isNull);
  });

  testWidgets('Sign in to join shows the team on sign-in and sign-up, '
      'then joins after Google', (tester) async {
    final invites = FakeInviteRepository()
      ..previewed = const InvitePreview(
        groupId: 'a',
        name: 'Thunder',
        sport: Sport.softball,
        memberCount: 12,
        logoUrl: 'https://example.com/logo.jpg',
      );
    await pumpApp(
      tester,
      auth: FakeAuthRepository(),
      groups: {'a': testGroup('a', 'Thunder')},
      invites: invites,
    );
    await go(tester, '/join/K7XPM2QR');
    await tester.tap(find.text('Sign in to join'));
    await tester.pumpAndSettle();

    // The team's badge and what happens next, above the buttons.
    expect(find.text(signInLine), findsOneWidget);
    final badge = tester.widget<TeamBadge>(find.byType(TeamBadge));
    expect(badge.imageUrl, 'https://example.com/logo.jpg');
    // Screen readers hear the line once, not the badge's name too.
    expect(find.bySemanticsLabel('Thunder'), findsNothing);

    // Sign-up says the same line, in place of its own title.
    await tester.tap(find.text("New here? Sign up, it's free"));
    await tester.pumpAndSettle();
    expect(find.text(signInLine), findsOneWidget);
    expect(find.text('Create your free account'), findsNothing);

    await tester.tap(find.text('Sign up with Google'));
    await tester.pumpAndSettle();
    expect(invites.redeemed, ['K7XPM2QR']);
  });

  testWidgets('a new account sees the team on setup, then joins', (
    tester,
  ) async {
    final invites = FakeInviteRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(),
      users: FakeUserRepository(needsSetup: true),
      invites: invites,
    );
    await go(tester, '/join/K7XPM2QR');
    await tester.tap(find.text('Sign in to join'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('set up your profile'), findsOneWidget);
    expect(
      find.text("Finish setting up, then you'll join Thunder"),
      findsOneWidget,
    );
    await tester.tap(find.text("I'm 18 or older"));
    await tester.tap(find.textContaining('I agree to the Terms'));
    await tester.pumpAndSettle();
    final next = find.widgetWithText(FilledButton, 'Continue');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(invites.redeemed, ['K7XPM2QR']);
  });

  testWidgets('plain sign-in has no team, and says Google and Apple make an '
      'account', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    expect(find.byType(TeamBadge), findsNothing);
    expect(find.textContaining('sign in or create'), findsNothing);
    expect(
      find.text('First time? Google and Apple also create your free account.'),
      findsOneWidget,
    );
    // The sign-up page's buttons already say Sign up.
    await go(tester, '/sign-up');
    expect(find.textContaining('also create'), findsNothing);
    expect(find.text('Create your free account'), findsOneWidget);
  });

  testWidgets('with Apple hidden, the line names Google alone', (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const SignInScreen())],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue with Apple'), findsNothing);
    expect(
      find.text('First time? Google also creates your free account.'),
      findsOneWidget,
    );
  });

  testWidgets("an invite that can't be used leaves sign-in plain", (
    tester,
  ) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    final back = Uri.encodeComponent('/join/NOPE1234?join=1');
    await go(tester, '/sign-in?from=$back');
    expect(find.byType(TeamBadge), findsNothing);
    expect(find.textContaining('sign in or create'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('the team line fits a small phone at 200% text', (tester) async {
    final invites = FakeInviteRepository()
      ..previewed = const InvitePreview(
        groupId: 'a',
        name: 'Riverside Sluggers 12U Travel',
        sport: Sport.baseball,
        memberCount: 12,
      );
    await pumpApp(
      tester,
      auth: FakeAuthRepository(),
      invites: invites,
      size: const Size(320, 640),
    );
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final back = Uri.encodeComponent('/join/K7XPM2QR?join=1');
    await go(tester, '/sign-in?from=$back');
    expect(tester.takeException(), isNull);
    expect(
      find.text(
        'Join Riverside Sluggers 12U Travel: sign in or create a free account',
      ),
      findsOneWidget,
    );
  });
}
