import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/domain/play_test.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/contrast.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// #52: Google Play's test accounts, labeled "Play test" on the admin Users
/// page and the user's own page, and never treated differently (ADMIN-4).
void main() {
  group('likelyPlayTestAccount', () {
    // The same cases as Functions' test/unit/play_test.test.ts, since the
    // two copies of the rule must match.
    test("knows Google's test lab and Gmail shaped like name.12345", () {
      for (final email in [
        'jane.48213@gmail.com',
        'x@cloudtestlabaccounts.com',
        'JANE.48213@GMAIL.COM',
        ' jane.48213@gmail.com ',
      ]) {
        expect(likelyPlayTestAccount(email), isTrue, reason: email);
      }
    });

    test('leaves everyone else alone', () {
      for (final email in [
        'jane48213@gmail.com',
        'jane.4821@gmail.com',
        'jane.482131@gmail.com',
        'jane.48213@yahoo.com',
        'jane.smith@gmail.com',
        'jane.48213@gmail.com.example',
        '',
        null,
      ]) {
        expect(likelyPlayTestAccount(email), isFalse, reason: email);
      }
    });
  });

  const boss = AuthUser(
    uid: 'boss',
    email: 'boss@example.com',
    displayName: 'Bea Boss',
    emailVerified: true,
    isSuperAdmin: true,
  );
  final joined = DateTime.now().subtract(const Duration(days: 3));
  AdminUserRow person(String uid, String name, String email) => AdminUserRow(
    uid: UserId(uid),
    displayName: name,
    email: email,
    createdAt: joined,
  );
  final jane = person('jane', 'Jane Doe', 'jane.48213@gmail.com');
  final sam = person('sam', 'Sam Rivera', 'sam@example.com');

  Future<void> open(
    WidgetTester tester,
    String path, {
    Size size = const Size(1280, 1000),
    TeamScheme scheme = TeamScheme.dark,
  }) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: boss),
      prefs: FakeLocalPrefs()..defaultSchemeValue = scheme,
      admin: FakeAdminRepository(
        users: [jane, sam],
        userDetails: {
          for (final u in [jane, sam])
            u.uid.value: AdminUserDetail(
              user: u,
              signInMethods: const ['google.com'],
            ),
        },
      ),
      size: size,
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
  }

  /// The tag in the same row or run as [name].
  Finder tagBeside(String name) => find.descendant(
    of: find
        .ancestor(
          of: find.text(name),
          matching: find.byWidgetPredicate((w) => w is Row || w is Wrap),
        )
        .first,
    matching: find.text('Play test'),
  );

  testWidgets('the Users table tags a likely Play test account, and only '
      'that one', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, '/admin/users');
    expect(find.text('Play test'), findsOneWidget);
    expect(tagBeside('Jane Doe'), findsOneWidget);
    expect(tagBeside('Sam Rivera'), findsNothing);
    // Heard with its row.
    expect(
      find.bySemanticsLabel(RegExp('likely Google Play test account')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('so do the phone rows', (tester) async {
    await open(tester, '/admin/users', size: const Size(390, 900));
    expect(find.byType(DataTable), findsNothing);
    expect(tagBeside('Jane Doe'), findsOneWidget);
    expect(find.text('Play test'), findsOneWidget);
  });

  testWidgets("the user's own page says it isn't blocked; others say "
      'nothing', (tester) async {
    await open(tester, '/admin/users/jane');
    expect(find.text('Play test'), findsOneWidget);
    expect(
      find.text("Likely a Google Play test account. It isn't blocked."),
      findsOneWidget,
    );
    await open(tester, '/admin/users/sam');
    expect(find.text('Play test'), findsNothing);
    expect(find.textContaining('Google Play'), findsNothing);
  });

  testWidgets('reads well: the tag in all seven schemes, and 200% text', (
    tester,
  ) async {
    for (final scheme in bootCampSchemes) {
      for (final path in ['/admin/users', '/admin/users/jane']) {
        await open(tester, path, scheme: scheme, size: const Size(390, 900));
        final handle = tester.ensureSemantics();
        await expectLater(tester, meetsGuideline(textContrast));
        handle.dispose();
      }
    }
    // 480 for the list, still the phone layout: in the test font, whose
    // letters are all 1 em wide, the Sort by menu alone outgrows a phone at
    // 200%; with the app's fonts it fits at 320 (looked at, #52).
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final (path, width) in [
      ('/admin/users', 480.0),
      ('/admin/users/jane', 320.0),
    ]) {
      await open(tester, path, size: Size(width, 900));
      expect(tester.takeException(), isNull, reason: path);
      expect(find.text('Play test'), findsOneWidget, reason: path);
    }
  });
}
