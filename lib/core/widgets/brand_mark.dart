// Made by tools/make_brand.py from the same shapes as website/logo.svg;
// change the mark there and run it again rather than editing this file.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The Battleplan mark (SPEC §7.1), the Sticker Pair: two candy dog tags on a
/// white ball chain, each a die-cut sticker with a white border in a navy
/// edge, the yellow one in front with the white stencil B and a coral one
/// swung out behind it, with two twinkles, on no tile: the page shows around
/// it, and the chain runs off the top. The same art as `website/logo.svg` and
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
      ..clipRRect(_rrect(0, 0, 1024, 1024, 0))
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

/// The app's name as the logo writes it (SPEC §7.1): "Battleplan" in Lilita
/// One's bubbly letters, white on a navy hard drop straight down, the look of
/// the Candy Pop scheme's header titles. [outlined] gives the letters a navy
/// edge as well, for a light page. Painted from the same outlines as
/// `website/wordmark.svg`; screen readers hear [label].
class BrandWordmark extends StatelessWidget {
  const new({
    required this.label,
    this.height = 44,
    this.outlined = false,
    super.key,
  });

  final String label;

  /// The box's height: the letters' cap height is two thirds of it.
  final double height;

  final bool outlined;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: CustomPaint(
      size: Size(height * _WordmarkPainter.aspect, height),
      painter: _WordmarkPainter(outlined: outlined),
    ),
  );
}

class _WordmarkPainter extends CustomPainter {
  const new({required this.outlined});

  final bool outlined;

  /// The box round the letters, their drop and their edge, in font units.
  static const _box = Rect.fromLTWH(16, -748, 4489, 1052);

  static double get aspect => _box.width / _box.height;

