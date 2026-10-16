import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The Plays icon (BOARD-1): an X, an O, and the X's route to it on a
/// chalkboard on an easel. No icon font has one, so it's drawn, in the
/// icon theme's color and size like any [Icon]. [filled] is the selected
/// look, as Material's filled icons are: a solid board with the play cut
/// out of it, so the navigation's indicator shows through.
class PlaysIcon extends StatelessWidget {
  const new({this.filled = false, this.size, this.color, super.key});

  final bool filled;

  /// Defaults to the icon theme's size, 24 unless set.
  final double? size;

  /// Defaults to the icon theme's color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    var paint = color ?? theme.color ?? const Color(0xFF000000);
    // An icon theme's opacity applies on top of its color, as Icon does.
    final opacity = theme.opacity;
    if (opacity != null && opacity < 1) {
      paint = paint.withValues(alpha: paint.a * opacity);
    }
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: side,
        child: CustomPaint(
          painter: PlaysIconPainter(color: paint, filled: filled),
        ),
      ),
    );
  }
}

/// Paints [PlaysIcon] in a 24-unit box scaled to its size, on the same
/// grid and stroke weight as the Material Symbols around it.
class PlaysIconPainter extends CustomPainter {
  const new({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    // Drawn solid, then faded as one, as a font's glyph is: overlapping
    // strokes (the X's crossing, the legs at the board) mustn't darken
    // when the color is see-through.
    const box = Rect.fromLTRB(0, 0, 24, 24);
    canvas.saveLayer(box, Paint()..color = Color.fromRGBO(0, 0, 0, color.a));
    final solid = color.withValues(alpha: 1);
    final stroke = Paint()
      ..color = solid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The easel's legs, under the board.
    canvas
      ..drawLine(const Offset(7.5, 17), const Offset(5.5, 21.5), stroke)
      ..drawLine(const Offset(16.5, 17), const Offset(18.5, 21.5), stroke);

    final board = RRect.fromLTRBR(2, 2.5, 22, 17, const Radius.circular(2.5));
    // The play: an X, the O it's going after, and the X's route there.
    final mark = Paint()
      ..color = solid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // The route arcs from the X over to the O; its arrowhead points along
    // the curve's end and stops short of the O.
    const from = Offset(9.2, 9.6);
    const bend = Offset(12, 3.4);
    const to = Offset(15.4, 7.9);
    final route = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(bend.dx, bend.dy, to.dx, to.dy);
    final back = (bend - to) / (bend - to).distance * 2.4;
    Offset turn(Offset v, double radians) => Offset(
      v.dx * math.cos(radians) - v.dy * math.sin(radians),
      v.dx * math.sin(radians) + v.dy * math.cos(radians),
    );
    final head = Path()
      ..moveTo(to.dx + turn(back, 0.6).dx, to.dy + turn(back, 0.6).dy)
      ..lineTo(to.dx, to.dy)
      ..lineTo(to.dx + turn(back, -0.6).dx, to.dy + turn(back, -0.6).dy);

    if (filled) {
      // A solid board, with the play cut out so what's behind shows.
      // The cut-out clears the whole layer through, to what's behind.
      canvas.drawRRect(board.inflate(1), Paint()..color = solid);
      mark.blendMode = BlendMode.clear;
    } else {
      canvas.drawRRect(board, stroke);
    }
    canvas
      ..drawLine(const Offset(5.2, 10.9), const Offset(8.4, 14.1), mark)
      ..drawLine(const Offset(5.2, 14.1), const Offset(8.4, 10.9), mark)
      ..drawCircle(const Offset(17.2, 12.5), 1.9, mark)
      ..drawPath(route, mark)
      ..drawPath(head, mark)
      ..restore();
  }

  @override
  bool shouldRepaint(PlaysIconPainter old) =>
      old.color != color || old.filled != filled;
}
