import 'package:battleplan/core/design/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// The Battleplan mark (SPEC §7.1): a white flag on a pole, with an angular
/// B cut out of it, on a rounded brand-blue tile. Drawn from the same
/// shapes as `website/favicon.svg` and `assets/brand/*.svg`, so it's sharp
/// at any size and needs no image to load. Decorative: screen readers skip
/// it, as the app's name is always written next to it.
class BrandMark extends StatelessWidget {
  const new({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  const new();

  // The art is drawn in its source's coordinates (a 726 × 690 drawing,
  // centered at 363, 347), then placed on a 512 tile as the SVGs do.
  static const _tile = 512.0;
  static const _corner = 112.0;

  static final Path _flag = Path()
    ..fillType = PathFillType.evenOdd
    ..moveTo(150, 98)
    ..cubicTo(260, 40, 380, 190, 690, 122)
    ..lineTo(588, 305)
    ..lineTo(690, 480)
    ..cubicTo(470, 560, 330, 400, 118, 492)
    ..close()
    // The B, cut out of the flag.
    ..addPolygon(const [
      Offset(200, 155),
      Offset(445, 155),
      Offset(505, 215),
      Offset(505, 255),
      Offset(462, 297),
      Offset(505, 340),
      Offset(505, 385),
      Offset(445, 430),
      Offset(218, 430),
      Offset(270, 370),
      Offset(405, 370),
      Offset(428, 347),
      Offset(400, 318),
      Offset(205, 318),
      Offset(262, 260),
      Offset(408, 260),
      Offset(435, 235),
      Offset(410, 210),
      Offset(255, 210),
    ], true);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / _tile, size.height / _tile)
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, _tile, _tile),
          const Radius.circular(_corner),
        ),
        Paint()..color = AppTokens.brand,
      )
      ..translate(256, 266)
      ..scale(0.6)
      ..translate(-363, -347);
    final white = Paint()..color = Colors.white;
    canvas
      ..drawLine(
        const Offset(60, 660),
        const Offset(108, 75),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 48
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(const Offset(112, 52), 42, white)
      ..drawPath(_flag, white)
      ..restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
