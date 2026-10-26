import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// The Plays icon (BOARD-1), after the Play Call app icon design: a coach's
/// play, with an O at the bottom left, its dotted route arcing up to an
/// arrowhead at the top right, and an X at the bottom right. No icon font
/// has one, so it's drawn, in the icon theme's color and size like any
/// [Icon]. [filled] is the selected look, as Material's filled icons are:
/// a little bolder. [colorful] is the big art on empty screens: the O in
/// lemon and the X in cherry, each on its hard lip, as in the app icon,
/// with the route in [color] (or the text color on the page).
class PlaysIcon extends StatelessWidget {
  const new({
    this.filled = false,
    this.colorful = false,
    this.size,
    this.color,
    super.key,
  });

  final bool filled;
  final bool colorful;

  /// Defaults to the icon theme's size, 24 unless set.
  final double? size;

  /// Defaults to the icon theme's color, or the text color on the page
  /// when [colorful].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    final g = colorful ? GumdropColors.of(context) : null;
    var paint =
        color ??
        (g != null ? g.textOnPage : theme.color) ??
        const Color(0xFF000000);
    // An icon theme's opacity applies on top of its color, as Icon does.
    final opacity = theme.opacity;
    if (opacity != null && opacity < 1) {
      paint = paint.withValues(alpha: paint.a * opacity);
    }
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: side,
        child: CustomPaint(
          painter: PlaysIconPainter(
            color: paint,
            filled: filled,
            candies: g == null
                ? null
                : (o: g.lemon, x: g.cherry, routeLip: g.you.lip),
          ),
        ),
      ),
    );
  }
}

/// Paints [PlaysIcon] in a 24-unit box scaled to its size, on the same
/// grid and stroke weight as the Material Symbols around it. The shapes are
/// the Play Call app icon's (on its 1024 canvas), scaled down, with the
/// route's dashes made into dots that read at tab size.
class PlaysIconPainter extends CustomPainter {
  const new({required this.color, required this.filled, this.candies});

  final Color color;
  final bool filled;

  /// The O's and the X's candy colors, and the route's lip, for the
  /// colorful look; null draws everything in [color].
  final ({GumdropAccent o, GumdropAccent x, Color routeLip})? candies;

  // The O, the X, the route, and the arrowhead, in 24 units.
  static const _o = Offset(7.36, 16.64);
  static const _oRadius = 3.0;
  static const _xFrom = Offset(14.9, 14.34);
  static const _xTo = Offset(19.6, 19.03);
  static const _routeStart = Offset(7.36, 11.72);
  static const _routeBend1 = Offset(7.36, 7.03);
  static const _routeBend2 = Offset(11.11, 5.86);
  static const _routeEnd = Offset(15.8, 5.86);
  static const _arrow = [
    Offset(16.27, 3.61),
    Offset(20.25, 5.86),
    Offset(16.27, 8.11),
  ];

  /// How far a lip sits under its shape in the colorful look, in units.
  static const _lip = 0.9;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..scale(size.width / 24, size.height / 24)
      // A tenth larger than the app icon's layout, so it fills the box as
      // the Material Symbols beside it do.
      ..translate(12, 12)
      ..scale(1.1)
      ..translate(-12, -12);
    // Drawn solid, then faded as one, as a font's glyph is: overlapping
    // strokes (the X's crossing) mustn't darken when the color is
    // see-through.
    const box = Rect.fromLTRB(0, 0, 24, 24);
    canvas.saveLayer(box, Paint()..color = Color.fromRGBO(0, 0, 0, color.a));
    final solid = color.withValues(alpha: 1);
    final weight = filled ? 2.5 : 2.1;
    Paint line(Color c, double width) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final route = Path()
      ..moveTo(_routeStart.dx, _routeStart.dy)
      ..cubicTo(
        _routeBend1.dx,
        _routeBend1.dy,
        _routeBend2.dx,
        _routeBend2.dy,
        _routeEnd.dx,
        _routeEnd.dy,
      );
    final arrow = Path()..addPolygon(_arrow, true);
    final x = Path()
      ..moveTo(_xFrom.dx, _xFrom.dy)
      ..lineTo(_xTo.dx, _xTo.dy)
      ..moveTo(_xTo.dx, _xFrom.dy)
      ..lineTo(_xFrom.dx, _xTo.dy);

    void drawPlay(Offset shift, {Color? o, Color? xs, Color? play}) {
      canvas
        ..save()
        ..translate(shift.dx, shift.dy);
      final routeColor = play ?? solid;
      // The route as dots, one every 3 units, clear of the O and ending
      // short of the arrowhead.
      for (final metric in route.computeMetrics()) {
        for (var d = 1.2; d <= metric.length - 0.8; d += 3) {
          final at = metric.getTangentForOffset(d)!.position;
          canvas.drawCircle(at, weight * 0.55, Paint()..color = routeColor);
        }
      }
      canvas
        ..drawPath(
          arrow,
          Paint()
            ..color = routeColor
            ..style = PaintingStyle.fill,
        )
        ..drawPath(arrow, line(routeColor, 0.8))
        ..drawCircle(_o, _oRadius, line(o ?? solid, weight))
        ..drawPath(x, line(xs ?? solid, weight))
        ..restore();
    }

    final c = candies;
    if (c == null) {
      drawPlay(Offset.zero);
    } else {
      // Each shape on its hard lip, then the faces, as in the app icon.
      drawPlay(
        const Offset(_lip, _lip),
        o: c.o.lip,
        xs: c.x.lip,
        play: c.routeLip,
      );
      drawPlay(Offset.zero, o: c.o.face, xs: c.x.face);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PlaysIconPainter old) =>
      old.color != color || old.filled != filled || old.candies != candies;
}
