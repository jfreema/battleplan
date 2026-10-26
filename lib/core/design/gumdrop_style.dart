import 'dart:math' as math;

import 'package:battleplan/core/design/arena/arena_theme.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:material_ui/material_ui.dart';

/// The parts of a Gumdrop theme that aren't colors (SPEC §7.4): the heading
/// and label fonts, how a heading's hard shadow sits, and the shapes of
/// gumdrops and cards. Every theme uses the Gumdrop Pop style but Gumdrop
/// Arena ([arenaStyle]), which slants its buttons, cuts two corners off its
/// cards, and sets headings and labels in a condensed italic.
@immutable
class GumdropStyle extends ThemeExtension<GumdropStyle> {
  const new({
    this.displayFont = AppFonts.display,
    this.labelFont = AppFonts.label,
    this.fontWeight,
    this.fontStyle = FontStyle.normal,
    this.headingShadowOffset,
    this.slant = 0,
    this.buttonRadius,
    this.cardCut = 0,
    this.headingOutline = 0,
    this.accentOutline = 0,
  });

  /// Gumdrop Pop's style: Lilita One headings with stacked shadows, Fredoka
  /// labels, pill gumdrops, and rounded cards.
  static const gumdrop = GumdropStyle();

  /// Gumdrop Pop Olive's style: Gumdrop Pop's, with headings outlined in
  /// the shadow's color and every candy gumdrop outlined in ink (design V1
  /// Olive).
  static const olive = GumdropStyle(headingOutline: 1.5, accentOutline: 2);

  /// The style of [flavor].
  static GumdropStyle forFlavor(GumdropFlavor flavor) => switch (flavor) {
    GumdropFlavor.arena => arenaStyle,
    GumdropFlavor.olive => olive,
    _ => gumdrop,
  };

  /// The style in effect at [context]: the theme's, or Gumdrop Pop's.
  static GumdropStyle of(BuildContext context) =>
      Theme.of(context).extension<GumdropStyle>() ?? gumdrop;

  /// Headings: screen titles, the team name, section headings.
  final String displayFont;

  /// Buttons, labels, tabs, chips, and people's names.
  final String labelFont;

  /// The one weight [displayFont] and [labelFont] are set in, or null for
  /// each text style's own (Lilita One's 400, Fredoka's 500 to 700).
  final FontWeight? fontWeight;

  /// Whether [displayFont] and [labelFont] are italic.
  final FontStyle fontStyle;

  /// A heading's hard shadow as one copy this far down and right; null for
  /// Gumdrop Pop's stack of 1 px steps.
  final double? headingShadowOffset;

  /// How far a gumdrop leans, in degrees (Arena's 11); 0 stands it upright.
  final double slant;

  /// A gumdrop's corner radius; null for a pill.
  final BorderRadius? buttonRadius;

  /// How far a card's top right and bottom left corners are cut off, in
  /// pixels; 0 rounds all four.
  final double cardCut;

  /// How thick an outline a heading has, in its shadow's color, around its
  /// letters (Olive's 1.5); 0 for none.
  final double headingOutline;

  /// How thick an ink outline candy gumdrops have (Olive's 2); 0 for none.
  final double accentOutline;

  /// [shape] in this style: leaning [slant] degrees, with [buttonRadius]
  /// corners when the style has them. Gumdrop Pop's leaves it as it is.
  GumdropShape styled(GumdropShape shape) => slant == 0 && buttonRadius == null
      ? shape
      : shape.copyWith(radius: buttonRadius, slant: slant);

  /// [style] in [labelFont], for a label styled by hand.
  TextStyle label(TextStyle style) => style.copyWith(
    fontFamily: labelFont,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
  );

  /// [style] in [displayFont], for a heading styled by hand.
  TextStyle display(TextStyle style) => style.copyWith(
    fontFamily: displayFont,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
  );

  /// The hard shadow under a heading in [color], [steps] deep in Gumdrop
  /// Pop's stack.
  List<Shadow> headingShadow(Color color, int steps) {
    final o = headingShadowOffset;
    final w = headingOutline;
    return [
      // The outline: copies all around the letters, as a stroke would be.
      if (w > 0)
        for (var i = 0; i < 16; i++)
          Shadow(
            color: color,
            offset: Offset(
              w * math.cos(i * math.pi / 8),
              w * math.sin(i * math.pi / 8),
            ),
          ),
      ...o == null
          ? GumdropColors.stackedShadow(color, steps)
          : [Shadow(color: color, offset: Offset(o, o))],
    ];
  }

  /// A card's outline: rounded, or with two corners cut off ([cardCut]).
  ShapeBorder cardShape(double radius, {BorderSide side = BorderSide.none}) =>
      cardCut > 0
      ? BeveledRectangleBorder(
          side: side,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(3),
            topRight: Radius.circular(cardCut),
            bottomLeft: Radius.circular(cardCut),
            bottomRight: const Radius.circular(3),
          ),
        )
      : RoundedRectangleBorder(
          side: side,
          borderRadius: BorderRadius.circular(radius),
        );

  /// [cardShape] filled with [color], as a decoration: a plain rounded box
  /// when no corner is cut.
  Decoration cardDecoration(
    Color color,
    double radius, {
    BorderSide side = BorderSide.none,
  }) => cardCut > 0
      ? ShapeDecoration(
          color: color,
          shape: cardShape(radius, side: side),
        )
      : BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: side.style == BorderStyle.none || side.width == 0
              ? null
              : Border.fromBorderSide(side),
        );

  @override
  GumdropStyle copyWith({
    String? displayFont,
    String? labelFont,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? headingShadowOffset,
    double? slant,
    BorderRadius? buttonRadius,
    double? cardCut,
    double? headingOutline,
    double? accentOutline,
  }) => GumdropStyle(
    displayFont: displayFont ?? this.displayFont,
    labelFont: labelFont ?? this.labelFont,
    fontWeight: fontWeight ?? this.fontWeight,
    fontStyle: fontStyle ?? this.fontStyle,
    headingShadowOffset: headingShadowOffset ?? this.headingShadowOffset,
    slant: slant ?? this.slant,
    buttonRadius: buttonRadius ?? this.buttonRadius,
    cardCut: cardCut ?? this.cardCut,
    headingOutline: headingOutline ?? this.headingOutline,
    accentOutline: accentOutline ?? this.accentOutline,
  );

  @override
  GumdropStyle lerp(GumdropStyle? other, double t) =>
      other == null || t < 0.5 ? this : other;
}
