import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'play.freezed.dart';

/// A point on a board, each from 0 to 1 across the board's width and down
/// its height, so a play draws the same at any size (ARCH §6.14).
typedef BoardPoint = ({double x, double y});

/// Which part of a board a play uses (BOARD-1): the whole field or court,
/// or half of it (basketball's half court, soccer's half pitch).
enum BoardVariant {
  full('full'),
  half('half');

  new(this.value);

  /// The string stored in Firestore.
  final String value;

  static BoardVariant? tryParse(String? value) => switch (value) {
    'full' => full,
    'half' => half,
    _ => null,
  };
}

/// Whose a marker is (BOARD-1): our team's players (O on football's board),
/// the other team's (X), or the ball.
enum MarkerSide {
  team('team'),
  opponent('opponent'),
  ball('ball');

  new(this.value);

  final String value;

  static MarkerSide? tryParse(String? value) => switch (value) {
    'team' => team,
    'opponent' => opponent,
    'ball' => ball,
    _ => null,
  };
}

/// What an arrow means (BOARD-2): a run or cut (solid), a pass (dashed), or
/// a block or screen (a T at the end).
enum ArrowKind {
  run('run'),
  pass('pass'),
  block('block');

  new(this.value);

  final String value;

  static ArrowKind? tryParse(String? value) => switch (value) {
    'run' => run,
    'pass' => pass,
    'block' => block,
    _ => null,
  };
}

/// Something drawn on a board (BOARD-2).
@freezed
sealed class BoardElement with _$BoardElement {
  /// A player, an opponent, or the ball, with a short label: a number, a
  /// position ("SS"), or a roster player's (BOARD-4: only a label, never
  /// saved on a player).
  const factory marker({
    required String id,
    required BoardPoint at,
    required MarkerSide side,
    @Default('') String label,
    PlayerId? playerId,
  }) = MarkerElement;

  /// An arrow along [points], 2 or more.
  const factory arrow({
    required String id,
    required ArrowKind kind,
    required List<BoardPoint> points,
  }) = ArrowElement;

  /// A freehand line.
  const factory line({required String id, required List<BoardPoint> points}) =
      LineElement;

  /// A short text note at a place on the board.
  const factory note({
    required String id,
    required BoardPoint at,
    required String text,
  }) = NoteElement;
}

/// One step of a play: what the board shows at that moment (BOARD-3).
@freezed
abstract class PlayStep with _$PlayStep {
  const factory({@Default(<BoardElement>[]) List<BoardElement> elements}) =
      _PlayStep;
}

/// A play saved to a team (ARCH §6.2 `plays`, SPEC BOARD-4).
@freezed
abstract class Play with _$Play {
  const factory({
    required PlayId id,
    required GroupId groupId,
    required PlayBoard board,
    required BoardVariant variant,
    required String title,
    @Default('') String note,
    @Default(<PlayStep>[PlayStep()]) List<PlayStep> steps,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,

    /// Its public link's ID while it's shared (BOARD-6): `/p/<shareId>`.
    String? shareId,
  }) = _Play;
}

/// A play to save: everything but who made it and when.
typedef PlayDraft = ({
  PlayBoard board,
  BoardVariant variant,
  String title,
  String note,
  List<PlayStep> steps,
});
