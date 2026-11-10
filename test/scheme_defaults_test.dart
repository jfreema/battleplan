// The default color scheme a person had before color schemes, from their
// old theme (SET-2).
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/scheme_defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Dark is the default (owner's request 2026-11-10)", () {
    expect(defaultTeamScheme, TeamScheme.dark);
  });

  test('each old theme maps to the scheme closest to it', () {
    // Gumdrop Army was a pick; System, which new accounts are written with,
    // and nothing set weren't, so they get the default, Dark.
    expect(schemeForThemeMode(ThemePreference.olive), TeamScheme.army);
    expect(schemeForThemeMode(ThemePreference.system), TeamScheme.dark);
    expect(schemeForThemeMode(null), TeamScheme.dark);
    expect(schemeForThemeMode(ThemePreference.dark), TeamScheme.navy);
    expect(schemeForThemeMode(ThemePreference.light), TeamScheme.light);
    expect(schemeForThemeMode(ThemePreference.candy), TeamScheme.light);
    expect(schemeForThemeMode(ThemePreference.arena), TeamScheme.dark);
    // Every old theme has one.
    for (final mode in ThemePreference.values) {
      expect(TeamScheme.values, contains(schemeForThemeMode(mode)));
    }
  });
}
