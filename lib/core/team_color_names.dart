import 'package:battleplan/l10n/gen/app_localizations.dart';

/// A team color's name (TEAM-1), for its swatch's label, looked up by the
/// color itself; a color outside the palette is its hex.
String teamColorName(AppLocalizations l10n, int argb) => switch (argb |
    0xFF000000) {
  0xFF2F5BEA => l10n.colorBlue,
  0xFF7BAFD4 => l10n.colorLightBlue,
  0xFF1E3A5F => l10n.colorNavy,
  0xFF0E7490 => l10n.colorTeal,
  0xFF0F8A5F => l10n.colorGreen,
  0xFF4D7C0F => l10n.colorOlive,
  0xFFD4A017 => l10n.colorYellow,
  0xFFA16207 => l10n.colorMustard,
  0xFFC2410C => l10n.colorOrange,
  0xFFB91C1C => l10n.colorRed,
  0xFF7F1D1D => l10n.colorMaroon,
  0xFFBE185D => l10n.colorPink,
  0xFF7C3AED => l10n.colorPurple,
  0xFF334155 => l10n.colorGray,
  0xFF111111 => l10n.colorBlack,
  _ => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
};
