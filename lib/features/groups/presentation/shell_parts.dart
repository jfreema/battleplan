import 'dart:math' as math;

import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/team_tint.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The lemon sticker under the team name (Gumdrop Pop design §3.4): what
/// the tab is, in capitals, tilted a little, with an ink outline and a hard
/// shadow. Screen readers hear it in plain case.
class TeamSticker extends StatelessWidget {
  const new(this.label, {super.key});

  final String label;

  /// The sticker for tab [index] (Chat, Schedule, Documents, Plays); the
  /// schedule's names the season it's in on [now].
  static String labelFor(AppLocalizations l10n, int index, DateTime now) =>
      switch (index) {
        0 => l10n.stickerChat,
        1 => switch (now.month) {
          12 || 1 || 2 => l10n.stickerScheduleWinter,
          3 || 4 || 5 => l10n.stickerScheduleSpring,
          6 || 7 || 8 => l10n.stickerScheduleSummer,
          _ => l10n.stickerScheduleFall,
        },
        2 => l10n.stickerDocuments,
        _ => l10n.stickerPlays,
      };

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final style = GumdropStyle.of(context);
    final text = Text(
      label.toUpperCase(),
      maxLines: 1,
      style: style.display(
        TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 15,
          height: 1.2,
          letterSpacing: 15 * 0.03,
          color: c.ink,
        ),
      ),
    );
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      // In a theme whose gumdrops lean (Gumdrop Arena), the sticker leans
      // with them, flat, with an ink outline only on a page it would melt
      // into (a Yellow team's).
      child: style.slant != 0
          ? Container(
              padding: const EdgeInsets.fromLTRB(15, 4, 15, 4),
              decoration: ShapeDecoration(
                color: c.sticker.face,
                shape: GumdropShape(
                  lip: 0,
                  highlight: 0,
                  radius: const BorderRadius.all(Radius.circular(3)),
                  slant: style.slant,
                  side:
                      ColorMath.contrast(c.sticker.face, c.page) < edgeContrast
                      ? BorderSide(color: c.ink, width: 2)
                      : BorderSide.none,
                ),
              ),
              child: text,
            )
          : Transform.rotate(
              angle: -2 * math.pi / 180,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 3, 12, 4),
                decoration: BoxDecoration(
                  color: c.sticker.face,
                  border: Border.all(color: c.ink, width: 2.5),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: c.pageShadow, offset: const Offset(3, 3)),
                  ],
                ),
                child: text,
              ),
            ),
    );
  }
}

/// The floating tab bar (design §3.12): a rounded surface panel, 16 px in
/// from the sides and 18 above the bottom (and the home indicator), holding
/// [child], the Material [NavigationBar] the theme draws with gumdrop
/// indicators.
class FloatingTabBar extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(18, bottom)),
      child: _Panel(
        colors: c,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          // The bar's own safe area is this panel's margin.
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The wide layout's rail as a floating rounded surface panel, as the tab
/// bar is (design §3.12).
class FloatingRail extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 18),
        child: _Panel(colors: c, child: child),
      ),
    );
  }
}

/// The surface panel behind the tab bar and the rail, with the card
/// outline and a 26 px radius.
class _Panel extends StatelessWidget {
  const new({required this.colors, required this.child});

  final GumdropColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = 26.0;
    final style = GumdropStyle.of(context);
    // The panel is a card: in Candy its text and icons are the card's
    // ink, not the page's white.
    final surface = GumdropSurface(child: child);
    return DecoratedBox(
      decoration: style.cardDecoration(
        colors.surface,
        radius,
        side: colors.surfaceBorderWidth == 0
            ? BorderSide.none
            : BorderSide(
                color: colors.surfaceBorder,
                width: colors.surfaceBorderWidth,
              ),
      ),
      child: style.cardCut > 0
          ? ClipPath(
              clipper: ShapeBorderClipper(shape: style.cardShape(radius)),
              child: surface,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: surface,
            ),
    );
  }
}
