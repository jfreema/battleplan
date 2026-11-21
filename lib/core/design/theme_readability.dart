import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/schemes.dart';

/// What the theme editor (#82) won't save: a color a theme changed that
/// leaves something unreadable (WCAG AA, 4.5:1, as every built-in scheme's
/// text is).
enum ThemeProblem {
  /// The scheme's text on the new background.
  textOnPage,

  /// The card's text on the new card color.
  textOnCard,

  /// The candy ink (button writing, your messages) on the new "you" color.
  inkOnAccent,
}

/// The problems [themed] has that [base], the colors it started from,
/// doesn't: so a theme is never refused for something it didn't change.
Set<ThemeProblem> themeProblems(SchemeRoles base, SchemeRoles themed) =>
    _problems(themed).difference(_problems(base));

Set<ThemeProblem> _problems(SchemeRoles r) => {
  if (ColorMath.contrast(r.text, r.page) < _minimum) ThemeProblem.textOnPage,
  if (ColorMath.contrast(r.cardText, r.card) < _minimum)
    ThemeProblem.textOnCard,
  if (ColorMath.contrast(r.candyInk, r.you) < _minimum)
    ThemeProblem.inkOnAccent,
};

const _minimum = 4.5;
