import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:material_ui/material_ui.dart';

/// The unread count on a button or tab (SPEC §7.3): Boot Camp Mix's red
/// (#85), a pill at least 19 px across with a black stencil number, in a
/// 2.5 px ink outline. [child] is the icon it's on;
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
    // The ink outline.
    backgroundColor: c.ink,
    // At least; it grows with the pill.
    largeSize: 24,
    padding: const EdgeInsets.all(2.5),
    offset: offset,
    label: Container(
      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      // Unread is red in Boot Camp Mix (#85), as the bell's dot is.
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
            fontWeight: FontWeight.w900,
            color: c.inkOn(c.cherry),
          ),
        ),
      ),
    ),
    child: child,
  );
}

/// How far an unread count's text grows with the system text size.
const double maxBadgeTextScale = 1.6;

/// A header icon button (SPEC §7.3): Boot Camp Mix's round icon button
/// (#85), a 36 px circle in the panel color with a 2.5 px ink outline on a
/// 2 px hard shadow, its 20 px icon in the text color, in a 48 × 48 tap
/// area, with an optional unread count at its top right.
class GumdropIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeLabel,
    this.red = false,
    this.dot = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// The unread count to show (1 to 99+), or null for none.
  final String? badgeLabel;

  /// The red one, for adding (the schedule's +, #85): white icon.
  final bool red;

  /// A 13 px dot in my own color on its corner, in an ink ring: a setting
  /// of mine is on (the schedule's filter).
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final face = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: red ? c.cherry.face : c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: c.ink, width: 2.5),
        boxShadow: [BoxShadow(color: c.pageShadow, offset: const Offset(2, 2))],
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 20,
        weight: red ? 700 : null,
        color: red ? Colors.white : c.textOnPage,
      ),
    );
    final glyph = !dot
        ? face
        : Stack(
            clipBehavior: Clip.none,
            children: [
              face,
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: c.you.face,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.ink, width: 2.5),
                  ),
                ),
              ),
            ],
          );
    return IconButton(
      tooltip: tooltip,
      color: c.textOnPage,
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
