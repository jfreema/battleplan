// Boot Camp Mix (SPEC §7.4, SET-2, #85) in its three color schemes: the
// tokens, how old picks are drawn, contrast, the card context, and the
// theme widgets.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/candy.dart';
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

/// The design's tokens (#85, #86, #89), by name, in [bootCampSchemes]'
/// order: Army green, Black, Light, Sky Blue, Royal & Gold (in Candy Pop's
/// place since #90), Central Wildcats, Geaux Tigahs, Graphite, Teal Wave,
/// Navy Steel, Forest, Tropic Blue, and Desert Tan.
const _tokens = <String, List<int>>{
  'ink': [
    0xFF1A1A18, 0xFF000000, 0xFF1A1A18, //
    0xFF0B1531, 0xFF050B24, 0xFF0B0B0B, 0xFF170730,
    0xFF070A0D, 0xFF021214, 0xFF02060F, 0xFF050D09,
    0xFF062033, 0xFF24231B,
    0xFF2B1A4A,
  ],
  'shadow': [
    0xFF1A1A18, 0xFF363A28, 0xFF1A1A18, //
    0xFF0B1531, 0xFF050B24, 0xFF0B0B0B, 0xFF170730,
    0xFF070A0D, 0xFF021214, 0xFF02060F, 0xFF050D09,
    0xFF062033, 0xFF24231B,
    0xFF2B1A4A,
  ],
  'page': [
    0xFF474C2B, 0xFF0D0D0C, 0xFFF2EBE0, //
    0xFFBCD9F5, 0xFF17307F, 0xFF5E1224, 0xFF461D7C,
    0xFF2B323B, 0xFF0B3B40, 0xFF101D3A, 0xFF0F2E1F,
    0xFF0A7EAC, 0xFFE4D6B4,
    0xFFFFF4EA,
  ],
  'pageDots': [
    0x331A1A18, 0x0EF4EAD0, 0x1A1A1A18, //
    0x210B1531, 0x12FFFFFF, 0x1CC0C5CC, 0x1CFDD023,
    0x0FF1F4F7, 0x12F0FBFA, 0x12F2F6FF, 0x0FFFFFFF,
    0x21FFFFFF, 0x1F24231B,
    0x24FF5FA8,
  ],
  'panel': [
    0xFF575A3A, 0xFF252522, 0xFFFFFFFF, //
    0xFFFFFFFF, 0xFF22409E, 0xFF701C30, 0xFF55278F,
    0xFF3A434E, 0xFF135058, 0xFF2B3850, 0xFF183E2C,
    0xFFFFFFFF, 0xFFF4ECD8,
    0xFFFFFFFF,
  ],
  'tabBar': [
    0xFF3D4124, 0xFF070707, 0xFFFFFFFF, //
    0xFFFFFFFF, 0xFF0E1E54, 0xFF0B0B0B, 0xFF2E1157,
    0xFF1E242B, 0xFF062A2E, 0xFF08101F, 0xFF081F14,
    0xFF062A45, 0xFFF4ECD8,
    0xFFFFFFFF,
  ],
  'text': [
    0xFFF4EAD0, 0xFFF4EAD0, 0xFF1A1A18, //
    0xFF0B1531, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
    0xFFF1F4F7, 0xFFF0FBFA, 0xFFF2F6FF, 0xFFFFFFFF,
    0xFFFFFFFF, 0xFF24231B,
    0xFF2B1A4A,
  ],
  'muted': [
    0xFFD3CCAE, 0xFFB5B1A2, 0xFF5E584B, //
    0xFF34476E, 0xFFC9D3F2, 0xFFCDD1D8, 0xFFD5C6F0,
    0xFFAEB8C4, 0xFFA9D3D0, 0xFFAFBACB, 0xFFB5CFC0,
    0xFFD8F1FF, 0xFF615A45,
    0xFF6E5F87,
  ],
  'panelText': [
    0xFFF4EAD0, 0xFFF4EAD0, 0xFF1A1A18, //
    0xFF0B1531, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
    0xFFF1F4F7, 0xFFF0FBFA, 0xFFF2F6FF, 0xFFFFFFFF,
    0xFF062033, 0xFF24231B,
    0xFF2B1A4A,
  ],
  'panelMuted': [
    0xFFD3CCAE, 0xFFB5B1A2, 0xFF5E584B, //
    0xFF34476E, 0xFFC9D3F2, 0xFFCDD1D8, 0xFFD5C6F0,
    0xFFAEB8C4, 0xFFA9D3D0, 0xFFAFBACB, 0xFFB5CFC0,
    0xFF3D5F7A, 0xFF615A45,
    0xFF6E5F87,
  ],
  'mustard': [
    0xFFF2C230, 0xFFF2C230, 0xFFEFBE2B, //
    0xFFF5C731, 0xFFF5C431, 0xFFC9CED6, 0xFFFDD023,
    0xFFFF7F66, 0xFF5CE1D3, 0xFFF2F5FA, 0xFFFFFFFF,
    0xFFFFD23F, 0xFFA3A95A,
    0xFFFF8CC6,
  ],
  'balloon': [
    0xFFF2C230, 0xFF93CFF5, 0xFFEFBE2B, //
    0xFFF5C731, 0xFFF5C431, 0xFFC9CED6, 0xFFFDD023,
    0xFFFF7F66, 0xFFFF8D75, 0xFFF2F5FA, 0xFFFFFFFF,
    0xFFFFD23F, 0xFFA3A95A,
    0xFFFF8CC6,
  ],
  'red': [
    0xFFDB442F, 0xFFDB442F, 0xFFD4432C, //
    0xFFE2463A, 0xFFE8473A, 0xFFEE4B37, 0xFFE8473A,
    0xFFF26A50, 0xFFFF6B57, 0xFFE2463A, 0xFFE5483A,
    0xFFFF5A4E, 0xFFC9452E,
    0xFFF2473D,
  ],
  'blue': [
    0xFF5FA3C8, 0xFF4F93B9, 0xFF4A86A8, //
    0xFF4C90E2, 0xFF6FC0FF, 0xFF5FA8E0, 0xFF5AA5EE,
    0xFF5AA7F0, 0xFF5AA7F0, 0xFF5AA0E0, 0xFF5BA8E0,
    0xFF4FCBF7, 0xFF4A86A8,
    0xFF35B0FF,
  ],
  'green': [
    0xFF9AD04A, 0xFF8DC63F, 0xFF86B93B, //
    0xFF7CC84E, 0xFF86D04F, 0xFF86C94A, 0xFF7FCB52,
    0xFF8DC63F, 0xFF8DD85A, 0xFF7CC84E, 0xFF8BDB5A,
    0xFF4FD38A, 0xFF6DB33F,
    0xFF5ED36A,
  ],
  'orange': [
    0xFFF5A040, 0xFFF2983A, 0xFFEE9230, //
    0xFFF5943A, 0xFFF79A3C, 0xFFF59A3A, 0xFFF79A3C,
    0xFFF5A93A, 0xFFFFB347, 0xFFF5943A, 0xFFF5A03A,
    0xFFFF9A2E, 0xFFE08A2E,
    0xFFFF9A2E,
  ],
  'purple': [
    0xFFAD8CD6, 0xFF9B79C4, 0xFF8C68AD, //
    0xFFA98BEB, 0xFFC3A6FF, 0xFFB08AE0, 0xFFC7A6FF,
    0xFFB49AF0, 0xFFB99AF0, 0xFFA98BEB, 0xFFB794E8,
    0xFFB58BFF, 0xFF8C68AD,
    0xFFB58BFF,
  ],
  'unansweredTag': [
    0xFF7E8160, 0xFF47473F, 0xFFDCD3C3, //
    0xFFE6F1FC, 0xFF4560B0, 0xFF8A5562, 0xFF7A56AE,
    0xFF4F5966, 0xFF3D6B70, 0xFF4A5670, 0xFF375A48,
    0xFFCDE7F2, 0xFFD3C6A6,
    0xFFEDE6F5,
  ],
  'answerRow': [
    0xFF4C5130, 0xFF1B1B19, 0xFFFAEDB2, //
    0xFFFBEFB4, 0xFF13286A, 0xFF5A1525, 0xFF481F7C,
    0xFF2E2A2D, 0xFF0A3035, 0xFF1A2742, 0xFF0C2619,
    0xFFFFF1B0, 0xFFE6E2C0,
    0xFFFFF0F7,
  ],
  'toolsRow': [
    0xFF4C5130, 0xFF1A1A18, 0xFFE6DCCB, //
    0xFFA9CBEE, 0xFF1A3486, 0xFF681A2E, 0xFF4E2287,
    0xFF2F3740, 0xFF10464D, 0xFF22304A, 0xFF14382A,
    0xFF0B76A3, 0xFFD8C9A5,
    0xFFF5E1EE,
  ],
  'disabledIcon': [
    0xFF8E9173, 0xFF64645C, 0xFFB2AB9B, //
    0xFF6F86AB, 0xFF7A8CC4, 0xFFA88892, 0xFF9A86C0,
    0xFF6F7A87, 0xFF5F8E91, 0xFF6B7790, 0xFF6A897A,
    0xFF9CC3D6, 0xFFA39A80,
    0xFFB6A9C9,
  ],
  'camoGround': [
    0xFF3F4722, 0xFF23241F, 0xFFC7B787, //
    0xFF2F5596, 0xFF1B3690, 0xFF55111F, 0xFF3F1A72,
    0xFF333B45, 0xFF0E4A50, 0xFF1C2840, 0xFF133524,
    0xFF0A6E99, 0xFFA8956A,
    0xFFFFC4DD,
  ],
  'camoBig': [
    0xFF2A3016, 0xFF161713, 0xFFA69468, //
    0xFF1E3A70, 0xFF112468, 0xFF350A14, 0xFF2A0F50,
    0xFF232A32, 0xFF083338, 0xFF121A2C, 0xFF0B2418,
    0xFF075478, 0xFF8A7A52,
    0xFFFF9FCB,
  ],
  'camoMid': [
    0xFF7F7A48, 0xFF3A3C33, 0xFFE0D4AC, //
    0xFF6390CC, 0xFF2F52B8, 0xFF8A2E42, 0xFF6C3DB0,
    0xFF4A5562, 0xFF1F6E73, 0xFF3A4760, 0xFF28543D,
    0xFF1E9CC8, 0xFFC9B88C,
    0xFFA9DCFF,
  ],
  'camoSmall': [
    0xFF14170B, 0xFF070706, 0xFF6E6143, //
    0xFF0E1D42, 0xFF070F33, 0xFF0B0B0B, 0xFF150628,
    0xFF12161B, 0xFF03191C, 0xFF060A14, 0xFF05110B,
    0xFF04324A, 0xFF5C5236,
    0xFFFFE27D,
  ],
  'headerHalftone': [
    0x33F4EAD0, 0x1FF4EAD0, 0x73FFFFFF, //
    0x57FFFFFF, 0x24FFFFFF, 0x24FFFFFF, 0x29FFFFFF,
    0x1FFFFFFF, 0x24F0FBFA, 0x21F2F6FF, 0x21FFFFFF,
    0x38FFFFFF, 0x47FFFFFF,
    0x8CFFFFFF,
  ],
  'headerLettering': [
    0xFFF4EAD0, 0xFFF4EAD0, 0xFF1A1A18, //
    0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
    0xFFF1F4F7, 0xFFF0FBFA, 0xFFF2F6FF, 0xFFFFFFFF,
    0xFFFFFFFF, 0xFF24231B,
    0xFF2B1A4A,
  ],
  'ballChain': [
    0xFF1A1A18, 0xFF77786E, 0xFF1A1A18, //
    0xFF0B1531, 0xFFF5C431, 0xFFC0C5CC, 0xFFFDD023,
    0xFFFF7F66, 0xFF5FE0D6, 0xFF8E9AB4, 0xFFCFE3D6,
    0xFFFFD23F, 0xFF24231B,
    0xFF2B1A4A,
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
        // Tropic Blue letters its page white and its white panels navy (#90,
        // as Candy Pop did in #86): its text boxes and menus opened from the
        // page take the camouflage's deeper blue.
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
            if (!two) ...[p.panel, p.toolsRow],
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
        // Sugar Rush's bubblegum (#98), elsewhere the shadow.
        expect(r.titleDrop, p.touches.titleDrop ?? p.shadow);
        expect(r.accentMark, p.mustard);
        expect(r.you, p.balloon);
      });
    }

    test('the fourteen are offered, and Black is the default', () {
      expect(ThemeCatalog.available, [
        TeamScheme.army,
        TeamScheme.dark,
        TeamScheme.light,
        TeamScheme.sky,
        TeamScheme.candypop,
        TeamScheme.wildcat,
        TeamScheme.purplegold,
        TeamScheme.graphite,
        TeamScheme.tealwave,
        TeamScheme.navy,
        TeamScheme.darkarmy,
        TeamScheme.tropicblue,
        TeamScheme.deserttan,
        TeamScheme.sugarrush,
      ]);
      expect(defaultTeamScheme, TeamScheme.dark);
    });

    test('every other stored scheme is drawn in the closest of the fourteen, '
        'and never rewritten', () {
      const want = {
        TeamScheme.army: TeamScheme.army,
        // Open Field's Forest green is Forest, and its Navy Navy Steel (#89).
        TeamScheme.darkarmy: TeamScheme.darkarmy,
        TeamScheme.light: TeamScheme.light,
        TeamScheme.sky: TeamScheme.sky,
        // Sky Blue Pop is Sky Blue now (#86).
        TeamScheme.skyblue: TeamScheme.sky,
        TeamScheme.candypop: TeamScheme.candypop,
        TeamScheme.dark: TeamScheme.dark,
        TeamScheme.navy: TeamScheme.navy,
        TeamScheme.graphite: TeamScheme.graphite,
        TeamScheme.tealwave: TeamScheme.tealwave,
        TeamScheme.tropicblue: TeamScheme.tropicblue,
        TeamScheme.deserttan: TeamScheme.deserttan,
        TeamScheme.sugarrush: TeamScheme.sugarrush,
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

    test('light pages are Light, Sky Blue, Desert Tan and Sugar Rush; cards '
        "agree but Tropic Blue's white ones", () {
      expect(bootCampSchemes.where((s) => !s.isDark), [
        TeamScheme.light,
        TeamScheme.sky,
        TeamScheme.deserttan,
        TeamScheme.sugarrush,
      ]);
      for (final scheme in bootCampSchemes) {
        final want = scheme.isDark ? Brightness.dark : Brightness.light;
        final card = scheme == TeamScheme.tropicblue ? Brightness.light : want;
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
        // On Tropic Blue's blue page its wells are its text boxes' deeper
        // blue (#90, as on Candy Pop's in #86).
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
          // text to read. They're one color but in Tropic Blue (#72, #90).
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
          if (!onCard && scheme != TeamScheme.tropicblue) {
            // Panels and pop-ups are one color, but in Tropic Blue, whose
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
        'Nunito SemiBold', () {
      for (final scheme in bootCampSchemes) {
        final t = AppTheme.of(scheme).textTheme;
        expect(t.headlineMedium!.fontFamily, 'Battleplan Stencil');
        expect(t.headlineMedium!.fontWeight, FontWeight.w900);
        expect(t.headlineMedium!.shadows ?? const <Shadow>[], isEmpty);
        expect(t.labelLarge!.fontFamily, 'Battleplan Stencil');
        // Reading text is Nunito SemiBold in every scheme (#97).
        for (final body in [t.bodyLarge!, t.bodyMedium!, t.bodySmall!]) {
          expect(body.fontFamily, 'Nunito');
          expect(body.fontWeight, FontWeight.w600);
        }
      }
      expect(
        GumdropStyle.bootCamp.headingShadow(const Color(0xFF1A1A18)),
        isEmpty,
      );
      expect(GumdropStyle.bootCamp.accentOutline, 3);
      expect(GumdropStyle.stencilSpacing(20), 1);
    });

    test('panels have corners of 15, on a hard shadow down and to the '
        "right; Sugar Rush's 20, on a lavender lip (#98)", () {
      const side = BorderSide(color: Color(0xFF1A1A18), width: 3);
      final d = GumdropStyle.bootCamp.cardDecoration(
        const Color(0xFF575A3A),
        18,
        side: side,
      ) as BoxDecoration;
      expect(d.borderRadius, BorderRadius.circular(15));
      expect(d.boxShadow!.single.offset, const Offset(4, 4));
      expect(d.boxShadow!.single.blurRadius, 0);
      final sugar = GumdropStyle.forPalette(CampPalette.sugarRush);
      expect(sugar.panelRadius, 20);
      expect(sugar.pills, isTrue);
      final lipped = sugar.cardDecoration(
        const Color(0xFFFFFFFF),
        18,
        side: side,
      ) as BoxDecoration;
      expect(lipped.borderRadius, BorderRadius.circular(20));
      // The ink 7 down, then the lavender band in it, 3 in at each side.
      expect(lipped.boxShadow!.first.color, side.color);
      expect(lipped.boxShadow!.first.offset, const Offset(0, 7));
      expect(lipped.boxShadow!.last.color, const Color(0xFFE3D7F7));
      expect(lipped.boxShadow!.last.spreadRadius, -3);
      expect(GumdropStyle.forPalette(CampPalette.army), GumdropStyle.bootCamp);
    });

    test('a push button sinks straight down onto its lip when pressed, its '
        'ink staying put (#98)', () {
      const rect = Rect.fromLTWH(0, 0, 100, 48);
      const up = GumdropShape(
        lipColor: Color(0xFFC28E0E),
        lipEdge: Color(0xFF1A1A18),
      );
      final down = up.copyWith(pressed: 1);
      // 7 under the usual 48 px button, sinking 3 onto a lip 4 deep.
      expect(up.lip, 7);
      expect(up.sink, 3);
      expect(
        up.getInnerPath(rect).getBounds(),
        const Rect.fromLTWH(0, 0, 100, 41),
      );
      expect(
        down.getInnerPath(rect).getBounds(),
        const Rect.fromLTWH(0, 3, 100, 41),
      );
      expect(up.getOuterPath(rect).getBounds(), rect);
      // Pressed: from the sunk face down to the ink, which stays put.
      expect(
        down.getOuterPath(rect).getBounds(),
        const Rect.fromLTRB(0, 3, 100, 48),
      );
      final half = ShapeBorder.lerp(up, down, 0.5)! as GumdropShape;
      expect(half.pressed, 0.5);
      expect(GumdropShape.depthFor(37), 6);
      expect(GumdropShape.depthFor(48), 7);
      expect(GumdropShape.depthFor(58), 8);
      expect(GumdropShape.sinkFor(7), 3);
      expect(GumdropShape.sinkFor(8), 4);
      expect(GumdropShape.sinkFor(4), 2);
    });

    test('lips are a darker shade of their own face (#98)', () {
      // The spec's rule, checked against the mockup's lips: lightness
      // times 0.66 and saturation 0.85, or 0.46 under a dark face.
      Color lip(int face) => Candy.lipOf(Color(face));
      double l(Color c) => HSLColor.fromColor(c).lightness;
      double h(Color c) => HSLColor.fromColor(c).hue;
      for (final face in [0xFFFFD43A, 0xFFF2473D, 0xFF35B0FF, 0xFF5ED36A]) {
        final c = Color(face);
        expect(l(lip(face)), closeTo(l(c) * 0.66, 0.01));
        expect(h(lip(face)), closeTo(h(c), 1));
      }
      expect(
        l(lip(0xFF252522)),
        closeTo(l(const Color(0xFF252522)) * 0.46, 0.01),
      );
      expect(Candy.isDark(const Color(0xFF252522)), isTrue);
      expect(Candy.isDark(const Color(0xFFFFD43A)), isFalse);
      // A dark face's highlight and shine are fainter.
      expect(
        Candy.highlightOn(const Color(0xFF252522)).a,
        lessThan(Candy.highlightOn(const Color(0xFFFFD43A)).a),
      );
      expect(
        Candy.streakOn(const Color(0xFF252522)).a,
        lessThan(Candy.streakOn(const Color(0xFFFFD43A)).a),
      );
      // Every scheme's lips follow its faces.
      for (final scheme in bootCampSchemes) {
        final g = GumdropColors.forScheme(scheme);
        expect(g.mint.lip, Candy.lipOf(g.mint.face), reason: '$scheme');
        expect(g.you.lip, Candy.lipOf(g.you.face), reason: '$scheme');
        expect(g.cherry.lip, Candy.lipOf(g.cherry.face), reason: '$scheme');
      }
    });
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
