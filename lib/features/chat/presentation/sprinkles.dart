import 'dart:math' as math;

import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// The chat's Sprinkles background (CHAT-18, Gumdrop Pop's chat look):
/// small rounded dashes in the six candy colors, scattered at fixed angles
/// over the page color at 80% opacity. The same tile repeats, so it draws
/// the same every time.
class Sprinkles extends StatelessWidget {
  const new({required this.colors, this.scale = 1.5, super.key});

  final GumdropColors colors;

  /// The design's 96 × 64 thumbnail tile, scaled up for the chat.
  final double scale;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: SprinklesPainter([
        colors.blueRaspberry.face,
        colors.bubblegum.face,
        colors.lemon.face,
        colors.mint.face,
        colors.tangerine.face,
        colors.grape.face,
      ], scale: scale),
      child: const SizedBox.expand(),
    ),
  );
}

/// Paints [Sprinkles]: the design's tile of 34 dashes, 9 × 3.4 with round
/// ends, each centered and turned as in the thumbnail, in [palette] by
/// turns, repeated across the canvas.
class SprinklesPainter extends CustomPainter {
  new(this.palette, {this.scale = 1.5});

  /// The colors the dashes take in turn.
  final List<Color> palette;
  final double scale;

  static const _tile = Size(96, 64);
  static const _dash = Size(9, 3.4);

  /// Each dash's center and angle in degrees, from the design's thumbnail.
  static const List<(double, double, double)> _dashes = [
    (34.1, 13.5, 121), (59.9, 9.5, 178), (50.8, 24.7, 170), //
    (13.1, 32.1, 16), (11.5, 28.2, 15), (14.0, 10.4, 179),
    (42.0, 48.7, 79), (18.3, 17.3, 165), (58.1, 55.0, 147),
    (54.1, 26.3, 174), (85.6, 8.1, 114), (76.3, 20.8, 72),
    (19.9, 11.8, 98), (32.9, 48.1, 171), (22.8, 35.9, 88),
    (59.0, 25.1, 5), (51.8, 9.0, 118), (13.2, 16.4, 90),
    (62.3, 27.9, 43), (33.3, 36.1, 156), (44.3, 21.3, 29),
    (71.3, 42.0, 126), (27.8, 35.6, 15), (50.0, 51.2, 55),
    (66.1, 20.7, 73), (85.9, 11.8, 33), (41.5, 45.1, 63),
    (20.5, 31.1, 101), (11.6, 40.4, 100), (68.9, 35.5, 127),
    (77.7, 22.0, 20), (63.4, 36.6, 42), (54.3, 29.4, 114),
    (74.9, 54.8, 102),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (palette.isEmpty || size.isEmpty) return;
    final tileW = _tile.width * scale;
    final tileH = _tile.height * scale;
    final dash = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: _dash.width * scale,
        height: _dash.height * scale,
      ),
      Radius.circular(_dash.height * scale / 2),
    );
    final paints = [for (final c in palette) Paint()..color = c];
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      // The whole scatter at 80%, as one layer, so overlaps don't darken.
      ..saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.8),
      );
    // Rows offset by half a tile, and every other tile turned half way
    // round, so the repeat doesn't line up in columns.
    var row = 0;
    for (var y = 0.0; y < size.height; y += tileH, row++) {
      final shift = row.isOdd ? -tileW / 2 : 0.0;
      var column = 0;
      for (var x = shift; x < size.width; x += tileW, column++) {
        final turned = (row + column).isOdd;
        for (final (i, (cx, cy, deg)) in _dashes.indexed) {
          final px = turned ? _tile.width - cx : cx;
          final py = turned ? _tile.height - cy : cy;
          canvas
            ..save()
            ..translate(x + px * scale, y + py * scale)
            ..rotate(deg * math.pi / 180)
            ..drawRRect(dash, paints[(i + (turned ? 3 : 0)) % paints.length])
            ..restore();
        }
      }
    }
    canvas
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(SprinklesPainter old) =>
      old.scale != scale || !_same(old.palette, palette);

  static bool _same(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
