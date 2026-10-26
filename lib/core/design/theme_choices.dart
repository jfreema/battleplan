import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';

/// The themes to pick from (SET-2), in the order Settings and the account
/// menu list them: each one's saved preference, its flavor, and its name.
List<(ThemePreference, GumdropFlavor, String)> themeChoices(
  AppLocalizations l10n,
) => [
  (ThemePreference.olive, GumdropFlavor.olive, l10n.themeGumdropOlive),
  (ThemePreference.dark, GumdropFlavor.dark, l10n.themeGumdropDark),
  (ThemePreference.light, GumdropFlavor.light, l10n.themeGumdropLight),
  (ThemePreference.candy, GumdropFlavor.candy, l10n.themeGumdropCandy),
  (ThemePreference.arena, GumdropFlavor.arena, l10n.themeGumdropArena),
];
