import 'package:material_ui/material_ui.dart';

/// Boot Camp Mix's round button (#87): a circle in its ink [side] on a
/// hard [shadow] down and to the right, as the mockup draws them. The
/// shadow is drawn only outside the circle, so it never covers the face,
/// and it stays put however the button's states change.
class CampRoundBorder extends CircleBorder {
  const new({
    required this.shadow,
    super.side,
    this.offset = const Offset(2, 2),
  });

  final Color shadow;
  final Offset offset;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final circle = Path()
      ..addOval(
        Rect.fromCircle(center: rect.center, radius: rect.shortestSide / 2),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, circle.shift(offset), circle),
      Paint()..color = shadow,
    );
    super.paint(canvas, rect, textDirection: textDirection);
  }

  @override
  CampRoundBorder copyWith({BorderSide? side, double? eccentricity}) =>
      CampRoundBorder(shadow: shadow, side: side ?? this.side, offset: offset);

  @override
  ShapeBorder scale(double t) =>
      CampRoundBorder(shadow: shadow, side: side.scale(t), offset: offset * t);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is CampRoundBorder
      ? CampRoundBorder(
          shadow: Color.lerp(a.shadow, shadow, t)!,
          side: BorderSide.lerp(a.side, side, t),
          offset: Offset.lerp(a.offset, offset, t)!,
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is CampRoundBorder
      ? CampRoundBorder(
          shadow: Color.lerp(shadow, b.shadow, t)!,
          side: BorderSide.lerp(side, b.side, t),
          offset: Offset.lerp(offset, b.offset, t)!,
        )
      : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is CampRoundBorder &&
      other.side == side &&
      other.shadow == shadow &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(side, shadow, offset);
}
