import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The pieces of the Gumdrop settings screens (design §3.2, §3.5, §3.8,
/// §3.13, §3.18): the round back button and big title, cards of rows with
/// icon discs, card and page headings, caps field labels, and the team
/// color grid. Shared by Settings, Team settings, Create team, Invite,
/// Roster, Documents, and Plays.

/// The detail screens' bar: the round lemon back button (when there's
/// somewhere to go back to) and the screen's title in Lilita One 32.
PreferredSizeWidget gumdropAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
  return AppBar(
    toolbarHeight: 68,
    automaticallyImplyLeading: false,
    leadingWidth: canPop ? 14 + 48 + 12 : null,
    titleSpacing: canPop ? 0 : 16,
    leading: canPop
        ? const Padding(
            padding: EdgeInsets.only(left: 14, right: 12),
            child: Center(child: GumdropBackButton()),
          )
        : null,
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    actions: actions,
    actionsPadding: const EdgeInsets.only(right: 8),
    bottom: bottom,
  );
}

/// The round back button (design §3.2): a 48 px lemon circle with an ink
/// outline and a hard offset shadow, and a chevron.
class GumdropBackButton extends StatelessWidget {
  const new({this.onPressed, super.key});

  /// Defaults to popping the route.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: c.pageShadow, offset: const Offset(4, 4))],
      ),
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(AppIcons.chevronLeft, size: 30, weight: 700),
        style: IconButton.styleFrom(
          fixedSize: const Size(48, 48),
          minimumSize: const Size(48, 48),
          padding: EdgeInsets.zero,
          backgroundColor: c.lemon.face,
          foregroundColor: c.ink,
          shape: CircleBorder(side: BorderSide(color: c.ink, width: 2.5)),
        ),
      ),
    );
  }
}

/// A card (design §3.5): the surface, the theme's card outline, rounded
/// corners, no shadow, and its [child] in the card context. A [Material],
/// so list tiles, switches, and ink inside draw on it.
class SettingsPanel extends StatelessWidget {
  const new({
    required this.child,
    this.radius = Corners.card,
    this.padding = const EdgeInsets.all(12),
    super.key,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Material(
      color: c.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: c.surfaceBorderWidth == 0
            ? BorderSide.none
            : BorderSide(color: c.surfaceBorder, width: c.surfaceBorderWidth),
      ),
      child: GumdropSurface(
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A card of rows (design §3.5 "Settings list section"): the surface, 20
/// px corners, 12 px sides, and a 2 px divider between rows.
class SettingsCard extends StatelessWidget {
  const new({
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.divided = true,
    super.key,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  /// A divider above every row but the first.
  final bool divided;

  @override
  Widget build(BuildContext context) {
    return SettingsPanel(
      padding: padding,
      child: Builder(
        builder: (context) {
          final c = GumdropColors.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, child) in children.indexed) ...[
                if (divided && i > 0) Container(height: 2, color: c.divider),
                child,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A 36 px icon disc (design §3.8): the "you" candy with an ink icon for
/// the [highlighted] row, otherwise the well with a text-colored icon.
class RowDisc extends StatelessWidget {
  const new({
    required this.icon,
    this.highlighted = false,
    this.accent,
    this.size = 36,
    super.key,
  });

  final IconData icon;
  final bool highlighted;

  /// Another candy for the disc (red for delete, for one).
  final GumdropAccent? accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final candy = accent ?? (highlighted ? c.you : null);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: candy?.face ?? c.well,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size / 2,
        weight: 600,
        color: candy == null ? c.textPrimary : c.ink,
      ),
    );
  }
}

/// A settings row (design §3.8): a disc, the title in Nunito 900 15, a
/// muted subtitle, and a chevron when it opens something. A [ListTile] so
/// it keeps the tile's semantics and tap target.
class SettingsRow extends StatelessWidget {
  const new({
    required this.title,
    this.icon,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.highlighted = false,
    this.accent,
    this.titleColor,
    this.chevron = true,
    this.subtitleLines = 1,
    super.key,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final VoidCallback? onTap;

  /// In place of the chevron.
  final Widget? trailing;
  final bool highlighted;
  final GumdropAccent? accent;
  final Color? titleColor;

  /// A chevron at the end when [onTap] is set and there's no [trailing].
  final bool chevron;
  final int subtitleLines;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme;
    final sub = subtitle;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      minTileHeight: 56,
      horizontalTitleGap: 11,
      minLeadingWidth: 36,
      leading: icon == null
          ? null
          : RowDisc(icon: icon!, highlighted: highlighted, accent: accent),
      title: Text(
        title,
        style: text.bodyMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: titleColor ?? c.textPrimary,
        ),
      ),
      subtitle: sub == null || sub.isEmpty
          ? null
          : Text(
              sub,
              maxLines: subtitleLines,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: c.textMuted),
            ),
      trailing:
          trailing ??
          (onTap != null && chevron
              ? Icon(
                  AppIcons.chevronRight,
                  size: 22,
                  weight: 700,
                  color: c.textMuted,
                )
              : null),
    );
  }
}

/// A permission row's text style (design §3.8, §3.11): Nunito 800 15, in
/// the card's text color (a switch row sits on a card).
TextStyle? switchRowTitle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: GumdropColors.of(context).card.textPrimary,
    );

/// A heading inside a card (design §3.3): Lilita One 20, 3-step shadow, in
/// the card's heading colors.
class CardHeading extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context).card;
    return Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 20,
          height: 1.1,
          color: c.headingTextOnCard,
          shadows: GumdropColors.stackedShadow(c.headingShadowOnCard, 3),
        ),
      ),
    );
  }
}

