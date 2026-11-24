import 'package:battleplan/core/design/candy.dart';
import 'package:material_ui/material_ui.dart';

/// Boot Camp Mix's round button (#87) with the candy finish (#98): a
/// circle in its ink [side], a glossy ball on a [lip] of its face's darker
/// shade [depth] px deep with the [ink] carried round under it, a white
/// [highlight] along its top, and a tilted oval [shine] near its top left.
/// The lip is drawn only outside the circle, under it, so it never covers
/// the face, and it stays put however the button's states change.
class CampRoundBorder extends CircleBorder {
  const new({
    required this.lip,
    required this.ink,
    super.side,
    this.depth = 4,
    this.highlight,
    this.shine,
  });

  /// The lip's color: the face's darker shade ([Candy.lipOf]).
  final Color lip;

  /// The ink round the lip.
  final Color ink;
  final double depth;

  /// The highlight along the top, or null for none
  /// ([Candy.highlightOn]).
  final Color? highlight;

  /// The oval shine's color, or null for none ([Candy.ballShineOn]).
  final Color? shine;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final d = rect.shortestSide;
    final face = RRect.fromRectAndRadius(
      Rect.fromCircle(center: rect.center, radius: d / 2),
      Radius.circular(d / 2),
    );
    final outline = side.style == BorderStyle.none ? 0.0 : side.width;
    final glow = shine;
    CandyFinish(
        lip: lip,
        ink: ink,
        depth: depth,
        outline: outline,
        highlight: highlight,
        shine: glow == null
            ? null
            : Rect.fromLTWH(d * 0.17, d * 0.14, d * 0.25, d * 0.14),
        shineColor: glow ?? const Color(0x00000000),
        ball: true,
      )
      ..paintUnder(canvas, face)
      ..paintOver(canvas, face, outlineColor: side.color);
  }

  @override
  CampRoundBorder copyWith({BorderSide? side, double? eccentricity}) =>
      CampRoundBorder(
        lip: lip,
        ink: ink,
        side: side ?? this.side,
        depth: depth,
        highlight: highlight,
        shine: shine,
      );

  @override
  ShapeBorder scale(double t) => CampRoundBorder(
    lip: lip,
    ink: ink,
    side: side.scale(t),
    depth: depth * t,
    highlight: highlight,
    shine: shine,
  );

  CampRoundBorder _lerp(CampRoundBorder a, CampRoundBorder b, double t) =>
      CampRoundBorder(
        lip: Color.lerp(a.lip, b.lip, t)!,
        ink: Color.lerp(a.ink, b.ink, t)!,
        side: BorderSide.lerp(a.side, b.side, t),
        depth: a.depth + (b.depth - a.depth) * t,
        highlight: Color.lerp(a.highlight, b.highlight, t),
        shine: Color.lerp(a.shine, b.shine, t),
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is CampRoundBorder ? _lerp(a, this, t) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is CampRoundBorder ? _lerp(this, b, t) : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is CampRoundBorder &&
      other.side == side &&
      other.lip == lip &&
      other.ink == ink &&
      other.depth == depth &&
      other.highlight == highlight &&
      other.shine == shine;

  @override
  int get hashCode => Object.hash(side, lip, ink, depth, highlight, shine);
}
