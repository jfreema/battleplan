import 'package:battleplan/core/constants.g.dart';

/// The color scheme for anyone who hasn't picked one, and for the
/// signed-out screens: Dark (SET-2, owner's request 2026-11-10: "make the
/// dark theme the default theme"; Army green before). It's worked out on
/// the device and never stored, so a pick, once made, always wins.
const TeamScheme defaultTeamScheme = TeamScheme.dark;

/// The color scheme a person had before color schemes, from their old
/// theme (`users.themeMode`): their default until they pick one (SET-2).
/// System, which every new account is written with, and nothing set were
/// never a pick, so they get [defaultTeamScheme]. Pure Dart, so domain code
/// can use it.
TeamScheme schemeForThemeMode(ThemePreference? mode) => switch (mode) {
  ThemePreference.dark => TeamScheme.navy,
  ThemePreference.light || ThemePreference.candy => TeamScheme.light,
  ThemePreference.arena => TeamScheme.dark,
  // Gumdrop Army, picked when it was offered (stored as olive).
  ThemePreference.olive => TeamScheme.army,
  ThemePreference.system || null => defaultTeamScheme,
};
