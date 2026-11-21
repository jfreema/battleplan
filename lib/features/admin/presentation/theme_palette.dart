import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/team_color_names.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// A color the theme editor offers, with its name (#83, owner's request
/// 2026-11-21: "add more colors to each option ... have it say the name of
/// the color in addition to showing the color code").
@immutable
final class NamedColor {
  const new(this.color, this.name);

  final Color color;
  final String name;
}

/// A titled group of the editor's colors.
typedef ColorGroup = ({String title, List<NamedColor> colors});

/// The colors every option of the theme editor offers: the candy colors,
/// the team colors, then each built-in theme's own (its page, cards, text,
/// and marks: maroon and silver, purple and gold, navy, and the rest), so
/// any theme's colors can go on any other.
List<ColorGroup> themePalette(AppLocalizations l10n) => [
  (
    title: l10n.adminThemeCandyColors,
    colors: [
      NamedColor(CandyFaces.coral, l10n.colorCoral),
      NamedColor(CandyFaces.cherry, l10n.colorCherryRed),
      NamedColor(CandyFaces.tangerine, l10n.candyTangerine),
      NamedColor(CandyFaces.lemon, l10n.candyLemon),
      NamedColor(CandyFaces.mint, l10n.candyMint),
      NamedColor(CandyFaces.blueRaspberry, l10n.candyBlueRaspberry),
      NamedColor(CandyFaces.grape, l10n.candyGrape),
      NamedColor(CandyFaces.bubblegum, l10n.candyBubblegum),
    ],
  ),
  (
    title: l10n.adminThemeTeamColors,
    colors: [
      for (final argb in teamColorValues)
        NamedColor(Color(argb), teamColorName(l10n, argb)),
    ],
  ),
  for (final scheme in builtInSchemes)
    (title: scheme.label(l10n), colors: schemeColors(l10n, scheme)),
];

/// [scheme]'s own colors as it ships, each once, by name: its page, cards,
/// pop-ups, text, and marks. Coral, in every scheme, is with the candies.
List<NamedColor> schemeColors(AppLocalizations l10n, TeamScheme scheme) {
  final r = SchemeRoles.builtIn(scheme);
  final seen = <int>{CandyFaces.coral.toARGB32()};
  return [
    for (final color in [
      r.page,
      r.card,
      r.popup,
      r.text,
      r.cardText,
      r.accentMark,
      r.titleDrop,
    ])
      if (color.a == 1 && seen.add(color.toARGB32()))
        NamedColor(color, themeColorName(l10n, color) ?? ColorMath.hex(color)),
  ];
}

/// The name of a color the built-in themes use, or null for one they don't.
String? themeColorName(AppLocalizations l10n, Color color) =>
    switch (color.toARGB32() & 0xFFFFFF) {
      0x474C2B => l10n.colorArmyGreen,
      0x575A3A => l10n.colorMoss,
      0xF4EAD0 => l10n.colorCream,
      0x242713 => l10n.colorForestGreen,
      0x33361F => l10n.colorDarkMoss,
      0xFBF5E6 => l10n.colorIvory,
      0xFFFFFF => l10n.colorWhite,
      0x1A1A18 => l10n.colorInk,
      0xC0262F => l10n.colorBrickRed,
      0x0E0E0D => l10n.colorNight,
      0x1B1B19 => l10n.colorCharcoal,
      0x0B1531 => l10n.colorMidnight,
      0x18284C => l10n.colorDuskBlue,
      0xF2F6FF => l10n.colorIce,
      0x2A63C9 => l10n.colorBrightBlue,
      0xBCD9F5 => l10n.colorSkyBlue,
      0xD3E6F9 => l10n.colorPaleSky,
      0xAB222A => l10n.colorCrimson,
      0x1748D4 => l10n.colorRoyalBlue,
      0x1238A8 => l10n.colorCobalt,
      0x0B1640 => l10n.colorDeepBlue,
      0xFFC7C7 => l10n.colorBlush,
      0x5E1224 => l10n.colorDarkMaroon,
      0x701C30 => l10n.colorWine,
      0xC0C5CC => l10n.colorSilver,
      0x0B0B0B || 0x0B0B0A => l10n.colorJetBlack,
      0x461D7C => l10n.colorRoyalPurple,
      0x55278F => l10n.colorViolet,
      0xFDD023 => l10n.colorGold,
      0x16130E => l10n.colorEspresso,
      0xFFC83D => l10n.colorAmber,
      0xFF7566 => l10n.colorSalmon,
      0xB8480A => l10n.colorBurntOrange,
      _ => null,
    };

/// What to call [color]: its name if it's one of the editor's colors, else
/// "Close to Maroon", for the nearest of them by eye (CIE Lab distance).
String colorNameOf(AppLocalizations l10n, Color color) {
  final opaque = color.withValues(alpha: 1);
  NamedColor? nearest;
  var best = double.infinity;
  for (final group in themePalette(l10n)) {
    for (final named in group.colors) {
      if (named.color.toARGB32() == opaque.toARGB32()) return named.name;
      final d = ColorMath.deltaE(named.color, opaque);
      if (d < best) {
        best = d;
        nearest = named;
      }
    }
  }
  return nearest == null
      ? ColorMath.hex(opaque)
      : l10n.adminThemeCloseTo(nearest.name);
}
