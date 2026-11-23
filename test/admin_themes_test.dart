// The theme editor, back for Boot Camp Mix (#88, owner's request
// 2026-11-22: "can you put the theme editor back in? only available to
// super admins, of course."; SPEC ADMIN-10): Themes in the Super Admin
// Panel lists the seven schemes; each opens to every color it's drawn
// from, the games, send and alerts color first, with a preview; colors
// nearly the same as what they sit on can't be saved; what's saved is
// drawn everywhere but the panel itself.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/widgets/back_chevron.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/theme_editor_screen.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

const _boss = AuthUser(
  uid: 'boss',
  email: 'boss@example.com',
  displayName: 'Bea Boss',
  emailVerified: true,
  isSuperAdmin: true,
);
const _coach = AuthUser(
  uid: 'coach',
  email: 'coach@example.com',
  emailVerified: true,
);
const _coral = 0xFFF45B5B;

void main() {
  tearDown(() => ThemeCatalog.installCamp(const {}));

  Future<FakeAdminRepository> open(
    WidgetTester tester, {
    String path = '/admin/themes',
    AuthUser user = _boss,
    AppConfig config = const AppConfig(),
    Size size = const Size(800, 4000),
  }) async {
    final admin = FakeAdminRepository(config: config);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: user),
      admin: admin,
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', user.uid, role: MemberRole.owner)],
      size: size,
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
    return admin;
  }

  String location(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Scaffold).last)).state.uri.path;

  FilledButton save(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));

  /// Picks [hex] for [color] by its code.
  Future<void> setColor(
    WidgetTester tester,
    CampColor color,
    String hex,
  ) async {
    await tester.tap(find.byKey(ValueKey('color-${color.value}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('colorCode')), hex);
    await tester.tap(find.widgetWithText(FilledButton, 'Use'));
    await tester.pumpAndSettle();
  }

  testWidgets('Themes is in the Super Admin Panel, with the seven schemes '
      'and how many of their colors are changed', (tester) async {
    await open(
      tester,
      path: '/admin',
      // The rail of sections, as on a laptop.
      size: const Size(1280, 3000),
      config: const AppConfig(
        campThemes: {
          TeamScheme.dark: {
            CampColor.red: _coral,
            CampColor.mustard: 0xFFFDD023,
          },
        },
      ),
    );
    await tester.tap(find.text('Themes').first);
    await tester.pumpAndSettle();
    expect(location(tester), '/admin/themes');
    for (final scheme in bootCampSchemes) {
      expect(find.byKey(ValueKey('theme-${scheme.value}')), findsOneWidget);
    }
    expect(find.text('2 colors changed'), findsOneWidget);
    expect(find.text('As it ships'), findsNWidgets(6));
    await tester.tap(find.byKey(const ValueKey('theme-dark')));
    await tester.pumpAndSettle();
    expect(location(tester), '/admin/themes/dark');
  });

  testWidgets('only super admins get there; any other address goes to the '
      'list', (tester) async {
    await open(tester, user: _coach);
    expect(location(tester), isNot(startsWith('/admin')));
  });

  testWidgets("a scheme that isn't one of the seven goes to the list", (
    tester,
  ) async {
    await open(tester, path: '/admin/themes/navy');
    expect(location(tester), '/admin/themes');
  });

  testWidgets('every color is there, games, send and alerts first, and a '
      'new one saves for everyone and shows in the preview', (tester) async {
    final admin = await open(tester, path: '/admin/themes/dark');
    for (final color in CampColor.values) {
      expect(find.byKey(ValueKey('color-${color.value}')), findsOneWidget);
    }
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('color-red'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('color-page'))).dy),
    );
    expect(find.text('Games, send and alerts'), findsOneWidget);
    expect(save(tester).onPressed, isNull);
    await setColor(tester, CampColor.red, '#f45b5b');
    expect(
      tester
          .widget<CampThemePreview>(find.byType(CampThemePreview))
          .palette
          .red,
      const Color(_coral),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(admin.savedCampThemes.single.$1, TeamScheme.dark);
    expect(admin.savedCampThemes.single.$2, {CampColor.red: _coral});
    expect(find.textContaining('Everyone using Black sees'), findsOneWidget);
    expect(save(tester).onPressed, isNull);
  });

  testWidgets('a color nearly the same as what it sits on is marked on both '
      "and can't be saved", (tester) async {
    final admin = await open(tester, path: '/admin/themes/army');
    await setColor(tester, CampColor.red, '#474C2B');
    expect(
      find.text('Nearly the same color as Page. Pick one that stands apart.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Nearly the same color as Games, send and alerts. Pick one that '
        'stands apart.',
      ),
      findsWidgets,
    );
    expect(
      find.text('Fix the colors marked above, then save.'),
      findsOneWidget,
    );
    expect(save(tester).onPressed, isNull);
    expect(admin.savedCampThemes, isEmpty);
    // Back to the original: nothing's changed.
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('color-red')),
        matching: find.byTooltip('Use the original'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fix the colors marked above, then save.'), findsNothing);
    expect(save(tester).onPressed, isNull);
  });

  testWidgets("a color can come from any scheme's own, or the team colors", (
    tester,
  ) async {
    final admin = await open(tester, path: '/admin/themes/purplegold');
    await tester.tap(find.byKey(const ValueKey('color-red')));
    await tester.pumpAndSettle();
    expect(find.text("Geaux Tigahs's colors"), findsOneWidget);
    expect(find.text('Team colors'), findsOneWidget);
    // Geaux Tigahs' gold: its trim.
    await tester.tap(find.bySemanticsLabel('Trim, #FDD023').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(admin.savedCampThemes.single.$2, {CampColor.red: 0xFFFDD023});
  });

  testWidgets('a bad code says how to write one', (tester) async {
    await open(tester, path: '/admin/themes/light');
    await tester.tap(find.byKey(const ValueKey('color-red')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('colorCode')), 'coral');
    await tester.tap(find.widgetWithText(FilledButton, 'Use'));
    await tester.pumpAndSettle();
    expect(
      find.text('Use # and six digits or letters A to F, like #DB442F.'),
      findsOneWidget,
    );
  });

  testWidgets('Put back as it ships asks first, then takes them all away', (
    tester,
  ) async {
    final admin = await open(
      tester,
      path: '/admin/themes/sky',
      config: const AppConfig(
        campThemes: {
          TeamScheme.sky: {CampColor.red: _coral},
        },
      ),
    );
    expect(
      tester
          .widget<CampThemePreview>(find.byType(CampThemePreview))
          .palette
          .red,
      const Color(_coral),
    );
    await tester.tap(find.text('Put back as it ships'));
    await tester.pumpAndSettle();
    expect(find.text('Put Sky Blue back as it ships?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Put back as it ships'));
    await tester.pumpAndSettle();
    expect(admin.resetCampThemes, [TeamScheme.sky]);
    expect(find.text('Sky Blue is back as it ships.'), findsOneWidget);
    expect(find.text('Put back as it ships'), findsNothing);
  });

  testWidgets('leaving with changes asks first', (tester) async {
    await open(tester, path: '/admin/themes/candypop');
    await setColor(tester, CampColor.red, '#F45B5B');
    await tester.tap(find.byType(BackChevron));
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(location(tester), '/admin/themes/candypop');
  });

  testWidgets('what is saved is drawn in the app, but the Super Admin Panel '
      'keeps the colors as they ship', (tester) async {
    await open(
      tester,
      path: '/g/a/chat',
      config: const AppConfig(
        campThemes: {
          TeamScheme.dark: {CampColor.red: _coral},
          // Hard to read, so never drawn.
          TeamScheme.light: {CampColor.text: 0xFFF2EBE0},
        },
      ),
    );
    expect(ThemeCatalog.campThemes.keys, [TeamScheme.dark]);
    final chat = GumdropColors.of(tester.element(find.byType(Scaffold).last));
    expect(chat.roles.palette.red, const Color(_coral));
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/admin');
    await tester.pumpAndSettle();
    final panel = GumdropColors.of(tester.element(find.byType(Scaffold).last));
    expect(panel.roles.palette.red, SchemeRoles.dark.palette.red);
  });
}
