// The schedule's Upcoming, Past and Calendar tabs with the app's real fonts
// (SPEC §7.3, §7.6): each at least 48 × 48 to tap, and read name first.
// The test font draws every glyph 1 em wide, which hid a Past only 34 wide,
// so this file loads the real ones (they stay loaded for the whole file).
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/golden.dart';
import 'helpers/scenes.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final (name, pump) in [
    ('team', pumpSchedule),
    ('group', pumpGroupSchedule),
  ]) {
    testWidgets("the $name schedule's tabs are 48 × 48 with the real fonts", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, scheme: TeamScheme.army);
      for (final (i, label) in ['Upcoming', 'Past', 'Calendar'].indexed) {
        final tab = find
            .ancestor(of: find.text(label), matching: find.byType(FocusRingInk))
            .first;
        final size = tester.getSize(tab);
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
        expect(
          find.bySemanticsLabel('$label, Tab ${i + 1} of 3'),
          findsOneWidget,
        );
      }
      // The words stay 24 apart, with the space between them tappable.
      final upcoming = tester.getRect(find.text('Upcoming'));
      final past = tester.getRect(find.text('Past'));
      expect(past.left - upcoming.right, moreOrLessEquals(24, epsilon: 0.5));
      await tester.tapAt(Offset(past.left - 6, past.center.dy));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Past, Tab 2 of 3')),
        isSemantics(isSelected: true, isButton: true, hasTapAction: true),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      semantics.dispose();
    });
  }
}
