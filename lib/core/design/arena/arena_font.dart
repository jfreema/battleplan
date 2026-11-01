import 'package:battleplan/core/design/arena/arena_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Barlow Condensed is only for Gumdrop Arena, so it isn't a bundled font
/// the web engine downloads before the first frame (about 40 KB): it's an
/// asset, loaded when Arena is picked or shown in the theme picker. Text
/// lays out again in it once it arrives. Safe to call again; it loads once,
/// and a failed load (offline) is tried again on the next call.
Future<void> loadArenaFont() async {
  if (debugSkipArenaFont) return;
  await (_loaded ??= _load().catchError((Object _) => _loaded = null));
}

/// Loads the font file as [arenaFont] (the goldens call it directly).
Future<void> loadArenaFontFile() =>
    (FontLoader(arenaFont)..addFont(rootBundle.load(arenaFontAsset))).load();

Future<void> _load() => loadArenaFontFile();

/// Tests draw Arena in the test font, as they did when the font was
/// bundled: a real font arriving partway through a test moves the layout
/// under its checks, differently on each machine. Goldens load it with
/// [loadArenaFontFile].
@visibleForTesting
bool debugSkipArenaFont = false;

/// The font file, listed under assets in pubspec.yaml.
const arenaFontAsset =
    'assets/fonts/barlow_condensed/BarlowCondensed-ExtraBoldItalic.ttf';

Future<void>? _loaded;
