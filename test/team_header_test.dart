// The team header after the usability review's #13 (owner's go
// 2026-11-16): long names take two lines instead of being cut, in the same
// one-row header, and Messages has its own icon. The back arrow's one dot
// is in notifications_test.dart; the header's height and labels in
// shell_test.dart.
//
// The test font draws every letter, and the space, 1 em square, so a name
// is as wide as its length times the font size.

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/widgets/team_switcher_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Fits [name] in [width] in the app's theme, at [scale] text size.
Future<TeamNameFit> _fit(
  WidgetTester tester,
  String name,
  double width, {
  double scale = 1,
}) async {
  late TeamNameFit fit;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.of(TeamScheme.dark),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Builder(
          builder: (context) {
            fit = TeamName.fitIn(context, name, width);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return fit;
}

void main() {
  group('a long team name (#13)', () {
    // The stencil's sizes (#85): 32 down to 22 on one line, then two lines
    // at 22 or 19, spaced 0.04 em, so a name of n letters is n × 1.04 em.
    testWidgets('one line while one fits, from 32 down to 22', (tester) async {
      var fit = await _fit(tester, 'Hawks', 200);
      expect((fit.lines, fit.style.fontSize), (1, 32));
      // 5 × 22 × 1.04 = 114.4.
      fit = await _fit(tester, 'Hawks', 120);
      expect((fit.lines, fit.style.fontSize), (1, 22));
    });

    testWidgets('then two even lines at 22, then at 19', (tester) async {
      // "Android App Testers": 19 letters, 435 wide at 22 on one line.
      var fit = await _fit(tester, 'Android App Testers', 260);
      expect((fit.lines, fit.style.fontSize), (2, 22));
      // Wrapped in the longer line of the evenest break, 11 letters (and
      // their letter spacing), so it never ends with one word alone.
      expect(fit.width, closeTo(11 * 22 * 1.04, 2));
      fit = await _fit(tester, 'Android App Testers', 220);
      expect((fit.lines, fit.style.fontSize), (2, 19));
      expect(fit.width, closeTo(11 * 19 * 1.04, 2));
    });

    testWidgets('then two lines ending in "…", but never a word broken', (
      tester,
    ) async {
      // No break fits two lines at 19, and each word fits a line: two
      // lines, the second cut.
      var fit = await _fit(tester, 'Riverside Thunder 10U Blue', 180);
      expect((fit.lines, fit.style.fontSize, fit.width), (2, 19, null));
      // "Riverside" alone is wider than the line (178 at 19): one line.
      fit = await _fit(tester, 'Riverside Thunder 10U Blue', 170);
      expect((fit.lines, fit.style.fontSize), (1, 19));
    });

    testWidgets('at the largest text sizes, one line before a tall header', (
      tester,
    ) async {
      // At 200%, two lines at 22 are 90 tall, under the 96 allowed.
      var fit = await _fit(tester, 'Android App Testers', 600, scale: 2);
      expect((fit.lines, fit.style.fontSize), (2, 22));
      // At 225% they'd be 101 at 22, so 19's, 88.
      fit = await _fit(tester, 'Android App Testers', 600, scale: 2.25);
      expect((fit.lines, fit.style.fontSize), (2, 19));
      // At 250% even 19's would be 97: one line, cut.
      fit = await _fit(tester, 'Android App Testers', 600, scale: 2.5);
      expect(fit.lines, 1);
    });

    testWidgets('the eyebrow steps aside for two lines, still read', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Future<void> title(double width) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.of(TeamScheme.dark),
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: const TeamTitle(
                name: 'Android App Testers',
                eyebrow: 'Team chat',
                eyebrowStyle: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      );
      await title(800);
      expect(find.text('TEAM CHAT'), findsOneWidget);
      await title(250);
      expect(find.text('TEAM CHAT'), findsNothing);
      expect(find.bySemanticsLabel('Team chat'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Android App Testers')).maxLines, 2);
      handle.dispose();
    });
  });

  test("Messages is an envelope, not Chat's speech bubbles (#13)", () {
    expect(AppIcons.directMessage, Symbols.mail_rounded);
    expect(AppIcons.directMessage, isNot(AppIcons.chat));
  });
}
