// Boot Camp Mix's round button (#87) with the candy finish (#98): a glossy
// ball in its ink outline on a lip of the face's darker shade, the ink
// carried round under it, drawn only outside the circle.
import 'dart:ui' as ui;

import 'package:battleplan/core/design/camp_round_border.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _lip = Color(0xFFC28E0E);
const _ink = Color(0xFF1A1A18);
const _shine = Color(0xFFFFFFFF);

void main() {
  test('the lip shows under the circle only, the ink round it', () async {
    const border = CampRoundBorder(
      lip: _lip,
      ink: _ink,
      side: BorderSide(color: _ink, width: 2),
      shine: _shine,
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

    // Within a little, for the curve's anti-aliasing.
    Matcher near(Color c) => predicate<Color>(
      (x) => (x.r - c.r).abs() < 0.05 && (x.g - c.g).abs() < 0.05,
      'near $c',
    );
    // Under the ball's bottom: the lip band 2 px down, then the ink under
    // it; beside the ball and above it, nothing. Inside, the face is left
    // alone, but for the shine near its top left.
    expect(at(30, 50), near(_lip));
    expect(at(30, 53), _ink);
    expect(at(30, 55).a, 0);
    expect(at(5, 30).a, 0);
    expect(at(30, 5).a, 0);
    expect(at(30, 30).a, 0);
    expect(at(23.8, 20.4), _shine);
    // The ink outline, on the rim.
    expect(at(30, 11), _ink);
    image.dispose();
  });

  test('keeps its lip through copies, scaling and state changes', () {
    const a = CampRoundBorder(lip: _lip, ink: _ink, side: BorderSide(width: 2));
    const b = CampRoundBorder(lip: _ink, ink: _ink, side: BorderSide(width: 4));
    expect(
      a,
      const CampRoundBorder(lip: _lip, ink: _ink, side: BorderSide(width: 2)),
    );
    expect(a.hashCode, isNot(b.hashCode));
    expect(a.copyWith(side: const BorderSide(width: 3)).lip, _lip);
    expect((a.scale(2) as CampRoundBorder).depth, 8);
    final halfway = a.lerpTo(b, 0.5)! as CampRoundBorder;
    expect(halfway.side.width, 3);
    expect(b.lerpFrom(a, 1), b);
    // Toward a plain circle it's a plain circle.
    expect(a.lerpTo(const CircleBorder(), 1), isA<CircleBorder>());
    expect(a.lerpFrom(const CircleBorder(), 0), isA<CircleBorder>());
  });
}