  static final Path _letters = _svgPath(
    'M541 -519Q541 -415 451 -361Q500 -343 533 -299Q566 -255 566 -174Q566 -94 506 -47Q447 0 336 0L100 0Q83 0 72 -12Q61 -23 61 -42L61 -682Q61 -693 64 -696Q68 -700 79 -700L307 -700Q541 -700 541 -519ZM253 -538L253 -407L258 -407Q354 -407 354 -471Q354 -506 336 -522Q317 -538 274 -538ZM253 -289L253 -159L271 -159Q314 -159 334 -175Q354 -191 354 -226Q354 -261 336 -275Q317 -289 274 -289ZM702 -363Q674 -413 674 -444Q674 -476 691 -485Q748 -510 848 -510Q947 -510 988 -464Q1029 -417 1029 -326L1029 -168L1063 -168Q1080 -168 1090 -148Q1099 -128 1099 -93Q1099 -58 1082 -24Q1064 10 1034 10Q980 10 947 -19Q932 -31 924 -48Q878 10 781 10Q708 10 658 -42Q608 -94 608 -165Q608 -328 803 -328L858 -328L858 -338Q858 -364 850 -372Q841 -379 810 -379Q772 -379 702 -363ZM782 -179Q782 -157 794 -146Q806 -134 824 -134Q843 -134 858 -149L858 -226L830 -226Q782 -226 782 -179ZM1386 -6Q1386 6 1302 6Q1202 2 1202 -7L1202 -361L1151 -361Q1131 -361 1131 -430Q1131 -448 1135 -474Q1138 -500 1149 -500L1202 -500L1202 -588Q1202 -608 1287 -608Q1371 -608 1371 -592L1371 -528L1372 -500L1457 -500Q1474 -500 1474 -430Q1474 -360 1457 -360L1386 -360ZM1754 -6Q1754 6 1670 6Q1570 2 1570 -7L1570 -361L1519 -361Q1499 -361 1499 -430Q1499 -448 1503 -474Q1506 -500 1517 -500L1570 -500L1570 -588Q1570 -608 1655 -608Q1739 -608 1739 -592L1739 -528L1740 -500L1825 -500Q1842 -500 1842 -430Q1842 -360 1825 -360L1754 -360ZM2074 -8Q2074 1 1972 1Q1892 0 1892 -7L1892 -688Q1892 -703 1989 -703Q2074 -700 2074 -693ZM2542 -27Q2479 10 2380 10Q2281 10 2213 -58Q2145 -125 2145 -244Q2145 -364 2211 -437Q2276 -510 2376 -510Q2476 -510 2531 -459Q2585 -408 2585 -335Q2585 -173 2399 -173L2330 -173Q2330 -143 2347 -132Q2363 -120 2395 -120Q2465 -120 2528 -152Q2529 -153 2537 -138Q2561 -95 2561 -66Q2561 -36 2542 -27ZM2417 -316Q2417 -358 2376 -358Q2357 -358 2343 -346Q2330 -335 2330 -313L2330 -282L2384 -282Q2417 -282 2417 -316ZM2865 182Q2865 189 2779 189Q2694 189 2694 182L2694 -333L2660 -333Q2636 -333 2627 -377Q2624 -391 2624 -413Q2624 -435 2638 -465Q2658 -509 2702 -509Q2731 -509 2755 -496Q2780 -482 2789 -470Q2799 -459 2799 -457Q2866 -509 2944 -509Q3022 -509 3078 -448Q3134 -388 3134 -262Q3134 -135 3078 -66Q3022 4 2936 4Q2897 4 2865 0ZM2906 -334Q2889 -334 2873 -323L2873 -146Q2890 -144 2901 -144Q2911 -144 2917 -144Q2958 -148 2958 -249Q2958 -334 2906 -334ZM3387 -8Q3387 1 3285 1Q3205 0 3205 -7L3205 -688Q3205 -703 3302 -703Q3387 -700 3387 -693ZM3540 -363Q3512 -413 3512 -444Q3512 -476 3529 -485Q3586 -510 3686 -510Q3785 -510 3826 -464Q3867 -417 3867 -326L3867 -168L3901 -168Q3918 -168 3928 -148Q3937 -128 3937 -93Q3937 -58 3920 -24Q3902 10 3872 10Q3818 10 3785 -19Q3770 -31 3762 -48Q3716 10 3619 10Q3546 10 3496 -42Q3446 -94 3446 -165Q3446 -328 3641 -328L3696 -328L3696 -338Q3696 -364 3688 -372Q3679 -379 3648 -379Q3610 -379 3540 -363ZM3620 -179Q3620 -157 3632 -146Q3644 -134 3662 -134Q3681 -134 3696 -149L3696 -226L3668 -226Q3620 -226 3620 -179ZM4203 -6Q4203 1 4131 1Q4031 -2 4031 -10L4031 -334L4005 -334Q3979 -334 3971 -378Q3969 -391 3969 -404Q3969 -435 3981 -466Q3999 -510 4037 -510Q4075 -510 4105 -492Q4135 -474 4145 -456Q4208 -510 4295 -510Q4382 -510 4421 -463Q4460 -416 4460 -309L4460 -9Q4460 3 4375 3Q4289 3 4289 -9L4289 -298Q4289 -348 4254 -348Q4244 -348 4226 -340Q4208 -331 4203 -327Z',
  );

  @override
  void paint(Canvas canvas, Size size) {
    final drop = _letters.shift(const Offset(0, 70));
    canvas
      ..save()
      ..scale(size.width / _box.width, size.height / _box.height)
      ..translate(-_box.left, -_box.top);
    if (outlined) {
      canvas
        ..drawPath(drop, _stroke(const Color(0xFF0B1640), 90))
        ..drawPath(_letters, _stroke(const Color(0xFF0B1640), 90));
    }
    canvas
      ..drawPath(drop, _fill(const Color(0xFF0B1640)))
      ..drawPath(_letters, _fill(const Color(0xFFFFFFFF)))
      ..restore();
  }

  @override
  bool shouldRepaint(_WordmarkPainter oldDelegate) =>
      oldDelegate.outlined != outlined;
}
