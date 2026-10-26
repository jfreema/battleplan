import 'dart:math' as math;

import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:material_ui/material_ui.dart';

/// A team's color behind every screen inside the team (TEAM-1): the theme's
/// [base] colors with the page in [teamColor] (ARGB, from `groups.color`).
/// Null leaves [base] as it is.
///
/// The page is the team's own color, not a blend, in every theme, as in the
/// Rounded Candy Pop design the picker comes from: darkened along L* only
/// when neither white nor ink would read on it (Green). Each theme keeps its
/// own cards, buttons, inputs, and candies (navy cards in Dark, white in
/// Light and Candy), so the page is a [GumdropColors.coloredPage]:
/// - Text on the page is whichever of white and ink reads better (ink on
///   Light blue and Yellow), and its heading shadow the other one. Muted
///   and success text keep the theme's colors where they read on the page,
///   and are the page's text color where they don't.
/// - Hard shadows on the page (the back button, the sticker) are ink, or
///   the team color 25 L* lighter where ink would vanish (Gray, Navy,
///   Black, Maroon).
/// - A candy too close to the page (lemon on Yellow, tangerine on Orange)
///   gets an ink lip, and so do the secondary buttons, so they still stand
///   out; a red team's unread badge gets an ink ring.
///
/// Blue and Navy are Gumdrop's own navy ([isGumdropHue]): Dark and Light
/// keep their own pages for them, so the theme looks as designed for the
/// default team color. Candy's page is already blue, and takes the team's.
GumdropColors teamTinted(GumdropColors base, int? teamColor) {
  if (teamColor == null) return base;
  final untinted = GumdropColors.forFlavor(base.flavor);
  final team = Color(teamColor).withAlpha(255);
  final keepsOwnPage = base.flavor != GumdropFlavor.candy && isGumdropHue(team);
  final tinted = (keepsOwnPage ? untinted : _onTeamPage(untinted, team))
      .copyWith(teamColor: team);
  return base.onCard ? tinted.card : tinted;
}

/// Gumdrop's own hue: halfway between the Dark and Light pages' hues
/// (about 283°, a navy blue).
final double gumdropHue =
    (ColorMath.lch(GumdropColors.dark.page).h +
        ColorMath.lch(GumdropColors.light.page).h) /
    2;

/// How close to [gumdropHue] a team's hue may be and still be the theme's
/// own color.
const sameHueDegrees = 25.0;

/// Team colors with less chroma than this are grays (Gray, Black), whatever
/// their hue: never the theme's own navy.
const grayChroma = 20.0;

/// Whether [team] is a gray (Gray, Black) rather than a color.
bool isGray(Color team) => ColorMath.lch(team).c < grayChroma;

/// Whether [team] is Gumdrop's own navy (Blue, Navy): colorful, and within
/// [sameHueDegrees] of [gumdropHue]. Dark and Light keep their own pages
/// for it.
bool isGumdropHue(Color team) =>
    !isGray(team) &&
    ColorMath.hueDistance(ColorMath.lch(team).h, gumdropHue) <= sameHueDegrees;

/// Under this contrast with the page, a candy or a secondary button gets an
/// ink lip (and the button an ink outline), so it doesn't melt into it.
const edgeContrast = 2.0;

const _white = Color(0xFFFFFFFF);

/// [c] with [teamColor] as the page.
GumdropColors _onTeamPage(GumdropColors c, Color teamColor) {
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
  // On the theme's own page (Candy's blue for a Blue team), the candies and
  // buttons are as designed.
  final own = ColorMath.lch(c.page);
  final now = ColorMath.lch(page);
  final ownPage =
      (now.l - own.l).abs() <= 5 &&
      (now.c - own.c).abs() <= 10 &&
      ColorMath.hueDistance(now.h, own.h) <= 10;
  // A candy on its own hue keeps an ink lip, so the FAB, send, selected
  // chips, and the tab indicator still stand out.
  GumdropAccent edged(GumdropAccent a) =>
      !ownPage && ColorMath.contrast(a.face, page) < edgeContrast
      ? GumdropAccent(face: a.face, lip: ink, text: a.text)
      : a;
  // So does a secondary button that would melt into the page (Dark's navy
  // buttons on Gray or Black, Light's white ones on Yellow), with an ink
  // outline too.
  final melts =
      !ownPage && ColorMath.contrast(c.raisedFace, page) < edgeContrast;
  return c.copyWith(
    coloredPage: true,
    page: page,
    you: edged(c.you),
    blueRaspberry: edged(c.blueRaspberry),
    lemon: edged(c.lemon),
    mint: edged(c.mint),
    cherry: edged(c.cherry),
    tangerine: edged(c.tangerine),
    grape: edged(c.grape),
    bubblegum: edged(c.bubblegum),
    raisedBorder: melts ? ink : null,
    raisedBorderWidth: melts ? 2 : null,
    raisedLip: melts ? ink : null,
    textOnPage: text,
    textMutedOnPage: orText(c.textMutedOnPage),
    successOnPage: orText(c.successOnPage),
    headingText: text,
    headingShadow: whiteText ? shadow : _white,
    pageShadow: shadow,
    selectedRingOuter: text,
    // A badge in the page's own hue (Red, Maroon) gets an ink ring, not a
    // gap.
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
