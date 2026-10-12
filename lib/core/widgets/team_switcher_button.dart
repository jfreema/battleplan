import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The team switcher in the header (SPEC §5.2, §7.5): the team's logo or
/// initials, its name, and ▾, with a dot when another team has unread
/// messages. [compact] is the badge alone, for the top of the rail.
class TeamSwitcherButton extends StatelessWidget {
  const new({
    required this.name,
    required this.badge,
    required this.onPressed,
    this.showDot = false,
    this.compact = false,
    super.key,
  });

  final String name;

  /// The team's logo or initials (a `TeamBadge`).
  final Widget badge;
  final VoidCallback onPressed;
  final bool showDot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dotted = Badge(isLabelVisible: showDot, smallSize: 10, child: badge);
    if (compact) {
      return IconButton(
        tooltip: l10n.switchTeamTooltip,
        onPressed: onPressed,
        icon: dotted,
      );
    }
    return Semantics(
      button: true,
      label: '${l10n.switchTeamTooltip}: $name',
      excludeSemantics: true,
      // The InkWell's own tap is excluded with its semantics.
      onTap: onPressed,
      child: InkWell(
        borderRadius: BorderRadius.circular(Corners.card),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dotted,
              const SizedBox(width: Space.sm),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(AppIcons.expand),
            ],
          ),
        ),
      ),
    );
  }
}
