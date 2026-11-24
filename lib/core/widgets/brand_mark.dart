// Made by tools/make_brand.py from the same shapes as website/favicon.svg;
// change the mark there and run it again rather than editing this file.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The Battleplan mark (SPEC §7.1), the Sticker Pair: two candy dog tags on a
/// white ball chain, each a die-cut sticker with a white border in a navy
/// edge, the yellow one in front with the white stencil B and a coral one
/// swung out behind it, with two twinkles, on Candy Pop's royal blue tile
/// under a dot grid. The same art as `website/favicon.svg` and
/// `assets/brand/*.svg`, painted from their shapes so it's sharp at any size
/// and needs no image to load. Decorative: screen readers skip it, as the
/// app's name is always written next to it.
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

  static final Path _p0 = _svgPath(
    'M453.2 685.0L453.2 395.0L507.6 395.0L507.6 685.0ZM525.7 685.0L525.7 637.1L527.5 637.1Q539.0 637.1 545.0 631.1Q551.1 625.0 551.1 613.6Q551.1 608.7 551.1 604.0Q551.1 599.3 551.1 594.4Q551.1 576.4 545.6 568.9Q540.1 561.4 527.5 561.4L525.7 561.4L525.7 513.5L527.5 513.5Q539.0 513.5 545.0 505.7Q551.1 497.8 551.1 483.5Q551.1 478.2 551.1 473.0Q551.1 467.9 551.1 462.8Q551.1 453.2 545.0 448.0Q539.0 442.9 527.5 442.9L525.7 442.9L525.7 395.0L527.5 395.0Q568.1 395.0 586.8 411.4Q605.5 427.8 605.5 465.7Q605.5 470.8 605.5 475.5Q605.5 480.2 605.1 484.9Q604.0 504.7 596.3 516.3Q588.6 528.0 572.5 533.5L572.5 542.2Q589.2 547.6 597.0 559.5Q604.8 571.4 605.5 591.8Q605.8 597.8 605.8 602.9Q605.8 608.0 605.5 614.3Q603.9 652.0 586.0 668.5Q568.1 685.0 527.5 685.0Z',
  );

  static final Path _p1 = _svgPath(
    'M878 370Q897.6 420.4 948 440Q897.6 459.6 878 510Q858.4 459.6 808 440Q858.4 420.4 878 370Z',
  );

  static final Path _p2 = _svgPath(
    'M168 814Q180.88 847.12 214 860Q180.88 872.88 168 906Q155.12 872.88 122 860Q155.12 847.12 168 814Z',
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / _tile, size.height / _tile)
      ..clipRRect(_rrect(0, 0, 1024, 1024, 224))
      ..drawRRect(_rrect(0, 0, 1024, 1024, 224), _fill(const Color(0xFF1748D4)))
      ..dots(64, 8, const Color(0x24FFFFFF))
      ..save()
      ..scaleAbout(1, 512, 512)
      ..translate(28, 50)
      ..beads(
        const [
          Offset(12, -100),
          Offset(39.9, -59.2),
          Offset(67.4, -20.9),
          Offset(94.7, 15),
          Offset(121.6, 48.4),
          Offset(148.2, 79.4),
          Offset(174.6, 107.9),
          Offset(200.6, 134),
          Offset(226.4, 157.6),
          Offset(251.9, 178.8),
          Offset(277, 197.5),
          Offset(301.9, 213.8),
          Offset(326.4, 227.6),
          Offset(350.6, 239),
          Offset(374.6, 247.9),
          Offset(398.2, 254.4),
          Offset(421.6, 258.4),
          Offset(444.6, 260),
          Offset(467.4, 259.1),
          Offset(489.9, 255.8),
          Offset(512, 250),
          Offset(956, -100),
          Offset(928.5, -54.8),
          Offset(901.4, -12.7),
          Offset(874.6, 26.4),
          Offset(848.1, 62.5),
          Offset(822, 95.5),
          Offset(796.2, 125.6),
          Offset(770.7, 152.6),
          Offset(745.5, 176.5),
          Offset(720.7, 197.5),
          Offset(696.2, 215.4),
          Offset(672, 230.3),
          Offset(648.2, 242.2),
          Offset(624.6, 251.1),
          Offset(601.5, 256.9),
          Offset(578.6, 259.7),
          Offset(556.1, 259.5),
          Offset(533.9, 256.3),
          Offset(512, 250),
        ],
        16,
        8,
      )
      ..save()
      ..translate(20, 24)
      ..rotateAbout(30, 512, 250)
      ..drawRRect(
        _rrect(337, 212, 350, 530, 114),
        _stroke(const Color(0xFF0B1640), 88),
      )
      ..drawRRect(
        _rrect(337, 212, 350, 530, 114),
        _fill(const Color(0xFF0B1640)),
      )
      ..restore()
      ..save()
      ..rotateAbout(30, 512, 250)
      ..drawRRect(
        _rrect(337, 212, 350, 530, 114),
        _stroke(const Color(0xFF0B1640), 88),
      )
      ..drawRRect(
        _rrect(337, 212, 350, 530, 114),
        _fill(const Color(0xFFFFFFFF)),
      )
      ..drawRRect(
        _rrect(337, 212, 350, 530, 114),
        _stroke(const Color(0xFFFFFFFF), 48),
      )
      ..drawRRect(
        _rrect(337, 212, 350, 530, 114),
        _fill(const Color(0xFFFFFFFF)),
      )
      ..drawRRect(
        _rrect(337, 212, 350, 530, 114),
        _stroke(const Color(0xFFD9533B), 9),
      )
      ..drawRRect(
        _rrect(337, 212, 350, 530, 114),
        _fill(const Color(0xFFFF7F66)),
      )
      ..drawCircle(const Offset(512, 250), 24, _fill(const Color(0xFF0B1640)))
      ..drawRRect(_rrect(376, 310, 40, 120, 20), _fill(const Color(0xBFFFFFFF)))
      ..drawCircle(const Offset(396, 476), 20, _fill(const Color(0xBFFFFFFF)))
      ..restore()
      ..save()
      ..translate(24, 28)
      ..rotateAbout(-10, 512, 250)
      ..drawRRect(
        _rrect(317, 212, 390, 580, 128),
        _stroke(const Color(0xFF0B1640), 96),
      )
      ..drawRRect(
        _rrect(317, 212, 390, 580, 128),
        _fill(const Color(0xFF0B1640)),
      )
      ..restore()
      ..save()
      ..rotateAbout(-10, 512, 250)
      ..drawRRect(
        _rrect(317, 212, 390, 580, 128),
        _stroke(const Color(0xFF0B1640), 96),
      )
      ..drawRRect(
        _rrect(317, 212, 390, 580, 128),
        _fill(const Color(0xFFFFFFFF)),
      )
      ..drawRRect(
        _rrect(317, 212, 390, 580, 128),
        _stroke(const Color(0xFFFFFFFF), 54),
      )
      ..drawRRect(
        _rrect(317, 212, 390, 580, 128),
        _fill(const Color(0xFFFFFFFF)),
      )
      ..drawRRect(
        _rrect(317, 212, 390, 580, 128),
        _stroke(const Color(0xFFE0A800), 9),
      )
      ..drawRRect(
        _rrect(317, 212, 390, 580, 128),
        _fill(const Color(0xFFFFD43A)),
      )
      ..drawCircle(const Offset(512, 250), 28, _fill(const Color(0xFF0B1640)))
      ..drawRRect(_rrect(355, 330, 40, 130, 20), _fill(const Color(0xBFFFFFFF)))
      ..drawCircle(const Offset(375, 506), 20, _fill(const Color(0xBFFFFFFF)))
      ..save()
      ..translate(13, 13)
      ..drawPath(_p0, _stroke(const Color(0xFF0B1640), 38))
      ..drawPath(_p0, _fill(const Color(0xFF0B1640)))
      ..restore()
      ..drawPath(_p0, _stroke(const Color(0xFF0B1640), 38))
      ..drawPath(_p0, _fill(const Color(0xFF0B1640)))
      ..drawPath(_p0, _fill(const Color(0xFFFFFFFF)))
      ..restore()
      ..drawCircle(
        const Offset(512, 250),
        18,
        _stroke(const Color(0xFF0B1640), 8),
      )
      ..drawCircle(const Offset(512, 250), 18, _fill(const Color(0xFFFFFFFF)))
      ..restore()
      ..save()
      ..scaleAbout(1, 512, 512)
      ..drawPath(_p1, _stroke(const Color(0xFF0B1640), 14))
      ..drawPath(_p1, _fill(const Color(0xFFFFFFFF)))
      ..drawPath(_p2, _stroke(const Color(0xFF0B1640), 12))
      ..drawPath(_p2, _fill(const Color(0xFFFFD43A)))
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}

