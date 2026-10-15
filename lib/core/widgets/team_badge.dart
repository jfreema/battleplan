import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/cover_image.dart';
import 'package:material_ui/material_ui.dart';

/// A team's logo, or its initials on the team color (SPEC §5.2, §7.1).
class TeamBadge extends StatelessWidget {
  const new({
    required this.name,
    this.color,
    this.imageUrl,
    this.size = 32,
    super.key,
  });

  final String name;
  final Color? color;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final radius = BorderRadius.circular(size * 0.28);
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: radius,
          child: url != null
              ? Image(
                  // Decoded at the size it's drawn, not the upload's, with
                  // the shorter side covering the box so it stays sharp.
                  image: CoverResizeImage.forBox(
                    NetworkImage(url),
                    logicalWidth: size,
                    logicalHeight: size,
                    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _initials(),
                )
              : _initials(),
        ),
      ),
    );
  }

  Widget _initials() {
    final fill = color ?? AppTokens.brand;
    return ColoredBox(
      color: fill,
      child: Center(
        child: Text(
          Avatar.initialsOf(name),
          style: TextStyle(
            // White or black, whichever reads better on the team's color
            // (Carolina blue and gold are light), as chat bubbles do.
            color: ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}
