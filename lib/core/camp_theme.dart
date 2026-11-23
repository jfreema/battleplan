import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/theme_override.dart';

/// A Boot Camp Mix scheme's colors as a super admin set them in the theme
/// editor (#88, owner's request 2026-11-22: "can you put the theme editor
/// back in? only available to super admins, of course."): each a
/// `CampPalette` token by name, as opaque ARGB. Only what's set is here;
/// the rest stays as the scheme ships. Pure Dart, so domain code can hold
/// it.
typedef CampColors = Map<CampColor, int>;

/// `config/app.campThemes` as the app reads it: under each scheme's value,
/// its tokens as `#RRGGBB`. Unknown schemes, tokens, and malformed colors
/// are skipped, so one bad entry can't break the rest. The old editor's
/// `config/app.themes` is left alone: its fields were the schemes before
/// Boot Camp Mix (#85).
Map<TeamScheme, CampColors> campThemesFromConfig(Object? raw) {
  if (raw is! Map) return const {};
  final out = <TeamScheme, CampColors>{};
  for (final MapEntry(:key, :value) in raw.entries) {
    final scheme = key is String ? TeamScheme.tryParse(key) : null;
    if (scheme == null || value is! Map) continue;
    final colors = <CampColor, int>{};
    for (final MapEntry(:key, :value) in value.entries) {
      final color = key is String ? CampColor.tryParse(key) : null;
      final argb = colorFromHex(value);
      if (color != null && argb != null) colors[color] = argb;
    }
    if (colors.isNotEmpty) out[scheme] = Map.unmodifiable(colors);
  }
  return Map.unmodifiable(out);
}

/// [colors] as `config/app.campThemes` keeps a scheme's: token to
/// `#RRGGBB`.
Map<String, String> campColorsToConfig(CampColors colors) => {
  for (final MapEntry(:key, :value) in colors.entries)
    key.value: hexOfColor(value)!,
};

/// Whether [a] and [b] hold the same colors for the same schemes.
bool campThemesEqual(
  Map<TeamScheme, CampColors> a,
  Map<TeamScheme, CampColors> b,
) {
  if (a.length != b.length) return false;
  for (final MapEntry(:key, :value) in a.entries) {
    final other = b[key];
    if (other == null || !campColorsEqual(value, other)) return false;
  }
  return true;
}

/// Whether [a] and [b] set the same tokens to the same colors.
bool campColorsEqual(CampColors a, CampColors b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
