// Golden tests of the key screens in light and dark at a phone size
// (ARCH §9), drawn with the test font, so text shows as boxes. They catch
// layout, color, and spacing changes in CI. Even boxes antialias a little
// differently on each operating system, so these compare only on CI's
// ([ciGoldensOs]) and are skipped elsewhere.
// screens_readable_golden_test.dart draws the same screens with real fonts
// to look at.
//
// Update after an intended change: run the Update goldens workflow on
// GitHub (.github/workflows/update-goldens.yml), which records them on
// Linux and commits them. On a Linux machine:
//   flutter test --tags golden --update-goldens test/goldens/screens_golden_test.dart
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden.dart';
import '../helpers/scenes.dart';

void main() {
  setUpAll(useTolerantGoldens);

  final skip = Platform.operatingSystem == ciGoldensOs
      ? null
      : 'CI goldens compare on $ciGoldensOs only';

  for (final MapEntry(key: name, value: pump) in goldenScreens.entries) {
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('$name ($theme)', skip: skip != null, (tester) async {
        await pump(tester, dark: dark);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('ci/${name}_$theme.png'),
        );
      });
    }
  }
}
