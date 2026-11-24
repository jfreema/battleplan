import 'dart:math' as math;

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/camp_lettering.dart';
import 'package:battleplan/core/widgets/candy_sprinkles.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The team switcher in the header (SPEC §5.2, §7.3): the tab's stencil
/// [eyebrow] over the team's [name] in the stencil outlined,
/// and a small chevron. One button, at least 48 tall, with the 3 px focus
/// ring for the keyboard. Screen readers hear the eyebrow in plain case,
/// then "Switch team: {name}". News in other teams is the back arrow's one
/// dot (#13, 2026-11-16); the switcher's list has each team's count.
class TeamSwitcherButton extends StatelessWidget {
  const new({
    required this.name,
    required this.onPressed,
    this.eyebrow,
    super.key,
  });

  final String name;

  /// What the tab is ("Team chat"), or null for the name alone.
  final String? eyebrow;
  final VoidCallback onPressed;

  /// The stencil eyebrow's style: the stencil 12/14, spaced 0.18 em, in
  /// the page's muted text (#12).
  static TextStyle eyebrowStyle(GumdropColors c) => TextStyle(
    fontFamily: AppFonts.sticker,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 14 / 12,
    letterSpacing: 12 * 0.18,
    color: c.textMutedOnPage,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final above = eyebrow;
    // The chevron, 18 px in a 20 × 30 box, 1 px low.
    final chevron = SizedBox(
      width: 20,
      height: 30,
      child: Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(
          AppIcons.expand,
          size: 18,
          weight: 700,
          color: c.textOnPage,
        ),
      ),
    );
    return Semantics(
      container: true,
      button: true,
      label: [?above, '${l10n.switchTeamTooltip}: $name'].join('. '),
      excludeSemantics: true,
      // The InkWell's own tap is excluded with its semantics.
      onTap: onPressed,
      child: FocusRingInk(
        radius: BorderRadius.circular(Corners.tile),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: TeamTitle(
            name: name,
            eyebrow: above,
            eyebrowStyle: eyebrowStyle(c),
            trailing: Padding(
              padding: const EdgeInsets.only(left: 3),
              child: chevron,
            ),
          ),
        ),
      ),
    );
  }
}

/// How a team's name fits its room ([TeamName.fitIn]): its style, on one
/// line or two, and how wide two lines may be.
@immutable
class TeamNameFit {
  const new({required this.style, this.lines = 1, this.width});

  final TextStyle style;

  /// 1, or 2 for a name that wraps.
  final int lines;

  /// For two lines, the width to wrap them in: the longer line of the most
  /// even break, so the lines come out as even as they can be ("Android /
  /// App Testers", not a lone last word); null for its whole room.
  final double? width;

  bool get wraps => lines > 1;
}

/// The stencil [eyebrow] over a team's [name], as the header shows them,
/// with [trailing] (the switcher's ▾) beside the name. While the name
/// takes two lines the eyebrow steps aside, so the header keeps its one
/// slim row (#13, 2026-11-16); screen readers still hear it.
class TeamTitle extends StatelessWidget {
  const new({
    required this.name,
    required this.eyebrowStyle,
    this.eyebrow,
    this.trailing,
    super.key,
  });

  final String name;
  final String? eyebrow;
  final TextStyle eyebrowStyle;
  final Widget? trailing;

  /// The room [trailing] takes: the switcher's 3 px gap and 20 px ▾.
  static const double trailingWidth = 23;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Less the outlined name's 6 px for its stroke and shadow.
      final room =
          constraints.maxWidth - (trailing == null ? 0 : trailingWidth) - 6;
      final fit = TeamName.fitIn(context, name, math.max(0, room));
      final above = eyebrow;
      // Over a two-line name the eyebrow would stack three lines into the
      // slim row; it steps aside instead (compared both ways 2026-11-16:
      // the name stays bigger and the row calmer).
      final showEyebrow = above != null && !fit.wraps;
      // The header's sprinkles keep off the tag and the name (#98).
      return SprinkleKeepOut(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Boot Camp Mix (#85): the eyebrow on a mustard tag, tucked
            // just over the name.
            if (showEyebrow)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 1),
                child: CampTag(above, semanticsLabel: above),
              )
            else if (above != null)
              // Stepped aside for a two-line name, but still read.
              Semantics(label: above, child: const SizedBox.shrink()),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: TeamName(name, fit: fit)),
                ?trailing,
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// A team's name in the stencil outlined (SPEC §7.3).
///
/// On one line at 27, stepping down to 23, 21 and 19 to fit. A name that
/// doesn't fit even at 19 wraps onto two lines at 19, or at 17, breaking
/// only between words; only a name too long for two lines at 17 ends in
/// "…" (#13, 2026-11-16: names over about 15 letters, and about 10 beside
/// a super admin's Admin panel button, used to be cut, as "Android Ap…").
class TeamName extends StatelessWidget {
  const new(this.name, {this.fit, super.key});

