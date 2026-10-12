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
