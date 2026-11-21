import 'package:battleplan/core/constants.g.dart';
import 'package:freezed_annotation/freezed_annotation.dart' show immutable;

/// A theme's own colors, set in the Super Admin Panel's theme editor (#82,
/// owner's request 2026-11-20: "make the app's default buttons and whatever
/// is always coral colored, customizable for the theme ... Allow the
/// background and the background of the bubbles to be changed in the theme
/// editor and allow new themes to be saved"). Kept in `config/app.themes`
/// under the scheme's value. Pure Dart, so domain code can hold it.
///
/// Over a built-in scheme it changes only what it sets. A saved theme takes
/// one of the reserved slots (`custom1` to `custom12`, [SavedThemeSlots]):
/// it has a [name], and a [base], the built-in scheme it starts from, which
/// gives every color it doesn't set.
@immutable
final class ThemeOverride {
  const new({this.name, this.base, this.accent, this.page, this.card});

  /// A saved theme's name, shown in the pickers.
  final String? name;

  /// A saved theme's starting scheme; null over a built-in one.
  final TeamScheme? base;

  /// The "you" color, coral in every built-in scheme: the main buttons, the
  /// + and send, your messages, the picked tab, and unread counts. As ARGB,
  /// like the rest; null keeps the base's.
  final int? accent;

  /// The page behind everything.
  final int? page;

  /// Cards, sheets, dialogs, and the chat's filled bubbles.
  final int? card;

  /// Whether this is a saved theme rather than a change to a built-in one.
  bool get isSaved => base != null;

  @override
  bool operator ==(Object other) =>
      other is ThemeOverride &&
      other.name == name &&
      other.base == base &&
      other.accent == accent &&
      other.page == page &&
      other.card == card;

  @override
  int get hashCode => Object.hash(name, base, accent, page, card);

  @override
  String toString() =>
      'ThemeOverride(name: $name, base: ${base?.value}, accent: '
      '${hexOfColor(accent)}, page: ${hexOfColor(page)}, card: '
      '${hexOfColor(card)})';
}

/// How long a saved theme's name can be; the server checks it too
/// (`THEME_NAME_MAX` in functions/src/admin/themes.ts).
const themeNameMax = 30;

/// The reserved slots saved themes take (#82): stored and checked like any
/// scheme, so a pick of one needs nothing new from the rules or the models.
extension SavedThemeSlots on TeamScheme {
  /// Whether this is a slot for a saved theme, not a built-in scheme.
  bool get isCustom => value.startsWith('custom');
}

/// The schemes the app ships with, in picker order.
final List<TeamScheme> builtInSchemes = List.unmodifiable([
  for (final s in TeamScheme.values)
    if (!s.isCustom) s,
]);

/// The slots for saved themes, in order: a new one takes the first free.
final List<TeamScheme> customSchemes = List.unmodifiable([
  for (final s in TeamScheme.values)
    if (s.isCustom) s,
]);

/// Whether [scheme] can be shown: built in, or a saved theme in [themes]. A
/// slot nobody has saved a theme in (or whose theme was deleted) isn't.
bool schemeAvailable(
  TeamScheme scheme,
  Map<TeamScheme, ThemeOverride> themes,
) => !scheme.isCustom || (themes[scheme]?.isSaved ?? false);

/// [scheme] if it can be shown ([schemeAvailable]), else null, so whatever
/// comes next (the team's default, my own default) takes its place.
TeamScheme? usableScheme(
  TeamScheme? scheme,
  Map<TeamScheme, ThemeOverride> themes,
) => scheme != null && schemeAvailable(scheme, themes) ? scheme : null;

/// `#RRGGBB` as opaque ARGB, or null for anything else.
int? colorFromHex(Object? value) {
  if (value is! String) return null;
  final m = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(value.trim());
  return m == null ? null : 0xFF000000 | int.parse(m[1]!, radix: 16);
}

/// ARGB as `#RRGGBB`, or null.
String? hexOfColor(int? argb) => argb == null
    ? null
    : '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// `config/app.themes` as the app reads it: each entry under a scheme's
/// value. An entry for a saved slot needs a name and a known built-in base;
/// anything malformed is skipped, so one bad entry can't break the rest.
Map<TeamScheme, ThemeOverride> themesFromConfig(Object? raw) {
  if (raw is! Map) return const {};
  final out = <TeamScheme, ThemeOverride>{};
  for (final MapEntry(:key, :value) in raw.entries) {
    final scheme = TeamScheme.tryParse(key as String?);
    if (scheme == null || value is! Map) continue;
    final accent = colorFromHex(value['accent']);
    final page = colorFromHex(value['page']);
    final card = colorFromHex(value['card']);
    if (scheme.isCustom) {
      final name = value['name'];
      final base = TeamScheme.tryParse(value['base'] as String?);
      if (name is! String || name.trim().isEmpty) continue;
      if (base == null || base.isCustom) continue;
      out[scheme] = ThemeOverride(
        name: name.trim(),
        base: base,
        accent: accent,
        page: page,
        card: card,
      );
    } else if (accent != null || page != null || card != null) {
      out[scheme] = ThemeOverride(accent: accent, page: page, card: card);
    }
  }
  return Map.unmodifiable(out);
}
