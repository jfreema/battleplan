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
        // A dark ink lip stays; a coral one takes a deeper blue. Coral's
        // own lip, for the "Cherry" people pick, stays as it ships.
        expect(r.candyLipCoral, base.candyLipCoral, reason: '$scheme');
        if (ColorMath.luminance(base.candyLipCoral) < 0.03) {
          expect(r.youLip, base.candyLipCoral, reason: '$scheme');
        } else {
          expect(
            ColorMath.hueDistance(
              ColorMath.lch(r.youLip).h,
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
      // The "you" color nearly the page's.
      expect(themeProblems(army, army.withOverrides(you: army.page)), {
        ThemeProblem.accentHidden,
      });
      // Only nearly the same is refused (owner's request 2026-11-21: "I only
      // want to block colors that are nearly identical"): near black buttons
      // on the olive, mid gray buttons, dark text where the tab bar stays
      // olive, and a yellow page all go, however they read.
      for (final themed in [
        army.withOverrides(you: const Color(0xFF101010)),
        army.withOverrides(you: const Color(0xFF808080)),
        army.withOverrides(
          page: const Color(0xFFFBF5E6),
          card: const Color(0xFFFFFFFF),
          text: const Color(0xFF1A1A18),
        ),
        army.withOverrides(page: const Color(0xFFFDD023)),
        SchemeRoles.light.withOverrides(page: const Color(0xFFF8D84A)),
      ]) {
        expect(themeProblems(army, themed), isEmpty);
      }
      // Text nearly the tab bar's color, which keeps Army green's.
      expect(
        themeProblems(
          army,
          army.withOverrides(
            page: const Color(0xFFFFFFFF),
            text: const Color(0xFF3D4124),
          ),
        ),
        contains(ThemeProblem.textOnBars),
      );
      // Text the color of the page: nearly the same everywhere it's written.
      expect(themeProblems(army, army.withOverrides(text: army.page)), {
        ThemeProblem.textOnPage,
        ThemeProblem.textOnBars,
        ThemeProblem.textOnCard,
      });
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

  group('text colors (#83)', () {
    test("the card's text follows the text but in Candy Pop, and muted text, "
        'lines and rings in the text color follow too, readable', () {
      const white = Color(0xFFFFFFFF);
      final army = SchemeRoles.army.withOverrides(text: white);
      expect(army.text, white);
      expect(army.cardText, white);
      // Army green's muted text and outlines are its cream at an opacity.
      expect(
        army.pageMuted,
        white.withValues(alpha: SchemeRoles.army.pageMuted.a),
      );
      expect(army.outline, white.withValues(alpha: SchemeRoles.army.outline.a));
      expect(
        army.cardOutline,
        white.withValues(alpha: SchemeRoles.army.cardOutline.a),
      );
      // Candy Pop's navy on white cards stays.
      final candy = SchemeRoles.candypop.withOverrides(
        text: const Color(0xFFFDD023),
      );
      expect(candy.cardText, SchemeRoles.candypop.cardText);
      expect(candy.cardMuted, SchemeRoles.candypop.cardMuted);
      // Its own card text, set.
      expect(
        SchemeRoles.candypop
            .withOverrides(cardText: const Color(0xFF1238A8))
            .cardText,
        const Color(0xFF1238A8),
      );
      // Navy's muted text is its own blue-gray, mixed again with gold.
      final navy = SchemeRoles.navy.withOverrides(
        text: const Color(0xFFFDD023),
      );
      expect(contrastOn(navy.pageMuted, navy.page), greaterThanOrEqualTo(4.5));
      expect(navy.pageMuted, isNot(SchemeRoles.navy.pageMuted));
    });

    test('colored text and marks on a new page or card are made to read, '
        'their hues kept', () {
      // A lighter olive than Army green's: its pale pink red would fade.
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
      expect(contrastOn(r.accentMark, page), greaterThanOrEqualTo(3));
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

    test('maroon "you" takes white writing, everywhere it writes', () {
      const maroon = Color(0xFF7F1D1D);
      ThemeCatalog.install(const {
        TeamScheme.light: ThemeOverride(accent: 0xFF7F1D1D),
      });
      final r = SchemeRoles.of(TeamScheme.light);
      expect(r.youInk, const Color(0xFFFFFFFF));
      expect(themeProblems(SchemeRoles.light, r), isEmpty);
      final c = GumdropColors.forScheme(TeamScheme.light);
      expect(c.you.face, maroon);
      expect(c.inkOn(c.you), const Color(0xFFFFFFFF));
      // The rest of the candies keep the ink.
      expect(c.inkOn(c.mint), c.ink);
      final theme = AppTheme.of(TeamScheme.light);
      expect(
        theme.floatingActionButtonTheme.foregroundColor,
        const Color(0xFFFFFFFF),
      );
      expect(theme.badgeTheme.textColor, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.onPrimaryContainer, const Color(0xFFFFFFFF));
    });

    test('"Cherry", for an icon, stays coral under a theme\'s own "you"', () {
      ThemeCatalog.install(const {
        TeamScheme.army: ThemeOverride(accent: 0xFF79BBFF),
      });
      final c = GumdropColors.forScheme(TeamScheme.army);
      expect(c.you.face, const Color(0xFF79BBFF));
      expect(c.coral.face, CandyFaces.coral);
      expect(c.coral.lip, SchemeRoles.army.candyLipCoral);
    });
  });

  group('hard-to-read themes are never drawn (#83)', () {
    test('readableThemes drops them; the rest stay', () {
      const bad = ThemeOverride(page: 0xFFF4EAD0);
      const good = ThemeOverride(accent: 0xFFFDD023);
      const badSaved = ThemeOverride(
        name: 'Fog',
        base: TeamScheme.light,
        text: 0xFFFBF5E6,
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

    test("the Super Admin Panel's theme is a scheme as it ships", () {
      ThemeCatalog.install(const {
        TeamScheme.army: ThemeOverride(page: 0xFF101010, accent: 0xFF79BBFF),
      });
      final shipped = AppTheme.of(TeamScheme.army, shipped: true);
      final g = shipped.extension<GumdropColors>()!;
      expect(g.shipped, isTrue);
      expect(g.page, SchemeRoles.army.page);
      expect(g.you.face, CandyFaces.coral);
      // Its card context is too.
      expect(g.card.shipped, isTrue);
      expect(g.card.surface, SchemeRoles.army.card);
      // The app's own takes the theme.
      expect(
        AppTheme.of(TeamScheme.army).extension<GumdropColors>()!.page,
        const Color(0xFF101010),
      );
    });
  });
}
