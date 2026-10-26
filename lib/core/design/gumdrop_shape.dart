import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// The gumdrop: a rounded face sitting on a hard lip of a darker color, with
/// a thin light highlight along its top (Gumdrop Pop design §3.1). Used as
/// the shape of buttons, chips, the FAB, and the tab indicator, so Material
/// paints the face in the widget's own color and this paints the rest.
///
/// The lip is inside the shape's box: the face fills the box less [lip] at
/// the bottom, and the lip shows below it. [pressed] (0 to 1) moves the face
/// down onto the lip, as a pressed gumdrop sinks; Material animates it.
///
/// [radius] null makes a pill (or a circle, when the box is square).
/// [side] is the optional outline (Light and Candy's secondary buttons, and
/// the keyboard focus ring), drawn inside the face. [slant] leans the face
/// and its lip that many degrees, top to the right (Gumdrop Arena's 11),
/// inside the same box; the label stays upright.
@immutable
class GumdropShape extends OutlinedBorder {
  const new({
    this.lip = 4,
    this.lipColor = const Color(0x00000000),
    this.highlight = 2,
    this.highlightColor = const Color(0x59FFFFFF),
    this.radius,
    this.pressed = 0,
    this.slant = 0,
    super.side,
  });

  /// The lip's height: 3 for gumdrops up to 38 px, 4 above (design §3.1).
  final double lip;
  final Color lipColor;

  /// The top highlight's height: 2 on accent gumdrops, 1.5 on secondary.
  final double highlight;
  final Color highlightColor;

  /// The face's corner radius; null for a pill.
  final BorderRadius? radius;

  /// 0 at rest; 1 fully pressed (the face on the lip, no lip showing).
  final double pressed;

  /// How far the face leans, in degrees; 0 stands it upright.
  final double slant;

  /// The lip for a gumdrop whose face is [height] px tall (design §3.1).
  static double lipFor(double height) => height <= 38 ? 3 : 4;

  /// The horizontal shift per pixel of height of a leaning face.
  double get _shear => math.tan(slant * math.pi / 180);

  /// [rect] narrowed so a leaning face stays inside it.
  Rect _upright(Rect rect) {
    final inset = _shear.abs() * rect.height / 2;
    return inset == 0
        ? rect
        : Rect.fromLTRB(
            rect.left + inset,
            rect.top,
            rect.right - inset,
            rect.bottom,
          );
  }

  /// [path] leaning [slant] degrees about [rect]'s center.
  Path _lean(Path path, Rect rect) {
    final k = _shear;
    if (k == 0) return path;
    final c = rect.center;
    // x' = x - k (y - cy): the top moves right, the bottom left.
    final m = Matrix4.identity()
      ..setEntry(0, 1, -k)
      ..setEntry(0, 3, k * c.dy);
    return path.transform(m.storage);
  }

  Rect _face(Rect rect) {
    final r = _upright(rect);
    final drop = lip * pressed.clamp(0, 1);
    return Rect.fromLTRB(r.left, r.top + drop, r.right, r.bottom - lip + drop);
  }

  RRect _rrect(Rect face) {
    final r = radius;
    if (r != null) return r.toRRect(face);
    return RRect.fromRectAndRadius(
      face,
      Radius.circular(face.shortestSide / 2),
    );
  }

  /// The face moved down to the box's bottom: the lip, where the face
  /// doesn't cover it.
  RRect _lipRRect(Rect rect) {
    final r = _upright(rect);
    return _rrect(Rect.fromLTRB(r.left, r.top + lip, r.right, r.bottom));
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _lean(
    Path()..addRRect(_rrect(_face(rect)).deflate(side.strokeInset)),
    rect,
  );

  /// The face and the lip under it, which Material fills with the widget's
  /// color (the lip is painted over in [lipColor]).
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _lean(
    Path()
      ..addRRect(_rrect(_face(rect)))
      ..addRRect(_lipRRect(rect)),
    rect,
  );

  @override
  bool get preferPaintInterior => false;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    Path lean(RRect r) => _lean(Path()..addRRect(r), rect);
    final face = _rrect(_face(rect));
    final facePath = lean(face);
    if (lip * (1 - pressed) > 0.01 && lipColor.a > 0) {
      final lipPath = Path.combine(
        PathOperation.difference,
        lean(_lipRRect(rect)),
        facePath,
      );
      canvas.drawPath(lipPath, Paint()..color = lipColor);
    }
    final inner = face.deflate(side.style == BorderStyle.none ? 0 : side.width);
    if (highlight > 0 && highlightColor.a > 0 && inner.height > highlight) {
      final band = Path.combine(
        PathOperation.difference,
        lean(inner),
        lean(inner.shift(Offset(0, highlight))),
      );
      canvas.drawPath(band, Paint()..color = highlightColor);
    }
    if (side.style != BorderStyle.none && side.width > 0) {
      canvas.drawPath(lean(face.deflate(side.width / 2)), side.toPaint());
    }
  }

  @override
  GumdropShape copyWith({
    BorderSide? side,
    double? lip,
    Color? lipColor,
    double? highlight,
    Color? highlightColor,
    BorderRadius? radius,
    double? pressed,
    double? slant,
  }) => GumdropShape(
    side: side ?? this.side,
    lip: lip ?? this.lip,
    lipColor: lipColor ?? this.lipColor,
    highlight: highlight ?? this.highlight,
    highlightColor: highlightColor ?? this.highlightColor,
    radius: radius ?? this.radius,
    pressed: pressed ?? this.pressed,
    slant: slant ?? this.slant,
  );

  @override
  ShapeBorder scale(double t) => copyWith(
    side: side.scale(t),
    lip: lip * t,
    highlight: highlight * t,
    radius: radius == null ? null : radius! * t,
  );

  GumdropShape _lerp(GumdropShape other, double t) => GumdropShape(
    side: BorderSide.lerp(side, other.side, t),
    lip: ui.lerpDouble(lip, other.lip, t)!,
    lipColor: Color.lerp(lipColor, other.lipColor, t)!,
    highlight: ui.lerpDouble(highlight, other.highlight, t)!,
    highlightColor: Color.lerp(highlightColor, other.highlightColor, t)!,
    radius: radius == null && other.radius == null
        ? null
        : BorderRadius.lerp(radius, other.radius, t),
    pressed: ui.lerpDouble(pressed, other.pressed, t)!,
    slant: ui.lerpDouble(slant, other.slant, t)!,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is GumdropShape ? a._lerp(this, t) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is GumdropShape ? _lerp(b, t) : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is GumdropShape &&
      other.side == side &&
      other.lip == lip &&
      other.lipColor == lipColor &&
      other.highlight == highlight &&
      other.highlightColor == highlightColor &&
      other.radius == radius &&
      other.pressed == pressed &&
      other.slant == slant;

  @override
  int get hashCode => Object.hash(
    side,
    lip,
    lipColor,
    highlight,
    highlightColor,
    radius,
    pressed,
    slant,
  );

  @override
  String toString() =>
      'GumdropShape(lip: $lip, lipColor: $lipColor, pressed: $pressed, '
      'side: $side)';
}
