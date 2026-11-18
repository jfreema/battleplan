import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// A team's color as a small dot beside its name (SPEC §7.4, #36): the
/// team's true color, never lightened, so navy still reads as navy. Where
/// it stands out from what's under it by less than 3:1 (navy, maroon,
/// slate, or black on a dark card; light blue on a light one), a 1.5 px
/// ring in the muted text color outlines it, in every scheme alike.
/// Decorative: the name beside it says the team.
class TeamDot extends StatelessWidget {
  const new({required this.color, this.size = defaultSize, super.key});

  /// The dot's color, the team's.
  final Color color;

  /// Its width and height, the ring included.
  final double size;

  /// The dot's size beside a 13 px name.
  static const double defaultSize = 10;

  /// The least contrast with the surface under it before it gets a ring.
  static const double minContrast = 3;

  /// Whether [color] needs the ring on [surface].
  static bool needsRing(Color color, Color surface) =>
      ColorMath.contrast(color, surface) < minContrast;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final surface = c.onCard ? c.surface : c.page;
    final ring = needsRing(color, surface);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: ring
              ? Border.all(
                  color: c.onCard ? c.textMuted : c.textMutedOnPage,
                  width: 1.5,
                )
              : null,
        ),
      ),
    );
  }
}
