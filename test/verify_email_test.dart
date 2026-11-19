import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// #33: creating a team needs a verified email, so the app says it before
/// anything is typed (a notice on Create a Team, a line on Welcome), checks
/// again by itself (on resume, and every 10 seconds on Create), finishes a
/// Create that waited on it, never loses what was typed when the banner
/// goes, and lets screen readers read both banners (SPEC AUTH-3, TEAM-1,
/// ADMIN-7, §7.6).
void main() {
  const pat = AuthUser(
    uid: 'pat',
    email: 'pat@example.com',
    emailVerified: false,
    providerIds: ['password'],
  );
  const google = AuthUser(
    uid: 'gg',
    email: 'gg@gmail.com',
    emailVerified: true,
    providerIds: ['google.com'],
  );

  Future<FakeGroupRepository> open(
    WidgetTester tester,
    FakeAuthRepository auth, {
    FakeAdminRepository? admin,
    TeamScheme scheme = TeamScheme.dark,
    Size size = const Size(400, 1600),
  }) async {
    final groups = FakeGroupRepository({});
    await pumpApp(
      tester,
      auth: auth,
      groupRepo: groups,
      admin: admin,
      size: size,
      prefs: FakeLocalPrefs()..defaultSchemeValue = scheme,
    );
    return groups;
  }

  Future<void> openCreate(WidgetTester tester) async {
    await tester.tap(find.text('Create a Team'));
    await tester.pumpAndSettle();
  }

  Finder createButton() => find.widgetWithText(FilledButton, 'Create a Team');

  Future<void> tapCreate(WidgetTester tester) async {
    await tester.ensureVisible(createButton());
    await tester.pumpAndSettle();
    await tester.tap(createButton());
    await tester.pumpAndSettle();
  }

  /// The app comes back to the front, as from the mail app.
  Future<void> resume(WidgetTester tester) async {
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  const notice = 'Verify your email to create a team';
  const welcomeLine =
      'To create a team, first verify your email. We sent a link to '
      'pat@example.com.';

  testWidgets('an unverified email account is told on Welcome and on Create '
      'a Team, before typing anything', (tester) async {
    await open(tester, FakeAuthRepository(user: pat));
    expect(find.text(welcomeLine), findsOneWidget);
    await openCreate(tester);
    expect(find.text(notice), findsOneWidget);
    expect(
      find.text(
        'We sent a link to pat@example.com. Open it, then come back here.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Resend email'), findsOneWidget);
    // The form is there to fill in meanwhile, and Create stays on.
    expect(find.byType(TextFormField), findsWidgets);
    expect(tester.widget<FilledButton>(createButton()).onPressed, isNotNull);
  });

  testWidgets('a group says group', (tester) async {
    await open(tester, FakeAuthRepository(user: pat));
    await tester.tap(find.text('Create a Group'));
    await tester.pumpAndSettle();
    expect(find.text('Verify your email to create a group'), findsOneWidget);
  });

  for (final (who, user) in [
    ('a verified email account', pat.copyWith(emailVerified: true)),
    ('a Google account', google),
  ]) {
    testWidgets('$who sees no line, no notice, and no banner', (tester) async {
      await open(tester, FakeAuthRepository(user: user));
      expect(find.text(welcomeLine), findsNothing);
      expect(find.textContaining('Verify your email'), findsNothing);
      await openCreate(tester);
      expect(find.text(notice), findsNothing);
      expect(find.textContaining('Verify your email'), findsNothing);
    });
  }

  testWidgets('coming back to the app checks again; verified, the banner and '
      'notice go and it says so', (tester) async {
    final auth = FakeAuthRepository(user: pat);
    await open(tester, auth);
    await openCreate(tester);
    await resume(tester);
    expect(auth.reloads, 1);
    expect(find.text(notice), findsOneWidget);

    auth.linkOpened = true;
    await resume(tester);
    expect(find.text(notice), findsNothing);
    expect(find.textContaining('Verify your email'), findsNothing);
    expect(
      find.text('Email verified. You can create your team now.'),
      findsOneWidget,
    );
    // The page keeps its "‹ Teams" through the router's refresh.
    expect(find.text('Teams'), findsOneWidget);
    // Verified: no more checks.
    final checks = auth.reloads;
    await resume(tester);
    expect(auth.reloads, checks);
  });

  testWidgets('Create a Team checks every 10 seconds while it waits, and '
      'stops when it closes', (tester) async {
    final auth = FakeAuthRepository(user: pat);
    await open(tester, auth);
    await openCreate(tester);
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    expect(auth.reloads, 2);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    expect(auth.reloads, 2);
  });

  testWidgets("Create tapped too soon checks first, says it isn't verified "
      'yet, and makes the team once verified, without another tap', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: pat);
    final groups = await open(tester, auth);
    await openCreate(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Hornets');
    await tapCreate(tester);
    // It asked the server first.
    expect(auth.reloads, 1);
    expect(groups.created, isEmpty);
    expect(
      find.text(
        "Your email isn't verified yet. Open the link we sent to "
        'pat@example.com.',
      ),
      findsOneWidget,
    );
    // No second error under the button.
    expect(find.textContaining('then tap'), findsNothing);

    // The link is opened on a computer: the next check finds it.
    auth.linkOpened = true;
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(groups.created, ['Hornets']);
    expect(groups.createRequests, hasLength(1));
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      endsWith('/invite'),
    );
    // "You can create your team now" isn't left over the made team.
    expect(
      find.text('Email verified. You can create your team now.'),
      findsNothing,
    );
  });

  testWidgets("a form changed while waiting isn't created by itself; Create "
      'is just ready', (tester) async {
    final auth = FakeAuthRepository(user: pat);
    final groups = await open(tester, auth);
    await openCreate(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Hornets');
    await tapCreate(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Hornets U12');
    auth.linkOpened = true;
    await resume(tester);
    expect(groups.created, isEmpty);
    await tapCreate(tester);
    expect(groups.created, ['Hornets U12']);
  });

  testWidgets('the banner going away rebuilds nothing under it, and typing '
      'stays', (tester) async {
    final auth = FakeAuthRepository(user: pat);
    await open(tester, auth);
    await openCreate(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Half-typed');
    final router = find.byWidgetPredicate((w) => w is Router);
    final before = tester.state(router);
    auth.linkOpened = true;
    await resume(tester);
    expect(find.textContaining('Verify your email'), findsNothing);
    // The same router, not one rebuilt in a new place (#33).
    expect(identical(tester.state(router), before), isTrue);
    expect(find.text('Half-typed'), findsOneWidget);
  });

  testWidgets("I've verified says so when it isn't yet; Resend says when to "
      'try again', (tester) async {
    final auth = FakeAuthRepository(user: pat);
    await open(tester, auth);
    await openCreate(tester);
    await tester.tap(find.widgetWithText(TextButton, "I've verified").last);
    await tester.pumpAndSettle();
    expect(
      find.text('Not verified yet. Open the link we sent to pat@example.com.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Resend email'));
    await tester.pumpAndSettle();
    expect(find.text('Sent. Check your inbox.'), findsOneWidget);
    expect(auth.verificationEmailsSent, 1);
    auth.resendFailsWith = const RateLimited();
    await tester.tap(find.widgetWithText(TextButton, 'Resend').first);
    await tester.pumpAndSettle();
    expect(find.text('Try again in a few minutes.'), findsOneWidget);
  });

  testWidgets('screen readers read both banners, the words and the buttons', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(
      tester,
      FakeAuthRepository(user: pat),
      admin: FakeAdminRepository(
        config: AppConfig(
          announcementBanner: Announcement(
            text: 'Scheduled maintenance tonight',
            severity: BannerSeverity.info,
            expiresAt: DateTime.now().add(const Duration(days: 1)),
          ),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(
        'Verify your email: we sent a link to pat@example.com.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Resend'), findsOneWidget);
    expect(find.bySemanticsLabel("I've verified"), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Scheduled maintenance tonight')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Dismiss'), findsOneWidget);
    // Each banner is announced when it appears.
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(
          'Verify your email: we sent a link to pat@example.com.',
        ),
      ),
      matchesSemantics(
        label: 'Verify your email: we sent a link to pat@example.com.',
        isLiveRegion: true,
        children: [
          matchesSemantics(
            label: 'Resend',
            isButton: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
          matchesSemantics(
            label: "I've verified",
            isButton: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        ],
      ),
    );
    handle.dispose();
  });

  testWidgets('reads well: 48 px targets and contrast in all five schemes, '
      'and 200% text at 320', (tester) async {
    for (final scheme in TeamScheme.values) {
      await open(tester, FakeAuthRepository(user: pat), scheme: scheme);
      await openCreate(tester);
      await tapCreate(tester);
      await tester.scrollUntilVisible(
        find.text(notice),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(
      tester,
      FakeAuthRepository(user: pat),
      size: const Size(320, 1400),
    );
    expect(tester.takeException(), isNull);
    await openCreate(tester);
    expect(tester.takeException(), isNull);
  });
}
