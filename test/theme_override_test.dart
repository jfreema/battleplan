// The theme editor's colors (#82) as the app reads and applies them:
// config/app.themes parsed, saved slots shown only when a theme is in
// them, a theme's colors over its base's (with its marks following its
// "you" color), and the readability check the editor saves by.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/theme_readability.dart';
import 'package:battleplan/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  tearDown(() => ThemeCatalog.install(const {}));

  group('config/app.themes', () {
    test('reads built-in changes and saved themes, skipping anything '
        'malformed', () {
      final themes = themesFromConfig({
        'army': {'accent': '#1e90ff', 'page': null, 'card': null},
        // Nothing set: no change.
        'navy': {'accent': null, 'page': null, 'card': null},
        'custom1': {
          'name': ' Night Game ',
          'base': 'navy',
          'accent': '#FDD023',
          'page': 'not a color',
        },
        // A saved theme needs a name, and a built-in base.
        'custom2': {'base': 'dark'},
        'custom3': {'name': 'Loop', 'base': 'custom1'},
        'custom4': {'name': 'Lost', 'base': 'plaid'},
        'plaid': {'accent': '#123456'},
        'sky': 'not a map',
      });
      expect(themes, {
        TeamScheme.army: const ThemeOverride(accent: 0xFF1E90FF),
        TeamScheme.custom1: const ThemeOverride(
          name: 'Night Game',
          base: TeamScheme.navy,
          accent: 0xFFFDD023,
        ),
      });
      expect(themesFromConfig(null), isEmpty);
      expect(themesFromConfig('nope'), isEmpty);
    });

    test('colors go to and from #RRGGBB', () {
      expect(colorFromHex('#f45b5b'), 0xFFF45B5B);
      expect(colorFromHex(' #F45B5B '), 0xFFF45B5B);
      for (final bad in ['F45B5B', '#F45B5', '#F45B5BAA', 'coral', 12, null]) {
        expect(colorFromHex(bad), isNull, reason: '$bad');
      }
      expect(hexOfColor(0xFF0A0B0C), '#0A0B0C');
      expect(hexOfColor(null), isNull);
    });

    test('equal themes are equal, and say what they hold', () {
      const a = ThemeOverride(
        name: 'A',
        base: TeamScheme.dark,
        page: 0xFF000000,
      );
      expect(
        a,
        const ThemeOverride(name: 'A', base: TeamScheme.dark, page: 0xFF000000),
      );
      expect(
        a.hashCode,
        const ThemeOverride(
          name: 'A',
          base: TeamScheme.dark,
          page: 0xFF000000,
        ).hashCode,
      );
      expect(a, isNot(const ThemeOverride(name: 'A', base: TeamScheme.dark)));
      expect(a.isSaved, isTrue);
      expect(const ThemeOverride(accent: 1).isSaved, isFalse);
      expect('$a', contains('page: #000000'));
    });
  });

  group('saved slots', () {
    test('twelve, after the built-in schemes, and shown only with a theme in '
        'them', () {
      expect(customSchemes, hasLength(12));
      expect(builtInSchemes.any((s) => s.isCustom), isFalse);
      expect(TeamScheme.values, [...builtInSchemes, ...customSchemes]);
      const themes = {
        TeamScheme.custom2: ThemeOverride(name: 'B', base: TeamScheme.sky),
        // A built-in scheme's change isn't a saved theme.
        TeamScheme.army: ThemeOverride(accent: 0xFF000000),
      };
      expect(schemeAvailable(TeamScheme.army, themes), isTrue);
      expect(schemeAvailable(TeamScheme.custom2, themes), isTrue);
      expect(schemeAvailable(TeamScheme.custom1, themes), isFalse);
      expect(usableScheme(TeamScheme.custom1, themes), isNull);
      expect(usableScheme(TeamScheme.custom2, themes), TeamScheme.custom2);
      expect(usableScheme(null, themes), isNull);
    });

    test('the pickers offer the built-in schemes, then the saved themes', () {
      expect(ThemeCatalog.available, builtInSchemes);
      final before = ThemeCatalog.version;
      ThemeCatalog.install(const {
        TeamScheme.custom4: ThemeOverride(name: 'D', base: TeamScheme.light),
        TeamScheme.custom1: ThemeOverride(name: 'A', base: TeamScheme.dark),
      });
      expect(ThemeCatalog.version, before + 1);
      expect(ThemeCatalog.available, [
        ...builtInSchemes,
        TeamScheme.custom1,
        TeamScheme.custom4,
      ]);
      // The same again changes nothing.
      ThemeCatalog.install(const {
        TeamScheme.custom4: ThemeOverride(name: 'D', base: TeamScheme.light),
        TeamScheme.custom1: ThemeOverride(name: 'A', base: TeamScheme.dark),
      });
      expect(ThemeCatalog.version, before + 1);
    });

    test("a saved theme's name and lightness come from it and its base", () {
      final l10n = AppLocalizationsEn();
      ThemeCatalog.install(const {
        TeamScheme.custom1: ThemeOverride(
          name: 'Night',
          base: TeamScheme.light,
        ),
        TeamScheme.custom2: ThemeOverride(
          name: 'Day',
          base: TeamScheme.dark,
          page: 0xFFFFFFFF,
        ),
      });
      expect(TeamScheme.custom1.label(l10n), 'Night');
      expect(TeamScheme.custom1.shortLabel(l10n), 'Based on Light');
      expect(TeamScheme.custom1.isDark, isFalse);
      // A white page reads as light, whatever it started from.
      expect(TeamScheme.custom2.isDark, isFalse);
      // A slot with nothing in it.
      expect(TeamScheme.custom3.label(l10n), 'Saved theme');
    });
  });

  group("a theme's colors", () {
    test('over a built-in scheme, change only what they set', () {
      ThemeCatalog.install(const {
        TeamScheme.army: ThemeOverride(page: 0xFF242713, card: 0xFF33361F),
      });
      final r = SchemeRoles.of(TeamScheme.army);
      expect(r.page, const Color(0xFF242713));
      expect(r.card, const Color(0xFF33361F));
      expect(r.you, CandyFaces.coral);
      expect(r.text, SchemeRoles.army.text);
      expect(r.tabbar, SchemeRoles.army.tabbar);
      // Untouched schemes stay as they ship.
      expect(SchemeRoles.of(TeamScheme.navy).page, SchemeRoles.navy.page);
    });

    test("a saved theme starts from its base; a pop-up that was the card's "
        'follows the card', () {
      final themed = SchemeRoles.themed(
        TeamScheme.custom1,
        const ThemeOverride(name: 'N', base: TeamScheme.dark, card: 0xFF202A44),
      );
      expect(themed.page, SchemeRoles.dark.page);
      expect(themed.card, const Color(0xFF202A44));
      expect(SchemeRoles.dark.popup, SchemeRoles.dark.card);
      expect(themed.popup, const Color(0xFF202A44));
      // Candy Pop's pop-ups are their own blue, and stay.
      final candy = SchemeRoles.candypop.withOverrides(
        card: const Color(0xFFFFF5E0),
      );
      expect(candy.popup, SchemeRoles.candypop.popup);
      // An empty slot is the default scheme's.
      expect(
        SchemeRoles.themed(TeamScheme.custom9, null).page,
        SchemeRoles.builtIn(defaultTeamScheme).page,
      );
    });

    test('a new "you" color brings coral marks and lips along, readable, '
        "and leaves a scheme's own alone", () {
      const blue = Color(0xFF79BBFF);
      for (final scheme in builtInSchemes) {
        final base = SchemeRoles.builtIn(scheme);
        final r = base.withOverrides(you: blue);
        expect(r.you, blue);
        final coralMark =
            ColorMath.hueDistance(
                  ColorMath.lch(base.accentMark).h,
                  ColorMath.lch(CandyFaces.coral).h,
                ) <
                20 &&
            ColorMath.lch(base.accentMark).c > 30;
        if (coralMark) {
          expect(r.accentMark, isNot(base.accentMark), reason: '$scheme');
          expect(
            ColorMath.contrast(r.accentMark, r.page),
            greaterThanOrEqualTo(3),
            reason: '$scheme',
          );
        } else {
          expect(r.accentMark, base.accentMark, reason: '$scheme');
        }
        // A dark ink lip stays; a coral one takes a deeper blue.
        if (ColorMath.luminance(base.candyLipCoral) < 0.03) {
          expect(r.candyLipCoral, base.candyLipCoral, reason: '$scheme');
        } else {
          expect(
            ColorMath.hueDistance(
              ColorMath.lch(r.candyLipCoral).h,
              ColorMath.lch(blue).h,
            ),
            lessThan(25),
            reason: '$scheme',
          );
        }
        // "You" text reads on the page and on a card.
        ThemeCatalog.install({scheme: const ThemeOverride(accent: 0xFF79BBFF)});
        for (final onCard in [false, true]) {
          final c = GumdropColors.forScheme(scheme, onCard: onCard);
          expect(c.you.face, blue);
          expect(
            ColorMath.contrast(c.you.text, onCard ? r.card : r.page),
            greaterThanOrEqualTo(4.5),
            reason: '$scheme on card $onCard',
          );
        }
      }
    });

    test('the same "you" color as coral changes nothing', () {
      expect(
        SchemeRoles.army.withOverrides(you: CandyFaces.coral).accentMark,
        SchemeRoles.army.accentMark,
      );
    });

    test("the app's theme is rebuilt when the themes change", () {
      final before = AppTheme.of(TeamScheme.army);
      expect(AppTheme.of(TeamScheme.army), same(before));
      ThemeCatalog.install(const {
        TeamScheme.army: ThemeOverride(accent: 0xFF79BBFF),
      });
      final after = AppTheme.of(TeamScheme.army);
      expect(after, isNot(same(before)));
      expect(
        after.extension<GumdropColors>()!.you.face,
        const Color(0xFF79BBFF),
      );
    });
  });

  group('readability (what the editor saves)', () {
    test('every built-in scheme passes as it ships', () {
      for (final scheme in builtInSchemes) {
        final r = SchemeRoles.builtIn(scheme);
        expect(themeProblems(r, r), isEmpty, reason: '$scheme');
      }
    });

    test('flags a background, card or "you" color it can\'t read on', () {
      const army = SchemeRoles.army;
      expect(themeProblems(army, army.withOverrides(page: army.text)), {
        ThemeProblem.textOnPage,
      });
      expect(themeProblems(army, army.withOverrides(card: army.cardText)), {
        ThemeProblem.textOnCard,
      });
      expect(
        themeProblems(army, army.withOverrides(you: const Color(0xFF101010))),
        {ThemeProblem.inkOnAccent},
      );
      expect(
        themeProblems(
          army,
          army.withOverrides(
            page: const Color(0xFF1B1D10),
            card: const Color(0xFF2E3120),
            you: CandyFaces.lemon,
          ),
        ),
        isEmpty,
      );
    });
  });
}
