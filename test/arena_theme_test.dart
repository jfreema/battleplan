// Gumdrop Arena (SPEC §7.4, SET-2), the fourth theme, kept apart in
// lib/core/design/arena/ so it can come out cleanly: its preference, fonts,
// leaning gumdrops, cut cards, team colors, and where people pick it. Its
// text contrast is checked with every theme's in gumdrop_theme_test.dart.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/arena/arena_theme.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_tint.dart';
import 'package:battleplan/features/settings/presentation/theme_picker.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart';

void main() {
  test('the arena preference picks it: dark, on its violet page', () {
    expect(AppTheme.flavorOf(ThemePreference.arena), GumdropFlavor.arena);
    final t = AppTheme.forPreference(ThemePreference.arena);
    expect(t.brightness, Brightness.dark);
    expect(t.scaffoldBackgroundColor, arenaColors.page);
    expect(t.extension<GumdropColors>()!.flavor, GumdropFlavor.arena);
    expect(t.extension<GumdropStyle>(), same(arenaStyle));
    // The other themes have Gumdrop Pop's style.
    expect(
      AppTheme.of(GumdropFlavor.dark).extension<GumdropStyle>(),
      same(GumdropStyle.gumdrop),
    );
  });

  test('headings and labels are the condensed italic, over one shadow', () {
    final t = AppTheme.of(GumdropFlavor.arena).textTheme;
    for (final style in [t.headlineMedium!, t.titleLarge!, t.labelLarge!]) {
      expect(style.fontFamily, arenaFont);
      expect(style.fontWeight, FontWeight.w800);
      expect(style.fontStyle, FontStyle.italic);
    }
    expect(t.headlineMedium!.shadows, [
      Shadow(color: arenaColors.headingShadow, offset: const Offset(3, 3)),
    ]);
    // Body text stays Nunito, upright.
    expect(t.bodyLarge!.fontFamily, AppFonts.body);
    expect(t.bodyLarge!.fontStyle, isNot(FontStyle.italic));
    // A label styled by hand takes the theme's font too.
    expect(
      arenaStyle.label(const TextStyle(fontWeight: FontWeight.w600)),
      const TextStyle(
        fontFamily: arenaFont,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
      ),
    );
    expect(
      GumdropStyle.gumdrop
          .label(const TextStyle(fontWeight: FontWeight.w600))
          .fontWeight,
      FontWeight.w600,
    );
    expect(fontLicenseAssets[arenaFont], contains('barlow_condensed'));
  });

  test('its gumdrops lean with small corners, and cards have two cut', () {
    GumdropShape button(ThemeData t) =>
        t.filledButtonTheme.style!.shape!.resolve({})! as GumdropShape;
    final arena = AppTheme.of(GumdropFlavor.arena);
    expect(button(arena).slant, 11);
    expect(button(arena).radius, const BorderRadius.all(Radius.circular(7)));
    expect(
      (arena.chipTheme.shape! as WidgetStateOutlinedBorder).resolve({}),
      isA<GumdropShape>().having((s) => s.slant, 'slant', 11),
    );
    expect(
      (arena.navigationBarTheme.indicatorShape! as GumdropShape).slant,
      11,
    );
    expect(arena.cardTheme.shape, isA<BeveledRectangleBorder>());
    expect(arena.dialogTheme.shape, isA<BeveledRectangleBorder>());
    expect(
      arenaStyle.cardDecoration(arenaColors.surface, 20),
      isA<ShapeDecoration>(),
    );
    // Gumdrop Pop's stand upright, as pills, on rounded cards.
    final dark = AppTheme.of(GumdropFlavor.dark);
    expect(button(dark).slant, 0);
    expect(button(dark).radius, isNull);
    expect(dark.cardTheme.shape, isA<RoundedRectangleBorder>());
    expect(
      GumdropStyle.gumdrop.cardDecoration(arenaColors.surface, 20),
      isA<BoxDecoration>(),
    );
  });

  test('a leaning gumdrop stays in its box, its top to the right', () {
    const box = Rect.fromLTWH(0, 0, 100, 48);
    const shape = GumdropShape(
      lipColor: Color(0xFF2A63C9),
      radius: BorderRadius.all(Radius.circular(7)),
      slant: 11,
    );
    final outer = shape.getOuterPath(box);
    final bounds = outer.getBounds();
    expect(bounds.left, greaterThanOrEqualTo(-0.01));
    expect(bounds.right, lessThanOrEqualTo(100.01));
    expect(bounds.top, 0);
    expect(bounds.bottom, 48);
    // Near the top, the face has moved right; near the bottom, the lip
    // has moved left.
    expect(outer.contains(const Offset(5, 3)), isFalse);
    expect(outer.contains(const Offset(95, 3)), isTrue);
    expect(outer.contains(const Offset(5, 44)), isTrue);
    expect(outer.contains(const Offset(95, 44)), isFalse);
    expect(shape.copyWith(slant: 0).slant, 0);
    final half = ShapeBorder.lerp(shape, shape.copyWith(slant: 0), 0.5)!;
    expect((half as GumdropShape).slant, closeTo(5.5, 0.001));
  });

  test("a team's color is the page, its cards that color muted", () {
    const red = Color(0xFFB91C1C);
    final c = teamTinted(arenaColors, red.toARGB32());
    expect(c.coloredPage, isTrue);
    expect(c.page, red);
    final card = ColorMath.lch(c.surface);
    expect(card.l, closeTo(ColorMath.lch(arenaColors.surface).l, 0.6));
    expect(ColorMath.hueDistance(card.h, ColorMath.lch(red).h), lessThan(4));
    // The default blue keeps Arena's own violet page.
    final blue = teamTinted(arenaColors, 0xFF2F5BEA);
    expect(blue.page, arenaColors.page);
    expect(blue.coloredPage, isFalse);
  });

  testWidgets('Settings offers it, two by two on a phone', (tester) async {
    ThemePreference? picked;
    Future<void> pumpAt(double width) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.of(GumdropFlavor.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: ThemePicker(
                  selected: ThemePreference.dark,
                  onSelect: (p) => picked = p,
                ),
              ),
            ),
          ),
        ),
      );
    }

    double top(String name) => tester.getTopLeft(find.text(name)).dy;

    await pumpAt(340);
    expect(top('Gumdrop Candy'), greaterThan(top('Gumdrop Pop Dark')));
    expect(top('Gumdrop Arena'), top('Gumdrop Candy'));
    await tester.tap(find.text('Gumdrop Arena'));
    expect(picked, ThemePreference.arena);

    // Four across where they fit.
    await pumpAt(600);
    expect(top('Gumdrop Arena'), top('Gumdrop Pop Dark'));
  });

  testWidgets('the account menu switches to it', (tester) async {
    final users = FakeUserRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach')],
      users: users,
    );
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<String>, 'Gumdrop Arena'),
    );
    await tester.pumpAndSettle();
    expect(users.themeMode, ThemePreference.arena);
    // The app is in Arena now: its page and its leaning sticker.
    final theme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(theme.extension<GumdropStyle>(), same(arenaStyle));
  });
}
