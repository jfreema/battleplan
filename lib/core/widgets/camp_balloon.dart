import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Which side of a speech balloon its tail points from (#85).
enum BalloonTail {
  /// Someone else's: from the left edge, near the top, toward their tag.
  left,

  /// Mine: from the right edge, near the bottom.
  right,

  /// None: an announcement or a deleted message.
  none,
}

/// Boot Camp Mix's speech balloon (#85, SPEC §7.4): a rounded box (corner
/// 19) in a [side] outline with a pointed tail on one side, drawn outside
/// the box, in the gap beside it. The tail on [BalloonTail.left] starts 11
/// from the top; on [BalloonTail.right], 9 from the bottom, as the design
/// has them. My own balloon has the candy finish's white [highlight] along
/// the top of its face (#98).
@immutable
class BalloonBorder extends OutlinedBorder {
  const new({
    this.tail = BalloonTail.left,
    this.radius = 19,
    this.tailLength = 9.5,
    this.tailSpan = 16,
    this.highlight,
    super.side,
  });

  final BalloonTail tail;

  /// A 2.5 px band along the top of the face, inside the outline, or null
  /// for none.
  final Color? highlight;

  /// The box's corner.
  final double radius;

  /// How far the tail's point stands out from the box.
  final double tailLength;

  /// How tall the tail is where it meets the box.
  final double tailSpan;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  /// The outline through [rect]: the rounded box with its tail.
  Path _shape(Rect rect) {
    final r = math.min(radius, math.min(rect.width, rect.height) / 2);
    final box = RRect.fromRectAndRadius(rect, Radius.circular(r));
    final path = Path()..addRRect(box);
    if (tail == BalloonTail.none) return path;
    final span = math.min(tailSpan, math.max(0, rect.height - 2 * r + 8));
    final top = tail == BalloonTail.left
        ? rect.top + math.min(11, math.max(0, rect.height - span) / 2)
        : math.max(rect.top, rect.bottom - 9 - span);
    // The point sits a little below the middle of its base, as the design's
    // skewed square does.
    final point = top + span * 0.55;
    final x = tail == BalloonTail.left ? rect.left : rect.right;
    final out = tail == BalloonTail.left ? -tailLength : tailLength;
    // Overlapping the box a little, so the two join without a seam.
    final inner = tail == BalloonTail.left ? 2.0 : -2.0;
    final pointer = Path()
      ..moveTo(x + inner, top)
      ..lineTo(x + out, point)
      ..lineTo(x + inner, top + span)
      ..close();
    return Path.combine(PathOperation.union, path, pointer);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _shape(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _shape(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final top = highlight;
    if (top != null && top.a > 0) {
      final inner = _shape(rect.deflate(side.width));
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          inner,
          inner.shift(const Offset(0, 2.5)),
        ),
        Paint()..color = top,
      );
    }
    if (side.style == BorderStyle.none || side.width == 0) return;
    // The stroke inside the box, so the outline's outer edge is the box's.
    canvas.drawPath(
      _shape(rect.deflate(side.width / 2)),
      side.toPaint()..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  BalloonBorder scale(double t) => BalloonBorder(
    tail: tail,
    radius: radius * t,
    tailLength: tailLength * t,
    tailSpan: tailSpan * t,
    highlight: highlight,
    side: side.scale(t),
  );

  @override
  BalloonBorder copyWith({BorderSide? side, BalloonTail? tail}) =>
      BalloonBorder(
        tail: tail ?? this.tail,
        radius: radius,
        tailLength: tailLength,
        tailSpan: tailSpan,
        highlight: highlight,
        side: side ?? this.side,
      );

  @override
  bool operator ==(Object other) =>
      other is BalloonBorder &&
      other.tail == tail &&
      other.radius == radius &&
      other.tailLength == tailLength &&
      other.tailSpan == tailSpan &&
      other.highlight == highlight &&
      other.side == side;

  @override
  int get hashCode =>
      Object.hash(tail, radius, tailLength, tailSpan, highlight, side);
}
