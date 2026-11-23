// Boot Camp Mix's round button (#87): a circle in its ink outline on a hard
// shadow down and to the right, drawn only outside the circle.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:battleplan/core/design/camp_round_border.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _shadow = Color(0xFFEF6A52);
const _ink = Color(0xFF1A1A18);

void main() {
  test(
    'the shadow shows outside the circle, down and to the right only',
    () async {
      const border = CampRoundBorder(
        shadow: _shadow,
        side: BorderSide(color: _ink, width: 2),
        offset: Offset(3, 3),
      );
      final recorder = ui.PictureRecorder();
      border.paint(Canvas(recorder), const Rect.fromLTWH(10, 10, 40, 40));
      final image = await recorder.endRecording().toImage(60, 60);
      final bytes = (await image.toByteData())!;
      Color at(double x, double y) {
        final i = (y.floor() * image.width + x.floor()) * 4;
        return Color.fromARGB(
          bytes.getUint8(i + 3),
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        );
      }

      // Just past the rim at the bottom right: the shadow. At the top left:
      // nothing. Inside, the face is left alone.
      const d = 21.5 / math.sqrt2;
      expect(at(30 + d, 30 + d), _shadow);
      expect(at(30 - d, 30 - d).a, 0);
      expect(at(30, 30).a, 0);
      // The ink outline, on the rim.
      expect(at(30, 11), _ink);
      image.dispose();
    },
  );

  test('keeps its shadow through copies, scaling and state changes', () {
    const a = CampRoundBorder(shadow: _shadow, side: BorderSide(width: 2));
    const b = CampRoundBorder(shadow: _ink, side: BorderSide(width: 4));
    expect(
      a,
      const CampRoundBorder(shadow: _shadow, side: BorderSide(width: 2)),
    );
    expect(a.hashCode, isNot(b.hashCode));
    expect(a.copyWith(side: const BorderSide(width: 3)).shadow, _shadow);
    expect((a.scale(2) as CampRoundBorder).offset, const Offset(4, 4));
    final halfway = a.lerpTo(b, 0.5)! as CampRoundBorder;
    expect(halfway.side.width, 3);
    expect(b.lerpFrom(a, 1), b);
    // Toward a plain circle it's a plain circle.
    expect(a.lerpTo(const CircleBorder(), 1), isA<CircleBorder>());
    expect(a.lerpFrom(const CircleBorder(), 0), isA<CircleBorder>());
  });
}
