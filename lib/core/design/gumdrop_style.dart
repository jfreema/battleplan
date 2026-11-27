import 'package:battleplan/core/design/camp_palette.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:material_ui/material_ui.dart';

/// The parts of the look that aren't colors (SPEC §7.4): the heading and
/// label fonts, the outline on candy buttons, and the panels' shape. Every
/// color scheme shares it.
///
/// Boot Camp Mix (#85, owner's pick 2026-11-22): a 3 px ink outline on
/// every panel and push button, panels on a hard shadow down and to the
/// right, and no drop under plain headings (the big titles are outlined
/// instead, `OutlinedText`). The candy finish (#98) rounds the panels'
/// corners to 15. Team Shirt (#104) letters it: bubbly titles, the plain
/// face for labels, and the stencil only on what's stamped on.
@immutable
class GumdropStyle extends ThemeExtension<GumdropStyle> {
  const new({
    this.displayFont = AppFonts.display,
    this.labelFont = AppFonts.label,
    this.accentOutline = 0,
    this.panelRadius = 0,
    this.panelLip,
    this.pills = false,
  });

  /// The style of [palette]'s scheme: [bootCamp], with Sugar Rush's own
  /// panels and pill buttons (#98, `CandyTouches`).
  static GumdropStyle forPalette(CampPalette palette) {
    final touches = palette.touches;
    if (identical(touches, CandyTouches.none)) return bootCamp;
    return bootCamp.copyWith(
      panelRadius: touches.panelRadius,
      panelLip: touches.panelLip,
      pills: touches.pills,
    );
  }

  /// Boot Camp Mix (#85): 3 px ink outlines, and panels with corners of 15
  /// (the candy finish, #98), lettered as Team Shirt (#104).
  static const bootCamp = GumdropStyle(accentOutline: 3, panelRadius: 15);

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

  /// A panel's corners: 15 (#98; square in #85), 20 on Sugar Rush.
  final double panelRadius;

  /// The lip panels sit on in place of their hard shadow (Sugar Rush's
  /// lavender, #98), or null for the shadow.
  final Color? panelLip;

  /// Whether push buttons are pills (Sugar Rush's, #98).
  final bool pills;

  /// What a panel stands on: a hard shadow [lip] px down and to the right
  /// in [shadow], or, with a [panelLip], a lip [depth] deep in it with
  /// [ink] carried round under it (the mockup's two box shadows, #98).
  List<BoxShadow> panelShadows({
    required Color shadow,
    required Color ink,
    double lip = 4,
    double depth = 7,
  }) {
    final band = panelLip;
    if (band == null) {
      return [BoxShadow(color: shadow, offset: Offset(lip, lip))];
    }
    return [
      BoxShadow(color: ink, offset: Offset(0, depth)),
      BoxShadow(color: band, offset: Offset(0, depth), spreadRadius: -3),
    ];
  }

  /// The outline of a candy button: [ink], [accentOutline] px.
  BorderSide accentSide(Color ink) => accentOutline == 0
      ? BorderSide.none
      : BorderSide(color: ink, width: accentOutline);

  /// [style] in [labelFont], for a label styled by hand: the plain face
  /// (Team Shirt, #104), in Black unless [style] names a weight, with no
  /// extra spacing.
  TextStyle label(TextStyle style) => style.copyWith(
    fontFamily: labelFont,
    fontWeight: style.fontWeight ?? AppFonts.heavy,
    letterSpacing: style.letterSpacing ?? 0,
  );

  /// [style] in [displayFont], for a heading styled by hand: the bubbly
  /// letters, which have one weight (a heavier one asked for would be
  /// faked), a little spaced.
  TextStyle display(TextStyle style) => style.copyWith(
    fontFamily: displayFont,
    fontFamilyFallback: AppFonts.bubblyFallback,
    fontWeight: AppFonts.displayWeight,
    letterSpacing:
        style.letterSpacing ?? AppFonts.bubblySpacing(style.fontSize),
  );

  /// [style] in the stencil, for what's stamped on (a tag, a stamp, a dog
  /// tag, a date's weekday): Black, its only weight, 0.05 em apart unless
  /// [style] says.
  static TextStyle stamped(TextStyle style) => style.copyWith(
    fontFamily: AppFonts.stencil,
    fontWeight: FontWeight.w900,
    letterSpacing: style.letterSpacing ?? stencilSpacing(style.fontSize),
  );

  /// [style] as a small label in the plain face's capitals ("NEXT UP",
  /// "OWED IN ALL"): Black, 0.08 em apart. The caller writes the text in
  /// capitals.
  static TextStyle caps(TextStyle style) => style.copyWith(
    fontFamily: AppFonts.plain,
    fontWeight: AppFonts.heavy,
    letterSpacing: AppFonts.capsSpacing(style.fontSize),
  );

  /// The stencil's letter spacing at [size]: 0.05 em, as the design's
  /// tags and stamps have it.
  static double stencilSpacing(double? size) => (size ?? 14) * 0.05;

  /// The hard drop under a title in [color]: none in Boot Camp Mix, whose
  /// plain headings have no drop (#85).
  List<Shadow> headingShadow(Color color, {bool big = false}) => const [];

  /// A panel's outline: [panelRadius] corners, with [side] as its rim.
  ShapeBorder cardShape(double radius, {BorderSide side = BorderSide.none}) =>
      RoundedRectangleBorder(
        side: side,
        borderRadius: BorderRadius.circular(panelRadius),
      );

  /// A panel filled with [color], as a decoration: [panelRadius] corners,
  /// with a rim ([side]), on a hard shadow [lip] px down and to the right
  /// in [shadow] (the rim's color unless given). [radius] is the corner the
  /// panel had before Boot Camp Mix, which every panel now shares (#85,
  /// #98).
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
          ? panelShadows(
              shadow: shadow ?? side.color,
              ink: side.color,
              lip: lip,
            )
          : null,
    );
  }

  /// A panel's hard shadow alone, [lip] px down and to the right in
  /// [shadow], with [panelRadius] corners: for a panel whose face is an
  /// [Ink] on a [Material], which would clip a shadow drawn with it at its
  /// edges (square corners showed once panels were rounded, #98).
  Decoration cardShadow(Color shadow, {Color? ink, double lip = 4}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(panelRadius),
        boxShadow: panelShadows(shadow: shadow, ink: ink ?? shadow, lip: lip),
      );

  @override
  GumdropStyle copyWith({
    String? displayFont,
    String? labelFont,
    double? accentOutline,
    double? panelRadius,
    Color? panelLip,
    bool? pills,
  }) => GumdropStyle(
    displayFont: displayFont ?? this.displayFont,
    labelFont: labelFont ?? this.labelFont,
    accentOutline: accentOutline ?? this.accentOutline,
    panelRadius: panelRadius ?? this.panelRadius,
    panelLip: panelLip ?? this.panelLip,
    pills: pills ?? this.pills,
  );

  @override
  GumdropStyle lerp(GumdropStyle? other, double t) =>
      other == null || t < 0.5 ? this : other;
}
