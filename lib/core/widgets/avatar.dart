import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/widgets/cover_image.dart';
import 'package:material_ui/material_ui.dart';

/// A person's photo, or their initials on the color they picked ([color],
/// SET-8), or else one derived from a stable key (SPEC §7.5).
class Avatar extends StatelessWidget {
  const new({
    required this.name,
    this.colorKey,
    this.imageUrl,
    this.color,
    this.size = 40,
    super.key,
  });

  final String name;

  /// The icon color the person picked; null for the hashed one.
  final AvatarColor? color;

  /// Keeps a person's color the same everywhere (their uid, usually).
  final String? colorKey;
  final String? imageUrl;
  final double size;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  /// The candy color for [key] (Gumdrop Pop design §3.9: circles in an
  /// accent with ink initials), the same for a person everywhere, in every
  /// scheme: people's colors are who they are, like team colors, so Boot
  /// Camp Mix's own reds and blues (#85) don't change them.
  static Color colorFor(GumdropColors colors, String key) {
    const palette = [
      CandyFaces.blueRaspberry,
      CandyFaces.lemon,
      CandyFaces.mint,
      CandyFaces.grape,
      CandyFaces.bubblegum,
      CandyFaces.tangerine,
      // "Cherry" is coral, as it always looked: the warning red went
      // deeper in #12 (2026-11-16), and icons kept their colors.
      CandyFaces.coral,
    ];
    var hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }

  /// The candy face of [color], the same in every scheme (#85).
  static Color faceOf(GumdropColors colors, AvatarColor color) =>
      switch (color) {
        AvatarColor.blueRaspberry => CandyFaces.blueRaspberry,
        AvatarColor.lemon => CandyFaces.lemon,
        AvatarColor.mint => CandyFaces.mint,
        AvatarColor.grape => CandyFaces.grape,
        AvatarColor.bubblegum => CandyFaces.bubblegum,
        AvatarColor.tangerine => CandyFaces.tangerine,
        // Coral, as it looked when they picked it (#12).
        AvatarColor.cherry => CandyFaces.coral,
      };

  /// The color the icon shows: [picked], else the one hashed from [key].
  static Color fillOf(GumdropColors colors, AvatarColor? picked, String key) =>
      picked == null ? colorFor(colors, key) : faceOf(colors, picked);

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final ring = GumdropColors.of(context).avatarRing;
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        // The scheme's thin inset ring (Light blue's), photo or initials.
        foregroundDecoration: ring.a == 0
            ? null
            : BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: size >= 96 ? 2 : 1.5),
              ),
        child: ClipOval(
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

  Widget _initials(BuildContext context) {
    final colors = GumdropColors.of(context);
    return ColoredBox(
      color: fillOf(colors, color, colorKey ?? name),
      child: Center(
        child: Text(
          initialsOf(name),
          maxLines: 1,
          // The circle doesn't grow with the text size, so its initials
          // don't either, or big text would clip them.
          textScaler: TextScaler.noScaling,
          style: GumdropStyle.of(context).label(
            TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: size * 0.38,
              height: 1,
              color: colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
