import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/widgets/header_patterns.dart';
import 'package:material_ui/material_ui.dart';

/// Boot Camp Mix's camouflage header (#85, SPEC §7.4): [child] on the
/// scheme's camouflage, three layers of soft blotches on its ground color
/// with a halftone fading in from the top right, and a 3 px ink line
/// under it. The pattern is our own, drawn here, never a real one.
///
/// The team header, Teams, Profile, and every pushed screen's top bar sit
/// on it; with [top] it reaches up under the status bar.
class CampHeader extends StatelessWidget {
  const new({required this.child, this.top = true, super.key});

  final Widget child;

  /// Whether it fills the status bar's room above [child] too.
  final bool top;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final p = c.roles.palette;
    // The ink line over the pattern, which fills to the bottom edge.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.ink, width: 3)),
      ),
      child: CustomPaint(
        // The theme editor's header background, if it set one (#91); the
        // Super Admin Panel's is always the camouflage, as it ships.
        painter: CamoPainter(
          p,
          style: c.shipped
              ? HeaderStyle.camo
              : ThemeCatalog.headerStyleOf(c.scheme),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: top ? MediaQuery.paddingOf(context).top : 0,
            bottom: 3,
          ),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: top,
            child: CampHeaderTheme(child: child),
          ),
        ),
      ),
    );
  }
}

/// Paints the camouflage: blotches in [palette]'s three camouflage colors
/// over its ground, and the header's halftone. The same blotches every
/// time (a fixed seed), repeated across wide screens. With another [style]
/// (#91, the theme editor's header backgrounds), that pattern in the same
/// four colors instead of the blotches (`HeaderPatternPainter`), under the
/// same halftone.
class CamoPainter extends CustomPainter {
  new(this.palette, {this.style = HeaderStyle.camo});

  final CampPalette palette;
  final HeaderStyle style;

  /// One tile of the pattern, repeated across.
  static const Size tile = Size(260, 150);

  static final List<_Blot> _blots = _layout();

  static List<_Blot> _layout() {
    final random = math.Random(85);
    final blots = <_Blot>[];
    // Big, then mid, then small blotches, each layer over the last.
    for (final (layer, count, minR, maxR) in [
      (0, 7, 26.0, 42.0),
      (1, 9, 16.0, 28.0),
      (2, 12, 7.0, 15.0),
    ]) {
      for (var i = 0; i < count; i++) {
        final center = Offset(
          random.nextDouble() * tile.width,
          random.nextDouble() * tile.height,
        );
        final radius = minR + random.nextDouble() * (maxR - minR);
        final stretch = 1.2 + random.nextDouble() * 0.9;
        final turn = random.nextDouble() * math.pi;
        final points = 7 + random.nextInt(3);
        final wobble = [
          for (var k = 0; k < points; k++) 0.62 + random.nextDouble() * 0.5,
        ];
        blots.add(_Blot(layer, center, radius, stretch, turn, wobble));
      }
    }
    return blots;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    if (style != HeaderStyle.camo) {
      HeaderPatternPainter(style, palette).paint(canvas, size);
      _halftone(canvas, size);
      canvas.restore();
      return;
    }
    // The ground under the blotches, so it's whole wherever it's drawn
    // (the theme editor's swatches, #91, as well as the header).
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.camoGround);
    final colors = [palette.camoBig, palette.camoMid, palette.camoSmall];
    // From a tile up and left of the corner, so blots that spill over a
    // tile's edge show on its neighbor and tiles join without seams.
    for (final blot in _blots) {
      final paint = Paint()..color = colors[blot.layer];
      for (var x = -tile.width; x < size.width; x += tile.width) {
        for (var y = -tile.height; y < size.height; y += tile.height) {
          canvas.drawPath(blot.path(Offset(x, y)), paint);
        }
      }
    }
    _halftone(canvas, size);
    canvas.restore();
  }

  /// Dots on a 9 px grid, fading out from the top right corner.
  void _halftone(Canvas canvas, Size size) {
    const step = 9.0;
    final corner = Offset(size.width, 0);
    final reach = math.max(size.width * 0.66, 120);
    final paint = Paint();
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        final fade = 1 - (Offset(x, y) - corner).distance / reach;
        if (fade <= 0) continue;
        paint.color = palette.headerHalftone.withValues(
          alpha: palette.headerHalftone.a * fade.clamp(0, 1),
        );
        canvas.drawCircle(Offset(x, y), 1.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CamoPainter old) =>
      old.palette != palette || old.style != style;
}

