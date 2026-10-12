// The main screens with real fonts (Roboto for Inter, Material Symbols for
// icons) in light and dark at a phone size, at 2x, to look at in review
// (ARCH §9). Fonts rasterize a little differently on each operating
// system, so these compare only on the one that made them
// ([readableGoldensOs]); screens_golden_test.dart covers CI's.
//
// Update after an intended change (on that system):
//   flutter test --tags golden --update-goldens
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden.dart';
import '../helpers/scenes.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens();
  });

  final skip = Platform.operatingSystem == readableGoldensOs
      ? null
      : 'Readable goldens compare on $readableGoldensOs only';

  for (final MapEntry(key: name, value: pump) in mainScreens.entries) {
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('$name ($theme)', skip: skip != null, (tester) async {
        await pump(tester, dark: dark);
        // The same layout, drawn at 2x so the text is sharp, with real
        // shadows rather than the test's solid outlines (reset before the
        // test ends, as the test framework checks).
        debugDisableShadows = false;
        tester.view
          ..devicePixelRatio = 2
          ..physicalSize = phoneSize * 2;
        try {
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('readable/${name}_$theme.png'),
          );
        } finally {
          debugDisableShadows = true;
        }
      });
    }
  }
}
