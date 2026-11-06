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

/// A tappable Open Field card (SPEC §7.3): the card color, a 2 px rim on a
/// 4 px lip, corner 18, and its [child] in the card's colors
/// ([GumdropSurface]). [edge], when given, is a 5 px stripe down its left
/// side (the event type's candy). A [footer] sits under it on the card,
/// outside what a tap opens: buttons of its own, like the answers.
class TapCard extends StatelessWidget {
  const new({
    required this.child,
    this.onTap,
    this.footer,
    this.edge,
    this.radius = 18,
    this.padding = const EdgeInsets.fromLTRB(15, 8, 12, 4),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Widget? footer;
  final Color? edge;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final rim = BorderSide(color: c.surfaceBorder, width: c.surfaceBorderWidth);
    final resolved = padding.resolve(Directionality.of(context));
    final body = switch (footer) {
      null => InkWell(
        onTap: onTap,
        child: Padding(padding: resolved, child: child),
      ),
      final footer => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(padding: resolved.copyWith(bottom: 2), child: child),
          ),
          Padding(padding: resolved.copyWith(top: 0), child: footer),
        ],
      ),
    };
    return GumdropSurface(
      child: DecoratedBox(
        // The 4 px lip under the card, in the rim's color.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [BoxShadow(color: rim.color, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            side: rim,
            borderRadius: BorderRadius.circular(radius),
          ),
          clipBehavior: Clip.antiAlias,
          child: edge == null
              ? body
              : Stack(
                  children: [
                    body,
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      bottom: 0,
                      width: 5,
                      child: ColoredBox(color: edge!),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The date column on a schedule card (SPEC §7.3): the weekday over the day
/// over the month, 38 wide. It reads as the day.
class DateColumn extends StatelessWidget {
  const new({required this.day, required this.semanticLabel, super.key});

  final DateTime day;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final style = GumdropStyle.of(context);
    final small = style.label(
      TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        height: 14 / 13,
        letterSpacing: 13 * 0.08,
        color: c.textMuted,
      ),
    );
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: ConstrainedBox(
        // 38 wide, growing with the text so each line stays one line.
        constraints: const BoxConstraints(minWidth: 38),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.E(l10n.localeName).format(day).toUpperCase(),
              maxLines: 1,
              softWrap: false,
              style: small,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                '${day.day}',
                maxLines: 1,
                softWrap: false,
                style: style.display(
                  TextStyle(
                    fontSize: 34,
                    height: 32 / 34,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            Text(
              DateFormat.MMM(l10n.localeName).format(day).toUpperCase(),
              maxLines: 1,
              softWrap: false,
              style: small,
            ),
          ],
        ),
      ),
    );
  }
}

/// The going bar: a track with [fraction] of it mint, [width] wide (null
/// to fill) and [height] tall. Decoration only; the words beside it say
/// the same.
class GoingBar extends StatelessWidget {
  const new({required this.fraction, this.width, this.height = 8, super.key});

  final double fraction;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c.cardTrack,
          borderRadius: BorderRadius.circular(height / 2 + 0.5),
        ),
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0, 1),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.mint.face,
              borderRadius: BorderRadius.circular(height / 2 + 0.5),
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

/// The RSVP choice: Going, Maybe, and Not going in equal parts, built on
/// [SegmentedButton] so it keeps its selection semantics and keyboard
/// behavior. On the event's page, three 54 px gumdrops with their discs;
/// [compact] (the schedule and chat cards, SPEC §7.3) three 36 px pills in
/// a 48 px tap height: the picked one its candy (mint, lemon, cherry) on
/// its lip, the others quiet, or all outlined while there's no answer.
class RsvpChoice extends StatelessWidget {
  const new({
    required this.statuses,
    required this.current,
    required this.onChanged,
    this.compact = false,
    this.onCleared,
    super.key,
  });

  final List<RsvpStatus> statuses;
  final RsvpStatus? current;

  /// Null when it can't be changed (past the deadline, say).
  final ValueChanged<RsvpStatus>? onChanged;
  final bool compact;

  /// A tap on the chosen answer: clears it, where given (the schedule
  /// list); otherwise the answer stays.
  final VoidCallback? onCleared;

  static const double _gap = 9;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final height = compact ? 48.0 : 58.0;
    final gap = compact ? 4.0 : _gap;
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
                  start: gap * i / n,
                  end: gap * (n - 1 - i) / n,
                ),
                child: compact
                    ? _RsvpPill(
                        status: s,
                        label: statusLabel(l10n, s),
                        selected: s == current,
                        unanswered: current == null,
                        enabled: enabled,
                      )
                    : _RsvpGumdrop(
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
                // Tapping the chosen answer again keeps it, or clears it.
                if (s.isEmpty) {
                  onCleared?.call();
                  return;
                }
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
          shape: GumdropShape(
            lip: lip,
            lipColor: lipColor,
            highlight: selected ? 2 : 1.5,
            highlightColor: highlight,
            side: side,
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
                      face: selected
                          ? GumdropColors.of(context).ink
                                .withValues(alpha: 0.14)
                          : null,
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

/// One card RSVP pill (SPEC §7.3): 36 px, corner 18, inside the 48 px
/// segment. Picked, its candy with a 2 px outline and a 3 px lip in its lip
/// color, raised onto the lip, with an ink label at 700; on a row with an
/// answer, the others are quiet card-muted words; on a row with none, all
/// three are outlined, with their icons in the answer colors.
class _RsvpPill extends StatelessWidget {
  const new({
    required this.status,
    required this.label,
    required this.selected,
    required this.unanswered,
    required this.enabled,
  });

  final RsvpStatus status;
  final String label;
  final bool selected;
  final bool unanswered;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final accent = statusAccent(context, status);
    final Color text;
    final Color icon;
    if (selected) {
      text = c.ink;
      icon = c.ink;
    } else if (unanswered && enabled) {
      text = c.textPrimary;
      icon = switch (status) {
        RsvpStatus.going => c.mint.text,
        RsvpStatus.maybe => c.lemon.text,
        RsvpStatus.notGoing => c.cherry.text,
      };
    } else {
      text = c.textMuted;
      icon = c.textMuted;
    }
    final (glyph, size) = switch (status) {
      RsvpStatus.going => (AppIcons.going, 16.0),
      RsvpStatus.maybe => (AppIcons.maybe, 18.0),
      RsvpStatus.notGoing => (AppIcons.notGoing, 14.0),
    };
    final pill = Container(
      height: 36,
      decoration: BoxDecoration(
        color: selected ? accent.face : null,
        borderRadius: BorderRadius.circular(18),
        border: selected
            ? Border.all(color: accent.lip, width: 2)
            : unanswered && enabled
            ? Border.all(color: c.cardOutline, width: 1.5)
            : null,
        boxShadow: selected
            ? [BoxShadow(color: accent.lip, offset: const Offset(0, 3))]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(glyph, size: size, weight: 700, color: icon),
              SizedBox(width: status == RsvpStatus.maybe ? 2 : 4),
              Text(
                label,
                maxLines: 1,
                style: GumdropStyle.of(context).label(
                  TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                    height: 1,
                    color: text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Align(
        child: Transform.translate(
          offset: Offset(0, selected ? -1.5 : 0),
          child: pill,
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
            backgroundColor: WidgetStatePropertyAll(c.sticker.face),
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
