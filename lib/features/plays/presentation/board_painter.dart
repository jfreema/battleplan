import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/plays/domain/board_layout.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:material_ui/material_ui.dart';

/// Draws a play: its board's field, from the real measurements in
/// board_layout.dart, and what's drawn on it (BOARD-1, BOARD-2). The same
/// painter draws the editor, the viewer, and the small pictures in lists
/// and the chat (ARCH §6.14).
class PlayPainter extends CustomPainter {
  const new({
    required this.board,
    required this.variant,
    required this.elements,
    this.selectedId,
    this.draft,
    this.dark = false,
  });

  final PlayBoard board;
  final BoardVariant variant;
  final List<BoardElement> elements;

  /// The element picked in the editor, ringed.
  final String? selectedId;

  /// An arrow or line being drawn, not yet added.
  final BoardElement? draft;

  /// The blank board follows the theme; fields keep their colors.
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    // The whole field, of which [size] shows the board's frame.
    final frame = boardFrame(board);
    final field = Size(size.width / frame.width, size.height / frame.height);
    canvas.translate(-frame.left * field.width, -frame.top * field.height);
    switch (board) {
      case PlayBoard.baseball:
        _baseball(canvas, field);
      case PlayBoard.basketball:
        _basketball(canvas, field, variant);
      case PlayBoard.soccer:
        _soccer(canvas, field, variant);
      case PlayBoard.football:
        _football(canvas, field);
      case PlayBoard.blank:
        _blank(canvas, field, dark: dark);
    }
    // What's drawn on the field is sized by the board as shown, so it
    // stays the same size however much of the field is.
    final shown = size.width;
    final ink = inkFor(board, dark: dark);
    for (final e in [...elements, ?draft]) {
      switch (e) {
        case ArrowElement():
          _arrow(canvas, field, shown, e, ink, selected: e.id == selectedId);
        case LineElement():
          _line(canvas, field, shown, e, ink, selected: e.id == selectedId);
        case MarkerElement() || NoteElement():
          break;
      }
    }
    for (final e in elements) {
      switch (e) {
        case MarkerElement():
          _marker(canvas, field, shown, e, selected: e.id == selectedId);
        case NoteElement():
          _note(canvas, field, shown, e, ink, selected: e.id == selectedId);
        case ArrowElement() || LineElement():
          break;
      }
    }
  }

  @override
  bool shouldRepaint(PlayPainter old) =>
      old.board != board ||
      old.variant != variant ||
      old.elements != elements ||
      old.selectedId != selectedId ||
      old.draft != draft ||
      old.dark != dark;

  // ---- Elements --------------------------------------------------------------------

  /// A marker's radius on [board] shown [width] pixels across: big enough
  /// to read on a phone, still readable in a thumbnail. Football's are
  /// smaller, so a line's eleven stand side by side.
  static double markerRadius(double width, PlayBoard board) =>
      width * (board == PlayBoard.football ? 0.015 : 0.025);

  void _marker(
    Canvas canvas,
    Size field,
    double shown,
    MarkerElement m, {
    required bool selected,
  }) {
    final c = Offset(m.at.x * field.width, m.at.y * field.height);
    final r = markerRadius(shown, board);
    if (selected) {
      canvas.drawCircle(c, r * 1.45, Paint()..color = const Color(0xCCFFD43B));
    }
    final shadow = Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18);
    switch (m.side) {
      case MarkerSide.ball:
        final br = r * 0.55;
        canvas
          ..drawCircle(c + Offset(0, r * 0.08), br, shadow)
          ..drawCircle(c, br, Paint()..color = _ballColor)
          ..drawCircle(
            c,
            br,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1, br * 0.18)
              ..color = const Color(0xFF1F2937),
          );
        return;
      case MarkerSide.opponent when board == PlayBoard.football:
        // X's and O's: the defense is an X.
        final arm = r * 0.72;
        final x = Paint()
          ..color = Colors.white
          ..strokeWidth = r * 0.34
          ..strokeCap = StrokeCap.round;
        final xShadow = Paint()
          ..color = const Color(0x66000000)
          ..strokeWidth = r * 0.5
          ..strokeCap = StrokeCap.round;
        for (final p in [xShadow, x]) {
          canvas
            ..drawLine(c - Offset(arm, arm), c + Offset(arm, arm), p)
            ..drawLine(c + Offset(-arm, arm), c + Offset(arm, -arm), p);
        }
        _label(
          canvas,
          c + Offset(0, r * 1.25),
          m.label,
          r * 0.62,
          Colors.white,
        );
        return;
      case MarkerSide.team when board == PlayBoard.football:
        // The offense is an O.
        canvas
          ..drawCircle(c + Offset(0, r * 0.08), r, shadow)
          ..drawCircle(c, r, Paint()..color = Colors.white)
          ..drawCircle(
            c,
            r * 0.86,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.2
              ..color = const Color(0xFF1F2937),
          );
        _label(canvas, c, m.label, r * 0.78, const Color(0xFF111827));
        return;
      case MarkerSide.team || MarkerSide.opponent:
        final fill = m.side == MarkerSide.team ? _team : _opponent;
        canvas
          ..drawCircle(c + Offset(0, r * 0.08), r, shadow)
          ..drawCircle(c, r, Paint()..color = fill)
          ..drawCircle(
            c,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1.2, r * 0.12)
              ..color = Colors.white,
          );
        _label(canvas, c, m.label, r * 0.82, Colors.white);
    }
  }

  static const _team = Color(0xFF2F5BEA);
  static const _opponent = Color(0xFFDC2626);

  Color get _ballColor => switch (board) {
    PlayBoard.basketball => const Color(0xFFE8590C),
    PlayBoard.football => const Color(0xFF8B4513),
    _ => Colors.white,
  };

  /// [text] centered on [at], shrunk to fit a marker.
  static void _label(
    Canvas canvas,
    Offset at,
    String text,
    double size,
    Color color,
  ) {
    if (text.isEmpty) return;
    final fontSize = text.length <= 2
        ? size
        : size * 2 / text.length.clamp(2, 5);
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    p.paint(canvas, at - Offset(p.width / 2, p.height / 2));
  }

  /// An arrow's width on a board shown [width] pixels across.
  static double strokeFor(double width) => math.max(2.5, width * 0.005);

  void _arrow(
    Canvas canvas,
    Size field,
    double shown,
    ArrowElement a,
    Color ink, {
    required bool selected,
  }) {
    final pts = [
      for (final p in a.points) Offset(p.x * field.width, p.y * field.height),
    ];
    if (pts.length < 2) return;
    final w = strokeFor(shown);
    final path = _smooth(pts);
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (selected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x99FFD43B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 3.2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawPath(
      a.kind == ArrowKind.pass ? _dashed(path, w * 3) : path,
      paint,
    );
    final end = pts.last;
    final from = pts.length >= 2 ? pts[pts.length - 2] : pts.first;
    final angle = math.atan2(end.dy - from.dy, end.dx - from.dx);
    if (a.kind == ArrowKind.block) {
      // A block or screen ends in a T.
      final half = w * 3.2;
      final across = Offset(
        math.cos(angle + math.pi / 2),
        math.sin(angle + math.pi / 2),
      );
      canvas.drawLine(end - across * half, end + across * half, paint);
    } else {
      final head = w * 3.6;
      final tip = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - head * math.cos(angle - 0.45),
          end.dy - head * math.sin(angle - 0.45),
        )
        ..lineTo(
          end.dx - head * math.cos(angle + 0.45),
          end.dy - head * math.sin(angle + 0.45),
        )
        ..close();
      canvas.drawPath(tip, Paint()..color = ink);
    }
  }

  void _line(
    Canvas canvas,
    Size field,
    double shown,
    LineElement l,
    Color ink, {
    required bool selected,
  }) {
    final pts = [
      for (final p in l.points) Offset(p.x * field.width, p.y * field.height),
    ];
    if (pts.length < 2) return;
    final w = strokeFor(shown) * 0.85;
    final path = _smooth(pts);
    if (selected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x99FFD43B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 3.2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _note(
    Canvas canvas,
    Size field,
    double shown,
    NoteElement n,
    Color ink, {
    required bool selected,
  }) {
    final c = Offset(n.at.x * field.width, n.at.y * field.height);
    final fontSize = (shown * 0.0215).clamp(9.0, 20.0);
    final dark = ink.computeLuminance() > 0.5;
    final p = TextPainter(
      text: TextSpan(
        text: n.text,
        style: TextStyle(
          color: dark ? Colors.white : const Color(0xFF111827),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 4,
    )..layout(maxWidth: shown * 0.33);
    final box = Rect.fromCenter(
      center: c,
      width: p.width + fontSize,
      height: p.height + fontSize * 0.5,
    );
    final rrect = RRect.fromRectAndRadius(box, Radius.circular(fontSize * 0.4));
    if (selected) {
      canvas.drawRRect(
        rrect.inflate(fontSize * 0.25),
        Paint()..color = const Color(0xCCFFD43B),
      );
    }
    canvas.drawRRect(
      rrect,
      Paint()..color = dark ? const Color(0xB3111827) : const Color(0xE6FFFFFF),
    );
    p.paint(canvas, box.topLeft + Offset(fontSize / 2, fontSize * 0.25));
  }

  /// A smooth path through [pts]: each corner rounded through the midpoints.
  static Path _smooth(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 2) return path..lineTo(pts.last.dx, pts.last.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = (pts[i] + pts[i + 1]) / 2;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    return path..lineTo(pts.last.dx, pts.last.dy);
  }

  static Path _dashed(Path source, double dash) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        out.addPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          Offset.zero,
        );
        d += dash * 1.8;
      }
    }
    return out;
  }

  // ---- Fields ----------------------------------------------------------------------

  static Paint _fill(Color c) => Paint()..color = c;

  static Paint _chalk(double width, [Color color = Colors.white]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;

  /// Mowed grass: bands of two greens.
  static void _stripes(
    Canvas canvas,
    Rect area,
    int bands, {
    Color a = const Color(0xFF3F9145),
    Color b = const Color(0xFF47994D),
  }) {
    final h = area.height / bands;
    for (var i = 0; i < bands; i++) {
      canvas.drawRect(
        Rect.fromLTWH(area.left, area.top + i * h, area.width, h + 0.5),
        _fill(i.isEven ? a : b),
      );
    }
  }

  void _baseball(Canvas canvas, Size size) {
    final w = size.width;
    Offset o(BoardPoint p) => Offset(p.x * w, p.y * size.height);
    double ft(double feet) => BaseballField.w(feet) * w;
    const dirt = Color(0xFFC49A6C);
    const darkGrass = Color(0xFF2F6B35);
    final home = o(BaseballField.home);
    final left = o(BaseballField.leftPole);
    final right = o(BaseballField.rightPole);
    final center = o(BaseballField.center);
    // The fence: a curve through center field's deepest point.
    final control = center * 2 - (left + right) / 2;
    final fence = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(control.dx, control.dy, right.dx, right.dy);
    final fair = Path()
      ..moveTo(home.dx, home.dy)
      ..lineTo(left.dx, left.dy)
      ..quadraticBezierTo(control.dx, control.dy, right.dx, right.dy)
      ..close();

    // Foul territory and the stands' edge.
    canvas
      ..drawRect(Offset.zero & size, _fill(darkGrass))
      ..save()
      ..clipPath(fair);
    _stripes(canvas, Offset.zero & size, 14);
    // The warning track, inside the fence.
    canvas.drawPath(
      fence,
      Paint()
        ..color = dirt
        ..style = PaintingStyle.stroke
        ..strokeWidth = ft(30),
    );
    // The infield dirt: an arc 95 feet from the rubber.
    final mound = o(BaseballField.mound);
    canvas
      ..drawCircle(mound, ft(BaseballField.infieldArcFeet), _fill(dirt))
      ..restore()
      // Dirt runs around home, both sides of the lines.
      ..drawCircle(home, ft(13), _fill(dirt));

    // The infield grass: the diamond, a little inside the base paths.
    final f = o(BaseballField.first);
    final s = o(BaseballField.second);
    final t = o(BaseballField.third);
    final mid = (home + s) / 2;
    Offset inset(Offset p) => mid + (p - mid) * 0.84;
    final grass = Path()
      ..moveTo(inset(home).dx, inset(home).dy)
      ..lineTo(inset(f).dx, inset(f).dy)
      ..lineTo(inset(s).dx, inset(s).dy)
      ..lineTo(inset(t).dx, inset(t).dy)
      ..close();
    canvas.drawPath(grass, _fill(const Color(0xFF47994D)));
    // Cutouts of dirt around the bases, and the mound.
    for (final base in [f, s, t]) {
      canvas.drawCircle(base, ft(13), _fill(dirt));
    }
    canvas
      ..drawCircle(home, ft(13), _fill(dirt))
      ..drawCircle(mound, ft(9), _fill(dirt))
      ..drawRect(
        Rect.fromCenter(
          center: mound,
          width: ft(4),
          height: math.max(1.5, ft(1)),
        ),
        _fill(Colors.white),
      );

    final line = math.max(1.5, w * 0.004);
    // Foul lines, to the poles.
    canvas
      ..drawLine(home, left, _chalk(line))
      ..drawLine(home, right, _chalk(line))
      // The fence itself.
      ..drawPath(
        fence,
        _chalk(math.max(2, w * 0.008), const Color(0xFF1B4D24)),
      );
    // Batter's boxes.
    for (final side in [-1.0, 1.0]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: home + Offset(side * ft(4.2), -ft(0.5)),
          width: ft(4),
          height: ft(6),
        ),
        _chalk(line * 0.8),
      );
    }
    // Bases, white squares set on point.
    for (final base in [f, s, t]) {
      canvas
        ..save()
        ..translate(base.dx, base.dy)
        ..rotate(math.pi / 4)
        ..drawRect(
          Rect.fromCenter(center: Offset.zero, width: ft(5), height: ft(5)),
          _fill(Colors.white),
        )
        ..restore();
    }
    // Home plate: a five-sided plate, pointing at the catcher.
    final p = ft(2.4);
    final plate = Path()
      ..moveTo(home.dx - p / 2, home.dy - p / 2)
      ..lineTo(home.dx + p / 2, home.dy - p / 2)
      ..lineTo(home.dx + p / 2, home.dy)
      ..lineTo(home.dx, home.dy + p / 2)
      ..lineTo(home.dx - p / 2, home.dy)
      ..close();
    canvas.drawPath(plate, _fill(Colors.white));
  }

  void _basketball(Canvas canvas, Size size, BoardVariant v) {
    final full = v == BoardVariant.full;
    canvas.drawRect(Offset.zero & size, _fill(const Color(0xFFDDB07C)));
    // Floorboards.
    final board = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 1;
    for (var i = 1; i < 25; i++) {
      final x = size.width * i / 25;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), board);
    }
    _halfCourt(canvas, size, flip: false, full: full);
    if (full) _halfCourt(canvas, size, flip: true, full: full);
  }

  /// One end of the court, the basket at the top (or the bottom, [flip]).
  void _halfCourt(
    Canvas canvas,
    Size size, {
    required bool flip,
    required bool full,
  }) {
    final ftPx = size.width / BasketballCourt.widthFeet;
    final lengthFeet = BasketballCourt.halfFeet * (full ? 2 : 1);
    Offset o(double x, double y) =>
        Offset(x * ftPx, (flip ? lengthFeet - y : y) * ftPx);
    final line = math.max(1.5, size.width * 0.005);
    final chalk = _chalk(line);
    canvas.save();
    if (flip) {
      // Mirror the drawing about the half-court line.
      canvas
        ..translate(0, size.height)
        ..scale(1, -1);
    }
    Offset p(double x, double y) => Offset(x * ftPx, y * ftPx);
    // The lane, painted.
    final lane = Rect.fromLTWH(
      p(25 - BasketballCourt.laneWidthFeet / 2, 0).dx,
      0,
      BasketballCourt.laneWidthFeet * ftPx,
      BasketballCourt.laneLengthFeet * ftPx,
    );
    canvas
      ..drawRect(lane, _fill(const Color(0xFFC47F45)))
      ..drawRect(lane, chalk)
      // The free-throw circle.
      ..drawCircle(
        p(25, BasketballCourt.laneLengthFeet),
        BasketballCourt.freeThrowRadiusFeet * ftPx,
        chalk,
      );
    // The three-point line: straight in the corners, then the arc.
    final hoop = p(25, BasketballCourt.hoopFeet);
    final r = BasketballCourt.threeRadiusFeet * ftPx;
    const corner = BasketballCourt.threeCornerFeet;
    const dx = 25 - corner;
    final dy = math.sqrt(
      BasketballCourt.threeRadiusFeet * BasketballCourt.threeRadiusFeet -
          dx * dx,
    );
    final cornerY = BasketballCourt.hoopFeet + dy;
    canvas
      ..drawLine(p(corner, 0), p(corner, cornerY), chalk)
      ..drawLine(p(50 - corner, 0), p(50 - corner, cornerY), chalk);
    final start = math.atan2(dy, dx);
    canvas
      ..drawArc(
        Rect.fromCircle(center: hoop, radius: r),
        start,
        math.pi - 2 * start,
        false,
        chalk,
      )
      // The restricted area, the backboard, and the rim.
      ..drawArc(
        Rect.fromCircle(
          center: hoop,
          radius: BasketballCourt.restrictedFeet * ftPx,
        ),
        0,
        math.pi,
        false,
        chalk,
      )
      ..drawLine(p(22, 4), p(28, 4), _chalk(line * 1.8))
      ..drawCircle(
        hoop,
        0.75 * ftPx,
        _chalk(line * 1.2, const Color(0xFFE8590C)),
      );
    // The court's edge and the half-court line.
    final edge = full
        ? Rect.fromLTWH(0, 0, size.width, BasketballCourt.halfFeet * ftPx)
        : Offset.zero & size;
    canvas
      ..drawRect(edge.deflate(line / 2), chalk)
      ..restore();
    if (!flip) {
      // Center circle on the half-court line.
      final mid = o(25, BasketballCourt.halfFeet);
      canvas.drawCircle(mid, BasketballCourt.centerRadiusFeet * ftPx, chalk);
    }
  }

  void _soccer(Canvas canvas, Size size, BoardVariant v) {
    final half = v == BoardVariant.half;
    final m = size.width / SoccerPitch.widthMeters;
    _stripes(
      canvas,
      Offset.zero & size,
      half ? 6 : 12,
      a: const Color(0xFF3B8F43),
      b: const Color(0xFF42994A),
    );
    final line = math.max(1.5, size.width * 0.005);
    final chalk = _chalk(line);
    const length = SoccerPitch.lengthMeters;
    canvas.drawRect((Offset.zero & size).deflate(line / 2), chalk);
    // Each end the board shows: the top always, the bottom on the full
    // pitch.
    for (final top in [true, if (!half) false]) {
      double y(double meters) => (top ? meters : length - meters) * m;
      final dir = top ? 1.0 : -1.0;
      void box(double width, double depth) {
        final x0 = (SoccerPitch.widthMeters - width) / 2 * m;
        canvas.drawRect(
          Rect.fromPoints(Offset(x0, y(0)), Offset(x0 + width * m, y(depth))),
          chalk,
        );
      }

      box(SoccerPitch.penaltyWidth, SoccerPitch.penaltyDepth);
      box(SoccerPitch.goalAreaWidth, SoccerPitch.goalAreaDepth);
      final spot = Offset(
        SoccerPitch.widthMeters / 2 * m,
        y(SoccerPitch.penaltySpot),
      );
      canvas.drawCircle(spot, line * 1.2, _fill(Colors.white));
      // The penalty arc, outside the box.
      const dy = SoccerPitch.penaltyDepth - SoccerPitch.penaltySpot;
      final a = math.asin(dy / SoccerPitch.circleRadius);
      canvas.drawArc(
        Rect.fromCircle(center: spot, radius: SoccerPitch.circleRadius * m),
        top ? a : -math.pi + a,
        math.pi - 2 * a,
        false,
        chalk,
      );
      // The goal, on the line.
      final g = SoccerPitch.goalWidth / 2 * m;
      final gx = SoccerPitch.widthMeters / 2 * m;
      canvas.drawLine(
        Offset(gx - g, y(0) + dir * line),
        Offset(gx + g, y(0) + dir * line),
        _chalk(line * 2.6),
      );
      // Corner arcs.
      for (final cx in [0.0, size.width]) {
        canvas.drawCircle(Offset(cx, y(0)), 1 * m, chalk);
      }
    }
    // Halfway line and the center circle (half of it on the half pitch).
    final halfway = length / 2 * m;
    canvas
      ..drawLine(Offset(0, halfway), Offset(size.width, halfway), chalk)
      ..drawCircle(
        Offset(size.width / 2, halfway),
        SoccerPitch.circleRadius * m,
        chalk,
      )
      ..drawCircle(
        Offset(size.width / 2, halfway),
        line * 1.2,
        _fill(Colors.white),
      );
  }

  void _football(Canvas canvas, Size size) {
    final yd = size.width / FootballField.widthYards;
    // Five-yard bands, alternating greens.
    for (var i = 0; i < FootballField.windowYards / 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * 5 * yd, size.width, 5 * yd + 0.5),
        _fill(i.isEven ? const Color(0xFF3B8F43) : const Color(0xFF42994A)),
      );
    }
    final line = math.max(1.5, size.width * 0.004);
    final chalk = _chalk(line);
    for (var y = 0; y <= FootballField.windowYards; y++) {
      final py = y * yd;
      if (y % 5 == 0) {
        canvas.drawLine(Offset(0, py), Offset(size.width, py), chalk);
      } else {
        // Hash marks, and the ticks along each sideline.
        final tick = 0.7 * yd;
        for (final x in [FootballField.leftHash, FootballField.rightHash]) {
          canvas.drawLine(
            Offset(x * yd - tick / 2, py),
            Offset(x * yd + tick / 2, py),
            chalk,
          );
        }
        canvas
          ..drawLine(Offset(0, py), Offset(tick, py), chalk)
          ..drawLine(
            Offset(size.width - tick, py),
            Offset(size.width, py),
            chalk,
          );
      }
    }
    // The line of scrimmage, and the line to gain.
    final los = FootballField.scrimmageYards * yd;
    canvas
      ..drawLine(
        Offset(0, los),
        Offset(size.width, los),
        _chalk(line * 1.8, const Color(0xE63B82F6)),
      )
      ..drawLine(
        Offset(0, los - 10 * yd),
        Offset(size.width, los - 10 * yd),
        _chalk(line * 1.8, const Color(0xE6FACC15)),
      );
  }

  void _blank(Canvas canvas, Size size, {required bool dark}) {
    canvas.drawRect(
      Offset.zero & size,
      _fill(dark ? const Color(0xFF1F2933) : const Color(0xFFF8F6F0)),
    );
    final grid = Paint()
      ..color = dark ? const Color(0x1AFFFFFF) : const Color(0x14000000)
      ..strokeWidth = 1;
    final step = size.width / 16;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }
}

/// The color arrows, lines, and notes are drawn in on [board]: chalk white
/// on grass, dark on wood or a light board.
Color inkFor(PlayBoard board, {required bool dark}) => switch (board) {
  PlayBoard.baseball || PlayBoard.soccer || PlayBoard.football => Colors.white,
  PlayBoard.basketball => const Color(0xFF1F2937),
  PlayBoard.blank => dark ? Colors.white : const Color(0xFF1F2937),
};
