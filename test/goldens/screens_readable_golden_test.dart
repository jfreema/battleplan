// The key screens with real fonts (the bundled Lilita One, Fredoka, and
// Nunito, Material Symbols for icons) in the three Gumdrop themes, Light,
// Dark, and Candy, at a phone size (one at a wide size), at 2x, to look at
// in review (ARCH §9). Fonts rasterize a little differently on each operating
// system, so these compare only on the one that made them
// ([readableGoldensOs]), and CI (Linux) skips them: they're for looking at
// a change, not for catching one.
//
// Update after an intended change (on that system):
//   flutter test --tags golden --update-goldens
@Tags(['golden'])
library;

import 'dart:io';

import 'package:battleplan/core/constants.g.dart';
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

  for (final MapEntry(key: name, value: pump) in goldenScreens.entries) {
    // The three Gumdrop themes (SET-2).
    for (final preference in [
      ThemePreference.light,
      ThemePreference.dark,
      ThemePreference.candy,
    ]) {
      final theme = preference.value;
      testWidgets('$name ($theme)', skip: skip != null, (tester) async {
        await pump(tester, theme: preference);
        // The same layout, drawn at 2x so the text is sharp, with real
        // shadows rather than the test's solid outlines (reset before the
        // test ends, as the test framework checks).
        debugDisableShadows = false;
        final logical = tester.view.physicalSize / tester.view.devicePixelRatio;
        tester.view
          ..devicePixelRatio = 2
          ..physicalSize = logical * 2;
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
