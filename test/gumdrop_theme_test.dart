// The Gumdrop Pop themes (SPEC §7.3, §7.4, SET-2, TEAM-1): the team-color
// tint against the design's tables (Gumdrop team-color proposal §5), and
// 4.5:1 text contrast for every text role in every theme and team color.
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
  'Green',
  'Orange',
  'Red',
  'Purple',
  'Teal',
  'Mustard',
  'Pink',
  'Olive',
  'Royal blue',
  'Violet',
  'Slate',
  'Navy',
  'Yellow',
];

/// §5a, Dark: page, card, raised, input, drop (lip), border.
const _dark = {
  'Blue': ['#121430', '#202248', '#31325C', '#0F0E29', '#0D0A1E', '#3E3F71'],
  'Light blue': [
    '#001926',
    '#00293D',
    '#003A54',
    '#00141E',
    '#000F17',
    '#004967',
  ],
  'Green': ['#001B0F', '#002D1C', '#003F29', '#00160B', '#001008', '#004E33'],
  'Orange': ['#281000', '#421A07', '#572A18', '#200C00', '#190900', '#6A3520'],
  'Red': ['#2E0C00', '#451711', '#5A271F', '#240900', '#1D0600', '#6F3128'],
  'Purple': ['#1C112C', '#2E1E43', '#402E57', '#180B26', '#14081C', '#4F3A6B'],
  'Teal': ['#001921', '#002A36', '#003C4C', '#00141A', '#000F14', '#014A5E'],
  'Mustard': ['#211400', '#382100', '#4D300D', '#1B0F00', '#150B00', '#5F3C13'],
  'Pink': ['#2F0815', '#471324', '#5C2334', '#29040F', '#20030B', '#712D41'],
  'Olive': ['#121900', '#1B2B00', '#293C11', '#0E1400', '#0A0F00', '#344A17'],
  'Royal blue': [
    '#131430',
    '#212248',
    '#32325C',
    '#100E29',
    '#0E0A1E',
    '#3F3E71',
  ],
  'Violet': ['#1F102B', '#311D42', '#432D55', '#1A0B24', '#15071B', '#533868'],
  'Slate': ['#071729', '#182739', '#29374B', '#011224', '#000E1D', '#374559'],
  'Navy': ['#001730', '#012749', '#1A375C', '#001228', '#010D1F', '#2A446A'],
  'Yellow': ['#1E1500', '#322400', '#463309', '#181000', '#130C00', '#56400E'],
};

/// §5b, Light: page, input, chip (well), hairline, border, drop (lip).
const _light = {
  'Blue': ['#F5F4FC', '#F8F7FD', '#ECEAF8', '#E4E2F3', '#DBD9EF', '#D2CFEA'],
  'Light blue': [
    '#EFF6FD',
    '#F3F9FE',
    '#E1EEF8',
    '#D7E6F3',
    '#C8DEF0',
    '#BBD5EB',
  ],
  'Green': ['#EEF7F2', '#F3FAF6', '#E0EFE7', '#D6E8DE', '#C7E1D3', '#BAD9C9'],
  'Orange': ['#FDF3EF', '#FEF7F4', '#F9E8E2', '#F4E0D8', '#F1D5CB', '#ECCBBF'],
  'Red': ['#FEF3F0', '#FFF6F5', '#FAE8E4', '#F6DFDB', '#F3D4CE', '#EECAC3'],
  'Purple': ['#F7F4FB', '#FAF7FD', '#F0E9F6', '#E9E1F1', '#E2D7EC', '#DACDE6'],
  'Teal': ['#EDF7FB', '#F2F9FD', '#DEEFF6', '#D3E7F1', '#C2E0ED', '#B4D7E7'],
  'Mustard': ['#FBF4ED', '#FDF7F2', '#F6EADF', '#F0E2D5', '#ECD8C6', '#E5CEB9'],
  'Pink': ['#FEF2F4', '#FFF6F8', '#FAE7EB', '#F5DFE3', '#F2D3D9', '#EDC9D0'],
  'Olive': ['#F3F6EE', '#F7F9F3', '#E9EEE1', '#E0E6D6', '#D6DEC8', '#CCD6BC'],
  'Royal blue': [
    '#F5F4FC',
    '#F8F7FD',
    '#ECEAF8',
    '#E5E2F3',
    '#DCD8EF',
    '#D2CFEA',
  ],
  'Violet': ['#F8F3FB', '#FAF7FC', '#F1E9F6', '#EAE1F0', '#E3D6EB', '#DCCDE5'],
  'Slate': ['#F1F5FD', '#F5F8FE', '#E5ECF9', '#DCE5F4', '#CFDCF1', '#C4D3EC'],
  'Navy': ['#F2F5FD', '#F6F8FE', '#E7ECF9', '#DEE4F4', '#D2DBF1', '#C7D2EC'],
  'Yellow': ['#FAF4ED', '#FCF8F2', '#F3EBDF', '#EDE3D4', '#E7D9C5', '#E0D0B8'],
};

