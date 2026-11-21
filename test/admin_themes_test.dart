// The theme editor in the Super Admin Panel (#82, owner's request
// 2026-11-20: "make the app's default buttons and whatever is always coral
// colored, customizable for the theme ... Allow the background and the
// background of the bubbles to be changed in the theme editor and allow
// new themes to be saved"): a theme's button color, background and cards,
// a readability check before saving, new saved themes in every picker, and
// deleting or putting back.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/features/admin/presentation/theme_editor_screen.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
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
  const tall = Size(1280, 3200);
  const nightGame = ThemeOverride(
    name: 'Night Game',
    base: TeamScheme.navy,
    accent: 0xFFFDD023,
  );

  /// Signs in as a super admin on team "a" with the settings [config],
  /// then goes to [path].
  Future<FakeAdminRepository> open(
    WidgetTester tester,
    String path, {
    AppConfig config = const AppConfig(),
    Size size = tall,
    FakeMemberRepository? members,
  }) async {
    final admin = FakeAdminRepository(config: config);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: boss),
      admin: admin,
      groupRepo: FakeGroupRepository({'a': testGroup('a', 'Home team')}),
      memberRepo:
          members ??
          FakeMemberRepository([
            testMembership('a', 'boss', role: MemberRole.owner),
          ]),
      size: size,
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
    return admin;
  }

  String path(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Scaffold).last)).state.uri.path;

  /// The color field in the section titled [title].
  Finder hex(String title) => find.descendant(
    of: find.widgetWithText(AdminSectionCard, title),
    matching: find.byType(TextField),
  );

  /// The preview's colors.
  SchemeRoles preview(WidgetTester tester) =>
      tester.widget<ThemePreview>(find.byType(ThemePreview)).roles;

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('Themes is a section of the panel, listing every built-in '
      'theme as it ships', (tester) async {
    await open(tester, '/admin');
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Themes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(path(tester), '/admin/themes');
    expect(find.text('No saved themes yet.'), findsOneWidget);
    expect(find.text('As it ships'), findsNWidgets(builtInSchemes.length));
    for (final name in ['Army green', 'Navy', 'Scoreboard']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.widgetWithText(FilledButton, 'New theme'), findsOneWidget);
  });

  testWidgets("a built-in theme's button color, saved for everyone, shows "
      'in the preview as it is typed', (tester) async {
    final admin = await open(tester, '/admin/themes');
    await tapText(tester, 'Army green');
    expect(path(tester), '/admin/themes/army');
    // Empty: the original, coral.
    expect(preview(tester).you, CandyFaces.coral);
    await tester.enterText(hex('Buttons and your messages'), '#1e90ff');
    await tester.pump();
    expect(preview(tester).you, const Color(0xFF1E90FF));
    await save(tester);
    expect(admin.savedThemes.single, (
      TeamScheme.army,
      const ThemeOverride(accent: 0xFF1E90FF),
    ));
    expect(find.text('Theme saved.'), findsOneWidget);
    expect(path(tester), '/admin/themes');
    expect(find.text('Colors changed'), findsOneWidget);
    // Everywhere Army green is drawn takes it: its main button color, and
    // its coral marks, which read on the page.
    final army = GumdropColors.forScheme(TeamScheme.army);
    expect(army.you.face, const Color(0xFF1E90FF));
    expect(army.accentMark, isNot(SchemeRoles.army.accentMark));
  });

  testWidgets('a new theme needs a name, starts from a built-in one, and '
      'then shows up in the color pickers', (tester) async {
    final admin = await open(tester, '/admin/themes');
    await tapText(tester, 'New theme');
    expect(path(tester), '/admin/themes/new');
    await save(tester);
    expect(find.text('Give the theme a name.'), findsOneWidget);
    expect(admin.savedThemes, isEmpty);

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Night');
    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Night Game',
    );
    await tester.tap(find.text('Dark').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Navy').last);
    await tester.pumpAndSettle();
    expect(preview(tester).page, SchemeRoles.navy.page);
    // A color from the row under the field.
    final gold = find.bySemanticsLabel('Use #FDD023');
    await tester.ensureVisible(gold);
    await tester.tap(gold);
    await tester.pumpAndSettle();
    expect(preview(tester).you, const Color(0xFFFDD023));
    await save(tester);
    expect(admin.savedThemes.single, (TeamScheme.custom1, nightGame));

    expect(find.text('Night Game'), findsOneWidget);
    expect(find.text('Based on Navy'), findsOneWidget);
    // In my own color pickers, after the built-in themes.
    GoRouter.of(tester.element(find.byType(Scaffold).last)).go('/g/a/scheme');
    await tester.pumpAndSettle();
    await tapText(tester, 'Night Game');
    expect(
      GumdropColors.of(tester.element(find.text('Night Game').last)).you.face,
      const Color(0xFFFDD023),
    );
  });

  testWidgets("colors that leave text unreadable, or aren't colors, can't "
      'be saved', (tester) async {
    final admin = await open(tester, '/admin/themes/army');
    // Army green's own cream type, as the background.
    await tester.enterText(hex('Background'), '#F4EAD0');
    await tester.pump();
    expect(
      find.text(
        "The text won't be easy to read on this background. Try a darker or "
        'lighter one.',
      ),
      findsOneWidget,
    );
    // Too dark for the button writing.
    await tester.enterText(hex('Buttons and your messages'), '#101010');
    await tester.pump();
    expect(
      find.text(
        "The writing on buttons won't be easy to read on this color. Try a "
        'lighter or darker one.',
      ),
      findsOneWidget,
    );
    await tester.enterText(hex('Cards and bubbles'), 'red');
    await tester.pump();
    expect(
      find.text('Use # and six digits or letters A to F, like #F45B5B.'),
      findsOneWidget,
    );
    await save(tester);
    expect(
      find.text('Fix the colors marked above, then save.'),
      findsOneWidget,
    );
    expect(admin.savedThemes, isEmpty);

    // Use the original empties a field, and the problem goes with it.
    await tester.enterText(hex('Cards and bubbles'), '');
    await tester.enterText(hex('Buttons and your messages'), '');
    await tester.pump();
    await tapText(tester, 'Use the original');
    expect(tester.widget<TextField>(hex('Background')).controller!.text, '');
    await save(tester);
    expect(admin.savedThemes.single, (TeamScheme.army, const ThemeOverride()));
  });

  testWidgets('deleting a saved theme asks first', (tester) async {
    final admin = await open(
      tester,
      '/admin/themes',
      config: const AppConfig(themes: {TeamScheme.custom1: nightGame}),
    );
    await tapText(tester, 'Night Game');
    expect(path(tester), '/admin/themes/custom1');
    expect(
      tester
          .widget<TextField>(hex('Buttons and your messages'))
          .controller!
          .text,
      '#FDD023',
    );
    await tapText(tester, 'Delete theme');
    expect(find.text('Delete Night Game?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(admin.deletedThemes, isEmpty);
    await tapText(tester, 'Delete theme');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(admin.deletedThemes, [TeamScheme.custom1]);
    expect(path(tester), '/admin/themes');
    expect(find.text('No saved themes yet.'), findsOneWidget);
  });

  testWidgets('a changed built-in theme can be put back as it ships', (
    tester,
  ) async {
    final admin = await open(
      tester,
      '/admin/themes/army',
      config: const AppConfig(
        themes: {TeamScheme.army: ThemeOverride(page: 0xFF111111)},
      ),
    );
    expect(find.text('Delete theme'), findsNothing);
    await tapText(tester, 'Put back as it ships');
    expect(find.text('Put Army green back?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Put back as it ships'));
    await tester.pumpAndSettle();
    expect(admin.deletedThemes, [TeamScheme.army]);
    expect(find.text('Theme put back.'), findsOneWidget);
  });

  testWidgets('with all twelve slots taken there is no New theme', (
    tester,
  ) async {
    await open(
      tester,
      '/admin/themes',
      config: AppConfig(
        themes: {
          for (final (i, s) in customSchemes.indexed)
            s: ThemeOverride(name: 'Theme ${i + 1}', base: TeamScheme.army),
        },
      ),
    );
    expect(find.text('New theme'), findsNothing);
    expect(
      find.text(
        'All 12 saved theme spaces are taken. Delete one to save '
        'another.',
      ),
      findsOneWidget,
    );
  });

  testWidgets("a link to a theme that's gone, or never was, says so", (
    tester,
  ) async {
    for (final id in ['custom5', 'plaid']) {
      await open(tester, '/admin/themes/$id');
      expect(find.text("That's gone, or the link is wrong."), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    }
  });

  testWidgets('a pick of a saved theme that was deleted falls back to my '
      'default', (tester) async {
    await open(
      tester,
      '/g/a/scheme',
      members: FakeMemberRepository([
        testMembership(
          'a',
          'boss',
          role: MemberRole.owner,
        ).copyWith(colorScheme: TeamScheme.custom3),
      ]),
    );
    final drawn = GumdropColors.of(tester.element(find.byType(Scaffold).last))
        .scheme;
    expect(drawn.isCustom, isFalse);
  });

  testWidgets('the editor fits a phone at twice the text size', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, '/admin/themes/new', size: const Size(390, 4000));
    expect(find.byType(ThemePreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
