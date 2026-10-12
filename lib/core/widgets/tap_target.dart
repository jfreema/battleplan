import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Gives a small control, like a reaction chip, a tap target of at least
/// [minSize] (48 × 48, SPEC §7.6) without drawing it any bigger: the child
/// sits centered in the larger box, and a tap anywhere in the box reaches
/// it. Material's buttons pad themselves the same way.
///
/// Put a `Semantics(container: true, ...)` above it so screen readers see
/// the whole target too.
class TapTargetPadding extends SingleChildRenderObjectWidget {
  const new({
    required Widget super.child,
    this.minSize = const Size.square(kMinInteractiveDimension),
    super.key,
  });

  final Size minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderTapTargetPadding(minSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderTapTargetPadding renderObject,
  ) => renderObject.minSize = minSize;
}

/// The render object of [TapTargetPadding].
class RenderTapTargetPadding extends RenderShiftedBox {
  new(this._minSize) : super(null);

  Size get minSize => _minSize;
  Size _minSize;
  set minSize(Size value) {
    if (_minSize == value) return;
    _minSize = value;
    markNeedsLayout();
  }

  Size _sizeFor(BoxConstraints constraints, Size childSize) =>
      constraints.constrain(
        Size(
          childSize.width > minSize.width ? childSize.width : minSize.width,
          childSize.height > minSize.height ? childSize.height : minSize.height,
        ),
      );

  @override
  double computeMinIntrinsicWidth(double height) {
    final w = child?.getMinIntrinsicWidth(height) ?? 0;
    return w > minSize.width ? w : minSize.width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final w = child?.getMaxIntrinsicWidth(height) ?? 0;
    return w > minSize.width ? w : minSize.width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final h = child?.getMinIntrinsicHeight(width) ?? 0;
    return h > minSize.height ? h : minSize.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final h = child?.getMaxIntrinsicHeight(width) ?? 0;
    return h > minSize.height ? h : minSize.height;
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.constrain(minSize);
    return _sizeFor(constraints, child.getDryLayout(constraints.loosen()));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(minSize);
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = _sizeFor(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    // Outside the child but inside the target: tap the child's middle.
    final child = this.child;
    if (child == null || !size.contains(position)) return false;
    final center = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, position) => child.hitTest(result, position: center),
    );
  }
}
