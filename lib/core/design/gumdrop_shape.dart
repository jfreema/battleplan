import 'dart:ui' as ui show lerpDouble;

import 'package:battleplan/core/design/candy.dart';
import 'package:material_ui/material_ui.dart';

/// The gumdrop: a rounded face sitting on a lip of a darker shade of its
/// own color (Gumdrop Pop design §3.1). Used as the shape of buttons, the
/// FAB, and other candy pieces, so Material paints the face in the widget's
/// own color and this paints the rest.
///
/// The candy finish (#98, SPEC §7.4): the lip is straight down, a band of
/// [lipColor] with the ink ([lipEdge]) carried round under it, as the
/// face's outline ([side]) is round the face; a thin white [highlight] runs
/// along the top of the face, inside the outline, and a [shine] sits near
/// its top left (a round button's is a tilted oval, [ball]). Painted the
/// way [CandyFinish] paints every other candy piece.
///
/// The lip is inside the shape's box: the face fills the box less [lip] at
/// the bottom, and the lip shows under it. [pressed] (0 to 1) sinks the
/// face [sink] px onto its lip, whose ink stays where it was; Material
/// animates it.
///
/// [radius] null makes a pill (or a circle, when the face is square).
/// [side] is the face's outline (ink, or the keyboard focus ring).
@immutable
class GumdropShape extends OutlinedBorder {
  const new({
    this.lip = 7,
    this.lipColor = const Color(0x00000000),
    this.lipEdge = const Color(0x00000000),
    this.highlight = 0,
    this.highlightColor = const Color(0x73FFFFFF),
    this.shine,
    this.shineColor = const Color(0xBFFFFFFF),
    this.ball = false,
    this.radius,
    this.pressed = 0,
    this.sink = 3,
    super.side,
  });

  /// How far the lip, with its ink, reaches below the face at rest: 7
  /// under a push button, 4 under a round one ([depthFor]).
  final double lip;

  /// The lip band's color: a darker shade of the face ([Candy.lipOf]).
  final Color lipColor;

  /// The ink carried round under the lip; transparent for none.
  final Color lipEdge;

  /// The top highlight's height: 2.5 on candy faces (#98), 0 for none.
  final double highlight;
  final Color highlightColor;

  /// The shine, from the face's top left inside its outline, or null for
  /// none.
  final Rect? shine;
  final Color shineColor;

  /// Whether the shine is a round button's tilted oval.
  final bool ball;

  /// The face's corner radius; null for a pill.
  final BorderRadius? radius;

  /// 0 at rest; 1 fully pressed (the face sunk [sink] px onto its lip).
  final double pressed;

  /// How far the face sinks when pressed: 3 on a push button, so its lip
  /// goes from 7 to 4 (#98).
  final double sink;

  /// The lip under a push button [height] px tall, lip included (#98): 6
  /// under the small ones (up to 43, the answer row's size), 7 under the
  /// usual 48, 8 under the event page's big ones.
  static double depthFor(double height) => height < 44
      ? 6
      : height <= 52
      ? 7
      : 8;

  /// How far a face with a lip [depth] deep sinks when pressed: onto a lip
  /// 4 deep (3 under the usual push button, 4 under the big ones), or half
  /// way on the shallow lips of small pieces.
  static double sinkFor(double depth) => depth >= 7 ? depth - 4 : depth / 2;

  /// The lip under a round button: 4 (#98).
  static const double roundDepth = 4;

  double get _down =>
      sink.clamp(0, lip).toDouble() * pressed.clamp(0, 1).toDouble();

  Rect _face(Rect rect) => Rect.fromLTRB(
    rect.left,
    rect.top + _down,
    rect.right,
    rect.bottom - lip + _down,
  );

  RRect _rrect(Rect face) {
    final r = radius;
    if (r != null) return r.toRRect(face);
    return RRect.fromRectAndRadius(
      face,
      Radius.circular(face.shortestSide / 2),
    );
  }

  /// Where the ink under the lip reaches: the face at rest, moved down to
  /// the box's bottom.
  RRect _under(Rect rect) =>
      _rrect(Rect.fromLTRB(rect.left, rect.top + lip, rect.right, rect.bottom));

