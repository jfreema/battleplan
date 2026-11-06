import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/back_chevron.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The pieces of the Gumdrop settings screens (design §3.2, §3.5, §3.8,
/// §3.13, §3.18): the round back button and big title, cards of rows with
/// icon discs, card and page headings, caps field labels, and the team
/// color grid. Shared by Settings, Team settings, Create team, Invite,
/// Roster, Documents, and Plays.

/// The pushed-screen bar (SPEC §7.3): a 48 px back row with the chevron
/// and [backLabel] (the screen it goes back to) when there's somewhere to
/// go back to, and [actions] on its right as 48 px icon buttons; then the
/// title in Lilita 32 with the scheme's drop, 20 px from the left. The
/// title row grows with the text size.
PreferredSizeWidget gumdropAppBar(
  BuildContext context, {
  required String title,
  String? backLabel,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
  final scaler = MediaQuery.textScalerOf(context);
  final titleStyle = Theme.of(context).textTheme.headlineMedium
      ?.copyWith(fontSize: 32, height: 36 / 32);
  final titleHeight = 6 + scaler.scale(36) + 4;
  final under = bottom?.preferredSize.height ?? 0;
  return AppBar(
    toolbarHeight: 48,
    automaticallyImplyLeading: false,
    // The back row isn't the heading; the title below it is, and names
    // the route.
    excludeHeaderSemantics: true,
    titleSpacing: 4,
    title: canPop
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: BackChevron(label: backLabel),
          )
        : null,
    actions: actions,
    actionsPadding: const EdgeInsets.only(right: 4),
    bottom: PreferredSize(
      preferredSize: Size.fromHeight(titleHeight + under),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
            child: Semantics(
              header: true,
              namesRoute: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
          ),
          ?bottom,
        ],
      ),
    ),
  );
}

/// What a pushed screen's back label says, passed as GoRouter `extra` by
/// an opener other than the usual one ([label] null: the chevron alone).
@immutable
class BackLabel {
  const new(this.label);

  final String? label;
}

/// The back label for the screen at [context]: its opener's [BackLabel],
/// else [usual] (the screen it's normally opened from).
String? backLabelFrom(BuildContext context, String usual) {
  // A screen outside a GoRouter page (a test pumping it alone) has none.
  if (ModalRoute.of(context)?.settings is! Page<Object?>) return usual;
  final extra = GoRouterState.of(context).extra;
  return extra is BackLabel ? extra.label : usual;
}

/// The top bar of Teams and Profile (SPEC §7.3): 52 px, the [title] in
/// Lilita 27 with the scheme's drop, 20 px from the left, and [actions]
/// (48 px icon buttons) on the right.
class TopLevelBar extends StatelessWidget {
  const new({required this.title, this.actions = const [], super.key});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 52),
    child: Padding(
      padding: const EdgeInsets.only(left: 20, right: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Padding(
                // Level with the icons' center.
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // From the 32 px style, for its 2 px drop.
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontSize: 27, height: 30 / 27),
                ),
              ),
            ),
          ),
          ...actions,
        ],
      ),
    ),
  );
}

/// Rows straight on the page (SPEC §7.3): a 1 px hairline above the first
/// and under each.
class PageRows extends StatelessWidget {
  const new({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final line = Container(height: 1, color: GumdropColors.of(context).divider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line,
        for (final child in children) ...[child, line],
      ],
    );
  }
}

/// A row on the page (SPEC §7.3): at least 50 tall, a 22 px [icon] (or
/// [leading]) in the text color, the title in Nunito 700 16/21, the
/// subtitle in Nunito 600 14/19 muted, and a 20 px chevron when it opens
/// something. [destructive] puts the icon and title in the accent text.
class PageRow extends StatelessWidget {
  const new({
    required this.title,
    this.icon,
    this.leading,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.chevron = true,
    this.destructive = false,
    this.subtitleMaxLines = 1,
    super.key,
  });

  final String title;

  /// Null lets the subtitle wrap (an address).
  final int? subtitleMaxLines;
  final IconData? icon;
  final Widget? leading;
  final String? subtitle;
  final VoidCallback? onTap;

  /// In place of the chevron.
  final Widget? trailing;
  final bool chevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme;
    final color = destructive ? c.cherry.text : c.textOnPage;
    final sub = subtitle;
    final lead =
        leading ?? (icon == null ? null : Icon(icon, size: 22, color: color));
    final end =
        trailing ??
        (onTap != null && chevron
            ? Icon(
                AppIcons.chevronRight,
                size: 20,
                weight: 700,
                color: c.textMutedOnPage,
              )
            : null);
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: FocusRingInk(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (lead != null) ...[lead, const SizedBox(width: 14)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: text.bodyLarge?.copyWith(
                            fontSize: 16,
                            height: 21 / 16,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        if (sub != null && sub.isNotEmpty)
                          Text(
                            sub,
                            maxLines: subtitleMaxLines,
                            overflow: subtitleMaxLines == null
                                ? null
                                : TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 19 / 14,
                              fontWeight: FontWeight.w600,
                              color: c.textMutedOnPage,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (end != null) ...[
                    const SizedBox(width: 14),
                    // Gives way to the title at large text sizes, at most
                    // under half the row.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                      ),
                      child: end,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A section label on the page (SPEC §7.3): Fredoka 600 13/16, spaced
/// 0.12 em, capitals, muted. Screen readers hear it in plain case.
class SectionLabel extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text.toUpperCase(),
      semanticsLabel: text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 13,
        height: 16 / 13,
        letterSpacing: 13 * 0.12,
        color: GumdropColors.of(context).textMutedOnPage,
      ),
    ),
  );
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
      shape: GumdropStyle.of(context).cardShape(
        radius,
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
