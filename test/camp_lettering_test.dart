// Boot Camp Mix's outlined lettering (#85, #86): page titles, the event's
// title and counts, the team's name. It's a fill (white, or an answer's
// color) inside a thick ink outline, and it reads where either stands apart
// from what it sits on: the fill on a dark page (Black's ink outline is
// black on near-black), the outline on a light one (Sky Blue's white fill
// on its sky blue). The text contrast check skips it
// (test/helpers/contrast.dart), so this is its check, in every scheme.
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/widgets/camp_lettering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Large text's minimum (WCAG 1.4.3): the lettering is 25 px or more.
const double _large = 3;

void main() {
  for (final scheme in bootCampSchemes) {
    test('${scheme.value}: outlined lettering stands apart from the page, '
        'the panels and the camouflage', () {
      final c = GumdropColors.forScheme(scheme);
      final p = c.roles.palette;
      double reads(Color fill, Color under) => [
        ColorMath.contrast(fill, under),
        ColorMath.contrast(p.ink, under),
      ].reduce((a, b) => a > b ? a : b);
      for (final (under, where) in [
        (p.page, 'page'),
        (p.panel, 'panel'),
        (p.camoGround, 'camouflage'),
        (p.red, "the chat event's header"),
      ]) {
        expect(
          reads(CampPalette.titleFill, under),
          greaterThanOrEqualTo(_large),
          reason: '${scheme.value}: a white title on the $where',
        );
      }
      // The event's counts, on the page.
      for (final (fill, what) in [
        (c.mint.face, 'Going'),
        (c.lemon.face, 'Maybe'),
        (CampPalette.cantGo, "Can't go"),
      ]) {
        expect(
          reads(fill, p.page),
          greaterThanOrEqualTo(_large),
          reason: '${scheme.value}: the $what count',
        );
      }
    });
  }

  testWidgets('outlined lettering tells the contrast check who it is', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutlinedText(
              'Team settings',
              style: TextStyle(fontSize: 40),
            ),
          ),
        ),
      ),
    );
    final data = tester
        .getSemantics(find.bySemanticsLabel('Team settings'))
        .getSemanticsData();
    expect(data.identifier, OutlinedText.semanticsIdentifier);
    handle.dispose();
  });
}
