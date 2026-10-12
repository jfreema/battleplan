// Golden tests of the main screens in light and dark at a phone size
// (ARCH §9), drawn with the test font: text shows as boxes, which draw the
// same on every operating system, so these run in CI and catch layout,
// color, and spacing changes. screens_readable_golden_test.dart draws the
// same screens with real fonts to look at.
//
// Update after an intended change:
//   flutter test --tags golden --update-goldens
@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden.dart';
import '../helpers/scenes.dart';

void main() {
  setUpAll(useTolerantGoldens);

  for (final MapEntry(key: name, value: pump) in mainScreens.entries) {
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('$name ($theme)', (tester) async {
        await pump(tester, dark: dark);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('ci/${name}_$theme.png'),
        );
      });
    }
  }
}
