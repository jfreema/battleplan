import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:material_ui/material_ui.dart';

/// The unread count on a button or tab (SPEC §7.3): a coral pill at least
/// 19 px across with an ink number in Fredoka 700 12, cut out of what's
/// under it by a 2 px ring in the page color. [child] is the icon it's on;
/// [offset] places the pill from the icon's top-right corner (Material
/// [Badge.offset]). A Material [Badge], so tests and screen readers find it
/// as before.
///
/// The pill grows with the text size, to 1.6 times, so the number is
/// never cut off and the icon under it still shows.
Widget unreadBadge(
  BuildContext context, {
  required String label,
  required Widget child,
  bool visible = true,
  Offset offset = const Offset(6, -4),
}) {
  final c = GumdropColors.of(context);
  final scaler = MediaQuery.textScalerOf(context)
      .clamp(maxScaleFactor: maxBadgeTextScale);
  return Badge(
    isLabelVisible: visible,
    backgroundColor: c.badgeRing,
    // At least; it grows with the pill.
    largeSize: 23,
    padding: const EdgeInsets.all(2),
    offset: offset,
    label: Container(
      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: c.cherry.face,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        textScaler: scaler,
        style: GumdropStyle.of(context).label(
          TextStyle(
            fontSize: 12,
            height: 19 / 12,
            fontWeight: FontWeight.w700,
            color: c.ink,
          ),
        ),
      ),
    ),
    child: child,
  );
}

/// How far an unread count's text grows with the system text size.
const double maxBadgeTextScale = 1.6;

/// A header icon button (SPEC §7.3): a 24 px icon in the text color in a
/// 48 × 48 tap area, with an optional unread count at its top right.
class GumdropIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeLabel,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// The unread count to show (1 to 99+), or null for none.
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: 24);
    return IconButton(
      tooltip: tooltip,
      color: GumdropColors.of(context).textOnPage,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: badgeLabel == null
          ? glyph
          // The pill's corner lands 4 px in from the box's right, 5 below
          // its top.
          : unreadBadge(
              context,
              label: badgeLabel!,
              offset: const Offset(8, -7),
              child: glyph,
            ),
    );
  }
}
