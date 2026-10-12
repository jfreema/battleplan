import 'package:battleplan/core/design/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// A bottom sheet on phones and a dialog on wide screens (SPEC §7.5). With
/// an [anchor] (the button that opened it), wide screens get a dropdown
/// panel under that button instead of a dialog, as the team switcher does
/// (SPEC §5.2).
Future<T?> showAdaptiveSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  BuildContext? anchor,
}) {
  final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
  if (wide) {
    final box = anchor?.findRenderObject();
    if (box is RenderBox && box.hasSize && box.attached) {
      return _showDropdownPanel<T>(context, anchor: box, builder: builder);
    }
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
          child: builder(context),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: builder,
  );
}

/// The panel's width and greatest height.
const _panelWidth = 400.0;
const _panelMaxHeight = 600.0;

/// A panel dropped down from [anchor], over a clear barrier that closes it
/// on a tap outside or Esc. It fades in quickly, or appears at once when
/// the system reduces motion (SPEC §7.3).
Future<T?> _showDropdownPanel<T>(
  BuildContext context, {
  required RenderBox anchor,
  required WidgetBuilder builder,
}) {
  final navigator = Navigator.of(context);
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final rect = Rect.fromPoints(
    anchor.localToGlobal(Offset.zero, ancestor: overlay),
    anchor.localToGlobal(
      anchor.size.bottomRight(Offset.zero),
      ancestor: overlay,
    ),
  );
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: Motion.of(context, Motion.fast),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Motion.curve),
      child: child,
    ),
    pageBuilder: (dialogContext, _, _) => CustomSingleChildLayout(
      delegate: _BelowAnchor(rect),
      child: Material(
        elevation: 3,
        // Shadows only on floating things (SPEC §7.3).
        shadowColor: Theme.of(dialogContext).colorScheme.shadow,
        color: Theme.of(dialogContext).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Corners.card),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.only(top: Space.md),
          child: builder(dialogContext),
        ),
      ),
    ),
  );
}

/// Places the panel just below [anchor], starting at its left edge, kept
/// on screen.
class _BelowAnchor extends SingleChildLayoutDelegate {
  const new(this.anchor);

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final below = constraints.maxHeight - anchor.bottom - Space.lg;
    return BoxConstraints(
      maxWidth: _panelWidth.clamp(0, constraints.maxWidth - 2 * Space.lg),
      maxHeight: below.clamp(160, _panelMaxHeight),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = anchor.left.clamp(
      Space.lg,
      (size.width - childSize.width - Space.lg).clamp(Space.lg, size.width),
    );
    final y = (anchor.bottom + Space.xs).clamp(
      0.0,
      (size.height - childSize.height).clamp(0.0, size.height),
    );
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_BelowAnchor old) => old.anchor != anchor;
}
