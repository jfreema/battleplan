import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/plays/domain/play.dart';

/// How many changes undo remembers.
const int boardUndoMax = 100;

/// A play being drawn (BOARD-2, BOARD-3): its steps, the step on show, and
/// what undo and redo go back to. Every change returns a new edit; moving
/// a marker while it's dragged changes nothing undo sees until the drag
/// ends ([commitFrom]).
final class BoardEdit {
  const new({
    required this.steps,
    this.step = 0,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  final List<PlayStep> steps;

  /// The step on show, from 0.
  final int step;
  final List<({List<PlayStep> steps, int step})> undoStack;
  final List<({List<PlayStep> steps, int step})> redoStack;

  List<BoardElement> get elements => steps[step].elements;
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  /// Room for one more element on this step.
  bool get hasRoom => elements.length < Limits.playElementsMax;

  bool get canAddStep => steps.length < Limits.playStepsMax;

  /// [next] as the play, remembered for undo.
  BoardEdit _change(List<PlayStep> next, {int? at}) {
    final history = [...undoStack, (steps: steps, step: step)];
    return BoardEdit(
      steps: next,
      step: at ?? step,
      undoStack: history.length > boardUndoMax
          ? history.sublist(history.length - boardUndoMax)
          : history,
    );
  }

  List<PlayStep> _withElements(List<BoardElement> elements) => [
    for (final (i, s) in steps.indexed)
      if (i == step) s.copyWith(elements: elements) else s,
  ];

  /// Adds [e] to this step, if there's room.
  BoardEdit add(BoardElement e) =>
      hasRoom ? _change(_withElements([...elements, e])) : this;

  /// [e] in place of the element with its ID.
  BoardEdit replace(BoardElement e) => _change(
    _withElements([
      for (final x in elements)
        if (x.id == e.id) e else x,
    ]),
  );

  BoardEdit remove(String id) => _change(
    _withElements([
      for (final x in elements)
        if (x.id != id) x,
    ]),
  );

  /// Everything off this step.
  BoardEdit clear() => elements.isEmpty ? this : _change(_withElements([]));

  /// [e] in place, without undo noticing: for each move while dragging.
  BoardEdit moveLive(BoardElement e) => BoardEdit(
    steps: _withElements([
      for (final x in elements)
        if (x.id == e.id) e else x,
    ]),
    step: step,
    undoStack: undoStack,
    redoStack: redoStack,
  );

  /// Ends a drag that began at [before]: one undo goes back to it.
  BoardEdit commitFrom(BoardEdit before) => BoardEdit(
    steps: steps,
    step: step,
    undoStack: [...before.undoStack, (steps: before.steps, step: before.step)],
  );

  /// A new step after this one, starting where everyone stands now: the
  /// markers carry over, and arrows, lines, and notes don't.
  BoardEdit addStep() {
    if (!canAddStep) return this;
    final carried = PlayStep(
      elements: [
        for (final e in elements)
          if (e is MarkerElement) e,
      ],
    );
    return _change([
      ...steps.sublist(0, step + 1),
      carried,
      ...steps.sublist(step + 1),
    ], at: step + 1);
  }

  /// This step gone; a play keeps at least one.
  BoardEdit removeStep() {
    if (steps.length == 1) return clear();
    final next = [...steps]..removeAt(step);
    return _change(next, at: math.min(step, next.length - 1));
  }

  /// Shows step [i], which isn't a change undo goes back over.
  BoardEdit show(int i) => BoardEdit(
    steps: steps,
    step: i.clamp(0, steps.length - 1),
    undoStack: undoStack,
    redoStack: redoStack,
  );

  BoardEdit undo() {
    if (!canUndo) return this;
    final last = undoStack.last;
    return BoardEdit(
      steps: last.steps,
      step: last.step,
      undoStack: undoStack.sublist(0, undoStack.length - 1),
      redoStack: [...redoStack, (steps: steps, step: step)],
    );
  }

  BoardEdit redo() {
    if (!canRedo) return this;
    final next = redoStack.last;
    return BoardEdit(
      steps: next.steps,
      step: next.step,
      undoStack: [...undoStack, (steps: steps, step: step)],
      redoStack: redoStack.sublist(0, redoStack.length - 1),
    );
  }
}

// ---- Geometry --------------------------------------------------------------------

/// The distance between [a] and [b] in board widths, on a board [aspect]
/// wide for each unit high (a unit of y is 1/aspect widths).
double boardDistance(BoardPoint a, BoardPoint b, double aspect) {
  final dx = a.x - b.x;
  final dy = (a.y - b.y) / aspect;
  return math.sqrt(dx * dx + dy * dy);
}

double _segmentDistance(
  BoardPoint p,
  BoardPoint a,
  BoardPoint b,
  double aspect,
) {
  final ax = a.x;
  final ay = a.y / aspect;
  final bx = b.x;
  final by = b.y / aspect;
  final px = p.x;
  final py = p.y / aspect;
  final dx = bx - ax;
  final dy = by - ay;
  final len = dx * dx + dy * dy;
  final t = len == 0
      ? 0.0
      : (((px - ax) * dx + (py - ay) * dy) / len).clamp(0.0, 1.0);
  final cx = ax + t * dx - px;
  final cy = ay + t * dy - py;
  return math.sqrt(cx * cx + cy * cy);
}

/// The element at [p], topmost first, within [tolerance] board widths
/// (the screen's finger-sized reach, measured where it's drawn), or null.
/// Markers win over the lines under them.
BoardElement? hitTest(
  List<BoardElement> elements,
  BoardPoint p,
  double aspect, {
  required double tolerance,
}) {
  for (final e in elements.reversed) {
    if (e is MarkerElement && boardDistance(e.at, p, aspect) <= tolerance) {
      return e;
    }
  }
  for (final e in elements.reversed) {
    final points = switch (e) {
      ArrowElement(:final points) || LineElement(:final points) => points,
      _ => const <BoardPoint>[],
    };
    for (var i = 1; i < points.length; i++) {
      if (_segmentDistance(p, points[i - 1], points[i], aspect) <= tolerance) {
        return e;
      }
    }
    if (e is NoteElement && boardDistance(e.at, p, aspect) <= tolerance * 2) {
      return e;
    }
  }
  return null;
}

/// A drawn path with the wobble taken out (Ramer–Douglas–Peucker, within
/// [epsilon] board widths), at most [Limits.playPointsMax] points.
List<BoardPoint> simplifyPath(
  List<BoardPoint> points,
  double aspect, {
  double epsilon = 0.006,
}) {
  if (points.length <= 2) return points;
  List<BoardPoint> rdp(List<BoardPoint> pts, double eps) {
    if (pts.length <= 2) return pts;
    var index = 0;
    var far = 0.0;
    for (var i = 1; i < pts.length - 1; i++) {
      final d = _segmentDistance(pts[i], pts.first, pts.last, aspect);
      if (d > far) {
        far = d;
        index = i;
      }
    }
    if (far <= eps) return [pts.first, pts.last];
    final left = rdp(pts.sublist(0, index + 1), eps);
    final right = rdp(pts.sublist(index), eps);
    return [...left.sublist(0, left.length - 1), ...right];
  }

  var eps = epsilon;
  var out = rdp(points, eps);
  while (out.length > Limits.playPointsMax) {
    eps *= 1.6;
    out = rdp(points, eps);
  }
  return out;
}

/// [p] kept on the board.
BoardPoint onBoard(BoardPoint p) =>
    (x: p.x.clamp(0.0, 1.0), y: p.y.clamp(0.0, 1.0));

/// [e] moved by [dx], [dy], kept on the board.
BoardElement moveElement(BoardElement e, double dx, double dy) {
  BoardPoint by(BoardPoint p) => onBoard((x: p.x + dx, y: p.y + dy));
  return switch (e) {
    MarkerElement() => e.copyWith(at: by(e.at)),
    NoteElement() => e.copyWith(at: by(e.at)),
    ArrowElement() => e.copyWith(points: [for (final p in e.points) by(p)]),
    LineElement() => e.copyWith(points: [for (final p in e.points) by(p)]),
  };
}

/// The board partway, [t] from 0 to 1, from step [from] to step [to], so a
/// play can be played back (BOARD-3): players and the ball glide to where
/// they stand next (matched by ID: a step carries its markers over), and
/// the arrows, lines, and notes are the step being played until it ends.
List<BoardElement> elementsBetween(
  List<BoardElement> from,
  List<BoardElement> to,
  double t,
) {
  if (t >= 1) return to;
  final next = {
    for (final e in to)
      if (e is MarkerElement) e.id: e,
  };
  BoardElement glide(BoardElement e) {
    if (e is! MarkerElement) return e;
    final n = next[e.id];
    if (n == null) return e;
    return e.copyWith(
      at: (
        x: e.at.x + (n.at.x - e.at.x) * t,
        y: e.at.y + (n.at.y - e.at.y) * t,
      ),
    );
  }

  return [for (final e in from) glide(e)];
}
