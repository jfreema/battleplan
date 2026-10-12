import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where Inter's license ships with the app (pubspec `assets`).
const interLicenseAsset = 'assets/fonts/inter/OFL.txt';

/// Lists Inter's SIL Open Font License under Settings › About › Licenses,
/// as the license asks of anyone bundling the font (SPEC §7.3; ARCH §5.5:
/// fonts are bundled as assets).
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Inter',
    ], await rootBundle.loadString(interLicenseAsset));
  });
}