  double get _outline => side.style == BorderStyle.none ? 0 : side.width;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(_face(rect)).deflate(side.strokeInset));

  /// The face and the lip under it, which Material fills with the widget's
  /// color (the lip and its ink are painted over it).
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(_rrect(_face(rect)))
    ..addRRect(_under(rect));

  @override
  bool get preferPaintInterior => false;

  /// How this gumdrop is finished, for [CandyFinish] to paint.
  CandyFinish _finish() => CandyFinish(
    lip: lipColor,
    ink: lipEdge,
    depth: lip - _down,
    outline: _outline,
    highlight: highlight > 0 ? highlightColor : null,
    highlightHeight: highlight,
    shine: shine,
    shineColor: shineColor,
    ball: ball,
  );

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final face = _rrect(_face(rect));
    _finish()
      ..paintUnder(canvas, face)
      ..paintOver(canvas, face, outlineColor: side.color);
  }

  @override
  GumdropShape copyWith({
    BorderSide? side,
    double? lip,
    Color? lipColor,
    Color? lipEdge,
    double? highlight,
    Color? highlightColor,
    Rect? shine,
    Color? shineColor,
    bool? ball,
    BorderRadius? radius,
    double? pressed,
    double? sink,
  }) => GumdropShape(
    side: side ?? this.side,
    lip: lip ?? this.lip,
    lipColor: lipColor ?? this.lipColor,
    lipEdge: lipEdge ?? this.lipEdge,
    highlight: highlight ?? this.highlight,
    highlightColor: highlightColor ?? this.highlightColor,
    shine: shine ?? this.shine,
    shineColor: shineColor ?? this.shineColor,
    ball: ball ?? this.ball,
    radius: radius ?? this.radius,
    pressed: pressed ?? this.pressed,
    sink: sink ?? this.sink,
  );

  @override
  ShapeBorder scale(double t) => GumdropShape(
    side: side.scale(t),
    lip: lip * t,
    lipColor: lipColor,
    lipEdge: lipEdge,
    highlight: highlight * t,
    highlightColor: highlightColor,
    shine: shine == null
        ? null
        : Rect.fromLTRB(
            shine!.left * t,
            shine!.top * t,
            shine!.right * t,
            shine!.bottom * t,
          ),
    shineColor: shineColor,
    ball: ball,
    radius: radius == null ? null : radius! * t,
    pressed: pressed,
    sink: sink * t,
  );

  GumdropShape _lerp(GumdropShape other, double t) => GumdropShape(
    side: BorderSide.lerp(side, other.side, t),
    lip: ui.lerpDouble(lip, other.lip, t)!,
    lipColor: Color.lerp(lipColor, other.lipColor, t)!,
    lipEdge: Color.lerp(lipEdge, other.lipEdge, t)!,
    highlight: ui.lerpDouble(highlight, other.highlight, t)!,
    highlightColor: Color.lerp(highlightColor, other.highlightColor, t)!,
    shine: shine == null || other.shine == null
        ? (t < 0.5 ? shine : other.shine)
        : Rect.lerp(shine, other.shine, t),
    shineColor: Color.lerp(shineColor, other.shineColor, t)!,
    ball: t < 0.5 ? ball : other.ball,
    radius: radius == null && other.radius == null
        ? null
        : BorderRadius.lerp(radius, other.radius, t),
    pressed: ui.lerpDouble(pressed, other.pressed, t)!,
    sink: ui.lerpDouble(sink, other.sink, t)!,
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
      other.lipEdge == lipEdge &&
      other.highlight == highlight &&
      other.highlightColor == highlightColor &&
      other.shine == shine &&
      other.shineColor == shineColor &&
      other.ball == ball &&
      other.radius == radius &&
      other.pressed == pressed &&
      other.sink == sink;

  @override
  int get hashCode => Object.hash(
    side,
    lip,
    lipColor,
    lipEdge,
    highlight,
    highlightColor,
    shine,
    shineColor,
    ball,
    radius,
    pressed,
    sink,
  );

  @override
  String toString() =>
      'GumdropShape(lip: $lip, lipColor: $lipColor, pressed: $pressed, '
      'side: $side)';
}
