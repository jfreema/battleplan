import 'package:battleplan/core/design/candy.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/candy_box.dart';
import 'package:battleplan/core/widgets/cover_image.dart';
import 'package:material_ui/material_ui.dart';

/// A team's logo, or its initials on the team color (SPEC §5.2, §7.1).
class TeamBadge extends StatelessWidget {
  const new({
    required this.name,
    this.color,
    this.imageUrl,
    this.size = 32,
    this.candy = false,
    super.key,
  });

  final String name;
  final Color? color;
  final String? imageUrl;
  final double size;

  /// The candy finish (#98), on the Teams cards: a 3 px ink outline, a lip
  /// of the team color's darker shade 5 px deep, and a shine down its
  /// left side, like a dog tag.
  final bool candy;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (candy) return _candy(context, url);
    // A rounded square: corner 14 on the 48 px badge.
    final radius = BorderRadius.circular(size * 14 / 48);
    final c = GumdropColors.of(context);
    // The scheme's inset ring (Boot Camp Mix's ink, #85, around every
    // badge), or, in a scheme with none, an outline for a team color close
    // to what the badge sits on, so the badge keeps its shape.
    final fill = color ?? AppTokens.brand;
    final ring = c.avatarRing.a != 0
        ? c.avatarRing
        : url == null && ColorMath.contrast(fill, c.background) < 1.5
        ? c.outline
        : c.avatarRing;
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        // Over logo or color.
        foregroundDecoration: ring.a == 0
            ? null
            : BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: ring, width: 1.5),
              ),
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
                  errorBuilder: (_, _, _) => _initials(context),
                )
              : _initials(context),
        ),
      ),
    );
  }

  Widget _candy(BuildContext context, String? url) {
    // Inside the outline.
    final inside = size - 6;
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: CandyBox(
        color: color ?? AppTokens.brand,
        radius: size * 15 / 50,
        outline: 3,
        depth: 5,
        shine: Rect.fromLTWH(size * 0.1, size * 0.14, 4.5, size * 0.4),
        shineColor: Candy.tagFaceShine,
        width: size,
        height: size,
        clipChild: true,
        child: url != null
            ? Image(
                image: CoverResizeImage.forBox(
                  NetworkImage(url),
                  logicalWidth: inside,
                  logicalHeight: inside,
                  devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                ),
                fit: BoxFit.cover,
                width: inside,
                height: inside,
                errorBuilder: (_, _, _) => _initials(context),
              )
            : _initials(context),
      ),
    );
  }

  Widget _initials(BuildContext context) {
    final fill = color ?? AppTokens.brand;
    return ColoredBox(
      color: fill,
      child: Center(
        child: Text(
          Avatar.initialsOf(name),
          style: GumdropStyle.of(context).display(
            TextStyle(
              // White or black, whichever reads better on the team's color
              // (Carolina blue and gold are light), as chat bubbles do.
              color:
                  ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
                  ? Colors.white
                  : GumdropColors.of(context).ink,
              fontWeight: FontWeight.w400,
              fontSize: size * 0.54,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
