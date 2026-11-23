import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/contrast.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// #66 (owner's report 2026-11-18): the super admins' Dashboard totals as
/// cards across the page, in the look of the team cards on Teams: one
/// column on a phone, two or three on wider screens, the number at each
/// card's end, and waiting reports in the warning red (ADMIN-1).
void main() {
  const boss = AuthUser(
    uid: 'boss',
    email: 'boss@example.com',
    displayName: 'Bea Boss',
    emailVerified: true,
    isSuperAdmin: true,
  );

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    int reports = 0,
    TeamScheme scheme = TeamScheme.dark,
  }) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: boss),
      prefs: FakeLocalPrefs()..defaultSchemeValue = scheme,
      admin: FakeAdminRepository(
        totalsValue: AdminTotals(
          users: 48,
          teams: 23,
          newTeams: 4,
          activeTeams: 3,
          messages: 1312,
          storageBytes: 1024,
          openReports: reports,
        ),
      ),
      size: size,
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/admin');
    await tester.pumpAndSettle();
  }

  Rect card(WidgetTester tester, String label) => tester.getRect(
    find.ancestor(of: find.text(label), matching: find.byType(Material)).first,
  );

  testWidgets('on a phone each total is a card across the page, its number '
      'at the end', (tester) async {
    await open(tester);
    final users = card(tester, 'Users');
    expect(users.width, greaterThan(390 - 2 * 24));
    // The number sits at the row's end, right of its label.
    expect(
      tester.getRect(find.text('48')).left,
      greaterThan(tester.getRect(find.text('Users')).right),
    );
    expect(users.right - tester.getRect(find.text('48')).right, lessThan(60));
    // Every card the page's width, one under the other.
    expect(card(tester, 'Open reports').width, users.width);
    expect(card(tester, 'Teams').top, greaterThan(users.bottom));
  });

  for (final (width, columns) in [(700.0, 2), (1280.0, 3)]) {
    testWidgets('$columns columns at ${width.round()} px', (tester) async {
      await open(tester, size: Size(width, 900));
      // Labels only the cards have (the rail says Users and Teams too).
      final labels = ['New teams', 'Active teams', 'Messages', 'Storage'];
      final tops = [for (final l in labels) card(tester, l).top];
      if (columns == 2) {
        // New teams and Active teams share the second line.
        expect(tops[1], tops[0]);
        expect(tops[2], greaterThan(tops[0]));
      } else {
        // Active teams, Messages and Storage share the second line.
        expect(tops[2], tops[1]);
        expect(tops[3], tops[1]);
        expect(tops[1], greaterThan(tops[0]));
      }
    });
  }

  testWidgets('waiting reports stand out in the warning red; none, they '
      "don't", (tester) async {
    await open(tester, reports: 5);
    Color? numberColor(String value) =>
        tester.widget<Text>(find.text(value)).style?.color;
    // Salmon in an ink outline (#85).
    expect(numberColor('5'), CampPalette.cantGo);
    await open(tester);
    expect(numberColor('0'), isNot(CampPalette.cantGo));
  });

  testWidgets('a row with a list opens it, with a chevron; the others have '
      'none', (tester) async {
    await open(tester);
    Finder chevronIn(String label) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Row)).last,
      matching: find.byIcon(AppIcons.chevronRight),
    );
    expect(chevronIn('Users'), findsOneWidget);
    expect(chevronIn('New teams'), findsNothing);
    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(Scaffold).first)).state.uri.path,
      '/admin/users',
    );
  });

  testWidgets('reads well: contrast and targets in every scheme, and '
      '200% text, the number under its label', (tester) async {
    for (final scheme in bootCampSchemes) {
      await open(tester, scheme: scheme, reports: 2);
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel('Users: 48. Every account.'),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(textContrast));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    }
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, size: const Size(320, 1600));
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.text('48')).top,
      greaterThanOrEqualTo(tester.getRect(find.text('Users')).bottom - 1),
    );
  });
}
