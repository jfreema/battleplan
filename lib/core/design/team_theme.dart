import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// [child] in the current Gumdrop theme tinted with a team's color (TEAM-1;
/// team_tint.dart): wrap every screen inside a team. [teamColor] is the
/// group's ARGB color; null (no color yet, or still loading) keeps the
/// untinted theme.
class TeamTheme extends StatelessWidget {
  const new({required this.teamColor, required this.child, super.key});

  final int? teamColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = GumdropColors.of(context);
    final team = teamColor == null ? null : teamColor! | 0xFF000000;
    if (colors.teamColor?.toARGB32() == team) return child;
    return _Themed(
      AppTheme.of(colors.flavor, teamColor: team, onCard: colors.onCard),
      child,
    );
  }
}

/// [child] on a card: the theme's card context, for what sits on a
/// [GumdropColors.surface] (a card, a white sheet, the composer). It only
/// changes anything in Candy, where text on the blue page is white and on a
/// white card navy: Material widgets, text styles, and headings inside take
/// the card's colors.
class GumdropSurface extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = GumdropColors.of(context);
    if (colors.onCard) return child;
    return _Themed(
      AppTheme.of(
        colors.flavor,
        teamColor: colors.teamColor?.toARGB32(),
        onCard: true,
      ),
      child,
    );
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

/// A card in the Gumdrop recipe (design §3.5): the surface color, the
/// theme's card outline, rounded corners, no shadow, and its [child] in the
/// card context ([GumdropSurface]).
class GumdropCard extends StatelessWidget {
  const new({
    required this.child,
    this.radius = 20,
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
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: colors.surfaceBorderWidth == 0
            ? null
            : Border.all(
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
