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

  static const _palette = [
    Color(0xFF2F5BEA),
    Color(0xFF0F8A5F),
    Color(0xFFC2410C),
    Color(0xFF7C3AED),
    Color(0xFF0E7490),
    Color(0xFFBE185D),
    Color(0xFFA16207),
    Color(0xFF334155),
  ];

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  static Color colorFor(String key) {
    var hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
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
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _initials(),
                )
              : _initials(),
        ),
      ),
    );
  }

  Widget _initials() => ColoredBox(
    color: colorFor(colorKey ?? name),
    child: Center(
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.38,
        ),
      ),
    ),
  );
}
