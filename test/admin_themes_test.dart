// The theme editor in the Super Admin Panel (#82, owner's request
// 2026-11-20: "make the app's default buttons and whatever is always coral
// colored, customizable for the theme ... Allow the background and the
// background of the bubbles to be changed in the theme editor and allow
// new themes to be saved"): a theme's button color, background and cards,
// a readability check before saving, new saved themes in every picker, and
// deleting or putting back.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/failure.dart';
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

  /// Opens Choose a color under [field] and picks [name].
  Future<void> chooseColor(
    WidgetTester tester,
    String field,
    String name,
  ) async {
    final choose = find.descendant(
      of: find.widgetWithText(AdminSectionCard, field),
      matching: find.text('Choose a color'),
    );
    await tester.ensureVisible(choose);
    await tester.pumpAndSettle();
    await tester.tap(choose);
    await tester.pumpAndSettle();
    final row = find.widgetWithText(ListTile, name);
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(row.first);
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
    // Gold, chosen by name from Geaux Tigahs' colors.
    await chooseColor(tester, 'Buttons and your messages', 'Gold');
    expect(preview(tester).you, const Color(0xFFFDD023));
    expect(find.text('#FDD023'), findsWidgets);
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

  testWidgets("colors nearly the same as what they sit on, or that aren't "
      "colors, can't be saved", (tester) async {
    final admin = await open(tester, '/admin/themes/army');
    // Army green's own cream type, as the background.
    await tester.enterText(hex('Background'), '#F4EAD0');
    await tester.pump();
    expect(
      find.text(
        'This is nearly the same color as the text. Pick one that stands '
        'apart from it.',
      ),
      findsOneWidget,
    );
    // Buttons the olive of the page.
    await tester.enterText(hex('Buttons and your messages'), '#474C2B');
    await tester.pump();
    expect(
      find.text(
        'This is nearly the same color as the background, the cards, or the '
        'tab bar. Pick one that stands apart.',
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

  testWidgets("the text colors save, and a text that won't read says where "
      '(#83)', (tester) async {
    final admin = await open(tester, '/admin/themes/purplegold');
    await chooseColor(tester, 'Text', 'Gold');
    expect(preview(tester).text, const Color(0xFFFDD023));
    // The card text follows the text here.
    expect(preview(tester).cardText, const Color(0xFFFDD023));
    await save(tester);
    expect(admin.savedThemes.single, (
      TeamScheme.purplegold,
      const ThemeOverride(text: 0xFFFDD023),
    ));

    // Not awaited: a push finishes when its page is closed.
    unawaited(
      GoRouter.of(tester.element(find.byType(Scaffold).last))
          .push<void>('/admin/themes/army'),
    );
    await tester.pumpAndSettle();
    // Dark text on a light page, where Army green's bars stay olive: hard
    // to read there, but not the same color, so it goes.
    await tester.enterText(hex('Background'), '#FBF5E6');
    await tester.enterText(hex('Cards and bubbles'), '#FFFFFF');
    await tester.enterText(hex('Text'), '#1A1A18');
    await tester.pump();
    expect(find.textContaining('nearly the same'), findsNothing);
    // Text the olive of Army green's tab bar.
    await tester.enterText(hex('Text'), '#3D4124');
    await tester.pump();
    expect(
      find.text(
        'This text is nearly the same color as the tab bar or text boxes, '
        "which keep Army green's colors. Pick one that stands apart from "
        'them.',
      ),
      findsOneWidget,
    );
    // Text the color of the page.
    await tester.enterText(hex('Background'), '');
    await tester.enterText(hex('Cards and bubbles'), '');
    await tester.enterText(hex('Text'), '#474C2B');
    await tester.pump();
    expect(
      find.text(
        'This text is nearly the same color as the background. Pick one that '
        'stands apart from it.',
      ),
      findsOneWidget,
    );
    // Candy Pop's own card text.
    // Not awaited: a push finishes when its page is closed.
    unawaited(
      GoRouter.of(tester.element(find.byType(Scaffold).last))
          .push<void>('/admin/themes/candypop'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(hex('Text on cards and bubbles'), '#FFFFFF');
    await tester.pump();
    expect(
      find.text(
        'This text is nearly the same color as the cards. Pick one that '
        'stands apart from them.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('every color says its name and code; one typed says the '
      'nearest name', (tester) async {
    await open(tester, '/admin/themes/wildcat');
    // The originals, by name.
    expect(find.text('Coral'), findsOneWidget);
    expect(find.text('Dark maroon'), findsOneWidget);
    expect(find.text('Wine'), findsOneWidget);
    expect(find.text('#5E1224'), findsWidgets);
    expect(
      find.text('Empty uses the original, Dark maroon (#5E1224).'),
      findsOneWidget,
    );
    await tester.enterText(hex('Buttons and your messages'), '#7F1D1D');
    await tester.pump();
    expect(find.text('Maroon'), findsOneWidget);
    await tester.enterText(hex('Buttons and your messages'), '#7E1C1D');
    await tester.pump();
    expect(find.text('Close to Maroon'), findsOneWidget);
    // Choose a color has the candies, the team colors, and each theme's.
    final choose = find
        .descendant(
          of: find.widgetWithText(AdminSectionCard, 'Background'),
          matching: find.text('Choose a color'),
        )
        .first;
    await tester.ensureVisible(choose);
    await tester.pumpAndSettle();
    await tester.tap(choose);
    await tester.pumpAndSettle();
    for (final heading in ['Candy colors', 'Team colors']) {
      expect(find.text(heading), findsOneWidget);
    }
    expect(find.widgetWithText(ListTile, 'Coral'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Maroon'), findsOneWidget);
  });

  testWidgets('a yellow background saves: only nearly the same colors are '
      'refused', (tester) async {
    final admin = await open(tester, '/admin/themes/army');
    await chooseColor(tester, 'Background', 'Gold');
    expect(find.textContaining('nearly the same'), findsNothing);
    await save(tester);
    expect(admin.savedThemes.single, (
      TeamScheme.army,
      const ThemeOverride(page: 0xFFFDD023),
    ));
  });

  testWidgets('a theme the server refuses says why', (tester) async {
    final admin = await open(tester, '/admin/themes/army');
    admin.failWith = const ActionRefused('unreadable-theme');
    await tester.enterText(hex('Buttons and your messages'), '#FDD023');
    await tester.pump();
    await save(tester);
    expect(
      find.text(
        'Some of those colors are nearly the same as what they sit on, so the '
        "theme wasn't saved.",
      ),
      findsOneWidget,
    );
    expect(path(tester), '/admin/themes/army');
  });

  testWidgets('a hard-to-read theme saved by hand is never drawn, and is '
      'listed turned off so it can be fixed', (tester) async {
    await open(
      tester,
      '/admin/themes',
      config: const AppConfig(
        themes: {
          // Army green's cream type, as its background.
          TeamScheme.army: ThemeOverride(page: 0xFFF4EAD0),
          TeamScheme.custom2: ThemeOverride(
            name: 'Fog',
            base: TeamScheme.light,
            text: 0xFFFBF5E6,
          ),
        },
      ),
    );
    expect(
      find.text(
        'Turned off: some of its colors are nearly the same. Open it to fix '
        'it.',
      ),
      findsNWidgets(2),
    );
    expect(
      GumdropColors.forScheme(TeamScheme.army).page,
      SchemeRoles.army.page,
    );
    expect(ThemeCatalog.available, isNot(contains(TeamScheme.custom2)));
  });

  testWidgets('the panel draws in my scheme as it ships, whatever a theme '
      'changed', (tester) async {
    // My default, Dark, with a deep blue page of its own.
    await open(
      tester,
      '/admin/themes',
      config: const AppConfig(
        themes: {TeamScheme.dark: ThemeOverride(page: 0xFF101828)},
      ),
    );
    final panel = GumdropColors.of(
      tester.element(find.text('Built-in themes')),
    );
    expect(panel.shipped, isTrue);
    expect(panel.page, SchemeRoles.dark.page);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor ??
          Theme.of(tester.element(find.text('Built-in themes')))
              .scaffoldBackgroundColor,
      SchemeRoles.dark.page,
    );
    // Outside it, the theme's page.
    expect(
      GumdropColors.forScheme(TeamScheme.dark).page,
      const Color(0xFF101828),
    );
  });
}
