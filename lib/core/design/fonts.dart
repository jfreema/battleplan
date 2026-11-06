import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The bundled font families (pubspec `fonts`), by role (SPEC §7.3).
abstract final class AppFonts {
  /// Headings: screen titles, the team name, section headings.
  static const String display = 'Lilita One';

  /// Buttons, labels, tabs, chips, and people's names.
  static const String label = 'Fredoka';

  /// Body text, messages, and inputs. Cut without Cyrillic, which draws in
  /// the fallback fonts (tools/cut_fonts.sh).
  static const String body = 'Nunito';

  /// The stencil eyebrows over the team's name and on the event screen:
  /// capitals only, never under 12 px. Cut to A–Z, the space and "·"
  /// (tools/cut_fonts.sh).
  static const String sticker = 'Black Ops One';
}

/// Each bundled family and where its license ships (pubspec `assets`).
const Map<String, String> fontLicenseAssets = {
  AppFonts.display: 'assets/fonts/lilita_one/OFL.txt',
  AppFonts.label: 'assets/fonts/fredoka/OFL.txt',
  AppFonts.body: 'assets/fonts/nunito/OFL.txt',
  AppFonts.sticker: 'assets/fonts/black_ops_one/OFL.txt',
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
