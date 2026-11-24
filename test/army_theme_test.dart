// Army green (SPEC §7.4, SET-2), the default until 2026-11-10 and still
// where Gumdrop Army accounts start; since Boot Camp Mix (#85) an olive
// page, olive panels a shade lighter, cream lettering, ink outlines and
// shadows, and mustard for you.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/candy.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/scheme_defaults.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final a = GumdropColors.forScheme(TeamScheme.army);

  test('is where Gumdrop Army accounts start, and no longer the default', () {
    expect(schemeForThemeMode(ThemePreference.olive), TeamScheme.army);
    expect(schemeForThemeMode(null), isNot(TeamScheme.army));
    expect(schemeForThemeMode(ThemePreference.system), isNot(TeamScheme.army));
  });

  test('olive page, cream lettering, olive panels', () {
    expect(a.page, const Color(0xFF474C2B));
    expect(a.textOnPage, const Color(0xFFF4EAD0));
    expect(a.textPrimary, const Color(0xFFF4EAD0));
    expect(a.surface, const Color(0xFF575A3A));
    expect(a.brightness, Brightness.dark);
    expect(AppTheme.of(TeamScheme.army).scaffoldBackgroundColor, a.page);
  });

  test('mustard is you and the sticker; orange is Maybe; red is games', () {
    expect(a.you.face, const Color(0xFFF2C230));
    expect(a.sticker.face, const Color(0xFFF2C230));
    expect(a.lemon.face, const Color(0xFFF5A040));
    expect(a.tangerine.face, const Color(0xFFDB442F));
    // Every candy sits on a lip of its own darker shade (#98).
    for (final c in [a.you, a.mint, a.lemon, a.tangerine, a.grape]) {
      expect(c.lip, Candy.lipOf(c.face));
    }
  });

  test('headings have no drop; big titles cast an ink shadow', () {
    expect(a.headingShadow.a, 0);
    expect(a.card.headingShadow.a, 0);
    expect(a.pageShadow, const Color(0xFF1A1A18));
  });
}
