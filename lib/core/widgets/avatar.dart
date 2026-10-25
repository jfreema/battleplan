import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/widgets/cover_image.dart';
import 'package:material_ui/material_ui.dart';

/// A person's photo, or their initials on a color derived from a stable key
/// (SPEC §7.5).
class Avatar extends StatelessWidget {
  const new({
    required this.name,
    this.colorKey,
    this.imageUrl,
    this.size = 40,
    super.key,
  });

  final String name;

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
  /// accent with ink initials), the same for a person everywhere.
  static Color colorFor(GumdropColors colors, String key) {
    final palette = [
      colors.blueRaspberry,
      colors.lemon,
      colors.mint,
      colors.grape,
      colors.bubblegum,
      colors.tangerine,
      colors.cherry,
    ];
    var hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length].face;
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
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
      color: colorFor(colors, colorKey ?? name),
      child: Center(
        child: Text(
          initialsOf(name),
          maxLines: 1,
          style: TextStyle(
            fontFamily: AppFonts.label,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.38,
            height: 1,
            color: colors.ink,
          ),
        ),
      ),
    );
  }
}
