import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Appearance (SET-2): the three Gumdrop themes as small previews, Gumdrop
/// Pop Dark, Gumdrop Pop Light, and Gumdrop Candy. The old "system" setting
/// shows as Dark, which it now is.
class ThemePicker extends StatelessWidget {
  const new({required this.selected, required this.onSelect, super.key});

  final ThemePreference selected;
  final ValueChanged<ThemePreference> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = AppTheme.flavorOf(selected);
    final choices = [
      (ThemePreference.dark, GumdropFlavor.dark, l10n.themeGumdropDark),
      (ThemePreference.light, GumdropFlavor.light, l10n.themeGumdropLight),
      (ThemePreference.candy, GumdropFlavor.candy, l10n.themeGumdropCandy),
    ];
    return Semantics(
      label: l10n.appearance,
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, (value, flavor, name)) in choices.indexed) ...[
            if (i > 0) const SizedBox(width: Space.sm),
            Expanded(
              child: _ThemeTile(
                flavor: flavor,
                name: name,
                selected: flavor == current,
                onTap: () => onSelect(value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const new({
    required this.flavor,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final GumdropFlavor flavor;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = GumdropColors.of(context);
    final label = Theme.of(context).textTheme.labelMedium;
    final radius = BorderRadius.circular(Corners.tile);
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected ? colors.surface : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? colors.textPrimary : colors.surfaceBorder,
              width: selected ? 2.5 : colors.surfaceBorderWidth,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ExcludeSemantics(child: _Preview(flavor: flavor)),
                      if (selected)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colors.mint.face,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.ink, width: 2),
                            ),
                            child: Icon(
                              AppIcons.check,
                              size: 15,
                              color: colors.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: label?.copyWith(
                      height: 1.15,
                      color: selected ? colors.textPrimary : colors.textOnPage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tiny screen in [flavor]'s colors: the page, a heading, a card, and
/// your bubble.
class _Preview extends StatelessWidget {
  const new({required this.flavor});

  final GumdropFlavor flavor;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.forFlavor(flavor);
    Widget bar(Color color, double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
    return Container(
      height: 64,
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: c.page,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.divider, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(c.headingText, 26, 6),
          const SizedBox(height: 6),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: bar(c.you.face, 30, 12),
          ),
        ],
      ),
    );
  }
}