/// A rounded rectangle from the SVG's x, y, width, height and corner radius.
RRect _rrect(double x, double y, double w, double h, double r) =>
    RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r));

Paint _fill(Color color) => Paint()..color = color;

/// An outline centred on the shape's edge, with round joins like the SVGs'.
Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeJoin = StrokeJoin.round;

/// The SVGs' transforms and repeated parts, so the painter is one cascade.
extension on Canvas {
  /// SVG's rotate(degrees cx cy).
  void rotateAbout(double degrees, double cx, double cy) => this
    ..translate(cx, cy)
    ..rotate(degrees * math.pi / 180)
    ..translate(-cx, -cy);

  /// Scales by k about (cx, cy).
  void scaleAbout(double k, double cx, double cy) => this
    ..translate(cx, cy)
    ..scale(k)
    ..translate(-cx, -cy);

  /// The tile's dot grid: a dot in the middle of every step-sized cell.
  void dots(double step, double r, Color color) {
    final paint = _fill(color);
    for (var y = step / 2; y < _MarkPainter._tile; y += step) {
      for (var x = step / 2; x < _MarkPainter._tile; x += step) {
        drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  /// The ball chain: white beads in a navy edge.
  void beads(List<Offset> centres, double r, double edge) {
    final fill = _fill(const Color(0xFFFFFFFF));
    final stroke = _stroke(const Color(0xFF0B1640), edge);
    for (final c in centres) {
      this
        ..drawCircle(c, r, fill)
        ..drawCircle(c, r, stroke);
    }
  }
}

/// A path from SVG path data with absolute M, L, Q and Z commands only, which
/// is all the mark uses.
Path _svgPath(String d) {
  final path = Path();
  final tokens = RegExp('[MLQZ]|-?[0-9.]+').allMatches(d).map((m) => m[0]!);
  final it = tokens.iterator;
  double next() {
    it.moveNext();
    return double.parse(it.current);
  }

  while (it.moveNext()) {
    switch (it.current) {
      case 'M':
        path.moveTo(next(), next());
      case 'L':
        path.lineTo(next(), next());
      case 'Q':
        path.quadraticBezierTo(next(), next(), next(), next());
      case 'Z':
        path.close();
    }
  }
  return path;
}
