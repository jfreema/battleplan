import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The candy finish (#98, owner's go 2026-11-23: "Go ahead and implement
/// thse changes to all the themes"; SPEC §7.4), mockup 51's Lemon Drop on
/// every scheme in its own colors: every push button, tag, badge, stamp
/// and dog tag is a glossy gumdrop. Its face, in its ink outline, sits on a
/// lip: a band of a darker shade of its own color, with the ink carried
/// round under it. A thin white highlight runs along the top of the face,
/// and a shine streak sits near its top left (a round button's is a tilted
/// oval). Picked or pressed, the face sinks onto its lip.
///
/// The lips are worked out from the faces ([lipOf]), so the theme editor
/// has no new colors to set.
abstract final class Candy {
  /// Lightness under which a face is dark: a licorice gumdrop, the panel
  /// color of a dark scheme.
  static const double darkBelow = 0.2;

  /// The 2.5 px highlight along the top of a face.
  static const double highlightHeight = 2.5;

  /// The lip under a candy [face]: its hue kept, its HSL lightness × 0.66
  /// and saturation × 0.85, or lightness × 0.46 under a dark face, which
  /// would hardly darken otherwise (Black's licorice #252522 takes
  /// #111110).
  static Color lipOf(Color face) {
    final hsl = HSLColor.fromColor(face.withValues(alpha: 1));
    final dark = hsl.lightness < darkBelow;
    return hsl
        .withLightness(hsl.lightness * (dark ? 0.46 : 0.66))
        .withSaturation(hsl.saturation * 0.85)
        .toColor()
        .withValues(alpha: face.a);
  }

  /// Whether [face] is dark (lightness under [darkBelow]): its highlight
  /// and shine are fainter.
  static bool isDark(Color face) =>
      HSLColor.fromColor(face.withValues(alpha: 1)).lightness < darkBelow;

  /// The highlight along a face's top: white at 45%, 9% on a dark face.
  static Color highlightOn(Color face) =>
      isDark(face) ? const Color(0x17FFFFFF) : const Color(0x73FFFFFF);

  /// A push button's shine streak: white at 75%, 17% on a dark face.
  static Color streakOn(Color face) =>
      isDark(face) ? const Color(0x2BFFFFFF) : const Color(0xBFFFFFFF);

  /// A round button's shine: white at 72%, 20% on a dark face.
  static Color ballShineOn(Color face) =>
      isDark(face) ? const Color(0x33FFFFFF) : const Color(0xB8FFFFFF);

  /// The shine on tags, stamps, tiles and badges: white at 80%.
  static const Color tagShine = Color(0xCCFFFFFF);

  /// The shine on dog tags: white at 72%.
  static const Color tagFaceShine = Color(0xB8FFFFFF);
}

/// How one candy piece is finished (see [Candy]): its lip, how deep it
/// sits, its outline, highlight, and shine. [paintUnder] paints what's
/// under the face (the ink and the lip), [paintOver] what's on it (the
/// highlight, the shine, and the outline); the face's own fill goes
/// between.
@immutable
class CandyFinish {
  const new({
    required this.lip,
    required this.ink,
    this.depth = 4,
    this.outline = 2.5,
    this.highlight,
    this.highlightHeight = Candy.highlightHeight,
    this.shine,
    this.shineColor = Candy.tagShine,
    this.shineRadius = 3,
    this.ball = false,
    this.ballTurn = -32,
  });

  /// The lip's color.
  final Color lip;

  /// The outline's, carried round under the lip.
  final Color ink;

  /// How far the ink under the lip reaches below the face, as drawn: 7 under
  /// a push button at rest, 4 once it has sunk onto its lip (the ink stays
  /// where it was, the face moves down).
  final double depth;

  /// The ink outline's width, on the face and round the lip.
  final double outline;

  /// The highlight along the face's top, or null for none.
  final Color? highlight;

  /// How tall the highlight is: 2.5, or 2 on the smallest pieces.
  final double highlightHeight;

  /// The shine, inside the outline: from the inner face's top left, or
  /// null for none.
  final Rect? shine;
  final Color shineColor;

  /// The shine streak's corners.
  final double shineRadius;

  /// Whether the shine is a tilted oval (a round button's).
  final bool ball;

  /// How far the oval is turned, in degrees.
  final double ballTurn;

  /// The ink under the face and the lip band in it, for a face whose outer
  /// edge (outline included) is [face]. Both reach into the face's outline,
  /// which [paintOver] draws over them, so no seam shows.
  void paintUnder(Canvas canvas, RRect face) {
    if (depth <= 0) return;
    final under = face.shift(Offset(0, depth));
    final inner = face.deflate(outline);
    if (ink.a > 0) {
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRRect(under),
          Path()..addRRect(inner),
        ),
        Paint()..color = ink,
      );
    }
    final band = under.deflate(outline);
    if (lip.a > 0 && !band.isEmpty) {
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRRect(band),
          Path()..addRRect(inner),
        ),
        Paint()..color = lip,
      );
    }
  }

  /// The highlight, the shine, and the outline, on a face whose outer
  /// edge is [face]. [outlineColor] draws the outline in another color
  /// than the ink (a button's keyboard focus ring).
  void paintOver(Canvas canvas, RRect face, {Color? outlineColor}) {
    final inner = face.deflate(outline);
    final top = highlight;
    if (top != null && top.a > 0 && inner.height > highlightHeight) {
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRRect(inner),
          Path()..addRRect(inner.shift(Offset(0, highlightHeight))),
        ),
        Paint()..color = top,
      );
    }
    final s = shine;
    if (s != null && shineColor.a > 0) {
      final at = s.shift(Offset(inner.left, inner.top));
      final paint = Paint()..color = shineColor;
      if (ball) {
        canvas
          ..save()
          ..translate(at.center.dx, at.center.dy)
          ..rotate(ballTurn * math.pi / 180)
          ..drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: at.width,
              height: at.height,
            ),
            paint,
          )
          ..restore();
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            at,
            Radius.circular(math.min(shineRadius, at.shortestSide / 2)),
          ),
          paint,
        );
      }
    }
    final edge = outlineColor ?? ink;
    if (outline > 0 && edge.a > 0) {
      canvas.drawRRect(
        face.deflate(outline / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outline
          ..color = edge,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is CandyFinish &&
      other.lip == lip &&
      other.ink == ink &&
      other.depth == depth &&
      other.outline == outline &&
      other.highlight == highlight &&
      other.highlightHeight == highlightHeight &&
      other.shine == shine &&
      other.shineColor == shineColor &&
      other.shineRadius == shineRadius &&
      other.ball == ball &&
      other.ballTurn == ballTurn;

  @override
  int get hashCode => Object.hash(
    lip,
    ink,
    depth,
    outline,
    highlight,
    highlightHeight,
    shine,
    shineColor,
    shineRadius,
    ball,
    ballTurn,
  );
}
