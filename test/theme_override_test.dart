// The theme editor's colors (#82) as the app reads them: config/app.themes
// parsed, a theme's colors over its base's for the editor's preview, and
// the readability check the editor saves by. Since Boot Camp Mix (#85) the
// editor is hidden and no theme is drawn: the three schemes are drawn as
// they ship, and a pick of a saved theme reads as Light or Black.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/theme_readability.dart';
import 'package:battleplan/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// How [fg] reads on [bg], drawn over it if see-through.
double contrastOn(Color fg, Color bg) =>
    ColorMath.contrast(Color.alphaBlend(fg, bg), bg);

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

    test('reads the text colors too (#83)', () {
      expect(
        themesFromConfig({
          'purplegold': {'text': '#fdd023', 'cardText': null},
          // Text alone is a change.
          'candypop': {'cardText': '#1238A8'},
        }),
        {
          TeamScheme.purplegold: const ThemeOverride(text: 0xFFFDD023),
          TeamScheme.candypop: const ThemeOverride(cardText: 0xFF1238A8),
        },
      );
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

  group('saved slots (#85: no longer offered)', () {
    test('twelve, after the built-in schemes, and a pick of one is still a '
        'stored scheme', () {
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

    test('the pickers offer the three, whatever is saved', () {
      expect(ThemeCatalog.available, bootCampSchemes);
      ThemeCatalog.install(const {
        TeamScheme.custom4: ThemeOverride(name: 'D', base: TeamScheme.light),
        TeamScheme.custom1: ThemeOverride(name: 'A', base: TeamScheme.dark),
      });
      expect(ThemeCatalog.available, bootCampSchemes);
    });

    test('a saved theme reads as Light or Black, by its page', () {
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
        TeamScheme.custom3: ThemeOverride(
          name: 'Late',
          base: TeamScheme.skyblue,
          page: 0xFF101010,
        ),
      });
      // Its base's page, when it sets none.
      expect(TeamScheme.custom1.look, TeamScheme.light);
      expect(TeamScheme.custom1.label(l10n), 'Light');
      expect(TeamScheme.custom1.isDark, isFalse);
      // A white page reads as light, whatever it started from.
      expect(TeamScheme.custom2.look, TeamScheme.light);
      // A dark one as Black.
      expect(TeamScheme.custom3.look, TeamScheme.dark);
      expect(TeamScheme.custom3.label(l10n), 'Black');
      // A slot with nothing in it: the default, Black.
      expect(TeamScheme.custom4.look, TeamScheme.dark);
    });
  });

  group("a theme's colors", () {
    test('are no longer drawn (#85): the schemes are as they ship', () {
      ThemeCatalog.install(const {
        TeamScheme.army: ThemeOverride(page: 0xFF242713, card: 0xFF33361F),
      });
      expect(SchemeRoles.of(TeamScheme.army), same(SchemeRoles.army));
      expect(
        AppTheme.of(TeamScheme.army).extension<GumdropColors>()!.page,
        SchemeRoles.army.page,
      );
    });

    test("over a built-in scheme, change only what they set (the editor's "
        'preview)', () {
      final r = SchemeRoles.themed(
        TeamScheme.army,
        const ThemeOverride(page: 0xFF242713, card: 0xFF33361F),
      );
      expect(r.page, const Color(0xFF242713));
      expect(r.card, const Color(0xFF33361F));
      expect(r.you, SchemeRoles.army.you);
      expect(r.text, SchemeRoles.army.text);
      expect(r.tabbar, SchemeRoles.army.tabbar);
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
      // An empty slot is the default scheme's.
      expect(
        SchemeRoles.themed(TeamScheme.custom9, null).page,
        SchemeRoles.builtIn(defaultTeamScheme).page,
      );
    });

    test('colored text and marks on a new page or card are made to read, '
        'their hues kept', () {
      const page = Color(0xFF8A9060);
      const card = Color(0xFF9DA374);
      final r = SchemeRoles.army.withOverrides(
        page: page,
        card: card,
        text: const Color(0xFF111111),
      );
      for (final (fg, what) in [
        (r.accentText, 'red'),
        (r.goingText, 'going'),
        (r.maybeText, 'maybe'),
        (r.gameText, 'game'),
        (r.grapePageText, 'grape'),
        (r.bubblegumPageText, 'bubblegum'),
        (r.blueRaspberryPageText, 'blue raspberry'),
      ]) {
        expect(contrastOn(fg, page), greaterThanOrEqualTo(4.5), reason: what);
      }
      for (final (fg, what) in [
        (r.cardGoingText, 'going'),
        (r.cardAccentText, 'red'),
        (r.cardMaybeText, 'maybe'),
        (r.typeGame, 'game'),
        (r.typePractice, 'practice'),
        (r.typeOther, 'other'),
      ]) {
        expect(contrastOn(fg, card), greaterThanOrEqualTo(4.5), reason: what);
      }
      expect(contrastOn(r.notGoingIcon, page), greaterThanOrEqualTo(3));
      // The red stays red.
      expect(
        ColorMath.hueDistance(
          ColorMath.lch(r.accentText).h,
          ColorMath.lch(SchemeRoles.army.accentText).h,
        ),
        lessThan(30),
      );
    });

    test('maroon "you" takes white writing', () {
      final r = SchemeRoles.themed(
        TeamScheme.light,
        const ThemeOverride(accent: 0xFF7F1D1D),
      );
      expect(r.you, const Color(0xFF7F1D1D));
      expect(r.youInk, const Color(0xFFFFFFFF));
    });
  });

  group('readability (what the editor saves)', () {
    test('every scheme passes as it ships', () {
      for (final scheme in TeamScheme.values) {
        final r = SchemeRoles.builtIn(scheme);
        expect(themeProblems(r, r), isEmpty, reason: '$scheme');
      }
    });

    test('flags only colors nearly the same as what they sit on', () {
      final army = SchemeRoles.army;
      expect(themeProblems(army, army.withOverrides(page: army.text)), {
        ThemeProblem.textOnPage,
      });
      expect(themeProblems(army, army.withOverrides(card: army.cardText)), {
        ThemeProblem.textOnCard,
      });
      // The "you" color nearly the page's.
      expect(themeProblems(army, army.withOverrides(you: army.page)), {
        ThemeProblem.accentHidden,
      });
      // Only nearly the same is refused (owner's request 2026-11-21: "I only
      // want to block colors that are nearly identical"): pale blue and pink
      // pages and mid gray buttons go, however they read.
      for (final themed in [
        army.withOverrides(you: const Color(0xFF808080)),
        army.withOverrides(page: const Color(0xFFBCD9F5)),
        SchemeRoles.light.withOverrides(page: const Color(0xFFFFE4E1)),
      ]) {
        expect(themeProblems(army, themed), isEmpty);
      }
    });
  });

  group('hard-to-read themes are left out (#83)', () {
    test('readableThemes drops them; the rest stay', () {
      const bad = ThemeOverride(page: 0xFFF4EAD0);
      const good = ThemeOverride(accent: 0xFF79BBFF);
      const badSaved = ThemeOverride(
        name: 'Fog',
        base: TeamScheme.light,
        text: 0xFFF2EBE0,
      );
      final shown = readableThemes(const {
        TeamScheme.army: bad,
        TeamScheme.navy: good,
        TeamScheme.custom1: badSaved,
      });
      expect(shown, {TeamScheme.navy: good});
      expect(themeReads(TeamScheme.army, bad), isFalse);
      expect(themeReads(TeamScheme.custom1, badSaved), isFalse);
    });
  });
}
