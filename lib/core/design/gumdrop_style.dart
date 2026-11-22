import 'package:battleplan/core/design/fonts.dart';
import 'package:material_ui/material_ui.dart';

/// The parts of the look that aren't colors (SPEC §7.4): the heading and
/// label fonts, the outline on candy buttons, and the panels' shape. Every
/// color scheme shares it.
///
/// Boot Camp Mix (#85, owner's pick 2026-11-22): stencil titles and labels,
/// a 3 px ink outline on every panel and push button, square panels on a
/// hard shadow down and to the right, and no drop under plain headings
/// (the big titles are outlined instead, `OutlinedText`).
@immutable
class GumdropStyle extends ThemeExtension<GumdropStyle> {
  const new({
    this.displayFont = AppFonts.display,
    this.labelFont = AppFonts.label,
    this.accentOutline = 0,
    this.panelRadius = 0,
  });

  /// Boot Camp Mix (#85): stencil titles and labels, 3 px ink outlines,
  /// square panels.
  static const bootCamp = GumdropStyle(accentOutline: 3);

  /// The name the look had before Boot Camp Mix; the same as [bootCamp].
  static const GumdropStyle openField = bootCamp;

  /// The style in effect at [context]: the theme's, or Boot Camp Mix.
  static GumdropStyle of(BuildContext context) =>
      Theme.of(context).extension<GumdropStyle>() ?? bootCamp;

  /// Headings: screen titles, the team name, section headings.
  final String displayFont;

  /// Buttons, labels, tabs, chips, and people's names.
  final String labelFont;

  /// How thick an outline candy buttons have, in ink.
  final double accentOutline;

  /// A panel's corners: square (#85).
  final double panelRadius;

  /// The outline of a candy button: [ink], [accentOutline] px.
  BorderSide accentSide(Color ink) => accentOutline == 0
      ? BorderSide.none
      : BorderSide(color: ink, width: accentOutline);

  /// [style] in [labelFont], for a label styled by hand: stencil, a little
  /// spaced, as the design sets its labels.
  TextStyle label(TextStyle style) => style.copyWith(
    fontFamily: labelFont,
    letterSpacing: style.letterSpacing ?? stencilSpacing(style.fontSize),
  );

  /// [style] in [displayFont], for a heading styled by hand.
  TextStyle display(TextStyle style) => style.copyWith(
    fontFamily: displayFont,
    letterSpacing: style.letterSpacing ?? stencilSpacing(style.fontSize),
  );

  /// The stencil's letter spacing at [size]: 0.05 em, as the design's
  /// buttons and labels have it.
  static double stencilSpacing(double? size) => (size ?? 14) * 0.05;

  /// The hard drop under a title in [color]: none in Boot Camp Mix, whose
  /// plain headings have no drop (#85).
  List<Shadow> headingShadow(Color color, {bool big = false}) => const [];

  /// A panel's outline: square, with [side] as its rim.
  ShapeBorder cardShape(double radius, {BorderSide side = BorderSide.none}) =>
      RoundedRectangleBorder(
        side: side,
        borderRadius: BorderRadius.circular(panelRadius),
      );

  /// A panel filled with [color], as a decoration: square, with a rim
  /// ([side]), on a hard shadow [lip] px down and to the right in [shadow]
  /// (the rim's color unless given). [radius] is the corner the panel had
  /// before Boot Camp Mix, which squares it (#85).
  Decoration cardDecoration(
    Color color,
    double radius, {
    BorderSide side = BorderSide.none,
    double lip = 4,
    Color? shadow,
  }) {
    final rimmed = side.style != BorderStyle.none && side.width > 0;
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(panelRadius),
      border: rimmed ? Border.fromBorderSide(side) : null,
      boxShadow: rimmed && lip > 0
          ? [BoxShadow(color: shadow ?? side.color, offset: Offset(lip, lip))]
          : null,
    );
  }

  @override
  GumdropStyle copyWith({
    String? displayFont,
    String? labelFont,
    double? accentOutline,
    double? panelRadius,
  }) => GumdropStyle(
    displayFont: displayFont ?? this.displayFont,
    labelFont: labelFont ?? this.labelFont,
    accentOutline: accentOutline ?? this.accentOutline,
    panelRadius: panelRadius ?? this.panelRadius,
  );

  @override
  GumdropStyle lerp(GumdropStyle? other, double t) =>
      other == null || t < 0.5 ? this : other;
}
