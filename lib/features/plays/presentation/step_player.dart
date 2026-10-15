import 'package:battleplan/features/plays/domain/board_edit.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:material_ui/material_ui.dart';

/// Plays a play's steps one after another (BOARD-3): the players and the
/// ball glide from where each step has them to where the next does, so the
/// team sees how the play unfolds.
class StepPlayer {
  new(TickerProvider vsync)
    : controller = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 1200),
      );

  /// Repaint with this while playing.
  final AnimationController controller;

  /// The step being left, while playing; null when still.
  int? _from;
  bool _stop = false;

  bool get playing => _from != null;

  /// Plays [steps] from [start] to the end, telling [onStep] as each one
  /// arrives.
  Future<void> play(
    List<PlayStep> steps, {
    required int start,
    required ValueChanged<int> onStep,
  }) async {
    _stop = false;
    for (var i = start; i < steps.length - 1 && !_stop; i++) {
      _from = i;
      await controller.forward(from: 0).orCancel.catchError((_) {});
      if (_stop) break;
      onStep(i + 1);
    }
    _from = null;
  }

  void stop() {
    _stop = true;
    controller.stop();
    _from = null;
  }

  /// What the board shows now: partway between two steps while playing,
  /// else [still].
  List<BoardElement> elements(List<PlayStep> steps, List<BoardElement> still) {
    final from = _from;
    if (from == null || from + 1 >= steps.length) return still;
    return elementsBetween(
      steps[from].elements,
      steps[from + 1].elements,
      Curves.easeInOut.transform(controller.value),
    );
  }

  void dispose() => controller.dispose();
}
