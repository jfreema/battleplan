import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/widgets/camo.dart';
import 'package:battleplan/core/widgets/camp_lettering.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The schedule's Gumdrop Pop pieces (design §3.15, §3.16): cards, the date
/// block, the going bar, answer discs, stat tiles, and the RSVP gumdrops.

/// A tappable Boot Camp Mix panel (#85, SPEC §7.3): the panel color, a 3 px
/// ink outline on a hard 4/4 shadow, square, and its [child] in the card's
/// colors ([GumdropSurface]). [edge], when given, is a 5 px stripe down its
/// left side (the event type's color). A [footer] sits under it on the
/// card, outside what a tap opens: buttons of its own, like the answers.
/// The keyboard focus rings the whole card (SPEC §7.6).
class TapCard extends StatefulWidget {
  const new({
    required this.child,
    this.onTap,
    this.footer,
    this.edge,
    this.radius = 0,
    this.padding = const EdgeInsets.fromLTRB(15, 8, 12, 4),
    this.footerBand,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Widget? footer;
  final Color? edge;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// The footer as its own band (#85): this color under a 3 px ink rule,
  /// across the whole card, as the schedule's answer row is.
  final Color? footerBand;

  @override
  State<TapCard> createState() => _TapCardState();
}

class _TapCardState extends State<TapCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final rim = BorderSide(color: c.surfaceBorder, width: c.surfaceBorderWidth);
    final resolved = widget.padding.resolve(Directionality.of(context));
    final edge = widget.edge;
    final radius = BorderRadius.circular(widget.radius);
    Widget ink(EdgeInsets padding) => InkWell(
      onTap: widget.onTap,
      // The ring around the card shows the focus instead.
      focusColor: Colors.transparent,
      onFocusChange: (f) => setState(() => _focused = f),
      child: Padding(padding: padding, child: widget.child),
    );
    final band = widget.footerBand;
    final body = switch (widget.footer) {
      null => ink(resolved),
      final footer when band != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ink(resolved),
          DecoratedBox(
            decoration: BoxDecoration(
              color: band,
              border: Border(top: BorderSide(color: c.ink, width: 3)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 9, 4),
              child: footer,
            ),
          ),
        ],
      ),
      final footer => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ink(resolved.copyWith(bottom: 2)),
          Padding(padding: resolved.copyWith(top: 0), child: footer),
        ],
      ),
    };
    return GumdropSurface(
      child: DecoratedBox(
        // The hard shadow, down and to the right.
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(color: c.pageShadow, offset: const Offset(4, 4)),
          ],
        ),
        // Outside the card, whose rim would cover a ring drawn on it.
        child: FocusRing(
          focused: _focused,
          radius: radius,
          child: Material(
            color: c.surface,
            shape: RoundedRectangleBorder(side: rim, borderRadius: radius),
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
                        child: ColoredBox(color: edge),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A schedule panel's date pennant (Boot Camp Mix, #85, SPEC §7.4): the
/// event's color under a halftone, down the panel's left side and ending
/// in a point edged in ink, with the weekday in small ink stencil over the
/// day in big outlined stencil. It reads as the day.
class DatePennant extends StatelessWidget {
  const new({
    required this.day,
    required this.color,
    this.semanticLabel,
    super.key,
  });

  final DateTime day;

  /// The event's color.
  final Color color;
  final String? semanticLabel;

  /// The pennant's width, to its point.
  static const double width = 75;

  /// Where the panel's text starts, clear of the point.
  static const double textStart = 82;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: semanticLabel ?? dayLabel(l10n, day),
      excludeSemantics: true,
      child: CustomPaint(
        painter: _PennantPainter(color: color, ink: c.ink),
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 13, 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat.E(l10n.localeName).format(day),
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontFamily: AppFonts.stencil,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    height: 14 / 12.5,
                    letterSpacing: 12.5 * 0.09,
                    color: c.inkOn(
                      GumdropAccent(face: color, lip: c.ink, text: color),
                    ),
                  ),
                ),
                OutlinedText(
                  '${day.day}',
                  // The pennant doesn't grow with the text size.
                  textScaler: TextScaler.noScaling,
                  shadow: 2.5,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: AppFonts.stencil,
                    fontWeight: FontWeight.w900,
                    fontSize: 38,
                    height: 39 / 38,
                    letterSpacing: 38 * 0.02,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The pennant: an ink shape with the color 4 px inside its point, and the
/// halftone over the color.
class _PennantPainter extends CustomPainter {
  new({required this.color, required this.ink});

  final Color color;
  final Color ink;

  Path _shape(Size size, double right) {
    const point = 15.0;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(right - point, 0)
      ..lineTo(right, size.height / 2)
      ..lineTo(right - point, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_shape(size, size.width), Paint()..color = ink);
    final face = _shape(size, size.width - 4);
    canvas
      ..drawPath(face, Paint()..color = color)
      ..save()
      ..clipPath(face);
    DotGridPainter(
      color: const Color(0x2B1B1D13),
      radius: 1.5,
    ).paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PennantPainter old) =>
      old.color != color || old.ink != ink;
}

/// My answer stamped on a schedule panel (#85): "GOING!" with a check on
/// green, "MAYBE" on orange, or "CAN'T GO" on salmon, in ink stencil in a
/// 2.5 px ink outline on a 2/2 shadow, turned -5°.
class AnswerStamp extends StatelessWidget {
  const new({required this.status, super.key});

  final RsvpStatus status;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final l10n = AppLocalizations.of(context);
    final accent = statusAccent(context, status);
    final label = switch (status) {
      RsvpStatus.going => '${statusLabel(l10n, status)}!',
      _ => statusLabel(l10n, status),
    };
    return Transform.rotate(
      angle: -5 * 3.141592653589793 / 180,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 8, 3),
        decoration: BoxDecoration(
          color: accent.face,
          border: Border.all(color: c.ink, width: 2.5),
          boxShadow: [
            BoxShadow(color: c.pageShadow, offset: const Offset(2, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == RsvpStatus.going) ...[
              Icon(
                AppIcons.going,
                size: 15,
                weight: 700,
                color: c.inkOn(accent),
              ),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: AppFonts.stencil,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                height: 1,
                letterSpacing: 15 * 0.05,
                color: c.inkOn(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A month's label in the schedule (#85): its name in mustard stencil on
/// an ink block, a mustard star before it, turned -1.2°.
class MonthLabel extends StatelessWidget {
  const new({required this.month, super.key});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final l10n = AppLocalizations.of(context);
    final mustard = c.roles.palette.mustard;
    return Semantics(
      header: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Transform.rotate(
          angle: -1.2 * 3.141592653589793 / 180,
          child: Container(
            color: c.ink,
            padding: const EdgeInsets.fromLTRB(9, 2, 10, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  painter: _StarPainter(mustard),
                  size: const Size(12, 12),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    DateFormat.MMMM(l10n.localeName).format(month),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.stencil,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 22 / 16,
                      letterSpacing: 16 * 0.08,
                      color: mustard,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A five-pointed star in [color].
class _StarPainter extends CustomPainter {
  new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // The design's star, as fractions of its box.
    const points = [
      (0.50, 0.0),
      (0.61, 0.35),
      (0.98, 0.35),
      (0.68, 0.57),
      (0.79, 0.91),
      (0.50, 0.70),
      (0.21, 0.91),
      (0.32, 0.57),
      (0.02, 0.35),
      (0.39, 0.35),
    ];
    final path = Path();
    for (final (i, (x, y)) in points.indexed) {
      final p = Offset(x * size.width, y * size.height);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

/// The RSVP choice: Going, Maybe, and Can't go in equal parts, built on
/// [SegmentedButton] so it keeps its selection semantics and keyboard
/// behavior: push buttons (#85), 50 tall on the event's page, and on the
/// schedule and chat cards ([compact], SPEC §7.3) 36 tall in a 48 px tap
/// height, the picked one in its answer's color pressed onto its shadow.
///
/// Locked ([onChanged] null: past the deadline, once the event starts, an
/// archived team, a super admin viewing), it's one flat tag with the answer
/// in the row's place instead, so nothing that can't be pressed looks
/// pressable (#53).
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

  /// A tap on the chosen answer clears it (RsvpButtons gives this
  /// wherever an answer can be changed, #44); without it the answer stays.
  final VoidCallback? onCleared;

  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final height = compact ? 48.0 : 53.0;
    final gap = compact ? 9.0 : _gap;
    final enabled = onChanged != null;
    if (!enabled) {
      return _LockedAnswer(status: current, height: height, compact: compact);
    }
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
                child: _RsvpPush(
                  status: s,
                  label: statusLabel(l10n, s),
                  selected: s == current,
                  enabled: enabled,
                  page: !compact,
                  height: height,
                ),
              ),
            ),
        ],
        selected: {?current},
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          // The gumdrops and pills draw every state, the keyboard focus as
          // a ring around themselves (ButtonFocusRing).
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
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

/// A locked answer (SCHED-5, #53): one flat pill at the start of the row,
/// in the row's height ([height]), so nothing moves when the deadline
/// passes. An answer is its icon and word on its candy (mint, lemon, or the
/// warning red for Not going) in ink or white, with no lip, raise, or
/// outline; no answer is "No reply" in muted text, outlined like an
/// InfoTag. Screen readers hear "Going. RSVPs are closed."
class _LockedAnswer extends StatelessWidget {
  const new({
    required this.status,
    required this.height,
    required this.compact,
  });

  final RsvpStatus? status;
  final double height;

  /// On a card (the schedule's): its card colors and smaller type.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final answer = status;
    final label = answer == null ? l10n.rsvpNoReply : statusLabel(l10n, answer);
    final Widget tag;
    if (answer == null) {
      final muted = c.onCard ? c.textMuted : c.textMutedOnPage;
      tag = Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: ShapeDecoration(
          shape: StadiumBorder(side: BorderSide(color: c.outline, width: 1.5)),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            maxLines: 1,
            style: GumdropStyle.of(context).label(
              TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: compact ? 14 : 15,
                height: 1.2,
                color: muted,
              ),
            ),
          ),
        ),
      );
    } else {
      final accent = statusAccent(context, answer);
      // Ink on its candy; white on the warning red.
      final ink = c.inkOn(accent);
      final (glyph, size) = switch (answer) {
        RsvpStatus.going => (AppIcons.going, compact ? 16.0 : 18.0),
        RsvpStatus.maybe => (AppIcons.maybe, compact ? 18.0 : 20.0),
        RsvpStatus.notGoing => (AppIcons.notGoing, compact ? 14.0 : 16.0),
      };
      tag = Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: accent.face,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(glyph, size: size, weight: 700, color: ink),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GumdropStyle.of(context).label(
                  TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 14 : 16,
                    height: 1.2,
                    color: ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Semantics(
      container: true,
      label: '$label. ${l10n.eventRsvpClosed}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Align(alignment: AlignmentDirectional.centerStart, child: tag),
      ),
    );
  }
}

/// One RSVP push button (Boot Camp Mix, #85, SPEC §7.3): the panel color
/// in an ink outline on a hard shadow down and to the right; picked, its
/// answer's color (green, orange, or Can't go's salmon) with the answer's
/// icon, pressed onto its shadow. The label is stencil capitals, ink on a
/// picked one. On the event's page ([page]) 50 tall, corner 13, a 3 px
/// outline on a 3 px shadow; on the cards 36 tall, corner 10, 2.5 on 2.5,
/// in a 48 px tap height.
class _RsvpPush extends StatelessWidget {
  const new({
    required this.status,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.page,
    required this.height,
  });

  final RsvpStatus status;
  final String label;
  final bool selected;
  final bool enabled;

  /// The event page's bigger buttons.
  final bool page;

  /// The tap height it's centered in.
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final accent = statusAccent(context, status);
    final face = page ? 50.0 : 36.0;
    final border = page ? 3.0 : 2.5;
    final shadow = page ? 3.0 : 2.5;
    final radius = BorderRadius.circular(page ? 13 : 10);
    // On the panel color, so in the panel's lettering, on a card or on the
    // event's page (Candy Pop's navy on white, #86).
    final panel = c.card;
    final text = selected
        ? c.inkOn(accent)
        : enabled
        ? panel.textPrimary
        : panel.textMuted;
    final glyph = switch (status) {
      RsvpStatus.going => AppIcons.going,
      RsvpStatus.maybe => AppIcons.maybe,
      RsvpStatus.notGoing => AppIcons.notGoing,
    };
    final button = ButtonFocusRing(
      radius: radius,
      child: Container(
        height: face,
        decoration: BoxDecoration(
          color: selected ? accent.face : c.surface,
          borderRadius: radius,
          border: Border.all(color: c.ink, width: border),
          boxShadow: selected
              ? null
              : [
                  BoxShadow(
                    color: c.pageShadow,
                    offset: Offset(shadow, shadow),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(glyph, size: page ? 20 : 16, weight: 700, color: text),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  maxLines: 1,
                  style: GumdropStyle.of(context).label(
                    TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: page ? 20 : 15,
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
    );
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Padding(
        // Room for the shadow at the right and bottom of every button.
        padding: EdgeInsets.only(right: shadow, bottom: page ? shadow : 0),
        child: Align(
          child: Transform.translate(
            // Picked, pressed onto its shadow.
            offset: selected ? Offset(shadow, shadow) : Offset.zero,
            child: button,
          ),
        ),
      ),
    );
  }
}
