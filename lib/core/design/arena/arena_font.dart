import 'package:battleplan/core/design/arena/arena_theme.dart';
import 'package:flutter/services.dart';

/// Barlow Condensed is only for Gumdrop Arena, so it isn't a bundled font
/// the web engine downloads before the first frame (about 40 KB): it's an
/// asset, loaded when Arena is picked or shown in the theme picker. Text
/// lays out again in it once it arrives. Safe to call again; it loads once.
Future<void> loadArenaFont() => _loaded ??= (FontLoader(
  arenaFont,
)..addFont(rootBundle.load(arenaFontAsset))).load();

/// The font file, listed under assets in pubspec.yaml.
const arenaFontAsset =
    'assets/fonts/barlow_condensed/BarlowCondensed-ExtraBoldItalic.ttf';

Future<void>? _loaded;
