import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The bundled font families (pubspec `fonts`), by role (SPEC §7.3).
///
/// Boot Camp Mix (#85, owner's pick 2026-11-22): the stencil for every
/// title, label, button, tab and count, and Nunito for reading text (#97,
/// owner's go 2026-11-23: "Nunito stays"). The stencil draws small letters
/// as capitals (tools/make_fonts.sh), so a label is in capitals however its
/// string is written.
abstract final class AppFonts {
  /// The stencil: Big Shoulders Stencil Display, Black.
  static const String stencil = 'Battleplan Stencil';

  /// Headings: screen titles, the team name, section headings.
  static const String display = stencil;

  /// Buttons, labels, tabs, chips, and people's names.
  static const String label = stencil;

  /// Body text, messages, inputs and information lines: Nunito, in
  /// [reading] (SemiBold), with bold spans in [bold]. Only those two
  /// weights ship, so a lighter one asked for draws in SemiBold and a
  /// heavier one in Bold.
  static const String body = 'Nunito';

  /// Reading text's weight: Nunito SemiBold.
  static const FontWeight reading = FontWeight.w600;

  /// A bold span in reading text (a place's name, a total): Nunito Bold.
  static const FontWeight bold = FontWeight.w700;

  /// The eyebrows over the team's name and on the event screen.
  static const String sticker = stencil;
}

/// Each bundled family and where its license ships (pubspec `assets`).
const Map<String, String> fontLicenseAssets = {
  'Battleplan Stencil (Big Shoulders Stencil)':
      'assets/fonts/battleplan_stencil/OFL.txt',
  AppFonts.body: 'assets/fonts/nunito/OFL.txt',
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
