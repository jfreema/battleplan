import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// The unread count on a button or tab (design §3.6): a 20 px cherry pill
/// with ink numbers, cut out of what's under it by a 2 px ring in the page
/// color. [child] is the icon it's on; [offset] places the pill from the
/// icon's top-right corner (Material [Badge.offset]). A Material [Badge], so
/// tests and screen readers find it as before.
Widget unreadBadge(
  BuildContext context, {
  required String label,
  required Widget child,
  bool visible = true,
  Offset offset = const Offset(6, -4),
}) {
  final c = GumdropColors.of(context);
  return Badge(
    isLabelVisible: visible,
    backgroundColor: c.badgeRing,
    largeSize: 20,
    padding: const EdgeInsets.all(2),
    offset: offset,
    label: Container(
      height: 16,
      constraints: const BoxConstraints(minWidth: 16),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: c.cherry.face,
        shape: const StadiumBorder(),
      ),
      child: Text(label),
    ),
    child: child,
  );
}

/// A round gumdrop icon button for headers (design §3.1): a 38 px
/// secondary gumdrop (or [accent]), with an optional unread count at its
/// top right (design §3.6). Its tap target stays 48.
class GumdropIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeLabel,
    this.accent,
    this.size = 38,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// The unread count to show (1 to 99+), or null for none.
  final String? badgeLabel;
  final GumdropAccent? accent;
  final double size;

  /// Where the count sits on the icon, so the pill's corner lands 6 px out
  /// from the button's top-right edge (design §3.6).
  static Offset badgeOffset(double size, double iconSize) {
    final inset = (size - iconSize) / 2;
    // Material puts the pill's left at the icon's right less the pill's
    // height (20) plus dx, and its top at dy + 8 less half its height; the
    // pill's right edge should be 6 past the button's, its top 6 above.
    return Offset(size - 14 - inset - iconSize + 20, -4 - inset);
  }

  @override
  Widget build(BuildContext context) {
    final b = GumdropButtons.of(context);
    final iconSize = size <= 38 ? 19.0 : 22.0;
    final glyph = Icon(icon);
    return IconButton(
      tooltip: tooltip,
      style: b.icon(size: size, accent: accent),
      onPressed: onPressed,
      icon: badgeLabel == null
          ? glyph
          : unreadBadge(
              context,
              label: badgeLabel!,
              offset: badgeOffset(size, iconSize),
              child: glyph,
            ),
    );
  }
}
