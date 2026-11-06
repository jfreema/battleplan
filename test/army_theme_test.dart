// Army green (SPEC §7.4, SET-2), the scheme a new account starts on: an
// army green page, cream type, and olive cards with cream type.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/scheme_defaults.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final a = GumdropColors.forScheme(TeamScheme.army);

  test('is where a new account and an unset theme start', () {
    expect(schemeForThemeMode(null), TeamScheme.army);
    expect(schemeForThemeMode(ThemePreference.system), TeamScheme.army);
    expect(schemeForThemeMode(ThemePreference.olive), TeamScheme.army);
  });

  test('army green page, cream type, olive cards', () {
    expect(a.page, const Color(0xFF474C2B));
    expect(a.textOnPage, const Color(0xFFF4EAD0));
    expect(a.textPrimary, const Color(0xFFF4EAD0));
    expect(a.surface, const Color(0xFF575A3A));
    expect(a.brightness, Brightness.dark);
    expect(AppTheme.of(TeamScheme.army).scaffoldBackgroundColor, a.page);
  });

  test('coral is you and the sticker; lemon is Maybe', () {
    expect(a.you.face, const Color(0xFFF45B5B));
    expect(a.sticker.face, const Color(0xFFF45B5B));
    expect(a.lemon.face, const Color(0xFFF8D84A));
    // Every candy sits on an ink lip in Army green.
    for (final c in [a.you, a.mint, a.lemon, a.tangerine, a.grape]) {
      expect(c.lip, const Color(0xFF1A1A18));
    }
  });

  test('titles drop onto ink on the page, and not on cards', () {
    expect(a.headingShadow, const Color(0xFF1A1A18));
    expect(a.card.headingShadow.a, 0);
  });
}