/// One blotch: a soft lump around [center], stretched and turned.
class _Blot {
  new(
    this.layer,
    this.center,
    this.radius,
    this.stretch,
    this.turn,
    this.wobble,
  );

  final int layer;
  final Offset center;
  final double radius;
  final double stretch;
  final double turn;
  final List<double> wobble;

  Path path(Offset origin) {
    final n = wobble.length;
    final points = [
      for (var k = 0; k < n; k++)
        () {
          final a = 2 * math.pi * k / n;
          final r = radius * wobble[k];
          final local = Offset(math.cos(a) * r * stretch, math.sin(a) * r);
          // Turned, then moved to its place.
          final x = local.dx * math.cos(turn) - local.dy * math.sin(turn);
          final y = local.dx * math.sin(turn) + local.dy * math.cos(turn);
          return origin + center + Offset(x, y);
        }(),
    ];
    // A smooth closed curve through the midpoints, the points as handles.
    final path = Path();
    Offset mid(int i) => (points[i % n] + points[(i + 1) % n]) / 2;
    path.moveTo(mid(0).dx, mid(0).dy);
    for (var i = 1; i <= n; i++) {
      final p = points[i % n];
      final m = mid(i);
      path.quadraticBezierTo(p.dx, p.dy, m.dx, m.dy);
    }
    return path..close();
  }
}

/// A grid of round dots (#85, SPEC §7.4): the page's 8 px grid
/// (`CampPalette.pageDots`), or the halftone on a colored block, like an
/// event's header or date pennant. Drawn over whatever is under it.
class DotGridPainter extends CustomPainter {
  new({required this.color, this.spacing = 8, this.radius = 1.15});

  final Color color;

  /// From one dot's middle to the next.
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;
    final paint = Paint()..color = color;
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DotGridPainter old) =>
      old.color != color || old.spacing != spacing || old.radius != radius;
}

/// [child] on the page's 8 px dot grid (#85), drawn behind it.
class PageDots extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: DotGridPainter(
      color: GumdropColors.of(context).roles.palette.pageDots,
    ),
    child: child,
  );
}

/// [child] lettered for the camouflage (#86): where the scheme's header
/// lettering isn't its page's text (Sky Blue's white on its blue
/// camouflage, over a page lettered in navy), the page's text colors, the
/// icons, and the app bar's lettering take the header's. Elsewhere it's
/// [child] as it is.
class CampHeaderTheme extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = GumdropColors.of(context);
    final lettering = c.roles.palette.headerLettering;
    if (c.onCard || lettering == c.textOnPage) return child;
    final muted = lettering.withValues(alpha: 0.86);
    final header = c.copyWith(
      textOnPage: lettering,
      textPrimary: lettering,
      headingText: lettering,
      textMutedOnPage: muted,
    );
    return Theme(
      data: theme.copyWith(
        extensions: [
          for (final e in theme.extensions.values)
            if (e is GumdropColors) header else e,
        ],
        iconTheme: theme.iconTheme.copyWith(color: lettering),
        appBarTheme: theme.appBarTheme.copyWith(
          foregroundColor: lettering,
          iconTheme: IconThemeData(color: lettering),
          actionsIconTheme: IconThemeData(color: lettering),
          titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
            color: lettering,
          ),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: lettering),
        child: IconTheme.merge(
          data: IconThemeData(color: lettering),
          child: child,
        ),
      ),
    );
  }
}