/// §5c, Candy: the page, the text on it, and the title (and page) shadow.
const _candy = {
  'Blue': ['#2F5BEA', '#FFFFFF', '#0D163D'],
  'Light blue': ['#7BAFD4', '#0D163D', '#FFFFFF'],
  'Green': ['#01855B', '#FFFFFF', '#0D163D'],
  'Orange': ['#C2410C', '#FFFFFF', '#0D163D'],
  'Red': ['#B91C1C', '#FFFFFF', '#0D163D'],
  'Purple': ['#7C3AED', '#FFFFFF', '#0D163D'],
  'Teal': ['#0E7490', '#FFFFFF', '#0D163D'],
  'Mustard': ['#A16207', '#FFFFFF', '#0D163D'],
  'Pink': ['#BE185D', '#FFFFFF', '#0D163D'],
  'Olive': ['#4D7C0F', '#FFFFFF', '#0D163D'],
  'Royal blue': ['#1D4ED8', '#FFFFFF', '#0D163D'],
  'Violet': ['#9333EA', '#FFFFFF', '#0D163D'],
  'Slate': ['#334155', '#FFFFFF', '#6F7D94'],
  'Navy': ['#1E3A5F', '#FFFFFF', '#5E759F'],
  'Yellow': ['#D4A017', '#0D163D', '#FFFFFF'],
};

/// The team hues that are Gumdrop's own navy keep the default Dark and
/// Light colors (the 25° rule), so their table rows, which show the plain
/// formula, aren't used.
const _sameHue = {'Blue', 'Royal blue', 'Slate', 'Navy'};

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

    test('Gumdrop Pop Dark matches table 5a', () {
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
      final yellow = teamTinted(
        GumdropColors.candy,
        teamColorValues[_names.indexOf('Yellow')],
      );
      expect(yellow.you.lip, yellow.ink);
      expect(yellow.lemon.lip, yellow.ink);
      // Hard shadows on the page stay ink where ink shows, and lift where
      // it wouldn't (Slate, Navy).
      final slate = teamTinted(GumdropColors.candy, teamColorValues[12]);
      expect(slate.pageShadow, _near('#6F7D94'));
      final lightBlue = teamTinted(GumdropColors.candy, teamColorValues[1]);
      expect(lightBlue.pageShadow, GumdropColors.candy.ink);
      // The red team's badge gets an ink ring, not a red gap.
      final red = teamTinted(GumdropColors.candy, teamColorValues[4]);
      expect(red.badgeRing, red.ink);
    });

    test('a tinted card context is the tinted theme on a card', () {
      final page = teamTinted(GumdropColors.candy, teamColorValues[1]);
      final card = teamTinted(GumdropColors.candy.card, teamColorValues[1]);
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
