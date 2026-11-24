import 'dart:math' as math;

import 'package:battleplan/core/design/camp_palette.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Candy sprinkles on the header (#98, SPEC §7.4): rounded rods strewn over
/// the header's background, under its lettering, in candy colors, kept
/// off the status bar's clock and icons, the title, and the buttons.
///
/// A [SprinkleScope] around the header holds where they keep off: every
/// [SprinkleKeepOut] inside it (the title, the tag, each round button)
/// and, at the top, the status bar's ends. [SprinkleLayer] paints the
/// sprinkles in its box, skipping any within 5 px of those.
///
/// The rods are a fixed seed's, the same every time, on a 400 × 140 tile
/// repeated across: 40 to a tile, at least 15 apart, 3 wide and 6.4 to 9.2
/// long, at any angle. On a light camouflage (whose lettering is dark:
/// Light, Desert Tan) each sits on a 5.2 px rod of ink; on a dark one,
/// they're at 90%.
abstract final class CandySprinkles {
  /// One tile of rods, repeated across.
  static const Size tile = Size(400, 140);

  /// How far a rod keeps from a keep-out box.
  static const double margin = 5;

  /// The candy colors, in turn: lemon, pink, sky, mint, tangerine, grape.
  static const List<Color> colors = [
    Color(0xFFFFD43A),
    Color(0xFFFF6FB1),
    Color(0xFF35B0FF),
    Color(0xFF5ED36A),
    Color(0xFFFF9A2E),
    Color(0xFFB58BFF),
  ];

  static final List<SprinkleRod> _rods = _strew(seed: 7, count: 40);

  static final Map<int, List<SprinkleRod>> _more = {};

  /// The rods of a tile with [count] of them: the usual 40, or another
  /// fixed seed's (Sugar Rush's 50, #98).
  static List<SprinkleRod> rodsFor(int? count) => count == null || count == 40
      ? _rods
      : _more.putIfAbsent(count, () => _strew(seed: 19, count: count));

  /// The rods on one tile: [count] of them from [seed], at least 15 apart.
  static List<SprinkleRod> _strew({required int seed, required int count}) {
    final random = math.Random(seed);
    final rods = <SprinkleRod>[];
    var tries = 0;
    while (rods.length < count && tries < 5000) {
      tries++;
      final at = Offset(
        6 + random.nextDouble() * (tile.width - 12),
        6 + random.nextDouble() * (tile.height - 12),
      );
      if (rods.any((r) => (r.at - at).distance < 15)) continue;
      rods.add(
        SprinkleRod(
          at: at,
          angle: random.nextDouble() * math.pi,
          half: 3.2 + random.nextDouble() * 1.4,
          color: rods.length % colors.length,
        ),
      );
    }
    return rods;
  }

  /// The rods of one tile.
  static List<SprinkleRod> get rods => _rods;

  /// Whether sprinkles on [palette]'s header sit on ink rods: its lettering
  /// is dark, so its camouflage is light.
  static bool outlined(CampPalette palette) =>
      ColorMath.luminance(palette.headerLettering) < 0.18;

  /// Paints the sprinkles over [size], skipping any within [margin] of
  /// [keepOut].
  static void paint(
    Canvas canvas,
    Size size,
    CampPalette palette, {
    List<Rect> keepOut = const [],
  }) {
    final dark = !outlined(palette);
    // Sugar Rush's own colors and count (#98).
    final candies = palette.touches.sprinkles ?? colors;
    final rods = rodsFor(palette.touches.sprinkleCount);
    final rod = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final edge = Paint()
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..color = palette.ink;
    final clear = [for (final r in keepOut) r.inflate(margin)];
    for (var x = 0.0; x < size.width; x += tile.width) {
      for (var y = 0.0; y < size.height; y += tile.height) {
        for (final r in rods) {
          final at = r.at + Offset(x, y);
          if (at.dx > size.width - 4 || at.dy > size.height - 4) continue;
          final d = Offset(math.cos(r.angle), math.sin(r.angle)) * r.half;
          final a = at - d;
          final b = at + d;
          if (clear.any((k) => k.contains(a) || k.contains(b))) continue;
          if (!dark) canvas.drawLine(a, b, edge);
          final color = candies[r.color % candies.length];
          rod.color = dark ? color.withValues(alpha: 0.9) : color;
          canvas.drawLine(a, b, rod);
        }
      }
    }
  }
}

