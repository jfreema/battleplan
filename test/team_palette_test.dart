// The team palette (TEAM-5): retired colors read as their replacements,
// and every color has a name.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/groups/domain/team_palette.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('a retired team color shows as its replacement', () {
    expect(currentTeamColor(0xFF1D4ED8), 0xFF2F5BEA); // Royal blue: Blue
    expect(currentTeamColor(0xFF9333EA), 0xFF7C3AED); // Violet: Purple
    expect(currentTeamColor(null), isNull);
    for (final argb in teamColorValues) {
      expect(currentTeamColor(argb), argb);
    }
    // Every replacement is in the palette; no retired color is.
    for (final MapEntry(key: old, value: now)
        in retiredTeamColorValues.entries) {
      expect(teamColorValues, contains(now));
      expect(teamColorValues, isNot(contains(old)));
    }
  });

  test('every team color has its own name, by value', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final names = [
      for (final argb in teamColorValues) teamColorName(l10n, argb),
    ];
    expect(names, [
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
    ]);
    // Anything else is its hex.
    expect(teamColorName(l10n, 0xFF123456), '#123456');
  });
}
