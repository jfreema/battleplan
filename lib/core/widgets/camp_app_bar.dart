import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/widgets/camo.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A pushed screen's top bar on Boot Camp Mix's camouflage (#85, SPEC
/// §7.4): an [AppBar] with the scheme's camouflage behind it (and its
/// [flexibleSpace], if any, over that) and a 3 px ink line under it. One
/// with its own [backgroundColor] (the photo viewer's black) keeps it,
/// plain.
class CampAppBar extends StatelessWidget implements PreferredSizeWidget {
  const new({
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.shape,
    this.backgroundColor,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.toolbarHeight,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.actionsPadding,
    super.key,
  });

  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final ShapeBorder? shape;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final bool excludeHeaderSemantics;
  final double? titleSpacing;
  final double? toolbarHeight;
  final TextStyle? titleTextStyle;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final EdgeInsetsGeometry? actionsPadding;

  @override
  Size get preferredSize => Size.fromHeight(
    (toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final p = GumdropColors.of(context).roles.palette;
    final camo = backgroundColor == null;
    // Icon buttons among the actions are round buttons (#85): the panel
    // color in a 2.5 px ink outline, 36 across in a 48 px tap area.
    final c = GumdropColors.of(context);
    // On the panel color, so in the panel's lettering (Candy Pop's navy
    // on white, #86).
    final onPanel = c.card.textOnPage;
    final round = IconButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(c.surface),
        foregroundColor: WidgetStatePropertyAll(onPanel),
        iconColor: WidgetStatePropertyAll(onPanel),
        shape: WidgetStatePropertyAll(
          CircleBorder(side: BorderSide(color: c.ink, width: 2.5)),
        ),
        fixedSize: const WidgetStatePropertyAll(Size.square(36)),
        minimumSize: const WidgetStatePropertyAll(Size.square(36)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        iconSize: const WidgetStatePropertyAll(20),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
    final buttons = actions;
    final bar = AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: title,
      actions: buttons == null || !camo
          ? buttons
          : [for (final a in buttons) IconButtonTheme(data: round, child: a)],
      flexibleSpace: camo
          ? Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: CamoPainter(p)),
                ?flexibleSpace,
              ],
            )
          : flexibleSpace,
      bottom: bottom,
      shape: camo ? Border(bottom: BorderSide(color: p.ink, width: 3)) : shape,
      backgroundColor: camo ? p.camoGround : backgroundColor,
      foregroundColor: foregroundColor,
      iconTheme: iconTheme,
      actionsIconTheme: actionsIconTheme,
      excludeHeaderSemantics: excludeHeaderSemantics,
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight,
      titleTextStyle: titleTextStyle,
      systemOverlayStyle: systemOverlayStyle,
      actionsPadding: actionsPadding,
    );
    // Lettered for the camouflage (Sky Blue's white, #86).
    return camo ? CampHeaderTheme(child: bar) : bar;
  }
}
