// The Gumdrop Pop themes (SPEC §7.3, §7.4, SET-2, TEAM-1): a team's color
// as the page in every theme, with readable text, shadows, and edges on it,
// and 4.5:1 text contrast for every text role in every theme and team
// color.
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

/// Every theme's page in each team color, with the text on it and the
/// heading (and page) shadow: the team's own color, as in Candy (Green a
/// little darker, so white reads). "ink" is the theme's own ink. Dark and
/// Light keep their own pages for Blue and Navy ([_ownPage]).
const _teamPages = {
  'Blue': ['#2F5BEA', 'white', 'ink'],
  'Light blue': ['#7BAFD4', 'ink', 'white'],
  'Navy': ['#1E3A5F', 'white', '#5E759F'],
  'Teal': ['#0E7490', 'white', 'ink'],
  'Green': ['#01855B', 'white', 'ink'],
  'Olive': ['#4D7C0F', 'white', 'ink'],
  'Yellow': ['#D4A017', 'ink', 'white'],
  'Mustard': ['#A16207', 'white', 'ink'],
  'Orange': ['#C2410C', 'white', 'ink'],
  'Red': ['#B91C1C', 'white', 'ink'],
  'Maroon': ['#7F1D1D', 'white', '#C95E55'],
  'Pink': ['#BE185D', 'white', 'ink'],
  'Purple': ['#7C3AED', 'white', 'ink'],
  'Gray': ['#334155', 'white', '#6F7D94'],
  'Black': ['#111111', 'white', '#474747'],
};

/// The team colors that are Gumdrop's own navy: Dark and Light keep their
/// own pages for them (the 25° rule). Gray is in that hue too, but it's a
/// gray.
const _ownPage = {'Blue', 'Navy'};

