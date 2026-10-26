import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The Battleplan mark (SPEC §7.1), the Sticker Crest: a lemon shield,
/// tilted and outlined in navy on a navy hard shadow, with a white chat
/// bubble saying B, on a rounded blue raspberry tile. Drawn from the same
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

  // The art is drawn in the SVGs' 1024 coordinates.
  static const _tile = 1024.0;
  static const _corner = 224.0;
  static const _navy = Color(0xFF0B1531);
  static const _lemon = Color(0xFFFFD84A);
  static const _white = Color(0xFFFFFFFF);

  static final Path _shield = Path()
    ..moveTo(240, 196)
    ..lineTo(784, 196)
    ..quadraticBezierTo(832, 196, 832, 244)
    ..lineTo(832, 492)
    ..cubicTo(832, 700, 694, 808, 512, 862)
    ..cubicTo(330, 808, 192, 700, 192, 492)
    ..lineTo(192, 244)
    ..quadraticBezierTo(192, 196, 240, 196)
    ..close();

  static final Path _bubble = Path()
    ..moveTo(371, 337)
    ..lineTo(653, 337)
    ..quadraticBezierTo(725, 337, 725, 409)
    ..lineTo(725, 539)
    ..quadraticBezierTo(725, 611, 653, 611)
    ..lineTo(476, 611)
    ..lineTo(392, 688)
    ..lineTo(406, 611)
    ..lineTo(371, 611)
    ..quadraticBezierTo(299, 611, 299, 539)
    ..lineTo(299, 409)
    ..quadraticBezierTo(299, 337, 371, 337)
    ..close();

  // Lilita One's B, as a path.
  static final Path _b = Path()
    ..moveTo(565.7, 433.8)
    ..quadraticBezierTo(565.7, 456.7, 545.9, 468.6)
    ..quadraticBezierTo(556.7, 472.5, 563.9, 482.2)
    ..quadraticBezierTo(571.2, 491.9, 571.2, 509.6)
    ..quadraticBezierTo(571.2, 527.3, 558.1, 537.7)
    ..quadraticBezierTo(545, 548, 520.6, 548)
    ..lineTo(468.7, 548)
    ..quadraticBezierTo(464.9, 548, 462.5, 545.5)
    ..quadraticBezierTo(460.1, 542.9, 460.1, 538.8)
    ..lineTo(460.1, 398)
    ..quadraticBezierTo(460.1, 395.5, 460.8, 394.8)
    ..quadraticBezierTo(461.6, 394, 464, 394)
    ..lineTo(514.2, 394)
    ..quadraticBezierTo(565.7, 394, 565.7, 433.8)
    ..close()
    ..moveTo(502.3, 429.6)
    ..lineTo(502.3, 458.5)
    ..lineTo(503.4, 458.5)
    ..quadraticBezierTo(524.5, 458.5, 524.5, 444.4)
    ..quadraticBezierTo(524.5, 436.7, 520.5, 433.2)
    ..quadraticBezierTo(516.4, 429.6, 506.9, 429.6)
    ..close()
    ..moveTo(502.3, 484.4)
    ..lineTo(502.3, 513)
    ..lineTo(506.3, 513)
    ..quadraticBezierTo(515.7, 513, 520.1, 509.5)
    ..quadraticBezierTo(524.5, 506, 524.5, 498.3)
    ..quadraticBezierTo(524.5, 490.6, 520.5, 487.5)
    ..quadraticBezierTo(516.4, 484.4, 506.9, 484.4)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    const tile = Rect.fromLTWH(0, 0, _tile, _tile);
    Paint stroke(double width) => Paint()
      ..color = _navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..save()
      ..scale(size.width / _tile, size.height / _tile)
      ..drawRRect(
        RRect.fromRectAndRadius(tile, const Radius.circular(_corner)),
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, -0.4),
            radius: 0.82,
            colors: [Color(0xFF6DB3FF), Color(0xFF2F6FDE)],
          ).createShader(tile),
      )
      // As the favicon: the crest 10% bigger, then nudged and tilted 7°.
      ..translate(512, 512)
      ..scale(1.1)
      ..translate(-512 - 16, -512 - 26)
      ..translate(512, 512)
      ..rotate(-7 * math.pi / 180)
      ..translate(-512, -512)
      // The hard shadow, then the shield, the bubble, and the B.
      ..save()
      ..translate(40, 40)
      ..drawPath(_shield, Paint()..color = _navy)
      ..drawPath(_shield, stroke(36))
      ..restore()
      ..drawPath(_shield, Paint()..color = _lemon)
      ..drawPath(_shield, stroke(36))
      ..drawPath(_bubble, Paint()..color = _white)
      ..drawPath(_bubble, stroke(26))
      ..drawPath(_b, Paint()..color = _navy)
      ..restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
