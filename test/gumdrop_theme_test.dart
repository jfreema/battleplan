// The Gumdrop Pop themes (SPEC §7.3, §7.4, SET-2, TEAM-1): the team-color
// tint against the design's tables (Gumdrop team-color proposal §5; Dark's
// is the lighter touch), the team-colored shadows, and 4.5:1 text contrast
// for every text role in every theme and team color.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/team_tint.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The team colors in the app's order, by the design's names.
const _names = [
  'Blue',
  'Light blue',
  'Navy',
  'Teal',
  'Green',
  'Olive',
  'Yellow',
  'Mustard',
  'Orange',
  'Red',
  'Maroon',
  'Pink',
  'Purple',
  'Gray',
  'Black',
];

/// Dark: page, card, raised, input, drop (lip), border. These are the
/// lighter touch, not table 5a: the team's hue at half the chroma
/// ([darkTeamShare]), and warm hues held to [warmChroma] so they're a warm
/// charcoal, not brown. Blue and Navy keep the defaults (the 25° rule);
/// Gray and Black are grays.
const _dark = {
  'Light blue': [
    '#051824',
    '#112837',
    '#233948',
    '#01141E',
    '#010E17',
    '#304656',
  ],
  'Teal': ['#001921', '#062A35', '#183A47', '#00141A', '#000F14', '#274855'],
  'Green': ['#051A11', '#132A1F', '#223B2F', '#00160B', '#001008', '#2B4A3B'],
  'Olive': ['#131906', '#212816', '#313925', '#0E1400', '#0A0F00', '#3D472F'],
  'Yellow': ['#1A160F', '#2A251F', '#3A362F', '#161107', '#120C01', '#48433C'],
  'Mustard': ['#1C150F', '#2B251F', '#3C352F', '#171008', '#140B02', '#49423C'],
  'Orange': ['#1D1511', '#2D2421', '#3D3431', '#190F0A', '#160A04', '#4B423E'],
  'Red': ['#1D1412', '#2D2422', '#3E3432', '#1A0F0C', '#160A06', '#4C413F'],
  'Maroon': ['#1D1413', '#2D2422', '#3E3432', '#1A0F0D', '#160907', '#4C4140'],
  'Pink': ['#241116', '#381F25', '#4B2E35', '#1F0C11', '#18080C', '#5C3A42'],
  'Purple': ['#1A1421', '#2B2235', '#3C3246', '#160F1C', '#110A15', '#4A3F57'],
  // Grays: a third of their chroma, so they read gray, not navy.
  'Gray': ['#13171D', '#22262D', '#33363D', '#0D1218', '#080D15', '#40444B'],
  'Black': ['#161616', '#262626', '#363636', '#121212', '#0D0D0D', '#444444'],
};

/// §5b, Light: page, input, chip (well), hairline, border, drop (lip).
/// Blue and Navy keep the defaults (the 25° rule).
const _light = {
  'Light blue': [
    '#EFF6FD',
    '#F3F9FE',
    '#E1EEF8',
    '#D7E6F3',
    '#C8DEF0',
    '#BBD5EB',
  ],
  'Teal': ['#EDF7FB', '#F2F9FD', '#DEEFF6', '#D3E7F1', '#C2E0ED', '#B4D7E7'],
  'Green': ['#EEF7F2', '#F3FAF6', '#E0EFE7', '#D6E8DE', '#C7E1D3', '#BAD9C9'],
  'Olive': ['#F3F6EE', '#F7F9F3', '#E9EEE1', '#E0E6D6', '#D6DEC8', '#CCD6BC'],
  'Yellow': ['#FAF4ED', '#FCF8F2', '#F3EBDF', '#EDE3D4', '#E7D9C5', '#E0D0B8'],
  'Mustard': ['#FBF4ED', '#FDF7F2', '#F6EADF', '#F0E2D5', '#ECD8C6', '#E5CEB9'],
  'Orange': ['#FDF3EF', '#FEF7F4', '#F9E8E2', '#F4E0D8', '#F1D5CB', '#ECCBBF'],
  'Red': ['#FEF3F0', '#FFF6F5', '#FAE8E4', '#F6DFDB', '#F3D4CE', '#EECAC3'],
  'Maroon': ['#FEF3F1', '#FFF6F5', '#FBE8E5', '#F6DFDC', '#F3D4CF', '#EECAC4'],
  'Pink': ['#FEF2F4', '#FFF6F8', '#FAE7EB', '#F5DFE3', '#F2D3D9', '#EDC9D0'],
  'Purple': ['#F7F4FB', '#FAF7FD', '#F0E9F6', '#E9E1F1', '#E2D7EC', '#DACDE6'],
  'Gray': ['#F4F5F8', '#F7F8FA', '#EAECF0', '#E1E4EA', '#D7DBE3', '#CDD2DB'],
  'Black': ['#F5F5F5', '#F8F8F8', '#ECECEC', '#E4E4E4', '#DBDBDB', '#D2D2D2'],
};

