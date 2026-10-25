import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The team switcher in the header (SPEC §5.2, §7.5; Gumdrop Pop design
/// §3.3): the team's name in the big Lilita One heading with its stacked
/// shadow, and a chevron, with a dot when another team has unread
/// messages. A team's uploaded logo shows before the name; initials on the
/// team color don't, as the name says it. [compact] is the badge alone,
/// for the top of the rail.
class TeamSwitcherButton extends StatelessWidget {
  const new({
    required this.name,
    required this.onPressed,
    this.badge,
    this.showDot = false,
    this.compact = false,
    super.key,
  });

  final String name;

  /// The team's logo (a `TeamBadge`), or null for the name alone.
  final Widget? badge;
  final VoidCallback onPressed;
  final bool showDot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final logo = badge;
    if (compact) {
      return IconButton(
        tooltip: l10n.switchTeamTooltip,
        onPressed: onPressed,
        icon: Badge(
          isLabelVisible: showDot,
          smallSize: 10,
          child: logo ?? const Icon(AppIcons.expand),
        ),
      );
    }
    // The chevron: 22 px of thick stroke with a hard 2 px drop shadow.
    final chevron = Badge(
      isLabelVisible: showDot,
      smallSize: 10,
      child: Icon(
        AppIcons.expand,
        size: 30,
        weight: 700,
        color: c.headingText,
        shadows: [Shadow(color: c.headingShadow, offset: const Offset(2, 2))],
      ),
    );
    return Semantics(
      container: true,
      button: true,
      label: '${l10n.switchTeamTooltip}: $name',
      excludeSemantics: true,
      // The InkWell's own tap is excluded with its semantics.
      onTap: onPressed,
      child: InkWell(
        borderRadius: BorderRadius.circular(Corners.tile),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logo != null) ...[logo, const SizedBox(width: Space.sm)],
              // Room for the heading's 4 px shadow.
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  child: _FittedName(name),
                ),
              ),
              const SizedBox(width: 1),
              chevron,
            ],
          ),
        ),
      ),
    );
  }
}

/// The team's name on one line in the team-name heading (36 px): a few
/// sizes smaller when it doesn't fit (a phone's header has four buttons
/// beside it), and cut with "…" only when even the smallest doesn't fit.
class _FittedName extends StatelessWidget {
  const new(this.name);

  final String name;

  /// The sizes tried, largest first.
  static const List<double> _sizes = [TypeScale.teamName, 30.0, 26.0, 22.0];

  @override
  Widget build(BuildContext context) {
    final heading = Theme.of(context).textTheme.headlineLarge!;
    return LayoutBuilder(
      builder: (context, constraints) {
        var style = heading.copyWith(fontSize: _sizes.last);
        for (final size in _sizes) {
          final candidate = heading.copyWith(fontSize: size);
          final painter = TextPainter(
            text: TextSpan(text: name, style: candidate),
            maxLines: 1,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final fits = !painter.didExceedMaxLines;
          painter.dispose();
          if (fits) {
            style = candidate;
            break;
          }
        }
        return Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}
