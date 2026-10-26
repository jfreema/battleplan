import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The schedule's Gumdrop Pop pieces (design §3.15, §3.16): cards, the date
/// block, the going bar, answer discs, stat tiles, and the RSVP gumdrops.

/// A tappable card (design §3.5): the surface, the theme's outline, no
/// shadow, and its [child] in the card's colors ([GumdropSurface]).
class TapCard extends StatelessWidget {
  const new({
    required this.child,
    this.onTap,
    this.radius = Corners.card,
    this.padding = const EdgeInsets.fromLTRB(9, 9, 12, 9),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final shape = GumdropStyle.of(context).cardShape(
      radius,
      side: c.surfaceBorderWidth == 0
          ? BorderSide.none
          : BorderSide(color: c.surfaceBorder, width: c.surfaceBorderWidth),
    );
    return GumdropSurface(
      child: Material(
        color: c.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The 58 x 74 candy date block: "OCT" over "19" over "MON" in ink on the
/// event type's color (design §3.15). It reads as the type and the day.
class DateBlock extends StatelessWidget {
  const new({
    required this.day,
    required this.accent,
    required this.semanticLabel,
    super.key,
  });

  final DateTime day;
  final GumdropAccent accent;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = GumdropColors.of(context).ink;
    final label = GumdropStyle.of(context)
        .label(TextStyle(fontWeight: FontWeight.w600, color: ink, height: 1));
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        width: 58,
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: accent.face,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat.MMM(l10n.localeName).format(day).toUpperCase(),
              style: label.copyWith(fontSize: 12, letterSpacing: 12 * 0.08),
            ),
            const SizedBox(height: 3),
            Text(
              '${day.day}',
              style: label.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat.E(l10n.localeName).format(day).toUpperCase(),
              style: label.copyWith(
                fontFamily: AppFonts.body,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 11 * 0.06,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The going bar: an 8 px well track with [fraction] of it mint (design
/// §3.15). Decoration only; the words beside it say the same.
class GoingBar extends StatelessWidget {
  const new({required this.fraction, super.key});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return ExcludeSemantics(
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: c.well,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0, 1),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.mint.face,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

/// An answer as a candy disc (design §3.9, §3.15): a mint check, a lemon
/// "?", or a cherry X, in ink; no answer is an empty ring. [label], when
/// given, is what it reads as.
class AnswerDisc extends StatelessWidget {
  const new({
    required this.status,
    this.size = 30,
    this.label,
    this.face,
    super.key,
  });

  final RsvpStatus? status;
  final double size;
  final String? label;

  /// The disc's fill, if not the answer's own candy (the selected RSVP
  /// button's ink tint).
  final Color? face;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final s = status;
    final icon = size * 0.56;
    final Widget disc;
    if (s == null) {
      disc = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.textMuted, width: 2.5),
        ),
      );
    } else {
      disc = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: face ?? statusAccent(context, s).face,
          shape: BoxShape.circle,
        ),
        child: switch (s) {
          RsvpStatus.going => Icon(
            AppIcons.check,
            size: icon,
            color: c.ink,
            weight: 700,
          ),
          RsvpStatus.notGoing => Icon(
            AppIcons.close,
            size: icon,
            color: c.ink,
            weight: 700,
          ),
          RsvpStatus.maybe => Text(
            '?',
            textScaler: TextScaler.noScaling,
            style: GumdropStyle.of(context).label(
              TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: size * 0.63,
                height: 1,
                color: c.ink,
              ),
            ),
          ),
        },
      );
    }
    if (label == null) return ExcludeSemantics(child: disc);
    return Semantics(label: label, excludeSemantics: true, child: disc);
  }
}

/// A count tile (design §3.16): a big number in [color] over a small
/// muted label, on a card.
class StatTile extends StatelessWidget {
  const new({
    required this.count,
    required this.label,
    required this.color,
    super.key,
  });

  final int count;
  final String label;

  /// The number's color, picked in the card's context, or null for the
  /// card's text color.
  final Color? Function(BuildContext card) color;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return DecoratedBox(
      decoration: GumdropStyle.of(context).cardDecoration(
        c.surface,
        Corners.tile,
        side: c.surfaceBorderWidth == 0
            ? BorderSide.none
            : BorderSide(color: c.surfaceBorder, width: c.surfaceBorderWidth),
      ),
      child: GumdropSurface(
        child: Builder(
          builder: (card) {
            final cc = GumdropColors.of(card);
            return MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 9, 4, 9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count',
                      style: GumdropStyle.of(context).label(
                        TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 28,
                          height: 1,
                          color: color(card) ?? cc.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: cc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A person's initials on a candy circle (design §3.9), the candy picked
/// from [colorKey] as [Avatar] picks it, so a person has one color
/// everywhere.
class CandyInitials extends StatelessWidget {
  const new({
    required this.name,
    required this.colorKey,
    this.size = 40,
    super.key,
  });

  final String name;
  final String colorKey;
  final double size;

  static String initialsOf(String name) {
    final parts = name
        .replaceAll(RegExp(r'#\S*'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Avatar.colorFor(c, colorKey),
          shape: BoxShape.circle,
        ),
        child: Text(
          initialsOf(name),
          textScaler: TextScaler.noScaling,
          style: GumdropStyle.of(context).label(
            TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: size * 0.375,
              height: 1,
              color: c.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small pill that isn't a button (the reminder beside Directions),
/// drawn as the secondary gumdrop Directions is (a 40 px face on a 4 px
/// lip) so the two match; it has no tap.
class InfoPill extends StatelessWidget {
  const new({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return GumdropSurface(
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        // The label rides on the face, above the lip.
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        decoration: ShapeDecoration(
          color: c.raisedFace,
          shape: GumdropStyle.of(context).styled(
            GumdropShape(
              lipColor: c.raisedLip,
              highlight: 1.5,
              highlightColor: c.raisedHighlight,
              radius: BorderRadius.circular(20),
              side: c.raisedBorderWidth == 0
                  ? BorderSide.none
                  : BorderSide(
                      color: c.raisedBorder,
                      width: c.raisedBorderWidth,
                    ),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: c.textPrimary),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                text,
                style: GumdropStyle.of(context).label(
                  TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The RSVP choice (design §3.16): Going, Maybe, and Not going as three
/// 54 px gumdrops with a gap between, built on [SegmentedButton] so it keeps
/// its selection semantics and keyboard behavior. The chosen answer is its
/// own candy (mint, lemon, or cherry) with ink on it; the others are
/// secondary gumdrops with their candy disc. [compact] (the chat card) is
/// 48 tall without the discs.
class RsvpChoice extends StatelessWidget {
  const new({
    required this.statuses,
    required this.current,
    required this.onChanged,
    this.compact = false,
    super.key,
  });

  final List<RsvpStatus> statuses;
  final RsvpStatus? current;

  /// Null when it can't be changed (past the deadline, say).
  final ValueChanged<RsvpStatus>? onChanged;
  final bool compact;

  static const double _gap = 9;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final height = compact ? 48.0 : 58.0;
    final enabled = onChanged != null;
    final n = statuses.length;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<RsvpStatus>(
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        segments: [
          for (final (i, s) in statuses.indexed)
            ButtonSegment(
              value: s,
              // The segments are equal, so each gives up the same share of
              // the gaps: none at the outer edges, [_gap] between.
              label: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: _gap * i / n,
                  end: _gap * (n - 1 - i) / n,
                ),
                child: _RsvpGumdrop(
                  status: s,
                  label: statusLabel(l10n, s),
                  selected: s == current,
                  enabled: enabled,
                  compact: compact,
                  height: height,
                ),
              ),
            ),
        ],
        selected: {?current},
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          // Only keyboard focus shows; the gumdrops draw the rest.
          overlayColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused)
                ? GumdropColors.of(context).textOnPage.withValues(alpha: 0.16)
                : Colors.transparent,
          ),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          minimumSize: WidgetStatePropertyAll(Size(48, height)),
          elevation: const WidgetStatePropertyAll(0),
          splashFactory: NoSplash.splashFactory,
          // Already 48 or taller; padding would clip the gumdrops' tops.
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onSelectionChanged: enabled
            ? (s) {
                // Tapping the chosen answer again keeps it.
                if (s.isEmpty) return;
                onChanged!(s.first);
              }
            : null,
      ),
    );
  }
}

/// One RSVP gumdrop, drawn inside its segment.
class _RsvpGumdrop extends StatelessWidget {
  const new({
    required this.status,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.height,
  });

  final RsvpStatus status;
  final String label;
  final bool selected;
  final bool enabled;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final accent = statusAccent(context, status);
    final lip = GumdropShape.lipFor(height - 4);
    final Color face;
    final Color lipColor;
    final Color text;
    final Color highlight;
    var side = BorderSide.none;
    if (selected) {
      face = accent.face;
      lipColor = accent.lip;
      text = c.ink;
      highlight = GumdropColors.accentHighlight;
    } else if (!enabled) {
      face = c.well;
      lipColor = Colors.transparent;
      text = c.textMuted;
      highlight = Colors.transparent;
    } else {
      face = c.raisedFace;
      lipColor = c.raisedLip;
      text = c.textPrimary;
      highlight = c.raisedHighlight;
      if (c.raisedBorderWidth > 0) {
        side = BorderSide(color: c.raisedBorder, width: c.raisedBorderWidth);
      }
    }
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: face,
          shape: GumdropStyle.of(context).styled(
            GumdropShape(
              lip: lip,
              lipColor: lipColor,
              highlight: selected ? 2 : 1.5,
              highlightColor: highlight,
              side: side,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 0, 6, lip),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!compact) ...[
                    AnswerDisc(
                      status: status,
                      size: 24,
                      face: selected ? GumdropColors.inkTint14 : null,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    style: GumdropStyle.of(context).label(
                      TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 15 : 17,
                        height: 1,
                        color: text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round 38 px gumdrop icon button for the event's header (design §3.1).
ButtonStyle headerIconStyle(BuildContext context) =>
    GumdropButtons.of(context).icon();

/// The round lemon back button (design §3.2): a 48 px circle with an ink
/// outline and a hard offset shadow. Still a [BackButton].
class LemonBackButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    // Where the theme's gumdrops lean (Gumdrop Arena), the theme's own back
    // button, a leaning lemon gumdrop.
    if (GumdropStyle.of(context).slant != 0) {
      return const Padding(
        padding: EdgeInsetsDirectional.only(start: 14),
        child: BackButton(),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: c.headingShadow, offset: const Offset(4, 4)),
          ],
        ),
        child: BackButton(
          color: c.ink,
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(c.lemon.face),
            foregroundColor: WidgetStatePropertyAll(c.ink),
            iconColor: WidgetStatePropertyAll(c.ink),
            fixedSize: const WidgetStatePropertyAll(Size(48, 48)),
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            iconSize: const WidgetStatePropertyAll(24),
            side: WidgetStateProperty.resolveWith(
              (s) => BorderSide(
                color: s.contains(WidgetState.focused) ? c.textOnPage : c.ink,
                width: s.contains(WidgetState.focused) ? 3.5 : 2.5,
              ),
            ),
            shape: const WidgetStatePropertyAll(CircleBorder()),
          ),
        ),
      ),
    );
  }
}