/// §5c, Candy: the page, the text on it, and the title (and page) shadow.
const _candy = {
  'Blue': ['#2F5BEA', '#FFFFFF', '#0D163D'],
  'Light blue': ['#7BAFD4', '#0D163D', '#FFFFFF'],
  'Navy': ['#1E3A5F', '#FFFFFF', '#5E759F'],
  'Teal': ['#0E7490', '#FFFFFF', '#0D163D'],
  'Green': ['#01855B', '#FFFFFF', '#0D163D'],
  'Olive': ['#4D7C0F', '#FFFFFF', '#0D163D'],
  'Yellow': ['#D4A017', '#0D163D', '#FFFFFF'],
  'Mustard': ['#A16207', '#FFFFFF', '#0D163D'],
  'Orange': ['#C2410C', '#FFFFFF', '#0D163D'],
  'Red': ['#B91C1C', '#FFFFFF', '#0D163D'],
  'Maroon': ['#7F1D1D', '#FFFFFF', '#C95E55'],
  'Pink': ['#BE185D', '#FFFFFF', '#0D163D'],
  'Purple': ['#7C3AED', '#FFFFFF', '#0D163D'],
  'Gray': ['#334155', '#FFFFFF', '#6F7D94'],
  'Black': ['#111111', '#FFFFFF', '#474747'],
};

/// The team hues that are Gumdrop's own navy keep the default Dark and
/// Light colors (the 25° rule). Gray is in that hue too, but it's a gray,
/// and tints gray.
const _sameHue = {'Blue', 'Navy'};

/// The grays (Gray, Black): gray in Dark and Light, not navy.
const _grays = {'Gray', 'Black'};

/// [name]'s ARGB, by the palette's order.
int _argb(String name) => teamColorValues[_names.indexOf(name)];

Color _hex(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));

/// Within 2 of [expected] on every channel: the tables were rounded in
/// another language.
Matcher _near(String expected) => predicate<Color>((c) {
  final e = _hex(expected);
  int ch(double v) => (v * 255).round();
  return (ch(c.r) - ch(e.r)).abs() <= 2 &&
      (ch(c.g) - ch(e.g)).abs() <= 2 &&
      (ch(c.b) - ch(e.b)).abs() <= 2;
}, 'within 2 of $expected');

void _reads(Color text, Color background, String what, {double min = 4.5}) {
  final ratio = ColorMath.contrast(text, background);
  expect(
    ratio,
    greaterThanOrEqualTo(min),
    reason:
        '$what: ${ColorMath.hex(text)} on ${ColorMath.hex(background)} '
        'is ${ratio.toStringAsFixed(2)}:1',
  );
}

