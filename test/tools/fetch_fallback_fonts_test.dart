// The web engine's fallback fonts, served from our site (ARCH §5.5): which
// files the build copies, read from the engine's own list.
import 'package:flutter_test/flutter_test.dart';

import '../../tools/fetch_fallback_fonts.dart' as fallback;

void main() {
  test("reads the font paths from the engine's sources, once each", () {
    const data = '''
List<NotoFont> getFallbackFontList() => <NotoFont>[
  NotoFont(
    'Noto Color Emoji 0',
    'notocoloremoji/v32/Yq6P-KqIXTD0t4D9z1ESnKM3-HpFabsE4tq3luCC7p-aXxcn.0.woff2',
  ),
  NotoFont('Noto Sans Symbols', 'notosanssymbols/v43/rP2up3q65FkAtHfwd-eIS2brbDN6gxP34F9jRRCe4W3gfQ8gavVFRkzrbQ.woff2'),
];''';
    const roboto = r"""
String _robotoUrl =
    '${configuration.fontFallbackBaseUrl}roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2';""";
    expect(fallback.fontPathsIn([data, roboto, roboto]), [
      'notocoloremoji/v32/Yq6P-KqIXTD0t4D9z1ESnKM3-HpFabsE4tq3luCC7p-aXxcn.0.woff2',
      'notosanssymbols/v43/rP2up3q65FkAtHfwd-eIS2brbDN6gxP34F9jRRCe4W3gfQ8gavVFRkzrbQ.woff2',
      'roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2',
    ]);
  });
}
