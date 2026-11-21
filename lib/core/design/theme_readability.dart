import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:material_ui/material_ui.dart' show Color;

/// What makes a theme hard to read (#82, #83, owner's request 2026-11-21:
/// "put a protection in there that prevents text and background from being
/// the same color"), grouped by the color that has to change to fix it.
enum ThemeProblem {
  /// Text on the page: the text, muted text, and colored text and marks.
  textOnPage,

  /// The text in the tab bar and text boxes (on the page and on cards),
  /// which keep the base's colors.
  textOnBars,

  /// Text on cards, sheets, and pop-ups.
  textOnCard,

  /// The writing on the "you" color: buttons, your messages, unread counts.
  inkOnAccent,

  /// The "you" color itself, hard to see on the page, a card, or the tab
  /// bar: the picked tab, unread dots, and buttons' edges.
  accentHidden,
}

/// One color drawn on another, how well it must read, and what it means
/// when it doesn't.
typedef ReadabilityPair = ({
  Color fg,
  Color bg,
  double minimum,
  ThemeProblem problem,
  String what,
});

/// Every place [r]'s writing or marks sit on a color a theme can change:
/// the spec's contrast table (Appendix A.4), plus the "you" color's. Text
/// needs 4.5:1, marks 3:1. A see-through color counts as drawn over what
/// it's on.
List<ReadabilityPair> readabilityPairs(SchemeRoles r) => [
  for (final (fg, bg, what) in [
    (r.text, r.page, 'text on page'),
    (r.pageMuted, r.page, 'muted text on page'),
    (r.accentText, r.page, 'red text on page'),
    (r.goingText, r.page, 'Going on page'),
    (r.maybeText, r.page, 'Maybe on page'),
    (r.gameText, r.page, 'Game on page'),
    (r.grapePageText, r.page, 'grape text on page'),
    (r.bubblegumPageText, r.page, 'bubblegum text on page'),
    (r.blueRaspberryPageText, r.page, 'blue raspberry text on page'),
  ])
    (
      fg: fg,
      bg: bg,
      minimum: 4.5,
      problem: ThemeProblem.textOnPage,
      what: what,
    ),
  (
    fg: r.notGoingIcon,
    bg: r.page,
    minimum: 3,
    problem: ThemeProblem.textOnPage,
    what: 'Not going x on page',
  ),
  (
    fg: r.accentMark,
    bg: r.page,
    minimum: 3,
    problem: ThemeProblem.textOnPage,
    what: 'marks on page',
  ),
  for (final (fg, bg, what) in [
    (r.text, r.tabbar, 'text on tab bar'),
    (r.pageMuted, r.tabbar, 'muted text on tab bar'),
    (r.text, r.field, 'text in text boxes'),
    (r.pageMuted, r.field, 'muted text in text boxes'),
    (r.cardText, r.cardField, 'text in text boxes on cards'),
    (r.cardMuted, r.cardField, 'muted text in text boxes on cards'),
  ])
    (
      fg: fg,
      bg: bg,
      minimum: 4.5,
      problem: ThemeProblem.textOnBars,
      what: what,
    ),
  for (final (fg, bg, what) in [
    (r.cardText, r.card, 'text on cards'),
    (r.cardMuted, r.card, 'muted text on cards'),
    (r.text, r.popup, 'text on pop-ups'),
    (r.cardMaybeText, r.card, 'Maybe on cards'),
    (r.cardGoingText, r.card, 'Going on cards'),
    (r.cardAccentText, r.card, 'red text on cards'),
    (r.typeGame, r.card, 'Game on cards'),
    (r.typePractice, r.card, 'Practice on cards'),
    (r.typeOther, r.card, 'other events on cards'),
    (r.blueRaspberryCardText, r.card, 'blue raspberry text on cards'),
  ])
    (
      fg: fg,
      bg: bg,
      minimum: 4.5,
      problem: ThemeProblem.textOnCard,
      what: what,
    ),
  (
    fg: r.youInk,
    bg: r.you,
    minimum: 4.5,
    problem: ThemeProblem.inkOnAccent,
    what: 'writing on buttons',
  ),
  for (final (bg, what) in [
    (r.page, 'buttons on page'),
    (r.card, 'buttons on cards'),
    (r.tabbar, 'picked tab on tab bar'),
  ])
    (
      fg: r.you,
      bg: bg,
      minimum: 3,
      problem: ThemeProblem.accentHidden,
      what: what,
    ),
];

/// How [fg] reads on [bg], drawn over it if see-through.
double readability(Color fg, Color bg) =>
    ColorMath.contrast(Color.alphaBlend(fg, bg), bg);

/// The problems [themed] has that [base], the colors it started from,
/// doesn't. Each pair must read as well as the standard (4.5:1 for text,
/// 3:1 for marks), or where the shipped theme itself reads less (coral on
/// Army green's olive page, 2.8:1), nearly as well as it does: so a theme
/// is never refused for something it didn't change, nor for a mark a shade
/// fainter than the theme it started from.
Set<ThemeProblem> themeProblems(SchemeRoles base, SchemeRoles themed) {
  final before = readabilityPairs(base);
  final after = readabilityPairs(themed);
  return {
    for (final (i, pair) in after.indexed)
      if (readability(pair.fg, pair.bg) <
          themeFloor(pair.minimum, readability(before[i].fg, before[i].bg)))
        pair.problem,
  };
}

/// The least a pair may read: [minimum], or nine tenths of what the
/// shipped theme reads where that's less, with a hair for rounding. The
/// server's check has the same rule (functions/src/admin/themes.ts).
double themeFloor(double minimum, double shipped) =>
    (shipped < minimum ? shipped * 0.9 : minimum) - 0.005;

/// Whether [theme] over [scheme] reads (#83): what the app shows, so a
/// theme saved before these checks, or by hand, that's hard to read is
/// never drawn.
bool themeReads(TeamScheme scheme, ThemeOverride theme) {
  final base = SchemeRoles.builtIn(theme.base ?? scheme);
  return themeProblems(base, SchemeRoles.themed(scheme, theme)).isEmpty;
}

/// [themes] without any that are hard to read ([themeReads]).
Map<TeamScheme, ThemeOverride> readableThemes(
  Map<TeamScheme, ThemeOverride> themes,
) => {
  for (final MapEntry(:key, :value) in themes.entries)
    if (themeReads(key, value)) key: value,
};
