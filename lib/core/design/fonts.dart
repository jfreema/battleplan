import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The bundled font families (pubspec `fonts`), by role (SPEC §7.3).
///
/// Boot Camp Mix (#85, owner's pick 2026-11-22): the stencil for every
/// title, label, button, tab and count, and Comic Neue for reading text.
/// The stencil draws small letters as capitals (tools/make_fonts.sh), so
/// a label is in capitals however its string is written.
abstract final class AppFonts {
  /// The stencil: Big Shoulders Stencil Display, Black.
  static const String stencil = 'Battleplan Stencil';

  /// Headings: screen titles, the team name, section headings.
  static const String display = stencil;

  /// Buttons, labels, tabs, chips, and people's names.
  static const String label = stencil;

  /// Body text, messages, and inputs: Comic Neue Bold.
  static const String body = 'Comic Neue';

  /// The eyebrows over the team's name and on the event screen.
  static const String sticker = stencil;
}

/// Each bundled family and where its license ships (pubspec `assets`).
const Map<String, String> fontLicenseAssets = {
  'Battleplan Stencil (Big Shoulders Stencil)':
      'assets/fonts/battleplan_stencil/OFL.txt',
  AppFonts.body: 'assets/fonts/comic_neue/OFL.txt',
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
