import 'package:battleplan/core/design/candy.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/widgets/candy_box.dart';
import 'package:battleplan/core/widgets/candy_sprinkles.dart';
import 'package:material_ui/material_ui.dart';

/// The unread count on a button or tab (SPEC §7.3): Boot Camp Mix's red
/// (#85), a pill at least 19 px across with a black number at 11, in a
/// 2.5 px ink outline, a candy drop on a 4 px lip of a darker red with a
/// shine at its top left (#98). [child] is the icon it's on;
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
    // The pill draws its own outline and lip.
    backgroundColor: Colors.transparent,
    // At least; it grows with the pill.
    largeSize: 24,
    padding: EdgeInsets.zero,
    offset: offset,
    // Unread is red in Boot Camp Mix (#85), as the bell's dot is.
    label: CandyBox(
      color: c.cherry.face,
      lip: c.cherry.lip,
      radius: 12,
      shine: const Rect.fromLTWH(5, 3, 7, 3),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
        alignment: Alignment.center,
        child: Text(
          label,
          textScaler: scaler,
          // A count: the plain face's Black at 11 (#104).
          style: GumdropStyle.of(context).label(
            TextStyle(fontSize: 11, height: 19 / 11, color: c.inkOn(c.cherry)),
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
/// (#85), a 36 px circle in the panel color with a 2.5 px ink outline, its
/// 20 px icon in the text color, in a 48 × 48 tap area, with an optional
/// unread count at its top right. A glossy ball (#98): on a 4 px lip of
/// the panel color's darker shade, with a tilted oval shine.
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
    final fill = red ? c.cherry.face : c.surface;
    final face = CandyBox(
      color: fill,
      lip: red ? c.cherry.lip : c.raisedLip,
      radius: 18,
      shine: const Rect.fromLTWH(6, 5, 9, 5),
      shineColor: Candy.ballShineOn(fill),
      ball: true,
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 20,
        weight: red ? 700 : null,
        // On the panel color, so in the panel's lettering (#86).
        color: red ? Colors.white : c.card.textOnPage,
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
    // The header's sprinkles keep off it (#98).
    return SprinkleKeepOut(
      child: IconButton(
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
      ),
    );
  }
}
