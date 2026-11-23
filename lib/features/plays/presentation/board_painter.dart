import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/features/plays/domain/board_layout.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:material_ui/material_ui.dart';

/// Boot Camp Mix's board pieces (#87), as the mockup draws them (style 31's
/// Plays): every piece in a heavy ink edge, like the rest of Boot Camp. The
/// same on every board and in every scheme, as the fields are.
abstract final class BoardPieces {
  /// Every edge, and the lettering on the pieces.
  static const ink = Color(0xFF1A1A18);

  /// Our team's players.
  static const team = Color(0xFF7DB7DA);

  /// The other team's, and baseball's batter and runners.
  static const opponent = Color(0xFFEF6A52);

  /// Arrows, lines, notes, the ball, and football's X's and O's: chalk over
  /// the ink.
  static const chalk = Color(0xFFFFFFFF);

  /// What's picked in the editor.
  static const pick = Color(0xFFF2C230);
}

/// The order arrows and lines are drawn in, as the mockup draws them: what's
/// picked ringed in mustard, then the ink under every one, then the chalk
/// over them all, so where two cross their chalk runs over both.
enum _Pass { pick, ink, chalk }

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
      case PlayBoard.volleyball:
        _volleyball(canvas, field, variant);
      case PlayBoard.blank:
        _blank(canvas, field, dark: dark);
    }
    // What's drawn on the field is sized by the board as shown, so it
    // stays the same size however much of the field is.
    final shown = size.width;
    final strokes = [
      for (final e in [...elements, ?draft])
        if (e is ArrowElement || e is LineElement) e,
    ];
    for (final pass in _Pass.values) {
      for (final e in strokes) {
        if (pass == _Pass.pick && e.id != selectedId) continue;
        switch (e) {
          case ArrowElement():
            _arrow(canvas, field, shown, e, pass);
          case LineElement():
            _line(canvas, field, shown, e, pass);
          case MarkerElement() || NoteElement():
            break;
        }
      }
    }
    for (final e in elements) {
      switch (e) {
        case MarkerElement():
          _marker(canvas, field, shown, e, selected: e.id == selectedId);
        case NoteElement():
          _note(canvas, field, shown, e, selected: e.id == selectedId);
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
  //
  // Sizes are the mockup's, on its 390-wide board, scaled with the board.

  /// A marker's radius on [board] shown [width] pixels across: the mockup's
  /// 10.5, big enough to read on a phone, still readable in a thumbnail.
  /// Football's are smaller, so a line's eleven stand side by side.
  static double markerRadius(double width, PlayBoard board) =>
      width * (board == PlayBoard.football ? 0.015 : 10.5 / 390);

  void _marker(
    Canvas canvas,
    Size field,
    double shown,
    MarkerElement m, {
    required bool selected,
  }) {
    final c = Offset(m.at.x * field.width, m.at.y * field.height);
    final r = markerRadius(shown, board);
    // The mockup's 2.4 edge on its 10.5 disc.
    final edge = r * 2.4 / 10.5;
    if (selected) {
      // Picked: a mustard ring in its own ink edge.
      _disc(canvas, c, r * 1.5, BoardPieces.pick, edge);
    }
    switch (m.side) {
      case MarkerSide.ball:
        // The mockup's 6.3 ball in a 2.2 edge.
        _disc(canvas, c, r * 6.3 / 10.5, _ballColor, r * 2.2 / 10.5);
      case MarkerSide.opponent when board == PlayBoard.football:
        // X's and O's: the defense is an X, chalk over ink, its label
        // under it.
        final arm = r * 0.72;
        final chalk = r * 0.34;
        for (final (color, width) in [
          (BoardPieces.ink, chalk + 2 * edge),
          (BoardPieces.chalk, chalk),
        ]) {
          final p = Paint()
            ..color = color
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round;
          canvas
            ..drawLine(c - Offset(arm, arm), c + Offset(arm, arm), p)
            ..drawLine(c + Offset(-arm, arm), c + Offset(arm, -arm), p);
        }
        _label(canvas, c + Offset(0, r * 1.5), m.label, r, outlined: true);
      case MarkerSide.team when board == PlayBoard.football:
        // The offense is an O: chalk in an ink edge.
        _disc(canvas, c, r, BoardPieces.chalk, edge);
        _label(canvas, c, m.label, r);
      case MarkerSide.team || MarkerSide.opponent:
        _disc(
          canvas,
          c,
          r,
          m.side == MarkerSide.team ? BoardPieces.team : BoardPieces.opponent,
          edge,
        );
        _label(canvas, c, m.label, r);
    }
  }

  Color get _ballColor => switch (board) {
    PlayBoard.basketball => const Color(0xFFE8590C),
    PlayBoard.football => const Color(0xFF8B4513),
    _ => BoardPieces.chalk,
  };

  /// A disc of [fill] in an ink edge [edge] wide, on its rim as the mockup
  /// strokes it.
  static void _disc(
    Canvas canvas,
    Offset c,
    double r,
    Color fill,
    double edge,
  ) => canvas
    ..drawCircle(c, r, Paint()..color = fill)
    ..drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = edge
        ..color = BoardPieces.ink,
    );

  /// [text] on a piece of radius [r] centered on [at], in ink in the
  /// reading font as the mockup letters them: 9.4 for one letter and 8.2
  /// for more on a 10.5 disc, shrunk to fit. [outlined] is chalk in an ink
  /// edge, for a label beside a piece (under football's X's).
  static void _label(
    Canvas canvas,
    Offset at,
    String text,
    double r, {
    bool outlined = false,
  }) {
    if (text.isEmpty) return;
    var fontSize = r * (text.characters.length == 1 ? 9.4 : 8.2) / 10.5;
    TextPainter painter(double size, {Paint? stroke}) => TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: size,
          fontWeight: FontWeight.w700,
          height: 1,
          color: stroke != null
              ? null
              : outlined
              ? BoardPieces.chalk
              : BoardPieces.ink,
          foreground: stroke,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    var fill = painter(fontSize);
    // A long label (a roster player's name) shrinks to fit the disc, or a
    // little wider beside it.
    final room = r * (outlined ? 2.6 : 1.62);
    if (fill.width > room) {
      fontSize *= room / fill.width;
      fill = painter(fontSize);
    }
    // The capitals' middle on [at]: the baseline 0.36 of the size below
    // it, where the mockup sets it.
    final baseline = fill.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final topLeft = at - Offset(fill.width / 2, baseline - fontSize * 0.36);
    if (outlined) {
      painter(
        fontSize,
        stroke: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = fontSize * 0.3
          ..strokeJoin = StrokeJoin.round
          ..color = BoardPieces.ink,
      ).paint(canvas, topLeft);
    }
    fill.paint(canvas, topLeft);
  }

  /// An arrow's chalk line on a board shown [width] pixels across: the
  /// mockup's 2.8, never thinner than reads in a list's picture.
  static double strokeFor(double width) => math.max(1.6, width * 2.8 / 390);

  /// The ink under a chalk line [w] wide: the mockup's 6.4 under its 2.8.
  static double _edgeFor(double w) => w * 6.4 / 2.8;

  /// A round-ended stroke.
  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// What's picked: a wide mustard glow under the ink.
  static Paint _pickStroke(double edge) =>
      _stroke(BoardPieces.pick.withValues(alpha: 0.7), edge * 2.2);

  /// One [pass] of an arrow: a run (solid), a pass (dashed), or a block or
  /// screen (ending in a T), each chalk over ink with its head to match.
  void _arrow(
    Canvas canvas,
    Size field,
    double shown,
    ArrowElement a,
    _Pass pass,
  ) {
    final pts = [
      for (final p in a.points) Offset(p.x * field.width, p.y * field.height),
    ];
    if (pts.length < 2) return;
    final w = strokeFor(shown);
    final edge = _edgeFor(w);
    final smooth = _smooth(pts);
    if (pass == _Pass.pick) {
      canvas.drawPath(smooth, _pickStroke(edge));
      return;
    }
    final ink = pass == _Pass.ink;
    final end = pts.last;
    final from = pts[pts.length - 2];
    final angle = math.atan2(end.dy - from.dy, end.dx - from.dx);
    final dir = Offset(math.cos(angle), math.sin(angle));
    final across = Offset(-dir.dy, dir.dx);
    final block = a.kind == ArrowKind.block;
    // The mockup's head: 11 long and 9 wide on a 2.8 line.
    final head = w * 11 / 2.8;
    // A head's line stops inside it, so the line's round end stays under
    // the point.
    var path = block ? smooth : _trim(smooth, head * 0.2);
    if (a.kind == ArrowKind.pass) {
      // The mockup's dashes: 7.5 on, 8 off, the same on both layers.
      path = _dashed(path, w * 7.5 / 2.8, w * 8 / 2.8);
    }
    final line = _stroke(
      ink ? BoardPieces.ink : BoardPieces.chalk,
      ink ? edge : w,
    );
    canvas.drawPath(path, line);
    if (block) {
      // A block or screen ends in a T.
      final half = w * 2.6;
      canvas.drawLine(end - across * half, end + across * half, line);
      return;
    }
    final base = end - dir * head;
    final wing = across * (head * 4.5 / 11);
    final tip = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo((base + wing).dx, (base + wing).dy)
      ..lineTo((base - wing).dx, (base - wing).dy)
      ..close();
    // Under the chalk, the head's ink runs as far past it as the line's.
    final rim = w * 0.6 / 2.8;
    canvas
      ..drawPath(
        tip,
        Paint()..color = ink ? BoardPieces.ink : BoardPieces.chalk,
      )
      ..drawPath(
        tip,
        _stroke(
          ink ? BoardPieces.ink : BoardPieces.chalk,
          ink ? edge - w + rim : rim,
        ),
      );
  }

  /// One [pass] of a freehand line: chalk over ink, like the arrows.
  void _line(
    Canvas canvas,
    Size field,
    double shown,
    LineElement l,
    _Pass pass,
  ) {
    final pts = [
      for (final p in l.points) Offset(p.x * field.width, p.y * field.height),
    ];
    if (pts.length < 2) return;
    final w = strokeFor(shown);
    canvas.drawPath(_smooth(pts), switch (pass) {
      _Pass.pick => _pickStroke(_edgeFor(w)),
      _Pass.ink => _stroke(BoardPieces.ink, _edgeFor(w)),
      _Pass.chalk => _stroke(BoardPieces.chalk, w),
    });
  }

  /// A note: ink lettering on a chalk tag in an ink edge, on a hard ink
  /// shadow, like Boot Camp's panels.
  void _note(
    Canvas canvas,
    Size field,
    double shown,
    NoteElement n, {
    required bool selected,
  }) {
    final c = Offset(n.at.x * field.width, n.at.y * field.height);
    final fontSize = (shown * 0.0215).clamp(9.0, 20.0);
    final p = TextPainter(
      text: TextSpan(
        text: n.text,
        style: TextStyle(
          fontFamily: AppFonts.body,
          color: BoardPieces.ink,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 4,
    )..layout(maxWidth: shown * 0.33);
    final box = Rect.fromCenter(
      center: c,
      width: p.width + fontSize,
      height: p.height + fontSize * 0.6,
    );
    final edge = strokeFor(shown);
    if (selected) {
      canvas
        ..drawRect(box.inflate(fontSize * 0.35), _fill(BoardPieces.pick))
        ..drawRect(
          box.inflate(fontSize * 0.35),
          _chalk(edge * 0.85, BoardPieces.ink),
        );
    }
    canvas
      ..drawRect(box.shift(Offset(edge, edge)), _fill(BoardPieces.ink))
      ..drawRect(box, _fill(BoardPieces.chalk))
      ..drawRect(box, _chalk(edge, BoardPieces.ink));
    p.paint(canvas, box.topLeft + Offset(fontSize / 2, fontSize * 0.3));
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

  /// [source] without its last [by] pixels.
  static Path _trim(Path source, double by) {
    final out = Path();
    final metrics = source.computeMetrics().toList();
    for (final (i, metric) in metrics.indexed) {
      final keep = i == metrics.length - 1
          ? math.max<double>(0, metric.length - by)
          : metric.length;
      out.addPath(metric.extractPath(0, keep), Offset.zero);
    }
    return out;
  }

  /// [source] as dashes [dash] long, [gap] apart.
  static Path _dashed(Path source, double dash, double gap) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        out.addPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          Offset.zero,
        );
        d += dash + gap;
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

  /// Volleyball's court (#87): a tan floor in a darker free zone, its
  /// lines inside it, the attack lines run on as broken lines past the
  /// sidelines, the service zone's marks, and the net across the middle,
  /// chalk over ink like the arrows, post to post.
  void _volleyball(Canvas canvas, Size size, BoardVariant v) {
    final m = size.width / VolleyballCourt.widthMeters;
    final top = VolleyballCourt.topOf(v);
    Offset o(double x, double y) => Offset(x * m, (y - top) * m);
    const left = VolleyballCourt.sideZone;
    const right = left + VolleyballCourt.courtWidth;
    const net = VolleyballCourt.netMeters;
    const near = net - VolleyballCourt.courtLength / 2;
    const far = net + VolleyballCourt.courtLength / 2;
    const attack = VolleyballCourt.attackMeters;
    canvas.drawRect(Offset.zero & size, _fill(const Color(0xFFC4925B)));
    final court = Rect.fromPoints(o(left, near), o(right, far));
    canvas.drawRect(court, _fill(const Color(0xFFDDB07C)));
    // Floorboards, up the board.
    final boards = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 1;
    for (var i = 1; i < 26; i++) {
      final x = size.width * i / 26;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), boards);
    }
    final line = math.max(1.5, size.width * 0.005);
    final chalk = _chalk(line);
    // The lines are part of the court, so they're drawn inside it.
    canvas.drawRect(court.deflate(line / 2), chalk);
    for (final y in [net - attack, net + attack]) {
      canvas.drawLine(o(left, y), o(right, y), chalk);
      // Each attack line runs on past the sidelines as five 15 cm dashes,
      // 20 cm apart.
      for (final (x, out) in [(left, -1.0), (right, 1.0)]) {
        for (var k = 0; k < 5; k++) {
          final x0 = x + out * (0.2 + k * 0.35);
          canvas.drawLine(o(x0, y), o(x0 + out * 0.15, y), chalk);
        }
      }
    }
    // The service zone's marks, behind each end line in line with the
    // sidelines.
    for (final (y, out) in [(near, -1.0), (far, 1.0)]) {
      for (final x in [left, right]) {
        canvas.drawLine(o(x, y + out * 0.2), o(x, y + out * 0.35), chalk);
      }
    }
    // The net over the center line, a meter past each sideline to its
    // posts.
    final posts = [o(left - 1, net), o(right + 1, net)];
    canvas
      ..drawLine(posts.first, posts.last, _stroke(BoardPieces.ink, line * 4.2))
      ..drawLine(
        posts.first,
        posts.last,
        _stroke(BoardPieces.chalk, line * 1.8),
      );
    for (final p in posts) {
      _disc(canvas, p, line * 2.4, BoardPieces.chalk, line * 1.1);
    }
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
