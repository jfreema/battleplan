// The Open Field theme (SPEC §7.4, SET-2) in its six color schemes: the
// role values, contrast, the card context, and the theme widgets.
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

/// Appendix A.2 of the Open Field spec, by role, in enum order: army,
/// darkarmy (Forest green, #77, #78), light, dark, navy, sky (Sky Blue,
/// #75), skyblue (Sky Blue Pop), then Candy Pop (#70), made after it from
/// TeamRank's colors, with TeamRank's white cards since #72.
const _a2 = <String, List<int>>{
  'page': [
    0xFF474C2B,
    0xFF242713,
    0xFFFBF5E6,
    0xFF0E0E0D,
    0xFF0B1531,
    0xFFBCD9F5,
    0xFFBCD9F5,
    0xFF1748D4,
    0xFF5E1224,
    0xFF461D7C,
    0xFF0B0B0A,
  ],
  'text': [
    0xFFF4EAD0,
    0xFFF4EAD0,
    0xFF1A1A18,
    0xFFF4EAD0,
    0xFFF2F6FF,
    0xFF0B1531,
    0xFF0B1531,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFFFFC83D,
  ],
  'pageMuted': [
    0xCCF4EAD0,
    0xCCF4EAD0,
    0xFF5F5A4D,
    0xBFF4EAD0,
    0xFFB2BFE0,
    0xFF34476E,
    0xFF34476E,
    0xFFDCE6FF,
    0xFFCDD1D8,
    0xFFD5C6F0,
    0xFFC2942E,
  ],
  'hairline': [
    0x24F4EAD0,
    0x24F4EAD0,
    0x1F1A1A18,
    0x1FF4EAD0,
    0x1FF2F6FF,
    0x240B1531,
    0x240B1531,
    0x33FFFFFF,
    0x33C0C5CC,
    0x33FDD023,
    0x24FFC83D,
  ],
  'outline': [
    0x4CF4EAD0,
    0x4CF4EAD0,
    0x4C1A1A18,
    0x4CF4EAD0,
    0x4CF2F6FF,
    0x590B1531,
    0x590B1531,
    0x66FFFFFF,
    0x99C0C5CC,
    0x99FDD023,
    0x66FFC83D,
  ],
  'tabbar': [
    0xFF3D4124,
    0xFF1D200F,
    0xFFFFFFFF,
    0xFF161615,
    0xFF07102A,
    0xFFAFD0F1,
    0xFFFFFFFF,
    0xFF0B1640,
    0xFF0B0B0B,
    0xFF2E1157,
    0xFF050505,
  ],
  'tabbarLine': [
    0x1AF4EAD0,
    0x1AF4EAD0,
    0xFF1A1A18,
    0x1AF4EAD0,
    0x1AF2F6FF,
    0x1A0B1531,
    0xFF0B1531,
    0xFF0B1640,
    0x66C0C5CC,
    0x66FDD023,
    0x33FFC83D,
  ],
  'field': [
    0xFF2B2F18,
    0xFF14160A,
    0xFFEFE6CC,
    0xFF1F1F1C,
    0xFF07102A,
    0xFFA9CCEE,
    0xFFE3EEFA,
    0xFF1238A8,
    0xFF470C1A,
    0xFF34125F,
    0xFF1D1912,
  ],
  'fieldRim': [
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x1AF2F6FF,
    0x00000000,
    0x00000000,
    0x33FFFFFF,
    0x66C0C5CC,
    0x66FDD023,
    0x33FFC83D,
  ],
  'card': [
    0xFF575A3A,
    0xFF33361F,
    0xFFFFFFFF,
    0xFF1B1B19,
    0xFF18284C,
    0xFFD3E6F9,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFF701C30,
    0xFF55278F,
    0xFF16130E,
  ],
  'cardRim': [
    0xFF1A1A18,
    0xFF1A1A18,
    0xFF1A1A18,
    0xFF363631,
    0xFF35466D,
    0xFF0B1531,
    0xFF0B1531,
    0xFF0B1640,
    0xFFC0C5CC,
    0xFFFDD023,
    0xFF8A6A16,
  ],
  'cardMuted': [
    0xE0F4EAD0,
    0xE0F4EAD0,
    0xFF5F5A4D,
    0xC7F4EAD0,
    0xFFC2CCE8,
    0xFF34476E,
    0xFF34476E,
    0xFF4B5A8C,
    0xFFD8DCE2,
    0xFFDCCFF3,
    0xFFCC9D33,
  ],
  'cardTrack': [
    0x38F4EAD0,
    0x38F4EAD0,
    0x1F1A1A18,
    0x2EF4EAD0,
    0x38F2F6FF,
    0x1F0B1531,
    0x1F0B1531,
    0x1F0B1640,
    0x38FFFFFF,
    0x38FFFFFF,
    0x38FFC83D,
  ],
  'cardOutline': [
    0x73F4EAD0,
    0x73F4EAD0,
    0x661A1A18,
    0x73F4EAD0,
    0x73F2F6FF,
    0x660B1531,
    0x660B1531,
    0x660B1640,
    0x99C0C5CC,
    0x99FDD023,
    0x73FFC83D,
  ],
  // The card's own text, fields, Maybe, and Material's pop-ups: the
  // page's or the card's in every scheme but Candy Pop (#72).
  'cardText': [
    0xFFF4EAD0,
    0xFFF4EAD0,
    0xFF1A1A18,
    0xFFF4EAD0,
    0xFFF2F6FF,
    0xFF0B1531,
    0xFF0B1531,
    0xFF0B1640,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFFFFC83D,
  ],
  'cardField': [
    0xFF2B2F18,
    0xFF14160A,
    0xFFEFE6CC,
    0xFF1F1F1C,
    0xFF07102A,
    0xFFBCD9F5,
    0xFFE3EEFA,
    0xFFDDE8FF,
    0xFF470C1A,
    0xFF34125F,
    0xFF1D1912,
  ],
  'cardMaybeText': [
    0xFFF8D84A,
    0xFFF8D84A,
    0xFF8F6500,
    0xFFF8D84A,
    0xFFF8D84A,
    0xFF785200,
    0xFF785200,
    0xFF785200,
    0xFFFFE680,
    0xFFFFE680,
    0xFFFFF06B,
  ],
  'popup': [
    0xFF575A3A,
    0xFF33361F,
    0xFFFFFFFF,
    0xFF1B1B19,
    0xFF18284C,
    0xFFD3E6F9,
    0xFFFFFFFF,
    0xFF1238A8,
    0xFF701C30,
    0xFF55278F,
    0xFF16130E,
  ],
  'candyInk': [
    0xFF1A1A18,
    0xFF1A1A18,
    0xFF1A1A18,
    0xFF1A1A18,
    0xFF050C1F,
    0xFF0B1531,
    0xFF0B1531,
    0xFF0B1640,
    0xFF0B0B0B,
    0xFF1E0A3C,
    0xFF0B0B0A,
  ],
  'candyLipCoral': [
    0xFF1A1A18,
    0xFF1A1A18,
    0xFF1A1A18,
    0xFFC0262F,
    0xFFC0262F,
    0xFF0B1531,
    0xFF0B1531,
    0xFF0B1640,
    0xFF0B0B0B,
    0xFF1E0A3C,
    0xFFC0262F,
  ],
  'candyLipMint': [
    0xFF1A1A18,
    0xFF1A1A18,
    0xFF1A1A18,
    0xFF137236,
    0xFF137236,
    0xFF0B1531,
    0xFF0B1531,
    0xFF0B1640,
    0xFF0B0B0B,
    0xFF1E0A3C,
    0xFF137236,
  ],
  'candyLipLemon': [
    0xFF1A1A18,
    0xFF1A1A18,
    0xFF1A1A18,
    0xFFA88A12,
    0xFFA88A12,
    0xFF0B1531,
    0xFF0B1531,
    0xFF0B1640,
    0xFF0B0B0B,
    0xFF1E0A3C,
    0xFFA88A12,
  ],
  'candyLipTangerine': [
    0xFF1A1A18,
    0xFF1A1A18,
    0xFF1A1A18,
    0xFF9E4B0A,
    0xFF9E4B0A,
    0xFF0B1531,
    0xFF0B1531,
    0xFF0B1640,
    0xFF0B0B0B,
    0xFF1E0A3C,
    0xFF9E4B0A,
  ],
  'titleDrop': [
    0xFF1A1A18,
    0xFF1A1A18,
    0x00000000,
    0x00000000,
    0xFF2A63C9,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFF0B1640,
    0xFF0B0B0B,
    0xFFFDD023,
    0xFFB8480A,
  ],
  'avatarRing': [
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0xFF0B1531,
    0xFF0B1531,
    0xFF0B1640,
    0x00000000,
    0x00000000,
    0x00000000,
  ],
  'accentText': [
    0xFFF9A5A5,
    0xFFF9A5A5,
    0xFFC0262F,
    0xFFF76F6F,
    0xFFF78C8C,
    0xFFAB222A,
    0xFFAB222A,
    0xFFFFC7C7,
    0xFFFFB3B3,
    0xFFFFB3B3,
    0xFFFF7566,
  ],
  'accentMark': [
    0xFFF45B5B,
    0xFFF45B5B,
    0xFFC0262F,
    0xFFF45B5B,
    0xFFF45B5B,
    0xFFAB222A,
    0xFFAB222A,
    0xFFFFC7C7,
    0xFFC0C5CC,
    0xFFFDD023,
    0xFFFF7566,
  ],
  'notGoingIcon': [
    0xFFFBC0C0,
    0xFFFBC0C0,
    0xFFC0262F,
    0xFFF76F6F,
    0xFFF78C8C,
    0xFFAB222A,
    0xFFAB222A,
    0xFFFFC7C7,
    0xFFFFB3B3,
    0xFFFFB3B3,
    0xFFFF7566,
  ],
  'goingText': [
    0xFFB5FAD0,
    0xFFB5FAD0,
    0xFF137236,
    0xFF58C173,
    0xFF79CD8F,
    0xFF116530,
    0xFF116530,
    0xFFB5FAD0,
    0xFFB8F2C8,
    0xFFB8F2C8,
    0xFF6FE08A,
  ],
  'maybeText': [
    0xFFF8D84A,
    0xFFF8D84A,
    0xFF8F6500,
    0xFFF8D84A,
    0xFFF8D84A,
    0xFF785200,
    0xFF785200,
    0xFFFFE45C,
    0xFFFFE680,
    0xFFFFE680,
    0xFFFFF06B,
  ],
  'cardGoingText': [
    0xFFB5FAD0,
    0xFFB5FAD0,
    0xFF137236,
    0xFF58C173,
    0xFF79CD8F,
    0xFF137236,
    0xFF137236,
    0xFF137236,
    0xFFB8F2C8,
    0xFFB8F2C8,
    0xFF6FE08A,
  ],
  'cardAccentText': [
    0xFFFBC0C0,
    0xFFFBC0C0,
    0xFFC0262F,
    0xFFF76F6F,
    0xFFF78C8C,
    0xFFC0262F,
    0xFFC0262F,
    0xFFC0262F,
    0xFFFFB3B3,
    0xFFFFB3B3,
    0xFFFF7566,
  ],
  'gameText': [
    0xFFF4AD79,
    0xFFF4AD79,
    0xFF9E4B0A,
    0xFFEE8131,
    0xFFF19A5A,
    0xFF8D4309,
    0xFF8D4309,
    0xFFFFCB99,
    0xFFFFC999,
    0xFFFFC999,
    0xFFFF9D4D,
  ],
  'typeGame': [
    0xFFF8CDAD,
    0xFFF8CDAD,
    0xFF9E4B0A,
    0xFFEE8131,
    0xFFF19A5A,
    0xFF9E4B0A,
    0xFF9E4B0A,
    0xFF9E4B0A,
    0xFFFFC999,
    0xFFFFC999,
    0xFFFF9D4D,
  ],
  'typePractice': [
    0xFFDBCBFB,
    0xFFDBCBFB,
    0xFF6C46CC,
    0xFFA57CF5,
    0xFFB796F7,
    0xFF6C46CC,
    0xFF6C46CC,
    0xFF6C46CC,
    0xFFE0D0FF,
    0xFFE0D0FF,
    0xFFC4A7FF,
  ],
  'typeOther': [
    0xFFF8C2DE,
    0xFFF8C2DE,
    0xFFAE2770,
    0xFFF06AAF,
    0xFFF184BE,
    0xFFAE2770,
    0xFFAE2770,
    0xFFAE2770,
    0xFFFFC2E0,
    0xFFFFC2E0,
    0xFFFF8AD0,
  ],
};

