import 'package:battleplan/core/constants.g.dart';

/// The color scheme a person had before color schemes, from their old
/// theme (`users.themeMode`): their default until they pick one (SET-2).
/// Pure Dart, so domain code can use it.
TeamScheme schemeForThemeMode(ThemePreference? mode) => switch (mode) {
  ThemePreference.dark => TeamScheme.navy,
  ThemePreference.light || ThemePreference.candy => TeamScheme.light,
  ThemePreference.arena => TeamScheme.dark,
  // Olive, system, or none.
  _ => TeamScheme.army,
};
