import 'package:material_ui/material_ui.dart';

/// The pass tool's icon (#87): the run tool's arrow up and to the right
/// with its line broken into dashes, as the mockup draws it and as a pass
/// is drawn on the board. No icon font has one, so it's drawn, in the icon
/// theme's color and size like any [Icon].
class PassArrowIcon extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    var color = theme.color ?? const Color(0xFF000000);
    // An icon theme's opacity applies on top of its color, as Icon does.
    final opacity = theme.opacity;
    if (opacity != null && opacity < 1) {
      color = color.withValues(alpha: color.a * opacity);
    }
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: theme.size ?? 24,
        child: CustomPaint(
          painter: PassArrowPainter(color, weight: theme.weight ?? 400),
        ),
      ),
    );
  }
}

/// Draws [PassArrowIcon] on a 24 grid, the Material icons' own, with their
/// line for the icon theme's [weight] (2 units at their regular 400): the
/// run tool's corner of a head at the top right and three dashes running
/// to it from the bottom left.
class PassArrowPainter extends CustomPainter {
  const new(this.color, {this.weight = 400});

  final Color color;
  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 24;
    Offset at(double x, double y) => Offset(x, y) * unit;
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (2 + (weight - 400) / 400) * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // The head: a corner, as the run tool's arrow has.
    canvas.drawPath(
      Path()
        ..moveTo(at(9.5, 6).dx, at(9.5, 6).dy)
        ..lineTo(at(18, 6).dx, at(18, 6).dy)
        ..lineTo(at(18, 14.5).dx, at(18, 14.5).dy),
      pen,
    );
    // The line, as three dashes from the bottom left into the corner.
    final from = at(5.5, 18.5);
    final to = at(17, 7);
    for (final (a, b) in const [(0.0, 0.2), (0.4, 0.6), (0.8, 1.0)]) {
      canvas.drawLine(
        Offset.lerp(from, to, a)!,
        Offset.lerp(from, to, b)!,
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(PassArrowPainter old) =>
      old.color != color || old.weight != weight;
}
