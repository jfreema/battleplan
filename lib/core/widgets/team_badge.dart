import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/avatar.dart';
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
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  // Decoded at the size it's drawn, not the upload's.
                  cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                      .ceil(),
                  errorBuilder: (_, _, _) => _initials(),
                )
              : _initials(),
        ),
      ),
    );
  }

  Widget _initials() => ColoredBox(
    color: color ?? AppTokens.brand,
    child: Center(
      child: Text(
        Avatar.initialsOf(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    ),
  );
}
