import 'package:material_ui/material_ui.dart';

/// A speech bubble with softly rounded corners, outlined or filled to match
/// the other navigation icons.
class ChatIcon extends StatelessWidget {
  const new({this.filled = false, super.key});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    var color = theme.color ?? const Color(0xFF000000);
    final opacity = theme.opacity;
    if (opacity != null && opacity < 1) {
      color = color.withValues(alpha: color.a * opacity);
    }
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: theme.size ?? 24,
        child: CustomPaint(
          painter: _ChatIconPainter(color: color, filled: filled),
        ),
      ),
    );
  }
}

class _ChatIconPainter extends CustomPainter {
  const new({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final bubble = Path()
      ..moveTo(6, 3)
      ..lineTo(18, 3)
      ..quadraticBezierTo(21, 3, 21, 6)
      ..lineTo(21, 15)
      ..quadraticBezierTo(21, 18, 18, 18)
      ..lineTo(8, 18)
      ..lineTo(4, 21)
      ..quadraticBezierTo(3, 21.75, 3, 20.5)
      ..lineTo(3, 6)
      ..quadraticBezierTo(3, 3, 6, 3)
      ..close();
    canvas.drawPath(
      bubble,
      Paint()
        ..color = color
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChatIconPainter oldDelegate) =>
      color != oldDelegate.color || filled != oldDelegate.filled;
}