/// A section heading on the page (design §3.3): Lilita One 22, 3-step
/// shadow.
class PageHeading extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

/// A field with its caps label above it (design §3.13): Fredoka 600 12,
/// spaced out, muted, 4 px over the field. The label also names the field
/// for screen readers.
class LabeledField extends StatelessWidget {
  const new({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(letterSpacing: 12 * 0.07, color: c.textMuted),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

/// The settings field look (design §3.13): 44 tall, 14 px corners, Nunito
/// 800 16. The fill and outline come from the theme.
InputDecoration gumdropField({String? hint, Widget? suffixIcon}) =>
    InputDecoration(
      hintText: hint,
      isDense: true,
      counterText: '',
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    );

/// The settings field text: Nunito 800 16.
TextStyle? gumdropFieldText(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge
        ?.copyWith(fontWeight: FontWeight.w800, height: 1.2);

/// A team color's name (TEAM-1), for its swatch's label, looked up by the
/// color itself; a color outside the palette is its hex.
String teamColorName(AppLocalizations l10n, int argb) => switch (argb |
    0xFF000000) {
  0xFF2F5BEA => l10n.colorBlue,
  0xFF7BAFD4 => l10n.colorLightBlue,
  0xFF1E3A5F => l10n.colorNavy,
  0xFF0E7490 => l10n.colorTeal,
  0xFF0F8A5F => l10n.colorGreen,
  0xFF4D7C0F => l10n.colorOlive,
  0xFFD4A017 => l10n.colorYellow,
  0xFFA16207 => l10n.colorMustard,
  0xFFC2410C => l10n.colorOrange,
  0xFFB91C1C => l10n.colorRed,
  0xFF7F1D1D => l10n.colorMaroon,
  0xFFBE185D => l10n.colorPink,
  0xFF7C3AED => l10n.colorPurple,
  0xFF334155 => l10n.colorGray,
  0xFF111111 => l10n.colorBlack,
  _ => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
};

/// The team color picker (design §3.18): 34 px swatches eight to a row,
/// spread across, the picked one ringed in the page color and the text
/// color with a white check. With [allowNone], a "No color" swatch first.
class TeamColorGrid extends StatelessWidget {
  const new({
    required this.selected,
    required this.onPick,
    this.allowNone = false,
    super.key,
  });

  final int? selected;
  final ValueChanged<int?> onPick;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <int?>[if (allowNone) null, ...teamColorValues];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Eight across, spread over a phone's width; no wider than 416 on a
        // big screen, so the swatches don't drift apart.
        final width = math.min(constraints.maxWidth, 8 * 52.0);
        final columns = (width / 40).floor().clamp(4, 8);
        final cell = width / columns;
        return Wrap(
          children: [
            for (final argb in options)
              SizedBox(
                width: cell,
                height: 48,
                child: _Swatch(
                  argb: argb,
                  selected: argb == selected,
                  label: argb == null
                      ? l10n.noTeamColor
                      : teamColorName(l10n, argb),
                  onTap: () => onPick(argb),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const new({
    required this.argb,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final int? argb;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final color = argb == null ? c.well : Color(argb!);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: selected
                  ? [
                      BoxShadow(color: c.selectedRingOuter, spreadRadius: 5.5),
                      BoxShadow(color: c.background, spreadRadius: 3),
                    ]
                  : null,
            ),
            foregroundDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.swatchInsetRing, width: 2),
            ),
            child: argb == null
                ? Icon(
                    selected ? AppIcons.check : AppIcons.close,
                    size: 18,
                    weight: 700,
                    color: c.textPrimary,
                  )
                : selected
                ? const Icon(
                    AppIcons.check,
                    size: 20,
                    weight: 800,
                    // The check is white on every team color (design 1c).
                    color: GumdropColors.switchKnob,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
