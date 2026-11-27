import 'dart:math' as math;

import 'package:battleplan/core/design/camp_palette.dart';
import 'package:battleplan/core/design/candy.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/widgets/candy_box.dart';
import 'package:battleplan/core/widgets/candy_sprinkles.dart';
import 'package:material_ui/material_ui.dart';

/// The big titles (#85, SPEC §7.4): [text] in white bubbly letters (Team
/// Shirt, #104; the stencil before it) with an ink stroke under it and a
/// hard shadow down and to the right in the scheme's shadow color: the
/// team name in the header, a screen's title, an event's opponent.
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
    this.header = false,
    this.namesRoute = false,
    super.key,
  });

  /// The semantics identifier every outlined lettering carries, so the
  /// accessibility checks can find it: it reads by its ink outline, which
  /// stands apart from every page and panel (#86), not by its fill.
  static const semanticsIdentifier = 'outlined-lettering';

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

  /// A heading for screen readers (a page's title, the event's), on the
  /// lettering's own node: a [Semantics] around it would be a node apart.
  final bool header;

  /// It names the route (a page's title).
  final bool namesRoute;

  /// The text scaling; the system's unless given (a date on a pennant
  /// that doesn't grow keeps [TextScaler.noScaling]).
  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final scaler = textScaler ?? MediaQuery.textScalerOf(context);
    // The style as the fill's Text resolves it, so the stroke matches.
    final inherited = DefaultTextStyle.of(context);
    final family = style.fontFamily ?? AppFonts.display;
    final bubbly = family == AppFonts.bubbly;
    final base = inherited.style.merge(
      style.copyWith(
        fontFamily: family,
        // The bubbly letters have one weight (a heavier one asked for would
        // be faked), and what they lack draws in the plain face.
        fontWeight: bubbly ? AppFonts.displayWeight : style.fontWeight,
        fontFamilyFallback: bubbly
            ? AppFonts.bubblyFallback
            : style.fontFamilyFallback,
      ),
    );
    final lines = maxLines ?? inherited.maxLines;
    // A header's sprinkles keep off it (#98).
    return SprinkleKeepOut(
      child: Semantics(
        label: semanticsLabel ?? text,
        identifier: semanticsIdentifier,
        header: header ? true : null,
        namesRoute: namesRoute ? true : null,
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
                  fontFamilyFallback: base.fontFamilyFallback,
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
                    // The scheme's title drop: its shadow, or Sugar Rush's
                    // bubblegum (#98).
                    if (shadow > 0)
                      Shadow(
                        color: c.roles.titleDrop,
                        offset: Offset(shadow, shadow),
                      ),
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
      ),
    );
  }
}

/// A mustard tag (#85): [text] in small ink stencil on mustard, in a 2 px
/// ink outline, turned a little: the eyebrow over the team's name ("TEAM
/// CHAT"), an event's kind ("GAME · HOME"), and the like. A lemon drop
/// (#98): corners of 7, on a lip of a darker mustard 4 px deep (5 under
/// the event page's bigger one), with a shine at its top left. The lip
/// takes no room: leave it a few pixels under the tag.
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
    final big = size >= 13;
    // A header's sprinkles keep off it (#98).
    return SprinkleKeepOut(
      child: Transform.rotate(
        angle: turn * 3.141592653589793 / 180,
        child: CandyBox(
          color: c.roles.palette.mustard,
          outline: 2,
          // The outline over the padding's edge, as before, so the tag keeps
          // its size.
          padOutline: false,
          depth: big ? 5 : 4,
          shine: big
              ? const Rect.fromLTWH(5, 3, 11, 3.5)
              : const Rect.fromLTWH(4, 2.5, 8, 3),
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
      ),
    );
  }
}

/// A starburst (#85, SPEC §7.4): a mustard star of [points] points in a
/// 3 px ink edge, its inner corners [inner] of the way out, with [child]
/// (ink lettering) on it: "IN 5 DAYS!", or an event's date in the chat.
/// The candy finish (#98) stacks it on a copy of itself 9% of its height
/// lower, in a darker mustard edged in ink, like a gumdrop on its lip, and
/// puts a white oval shine at its top left.
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
          fill: c.roles.palette.touches.burst ?? c.roles.palette.mustard,
          lip: Candy.lipOf(
            c.roles.palette.touches.burst ?? c.roles.palette.mustard,
          ),
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
    required this.lip,
    required this.edge,
    required this.points,
    required this.inner,
  });

  final Color fill;

  /// The copy under it (#98).
  final Color lip;
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
    final stroke = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    // Its lip: the burst again, 9% of its height lower, darker (#98).
    final under = path.shift(Offset(0, size.height * 0.09));
    canvas
      ..drawPath(under, Paint()..color = lip)
      ..drawPath(under, stroke)
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(path, stroke)
      // The shine: a white oval at (31, 30) of a 100 x 100 box stretched to
      // the burst's, 20 x 11, turned -24 degrees, at 72%.
      ..save()
      ..scale(size.width / 100, size.height / 100)
      ..translate(31, 30)
      ..rotate(-24 * math.pi / 180)
      ..drawOval(
        Rect.fromCenter(center: Offset.zero, width: 20, height: 11),
        Paint()..color = Candy.ballShineOn(fill),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_StarburstPainter old) =>
      old.fill != fill ||
      old.lip != lip ||
      old.edge != edge ||
      old.points != points ||
      old.inner != inner;
}
