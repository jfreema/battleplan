// Tap targets with the app's real fonts (SPEC §7.6), at a 390 px phone and
// a 360 px one (many Android phones). The test font draws every letter
// 1 em wide, so a tap area sized by its word or squeezed by a narrow
// screen (the icon colors) only shows up here. Fonts stay loaded for the
// whole file, which is why this is a file of its own.
//
// The schedule isn't here yet: its Upcoming/Past toggle sizes each tab by
// its word, and "Past" is narrower than 44 px. The schedule's own fix
// widens those tabs and adds the schedule to this list.
import 'package:battleplan/core/constants.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/golden.dart';
import 'helpers/scenes.dart';

void main() {
  setUpAll(loadAppFonts);

  final guidelines = {
    'Android tap targets': androidTapTargetGuideline,
    'iOS tap targets': iOSTapTargetGuideline,
  };

  Future<void> top(WidgetTester tester, Size size, String path) async {
    await pumpTeam(tester, scheme: TeamScheme.army, size: size);
    await goTo(tester, path);
  }

  final screens = {
    'chat': (WidgetTester tester, Size size) =>
        pumpTeam(tester, scheme: TeamScheme.army, size: size),
    'teams': (WidgetTester tester, Size size) => top(tester, size, '/teams'),
    'profile': (WidgetTester tester, Size size) =>
        top(tester, size, '/profile'),
    'your icon': (WidgetTester tester, Size size) async {
      await top(tester, size, '/profile');
      await pushTo(tester, '/profile/icon');
    },
    'team info': (WidgetTester tester, Size size) async {
      await pumpTeam(tester, scheme: TeamScheme.army, size: size);
      await pushTo(tester, '/g/a/info');
    },
    'color scheme': (WidgetTester tester, Size size) async {
      await top(tester, size, '/g/a/info');
      await pushTo(tester, '/g/a/scheme');
    },
    'dues': (WidgetTester tester, Size size) async {
      await top(tester, size, '/g/a/info');
      await pushTo(tester, '/g/a/dues');
    },
    'due': (WidgetTester tester, Size size) async {
      await top(tester, size, '/g/a/info');
      await pushTo(tester, '/g/a/dues');
      await pushTo(tester, '/g/a/dues/d0');
    },
    'new due': (WidgetTester tester, Size size) async {
      await top(tester, size, '/g/a/info');
      await pushTo(tester, '/g/a/dues');
      await pushTo(tester, '/g/a/dues/new');
    },
  };

  for (final size in [phoneSize, const Size(360, 780)]) {
    for (final MapEntry(key: name, value: pump) in screens.entries) {
      testWidgets('$name meets the tap target guidelines at '
          '${size.width.round()} px with real fonts', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, size);
        final failures = <String>[];
        for (final MapEntry(key: what, value: guideline)
            in guidelines.entries) {
          final result = await guideline.evaluate(tester);
          if (!result.passed) failures.add('$what:\n${result.reason}');
        }
        expect(failures, isEmpty, reason: failures.join('\n\n'));
        handle.dispose();
      });
    }
  }
}
