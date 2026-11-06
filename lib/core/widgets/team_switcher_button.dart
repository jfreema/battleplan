import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The team switcher in the header (SPEC §5.2, §7.3): the tab's stencil
/// [eyebrow] over the team's [name] in Lilita One with the scheme's drop,
/// and a small chevron, with a coral dot when another team has unread
/// messages. One button, at least 48 tall.
class TeamSwitcherButton extends StatelessWidget {
  const new({
    required this.name,
    required this.onPressed,
    this.eyebrow,
    this.showDot = false,
    super.key,
  });

  final String name;

  /// What the tab is ("Team chat"), or null for the name alone.
  final String? eyebrow;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final above = eyebrow;
    // The chevron, 18 px in a 24 × 30 box, 1 px low, with the dot at its
    // top right.
    final chevron = SizedBox(
      width: 24,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 1,
            child: Icon(
              AppIcons.expand,
              size: 18,
              weight: 700,
              color: c.textOnPage,
            ),
          ),
          if (showDot)
            Positioned(
              top: 3,
              right: -3,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: c.badgeRing,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: c.cherry.face,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (above != null)
                Text(
                  above.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    fontFamily: AppFonts.sticker,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 14 / 12,
                    letterSpacing: 12 * 0.18,
                    color: c.you.text,
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: TeamName(name)),
                  const SizedBox(width: 3),
                  chevron,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The team's name on one line in Lilita 27 with the scheme's drop: 23, 21
/// or 19 when it doesn't fit, and cut with "…" only when even 19 doesn't.
class TeamName extends StatelessWidget {
  const new(this.name, {super.key});

  final String name;

  /// The sizes tried, largest first.
  static const List<double> sizes = [27, 23, 21, 19];

  @override
  Widget build(BuildContext context) {
    // From the 32 px style, for its 2 px drop.
    final heading = Theme.of(context).textTheme.headlineMedium!
        .copyWith(height: 30 / 27, letterSpacing: 27 * 0.005);
    return LayoutBuilder(
      builder: (context, constraints) {
        var style = heading.copyWith(fontSize: sizes.last);
        for (final size in sizes) {
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
        return Padding(
          // Room for the 2 px drop.
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        );
      },
    );
  }
}
