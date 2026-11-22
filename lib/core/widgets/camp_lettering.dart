import 'dart:math' as math;

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
    this.textScaler,
    this.fill = CampPalette.titleFill,
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

  /// The lettering's fill: white, or a count's color (Going's green).
  final Color fill;

  /// The text scaling; the system's unless given (a date on a pennant
  /// that doesn't grow keeps [TextScaler.noScaling]).
  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final scaler = textScaler ?? MediaQuery.textScalerOf(context);
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
            textScaler: scaler,
            maxLines: lines,
            overflow: overflow ?? inherited.overflow,
            textAlign: textAlign ?? inherited.textAlign ?? TextAlign.start,
            textWidthBasis: textWidthBasis ?? inherited.textWidthBasis,
            softWrap: inherited.softWrap,
          ),
          Text(
            text,
            style: base.copyWith(color: fill, shadows: const []),
            textScaler: scaler,
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

/// A starburst (#85, SPEC §7.4): a mustard star of [points] points in a
/// 3 px ink edge, its inner corners [inner] of the way out, with [child]
/// (ink lettering) on it: "IN 5 DAYS!", or an event's date in the chat.
class Starburst extends StatelessWidget {
  const new({
    required this.child,
    this.width = 86,
    this.height = 62,
    this.points = 14,
    this.inner = 0.78,
    this.turn = -6,
    super.key,
  });

  final Widget child;
  final double width;
  final double height;
  final int points;

  /// How far out the inner corners sit, as a share of the outer ones.
  final double inner;

  /// How far it's turned, in degrees.
  final double turn;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Transform.rotate(
      angle: turn * 3.141592653589793 / 180,
      child: CustomPaint(
        painter: _StarburstPainter(
          fill: c.roles.palette.mustard,
          edge: c.ink,
          points: points,
          inner: inner,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: DefaultTextStyle.merge(
              style: TextStyle(color: c.ink),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarburstPainter extends CustomPainter {
  new({
    required this.fill,
    required this.edge,
    required this.points,
    required this.inner,
  });

  final Color fill;
  final Color edge;
  final int points;
  final double inner;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rx = size.width / 2;
    final ry = size.height / 2;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final angle = -math.pi / 2 + math.pi * i / points;
      final k = i.isEven ? 1.0 : inner;
      final p =
          center + Offset(math.cos(angle) * rx * k, math.sin(angle) * ry * k);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_StarburstPainter old) =>
      old.fill != fill ||
      old.edge != edge ||
      old.points != points ||
      old.inner != inner;
}
