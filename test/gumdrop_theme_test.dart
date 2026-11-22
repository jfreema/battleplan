// Boot Camp Mix (SPEC §7.4, SET-2, #85) in its three color schemes: the
// tokens, how old picks are drawn, contrast, the card context, and the
// theme widgets.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The design's tokens (#85, #86), by name, in [bootCampSchemes]' order:
/// Army green, Black, Light, Sky Blue, Candy Pop, Central Wildcats, Geaux
/// Tigahs.
const _tokens = <String, List<int>>{
  'ink': [
    0xFF1A1A18, 0xFF000000, 0xFF1A1A18, //
    0xFF0B1531, 0xFF0B1640, 0xFF0B0B0B, 0xFF170730,
  ],
  'shadow': [
    0xFF1A1A18, 0xFF363A28, 0xFF1A1A18, //
    0xFF0B1531, 0xFF0B1640, 0xFF0B0B0B, 0xFF170730,
  ],
  'page': [
    0xFF474C2B, 0xFF0D0D0C, 0xFFF2EBE0, //
    0xFFBCD9F5, 0xFF1748D4, 0xFF5E1224, 0xFF461D7C,
  ],
  'pageDots': [
    0x331A1A18, 0x0EF4EAD0, 0x1A1A1A18, //
    0x210B1531, 0x21FFFFFF, 0x1CC0C5CC, 0x1CFDD023,
  ],
  'panel': [
    0xFF575A3A, 0xFF252522, 0xFFFFFFFF, //
    0xFFBCD9F5, 0xFFFFFFFF, 0xFF701C30, 0xFF55278F,
  ],
  'tabBar': [
    0xFF3D4124, 0xFF070707, 0xFFFFFFFF, //
    0xFFBCD9F5, 0xFF0B1640, 0xFF0B0B0B, 0xFF2E1157,
  ],
  'text': [
    0xFFF4EAD0, 0xFFF4EAD0, 0xFF1A1A18, //
    0xFF0B1531, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
  ],
  'muted': [
    0xFFD3CCAE, 0xFFB5B1A2, 0xFF5E584B, //
    0xFF34476E, 0xFFDCE6FF, 0xFFCDD1D8, 0xFFD5C6F0,
  ],
  'panelText': [
    0xFFF4EAD0, 0xFFF4EAD0, 0xFF1A1A18, //
    0xFF0B1531, 0xFF0B1640, 0xFFFFFFFF, 0xFFFFFFFF,
  ],
  'panelMuted': [
    0xFFD3CCAE, 0xFFB5B1A2, 0xFF5E584B, //
    0xFF34476E, 0xFF4B5A8C, 0xFFCDD1D8, 0xFFD5C6F0,
  ],
  'mustard': [
    0xFFF2C230, 0xFFF2C230, 0xFFEFBE2B, //
    0xFFF5C731, 0xFFFFD43A, 0xFFC9CED6, 0xFFFDD023,
  ],
  'balloon': [
    0xFFF2C230, 0xFF93CFF5, 0xFFEFBE2B, //
    0xFFF5C731, 0xFFFFD43A, 0xFFC9CED6, 0xFFFDD023,
  ],
  'red': [
    0xFFDB442F, 0xFFDB442F, 0xFFD4432C, //
    0xFFE2463A, 0xFFF2473D, 0xFFEE4B37, 0xFFE8473A,
  ],
  'blue': [
    0xFF5FA3C8, 0xFF4F93B9, 0xFF4A86A8, //
    0xFF4C90E2, 0xFF35B0FF, 0xFF5FA8E0, 0xFF5AA5EE,
  ],
  'green': [
    0xFF9AD04A, 0xFF8DC63F, 0xFF86B93B, //
    0xFF7CC84E, 0xFF5ED36A, 0xFF86C94A, 0xFF7FCB52,
  ],
  'orange': [
    0xFFF5A040, 0xFFF2983A, 0xFFEE9230, //
    0xFFF5943A, 0xFFFF9A2E, 0xFFF59A3A, 0xFFF79A3C,
  ],
  'purple': [
    0xFFAD8CD6, 0xFF9B79C4, 0xFF8C68AD, //
    0xFFA98BEB, 0xFFB58BFF, 0xFFB08AE0, 0xFFC7A6FF,
  ],
  'unansweredTag': [
    0xFF7E8160, 0xFF47473F, 0xFFDCD3C3, //
    0xFFE6F1FC, 0xFFC9D3EE, 0xFF8A5562, 0xFF7A56AE,
  ],
  'answerRow': [
    0xFF4C5130, 0xFF1B1B19, 0xFFFAEDB2, //
    0xFFFBEFB4, 0xFFFFF1B0, 0xFF5A1525, 0xFF481F7C,
  ],
  'toolsRow': [
    0xFF4C5130, 0xFF1A1A18, 0xFFE6DCCB, //
    0xFFA9CBEE, 0xFF1240B8, 0xFF681A2E, 0xFF4E2287,
  ],
  'disabledIcon': [
    0xFF8E9173, 0xFF64645C, 0xFFB2AB9B, //
    0xFF6F86AB, 0xFFA3B0D6, 0xFFA88892, 0xFF9A86C0,
  ],
  'camoGround': [
    0xFF3F4722, 0xFF23241F, 0xFFC7B787, //
    0xFF2F5596, 0xFF1238A8, 0xFF55111F, 0xFF3F1A72,
  ],
  'camoBig': [
    0xFF2A3016, 0xFF161713, 0xFFA69468, //
    0xFF1E3A70, 0xFF0C2A86, 0xFF350A14, 0xFF2A0F50,
  ],
  'camoMid': [
    0xFF7F7A48, 0xFF3A3C33, 0xFFE0D4AC, //
    0xFF6390CC, 0xFF3F6FF2, 0xFF8A2E42, 0xFF6C3DB0,
  ],
  'camoSmall': [
    0xFF14170B, 0xFF070706, 0xFF6E6143, //
    0xFF0E1D42, 0xFF0B1640, 0xFF0B0B0B, 0xFF150628,
  ],
  'headerHalftone': [
    0x33F4EAD0, 0x1FF4EAD0, 0x73FFFFFF, //
    0x57FFFFFF, 0x38FFFFFF, 0x24FFFFFF, 0x29FFFFFF,
  ],
  'headerLettering': [
    0xFFF4EAD0, 0xFFF4EAD0, 0xFF1A1A18, //
    0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
  ],
  'ballChain': [
    0xFF1A1A18, 0xFF77786E, 0xFF1A1A18, //
    0xFF0B1531, 0xFFDCE6FF, 0xFFC0C5CC, 0xFFFDD023,
  ],
};

