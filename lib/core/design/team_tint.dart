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
///   A team hue within 25° of Gumdrop's own navy hue (Blue, Royal blue,
///   Navy, Slate) keeps the default colors: it's the theme's own.
/// - **Candy** uses the team color itself as the page, darkened along L*
///   until white text reads when neither white nor ink does (Green). Text
///   on the page is whichever of white and ink reads better (ink on Light
///   blue and Yellow), its heading shadow the other one; shadows on the page
///   that would vanish (ink on Slate and Navy) use the team color 25 L*
///   lighter. Cards, ink, and the candies don't change.
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

/// Whether [team] is close enough to Gumdrop's own navy to leave Dark and
/// Light untinted.
bool isGumdropHue(Color team) =>
    ColorMath.hueDistance(ColorMath.lch(team).h, gumdropHue) <= sameHueDegrees;

/// [token]'s lightness in [team]'s hue, with chroma no higher than either's.
Color _derive(Color token, Lch team) {
  final t = ColorMath.lch(token);
  return ColorMath.fromLch(t.l, math.min(t.c, team.c), team.h);
}

GumdropColors _tintDark(GumdropColors d, Color teamColor) {
  if (isGumdropHue(teamColor)) return d;
  final team = ColorMath.lch(teamColor);
  final page = _derive(d.page, team);
  final raised = _derive(d.raisedFace, team);
  final input = _derive(d.inputFill, team);
  final line = _derive(d.inputBorder, team);
  return d.copyWith(
    page: page,
    surface: _derive(d.surface, team),
    raisedFace: raised,
    switchOffTrack: raised,
    inputFill: input,
    well: input,
    raisedLip: _derive(d.raisedLip, team),
    inputBorder: line,
    divider: line,
    badgeRing: page,
  );
}

GumdropColors _tintLight(GumdropColors l, Color teamColor) {
  if (isGumdropHue(teamColor)) return l;
  final team = ColorMath.lch(teamColor);
  final page = _derive(l.page, team);
  final chip = _derive(l.well, team);
  final border = _derive(l.raisedBorder, team);
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
