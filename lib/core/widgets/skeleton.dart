import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder rows shown while a list loads. Lists never show spinners
/// (SPEC §7.5).
class SkeletonList extends StatelessWidget {
  const new({this.rows = 6, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Corners.chip),
      ),
    );
    return Semantics(
      label: AppLocalizations.of(context).loadingLabel,
      child: ExcludeSemantics(
        child: ListView.separated(
          // Fits in a column or a sheet as well as filling a screen.
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Space.lg),
          itemCount: rows,
          separatorBuilder: (_, _) => const SizedBox(height: Space.lg),
          itemBuilder: (_, i) => Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(120, 12),
                    const SizedBox(height: Space.sm),
                    bar(i.isEven ? 220 : 160, 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder tiles shown while a grid loads (SPEC §7.5, #25): the
/// grid's own columns of [aspect]-shaped tiles, one for each [maxTile],
/// [spacing] apart inside [padding], so the page keeps its shape when the
/// pictures come. Saved plays and Team photos load with it, not a spinner.
class SkeletonGrid extends StatelessWidget {
  const new({
    this.maxTile = 300,
    this.aspect = 1,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(16),
    this.minColumns = 1,
    this.tiles = 6,
    super.key,
  });

  final double maxTile;
  final double aspect;
  final double spacing;
  final EdgeInsets padding;

  /// The fewest columns, as the grid itself keeps (three for photos).
  final int minColumns;
  final int tiles;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: AppLocalizations.of(context).loadingLabel,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth - padding.horizontal;
            // As the grids count theirs: whole tiles of [maxTile].
            final columns = (width / maxTile).floor().clamp(minColumns, 8);
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: padding,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: aspect,
              ),
              itemCount: tiles,
              itemBuilder: (_, _) => DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(Corners.chip),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
