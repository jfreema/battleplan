import 'package:battleplan/core/design/camp_palette.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Boot Camp Mix's big titles (#85, SPEC §7.4): [text] in white stencil
/// with an ink stroke under it and a hard shadow down and to the right in
/// the scheme's shadow color: the team name in the header, a screen's
/// title, an event's opponent.
class OutlinedText extends StatelessWidget {
  const new(
    this.text, {
    required this.style,
    this.stroke = 4.5,
    this.shadow = 3,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.textWidthBasis,
    this.semanticsLabel,
    super.key,
  });

  final String text;

  /// The title's font, size and spacing; its color is the white fill.
  final TextStyle style;

  /// The ink stroke's width.
  final double stroke;

  /// How far the shadow falls, down and to the right.
  final double shadow;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextWidthBasis? textWidthBasis;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    // The style as the fill's Text resolves it, so the stroke matches.
    final inherited = DefaultTextStyle.of(context);
    final base = inherited.style.merge(
      style.copyWith(fontFamily: style.fontFamily ?? AppFonts.display),
    );
    final lines = maxLines ?? inherited.maxLines;
    return Semantics(
      label: semanticsLabel ?? text,
      excludeSemantics: true,
      child: Stack(
        children: [
          // The stroke, under the fill: a RichText, so the title is one
          // Text to find, and a style built anew, since a stroke can't have
          // a color too.
          RichText(
            text: TextSpan(
              text: text,
              style: TextStyle(
                fontFamily: base.fontFamily,
                fontWeight: base.fontWeight,
                fontSize: base.fontSize,
                height: base.height,
                letterSpacing: base.letterSpacing,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = stroke
                  ..strokeJoin = StrokeJoin.round
                  ..color = c.ink,
                shadows: [
                  if (shadow > 0)
                    Shadow(color: c.pageShadow, offset: Offset(shadow, shadow)),
                ],
              ),
            ),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: lines,
            overflow: overflow ?? inherited.overflow,
            textAlign: textAlign ?? inherited.textAlign ?? TextAlign.start,
            textWidthBasis: textWidthBasis ?? inherited.textWidthBasis,
            softWrap: inherited.softWrap,
          ),
          Text(
            text,
            style: base.copyWith(
              color: CampPalette.titleFill,
              shadows: const [],
            ),
            maxLines: lines,
            overflow: overflow ?? inherited.overflow,
            textAlign: textAlign ?? inherited.textAlign,
            textWidthBasis: textWidthBasis ?? inherited.textWidthBasis,
            softWrap: inherited.softWrap,
          ),
        ],
      ),
    );
  }
}

/// A mustard tag (#85): [text] in small ink stencil on mustard, in a 2 px
/// ink outline, turned a little: the eyebrow over the team's name ("TEAM
/// CHAT"), an event's kind ("GAME · HOME"), and the like.
class CampTag extends StatelessWidget {
  const new(
    this.text, {
    this.size = 11,
    this.turn = -2,
    this.semanticsLabel,
    super.key,
  });

  final String text;

  /// The lettering's size.
  final double size;

  /// How far it's turned, in degrees.
  final double turn;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Transform.rotate(
      angle: turn * 3.141592653589793 / 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.roles.palette.mustard,
          border: Border.all(color: c.ink, width: 2),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(size * 0.7, 1, size * 0.75, 0),
          child: Text(
            text.toUpperCase(),
            semanticsLabel: semanticsLabel ?? text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontFamily: AppFonts.stencil,
              fontWeight: FontWeight.w900,
              fontSize: size,
              height: 15 / 11,
              letterSpacing: size * 0.09,
              color: c.ink,
            ),
          ),
        ),
      ),
    );
  }
}
