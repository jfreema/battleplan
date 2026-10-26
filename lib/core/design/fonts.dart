import 'package:battleplan/core/design/arena/arena_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The bundled font families (pubspec `fonts`), by role (SPEC §7.3).
abstract final class AppFonts {
  /// Headings: screen titles, the team name, section headings.
  static const String display = 'Lilita One';

  /// Buttons, labels, tabs, chips, and people's names.
  static const String label = 'Fredoka';

  /// Body text, messages, and inputs.
  static const String body = 'Nunito';
}

/// Each bundled family and where its license ships (pubspec `assets`).
const Map<String, String> fontLicenseAssets = {
  AppFonts.display: 'assets/fonts/lilita_one/OFL.txt',
  AppFonts.label: 'assets/fonts/fredoka/OFL.txt',
  AppFonts.body: 'assets/fonts/nunito/OFL.txt',
  arenaFont: 'assets/fonts/barlow_condensed/OFL.txt',
};

/// Lists each bundled font's SIL Open Font License under Settings › About ›
/// Licenses, as the license asks of anyone bundling the font (SPEC §7.3;
/// ARCH §5.5: fonts are bundled as assets).
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: family, value: asset)
        in fontLicenseAssets.entries) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString(asset));
    }
  });
}
