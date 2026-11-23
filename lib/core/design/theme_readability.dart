import 'package:battleplan/core/camp_theme.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:material_ui/material_ui.dart' show Color;

/// What the theme editor won't save: a color nearly the same as what's
/// drawn on it (#83, owner's requests 2026-11-21: "put a protection in
/// there that prevents text and background from being the same color",
/// then "I only want to block colors that are nearly identical"), grouped
/// by the color that has to change to fix it.
enum ThemeProblem {
  /// The text and the page.
  textOnPage,

  /// The text and the tab bar or text boxes (on the page and on cards),
  /// which keep the base's colors.
  textOnBars,

  /// The text and the cards or pop-ups.
  textOnCard,

  /// The writing on the "you" color (buttons, your messages, unread
  /// counts) and the color itself.
  inkOnAccent,

  /// The "you" color and the page, a card, or the tab bar: the picked tab,
  /// unread dots, and buttons.
  accentHidden,
}

/// One color drawn on another, and what it means when they're nearly the
/// same.
typedef ThemePair = ({Color fg, Color bg, ThemeProblem problem, String what});

/// Every place [r]'s text or "you" color sits on a color a theme can
/// change. A see-through color counts as drawn over what it's on. The
/// colors that follow these (muted text, colored words, marks) are made to
/// read by `SchemeRoles.withOverrides`, so they aren't checked here; the
/// server checks the same pairs (`unreadableParts` in
/// functions/src/admin/themes.ts).
List<ThemePair> themePairs(SchemeRoles r) => [
  (fg: r.text, bg: r.page, problem: ThemeProblem.textOnPage, what: 'page'),
  for (final (bg, what) in [(r.tabbar, 'tab bar'), (r.field, 'text boxes')])
    (fg: r.text, bg: bg, problem: ThemeProblem.textOnBars, what: what),
  (
    fg: r.cardText,
    bg: r.cardField,
    problem: ThemeProblem.textOnBars,
    what: 'text boxes on cards',
  ),
  (fg: r.cardText, bg: r.card, problem: ThemeProblem.textOnCard, what: 'cards'),
  (fg: r.text, bg: r.popup, problem: ThemeProblem.textOnCard, what: 'pop-ups'),
  (
    fg: r.youInk,
    bg: r.you,
    problem: ThemeProblem.inkOnAccent,
    what: 'writing on buttons',
  ),
  for (final (bg, what) in [
    (r.page, 'buttons on page'),
    (r.card, 'buttons on cards'),
    (r.tabbar, 'picked tab on tab bar'),
  ])
    (fg: r.you, bg: bg, problem: ThemeProblem.accentHidden, what: what),
];

/// Under this ΔE two colors look nearly the same ([ColorMath.deltaE]):
/// the theme editor's line, and the server's.
const double nearlySame = 15;

/// How different [fg] looks from [bg], drawn over it if see-through.
double difference(Color fg, Color bg) =>
    ColorMath.deltaE(Color.alphaBlend(fg, bg), bg);

/// The pairs in [themed] whose colors are nearly the same, where in
/// [base], the colors it started from, they aren't: so a theme is never
/// refused for something it didn't change. Anything else goes, however it
/// reads; the Super Admin Panel is always drawn as the app ships, so a
/// theme can always be put right.
Set<ThemeProblem> themeProblems(SchemeRoles base, SchemeRoles themed) {
  final before = themePairs(base);
  final after = themePairs(themed);
  return {
    for (final (i, pair) in after.indexed)
      if (difference(pair.fg, pair.bg) < nearlySame &&
          difference(before[i].fg, before[i].bg) >= nearlySame)
        pair.problem,
  };
}

/// Whether [theme] over [scheme] can be drawn (#83): what the app shows, so
/// a theme saved before these checks, or by hand, with text the color of
/// its page is never drawn.
bool themeReads(TeamScheme scheme, ThemeOverride theme) {
  final base = SchemeRoles.builtIn(theme.base ?? scheme);
  return themeProblems(base, SchemeRoles.themed(scheme, theme)).isEmpty;
}

/// [themes] without any that fail [themeReads].
Map<TeamScheme, ThemeOverride> readableThemes(
  Map<TeamScheme, ThemeOverride> themes,
) => {
  for (final MapEntry(:key, :value) in themes.entries)
    if (themeReads(key, value)) key: value,
};

// ---- Boot Camp Mix (#88) ------------------------------------------------------

/// One Boot Camp Mix token drawn on another, as the theme editor's tokens
/// name them.
typedef CampPair = ({CampColor fg, CampColor bg, Color fgColor, Color bgColor});

/// Where [p]'s lettering and accents sit on a color the theme editor can
/// change (#88): the text on the page, the tab bar, and text boxes (Candy
/// Pop's are the camouflage's deeper blue, where its page's white reads),
/// the panels' text on them, the header's lettering on the camouflage, the
/// tags' ink lettering on the trim, the current tab's trim tile on the tab
/// bar, games, send and alerts on the page and on panels, and your messages
/// on the page. What the app makes read by itself (second lines, colored
/// words, the lettering on a colored block) isn't checked; the server checks
/// the same pairs (`unreadableCampParts` in functions/src/admin/themes.ts).
List<CampPair> campPairs(CampPalette p) {
  final field = p.panelText != p.text ? CampColor.camoGround : CampColor.panel;
  CampPair pair(CampColor fg, CampColor bg) =>
      (fg: fg, bg: bg, fgColor: p.colorOf(fg), bgColor: p.colorOf(bg));
  return [
    pair(CampColor.text, CampColor.page),
    pair(CampColor.text, CampColor.tabBar),
    pair(CampColor.text, field),
    pair(CampColor.panelText, CampColor.panel),
    pair(CampColor.headerLettering, CampColor.camoGround),
    pair(CampColor.ink, CampColor.mustard),
    pair(CampColor.mustard, CampColor.tabBar),
    pair(CampColor.red, CampColor.page),
    pair(CampColor.red, CampColor.panel),
    pair(CampColor.balloon, CampColor.page),
  ];
}

/// The pairs in [themed] whose colors are nearly the same, where in [base],
/// the scheme as it ships, they aren't: so a scheme is never refused for
/// what it has itself.
List<CampPair> campThemeProblems(CampPalette base, CampPalette themed) {
  final before = campPairs(base);
  return [
    for (final (i, pair) in campPairs(themed).indexed)
      if (ColorMath.deltaE(pair.fgColor, pair.bgColor) < nearlySame &&
          ColorMath.deltaE(before[i].fgColor, before[i].bgColor) >= nearlySame)
        pair,
  ];
}

/// [scheme]'s palette with the theme editor's [colors] (#88).
CampPalette editedPalette(TeamScheme scheme, CampColors colors) =>
    SchemeRoles.builtIn(scheme).palette.withColors({
      for (final MapEntry(:key, :value) in colors.entries) key: Color(value),
    });

/// Whether [theme]'s colors over [scheme] can be drawn (#88): what the app
/// shows, so colors saved by hand with text the color of its page never
/// are. Its header background (#91) is drawn from the colors, so it needs
/// no check of its own.
bool campThemeReads(TeamScheme scheme, CampTheme theme) => campThemeProblems(
  SchemeRoles.builtIn(scheme).palette,
  editedPalette(scheme, theme.colors),
).isEmpty;

/// [themes] without any that fail [campThemeReads].
Map<TeamScheme, CampTheme> readableCampThemes(
  Map<TeamScheme, CampTheme> themes,
) => {
  for (final MapEntry(:key, :value) in themes.entries)
    if (campThemeReads(key, value)) key: value,
};
