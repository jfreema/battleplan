import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/plays/domain/play.dart';

/// The sizes of each board's field, in its own units, and where things are
/// on it (BOARD-1). The painter draws from these and the formations stand
/// on them, so a shortstop stands at short. Points are 0 to 1 across and
/// down; boards are drawn with the end the team attacks at the top.

/// The part of a field a board shows, in the field's points: all of it, or
/// (baseball's) cut to the fence so the field fills the board.
final class BoardFrame {
  const new({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  static const whole = BoardFrame(left: 0, top: 0, width: 1, height: 1);

  final double left;
  final double top;
  final double width;
  final double height;

  /// The field's point [x] across and [y] down the frame, each 0 to 1.
  BoardPoint pointAt(double x, double y) =>
      (x: left + x * width, y: top + y * height);

  /// [p], kept within the frame.
  BoardPoint clamp(BoardPoint p) =>
      (x: p.x.clamp(left, left + width), y: p.y.clamp(top, top + height));
}

/// Baseball (and softball): home plate near the bottom, the outfield fence
/// across the top. Distances in feet, 90-foot bases.
abstract final class BaseballField {
  /// The field's width in feet: the fence's foul poles sit near the edges.
  static const double widthFeet = 470;
  static const BoardPoint home = (x: 0.5, y: 0.9);
  static const double baseFeet = 90;
  static const double moundFeet = 60.5;
  static const double poleFeet = 330;

  /// The infield's dirt arc, from the pitcher's rubber.
  static const double infieldArcFeet = 95;

  /// A distance in feet as a fraction of the board's width.
  static double w(double feet) => feet / widthFeet;

  /// Feet along a direction from home: 0° is straight out to center, -45°
  /// the left-field line, 45° the right-field line.
  static BoardPoint fromHome(double feet, double degrees) {
    final r = degrees * math.pi / 180;
    return (
      x: home.x + w(feet) * math.sin(r),
      y: home.y - w(feet) * math.cos(r) * aspect,
    );
  }

  /// Width over height.
  static const double aspect = 1;

  /// What the board shows: from a few feet past the center-field fence to
  /// 47 feet behind home (room for the pitcher backing up the plate), and
  /// 16 feet in from each side. The fence runs to the board's edges, and
  /// the field fills it.
  static const frame = BoardFrame(
    left: 16 / widthFeet,
    top: 0.04,
    width: 1 - 2 * 16 / widthFeet,
    height: 0.96,
  );

  static BoardPoint get first => fromHome(baseFeet, 45);
  static BoardPoint get second => fromHome(baseFeet * math.sqrt2, 0);
  static BoardPoint get third => fromHome(baseFeet, -45);
  static BoardPoint get mound => fromHome(moundFeet, 0);
  static BoardPoint get leftPole => fromHome(poleFeet, -45);
  static BoardPoint get rightPole => fromHome(poleFeet, 45);

  /// Dead center field's fence.
  static BoardPoint get center => fromHome(400, 0);
}

/// Basketball: the basket at the top, in feet (50 wide, 47 to half court).
abstract final class BasketballCourt {
  static const double widthFeet = 50;
  static const double halfFeet = 47;
  static const double hoopFeet = 5.25;
  static const double laneWidthFeet = 16;
  static const double laneLengthFeet = 19;
  static const double freeThrowRadiusFeet = 6;
  static const double threeRadiusFeet = 23.75;
  static const double threeCornerFeet = 3;
  static const double restrictedFeet = 4;
  static const double centerRadiusFeet = 6;

  static double aspectOf(BoardVariant v) =>
      widthFeet / (v == BoardVariant.half ? halfFeet : halfFeet * 2);

  /// A spot in feet from the left sideline and the top baseline.
  static BoardPoint at(double x, double y, BoardVariant v) => (
    x: x / widthFeet,
    y: y / (v == BoardVariant.half ? halfFeet : halfFeet * 2),
  );
}

/// Soccer: the goal the team attacks at the top, in meters (68 by 105).
abstract final class SoccerPitch {
  static const double widthMeters = 68;
  static const double lengthMeters = 105;
  static const double penaltyWidth = 40.32;
  static const double penaltyDepth = 16.5;
  static const double goalAreaWidth = 18.32;
  static const double goalAreaDepth = 5.5;
  static const double penaltySpot = 11;
  static const double circleRadius = 9.15;
  static const double goalWidth = 7.32;

  static double aspectOf(BoardVariant v) =>
      widthMeters / (v == BoardVariant.half ? lengthMeters / 2 : lengthMeters);

  /// A spot in meters from the left touchline and the top goal line.
  static BoardPoint at(double x, double y) =>
      (x: x / widthMeters, y: y / lengthMeters);
}

/// American football: a 40-yard window of the field, the line of
/// scrimmage across it, the offense below it heading up. In yards.
abstract final class FootballField {
  static const double widthYards = 160 / 3;
  static const double windowYards = 40;

  /// The line of scrimmage, in yards from the top.
  static const double scrimmageYards = 25;

  /// High school hash marks, from the left sideline.
  static const double leftHash = 17.78;
  static const double rightHash = widthYards - leftHash;

  static const double aspect = widthYards / windowYards;

  /// A spot in yards from the left sideline, and from the line of
  /// scrimmage (behind it is positive: the offense's side).
  static BoardPoint at(double x, double behind) =>
      (x: x / widthYards, y: (scrimmageYards + behind) / windowYards);
}

/// A blank board for any other sport (BOARD-1).
abstract final class BlankBoard {
  static const double aspect = 4 / 3;
}

/// Width over height of [board]'s whole field in [variant]: what a point's
/// units measure, for distances on it.
double fieldAspect(PlayBoard board, BoardVariant variant) => switch (board) {
  PlayBoard.baseball => BaseballField.aspect,
  PlayBoard.basketball => BasketballCourt.aspectOf(variant),
  PlayBoard.soccer => SoccerPitch.aspectOf(variant),
  PlayBoard.football => FootballField.aspect,
  PlayBoard.blank => BlankBoard.aspect,
};

/// The part of [board]'s field it shows.
BoardFrame boardFrame(PlayBoard board) =>
    board == PlayBoard.baseball ? BaseballField.frame : BoardFrame.whole;

/// Width over height of [board] in [variant], as it's shown.
double boardAspect(PlayBoard board, BoardVariant variant) {
  final frame = boardFrame(board);
  return fieldAspect(board, variant) * frame.width / frame.height;
}

/// The variants [board] has (BOARD-1): basketball's half and full court,
/// soccer's full and half pitch; one for the others.
List<BoardVariant> boardVariants(PlayBoard board) => switch (board) {
  PlayBoard.basketball => const [BoardVariant.half, BoardVariant.full],
  PlayBoard.soccer => const [BoardVariant.full, BoardVariant.half],
  _ => const [BoardVariant.full],
};

/// The board a team's sport starts with: baseball's for softball too, a
/// blank one for sports without their own yet.
PlayBoard boardForSport(Sport? sport) => switch (sport) {
  Sport.baseball || Sport.softball => PlayBoard.baseball,
  Sport.basketball => PlayBoard.basketball,
  Sport.soccer => PlayBoard.soccer,
  Sport.football => PlayBoard.football,
  _ => PlayBoard.blank,
};

/// A player's spot in a formation.
typedef Spot = ({String label, BoardPoint at});

/// A starting lineup a board offers, for the team or the other side.
final class Formation {
  const new({required this.id, required this.name, required this.spots});

  /// Stable for tests and saving the choice: '4-4-2', 'i-form'.
  final String id;

  /// What the picker shows. Formation names aren't translated.
  final String name;
  final List<Spot> spots;
}

Spot _s(String label, BoardPoint at) => (label: label, at: at);

// ---- Baseball ------------------------------------------------------------------

List<Spot> get _baseballDefense {
  final f = BaseballField.first;
  final s = BaseballField.second;
  final t = BaseballField.third;
  return [
    _s('P', BaseballField.mound),
    _s('C', BaseballField.fromHome(-12, 0)),
    _s('1B', (x: f.x + 0.012, y: f.y - 0.045)),
    _s('2B', (x: (f.x + s.x) / 2 + 0.01, y: s.y + 0.012)),
    _s('SS', (x: (t.x + s.x) / 2 - 0.01, y: s.y + 0.012)),
    _s('3B', (x: t.x - 0.012, y: t.y - 0.045)),
    _s('LF', BaseballField.fromHome(270, -28)),
    _s('CF', BaseballField.fromHome(300, 0)),
    _s('RF', BaseballField.fromHome(270, 28)),
  ];
}

List<Spot> get _baseballBatter => [
  _s('B', (x: BaseballField.home.x - 0.035, y: BaseballField.home.y)),
];

List<Spot> get _baseballRunners => [
  ..._baseballBatter,
  _s('R1', BaseballField.first),
  _s('R2', BaseballField.second),
  _s('R3', BaseballField.third),
];

// ---- Basketball ----------------------------------------------------------------

List<Spot> _basketballOffense(BoardVariant v) => [
  _s('PG', BasketballCourt.at(25, 30, v)),
  _s('SG', BasketballCourt.at(41, 20, v)),
  _s('SF', BasketballCourt.at(9, 20, v)),
  _s('PF', BasketballCourt.at(32, 9, v)),
  _s('C', BasketballCourt.at(18, 9, v)),
];

List<Spot> _basketballManToMan(BoardVariant v) => [
  _s('1', BasketballCourt.at(25, 25, v)),
  _s('2', BasketballCourt.at(37, 16, v)),
  _s('3', BasketballCourt.at(13, 16, v)),
  _s('4', BasketballCourt.at(29, 5.5, v)),
  _s('5', BasketballCourt.at(21, 5.5, v)),
];

List<Spot> _basketballZone(BoardVariant v) => [
  _s('1', BasketballCourt.at(19, 21, v)),
  _s('2', BasketballCourt.at(31, 21, v)),
  _s('3', BasketballCourt.at(8, 9, v)),
  _s('4', BasketballCourt.at(25, 8, v)),
  _s('5', BasketballCourt.at(42, 9, v)),
];

// ---- Soccer ---------------------------------------------------------------------

/// Spots in meters on the full pitch, the team's goal at the bottom.
List<Spot> _pitch(List<(String, double, double)> spots) => [
  for (final (label, x, y) in spots) _s(label, SoccerPitch.at(x, y)),
];

final _soccerFormations = <String, List<(String, double, double)>>{
  '4-4-2': [
    ('GK', 34, 101), ('LB', 8, 86), ('CB', 25, 89), ('CB', 43, 89), //
    ('RB', 60, 86), ('LM', 8, 68), ('CM', 25, 71), ('CM', 43, 71),
    ('RM', 60, 68), ('ST', 27, 58), ('ST', 41, 58),
  ],
  '4-3-3': [
    ('GK', 34, 101), ('LB', 8, 86), ('CB', 25, 89), ('CB', 43, 89), //
    ('RB', 60, 86), ('CM', 20, 71), ('CM', 34, 73), ('CM', 48, 71),
    ('LW', 10, 59), ('ST', 34, 56), ('RW', 58, 59),
  ],
  '3-5-2': [
    ('GK', 34, 101), ('CB', 20, 89), ('CB', 34, 90), ('CB', 48, 89), //
    ('LWB', 6, 73), ('CM', 22, 73), ('CM', 34, 75), ('CM', 46, 73),
    ('RWB', 62, 73), ('ST', 27, 58), ('ST', 41, 58),
  ],
  '9v9': [
    ('GK', 34, 101), ('D', 17, 88), ('D', 34, 89), ('D', 51, 88), //
    ('M', 17, 72), ('M', 34, 73), ('M', 51, 72), ('F', 26, 59),
    ('F', 42, 59),
  ],
  '7v7': [
    ('GK', 34, 101), ('D', 24, 88), ('D', 44, 88), ('M', 14, 72), //
    ('M', 34, 73), ('M', 54, 72), ('F', 34, 59),
  ],
};

/// A formation's spots on [v]: on the half pitch, the team's half, with
/// the keeper left out, fills the board as an attack on the goal.
List<Spot> _soccerSpots(String id, BoardVariant v, {required bool opponent}) {
  var spots = _pitch(_soccerFormations[id]!);
  if (v == BoardVariant.half) {
    spots = [
      for (final s in spots)
        if (s.label != 'GK')
          _s(s.label, (x: s.at.x, y: ((s.at.y - 0.5) * 2).clamp(0.04, 0.96))),
    ];
  }
  // The other team mirrors the shape, attacking down.
  return opponent
      ? [for (final s in spots) _s(s.label, (x: 1 - s.at.x, y: 1 - s.at.y))]
      : spots;
}

// ---- Football -------------------------------------------------------------------

const double _mid = FootballField.widthYards / 2;
const double _gap = 2;

List<Spot> get _offensiveLine => [
  _s('C', FootballField.at(_mid, 1)),
  _s('G', FootballField.at(_mid - _gap, 1)),
  _s('G', FootballField.at(_mid + _gap, 1)),
  _s('T', FootballField.at(_mid - 2 * _gap, 1)),
  _s('T', FootballField.at(_mid + 2 * _gap, 1)),
];

List<Spot> get _iFormation => [
  ..._offensiveLine,
  _s('Y', FootballField.at(_mid + 3 * _gap, 1.2)),
  _s('X', FootballField.at(5, 1)),
  _s('Z', FootballField.at(FootballField.widthYards - 7, 2.4)),
  _s('QB', FootballField.at(_mid, 2.6)),
  _s('FB', FootballField.at(_mid, 5)),
  _s('RB', FootballField.at(_mid, 7.6)),
];

List<Spot> get _shotgun => [
  ..._offensiveLine,
  _s('Y', FootballField.at(_mid + 3 * _gap, 1.2)),
  _s('X', FootballField.at(5, 1)),
  _s('H', FootballField.at(FootballField.widthYards - 13, 2.4)),
  _s('Z', FootballField.at(FootballField.widthYards - 5, 2.4)),
  _s('QB', FootballField.at(_mid, 5.5)),
  _s('RB', FootballField.at(_mid - 2.2, 5.5)),
];

List<Spot> get _fourThree => [
  _s('E', FootballField.at(_mid - 2.6 * _gap, -1.6)),
  _s('T', FootballField.at(_mid - 0.6 * _gap, -1.6)),
  _s('T', FootballField.at(_mid + 0.9 * _gap, -1.6)),
  _s('E', FootballField.at(_mid + 2.9 * _gap, -1.6)),
  _s('W', FootballField.at(_mid - 4, -5.5)),
  _s('M', FootballField.at(_mid, -5.5)),
  _s('S', FootballField.at(_mid + 4, -5.5)),
  _s('CB', FootballField.at(5, -6)),
  _s('CB', FootballField.at(FootballField.widthYards - 7, -6)),
  _s('FS', FootballField.at(_mid - 6, -12)),
  _s('SS', FootballField.at(_mid + 6, -11)),
];

List<Spot> get _threeFour => [
  _s('E', FootballField.at(_mid - 1.6 * _gap, -1.6)),
  _s('N', FootballField.at(_mid, -1.6)),
  _s('E', FootballField.at(_mid + 1.6 * _gap, -1.6)),
  _s('OLB', FootballField.at(_mid - 3.6 * _gap, -2)),
  _s('ILB', FootballField.at(_mid - 2.4, -5.5)),
  _s('ILB', FootballField.at(_mid + 2.4, -5.5)),
  _s('OLB', FootballField.at(_mid + 3.6 * _gap, -2)),
  _s('CB', FootballField.at(5, -6)),
  _s('CB', FootballField.at(FootballField.widthYards - 7, -6)),
  _s('FS', FootballField.at(_mid - 6, -12)),
  _s('SS', FootballField.at(_mid + 6, -11)),
];

/// The team's formations on [board] in [variant], the first the default.
List<Formation> teamFormations(PlayBoard board, BoardVariant variant) =>
    switch (board) {
      PlayBoard.baseball => [
        Formation(id: 'field', name: 'In the field', spots: _baseballDefense),
      ],
      PlayBoard.basketball => [
        Formation(
          id: 'offense',
          name: 'Offense (1-2-2)',
          spots: _basketballOffense(variant),
        ),
      ],
      PlayBoard.soccer => [
        for (final id in _soccerFormations.keys)
          Formation(
            id: id,
            name: id,
            spots: _soccerSpots(id, variant, opponent: false),
          ),
      ],
      PlayBoard.football => [
        Formation(id: 'i-form', name: 'I formation', spots: _iFormation),
        Formation(id: 'shotgun', name: 'Shotgun', spots: _shotgun),
      ],
      PlayBoard.blank => const [],
    };

/// The other side's formations on [board] in [variant].
List<Formation> opponentFormations(PlayBoard board, BoardVariant variant) =>
    switch (board) {
      PlayBoard.baseball => [
        Formation(id: 'batter', name: 'Batter', spots: _baseballBatter),
        Formation(id: 'loaded', name: 'Bases loaded', spots: _baseballRunners),
      ],
      PlayBoard.basketball => [
        Formation(
          id: 'man',
          name: 'Man-to-man',
          spots: _basketballManToMan(variant),
        ),
        Formation(
          id: 'zone',
          name: '2-3 zone',
          spots: _basketballZone(variant),
        ),
      ],
      PlayBoard.soccer => [
        for (final id in _soccerFormations.keys)
          Formation(
            id: id,
            name: id,
            spots: _soccerSpots(id, variant, opponent: true),
          ),
      ],
      PlayBoard.football => [
        Formation(id: '4-3', name: '4-3 defense', spots: _fourThree),
        Formation(id: '3-4', name: '3-4 defense', spots: _threeFour),
      ],
      PlayBoard.blank => const [],
    };

final _random = math.Random();

/// A new element's ID: short, and unique enough within one play.
String newElementId() => List.generate(
  8,
  (_) => 'abcdefghijkmnpqrstuvwxyz23456789'[_random.nextInt(32)],
).join();

/// Where the ball starts on [board] in [variant], for dragging through a
/// play: in the pitcher's hand, with the point guard, on the center spot,
/// on the line of scrimmage. None on a blank board.
BoardPoint? ballSpot(PlayBoard board, BoardVariant variant) => switch (board) {
  PlayBoard.baseball => (
    x: BaseballField.mound.x + 0.03,
    y: BaseballField.mound.y + 0.012,
  ),
  PlayBoard.basketball => BasketballCourt.at(27.5, 31, variant),
  PlayBoard.soccer =>
    variant == BoardVariant.half ? (x: 0.5, y: 0.62) : (x: 0.5, y: 0.5),
  PlayBoard.football => FootballField.at(_mid, 0),
  PlayBoard.blank => null,
};

/// A board's first step: [team]'s players and [opponent]'s, from their
/// formations' spots (either may be null for none), and the [ball].
PlayStep startingStep(
  Formation? team,
  Formation? opponent, {
  BoardPoint? ball,
}) => PlayStep(
  elements: [
    for (final s in team?.spots ?? const <Spot>[])
      BoardElement.marker(
        id: newElementId(),
        at: s.at,
        side: MarkerSide.team,
        label: s.label,
      ),
    for (final s in opponent?.spots ?? const <Spot>[])
      BoardElement.marker(
        id: newElementId(),
        at: s.at,
        side: MarkerSide.opponent,
        label: s.label,
      ),
    if (ball != null)
      BoardElement.marker(id: newElementId(), at: ball, side: MarkerSide.ball),
  ],
);
