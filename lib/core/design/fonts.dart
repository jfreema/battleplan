import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The bundled font families (pubspec `fonts`), by role (SPEC §7.3).
///
/// Team Shirt (#104, owner's pick 2026-11-27: "update the site and app to
/// do look 56 Team Shirt with the Lato font"), named for a team's shirt,
/// rounded letters over a line of stencil:
///
/// - [stencil], only where something is stamped on: tags, the Going!
///   stamps, dog tags, and the weekday on a date. It draws small letters as
///   capitals (tools/make_fonts.sh), so a tag is in capitals however its
///   string is written.
/// - [bubbly], Candy Pop's letters (Lilita One, the wordmark's), for names
///   and titles: the team's name, a screen's or an event's title, dates,
///   month labels, and questions.
/// - [plain], Lato (bundled as Battleplan Sans, tools/make_fonts.sh), for
///   everything else: [reading] text in Regular with [bold] spans, tabs and
///   rows in Bold, and buttons, labels and people's names in [heavy].
abstract final class AppFonts {
  /// The stencil: Big Shoulders Stencil Display, Black.
  static const String stencil = 'Battleplan Stencil';

  /// Candy Pop's bubbly letters: Lilita One, which has one weight
  /// ([displayWeight]).
  static const String bubbly = 'Lilita One';

  /// The bubbly letters' only weight. Always ask for it: asked for 600 or
  /// more, the engine thickens the letters artificially.
  static const FontWeight displayWeight = FontWeight.w400;

  /// The plain face: Lato, cut to Latin and renamed (its license reserves
  /// the name for the untouched font). Regular, Bold and Black ship, so a
  /// weight between two draws as fonts are matched: 500 in the Regular, 600
  /// in the Bold, 800 in the Black.
  static const String plain = 'Battleplan Sans';

  /// Headings: screen titles, the team name, section headings.
  static const String display = bubbly;

  /// Buttons, labels, tabs, chips, and people's names, in [heavy] or
  /// [bold].
  static const String label = plain;

  /// Body text, messages, inputs and information lines, in [reading], with
  /// bold spans in [bold].
  static const String body = plain;

  /// Reading text's weight: Regular.
  static const FontWeight reading = FontWeight.w400;

  /// A bold span in reading text (a place's name, a total), and the quiet
  /// labels: tabs, the views over the schedule, a row that's a link.
  static const FontWeight bold = FontWeight.w700;

  /// Buttons, labels and people's names: Black.
  static const FontWeight heavy = FontWeight.w900;

  /// What's stamped on: tags, stamps, dog tags, the weekday on a date.
  static const String sticker = stencil;

  /// The plain face's Black alone, as a family of its own (pubspec): a
  /// fallback family is asked for the weight of the text it's in, and the
  /// bubbly letters' is 400, which in [plain] would be the Regular.
  static const String plainBlack = 'Battleplan Sans Black';

  /// What [bubbly] lacks (it has Latin-1 and little else: no Polish, Czech,
  /// Turkish or Vietnamese letters) draws in the plain face's Black, as
  /// heavy as the title around it, before the system's font.
  static const List<String> bubblyFallback = [plainBlack, plain];

  /// How far apart the bubbly letters sit: 0.01 em, as the mockup sets its
  /// titles.
  static double bubblySpacing(double? size) => (size ?? 20) * 0.01;

  /// The tracking of a small label in the plain face's capitals ("NEXT
  /// UP"): 0.08 em.
  static double capsSpacing(double? size) => (size ?? 11) * 0.08;
}

/// Each bundled family and where its license ships (pubspec `assets`).
const Map<String, String> fontLicenseAssets = {
  'Battleplan Stencil (Big Shoulders Stencil)':
      'assets/fonts/battleplan_stencil/OFL.txt',
  AppFonts.bubbly: 'assets/fonts/lilita_one/OFL.txt',
  'Battleplan Sans (Lato)': 'assets/fonts/battleplan_sans/OFL.txt',
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