/// One sprinkle: a rod around [at], [half] long each way, turned [angle].
@immutable
class SprinkleRod {
  const new({
    required this.at,
    required this.angle,
    required this.half,
    required this.color,
  });

  final Offset at;
  final double angle;
  final double half;

  /// Which of [CandySprinkles.colors].
  final int color;
}

/// Where a header's sprinkles keep off (see [CandySprinkles]): the boxes
/// of the [SprinkleKeepOut]s inside it, which its [SprinkleLayer] reads
/// when it paints.
class SprinkleScope extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<SprinkleScope> createState() => _SprinkleScopeState();
}

class _SprinkleScopeState extends State<SprinkleScope> {
  final _registry = _SprinkleRegistry();

  @override
  Widget build(BuildContext context) =>
      _SprinkleRegistryScope(registry: _registry, child: widget.child);
}

class _SprinkleRegistryScope extends InheritedWidget {
  const new({required this.registry, required super.child});

  final _SprinkleRegistry registry;

  @override
  bool updateShouldNotify(_SprinkleRegistryScope old) =>
      old.registry != registry;
}

/// The keep-outs and the layers that paint around them.
class _SprinkleRegistry {
  final Set<RenderBox> keepOuts = {};
  final Set<RenderSprinkles> layers = {};

  void changed() {
    for (final layer in layers) {
      layer.markNeedsPaint();
    }
  }

  static _SprinkleRegistry? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SprinkleRegistryScope>()
      ?.registry;
}

/// Keeps the header's sprinkles off [child] (a title, a tag, a button).
/// Outside a [SprinkleScope] it does nothing.
class SprinkleKeepOut extends SingleChildRenderObjectWidget {
  const new({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSprinkleKeepOut._(_SprinkleRegistry.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSprinkleKeepOut renderObject,
  ) {
    renderObject._useRegistry(_SprinkleRegistry.of(context));
  }
}

/// The render object of a [SprinkleKeepOut].
class RenderSprinkleKeepOut extends RenderProxyBox {
  new _(this._registry);

  _SprinkleRegistry? _registry;

  void _useRegistry(_SprinkleRegistry? value) {
    if (value == _registry) return;
    _registry?.keepOuts.remove(this);
    _registry?.changed();
    _registry = value;
    if (attached) _registry?.keepOuts.add(this);
    _registry?.changed();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _registry?.keepOuts.add(this);
    _registry?.changed();
  }

  @override
  void detach() {
    _registry?.keepOuts.remove(this);
    _registry?.changed();
    super.detach();
  }

  @override
  void performLayout() {
    super.performLayout();
    // Where it is may have changed: the sprinkles paint around it again.
    _registry?.changed();
  }
}

/// Paints the header's sprinkles (see [CandySprinkles]) over its box, off
/// its [SprinkleScope]'s keep-outs, and off the ends of the [statusBar]
/// at its top, where the clock and the status icons are.
class SprinkleLayer extends LeafRenderObjectWidget {
  const new({required this.palette, this.statusBar = 0, super.key});

  final CampPalette palette;

  /// How tall the status bar over the header is; 0 for none.
  final double statusBar;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSprinkles._(_SprinkleRegistry.of(context), palette, statusBar);

  @override
  void updateRenderObject(BuildContext context, RenderSprinkles renderObject) {
    renderObject
      .._useRegistry(_SprinkleRegistry.of(context))
      ..palette = palette
      ..statusBar = statusBar;
  }
}

/// The render object of a [SprinkleLayer].
class RenderSprinkles extends RenderBox {
  new _(this._registry, this._palette, this._statusBar);

  _SprinkleRegistry? _registry;
  void _useRegistry(_SprinkleRegistry? value) {
    if (value == _registry) return;
    _registry?.layers.remove(this);
    _registry = value;
    if (attached) _registry?.layers.add(this);
    markNeedsPaint();
  }

  /// The scheme the sprinkles are drawn for.
  CampPalette get palette => _palette;
  CampPalette _palette;
  set palette(CampPalette value) {
    if (value == _palette) return;
    _palette = value;
    markNeedsPaint();
  }

  /// The status bar's height at the top.
  double get statusBar => _statusBar;
  double _statusBar;
  set statusBar(double value) {
    if (value == _statusBar) return;
    _statusBar = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _registry?.layers.add(this);
  }

  @override
  void detach() {
    _registry?.layers.remove(this);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    final keepOut = <Rect>[
      // The status bar's ends: the clock, and the signal and battery.
      if (_statusBar > 0) ...[
        Rect.fromLTWH(0, 0, size.width * 0.32, _statusBar),
        Rect.fromLTWH(size.width * 0.68, 0, size.width * 0.32, _statusBar),
      ],
      for (final box in _registry?.keepOuts ?? const <RenderBox>{})
        if (box.attached && box.hasSize)
          MatrixUtils.transformRect(
            box.getTransformTo(null),
            Offset.zero & box.size,
          ).shift(-localToGlobal(Offset.zero)),
    ];
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..clipRect(Offset.zero & size);
    CandySprinkles.paint(canvas, size, _palette, keepOut: keepOut);
    canvas.restore();
  }
}

/// A four-point twinkle (#98, SPEC §7.4), the logo's sparkle: a star with
/// pinched sides in [color], outlined in [ink] (1.7 in its 24 px box),
/// [size] across. Decoration only: screen readers skip it, and taps go
/// through it.
class Twinkle extends StatelessWidget {
  const new({
    required this.color,
    required this.ink,
    this.size = 20,
    super.key,
  });

  final Color color;
  final Color ink;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _TwinklePainter(color: color, ink: ink),
      ),
    ),
  );
}