/// Each role's value in [r], by the name A.2 uses.
Map<String, Color> _roles(SchemeRoles r) => {
  'page': r.page,
  'text': r.text,
  'pageMuted': r.pageMuted,
  'hairline': r.hairline,
  'outline': r.outline,
  'tabbar': r.tabbar,
  'tabbarLine': r.tabbarLine,
  'field': r.field,
  'fieldRim': r.fieldRim,
  'card': r.card,
  'cardRim': r.cardRim,
  'cardMuted': r.cardMuted,
  'cardTrack': r.cardTrack,
  'cardOutline': r.cardOutline,
  'cardText': r.cardText,
  'cardField': r.cardField,
  'cardMaybeText': r.cardMaybeText,
  'popup': r.popup,
  'candyInk': r.candyInk,
  'candyLipCoral': r.candyLipCoral,
  'candyLipMint': r.candyLipMint,
  'candyLipLemon': r.candyLipLemon,
  'candyLipTangerine': r.candyLipTangerine,
  'titleDrop': r.titleDrop,
  'avatarRing': r.avatarRing,
  'accentText': r.accentText,
  'accentMark': r.accentMark,
  'notGoingIcon': r.notGoingIcon,
  'goingText': r.goingText,
  'maybeText': r.maybeText,
  'cardGoingText': r.cardGoingText,
  'cardAccentText': r.cardAccentText,
  'gameText': r.gameText,
  'typeGame': r.typeGame,
  'typePractice': r.typePractice,
  'typeOther': r.typeOther,
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
  group('the roles (Appendix A.2)', () {
    for (final (i, scheme) in builtInSchemes.indexed) {
      test('${scheme.value} matches the spec', () {
        final roles = _roles(SchemeRoles.of(scheme));
        expect(roles.keys.toSet(), _a2.keys.toSet());
        for (final MapEntry(key: role, value: values) in _a2.entries) {
          expect(
            roles[role]!.toARGB32(),
            values[i],
            reason: '${scheme.value} $role',
          );
        }
      });
    }

    test('the candy faces are the same in every scheme', () {
      for (final scheme in builtInSchemes) {
        final c = GumdropColors.forScheme(scheme);
        expect(c.you.face, CandyFaces.coral);
        expect(c.cherry.face, CandyFaces.cherry);
        expect(c.mint.face, const Color(0xFF58C173));
        expect(c.lemon.face, const Color(0xFFF8D84A));
        expect(c.tangerine.face, const Color(0xFFEE8131));
        expect(c.grape.face, const Color(0xFFA57CF5));
        expect(c.bubblegum.face, const Color(0xFFEB50A2));
        expect(c.blueRaspberry.face, const Color(0xFF79BBFF));
      }
    });

    // The usability review's #12 (owner's go 2026-11-16): coral and the
    // warning red were one color, so unread, "you", and every warning
    // looked alike.
    test('the warning red is its own, clearly deeper than coral', () {
      expect(CandyFaces.cherry, isNot(CandyFaces.coral));
      expect(
        ColorMath.contrast(CandyFaces.coral, CandyFaces.cherry),
        greaterThanOrEqualTo(1.4),
      );
      for (final scheme in builtInSchemes) {
        final r = SchemeRoles.of(scheme);
        final c = GumdropColors.forScheme(scheme);
        expect(c.cherry.lip, r.cherryLip);
        // White on its face; the candy ink on every other candy.
        expect(c.inkOn(c.cherry), CandyFaces.cherryInk);
        for (final candy in [c.you, c.mint, c.lemon, c.sticker]) {
          expect(c.inkOn(candy), c.ink);
        }
        _reads(
          c.inkOn(c.cherry),
          c.cherry.face,
          '${scheme.value} white on the warning red',
        );
        // A mark on its own (a Canceled tag, Owes) where no ink lip
        // outlines it: everywhere but the Army greens and Candy Pop, whose
        // pages are as deep as the red; its white words carry it there.
        if (scheme != TeamScheme.army &&
            scheme != TeamScheme.darkarmy &&
            scheme != TeamScheme.candypop &&
            scheme != TeamScheme.wildcat &&
            scheme != TeamScheme.purplegold) {
          _reads(c.cherry.face, r.page, '${scheme.value} red on page', min: 3);
          _reads(c.cherry.face, r.card, '${scheme.value} red on card', min: 3);
        }
      }
    });

    test('Army greens, Dark, Navy, and Candy Pop are dark; Light, Sky Blue, '
        "and Sky Blue Pop light; cards agree, but Candy Pop's white ones", () {
      expect(builtInSchemes.where((s) => s.isDark), [
        TeamScheme.army,
        TeamScheme.darkarmy,
        TeamScheme.dark,
        TeamScheme.navy,
        TeamScheme.candypop,
        TeamScheme.wildcat,
        TeamScheme.purplegold,
        TeamScheme.scoreboard,
      ]);
      for (final scheme in builtInSchemes) {
        final want = scheme.isDark ? Brightness.dark : Brightness.light;
        final card = scheme == TeamScheme.candypop ? Brightness.light : want;
        expect(GumdropColors.forScheme(scheme).brightness, want);
        expect(GumdropColors.forScheme(scheme, onCard: true).brightness, card);
        expect(AppTheme.of(scheme).brightness, want);
        expect(AppTheme.of(scheme, onCard: true).brightness, card);
      }
    });
  });

  group('contrast (Appendix A.4)', () {
    for (final scheme in builtInSchemes) {
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
        for (final (face, name) in [
          (CandyFaces.coral, 'coral'),
          (const Color(0xFF58C173), 'mint'),
          (const Color(0xFFF8D84A), 'lemon'),
          (const Color(0xFFEE8131), 'tangerine'),
          (const Color(0xFFA57CF5), 'grape'),
          (const Color(0xFFEB50A2), 'bubblegum'),
          (const Color(0xFF79BBFF), 'blue raspberry'),
        ]) {
          _reads(r.candyInk, face, '${scheme.value} ink on $name');
        }
        // Marks need 3:1. Decorative by choice (spec 11.4): accent-mark on
        // Army green's page (beside a label), outlines (the labels carry
        // the meaning), and card rims in the dark schemes.
        _reads(r.notGoingIcon, r.page, 'not-going icon', min: 3);
        if (scheme != TeamScheme.army) {
          _reads(r.accentMark, r.page, 'accent mark', min: 3);
        }
      });
    }
  });

  group('the card context (4.3)', () {
    for (final scheme in builtInSchemes) {
      test('${scheme.value}: the card texts take their places', () {
        final r = SchemeRoles.of(scheme);
        final page = GumdropColors.forScheme(scheme);
        final card = page.card;
        expect(card.onCard, isTrue);
        expect(card.scheme, scheme);
        expect(page.you.text, r.accentText);
        expect(card.you.text, r.cardAccentText);
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
        expect(page.well, r.field);
        expect(card.well, r.cardTrack);
        expect(page.headingShadow, r.titleDrop);
        expect(card.headingShadow.a, 0);
        expect(card.notGoingIcon, r.cardAccentText);
        expect(card.badgeRing, r.card);
        expect(page.badgeRing, r.page);
        // The card's own text and fields (Candy Pop's navy on white, #72),
        // and Material's pop-ups.
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
    for (final scheme in builtInSchemes) {
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
            // The same color everywhere else.
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
      for (final scheme in builtInSchemes) {
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
        lessThanOrEqualTo(2 * builtInSchemes.length),
      );
    });

    test('titles are Lilita One with one hard drop, or none', () {
      final navy = AppTheme.of(TeamScheme.navy).textTheme.headlineMedium!;
      expect(navy.fontFamily, 'Lilita One');
      expect(navy.shadows, [
        Shadow(color: SchemeRoles.navy.titleDrop, offset: const Offset(0, 2)),
      ]);
      expect(
        AppTheme.of(TeamScheme.light).textTheme.headlineMedium!.shadows,
        isEmpty,
      );
      expect(
        GumdropStyle.openField
            .headingShadow(const Color(0xFF1A1A18), big: true)
            .single
            .offset,
        const Offset(0, 3),
      );
    });

    test('a gumdrop sinks onto its lip when pressed', () {
      const rect = Rect.fromLTWH(0, 0, 100, 48);
      const up = GumdropShape(lipColor: Color(0xFF2A63C9));
      final down = up.copyWith(pressed: 1);
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
        TeamScheme.navy,
        (child) => Material(
          child: SchemeTheme(scheme: TeamScheme.light, child: child),
        ),
      );
      expect(t.extension<GumdropColors>()!.scheme, TeamScheme.light);
      expect(t.scaffoldBackgroundColor, SchemeRoles.light.page);
      // No stray cream text from the Navy root.
      expect(text.color, SchemeRoles.light.text);
    });

    testWidgets('keeps the card context on a card', (tester) async {
      final (t, _) = await pumpIn(
        tester,
        TeamScheme.army,
        (child) => GumdropSurface(
          child: SchemeTheme(scheme: TeamScheme.skyblue, child: child),
        ),
      );
      final c = t.extension<GumdropColors>()!;
      expect(c.scheme, TeamScheme.skyblue);
      expect(c.onCard, isTrue);
      expect(t.colorScheme.surface, SchemeRoles.skyblue.card);
    });
  });

  testWidgets("a list tile's title is in the text color and its subtitle "
      'muted, in every scheme', (tester) async {
    for (final scheme in builtInSchemes) {
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

  testWidgets('a team badge close to its card gets an outline', (tester) async {
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

    // Navy on Navy's cards, black on Dark's: edged.
    expect(
      await edge(TeamScheme.navy, 0xFF1E3A5F),
      SchemeRoles.navy.cardOutline,
    );
    expect(
      await edge(TeamScheme.dark, 0xFF000000),
      SchemeRoles.dark.cardOutline,
    );
    // A bright color reads on its own.
    expect(await edge(TeamScheme.navy, 0xFFF45B5B), isNull);
    // Light blue rings every badge already.
    expect(
      await edge(TeamScheme.skyblue, 0xFFFFFFFF),
      SchemeRoles.skyblue.avatarRing,
    );
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
