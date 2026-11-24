import 'dart:math' as math;

import 'package:battleplan/core/design/candy.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// A candy piece around [child] (#98, SPEC §7.4): a face of [color] with
/// corners of [radius] in an [outline] px ink outline, on a lip [depth] px
/// deep of a darker shade of it ([Candy.lipOf], or [lip]) with the ink
/// carried round under it, a white highlight along its top, and a [shine]
/// near its top left. Tags, stamps, the current tab's tile, badges, and
/// dog tags.
///
/// The lip is painted under the box, taking no room, as the mockup's box
/// shadows do: leave [depth] px under it, or it overlaps what's below.
/// [sunk] moves the face that far down onto its lip (a picked button), the
/// lip then [depth] deep under it.
///
/// [padding] is inside the outline, as a [Container]'s is inside its
/// border, unless [padOutline] is false: then it's from the face's edge,
/// as a [DecoratedBox]'s outline doesn't move its child.
class CandyBox extends StatelessWidget {
  const new({
    required this.color,
    this.child,
    this.lip,
    this.ink,
    this.radius = 7,
    this.outline = 2.5,
    this.depth = 4,
    this.sunk = 0,
    this.highlight = true,
    this.shine,
    this.shineColor = Candy.tagShine,
    this.ball = false,
    this.padding,
    this.width,
    this.height,
    this.alignment,
    this.clipChild = false,
    this.padOutline = true,
    super.key,
  });

  /// The face.
  final Color color;
  final Widget? child;

  /// The lip's color; null for the face's darker shade.
  final Color? lip;

  /// The outline's color; null for the scheme's ink.
  final Color? ink;

  /// The face's corners; a radius past half its height makes a pill.
  final double radius;
  final double outline;
  final double depth;
  final double sunk;

  /// Whether the face has the white highlight along its top.
  final bool highlight;

  /// The shine, from the face's top left inside its outline; null for
  /// none.
  final Rect? shine;
  final Color shineColor;

  /// Whether the shine is a tilted oval (round pieces).
  final bool ball;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  /// Whether [child] is clipped to the face inside its outline (a photo
  /// on a dog tag).
  final bool clipChild;

  /// Whether [padding] starts inside the outline.
  final bool padOutline;

  @override
  Widget build(BuildContext context) {
    final finish = CandyFinish(
      lip: lip ?? Candy.lipOf(color),
      ink: ink ?? GumdropColors.of(context).ink,
      depth: depth,
      outline: outline,
      highlight: highlight ? Candy.highlightOn(color) : null,
      shine: shine,
      shineColor: shineColor,
      ball: ball,
    );
    var inside = child;
    if (inside != null && clipChild) {
      inside = ClipRRect(
        borderRadius: BorderRadius.circular(math.max(0, radius - outline)),
        child: inside,
      );
    }
    final face = CustomPaint(
      painter: _CandyUnder(finish: finish, color: color, radius: radius),
      foregroundPainter: _CandyOver(finish: finish, radius: radius),
      child: Container(
        width: width,
        height: height,
        alignment: alignment,
        padding: padOutline
            ? EdgeInsets.all(outline).add(padding ?? EdgeInsets.zero)
            : padding,
        child: inside,
      ),
    );
    return sunk == 0
        ? face
        : Transform.translate(offset: Offset(0, sunk), child: face);
  }
}

RRect _faceOf(Size size, double radius) => RRect.fromRectAndRadius(
  Offset.zero & size,
  Radius.circular(math.min(radius, size.shortestSide / 2)),
);

/// The ink and the lip under the face, then the face.
class _CandyUnder extends CustomPainter {
  const new({required this.finish, required this.color, required this.radius});

  final CandyFinish finish;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final face = _faceOf(size, radius);
    finish.paintUnder(canvas, face);
    canvas.drawRRect(face, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CandyUnder old) =>
      old.finish != finish || old.color != color || old.radius != radius;
}

/// The highlight, the shine, and the outline, over the face's contents.
class _CandyOver extends CustomPainter {
  const new({required this.finish, required this.radius});

  final CandyFinish finish;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) =>
      finish.paintOver(canvas, _faceOf(size, radius));

  @override
  bool shouldRepaint(_CandyOver old) =>
      old.finish != finish || old.radius != radius;
}