class _TwinklePainter extends CustomPainter {
  const new({required this.color, required this.ink});

  final Color color;
  final Color ink;

  /// The star in a 24 box, as the mockup's twinkle draws it.
  static final Path _star = Path()
    ..moveTo(12, 1.2)
    ..cubicTo(12.9, 7.7, 16.3, 11.1, 22.8, 12)
    ..cubicTo(16.3, 12.9, 12.9, 16.3, 12, 22.8)
    ..cubicTo(11.1, 16.3, 7.7, 12.9, 1.2, 12)
    ..cubicTo(7.7, 11.1, 11.1, 7.7, 12, 1.2)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    // The 24 box with a unit of room around it for the outline, as the
    // mockup's 26-unit view box has it.
    final scale = size.shortestSide / 26;
    canvas
      ..save()
      ..scale(scale)
      ..translate(1, 1)
      ..drawPath(_star, Paint()..color = color)
      ..drawPath(
        _star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeJoin = StrokeJoin.round
          ..color = ink,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_TwinklePainter old) =>
      old.color != color || old.ink != ink;
}

/// The twinkles' two colors (#98): lemon and sky on a dark scheme, the
/// scheme's mustard and pink on a [light] one, where lemon wouldn't show,
/// or the scheme's own (Sugar Rush's lemon and sky).
({Color first, Color second}) twinkleColors(
  CampPalette palette, {
  required bool light,
}) {
  const lemon = Color(0xFFFFD43A);
  const sky = Color(0xFF8FD8FF);
  const pink = Color(0xFFFF7FBF);
  return palette.touches.twinkles ??
      (light
          ? (first: palette.mustard, second: pink)
          : (first: lemon, second: sky));
}

/// Where a twinkle sits over a piece ([Twinkled]): from its box's edges,
/// [size] across, in the first of [twinkleColors] or the [second].
@immutable
class TwinkleSpot {
  const new({
    required this.size,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.second = false,
  });

  final double size;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final bool second;
}

/// [child] with twinkles at its edges (#98, SPEC §7.4): a few, on good
/// news only (a Going! stamp, the countdown, the chat's game date, the
/// Going count), never over text, and still.
class Twinkled extends StatelessWidget {
  const new({required this.child, required this.spots, super.key});

  final Widget child;
  final List<TwinkleSpot> spots;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final colors = twinkleColors(
      c.roles.palette,
      light: c.brightness == Brightness.light,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        for (final s in spots)
          Positioned(
            left: s.left,
            top: s.top,
            right: s.right,
            bottom: s.bottom,
            child: Twinkle(
              color: s.second ? colors.second : colors.first,
              ink: c.ink,
              size: s.size,
            ),
          ),
      ],
    );
  }
}
