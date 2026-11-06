import 'package:material_ui/material_ui.dart';

/// The Battleplan mark (SPEC §7.1), the Stencil Crest: an upright team-patch
/// shield with a cream rim, a cream B and a coral hem at its point, on a
/// rounded army-green tile, with an ink edge and hard ink shadows like Open
/// Field's stickers. Drawn from the same shapes as `website/favicon.svg` and
/// `assets/brand/*.svg`, so it's sharp at any size and needs no image to load.
/// Decorative: screen readers skip it, as the app's name is always written
/// next to it.
class BrandMark extends StatelessWidget {
  const new({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  const new();

  // The art is drawn in the SVGs' 1024 coordinates.
  static const _tile = 1024.0;
  static const _corner = 224.0;
  static const _ink = Color(0xFF1A1A18);
  static const _cream = Color(0xFFF4EAD0);
  static const _olive = Color(0xFF575A3A);
  static const _coral = Color(0xFFF45B5B);

  // The shield's field: a flat top with cut corners (softened a little),
  // straight sides, and a long curved point. The ink edge and the cream rim
  // are this path stroked with miter joins.
  static final Path _shield = Path()
    ..moveTo(277.6, 160)
    ..lineTo(714.4, 160)
    ..cubicTo(718.5, 160, 722.4, 161.6, 725.3, 164.5)
    ..lineTo(795.5, 234.7)
    ..cubicTo(798.4, 237.6, 800, 241.5, 800, 245.6)
    ..lineTo(800, 549.4)
    ..cubicTo(800, 674.8, 648, 758.4, 496, 848)
    ..cubicTo(344, 758.4, 192, 674.8, 192, 549.4)
    ..lineTo(192, 245.6)
    ..cubicTo(192, 241.5, 193.6, 237.6, 196.5, 234.7)
    ..lineTo(266.7, 164.5)
    ..cubicTo(269.6, 161.6, 273.5, 160, 277.6, 160)
    ..close();

  // The coral hem: the field's point below y = 736.
  static final Path _hem = Path()
    ..moveTo(674.6, 736)
    ..cubicTo(622.3, 774.6, 559.2, 810.8, 496, 848)
    ..cubicTo(432.8, 810.8, 369.7, 774.6, 317.4, 736)
    ..lineTo(674.6, 736)
    ..close();

  // The B, Black Ops One's shape fitted to whole pixels at 32 px. Its two
  // counters wind the other way, so they stay holes.
  static final Path _b = Path()
    ..moveTo(256, 224)
    ..lineTo(608, 224)
    ..lineTo(704, 320)
    ..lineTo(704, 400)
    ..lineTo(656, 448)
    ..lineTo(704, 496)
    ..lineTo(704, 576)
    ..lineTo(608, 672)
    ..lineTo(256, 672)
    ..close()
    ..moveTo(416, 320)
    ..lineTo(416, 416)
    ..lineTo(544, 416)
    ..lineTo(544, 320)
    ..close()
    ..moveTo(416, 480)
    ..lineTo(416, 576)
    ..lineTo(544, 576)
    ..lineTo(544, 480)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    const tile = Rect.fromLTWH(0, 0, _tile, _tile);
    // Paint for an outline drawn centred on the shield's edge.
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.miter
      ..strokeMiterLimit = 8;
    final ink = Paint()..color = _ink;
    canvas
      ..save()
      ..scale(size.width / _tile, size.height / _tile)
      // The tile: army green, lifted a little in the middle.
      ..drawRRect(
        RRect.fromRectAndRadius(tile, const Radius.circular(_corner)),
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, -0.140625),
            radius: 0.72265625,
            colors: [Color(0xFF50552F), Color(0xFF474C2B), Color(0xFF3D4124)],
            stops: [0, 0.55, 1],
          ).createShader(tile),
      )
      // The crest's hard shadow, down and to the right.
      ..save()
      ..translate(24, 28)
      ..drawPath(_shield, ink)
      ..drawPath(_shield, stroke(_ink, 192))
      ..restore()
      // The ink edge, the cream rim, the olive field and the coral hem.
      ..drawPath(_shield, ink)
      ..drawPath(_shield, stroke(_ink, 192))
      ..drawPath(_shield, Paint()..color = _cream)
      ..drawPath(_shield, stroke(_cream, 128))
      ..drawPath(_shield, Paint()..color = _olive)
      ..drawPath(_hem, Paint()..color = _coral)
      // The B's hard shadow, then the B.
      ..save()
      ..translate(24, 24)
      ..drawPath(_b, ink)
      ..restore()
      ..drawPath(_b, Paint()..color = _cream)
      ..restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
