// The candy finish (#98, SPEC §7.4): pieces on lips of their own darker
// shade, the twinkles, the header sprinkles and where they keep off, and
// Sugar Rush's own touches.
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/candy.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/widgets/camo.dart';
import 'package:battleplan/core/widgets/candy_box.dart';
import 'package:battleplan/core/widgets/candy_sprinkles.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<ByteData> _pixels(WidgetTester tester, Finder of) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(of);
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData())!;
    image.dispose();
    return data;
  });
  return bytes!;
}

Color _at(ByteData bytes, int width, int x, int y) {
  final i = (y * width + x) * 4;
  return Color.fromARGB(
    bytes.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

void main() {
  group('a candy piece (CandyBox)', () {
    testWidgets('sits on a lip of its darker shade, the ink round it, '
        'painted under its box', (tester) async {
      const face = Color(0xFFFFD43A);
      await tester.pumpWidget(
        Theme(
          data: AppTheme.of(TeamScheme.dark),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: ValueKey('box'),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: CandyBox(
                    color: face,
                    radius: 4,
                    depth: 6,
                    highlight: false,
                    width: 40,
                    height: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // The box takes its face's room alone: the lip is under it.
      expect(tester.getSize(find.byType(CandyBox)), const Size(40, 20));
      final bytes = await _pixels(tester, find.byKey(const ValueKey('box')));
      final ink = GumdropColors.forScheme(TeamScheme.dark).ink;
      // The face in the middle, the lip band under it (2.5 in from each
      // side, 3.5 deep), then the ink under the lip.
      expect(_at(bytes, 40, 20, 10), face);
      expect(_at(bytes, 40, 20, 21), Candy.lipOf(face));
      expect(_at(bytes, 40, 20, 25), ink);
      expect(_at(bytes, 40, 1, 21), ink);
    });

    testWidgets("is decoration: nothing for screen readers but its child's", (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: CandyBox(
              color: Color(0xFF5ED36A),
              shine: Rect.fromLTWH(4, 2, 8, 3),
              child: Text('GOING!'),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('GOING!'), findsOneWidget);
    });
  });

  group('twinkles', () {
    testWidgets('are still decoration, out of semantics and hits', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: GestureDetector(
              onTap: () => taps++,
              child: const Twinkled(
                spots: [TwinkleSpot(size: 22, left: 0, top: 0)],
                child: ColoredBox(
                  color: Color(0xFF252522),
                  child: SizedBox(width: 60, height: 60),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Twinkle), findsOneWidget);
      expect(tester.getSize(find.byType(Twinkle)), const Size(22, 22));
      // A tap on it reaches what's under it.
      await tester.tap(find.byType(Twinkle));
      expect(taps, 1);
      expect(
        find.descendant(
          of: find.byType(Twinkle),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    test('are lemon and sky on a dark scheme, mustard and pink on a light '
        "one, Sugar Rush's own on it", () {
      final dark = twinkleColors(CampPalette.black, light: false);
      expect(dark.first, const Color(0xFFFFD43A));
      expect(dark.second, const Color(0xFF8FD8FF));
      final light = twinkleColors(CampPalette.light, light: true);
      expect(light.first, CampPalette.light.mustard);
      expect(light.second, const Color(0xFFFF7FBF));
      final sugar = twinkleColors(CampPalette.sugarRush, light: true);
      expect(sugar.first, const Color(0xFFFFD43A));
      expect(sugar.second, const Color(0xFF8FD8FF));
    });
  });

  group('sprinkles', () {
    test("are a fixed seed's rods, at least 15 apart, 6.4 to 9.2 long", () {
      final rods = CandySprinkles.rods;
      expect(rods, hasLength(40));
      expect(identical(CandySprinkles.rodsFor(null), rods), isTrue);
      for (final (i, a) in rods.indexed) {
        expect(a.half * 2, inInclusiveRange(6.4, 9.2));
        for (final b in rods.skip(i + 1)) {
          expect((a.at - b.at).distance, greaterThanOrEqualTo(15));
        }
      }
      // Sugar Rush's 50, the same every time.
      final sugar = CandySprinkles.rodsFor(50);
      expect(sugar, hasLength(50));
      expect(identical(CandySprinkles.rodsFor(50), sugar), isTrue);
    });

    test('sit on ink rods on a light camouflage', () {
      expect(CandySprinkles.outlined(CampPalette.light), isTrue);
      expect(CandySprinkles.outlined(CampPalette.desertTan), isTrue);
      expect(CandySprinkles.outlined(CampPalette.sugarRush), isTrue);
      expect(CandySprinkles.outlined(CampPalette.black), isFalse);
      expect(CandySprinkles.outlined(CampPalette.army), isFalse);
    });

    test('keep off what they must', () {
      // Every rod painted, then none where the whole tile is kept off, and
      // none of the left half's where it is.
      final every = _CountingCanvas();
      CandySprinkles.paint(every, CandySprinkles.tile, CampPalette.black);
      final none = _CountingCanvas();
      CandySprinkles.paint(
        none,
        CandySprinkles.tile,
        CampPalette.black,
        keepOut: [Offset.zero & CandySprinkles.tile],
      );
      final half = _CountingCanvas();
      CandySprinkles.paint(
        half,
        CandySprinkles.tile,
        CampPalette.black,
        keepOut: [const Rect.fromLTWH(0, 0, 200, 140)],
      );
      expect(every.lines, greaterThan(30));
      expect(none.lines, 0);
      expect(half.lines, inExclusiveRange(0, every.lines));
      // On ink rods on a light camouflage: two lines a rod.
      final light = _CountingCanvas();
      CandySprinkles.paint(light, CandySprinkles.tile, CampPalette.light);
      expect(light.lines, every.lines * 2);
    });

    testWidgets('a header keeps them off its title and buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        Theme(
          data: AppTheme.of(TeamScheme.dark),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 390,
                child: CampHeader(
                  top: false,
                  child: SizedBox(
                    height: 120,
                    child: Row(
                      children: [
                        SprinkleKeepOut(
                          child: SizedBox(width: 390, height: 120),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // The layer is there, and nothing is left to paint around the one
      // keep-out that fills the header: no rod is drawn.
      expect(find.byType(SprinkleLayer), findsOneWidget);
      expect(find.byType(SprinkleKeepOut), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Sugar Rush (#98)', () {
    test('is the last of the twelve schemes (fourteen until Teal Wave '
        'left, #105, and Tropic Blue, #106), light, vanilla and '
        'bubblegum', () {
      expect(bootCampSchemes.last, TeamScheme.sugarrush);
      expect(bootCampSchemes, hasLength(12));
      expect(bootCampSchemes, isNot(contains(TeamScheme.tealwave)));
      expect(bootCampSchemes, isNot(contains(TeamScheme.tropicblue)));
      expect(TeamScheme.sugarrush.look, TeamScheme.sugarrush);
      expect(TeamScheme.sugarrush.isDark, isFalse);
      final p = SchemeRoles.of(TeamScheme.sugarrush).palette;
      expect(p.page, const Color(0xFFFFF4EA));
      expect(p.mustard, const Color(0xFFFF8CC6));
      expect(p.ink, const Color(0xFF2B1A4A));
    });

    test('has its own touches, which no other scheme has', () {
      final t = CampPalette.sugarRush.touches;
      expect(t.titleDrop, const Color(0xFFFF5FA8));
      expect(t.burst, const Color(0xFFFFD43A));
      expect(t.panelLip, const Color(0xFFE3D7F7));
      expect(t.panelRadius, 20);
      expect(t.pills, isTrue);
      expect(t.stripes, isTrue);
      expect(t.candyDots, isTrue);
      expect(t.sprinkles, hasLength(6));
      for (final scheme in bootCampSchemes) {
        if (scheme == TeamScheme.sugarrush) continue;
        expect(
          identical(
            SchemeRoles.builtIn(scheme).palette.touches,
            CandyTouches.none,
          ),
          isTrue,
          reason: scheme.value,
        );
      }
      // The theme editor's colors keep them.
      final edited = CampPalette.sugarRush.withColors({
        CampColor.page: const Color(0xFFFFFFFF),
      });
      expect(identical(edited.touches, CandyTouches.sugarRush), isTrue);
      // Its unpicked buttons' lips are the lavender, its title drop pink.
      final g = GumdropColors.forScheme(TeamScheme.sugarrush);
      expect(g.raisedLip, const Color(0xFFE3D7F7));
      expect(g.roles.titleDrop, const Color(0xFFFF5FA8));
    });

    testWidgets('its page dots are four candy colors', (tester) async {
      await tester.pumpWidget(
        Theme(
          data: AppTheme.of(TeamScheme.sugarrush),
          child: const PageDots(child: SizedBox(width: 36, height: 36)),
        ),
      );
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(PageDots),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(paint.painter, isA<CandyDotsPainter>());
    });
  });
}

/// Counts the lines drawn on it (each rod is one, or two on ink).
class _CountingCanvas implements Canvas {
  int lines = 0;

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => lines++;

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}