/// The grays (Gray, Black).
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

    test("the page is the team's own color in every theme, not a blend", () {
      for (final flavor in GumdropFlavor.values) {
        final base = GumdropColors.forFlavor(flavor);
        for (final (i, name) in _names.indexed) {
          final what = '$name ${flavor.name}';
          final c = teamTinted(base, teamColorValues[i]);
          expect(c.teamColor, Color(teamColorValues[i]), reason: what);
          if (flavor != GumdropFlavor.candy && _ownPage.contains(name)) {
            continue;
          }
          final [page, text, shadow] = _teamPages[name]!;
          Color named(String color) => switch (color) {
            'white' => const Color(0xFFFFFFFF),
            'ink' => base.ink,
            _ => _hex(color),
          };
          expect(c.coloredPage, isTrue, reason: what);
          expect(c.page, _near(page), reason: '$what page');
          expect(c.textOnPage, named(text), reason: '$what text');
          expect(c.headingText, named(text), reason: '$what heading');
          expect(c.headingShadow, _near(ColorMath.hex(named(shadow))));
          // Hard shadows on the page (the back button, the sticker) show.
          expect(
            ColorMath.contrast(c.pageShadow, c.page),
            greaterThanOrEqualTo(2),
            reason: '$what page shadow ${ColorMath.hex(c.pageShadow)}',
          );
          expect(c.badgeRing, anyOf(c.page, c.ink), reason: what);
          // Each theme keeps its own cards, inputs, text on cards, and
          // candy faces.
          expect(c.surface, base.surface, reason: what);
          expect(c.inputFill, base.inputFill, reason: what);
          expect(c.textPrimary, base.textPrimary, reason: what);
          expect(c.headingTextOnCard, base.headingTextOnCard, reason: what);
          expect(c.you.face, base.you.face, reason: what);
          expect(c.raisedFace, base.raisedFace, reason: what);
        }
      }
      // A gray is the gray itself: Black's page is black in every theme.
      for (final flavor in GumdropFlavor.values) {
        final black = teamTinted(
          GumdropColors.forFlavor(flavor),
          _argb('Black'),
        );
        expect(black.page, const Color(0xFF111111), reason: flavor.name);
        expect(black.textOnPage, const Color(0xFFFFFFFF), reason: flavor.name);
      }
    });

    test('Dark and Light keep their own pages for Blue and Navy', () {
      for (final (i, name) in _names.indexed) {
        expect(
          isGumdropHue(Color(teamColorValues[i])),
          _ownPage.contains(name),
          reason: name,
        );
        expect(
          isGray(Color(teamColorValues[i])),
          _grays.contains(name),
          reason: name,
        );
      }
      for (final base in [GumdropColors.dark, GumdropColors.light]) {
        for (final name in _ownPage) {
          final c = teamTinted(base, _argb(name));
          expect(c.page, base.page, reason: '$name ${base.flavor}');
          expect(c.coloredPage, isFalse, reason: '$name ${base.flavor}');
        }
      }
    });

    test('a candy or button that melts into the page gets an ink edge', () {
      // Lemon on a Yellow team's page: an ink lip on you (Candy) and maybe.
      final yellow = teamTinted(GumdropColors.candy, _argb('Yellow'));
      expect(yellow.you.lip, yellow.ink);
      expect(yellow.lemon.lip, yellow.ink);
      // Light blue's page and Dark's blue: an ink lip on your color.
      final lightBlue = teamTinted(GumdropColors.dark, _argb('Light blue'));
      expect(lightBlue.you.lip, lightBlue.ink);
      // Dark's navy buttons on Gray and Black get an ink outline and lip;
      // on Yellow they stand out as they are.
      for (final name in ['Gray', 'Black']) {
        final c = teamTinted(GumdropColors.dark, _argb(name));
        expect(c.raisedBorder, c.ink, reason: name);
        expect(c.raisedBorderWidth, 2, reason: name);
        expect(c.raisedLip, c.ink, reason: name);
      }
      final onYellow = teamTinted(GumdropColors.dark, _argb('Yellow'));
      expect(onYellow.raisedLip, GumdropColors.dark.raisedLip);
      expect(onYellow.raisedBorderWidth, 0);
      // On every team page, every candy either stands out from the page or
      // has an ink lip. A theme's own page is as designed: Dark's and
      // Light's for Blue and Navy, and Candy's blue for Blue.
      for (final flavor in GumdropFlavor.values) {
        for (final (i, name) in _names.indexed) {
          if (flavor == GumdropFlavor.candy
              ? name == 'Blue'
              : _ownPage.contains(name)) {
            final c = teamTinted(
              GumdropColors.forFlavor(flavor),
              teamColorValues[i],
            );
            final own = GumdropColors.forFlavor(flavor);
            expect(c.grape, own.grape, reason: '$name ${flavor.name}');
            expect(c.raisedLip, own.raisedLip, reason: '$name ${flavor.name}');
            continue;
          }
          final c = teamTinted(
            GumdropColors.forFlavor(flavor),
            teamColorValues[i],
          );
          for (final a in [
            c.you,
            c.lemon,
            c.mint,
            c.cherry,
            c.tangerine,
            c.grape,
            c.bubblegum,
          ]) {
            expect(
              ColorMath.contrast(a.face, c.page) >= edgeContrast ||
                  a.lip == c.ink,
              isTrue,
              reason: '$name ${flavor.name} ${ColorMath.hex(a.face)}',
            );
          }
        }
      }
      // The red teams' badges get an ink ring, not a red gap.
      for (final flavor in GumdropFlavor.values) {
        for (final name in ['Red', 'Maroon']) {
          final c = teamTinted(GumdropColors.forFlavor(flavor), _argb(name));
          expect(c.badgeRing, c.ink, reason: '$name ${flavor.name}');
        }
      }
    });

    test("a team page's brightness follows the text on it", () {
      final red = teamTinted(GumdropColors.light, _argb('Red'));
      expect(red.brightness, Brightness.dark);
      expect(red.card.brightness, Brightness.light);
      final yellow = teamTinted(GumdropColors.dark, _argb('Yellow'));
      expect(yellow.brightness, Brightness.light);
      expect(yellow.card.brightness, Brightness.dark);
      expect(GumdropColors.candy.brightness, Brightness.dark);
      expect(GumdropColors.dark.brightness, Brightness.dark);
      expect(GumdropColors.light.brightness, Brightness.light);
    });

    test('a tinted card context is the tinted theme on a card', () {
      for (final flavor in GumdropFlavor.values) {
        final base = GumdropColors.forFlavor(flavor);
        final page = teamTinted(base, _argb('Light blue'));
        final card = teamTinted(base.card, _argb('Light blue'));
        expect(card.onCard, isTrue);
        expect(card.page, page.page);
        expect(card.textOnPage, base.textPrimary);
        expect(card.headingText, base.headingTextOnCard);
      }
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
      expect(c.page, const Color(0xFFC2410C));
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
