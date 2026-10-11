import 'package:material_ui/material_ui.dart';

/// App-specific colors that Material's scheme doesn't cover (ARCH §5.5).
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

  static const light = AppColors(
    going: Color(0xFF16803C),
    maybe: Color(0xFFA15C07),
    notGoing: Color(0xFFC0262D),
    bubbleMine: Color(0xFF2F5BEA),
    onBubbleMine: Color(0xFFFFFFFF),
    bubbleOther: Color(0xFFEDEFF5),
    onBubbleOther: Color(0xFF1A1C22),
    game: Color(0xFFC2410C),
    practice: Color(0xFF2F5BEA),
    meeting: Color(0xFF7C3AED),
    social: Color(0xFF0F8A5F),
    otherEvent: Color(0xFF475569),
  );

  static const dark = AppColors(
    going: Color(0xFF4ADE80),
    maybe: Color(0xFFFBBF24),
    notGoing: Color(0xFFF87171),
    bubbleMine: Color(0xFF3D67F0),
    onBubbleMine: Color(0xFFFFFFFF),
    bubbleOther: Color(0xFF262A33),
    onBubbleOther: Color(0xFFE6E8EF),
    game: Color(0xFFFB923C),
    practice: Color(0xFF8AA6FF),
    meeting: Color(0xFFC4B5FD),
    social: Color(0xFF6EE7B7),
    otherEvent: Color(0xFFCBD5E1),
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
      Theme.of(context).extension<AppColors>()!;

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
