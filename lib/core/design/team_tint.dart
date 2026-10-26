import 'dart:math' as math;

import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// A team's color behind every screen inside the team (TEAM-1): the theme's
/// [base] colors tinted with [teamColor] (ARGB, from `groups.color`), as the
/// Gumdrop team-color proposal (§5) sets out. Null leaves [base] as it is.
///
/// - **Dark and Light** keep each tinted role's CIE lightness L*, so every
///   text contrast stays as designed, and take the team's hue with the
///   chroma capped at the role's own (and the team's): the page, cards,
///   raised buttons, wells, inputs, lips, and lines in Dark; the page, wells,
///   inputs, hairlines, outlines, and lips in Light (cards stay white).
///   Dark is a lighter touch, at half that chroma ([darkTeamShare]), and a
///   warm hue that would read brown that dark (Yellow, Mustard, Orange, Red,
///   Maroon: [isWarmHue]) is held to [warmChroma], a warm charcoal.
///   A saturated team hue within 25° of Gumdrop's own navy hue (Blue,
///   Navy) keeps the default colors: it's the theme's own. A gray team
///   color (Gray, Black) gives gray backgrounds: its own faint hue at a
///   third of the chroma, so it doesn't read as navy.
///   The team color itself is the hard shadow under headings and on the
///   page (the team name, the tab's sticker, the back button), so every
///   team reads as its color however dark or pale the page: in Dark made
///   lighter until it shows on the page ([_darkShadow]), in Light kept clear
///   of the navy heading text and darkened only if it would vanish on the
///   page ([_lightShadow]).
/// - **Candy** uses the team color itself as the page, darkened along L*
///   until white text reads when neither white nor ink does (Green). Text
///   on the page is whichever of white and ink reads better (ink on Light
///   blue and Yellow), its heading shadow the other one; shadows on the page
///   that would vanish (ink on Gray, Navy, and Black) use the team color 25
///   L* lighter. Cards, ink, and the candies don't change.
GumdropColors teamTinted(GumdropColors base, int? teamColor) {
  if (teamColor == null) return base;
  final untinted = GumdropColors.forFlavor(base.flavor);
  final team = Color(teamColor).withAlpha(255);
  final tinted = switch (base.flavor) {
    GumdropFlavor.dark => _tintDark(untinted, team),
    GumdropFlavor.light => _tintLight(untinted, team),
    GumdropFlavor.candy => _tintCandy(untinted, team),
  }.copyWith(teamColor: team);
  return base.onCard ? tinted.card : tinted;
}

/// Gumdrop's own hue: halfway between the Dark and Light pages' hues
/// (about 283°, a navy blue). Team hues this close keep the default colors.
final double gumdropHue =
    (ColorMath.lch(GumdropColors.dark.page).h +
        ColorMath.lch(GumdropColors.light.page).h) /
    2;

/// How close to [gumdropHue] a team's hue may be and still keep the default
/// colors in Dark and Light.
const sameHueDegrees = 25.0;

/// Team colors with less chroma than this are grays (Gray, Black): they
/// tint Dark and Light gray, even in Gumdrop's own hue.
const grayChroma = 20.0;

/// How much of the chroma a gray team color keeps in Dark and Light.
const grayShare = 0.35;

/// Whether [team] is a gray (Gray, Black) rather than a color.
bool isGray(Color team) => ColorMath.lch(team).c < grayChroma;

/// Whether [team] is close enough to Gumdrop's own navy, and colorful
/// enough, to leave Dark and Light untinted.
bool isGumdropHue(Color team) =>
    !isGray(team) &&
    ColorMath.hueDistance(ColorMath.lch(team).h, gumdropHue) <= sameHueDegrees;

/// [token]'s lightness in [team]'s hue, with chroma no higher than either's
/// (and a third of that for a gray team).
Color _derive(Color token, Lch team) {
  final t = ColorMath.lch(token);
  final chroma = math.min(t.c, team.c) * (team.c < grayChroma ? grayShare : 1);
  return ColorMath.fromLch(t.l, chroma, team.h);
}

/// How much of the chroma Gumdrop Pop Dark takes, so its tint is a lighter
/// touch than Light's.
const darkTeamShare = 0.5;

/// The most chroma a warm hue ([isWarmHue]) gets in Dark: a warm charcoal.
/// Any more at Dark's lightness reads brown.
const warmChroma = 5.0;

/// Whether [hue] is one that reads brown at Dark's lightness: orange to
/// yellow, 20° to 110° (Red, Maroon, Orange, Mustard, Yellow). Pink and
/// Olive are just outside.
bool isWarmHue(double hue) => hue >= 20 && hue <= 110;

/// Dark's [token] tinted for [team]: [token]'s L* in [team]'s hue, at half
/// the chroma ([darkTeamShare]), and no more than [warmChroma] for a warm
/// hue. A gray team's is [_derive]'s, so it stays gray.
Color _shadeDark(Color token, Lch team) {
  if (team.c < grayChroma) return _derive(token, team);
  final t = ColorMath.lch(token);
  var chroma = darkTeamShare * math.min(t.c, team.c);
  if (isWarmHue(team.h)) chroma = math.min(chroma, warmChroma);
  return ColorMath.fromLch(t.l, chroma, team.h);
}

/// The contrast a team color's hard shadow keeps against what it sits on in
/// Dark, and against Light's navy heading text.
const shadowContrast = 3.0;

