// Made by tools/make_brand.py from the same shapes as website/logo.svg;
// change the mark there and run it again rather than editing this file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// The BattlePlan mark (SPEC §7.1), All Sports: the app's B as a tank, a
/// heavy leaning coral B on a track whose three wheels are a basketball, a
/// soccer ball and a baseball, its gun up and to the right, every part in a
/// thick ink edge on a hard ink shadow, on no tile: the page shows around it,
/// so the track is Army green here (it's black on the app icon's green tile),
/// to be seen on a black page. The same art as `website/logo.svg`, painted
/// from its shapes so it's sharp at any size and needs no image to load.
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

  static final Path _p0 = _svgPath(
    'M183.4 696L289 196L585.5 196Q645.3 196 683 227.1Q720.6 258.1 720.6 308.6Q720.6 324.1 717.5 337.3Q709.8 374.6 691.5 401Q673.3 427.4 648.4 442.9Q669.4 453.8 681.8 469.7Q694.2 485.6 694.2 512.8Q694.2 519.8 693.1 527.9Q691.9 536.1 690.4 544.6Q675.6 615.3 625.5 655.6Q575.4 696 483.1 696ZM424.8 387.8L494.7 387.8Q532 387.8 539 354.4Q539.7 351.3 539.7 346.6Q539.7 323.3 508.7 323.3L438.8 323.3ZM386 568.7L455.9 568.7Q493.1 568.7 500.1 535.3Q500.9 533 500.9 530.6Q500.9 528.3 500.9 526.7Q500.9 504.2 469.9 504.2L400 504.2Z',
  );

  static final Path _p1 = _svgPath(
    'M205.3 701.6Q236 676 276 676L752 676Q792 676 822.7 701.6L834 711Q876 746 848.8 799.5L841.7 813.6Q810 876 740 876L292 876Q222 876 188.8 814.4L180.4 798.8Q152 746 194 711Z',
  );

  static final Path _p2 = _svgPath('M90 -20L260 -20');

  static final Path _p3 = _svgPath(
    'M205.3 701.6L213.1 695.6L221.2 690.4L223.4 689.2M237.9 682.6L238.3 682.4L247.3 679.6L256.6 677.6L259.3 677.3M275.2 676L276 676L297.2 676M313.2 676L335.2 676M351.2 676L373.2 676M389.2 676L411.2 676M427.2 676L449.2 676M465.2 676L487.2 676M503.2 676L525.2 676M541.2 676L563.2 676M579.2 676L601.2 676M617.2 676L639.2 676M655.2 676L677.2 676M693.2 676L715.2 676M731.2 676L752 676L753.2 676M769.1 677.3L771.4 677.6L780.7 679.6L789.7 682.4L790.4 682.7M804.9 689.4L806.8 690.4L814.9 695.6L822.7 701.6L823 701.9M835.2 712.2L843.4 720L849.8 728.5M856.6 742.9L858.7 750.6L859.5 762L859.2 764.6M856.3 780.3L854.5 786.4L848.8 799.5L848.2 800.7M840.9 814.9L833.2 828.2L829.1 833.5M818.7 845.6L812.5 851.6L801.7 859.5M787.6 867L787.1 867.2L772.6 872.1L766.6 873.2M750.7 875.4L740 876L728.8 876M712.8 876L690.8 876M674.8 876L652.8 876M636.8 876L614.8 876M598.8 876L576.8 876M560.8 876L538.8 876M522.8 876L500.8 876M484.8 876L462.8 876M446.8 876L424.8 876M408.8 876L386.8 876M370.8 876L348.8 876M332.8 876L310.8 876M294.8 876L292 876L275.1 875L272.8 874.6M257.2 871.4L244.7 867.3L236.8 863.4M223.2 855L218.9 851.9L207.7 841.3L206.9 840.3M197 827.7L188.8 814.4L185.8 808.8M178.5 794.6L174.4 785.9L170.8 774M169.2 758.1L169.6 750.5L172.4 739.8L173.8 736.9M182.2 723.3L184.6 720L194 711L197.8 707.9',
  );

  static final Path _p4 = _svgPath(
    'M306 710L306 846M238 778L374 778M261.1 723.6Q292.4 778 261.1 832.4M350.9 723.6Q319.6 778 350.9 832.4',
  );

  static final Path _p5 = _svgPath(
    'M514 752.8L537.9 770.2L528.8 798.4L499.2 798.4L490.1 770.2ZM514 727.7L534.5 721.8L545.8 699.2L482.2 699.2L493.5 721.8ZM561.9 762.5L573.8 780.1L598.8 783.9L579.1 723.4L561.2 741.2ZM543.6 818.7L530.5 835.5L534.6 860.5L586.1 823L563.6 811.5ZM484.4 818.7L464.4 811.5L441.9 823L493.4 860.5L497.5 835.5ZM466.1 762.5L466.8 741.2L448.9 723.4L429.2 783.9L454.2 780.1Z',
  );

  static final Path _p6 = _svgPath(
    'M514 752.8L514 727.7M534.5 721.8L561.2 741.2M537.9 770.2L561.9 762.5M573.8 780.1L563.6 811.5M528.8 798.4L543.6 818.7M530.5 835.5L497.5 835.5M499.2 798.4L484.4 818.7M464.4 811.5L454.2 780.1M490.1 770.2L466.1 762.5M466.8 741.2L493.5 721.8',
  );

  static final Path _p7 = _svgPath(
    'M775.6 819.9L773.7 818.4L771.8 816.8L770.1 815.1L768.4 813.4L766.8 811.5L765.3 809.6L763.9 807.7L762.5 805.6L761.3 803.6L760.2 801.4L759.1 799.2L758.2 797L757.4 794.7L756.7 792.4L756 790L755.5 787.7L755.1 785.3L754.9 782.8L754.7 780.4L754.6 778L754.7 775.6L754.9 773.2L755.1 770.7L755.5 768.3L756 766L756.7 763.6L757.4 761.3L758.2 759L759.1 756.8L760.2 754.6L761.3 752.4L762.5 750.4L763.9 748.3L765.3 746.4L766.8 744.5L768.4 742.6L770.1 740.9L771.8 739.2L773.7 737.6L775.6 736.1M668.4 819.9L670.3 818.4L672.2 816.8L673.9 815.1L675.6 813.4L677.2 811.5L678.7 809.6L680.1 807.7L681.5 805.6L682.7 803.6L683.8 801.4L684.9 799.2L685.8 797L686.6 794.7L687.3 792.4L688 790L688.5 787.7L688.9 785.3L689.1 782.8L689.3 780.4L689.4 778L689.3 775.6L689.1 773.2L688.9 770.7L688.5 768.3L688 766L687.3 763.6L686.6 761.3L685.8 759L684.9 756.8L683.8 754.6L682.7 752.4L681.5 750.4L680.1 748.3L678.7 746.4L677.2 744.5L675.6 742.6L673.9 740.9L672.2 739.2L670.3 737.6L668.4 736.1',
  );

  static final Path _p8 = _svgPath(
    'M767.6 815.5L765.9 826.9M770.5 812.7L782 811.5M759.4 804.4L754.9 815M763 802.4L774.4 804.2M754.3 791.6L747.3 800.8M758.3 790.6L768.9 795.2M752.6 778L743.5 785.1M756.7 778L765.8 785.1M754.3 764.4L743.7 769M758.3 765.4L765.3 774.6M759.4 751.6L748 753.4M763 753.6L767.5 764.2M767.6 740.5L756.1 739.4M770.5 743.3L772.2 754.8M676.4 815.5L678.1 826.9M673.5 812.7L662 811.5M684.6 804.4L689.1 815M681 802.4L669.6 804.2M689.7 791.6L696.7 800.8M685.7 790.6L675.1 795.2M691.4 778L700.5 785.1M687.3 778L678.2 785.1M689.7 764.4L700.3 769M685.7 765.4L678.7 774.6M684.6 751.6L696 753.4M681 753.6L676.5 764.2M676.4 740.5L687.9 739.4M673.5 743.3L671.8 754.8',
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / _tile, size.height / _tile)
      ..save()
      ..translate(-64.5, -37)
      ..scaleAbout(1.1692, 576.5, 549)
      ..save()
      ..translate(22, 26)
      ..drawPath(_p0, _fill(const Color(0xFF0B0B0A)))
      ..drawPath(_p0, _stroke(const Color(0xFF0B0B0A), 52))
      ..drawPath(_p1, _fill(const Color(0xFF0B0B0A)))
      ..drawPath(_p1, _stroke(const Color(0xFF0B0B0A), 52))
      ..save()
      ..translate(604, 352)
      ..rotateAbout(-13, 0, 0)
      ..drawRRect(_rrect(0, -34, 300, 68, 8), _fill(const Color(0xFF0B0B0A)))
      ..drawRRect(
        _rrect(0, -34, 300, 68, 8),
        _stroke(const Color(0xFF0B0B0A), 52),
      )
      ..drawRRect(_rrect(276, -50, 84, 100, 16), _fill(const Color(0xFF0B0B0A)))
      ..drawRRect(
        _rrect(276, -50, 84, 100, 16),
        _stroke(const Color(0xFF0B0B0A), 52),
      )
      ..restore()
      ..restore()
      ..save()
      ..translate(604, 352)
      ..rotateAbout(-13, 0, 0)
      ..drawRRect(_rrect(0, -34, 300, 68, 8), _fill(const Color(0xFF0B0B0A)))
      ..drawRRect(
        _rrect(0, -34, 300, 68, 8),
        _stroke(const Color(0xFF0B0B0A), 52),
      )
      ..drawRRect(
        _rrect(0, -34, 300, 68, 8),
        _blend(
          const Offset(0, -34),
          const Offset(0, 34),
          const Color(0xFFFF9480),
          const Color(0xFFE9573F),
        ),
      )
      ..drawPath(_p2, _stroke(const Color(0x80FFFFFF), 9))
      ..drawRRect(_rrect(276, -50, 84, 100, 16), _fill(const Color(0xFF0B0B0A)))
      ..drawRRect(
        _rrect(276, -50, 84, 100, 16),
        _stroke(const Color(0xFF0B0B0A), 52),
      )
      ..drawRRect(_rrect(276, -50, 84, 100, 16), _fill(const Color(0xFFF2644C)))
      ..restore()
      ..drawPath(_p0, _fill(const Color(0xFF0B0B0A)))
      ..drawPath(_p0, _stroke(const Color(0xFF0B0B0A), 52))
      ..drawPath(
        _p0,
        _blend(
          const Offset(0, 196),
          const Offset(0, 696),
          const Color(0xFFFF9480),
          const Color(0xFFF2644C),
        ),
      )
      ..drawPath(_p1, _fill(const Color(0xFF0B0B0A)))
      ..drawPath(_p1, _stroke(const Color(0xFF0B0B0A), 52))
      ..drawPath(_p1, _fill(const Color(0xFF4A5327)))
      ..save()
      ..clipPath(_p1)
      ..drawPath(_p3, _stroke(const Color(0xFF2F3619), 34))
      ..restore()
      ..drawCircle(const Offset(306, 778), 68, _fill(const Color(0xFF0B0B0A)))
      ..drawCircle(
        const Offset(306, 778),
        68,
        _stroke(const Color(0xFF0B0B0A), 12),
      )
      ..save()
      ..clipRRect(_rrect(238, 710, 136, 136, 68))
      ..drawCircle(const Offset(306, 778), 68, _fill(const Color(0xFFEDAE00)))
      ..drawCircle(
        const Offset(299.9, 771.2),
        68,
        _fill(const Color(0xFFFFDD55)),
      )
      ..save()
      ..rotateAbout(-24, 306, 778)
      ..drawPath(_p4, _stroke(const Color(0xFF2A1606), 7))
      ..restore()
      ..restore()
      ..drawCircle(const Offset(514, 778), 68, _fill(const Color(0xFF0B0B0A)))
      ..drawCircle(
        const Offset(514, 778),
        68,
        _stroke(const Color(0xFF0B0B0A), 12),
      )
      ..save()
      ..clipRRect(_rrect(446, 710, 136, 136, 68))
      ..drawCircle(const Offset(514, 778), 68, _fill(const Color(0xFFD9DCE0)))
      ..drawCircle(
        const Offset(507.9, 771.2),
        68,
        _fill(const Color(0xFFFFFFFF)),
      )
      ..save()
      ..rotateAbout(14, 514, 778)
      ..drawPath(_p5, _fill(const Color(0xFF17181B)))
      ..drawPath(_p6, _stroke(const Color(0xFF17181B), 6))
      ..restore()
      ..restore()
      ..drawCircle(const Offset(722, 778), 68, _fill(const Color(0xFF0B0B0A)))
      ..drawCircle(
        const Offset(722, 778),
        68,
        _stroke(const Color(0xFF0B0B0A), 12),
      )
      ..save()
      ..clipRRect(_rrect(654, 710, 136, 136, 68))
      ..drawCircle(const Offset(722, 778), 68, _fill(const Color(0xFFE6DAC0)))
      ..drawCircle(
        const Offset(715.9, 771.2),
        68,
        _fill(const Color(0xFFFFF8EA)),
      )
      ..save()
      ..rotateAbout(64, 722, 778)
      ..drawPath(_p7, _stroke(const Color(0xFFD92B2B), 7))
      ..drawPath(_p8, _stroke(const Color(0xFFD92B2B), 9))
      ..restore()
      ..restore()
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

