import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// [child] in [scheme] (SET-2): a team's screens in the scheme you see it
/// in. The new theme keeps the card context when nested on a card. It always
/// wraps [child] the same way, so a change of scheme doesn't rebuild the
/// subtree from scratch (and lose its state).
class SchemeTheme extends StatelessWidget {
  const new({required this.scheme, required this.child, super.key});

  final TeamScheme scheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = GumdropColors.of(context);
    return _Themed(AppTheme.of(scheme, onCard: colors.onCard), child);
  }
}

/// [child] with the status bar's icons set for the scheme it's drawn in:
/// light on a dark page, dark on a light one, as the app bars set them
/// (SPEC §7.4). For a screen with no app bar at its top, like Teams,
/// Profile and a team's tabs, so the icons don't keep the last screen's.
class SchemeStatusBar extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value:
        Theme.of(context).appBarTheme.systemOverlayStyle ??
        (GumdropColors.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark),
    child: child,
  );
}

/// [child] on a card: the theme's card context, for what sits on a
/// [GumdropColors.surface] (a card, a sheet, the composer). Material
/// widgets, text styles, and headings inside take the card's colors (muted
/// text, outlines, and the candies' text shades differ from the page's).
class GumdropSurface extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = GumdropColors.of(context);
    if (colors.onCard) return child;
    return _Themed(AppTheme.of(colors.scheme, onCard: true), child);
  }
}

/// [child] in [theme], with the default text color that Material set above
/// (from the old theme) brought along.
class _Themed extends StatelessWidget {
  const new(this.theme, this.child);

  final ThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: theme,
    child: DefaultTextStyle.merge(
      style: TextStyle(color: theme.colorScheme.onSurface),
      child: child,
    ),
  );
}

/// An Open Field card: the card color, a 2 px rim on a 4 px lip in the rim
/// color, corner 18, and its [child] in the card context
/// ([GumdropSurface]).
class GumdropCard extends StatelessWidget {
  const new({
    required this.child,
    this.radius = 18,
    this.padding = const EdgeInsets.all(12),
    this.color,
    super.key,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// The fill, if not the theme's surface.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = GumdropColors.of(context);
    return DecoratedBox(
      decoration: GumdropStyle.of(context).cardDecoration(
        color ?? colors.surface,
        radius,
        side: colors.surfaceBorderWidth == 0
            ? BorderSide.none
            : BorderSide(
                color: colors.surfaceBorder,
                width: colors.surfaceBorderWidth,
              ),
      ),
      child: Padding(
        padding: padding,
        child: GumdropSurface(child: child),
      ),
    );
  }
}
