// A few key screens in Gumdrop Arena (SPEC §7.4) with real fonts, to look
// at in review, as screens_readable_golden_test.dart does for the other
// themes: chat (and in a team's color), the schedule, an event, and
// Settings. Kept apart, with the theme (lib/core/design/arena/).
//
// Update after an intended change (on macOS):
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

  final skip = Platform.operatingSystem != readableGoldensOs;

  for (final name in [
    'chat',
    'chat_orange',
    'schedule',
    'event_details',
    'settings',
  ]) {
    testWidgets('$name (arena)', skip: skip, (tester) async {
      await goldenScreens[name]!(tester, theme: ThemePreference.arena);
      debugDisableShadows = false;
      final logical = tester.view.physicalSize / tester.view.devicePixelRatio;
      tester.view
        ..devicePixelRatio = 2
        ..physicalSize = logical * 2;
      try {
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('readable/${name}_arena.png'),
        );
      } finally {
        debugDisableShadows = true;
      }
    });
  }
}
