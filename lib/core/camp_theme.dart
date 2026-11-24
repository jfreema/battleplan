import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/theme_override.dart';
import 'package:freezed_annotation/freezed_annotation.dart' show immutable;

/// A Boot Camp Mix scheme's colors as a super admin set them in the theme
/// editor (#88, owner's request 2026-11-22: "can you put the theme editor
/// back in? only available to super admins, of course."): each a
/// `CampPalette` token by name, as opaque ARGB. Only what's set is here;
/// the rest stays as the scheme ships. Pure Dart, so domain code can hold
/// it.
typedef CampColors = Map<CampColor, int>;

/// A Boot Camp Mix scheme as the theme editor changed it: its [colors]
/// (#88), its [header] background (#91, owner's request 2026-11-23:
/// "Add a few alternate backgrounds for the headers [in] the theme editor
/// that allows further customization to themes"), the camouflage unless
/// set, and whether its headers have the candy [sprinkles] (#98's, on
/// unless turned off; owner's question 2026-11-24: "WHy are there
/// sprinkles on the navy steel theme? how do i get rid of that? or add it
/// if i want it back?").
@immutable
final class CampTheme {
  const new({
    this.colors = const {},
    this.header = HeaderStyle.camo,
    this.sprinkles = true,
  });

  final CampColors colors;
  final HeaderStyle header;

  /// Whether the headers are strewn with candy sprinkles, as every scheme
  /// ships.
  final bool sprinkles;

  /// Whether it changes nothing: the scheme as it ships.
  bool get isEmpty => colors.isEmpty && header == HeaderStyle.camo && sprinkles;

  CampTheme copyWith({
    CampColors? colors,
    HeaderStyle? header,
    bool? sprinkles,
  }) => CampTheme(
    colors: colors ?? this.colors,
    header: header ?? this.header,
    sprinkles: sprinkles ?? this.sprinkles,
  );

  @override
  bool operator ==(Object other) =>
      other is CampTheme &&
      other.header == header &&
      other.sprinkles == sprinkles &&
      campColorsEqual(other.colors, colors);

  @override
  int get hashCode => Object.hash(
    header,
    sprinkles,
    Object.hashAllUnordered([
      for (final MapEntry(:key, :value) in colors.entries)
        Object.hash(key, value),
    ]),
  );

  @override
  String toString() {
    final hex = {
      for (final MapEntry(:key, :value) in colors.entries)
        key.value: hexOfColor(value),
    };
    return 'CampTheme(${header.value}, ${sprinkles ? 'sprinkles' : 'no sprinkles'}, $hex)';
  }
}

/// `config/app.campThemes` as the app reads it: under each scheme's value,
/// its tokens as `#RRGGBB`, `header` for its header background, and
/// `sprinkles: false` when its headers have none (anything else is on).
/// Unknown schemes, tokens, styles, and malformed colors are skipped, so
/// one bad entry can't break the rest. The old editor's `config/app.themes`
/// is left alone: its fields were the schemes before Boot Camp Mix (#85).
Map<TeamScheme, CampTheme> campThemesFromConfig(Object? raw) {
  if (raw is! Map) return const {};
  final out = <TeamScheme, CampTheme>{};
  for (final MapEntry(:key, :value) in raw.entries) {
    final scheme = key is String ? TeamScheme.tryParse(key) : null;
    if (scheme == null || value is! Map) continue;
    final colors = <CampColor, int>{};
    for (final MapEntry(:key, :value) in value.entries) {
      final color = key is String ? CampColor.tryParse(key) : null;
      final argb = colorFromHex(value);
      if (color != null && argb != null) colors[color] = argb;
    }
    final header = value['header'];
    final theme = CampTheme(
      colors: Map.unmodifiable(colors),
      header:
          (header is String ? HeaderStyle.tryParse(header) : null) ??
          HeaderStyle.camo,
      sprinkles: value['sprinkles'] != false,
    );
    if (!theme.isEmpty) out[scheme] = theme;
  }
  return Map.unmodifiable(out);
}

/// [colors] as `config/app.campThemes` keeps a scheme's: token to
/// `#RRGGBB`.
Map<String, String> campColorsToConfig(CampColors colors) => {
  for (final MapEntry(:key, :value) in colors.entries)
    key.value: hexOfColor(value)!,
};

/// Whether [a] and [b] hold the same themes for the same schemes.
bool campThemesEqual(
  Map<TeamScheme, CampTheme> a,
  Map<TeamScheme, CampTheme> b,
) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

/// Whether [a] and [b] set the same tokens to the same colors.
bool campColorsEqual(CampColors a, CampColors b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
