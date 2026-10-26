// Gumdrop Pop Olive (SPEC §7.4, SET-2), the default theme: an olive page in
// every team, cream cards, coral for you, the sticker, and the back button,
// and outlines on its headings and candies.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_tint.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const o = GumdropColors.olive;

  test('is the default: no choice, and a new account, get it', () {
    expect(AppTheme.flavorOf(ThemePreference.system), GumdropFlavor.olive);
    expect(AppTheme.flavorOf(ThemePreference.olive), GumdropFlavor.olive);
    expect(GumdropFlavor.olive.isDark, isFalse);
  });

  test('cream text on the olive page, ink on cream cards', () {
    expect(o.coloredPage, isTrue);
    expect(ColorMath.contrast(o.textOnPage, o.page), greaterThanOrEqualTo(4.5));
    expect(
      ColorMath.contrast(o.successOnPage, o.page),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      ColorMath.contrast(o.textPrimary, o.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      ColorMath.contrast(o.textMuted, o.surface),
      greaterThanOrEqualTo(4.5),
    );
    for (final a in [
      o.you,
      o.lemon,
      o.mint,
      o.cherry,
      o.tangerine,
      o.grape,
      o.bubblegum,
      o.blueRaspberry,
    ]) {
      expect(ColorMath.contrast(a.text, o.surface), greaterThanOrEqualTo(4.5));
      expect(ColorMath.contrast(o.ink, a.face), greaterThanOrEqualTo(4.5));
      // Every candy sits on an ink lip, as in the design.
      expect(a.lip, o.ink);
    }
  });

  test('coral is you, the sticker, and the back button; lemon is Maybe', () {
    expect(o.you.face, const Color(0xFFF45B5B));
    expect(o.sticker.face, const Color(0xFFF45B5B));
    expect(o.lemon.face, const Color(0xFFF8D84A));
    // The other themes keep lemon.
    expect(GumdropColors.dark.sticker, GumdropColors.dark.lemon);
    expect(GumdropColors.candy.sticker, GumdropColors.candy.lemon);
  });

  test('keeps its olive page and cream cards in every team color', () {
    for (final argb in teamColorValues) {
      final c = teamTinted(o, argb);
      expect(c.page, o.page);
      expect(c.surface, o.surface);
      expect(c.you, o.you);
      expect(c.teamColor, Color(argb));
    }
    expect(teamTinted(o.card, teamColorValues.first).onCard, isTrue);
  });

  test('headings are outlined over the hard shadow; candies are outlined', () {
    final t = AppTheme.of(GumdropFlavor.olive).textTheme;
    final shadows = t.headlineMedium!.shadows!;
    // 16 around the letters, then the 4-step stack.
    expect(shadows, hasLength(20));
    expect(shadows.every((s) => s.color == o.headingShadow), isTrue);
    expect(shadows.last.offset, const Offset(4, 4));
    expect(t.headlineMedium!.color, o.headingText);
    expect(GumdropStyle.forFlavor(GumdropFlavor.olive).accentOutline, 2);
    // The other themes have neither.
    expect(
      AppTheme.of(GumdropFlavor.dark).textTheme.headlineMedium!.shadows,
      hasLength(4),
    );
    expect(GumdropStyle.forFlavor(GumdropFlavor.dark).accentOutline, 0);
    final filled = AppTheme.of(GumdropFlavor.olive).filledButtonTheme.style!;
    expect(filled.side!.resolve({})!.color, o.ink);
  });
}