/// Each token's value in [p], by the name the design uses.
Map<String, Color> _palette(CampPalette p) => {
  'ink': p.ink,
  'shadow': p.shadow,
  'page': p.page,
  'pageDots': p.pageDots,
  'panel': p.panel,
  'tabBar': p.tabBar,
  'text': p.text,
  'muted': p.muted,
  'panelText': p.panelText,
  'panelMuted': p.panelMuted,
  'mustard': p.mustard,
  'balloon': p.balloon,
  'red': p.red,
  'blue': p.blue,
  'green': p.green,
  'orange': p.orange,
  'purple': p.purple,
  'unansweredTag': p.unansweredTag,
  'answerRow': p.answerRow,
  'toolsRow': p.toolsRow,
  'disabledIcon': p.disabledIcon,
  'camoGround': p.camoGround,
  'camoBig': p.camoBig,
  'camoMid': p.camoMid,
  'camoSmall': p.camoSmall,
  'headerHalftone': p.headerHalftone,
  'headerLettering': p.headerLettering,
  'ballChain': p.ballChain,
};

/// [fg] composited over [bg] (translucent roles), then the contrast.
double _contrast(Color fg, Color bg) =>
    ColorMath.contrast(Color.alphaBlend(fg, bg), bg);

void _reads(Color fg, Color bg, String what, {double min = 4.5}) {
  final ratio = _contrast(fg, bg);
  expect(
    ratio,
    greaterThanOrEqualTo(min),
    reason: '$what: ${ratio.toStringAsFixed(2)}:1',
  );
}