  final String name;

  /// How it fits, when the caller measured it ([TeamTitle]); measured here
  /// otherwise.
  final TeamNameFit? fit;

  /// The sizes tried on one line, largest first: the stencil is narrow,
  /// so they're bigger than Open Field's were (#85).
  static const List<double> sizes = [32, 28, 25, 22];

  /// The sizes tried on two lines, largest first.
  static const List<double> wrapSizes = [22, 19];

  /// Two lines' height: set solid, so they read as one name and two lines
  /// at 22 with the shadow's room fit the one-row header (#85).
  static const double wrapHeight = 1;

  /// The tallest two lines may make the header, in pixels, at large text
  /// sizes; above it the name stays on one line and ends in "…".
  static const double tallestWrap = 96;

  static TextStyle _heading(BuildContext context, double size) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontSize: size,
        height: 37 / 32.5,
        letterSpacing: size * 0.04,
        shadows: const [],
      );

  /// How [name] fits [maxWidth]: the first one-line size that holds it,
  /// else two lines, else two lines ending in "…" (one line where a single
  /// word is wider than a line, which two lines would break).
  static TeamNameFit fitIn(BuildContext context, String name, double maxWidth) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    bool fits(TextStyle style, int lines) {
      final painter = TextPainter(
        text: TextSpan(text: name, style: style),
        maxLines: lines,
        textDirection: direction,
        textScaler: scaler,
      )..layout(maxWidth: maxWidth);
      final ok = !painter.didExceedMaxLines;
      painter.dispose();
      return ok;
    }

    double widthOf(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final words = name.trim().split(RegExp(r'\s+'));

    // The widest single word, which two lines can't break.
    double widestWord(TextStyle style) =>
        words.map((w) => widthOf(w, style)).fold(0, math.max);

    // The narrowest width two lines fit in, breaking between words: the
    // longer line of the most even break. Wrapped in it, the text breaks
    // there by itself (any break that fits it is as even). Null when no
    // break fits both lines in [maxWidth].
    double? balanced(TextStyle style) {
      double? best;
      for (var i = 1; i < words.length; i++) {
        final longer = math.max(
          widthOf(words.take(i).join(' '), style),
          widthOf(words.skip(i).join(' '), style),
        );
        if (longer <= maxWidth && (best == null || longer < best)) {
          best = longer;
        }
      }
      return best;
    }

    for (final size in sizes) {
      final style = _heading(context, size);
      if (fits(style, 1)) return TeamNameFit(style: style);
    }
    const wrapping = wrapSizes;
    const height = wrapHeight;
    // Two lines only while they leave the header a sensible height: at the
    // largest text sizes the name stays on one line.
    bool shortEnough(double size) =>
        2 * scaler.scale(size) * height + 2 <= tallestWrap;
    for (final size in wrapping) {
      final style = _heading(context, size).copyWith(height: height);
      if (!shortEnough(size)) continue;
      if (balanced(style) case final width?) {
        return TeamNameFit(style: style, lines: 2, width: width);
      }
    }
    final last = _heading(context, wrapping.last).copyWith(height: height);
    if (shortEnough(wrapping.last) && widestWord(last) <= maxWidth) {
      return TeamNameFit(style: last, lines: 2);
    }
    return TeamNameFit(style: _heading(context, wrapping.last));
  }

  @override
  Widget build(BuildContext context) {
    Widget text(TeamNameFit fit) {
      // Boot Camp Mix (#85): white stencil on an ink stroke, with a hard
      // shadow.
      Widget name = OutlinedText(
        this.name,
        maxLines: fit.lines,
        overflow: TextOverflow.ellipsis,
        // As wide as its longest line, so the switcher's ▾ sits beside a
        // two-line name rather than at the far side of its room.
        textWidthBasis: TextWidthBasis.longestLine,
        style: fit.style,
      );
      if (fit.width case final width?) {
        // A hair over, so rounding never pushes a word to a third line.
        name = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width + 1),
          child: name,
        );
      }
      // Room for the stroke and the shadow.
      return Padding(
        padding: const EdgeInsets.only(left: 2, right: 4, bottom: 3),
        child: name,
      );
    }

    final given = fit;
    if (given != null) return text(given);
    return LayoutBuilder(
      builder: (context, constraints) =>
          text(fitIn(context, name, constraints.maxWidth)),
    );
  }
}
