import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/camp_palette.dart';
import 'package:material_ui/material_ui.dart';

part 'header_pattern_data.dart';

/// The header backgrounds besides the camouflage (#91, owner's request
/// 2026-11-23: "Add a few alternate backgrounds for the headers [in] the
/// theme editor that allows further customization to themes"; SPEC
/// ADMIN-10): digital camouflage, a topo map, a playbook, hazard stripes,
/// and a halftone, each drawn from only the scheme's four camouflage colors
/// (ground, big, mid, small), so the header's lettering reads on it as on
/// the camouflage. Each is the mockups' 400 by 140 tile (their generator,
/// `mk_headers.py`), drawn to cover the header, centered; the seeded parts
/// are its own output (`header_pattern_data.dart`).
class HeaderPatternPainter extends CustomPainter {
  new(this.style, this.palette)
    : assert(style != HeaderStyle.camo, 'the camouflage is CamoPainter');

  final HeaderStyle style;
  final CampPalette palette;

  /// The pattern's tile, in its own units.
  static const Size tile = Size(400, 140);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..drawRect(Offset.zero & size, Paint()..color = palette.camoGround);
    final scale = math.max(size.width / tile.width, size.height / tile.height);
    canvas
      ..translate(
        (size.width - tile.width * scale) / 2,
        (size.height - tile.height * scale) / 2,
      )
      ..scale(scale);
    switch (style) {
      case HeaderStyle.digital:
        _digital(canvas);
      case HeaderStyle.topo:
        _topo(canvas);
      case HeaderStyle.playbook:
        _playbook(canvas);
      case HeaderStyle.stripes:
        _stripes(canvas);
      case HeaderStyle.halftone:
        _halftone(canvas);
      case HeaderStyle.camo:
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(HeaderPatternPainter old) =>
      old.style != style || old.palette != palette;

  Paint _fill(Color color) => Paint()..color = color;

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Square-pixel camouflage: 7-unit cells in the big, mid and small colors.
  void _digital(Canvas canvas) {
    const cell = 7.0;
    final paths = [Path(), Path(), Path()];
    for (final (y, row) in _digitalRows.indexed) {
      for (var x = 0; x < row.length; x++) {
        final v = row.codeUnitAt(x) - 48;
        if (v > 0) {
          paths[v - 1].addRect(Rect.fromLTWH(x * cell, y * cell, cell, cell));
        }
      }
    }
    for (final (i, color) in [
      palette.camoBig,
      palette.camoMid,
      palette.camoSmall,
    ].indexed) {
      canvas.drawPath(paths[i], _fill(color));
    }
  }

  /// A wobbly ring around ([cx], [cy]) of radius [r], [sx] times as wide as
  /// tall, through 14 points pulled in or out by [wobble]: the mockups'
  /// smooth closed curve through them.
  static Path _ring(
    double cx,
    double cy,
    double r,
    double sx,
    List<double> wobble,
  ) {
    final n = wobble.length;
    final pts = [
      for (var i = 0; i < n; i++)
        Offset(
          cx + r * (1 + wobble[i]) * math.cos(2 * math.pi * i / n) * sx,
          cy + r * (1 + wobble[i]) * math.sin(2 * math.pi * i / n),
        ),
    ];
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      final p3 = pts[(i + 2) % n];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  /// A topographic map: rings in the mid color around seven hills, every
  /// fourth heavier with a small-color shadow.
  void _topo(Canvas canvas) {
    final thin = Path();
    final thick = Path();
    for (final r in _topoRings) {
      final ring = _ring(r[0], r[1], r[2], r[3], r.sublist(5));
      (r[4] == 1 ? thick : thin).addPath(ring, Offset.zero);
    }
    canvas
      ..drawPath(thin, _stroke(palette.camoMid, 1.3))
      ..drawPath(thick, _stroke(palette.camoMid, 2.6))
      ..drawPath(
        thick.shift(const Offset(1.5, 1.5)),
        _stroke(palette.camoSmall.withValues(alpha: 0.7), 1),
      );
  }

  /// A coach's chalkboard: big-color smudges, then X's, O's, and dashed
  /// routes with arrowheads in the mid color.
  void _playbook(Canvas canvas) {
    final smudges = Path();
    for (final s in _playbookSmudges) {
      smudges.addPath(_ring(s[0], s[1], s[2], s[3], s.sublist(4)), Offset.zero);
    }
    canvas.drawPath(smudges, _fill(palette.camoBig));
    final mid = palette.camoMid;
    final route = _stroke(mid, 2.2);
    for (final m in _playbookMarks) {
      final (start, control, end) = (
        Offset(m[3], m[4]),
        Offset(m[5], m[6]),
        Offset(m[7], m[8]),
      );
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(_dashed(path, 5, 5), route);
      final a = math.atan2(end.dy - control.dy, end.dx - control.dx);
      Offset at(double turn) =>
          end + Offset(math.cos(a + turn), math.sin(a + turn)) * 6;
      final head = Path()
        ..moveTo(at(0).dx, at(0).dy)
        ..lineTo(at(2.5).dx, at(2.5).dy)
        ..lineTo(at(-2.5).dx, at(-2.5).dy)
        ..close();
      canvas.drawPath(head, _fill(mid));
    }
    for (final m in _playbookMarks) {
      final c = Offset(m[1], m[2]);
      if (m[0] == 1) {
        canvas.drawCircle(c, 7, _stroke(mid, 2.6));
      } else {
        final x = _stroke(mid, 2.8);
        canvas
          ..drawLine(c + const Offset(-6, -6), c + const Offset(6, 6), x)
          ..drawLine(c + const Offset(6, -6), c + const Offset(-6, 6), x);
      }
    }
  }

  /// [source] as dashes [dash] long, [gap] apart.
  static Path _dashed(Path source, double dash, double gap) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        out.addPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          Offset.zero,
        );
      }
    }
    return out;
  }

  /// Hazard stripes: 45° bands of big and ground every 44 units across, a
  /// mid stripe in each ground band and a small hairline before each big.
  void _stripes(Canvas canvas) {
    const period = 44.0;
    final h = tile.height;
    final bands = Path();
    final mids = Path();
    final hairs = Path();
    Path slant(double x0, double width) => Path()
      ..moveTo(x0, 0)
      ..lineTo(x0 + width, 0)
      ..lineTo(x0 + width - h, h)
      ..lineTo(x0 - h, h)
      ..close();
    for (var k = -6; k < tile.width ~/ period + 6; k++) {
      final x0 = k * period;
      bands.addPath(slant(x0, period / 2), Offset.zero);
      mids.addPath(slant(x0 + period / 2 + 4, 5), Offset.zero);
      hairs.addPath(slant(x0 - 3, 1.6), Offset.zero);
    }
    canvas
      ..drawPath(bands, _fill(palette.camoBig))
      ..drawPath(mids, _fill(palette.camoMid))
      ..drawPath(hairs, _fill(palette.camoSmall));
  }

  /// A comic halftone: a big-color wash over the right, mid dots swelling
  /// toward the top right, and a scatter of small dots where they fade.
  void _halftone(Canvas canvas) {
    final (w, h) = (tile.width, tile.height);
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(w * 0.45, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h)
        ..close(),
      _fill(palette.camoBig.withValues(alpha: palette.camoBig.a * 0.55)),
    );
    const step = 10.0;
    final dots = Path();
    final specks = Path();
    for (var j = 0; j < h ~/ step + 2; j++) {
      for (var i = 0; i < w ~/ step + 2; i++) {
        final x = i * step + (j.isOdd ? step / 2 : 0);
        final y = j * step;
        final t = ((x / w) * 0.8 + (1 - y / h) * 0.45 - 0.1).clamp(0.0, 1.0);
        final r = 4.6 * t;
        if (r > 0.5) {
          dots.addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
        } else if ((i + j) % 3 == 0) {
          specks.addOval(Rect.fromCircle(center: Offset(x, y), radius: 1));
        }
      }
    }
    canvas
      ..drawPath(dots, _fill(palette.camoMid))
      ..drawPath(specks, _fill(palette.camoSmall));
  }
}