/// A fill that runs from one color at [from] into another at [to], as the
/// SVGs' linear gradients do: the B from its top to its foot, the barrel
/// across it.
Paint _blend(Offset from, Offset to, Color first, Color last) =>
    Paint()..shader = ui.Gradient.linear(from, to, [first, last]);

/// An outline centred on the shape's edge, with round joins and round ends
/// like the SVGs'.
Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

/// The SVGs' transforms, so the painter is one cascade.
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

/// The app's name as the logo writes it (SPEC §7.1): "BattlePlan" in Lilita
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
  static const _box = Rect.fromLTWH(16, -748, 4504, 1052);

  static double get aspect => _box.width / _box.height;

  static final Path _letters = _svgPath(
    'M541 -519Q541 -415 451 -361Q500 -343 533 -299Q566 -255 566 -174Q566 -94 506 -47Q447 0 336 0L100 0Q83 0 72 -12Q61 -23 61 -42L61 -682Q61 -693 64 -696Q68 -700 79 -700L307 -700Q541 -700 541 -519ZM253 -538L253 -407L258 -407Q354 -407 354 -471Q354 -506 336 -522Q317 -538 274 -538ZM253 -289L253 -159L271 -159Q314 -159 334 -175Q354 -191 354 -226Q354 -261 336 -275Q317 -289 274 -289ZM702 -363Q674 -413 674 -444Q674 -476 691 -485Q748 -510 848 -510Q947 -510 988 -464Q1029 -417 1029 -326L1029 -168L1063 -168Q1080 -168 1090 -148Q1099 -128 1099 -93Q1099 -58 1082 -24Q1064 10 1034 10Q980 10 947 -19Q932 -31 924 -48Q878 10 781 10Q708 10 658 -42Q608 -94 608 -165Q608 -328 803 -328L858 -328L858 -338Q858 -364 850 -372Q841 -379 810 -379Q772 -379 702 -363ZM782 -179Q782 -157 794 -146Q806 -134 824 -134Q843 -134 858 -149L858 -226L830 -226Q782 -226 782 -179ZM1386 -6Q1386 6 1302 6Q1202 2 1202 -7L1202 -361L1151 -361Q1131 -361 1131 -430Q1131 -448 1135 -474Q1138 -500 1149 -500L1202 -500L1202 -588Q1202 -608 1287 -608Q1371 -608 1371 -592L1371 -528L1372 -500L1457 -500Q1474 -500 1474 -430Q1474 -360 1457 -360L1386 -360ZM1754 -6Q1754 6 1670 6Q1570 2 1570 -7L1570 -361L1519 -361Q1499 -361 1499 -430Q1499 -448 1503 -474Q1506 -500 1517 -500L1570 -500L1570 -588Q1570 -608 1655 -608Q1739 -608 1739 -592L1739 -528L1740 -500L1825 -500Q1842 -500 1842 -430Q1842 -360 1825 -360L1754 -360ZM2074 -8Q2074 1 1972 1Q1892 0 1892 -7L1892 -688Q1892 -703 1989 -703Q2074 -700 2074 -693ZM2542 -27Q2479 10 2380 10Q2281 10 2213 -58Q2145 -125 2145 -244Q2145 -364 2211 -437Q2276 -510 2376 -510Q2476 -510 2531 -459Q2585 -408 2585 -335Q2585 -173 2399 -173L2330 -173Q2330 -143 2347 -132Q2363 -120 2395 -120Q2465 -120 2528 -152Q2529 -153 2537 -138Q2561 -95 2561 -66Q2561 -36 2542 -27ZM2417 -316Q2417 -358 2376 -358Q2357 -358 2343 -346Q2330 -335 2330 -313L2330 -282L2384 -282Q2417 -282 2417 -316ZM2742 2Q2651 2 2651 -18L2651 -666Q2651 -700 2682 -700L2858 -700Q3006 -700 3071 -639Q3137 -578 3137 -462Q3137 -366 3075 -286Q3044 -246 2984 -222Q2924 -198 2844 -198L2844 -19Q2844 -7 2807 -2Q2769 2 2742 2ZM2844 -526L2844 -368L2857 -368Q2892 -368 2916 -390Q2940 -412 2940 -452Q2940 -492 2923 -509Q2907 -526 2865 -526ZM3402 -8Q3402 1 3300 1Q3220 0 3220 -7L3220 -688Q3220 -703 3317 -703Q3402 -700 3402 -693ZM3555 -363Q3527 -413 3527 -444Q3527 -476 3544 -485Q3601 -510 3701 -510Q3800 -510 3841 -464Q3882 -417 3882 -326L3882 -168L3916 -168Q3933 -168 3943 -148Q3952 -128 3952 -93Q3952 -58 3935 -24Q3917 10 3887 10Q3833 10 3800 -19Q3785 -31 3777 -48Q3731 10 3634 10Q3561 10 3511 -42Q3461 -94 3461 -165Q3461 -328 3656 -328L3711 -328L3711 -338Q3711 -364 3703 -372Q3694 -379 3663 -379Q3625 -379 3555 -363ZM3635 -179Q3635 -157 3647 -146Q3659 -134 3677 -134Q3696 -134 3711 -149L3711 -226L3683 -226Q3635 -226 3635 -179ZM4218 -6Q4218 1 4146 1Q4046 -2 4046 -10L4046 -334L4020 -334Q3994 -334 3986 -378Q3984 -391 3984 -404Q3984 -435 3996 -466Q4014 -510 4052 -510Q4090 -510 4120 -492Q4150 -474 4160 -456Q4223 -510 4310 -510Q4397 -510 4436 -463Q4475 -416 4475 -309L4475 -9Q4475 3 4390 3Q4304 3 4304 -9L4304 -298Q4304 -348 4269 -348Q4259 -348 4241 -340Q4223 -331 4218 -327Z',
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
