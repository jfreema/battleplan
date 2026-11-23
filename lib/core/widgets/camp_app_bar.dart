import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
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
    this.columnWidth,
    super.key,
  });

  /// The page's centered column on a wide screen, if it has one: the
  /// camouflage and its ink line still run the bar's whole width, but the
  /// back button, title, and actions stand in the column, over the page
  /// they belong to. Before, a page in a column (`GumdropScaffold`, #29)
  /// narrowed the whole bar, so on an iPad or a computer its camouflage
  /// stopped short of both edges, a strip floating mid-page. Null for a
  /// bar as wide as its contents.
  final double? columnWidth;

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
    // A menu's button (More) takes its icon's color from the menu theme
    // over the button theme, so it's set there too (#87): otherwise it's
    // the header's lettering, white on Candy Pop's white face.
    final menus = PopupMenuTheme.of(context).copyWith(iconColor: onPanel);
    final buttons = actions;
    // The theme editor's header background, if it set one (#91); the
    // Super Admin Panel's, the camouflage.
    final ground = CamoPainter(
      p,
      style: c.shipped
          ? HeaderStyle.camo
          : ThemeCatalog.headerStyleOf(c.scheme),
    );
    AppBar barOf({required bool painted}) => AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: title,
      actions: buttons == null || !camo
          ? buttons
          : [
              for (final a in buttons)
                IconButtonTheme(
                  data: round,
                  child: PopupMenuTheme(data: menus, child: a),
                ),
            ],
      flexibleSpace: camo && painted
          ? Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: ground),
                ?flexibleSpace,
              ],
            )
          : flexibleSpace,
      bottom: bottom,
      shape: !camo
          ? shape
          : painted
          ? Border(bottom: BorderSide(color: p.ink, width: 3))
          : null,
      // In a column the ground is painted around the bar, so the bar
      // itself is clear and never tints as the page scrolls under it.
      backgroundColor: !camo
          ? backgroundColor
          : painted
          ? p.camoGround
          : Colors.transparent,
      scrolledUnderElevation: camo && !painted ? 0 : null,
      surfaceTintColor: camo && !painted ? Colors.transparent : null,
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
    final column = columnWidth;
    if (!camo) return barOf(painted: true);
    // Lettered for the camouflage (Sky Blue's white, #86).
    if (column == null) return CampHeaderTheme(child: barOf(painted: true));
    return CampHeaderTheme(
      child: LayoutBuilder(
        builder: (context, box) {
          final margin = math.max<double>(0, (box.maxWidth - column) / 2);
          if (margin == 0) return barOf(painted: true);
          // The ground and its ink line across the whole width, the bar's
          // contents in the column over it.
          return DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: p.ink, width: 3)),
            ),
            child: ColoredBox(
              color: p.camoGround,
              child: CustomPaint(
                painter: ground,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: margin),
                  child: barOf(painted: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