void main() {
  group('color math', () {
    test('matches the tables: L*, chroma, hue, and contrast', () {
      final navy = ColorMath.lch(GumdropColors.dark.page);
      expect(navy.l, closeTo(7.5, 0.05));
      expect(navy.c, closeTo(21.1, 0.1));
      expect(navy.h, closeTo(288.9, 0.1));
      expect(
        ColorMath.contrast(const Color(0xFFFFFFFF), const Color(0xFF0F8A5F)),
        closeTo(4.36, 0.01),
      );
      // A round trip lands on the same color.
      for (final argb in teamColorValues) {
        final c = ColorMath.lch(Color(argb));
        expect(
          ColorMath.fromLch(c.l, c.c, c.h),
          _near(ColorMath.hex(Color(argb))),
        );
      }
    });

    test('readable moves lightness until text reads', () {
      const blue = Color(0xFF4D9BFF);
      const white = Color(0xFFFFFFFF);
      final onWhite = ColorMath.readable(blue, [white]);
      expect(ColorMath.contrast(onWhite, white), greaterThanOrEqualTo(4.5));
      // Still a blue.
      expect(
        ColorMath.hueDistance(ColorMath.lch(onWhite).h, ColorMath.lch(blue).h),
        lessThan(10),
      );
      expect(ColorMath.readable(blue, [const Color(0xFF0B1531)]), blue);
    });
  });

  group('team tint (TEAM-1)', () {
    test('no team color leaves every theme as it is', () {
      for (final flavor in GumdropFlavor.values) {
        final base = GumdropColors.forFlavor(flavor);
        expect(teamTinted(base, null), same(base));
      }
    });

    test('Gumdrop Pop Dark matches its table (the lighter touch)', () {
      for (final (i, name) in _names.indexed) {
        final c = teamTinted(GumdropColors.dark, teamColorValues[i]);
        const d = GumdropColors.dark;
        final row = _sameHue.contains(name)
            ? [
                d.page,
                d.surface,
                d.raisedFace,
                d.inputFill,
                d.raisedLip,
                d.inputBorder,
              ].map(ColorMath.hex).toList()
            : _dark[name]!;
        expect(c.page, _near(row[0]), reason: '$name page');
        expect(c.surface, _near(row[1]), reason: '$name card');
        expect(c.raisedFace, _near(row[2]), reason: '$name raised');
        expect(c.switchOffTrack, c.raisedFace, reason: name);
        expect(c.inputFill, _near(row[3]), reason: '$name input');
        expect(c.well, c.inputFill, reason: name);
        expect(c.raisedLip, _near(row[4]), reason: '$name drop');
        expect(c.inputBorder, _near(row[5]), reason: '$name border');
        expect(c.divider, c.inputBorder, reason: name);
        expect(c.badgeRing, c.page, reason: name);
        // Text and candies don't change.
        expect(c.textPrimary, d.textPrimary);
        expect(c.you, d.you);
        expect(c.teamColor, Color(teamColorValues[i]));
      }
    });

    test('Gumdrop Pop Light matches table 5b, with white cards', () {
      for (final (i, name) in _names.indexed) {
        final c = teamTinted(GumdropColors.light, teamColorValues[i]);
        const l = GumdropColors.light;
        final row = _sameHue.contains(name)
            ? [
                l.page,
                l.inputFill,
                l.well,
                l.surfaceBorder,
                l.raisedBorder,
                l.raisedLip,
              ].map(ColorMath.hex).toList()
            : _light[name]!;
        expect(c.page, _near(row[0]), reason: '$name page');
        expect(c.inputFill, _near(row[1]), reason: '$name input');
        expect(c.well, _near(row[2]), reason: '$name chip');
        expect(c.surfaceBorder, _near(row[3]), reason: '$name hairline');
        expect(c.raisedBorder, _near(row[4]), reason: '$name border');
        expect(c.inputBorder, c.raisedBorder, reason: name);
        expect(c.raisedLip, _near(row[5]), reason: '$name drop');
        expect(c.surface, l.surface, reason: '$name cards stay white');
      }
    });

    test("the theme's own hues keep the defaults in Dark and Light", () {
      for (final (i, name) in _names.indexed) {
        expect(
          isGumdropHue(Color(teamColorValues[i])),
          _sameHue.contains(name),
          reason: name,
        );
      }
    });

    test('the grays tint Dark and Light gray, not navy', () {
      for (final name in _grays) {
        final argb = _argb(name);
        expect(isGray(Color(argb)), isTrue, reason: name);
        for (final base in [GumdropColors.dark, GumdropColors.light]) {
          final c = teamTinted(base, argb);
          expect(c.page, isNot(base.page), reason: '$name ${base.flavor}');
          expect(ColorMath.lch(c.page).c, lessThan(5), reason: '$name page');
          expect(ColorMath.lch(c.surface).c, lessThan(6), reason: '$name card');
        }
      }
      // Black is a neutral gray, at the theme's own lightness.
      final black = teamTinted(GumdropColors.dark, _argb('Black'));
      expect(ColorMath.lch(black.page).c, lessThan(0.5));
      expect(
        ColorMath.lch(black.page).l,
        closeTo(ColorMath.lch(GumdropColors.dark.page).l, 0.5),
      );
      // Every other team color is a color.
      for (final (i, name) in _names.indexed) {
        if (_grays.contains(name)) continue;
        expect(isGray(Color(teamColorValues[i])), isFalse, reason: name);
      }
    });

    test('Dark is a lighter touch: warm teams are not brown', () {
      // Brown is a dark warm hue (orange to yellow, 40° to 100°) with real
      // chroma. The warm teams' pages and cards are a warm charcoal: their
      // own hue, with too little chroma to read brown.
      for (final name in ['Yellow', 'Mustard', 'Orange', 'Red', 'Maroon']) {
        expect(isWarmHue(ColorMath.lch(Color(_argb(name))).h), isTrue);
        final c = teamTinted(GumdropColors.dark, _argb(name));
        for (final (role, color) in [('page', c.page), ('card', c.surface)]) {
          final lch = ColorMath.lch(color);
          final brown = lch.h >= 40 && lch.h <= 100 && lch.c >= 6;
          expect(brown, isFalse, reason: '$name $role ${ColorMath.hex(color)}');
        }
      }
      for (final name in ['Pink', 'Olive', 'Green', 'Purple']) {
        expect(isWarmHue(ColorMath.lch(Color(_argb(name))).h), isFalse);
      }
      // Every team but the theme's own hues still changes Dark's page and
      // cards.
      for (final (i, name) in _names.indexed) {
        if (_sameHue.contains(name)) continue;
        final c = teamTinted(GumdropColors.dark, teamColorValues[i]);
        expect(c.page, isNot(GumdropColors.dark.page), reason: name);
        expect(c.surface, isNot(GumdropColors.dark.surface), reason: name);
      }
    });

    test("Dark and Light pages keep the team's hue", () {
      // Within 30° of the team color's own hue, so Green isn't teal and
      // Yellow isn't mauve. The grays are gray, and Blue and Navy keep the
      // defaults.
      for (final (i, name) in _names.indexed) {
        if (_sameHue.contains(name) || _grays.contains(name)) continue;
        final team = ColorMath.lch(Color(teamColorValues[i])).h;
        for (final base in [GumdropColors.dark, GumdropColors.light]) {
          final page = teamTinted(base, teamColorValues[i]).page;
          expect(
            ColorMath.hueDistance(ColorMath.lch(page).h, team),
            lessThanOrEqualTo(30),
            reason: '$name ${base.flavor} page ${ColorMath.hex(page)}',
          );
        }
      }
    });

    test(
      'Dark and Light shadows are the team color, and each team its own',
      () {
        // A page this dark (or pale) can't tell Red from Maroon, or Yellow
        // from Mustard: they're the same hue. The hard shadows under headings
        // and on the page carry the team color itself, so every team shows.
        for (final base in [GumdropColors.dark, GumdropColors.light]) {
          final shadows = <String, Color>{};
          for (final (i, name) in _names.indexed) {
            final c = teamTinted(base, teamColorValues[i]);
            final what = '$name ${base.flavor}';
            expect(c.pageShadow, c.headingShadow, reason: what);
            if (_sameHue.contains(name)) {
              expect(c.headingShadow, base.headingShadow, reason: what);
              expect(c.headingShadowOnCard, base.headingShadowOnCard);
              continue;
            }
            final team = ColorMath.lch(Color(teamColorValues[i]));
            final shadow = ColorMath.lch(c.headingShadow);
            // The team's own hue and chroma, at most a little lighter.
            if (!_grays.contains(name)) {
              expect(
                ColorMath.hueDistance(shadow.h, team.h),
                lessThan(3),
                reason: what,
              );
            }
            expect(shadow.c, closeTo(team.c, 1.5), reason: what);
            if (base.flavor == GumdropFlavor.dark) {
              // It shows on the page, and on cards.
              for (final (shadow, bg) in [
                (c.headingShadow, c.page),
                (c.headingShadowOnCard, c.surface),
              ]) {
                expect(
                  ColorMath.contrast(shadow, bg),
                  greaterThanOrEqualTo(shadowContrast),
                  reason: '$what ${ColorMath.hex(shadow)}',
                );
              }
            } else {
              // Clear of the navy heading text, and it shows on the page.
              expect(
                ColorMath.contrast(c.headingShadow, c.headingText),
                greaterThanOrEqualTo(shadowContrast),
                reason: what,
              );
              expect(
                ColorMath.contrast(c.headingShadow, c.page),
                greaterThanOrEqualTo(2),
                reason: what,
              );
            }
            shadows[name] = c.headingShadow;
          }
          shadows['Blue'] = base.headingShadow;
          // Any two teams' shadows are clearly different colors (Blue and
          // Navy share the default).
          final names = shadows.keys.toList();
          for (final (i, a) in names.indexed) {
            for (final b in names.skip(i + 1)) {
              expect(
                ColorMath.deltaE(shadows[a]!, shadows[b]!),
                greaterThanOrEqualTo(10),
                reason: '${base.flavor} $a and $b',
              );
            }
          }
        }
        // Maroon is its own red: a duller one than Red, lifted to show.
        final dark = teamTinted(GumdropColors.dark, _argb('Maroon'));
        expect(dark.headingShadow, _near('#A8423B'));
        final light = teamTinted(GumdropColors.light, _argb('Black'));
        expect(light.headingShadow, _near('#666666'));
      },
    );

    test('Gumdrop Candy matches table 5c', () {
      for (final (i, name) in _names.indexed) {
        final c = teamTinted(GumdropColors.candy, teamColorValues[i]);
        final [page, text, shadow] = _candy[name]!;
        expect(c.page, _near(page), reason: '$name page');
        expect(c.textOnPage, _hex(text), reason: '$name text');
        expect(c.headingText, _hex(text), reason: '$name heading');
        expect(c.headingShadow, _near(shadow), reason: '$name shadow');
        expect(c.badgeRing, anyOf(c.page, c.ink), reason: name);
        // Cards and candies don't change, except that a candy on its own
        // hue (lemon on Yellow) keeps an ink lip to stand out (5c).
        expect(c.surface, GumdropColors.candy.surface);
        expect(c.you.face, GumdropColors.candy.you.face);
        expect(
          c.you.lip,
          ColorMath.contrast(c.you.face, c.page) < 2
              ? c.ink
              : GumdropColors.candy.you.lip,
          reason: '$name you lip',
        );
      }
      final yellow = teamTinted(GumdropColors.candy, _argb('Yellow'));
      expect(yellow.you.lip, yellow.ink);
      expect(yellow.lemon.lip, yellow.ink);
      // Hard shadows on the page stay ink where ink shows, and lift where
      // it wouldn't (Gray, Navy, Maroon, Black).
      for (final (name, shadow) in [
        ('Gray', '#6F7D94'),
        ('Navy', '#5E759F'),
        ('Maroon', '#C95E55'),
        ('Black', '#474747'),
      ]) {
        final c = teamTinted(GumdropColors.candy, _argb(name));
        expect(c.pageShadow, _near(shadow), reason: name);
        expect(
          ColorMath.contrast(c.pageShadow, c.page),
          greaterThanOrEqualTo(2),
          reason: '$name shadow shows',
        );
      }
      final lightBlue = teamTinted(GumdropColors.candy, _argb('Light blue'));
      expect(lightBlue.pageShadow, GumdropColors.candy.ink);
      // The red teams' badges get an ink ring, not a red gap.
      for (final name in ['Red', 'Maroon']) {
        final c = teamTinted(GumdropColors.candy, _argb(name));
        expect(c.badgeRing, c.ink, reason: name);
      }
      // Black's page is black, with white text.
      final black = teamTinted(GumdropColors.candy, _argb('Black'));
      expect(black.page, const Color(0xFF111111));
      expect(black.textOnPage, const Color(0xFFFFFFFF));
    });

    test('a tinted card context is the tinted theme on a card', () {
      final page = teamTinted(GumdropColors.candy, _argb('Light blue'));
      final card = teamTinted(GumdropColors.candy.card, _argb('Light blue'));
      expect(card.onCard, isTrue);
      expect(card.page, page.page);
      expect(card.textOnPage, GumdropColors.candy.textPrimary);
    });
  });

  group('text reads at 4.5:1 (SPEC §7.6)', () {
    final palettes = <String, GumdropColors>{
      for (final flavor in GumdropFlavor.values) ...{
        flavor.name: GumdropColors.forFlavor(flavor),
        for (final (i, name) in _names.indexed)
          '${flavor.name} $name': teamTinted(
            GumdropColors.forFlavor(flavor),
            teamColorValues[i],
          ),
      },
    };

    for (final MapEntry(key: what, value: c) in palettes.entries) {
      test('$what: every text role on its background', () {
        _reads(c.textOnPage, c.page, 'text on page');
        _reads(c.textMutedOnPage, c.page, 'muted on page');
        _reads(c.headingText, c.page, 'heading on page');
        _reads(c.successOnPage, c.page, 'success on page', min: 3);
        for (final (bg, name) in [
          (c.surface, 'surface'),
          (c.raisedFace, 'raised'),
          (c.well, 'well'),
          (c.inputFill, 'input'),
        ]) {
          _reads(c.textPrimary, bg, 'text on $name');
          _reads(c.textMuted, bg, 'muted on $name');
        }
        _reads(c.headingTextOnCard, c.surface, 'heading on card');
        for (final (a, name) in [
          (c.you, 'you'),
          (c.blueRaspberry, 'blue raspberry'),
          (c.lemon, 'lemon'),
          (c.mint, 'mint'),
          (c.cherry, 'cherry'),
          (c.tangerine, 'tangerine'),
          (c.grape, 'grape'),
          (c.bubblegum, 'bubblegum'),
        ]) {
          _reads(c.ink, a.face, 'ink on $name');
          _reads(a.text, c.surface, '$name text on surface');
        }
      });

      test("$what: the Material theme's text roles", () {
        for (final onCard in [false, true]) {
          final colors = onCard ? c.card : c;
          final theme = AppTheme.build(colors);
          final s = theme.colorScheme;
          final where = onCard ? 'card' : 'page';
          for (final (bg, name) in [
            (s.surface, 'surface'),
            (s.surfaceContainerLowest, 'lowest'),
            (s.surfaceContainerLow, 'low'),
            (s.surfaceContainer, 'container'),
            (s.surfaceContainerHigh, 'high'),
            (s.surfaceContainerHighest, 'highest'),
          ]) {
            _reads(s.onSurface, bg, '$where onSurface on $name');
            _reads(s.onSurfaceVariant, bg, '$where onSurfaceVariant on $name');
          }
          for (final (fg, name) in [
            (s.primary, 'primary'),
            (s.secondary, 'secondary'),
            (s.tertiary, 'tertiary'),
            (s.error, 'error'),
          ]) {
            _reads(fg, s.surface, '$where $name on surface');
            _reads(fg, s.surfaceContainerLow, '$where $name on cards');
          }
          for (final (fg, bg, name) in [
            (s.onPrimary, s.primary, 'onPrimary'),
            (s.onSecondary, s.secondary, 'onSecondary'),
            (s.onTertiary, s.tertiary, 'onTertiary'),
            (s.onError, s.error, 'onError'),
            (s.onPrimaryContainer, s.primaryContainer, 'onPrimaryContainer'),
            (
              s.onSecondaryContainer,
              s.secondaryContainer,
              'onSecondaryContainer',
            ),
            (s.onTertiaryContainer, s.tertiaryContainer, 'onTertiaryContainer'),
            (s.onErrorContainer, s.errorContainer, 'onErrorContainer'),
            (s.onInverseSurface, s.inverseSurface, 'onInverseSurface'),
            (s.inversePrimary, s.inverseSurface, 'inversePrimary'),
          ]) {
            _reads(fg, bg, '$where $name');
          }
          final input = theme.inputDecorationTheme;
          _reads(
            theme.textTheme.bodyLarge!.color!,
            input.fillColor!,
            '$where input text',
          );
          _reads(input.hintStyle!.color!, input.fillColor!, '$where hint');
          final app = theme.extension<AppColors>()!;
          for (final (fg, name) in [
            (app.going, 'going'),
            (app.maybe, 'maybe'),
            (app.notGoing, 'not going'),
            (app.game, 'game'),
            (app.practice, 'practice'),
            (app.meeting, 'meeting'),
            (app.social, 'social'),
            (app.otherEvent, 'other'),
          ]) {
            _reads(fg, s.surface, '$where $name');
            _reads(fg, s.surfaceContainerLow, '$where $name on cards');
          }
          _reads(app.onBubbleMine, app.bubbleMine, '$where my bubble');
          _reads(app.onBubbleOther, app.bubbleOther, "$where others' bubble");
        }
      });
    }
  });

  group('themes', () {
    test('each preference picks its theme; system is Gumdrop Pop Dark', () {
      expect(AppTheme.flavorOf(ThemePreference.system), GumdropFlavor.dark);
      expect(AppTheme.flavorOf(ThemePreference.dark), GumdropFlavor.dark);
      expect(AppTheme.flavorOf(ThemePreference.light), GumdropFlavor.light);
      expect(AppTheme.flavorOf(ThemePreference.candy), GumdropFlavor.candy);
      final dark = AppTheme.forPreference(ThemePreference.dark);
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, GumdropColors.dark.page);
      expect(
        AppTheme.forPreference(ThemePreference.light).brightness,
        Brightness.light,
      );
      // Candy's page holds white text; its cards hold navy.
      expect(
        AppTheme.forPreference(ThemePreference.candy).brightness,
        Brightness.dark,
      );
      expect(
        AppTheme.of(GumdropFlavor.candy, onCard: true).brightness,
        Brightness.light,
      );
    });

    test('built once per theme, team color, and context', () {
      final a = AppTheme.forPreference(
        ThemePreference.candy,
        teamColor: 0xFFB91C1C,
      );
      final b = AppTheme.of(GumdropFlavor.candy, teamColor: 0xFFB91C1C);
      expect(a, same(b));
      expect(a.extension<GumdropColors>()!.page, const Color(0xFFB91C1C));
      expect(
        AppTheme.forPreference(ThemePreference.system),
        same(AppTheme.of(GumdropFlavor.dark)),
      );
    });

    test('headings are Lilita One with a stacked hard shadow', () {
      final t = AppTheme.of(GumdropFlavor.dark).textTheme;
      expect(t.headlineMedium!.fontFamily, 'Lilita One');
      expect(t.headlineMedium!.shadows, hasLength(4));
      expect(t.headlineMedium!.shadows!.last.offset, const Offset(4, 4));
      expect(t.titleLarge!.shadows, hasLength(3));
      expect(
        t.titleLarge!.shadows!.first.color,
        GumdropColors.dark.headingShadow,
      );
      expect(t.labelLarge!.fontFamily, 'Fredoka');
      expect(t.bodyLarge!.fontFamily, 'Nunito');
    });

    test('a gumdrop sinks onto its lip when pressed', () {
      const rect = Rect.fromLTWH(0, 0, 100, 48);
      const up = GumdropShape(lipColor: Color(0xFF2A63C9));
      final down = up.copyWith(pressed: 1);
      // At rest the face is 44 tall at the top; pressed, at the bottom.
      expect(
        up.getInnerPath(rect).getBounds(),
        const Rect.fromLTWH(0, 0, 100, 44),
      );
      expect(
        down.getInnerPath(rect).getBounds(),
        const Rect.fromLTWH(0, 4, 100, 44),
      );
      expect(up.getOuterPath(rect).getBounds(), rect);
      final half = ShapeBorder.lerp(up, down, 0.5)! as GumdropShape;
      expect(half.pressed, 0.5);
      expect(GumdropShape.lipFor(38), 3);
      expect(GumdropShape.lipFor(40), 4);
    });
  });

  group('TeamTheme', () {
    Future<ThemeData> pumpIn(
      WidgetTester tester,
      GumdropFlavor flavor,
      Widget Function(Widget child) wrap,
    ) async {
      late ThemeData seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.of(flavor),
          home: wrap(
            Builder(
              builder: (context) {
                seen = Theme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return seen;
    }

    testWidgets('tints its subtree in the current theme', (tester) async {
      final t = await pumpIn(
        tester,
        GumdropFlavor.light,
        (child) => TeamTheme(teamColor: 0xFFC2410C, child: child),
      );
      final c = t.extension<GumdropColors>()!;
      expect(c.flavor, GumdropFlavor.light);
      expect(c.page, _near('#FDF3EF'));
      expect(t.scaffoldBackgroundColor, c.page);
    });

    testWidgets('no color leaves the theme untinted', (tester) async {
      final t = await pumpIn(
        tester,
        GumdropFlavor.dark,
        (child) => TeamTheme(teamColor: null, child: child),
      );
      expect(t.extension<GumdropColors>()!.page, GumdropColors.dark.page);
    });

    testWidgets("GumdropSurface gives Candy's cards navy text", (tester) async {
      final t = await pumpIn(
        tester,
        GumdropFlavor.candy,
        (child) => TeamTheme(
          teamColor: 0xFF7C3AED,
          child: GumdropSurface(child: child),
        ),
      );
      final c = t.extension<GumdropColors>()!;
      expect(c.onCard, isTrue);
      expect(c.page, const Color(0xFF7C3AED));
      expect(t.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(t.colorScheme.onSurface, GumdropColors.candy.textPrimary);
      expect(
        t.textTheme.headlineSmall!.color,
        GumdropColors.candy.headingTextOnCard,
      );
    });
  });
}
