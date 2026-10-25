import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// App-specific colors that Material's scheme doesn't cover (ARCH §5.5),
/// all for text and icons: the RSVP answers and event types. The theme
/// builds them from its [GumdropColors]; gumdrop faces are there.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const new({
    required this.going,
    required this.maybe,
    required this.notGoing,
    required this.bubbleMine,
    required this.onBubbleMine,
    required this.bubbleOther,
    required this.onBubbleOther,
    required this.game,
    required this.practice,
    required this.meeting,
    required this.social,
    required this.otherEvent,
  });

  /// The colors for [g], readable as text and icons on every one of
  /// [backgrounds] (the page and the cards under it) and on their own light
  /// tint over them (ARCH §5.5): the Gumdrop candies, as text.
  ///
  /// RSVP answers are mint, lemon, and cherry. Event types: games
  /// tangerine, practices grape, meetings blue raspberry, socials mint, and
  /// other events bubblegum (the design's Other filter). Mine are the "you"
  /// bubble and ink; others' the card.
  factory fromGumdrop(GumdropColors g, {required List<Color> backgrounds}) {
    Color text(GumdropAccent a) =>
        ColorMath.readable(a.text, backgrounds, tint: 0.18);
    return AppColors(
      going: text(g.mint),
      maybe: text(g.lemon),
      notGoing: text(g.cherry),
      bubbleMine: g.you.face,
      onBubbleMine: g.ink,
      bubbleOther: g.surface,
      onBubbleOther: g.textPrimary,
      game: text(g.tangerine),
      practice: text(g.grape),
      meeting: text(g.blueRaspberry),
      social: text(g.mint),
      otherEvent: text(g.bubblegum),
    );
  }

  /// Gumdrop Pop Dark's, for a bare MaterialApp (some tests).
  static final fallback = AppColors.fromGumdrop(
    GumdropColors.dark,
    backgrounds: [GumdropColors.dark.page, GumdropColors.dark.surface],
  );

  final Color going;
  final Color maybe;
  final Color notGoing;
  final Color bubbleMine;
  final Color onBubbleMine;
  final Color bubbleOther;
  final Color onBubbleOther;
  final Color game;
  final Color practice;
  final Color meeting;
  final Color social;
  final Color otherEvent;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? fallback;

  @override
  AppColors copyWith({
    Color? going,
    Color? maybe,
    Color? notGoing,
    Color? bubbleMine,
    Color? onBubbleMine,
    Color? bubbleOther,
    Color? onBubbleOther,
    Color? game,
    Color? practice,
    Color? meeting,
    Color? social,
    Color? otherEvent,
  }) => AppColors(
    going: going ?? this.going,
    maybe: maybe ?? this.maybe,
    notGoing: notGoing ?? this.notGoing,
    bubbleMine: bubbleMine ?? this.bubbleMine,
    onBubbleMine: onBubbleMine ?? this.onBubbleMine,
    bubbleOther: bubbleOther ?? this.bubbleOther,
    onBubbleOther: onBubbleOther ?? this.onBubbleOther,
    game: game ?? this.game,
    practice: practice ?? this.practice,
    meeting: meeting ?? this.meeting,
    social: social ?? this.social,
    otherEvent: otherEvent ?? this.otherEvent,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      going: l(going, other.going),
      maybe: l(maybe, other.maybe),
      notGoing: l(notGoing, other.notGoing),
      bubbleMine: l(bubbleMine, other.bubbleMine),
      onBubbleMine: l(onBubbleMine, other.onBubbleMine),
      bubbleOther: l(bubbleOther, other.bubbleOther),
      onBubbleOther: l(onBubbleOther, other.onBubbleOther),
      game: l(game, other.game),
      practice: l(practice, other.practice),
      meeting: l(meeting, other.meeting),
      social: l(social, other.social),
      otherEvent: l(otherEvent, other.otherEvent),
    );
  }
}
