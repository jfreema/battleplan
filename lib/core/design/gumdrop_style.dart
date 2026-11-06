import 'package:battleplan/core/design/fonts.dart';
import 'package:material_ui/material_ui.dart';

/// The parts of the Open Field theme that aren't colors (SPEC §7.4): the
/// heading and label fonts, the hard drop under titles, the 2 px outline on
/// candy gumdrops, and the cards' shape. Every color scheme shares it.
@immutable
class GumdropStyle extends ThemeExtension<GumdropStyle> {
  const new({
    this.displayFont = AppFonts.display,
    this.labelFont = AppFonts.label,
    this.accentOutline = 0,
  });

  /// Open Field: Lilita One titles with a hard drop, Fredoka labels, pill
  /// gumdrops outlined in their lip color, and rounded cards with a lip.
  static const openField = GumdropStyle(accentOutline: 2);

  /// The style in effect at [context]: the theme's, or Open Field.
  static GumdropStyle of(BuildContext context) =>
      Theme.of(context).extension<GumdropStyle>() ?? openField;

  /// Headings: screen titles, the team name, section headings.
  final String displayFont;

  /// Buttons, labels, tabs, chips, and people's names.
  final String labelFont;

  /// How thick an outline candy gumdrops have, in their lip color.
  final double accentOutline;

  /// The outline of a candy gumdrop whose lip is [lip].
  BorderSide accentSide(Color lip) => accentOutline == 0
      ? BorderSide.none
      : BorderSide(color: lip, width: accentOutline);

  /// [style] in [labelFont], for a label styled by hand.
  TextStyle label(TextStyle style) => style.copyWith(fontFamily: labelFont);

  /// [style] in [displayFont], for a heading styled by hand.
  TextStyle display(TextStyle style) => style.copyWith(fontFamily: displayFont);

  /// The hard drop under a title in [color]: one copy 2 px straight down,
  /// or 3 px under a [big] (48 px) one, and none when [color] is
  /// transparent (Light and Dark have no drop).
  List<Shadow> headingShadow(Color color, {bool big = false}) => [
    if (color.a > 0) Shadow(color: color, offset: Offset(0, big ? 3 : 2)),
  ];

  /// A card's outline: rounded, with [side] as its rim.
  ShapeBorder cardShape(double radius, {BorderSide side = BorderSide.none}) =>
      RoundedRectangleBorder(
        side: side,
        borderRadius: BorderRadius.circular(radius),
      );

  /// [cardShape] filled with [color], as a decoration: with a rim ([side]),
  /// it sits on a hard lip of the rim's color, [lip] px deep.
  Decoration cardDecoration(
    Color color,
    double radius, {
    BorderSide side = BorderSide.none,
    double lip = 4,
  }) {
    final rimmed = side.style != BorderStyle.none && side.width > 0;
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: rimmed ? Border.fromBorderSide(side) : null,
      boxShadow: rimmed && lip > 0
          ? [BoxShadow(color: side.color, offset: Offset(0, lip))]
          : null,
    );
  }

  @override
  GumdropStyle copyWith({
    String? displayFont,
    String? labelFont,
    double? accentOutline,
  }) => GumdropStyle(
    displayFont: displayFont ?? this.displayFont,
    labelFont: labelFont ?? this.labelFont,
    accentOutline: accentOutline ?? this.accentOutline,
  );

  @override
  GumdropStyle lerp(GumdropStyle? other, double t) =>
      other == null || t < 0.5 ? this : other;
}