/// [team] as a hard shadow on Dark's [background]: a whole L* step lighter
/// at a time, same hue and chroma, until it reaches [shadowContrast].
Color _darkShadow(Color team, Color background) {
  final t = ColorMath.lch(team);
  var shadow = team;
  for (
    var l = t.l.floorToDouble() + 1;
    ColorMath.contrast(shadow, background) < shadowContrast && l <= 100;
    l++
  ) {
    shadow = ColorMath.fromLch(l, t.c, t.h);
  }
  return shadow;
}

/// [team] as a hard shadow under Light's navy [text] on [background]: a
/// step lighter at a time until it's [shadowContrast] from the text (Black,
/// Maroon), then a step darker at a time while it would vanish on
/// [background] (under 2:1).
Color _lightShadow(Color team, Color text, Color background) {
  final t = ColorMath.lch(team);
  var shadow = team;
  var l = t.l.floorToDouble();
  while (ColorMath.contrast(shadow, text) < shadowContrast && l < 100) {
    shadow = ColorMath.fromLch(++l, t.c, t.h);
  }
  while (ColorMath.contrast(shadow, background) < 2 && l > 0) {
    shadow = ColorMath.fromLch(--l, t.c, t.h);
  }
  return shadow;
}

GumdropColors _tintDark(GumdropColors d, Color teamColor) {
  if (isGumdropHue(teamColor)) return d;
  final team = ColorMath.lch(teamColor);
  final page = _shadeDark(d.page, team);
  final surface = _shadeDark(d.surface, team);
  final raised = _shadeDark(d.raisedFace, team);
  final input = _shadeDark(d.inputFill, team);
  final line = _shadeDark(d.inputBorder, team);
  final shadow = _darkShadow(teamColor, page);
  return d.copyWith(
    page: page,
    surface: surface,
    raisedFace: raised,
    switchOffTrack: raised,
    inputFill: input,
    well: input,
    raisedLip: _shadeDark(d.raisedLip, team),
    inputBorder: line,
    divider: line,
    badgeRing: page,
    headingShadow: shadow,
    headingShadowOnCard: _darkShadow(teamColor, surface),
    pageShadow: shadow,
  );
}

GumdropColors _tintLight(GumdropColors l, Color teamColor) {
  if (isGumdropHue(teamColor)) return l;
  final team = ColorMath.lch(teamColor);
  final page = _derive(l.page, team);
  final chip = _derive(l.well, team);
  final border = _derive(l.raisedBorder, team);
  final shadow = _lightShadow(teamColor, l.headingText, page);
  return l.copyWith(
    page: page,
    inputFill: _derive(l.inputFill, team),
    well: chip,
    switchOffTrack: chip,
    surfaceBorder: _derive(l.surfaceBorder, team),
    raisedBorder: border,
    inputBorder: border,
    divider: border,
    raisedLip: _derive(l.raisedLip, team),
    badgeRing: page,
    headingShadow: shadow,
    headingShadowOnCard: _lightShadow(
      teamColor,
      l.headingTextOnCard,
      l.surface,
    ),
    pageShadow: shadow,
  );
}

const _white = Color(0xFFFFFFFF);

GumdropColors _tintCandy(GumdropColors c, Color teamColor) {
  final ink = c.ink;
  final team = ColorMath.lch(teamColor);
  var page = teamColor;
  // Neither white nor ink reads on it (Green): darken it, a whole L* step
  // at a time, until white does.
  if (math.max(
        ColorMath.contrast(_white, page),
        ColorMath.contrast(ink, page),
      ) <
      4.5) {
    for (var l = team.l.floorToDouble(); l >= 0; l--) {
      page = ColorMath.fromLch(l, team.c, team.h);
      if (ColorMath.contrast(_white, page) >= 4.5) break;
    }
  }
  final whiteText =
      ColorMath.contrast(_white, page) >= ColorMath.contrast(ink, page);
  final text = whiteText ? _white : ink;
  // Ink that would vanish on a dark page lifts to the team color 25 L*
  // lighter.
  final pageL = ColorMath.lch(page).l;
  final lifted = ColorMath.fromLch(math.min(pageL + 25, 60), team.c, team.h);
  final inkShows = ColorMath.contrast(ink, page) >= 2;
  final shadow = inkShows ? ink : lifted;
  Color orText(Color color) =>
      ColorMath.contrast(color, page) >= 4.5 ? color : text;
  // Candy on its own hue (lemon on Yellow) keeps an ink lip, so the FAB,
  // send, selected chips and the tab indicator still stand out.
  GumdropAccent edged(GumdropAccent a) => ColorMath.contrast(a.face, page) < 2
      ? GumdropAccent(face: a.face, lip: ink, text: a.text)
      : a;
  return c.copyWith(
    page: page,
    you: edged(c.you),
    lemon: edged(c.lemon),
    textOnPage: text,
    textMutedOnPage: orText(c.textMutedOnPage),
    successOnPage: orText(c.successOnPage),
    headingText: text,
    headingShadow: whiteText ? shadow : _white,
    pageShadow: shadow,
    // A badge in the page's own hue (Red) gets an ink ring, not a gap.
    badgeRing:
        ColorMath.hueDistance(
              ColorMath.lch(c.cherry.face).h,
              ColorMath.lch(page).h,
            ) <=
            sameHueDegrees
        ? ink
        : page,
  );
}