void main() {
  group('the tokens (#85)', () {
    for (final (i, scheme) in bootCampSchemes.indexed) {
      test('${scheme.value} matches the design', () {
        final p = SchemeRoles.of(scheme).palette;
        final tokens = _palette(p);
        expect(tokens.keys.toSet(), _tokens.keys.toSet());
        for (final MapEntry(key: token, value: values) in _tokens.entries) {
          expect(
            tokens[token]!.toARGB32(),
            values[i],
            reason: '${scheme.value} $token',
          );
        }
        expect(CampPalette.cantGo, const Color(0xFFFF8A80));
        expect(CampPalette.titleFill, const Color(0xFFFFFFFF));
      });

      test('${scheme.value}: the roles come from the tokens', () {
        final r = SchemeRoles.of(scheme);
        final p = r.palette;
        // Candy Pop letters its page white and its white panels navy (#86):
        // its text boxes and menus opened from the page take a deeper blue.
        final two = p.panelText != p.text;
        final field = two ? p.camoGround : p.panel;
        expect(r.page, p.page);
        expect(r.text, p.text);
        expect(r.cardText, p.panelText);
        expect(
          r.pageMuted,
          ColorMath.readable(p.muted, [
            p.page,
            field,
            p.tabBar,
            if (!two) p.panel,
          ]),
        );
        expect(r.card, p.panel);
        expect(r.field, field);
        expect(r.popup, field);
        expect(r.tabbar, p.tabBar);
        for (final line in [
          r.hairline,
          r.outline,
          r.tabbarLine,
          r.fieldRim,
          r.cardRim,
          r.cardOutline,
          r.candyInk,
        ]) {
          expect(line, p.ink);
        }
        expect(r.titleDrop, p.shadow);
        expect(r.accentMark, p.mustard);
        expect(r.you, p.balloon);
      });
    }

    test('the seven are offered, and Black is the default', () {
      expect(ThemeCatalog.available, [
        TeamScheme.army,
        TeamScheme.dark,
        TeamScheme.light,
        TeamScheme.sky,
        TeamScheme.candypop,
        TeamScheme.wildcat,
        TeamScheme.purplegold,
      ]);
      expect(defaultTeamScheme, TeamScheme.dark);
    });

    test('every other stored scheme is drawn in the closest of the seven, and '
        'never rewritten', () {
      const want = {
        TeamScheme.army: TeamScheme.army,
        TeamScheme.darkarmy: TeamScheme.army,
        TeamScheme.light: TeamScheme.light,
        TeamScheme.sky: TeamScheme.sky,
        // Sky Blue Pop is Sky Blue now (#86).
        TeamScheme.skyblue: TeamScheme.sky,
        TeamScheme.candypop: TeamScheme.candypop,
        TeamScheme.dark: TeamScheme.dark,
        TeamScheme.navy: TeamScheme.dark,
        TeamScheme.wildcat: TeamScheme.wildcat,
        TeamScheme.purplegold: TeamScheme.purplegold,
        TeamScheme.scoreboard: TeamScheme.dark,
        // A saved slot with nothing in it.
        TeamScheme.custom1: TeamScheme.dark,
      };
      for (final MapEntry(key: stored, value: look) in want.entries) {
        expect(stored.look, look, reason: stored.value);
        expect(
          identical(SchemeRoles.of(stored), SchemeRoles.of(look)),
          isTrue,
          reason: stored.value,
        );
        expect(GumdropColors.forScheme(stored).roles.palette, isNotNull);
      }
    });

    test("the candies are the scheme's colors", () {
      for (final scheme in bootCampSchemes) {
        final c = GumdropColors.forScheme(scheme);
        final p = c.roles.palette;
        expect(c.you.face, p.balloon, reason: scheme.value);
        expect(c.sticker.face, p.balloon);
        expect(c.cherry.face, p.red);
        expect(c.coral.face, p.red);
        expect(c.tangerine.face, p.red);
        expect(c.mint.face, p.green);
        expect(c.lemon.face, p.orange);
        expect(c.grape.face, p.blue);
        expect(c.blueRaspberry.face, p.blue);
        expect(c.bubblegum.face, p.purple);
      }
      // Your balloon: mustard, but light blue in Black.
      expect(
        GumdropColors.forScheme(TeamScheme.army).you.face,
        const Color(0xFFF2C230),
      );
      expect(
        GumdropColors.forScheme(TeamScheme.dark).you.face,
        const Color(0xFF93CFF5),
      );
    });

    // "Lettering on any bright block is always ink" (#85); on the reds, and
    // Light's blue and purple, black, where the ink doesn't quite read.
    test('lettering on a colored block reads', () {
      for (final scheme in bootCampSchemes) {
        final c = GumdropColors.forScheme(scheme);
        for (final candy in [c.you, c.mint, c.lemon, c.sticker]) {
          expect(c.inkOn(candy), c.ink, reason: scheme.value);
        }
        for (final (candy, name) in [
          (c.you, 'your color'),
          (c.mint, 'green'),
          (c.lemon, 'orange'),
          (c.cherry, 'red'),
          (c.tangerine, 'game red'),
          (c.grape, 'blue'),
          (c.bubblegum, 'purple'),
          (c.blueRaspberry, 'blue raspberry'),
        ]) {
          _reads(c.inkOn(candy), candy.face, '${scheme.value} ink on $name');
        }
        _reads(c.ink, c.roles.palette.mustard, '${scheme.value} on mustard');
      }
    });

    test("light pages are Light and Sky Blue; cards agree but Candy Pop's "
        'white ones', () {
      expect(bootCampSchemes.where((s) => !s.isDark), [
        TeamScheme.light,
        TeamScheme.sky,
      ]);
      for (final scheme in bootCampSchemes) {
        final want = scheme.isDark ? Brightness.dark : Brightness.light;
        final card = scheme == TeamScheme.candypop ? Brightness.light : want;
        expect(GumdropColors.forScheme(scheme).brightness, want);
        expect(GumdropColors.forScheme(scheme, onCard: true).brightness, card);
        expect(AppTheme.of(scheme).brightness, want);
        expect(AppTheme.of(scheme, onCard: true).brightness, card);
      }
    });

    test("the camouflage is lettered in its own color: white on Sky Blue's "
        'blue one, over a page lettered in navy (#86)', () {
      final sky = SchemeRoles.sky.palette;
      expect(sky.headerLettering, const Color(0xFFFFFFFF));
      expect(sky.text, isNot(sky.headerLettering));
      for (final scheme in bootCampSchemes) {
        final p = SchemeRoles.of(scheme).palette;
        expect(
          ColorMath.contrast(p.headerLettering, p.camoGround),
          greaterThanOrEqualTo(4.5),
          reason: scheme.value,
        );
      }
    });
  });

  group('contrast (Appendix A.4)', () {
    for (final scheme in bootCampSchemes) {
      test('${scheme.value}: every text role reads on what it sits on', () {
        final r = SchemeRoles.of(scheme);
        for (final (fg, bg, what) in [
          (r.text, r.page, 'text on page'),
          (r.cardText, r.card, 'card text on card'),
          (r.text, r.tabbar, 'text on tab bar'),
          (r.text, r.field, 'text on field'),
          (r.text, r.popup, 'text on pop-ups'),
          (r.cardText, r.cardField, 'card text on a card field'),
          (r.cardMuted, r.cardField, 'card-muted on a card field'),
          (r.pageMuted, r.page, 'page-muted on page'),
          (r.pageMuted, r.tabbar, 'page-muted on tab bar'),
          (r.pageMuted, r.field, 'page-muted on field'),
          (r.cardMuted, r.card, 'card-muted on card'),
          (r.accentText, r.page, 'accent-text on page'),
          (r.goingText, r.page, 'going-text on page'),
          (r.maybeText, r.page, 'maybe-text on page'),
          (r.cardMaybeText, r.card, 'card-maybe-text on card'),
          (r.gameText, r.page, 'game-text on page'),
          (r.cardGoingText, r.card, 'card-going-text on card'),
          (r.cardAccentText, r.card, 'card-accent-text on card'),
          (r.typeGame, r.card, 'type-game on card'),
          (r.typePractice, r.card, 'type-practice on card'),
          (r.typeOther, r.card, 'type-other on card'),
          // The derived page and card texts (A.3).
          (r.grapePageText, r.page, 'grape on page'),
          (r.bubblegumPageText, r.page, 'bubblegum on page'),
          (r.blueRaspberryPageText, r.page, 'blue raspberry on page'),
          (r.blueRaspberryCardText, r.card, 'blue raspberry on card'),
        ]) {
          _reads(fg, bg, '${scheme.value} $what');
        }
        // Marks need 3:1: the not-going icon, and the mustard tags and
        // tiles, which carry an ink outline besides.
        _reads(r.notGoingIcon, r.page, 'not-going icon', min: 3);
        _reads(r.palette.ink, r.palette.mustard, 'ink on mustard');
      });
    }
  });

  group('the card context (4.3)', () {
    for (final scheme in bootCampSchemes) {
      test('${scheme.value}: the card texts take their places', () {
        final r = SchemeRoles.of(scheme);
        final page = GumdropColors.forScheme(scheme);
        final card = page.card;
        expect(card.onCard, isTrue);
        expect(card.scheme, scheme);
        // Your color as text, made to read where it sits.
        expect(page.you.text, ColorMath.readable(r.you, [r.page]));
        expect(card.you.text, ColorMath.readable(r.you, [r.card]));
        expect(page.mint.text, r.goingText);
        expect(card.mint.text, r.cardGoingText);
        expect(page.lemon.text, r.maybeText);
        expect(card.lemon.text, r.cardMaybeText);
        expect(page.tangerine.text, r.gameText);
        expect(card.tangerine.text, r.typeGame);
        expect(card.grape.text, r.typePractice);
        expect(card.bubblegum.text, r.typeOther);
        expect(card.blueRaspberry.text, r.blueRaspberryCardText);
        expect(page.textMutedOnPage, r.pageMuted);
        expect(card.textMutedOnPage, r.cardMuted);
        // On Candy Pop's blue page its wells are its text boxes' deeper
        // blue (#86).
        expect(page.well, r.cardText == r.text ? r.cardTrack : r.field);
        expect(card.well, r.cardTrack);
        // Plain headings have no drop; big titles are outlined.
        expect(page.headingShadow.a, 0);
        expect(card.headingShadow.a, 0);
        expect(page.pageShadow, r.palette.shadow);
        expect(card.notGoingIcon, r.cardAccentText);
        expect(card.badgeRing, r.card);
        expect(page.badgeRing, r.page);
        // The card's own text and fields, and Material's pop-ups.
        expect(page.textPrimary, r.text);
        expect(card.textPrimary, r.cardText);
        expect(card.textOnPage, r.cardText);
        expect(card.headingText, r.cardText);
        expect(page.headingTextOnCard, r.cardText);
        expect(page.inputFill, r.field);
        expect(card.inputFill, r.cardField);
        expect(page.popup, r.popup);
        expect(card.popup, r.card);
      });
    }

    test('a bare MaterialApp falls back to Army green', () {
      expect(AppColors.fallback.going, isNotNull);
    });
  });

  group("the Material theme's text reads (SPEC §7.6)", () {
    for (final scheme in bootCampSchemes) {
      for (final onCard in [false, true]) {
        final where = '${scheme.value} ${onCard ? 'card' : 'page'}';
        test(where, () {
          final theme = AppTheme.of(scheme, onCard: onCard);
          final s = theme.colorScheme;
          // Low is the cards and sheets, whose content is in the card
          // context (its own check): from the page, only the containers
          // Material draws its own rows on (menus, pickers) need the page's
          // text to read. They're one color but in Candy Pop (#72).
          for (final (bg, name) in [
            (s.surface, 'surface'),
            (s.surfaceContainerLowest, 'lowest'),
            if (onCard) (s.surfaceContainerLow, 'low'),
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
            _reads(fg, s.surfaceContainer, '$where $name on pop-ups');
            if (onCard) {
              _reads(fg, s.surfaceContainerLow, '$where $name on cards');
            }
          }
          if (!onCard && scheme != TeamScheme.candypop) {
            // Panels and pop-ups are one color, but in Candy Pop, whose
            // pop-ups from the page are a deeper blue than its white panels.
            expect(s.surfaceContainerLow, s.surfaceContainer);
          }
          for (final (fg, bg, name) in [
            (s.onPrimary, s.primary, 'onPrimary'),
            (s.onSecondary, s.secondary, 'onSecondary'),
            (s.onTertiary, s.tertiary, 'onTertiary'),
            (s.onError, s.error, 'onError'),
            (s.onPrimaryContainer, s.primaryContainer, 'onPrimaryContainer'),
            (s.onTertiaryContainer, s.tertiaryContainer, 'onTertiaryContainer'),
            (s.onErrorContainer, s.errorContainer, 'onErrorContainer'),
            (s.onInverseSurface, s.inverseSurface, 'snack bar'),
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
          }
          _reads(app.onBubbleMine, app.bubbleMine, '$where my bubble');
          _reads(app.onBubbleOther, app.bubbleOther, "$where others' bubble");
        });
      }
    }
  });

  group('themes', () {
    test('built once per scheme and context, two each at most', () {
      for (final scheme in bootCampSchemes) {
        for (final onCard in [false, true]) {
          expect(
            identical(
              AppTheme.of(scheme, onCard: onCard),
              AppTheme.of(scheme, onCard: onCard),
            ),
            isTrue,
          );
        }
      }
      expect(
        AppTheme.cachedThemes,
        lessThanOrEqualTo(2 * bootCampSchemes.length),
      );
    });

    test('titles and labels are the stencil, with no drop; body text is '
        'Comic Neue', () {
      for (final scheme in bootCampSchemes) {
        final t = AppTheme.of(scheme).textTheme;
        expect(t.headlineMedium!.fontFamily, 'Battleplan Stencil');
        expect(t.headlineMedium!.fontWeight, FontWeight.w900);
        expect(t.headlineMedium!.shadows ?? const <Shadow>[], isEmpty);
        expect(t.labelLarge!.fontFamily, 'Battleplan Stencil');
        expect(t.bodyMedium!.fontFamily, 'Comic Neue');
      }
      expect(
        GumdropStyle.bootCamp.headingShadow(const Color(0xFF1A1A18)),
        isEmpty,
      );
      expect(GumdropStyle.bootCamp.accentOutline, 3);
      expect(GumdropStyle.stencilSpacing(20), 1);
    });

    test('panels are square, on a hard shadow down and to the right', () {
      final d = GumdropStyle.bootCamp.cardDecoration(
        const Color(0xFF575A3A),
        18,
        side: const BorderSide(color: Color(0xFF1A1A18), width: 3),
      ) as BoxDecoration;
      expect(d.borderRadius, BorderRadius.zero);
      expect(d.boxShadow!.single.offset, const Offset(4, 4));
      expect(d.boxShadow!.single.blurRadius, 0);
    });

    test(
      'a push button shifts down and right onto its shadow when pressed',
      () {
        const rect = Rect.fromLTWH(0, 0, 100, 40);
        const up = GumdropShape(lipColor: Color(0xFF1A1A18), lip: 3);
        final down = up.copyWith(pressed: 1);
        final lip = GumdropShape.lipFor(40);
        expect(lip, 3);
        expect(
          up.getInnerPath(rect).getBounds(),
          Rect.fromLTWH(0, 0, 100 - lip, 40 - lip),
        );
        expect(
          down.getInnerPath(rect).getBounds(),
          Rect.fromLTWH(lip, lip, 100 - lip, 40 - lip),
        );
        expect(up.getOuterPath(rect).getBounds(), rect);
        final half = ShapeBorder.lerp(up, down, 0.5)! as GumdropShape;
        expect(half.pressed, 0.5);
        expect(GumdropShape.lipFor(36), 2);
        expect(GumdropShape.lipFor(56), 3);
        expect(GumdropShape.lipFor(60), 4);
      },
    );
  });

  group('SchemeTheme', () {
    Future<(ThemeData, TextStyle)> pumpIn(
      WidgetTester tester,
      TeamScheme root,
      Widget Function(Widget child) wrap,
    ) async {
      late ThemeData seen;
      late TextStyle text;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.of(root),
          home: wrap(
            Builder(
              builder: (context) {
                seen = Theme.of(context);
                text = DefaultTextStyle.of(context).style;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return (seen, text);
    }

    testWidgets('draws its subtree in its scheme, with its text color', (
      tester,
    ) async {
      final (t, text) = await pumpIn(
        tester,
        TeamScheme.dark,
        (child) => Material(
          child: SchemeTheme(scheme: TeamScheme.light, child: child),
        ),
      );
      expect(t.extension<GumdropColors>()!.scheme, TeamScheme.light);
      expect(t.scaffoldBackgroundColor, SchemeRoles.light.page);
      // No stray cream text from the Black root.
      expect(text.color, SchemeRoles.light.text);
    });

    testWidgets('keeps the card context on a card', (tester) async {
      final (t, _) = await pumpIn(
        tester,
        TeamScheme.army,
        (child) => GumdropSurface(
          child: SchemeTheme(scheme: TeamScheme.light, child: child),
        ),
      );
      final c = t.extension<GumdropColors>()!;
      expect(c.scheme, TeamScheme.light);
      expect(c.onCard, isTrue);
      expect(t.colorScheme.surface, SchemeRoles.light.card);
    });
  });

  testWidgets("a list tile's title is in the text color and its subtitle "
      'muted, in every scheme', (tester) async {
    for (final scheme in bootCampSchemes) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.of(scheme),
          home: const Material(
            child: ListTile(title: Text('Coach Lee'), subtitle: Text('Owner')),
          ),
        ),
      );
      // Past the theme's change from the last scheme.
      await tester.pumpAndSettle();
      Color? color(String text) => tester
          .widget<RichText>(
            find.descendant(
              of: find.text(text),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style
          ?.color;
      final roles = SchemeRoles.of(scheme);
      expect(color('Coach Lee'), roles.text, reason: scheme.value);
      expect(color('Owner'), roles.pageMuted, reason: scheme.value);
    }
  });

  testWidgets('a team badge is ringed in ink', (tester) async {
    Future<Color?> edge(TeamScheme scheme, int color) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.of(scheme, onCard: true),
          home: TeamBadge(name: 'Thunder', color: Color(color), size: 48),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(TeamBadge),
          matching: find.byType(Container),
        ),
      );
      final border =
          (box.foregroundDecoration as BoxDecoration?)?.border as Border?;
      return border?.top.color;
    }

    // Every badge is ringed in ink, as everything is in Boot Camp Mix:
    // olive on Army green's panels, black on Black's, and a bright one.
    for (final (scheme, color) in [
      (TeamScheme.army, 0xFF575A3A),
      (TeamScheme.dark, 0xFF000000),
      (TeamScheme.dark, 0xFFF45B5B),
      (TeamScheme.light, 0xFFFFFFFF),
    ]) {
      expect(await edge(scheme, color), SchemeRoles.of(scheme).avatarRing);
    }
  });

  testWidgets('dialogs and sheets are in the card context', (tester) async {
    GumdropColors? seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(TeamScheme.army),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCardDialog<void>(
              context: context,
              builder: (context) {
                seen = GumdropColors.of(context);
                return const AlertDialog(content: Text('Hi'));
              },
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(seen!.onCard, isTrue);
    // An error under a field in a dialog reads on the card.
    _reads(seen!.cherry.text, seen!.surface, 'error text in a dialog');
  });
}
