import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/team_color_names.dart';
import 'package:battleplan/core/widgets/back_chevron.dart';
import 'package:battleplan/core/widgets/camo.dart';
import 'package:battleplan/core/widgets/camp_app_bar.dart';
import 'package:battleplan/core/widgets/camp_lettering.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

export 'package:battleplan/core/team_color_names.dart' show teamColorName;

/// The pieces of the Open Field settings screens (SPEC §7.3): the
/// pushed-screen bar with its back row and big title, rows on the page
/// between hairlines, true cards, card and page headings, section labels,
/// caps field labels, and the team color grid. Shared by Settings, Team
/// admin, Create team, Invite, Roster, Dues, Documents, and Plays.

/// A page opened on top (SPEC §7.3): the app's one frame for them (#14,
/// owner's go 2026-11-16, after pages that looked like two different apps).
///
/// A 48 px back row, pinned: the chevron and [backLabel] (the screen it
/// goes back to), and [actions] on its right as 48 px icon buttons. Then
/// the [title] in stencil 32 outlined, 20 px from the left,
/// which scrolls away with the page's own list, giving back its room
/// (owner's request 2026-11-05: headers that take less room). Once it's
/// out of sight the page's name fades into the back row's middle, small,
/// where it fits beside the back label; never crowding it. With nothing
/// under the page (a link, a web reload, a notification on a cold start),
/// the chevron alone goes [upFrom] it, and Android's Back with it.
///
/// [body] needs no changes: its list scrolls with the title through the
/// primary scroll controller, as a ListView takes it by itself. A body
/// with a controller of its own keeps its title in place.
class GumdropScaffold extends StatefulWidget {
  const new({
    required this.title,
    required this.body,
    this.backLabel,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.maxWidth,
    super.key,
  });

  final String title;
  final Widget body;
  final String? backLabel;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  /// The width of the [body]'s centered column, its margins included, for
  /// a body that keeps to one (560 for most, as [PageList]): the big
  /// title sits in a column as wide, centered, so on a wide screen or in a
  /// side panel it lines up with the page instead of standing at the
  /// edge (#14, 2026-11-16). The back row keeps to the same column, the
  /// chevron at its left and the actions at its right, rather than the
  /// window's far edges (#29, 2026-11-20). Null for a body as wide as the
  /// screen.
  final double? maxWidth;

  @override
  State<GumdropScaffold> createState() => _GumdropScaffoldState();
}

class _GumdropScaffoldState extends State<GumdropScaffold> {
  final _outer = ScrollController();
  final GlobalKey _title = GlobalKey();

  /// The title has scrolled out of sight: the small one shows.
  bool _away = false;

  /// The big title's height, padding included: as laid out, one line or
  /// two, else one line at this text size.
  double _titleExtent(BuildContext context) =>
      _title.currentContext?.size?.height ??
      6 + MediaQuery.textScalerOf(context).scale(36) + 4;

  @override
  void initState() {
    super.initState();
    _outer.addListener(() {
      final away =
          _outer.hasClients && _outer.offset >= _titleExtent(context) - 1;
      if (away != _away) setState(() => _away = away);
    });
  }

  @override
  void dispose() {
    _outer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final backLabel = canPop ? widget.backLabel : null;
    final back = canPop
        ? BackChevron(label: backLabel)
        : switch (_goUp(context)) {
            final up? => _UpChevron(up: up),
            null => null,
          };
    final actions = widget.actions ?? const <Widget>[];
    return Scaffold(
      // The camouflage across the window, the back row in the page's
      // centered column on a wide screen (#29).
      appBar: CampAppBar(
        columnWidth: widget.maxWidth,
        toolbarHeight: 48,
        automaticallyImplyLeading: false,
        // The back row isn't the heading; the title is, and names the
        // route.
        excludeHeaderSemantics: true,
        titleSpacing: 4,
        title: back == null
            ? null
            : Align(alignment: AlignmentDirectional.centerStart, child: back),
        actions: actions,
        actionsPadding: const EdgeInsets.only(right: 4),
        // A hairline under the row once the page scrolls under it, so its
        // edge shows; none at the top, where the title sits below it. As
        // wide as the column, as the team header's is.
        shape: _away
            ? Border(
                bottom: BorderSide(color: GumdropColors.of(context).divider),
              )
            : null,
        flexibleSpace: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 48,
            child: _SmallTitle(
              title: widget.title,
              shown: _away,
              // Where the back button and the actions are, so the small
              // title, centered, never runs into either.
              left: back == null
                  ? 4
                  : 4 + BackChevron.widthOf(context, backLabel),
              right: 4 + 48.0 * actions.length,
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
      // The button at the column's corner, not the window's (#29).
      floatingActionButtonLocation: switch (widget.maxWidth) {
        final max? => _ColumnEndFloat(max),
        null => null,
      },
      body: NestedScrollView(
        controller: _outer,
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: switch (widget.maxWidth) {
              final max? => Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: max),
                  // The column's whole width, the title at its left edge.
                  child: SizedBox(
                    width: double.infinity,
                    child: PageTitle(widget.title, key: _title),
                  ),
                ),
              ),
              null => PageTitle(widget.title, key: _title),
            },
          ),
        ],
        // The page's list scrolls with the title on every platform, the
        // web and desktop included, which don't take a primary scroll
        // controller by themselves.
        body: Builder(
          builder: (context) => PrimaryScrollController(
            controller: PrimaryScrollController.of(context),
            automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
            child: widget.body,
          ),
        ),
      ),
    );
  }
}

/// The even margin either side of a centered column of [column] in
/// [width]: none on a phone, or with no column.
double _margin(double width, double? column) =>
    column == null ? 0 : math.max<double>(0, (width - column) / 2);

/// [GumdropScaffold]'s floating button at the bottom corner of the page's
/// centered column of [maxWidth] rather than the window's (#29,
/// 2026-11-20): Messages' New message stood far from its rows on a
/// computer. Where Material puts it on a phone.
class _ColumnEndFloat extends FloatingActionButtonLocation {
  const new(this.maxWidth);

  final double maxWidth;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final end = FloatingActionButtonLocation.endFloat.getOffset(
      scaffoldGeometry,
    );
    final margin = _margin(scaffoldGeometry.scaffoldSize.width, maxWidth);
    // The end is the right in left-to-right text, the left otherwise.
    return switch (scaffoldGeometry.textDirection) {
      TextDirection.ltr => end.translate(-margin, 0),
      TextDirection.rtl => end.translate(margin, 0),
    };
  }
}

/// The body of a page opened on top, as Settings has it (SPEC §7.3): a
/// list whose rows sit 20 px from the edge, level with the title, at most
/// [maxWidth] wide on a wide screen. Rows go in [SettingsCard]s under
/// [PageHeading]s.
class PageList extends StatelessWidget {
  const new({required this.children, this.maxWidth = 560, super.key});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.page,
          14,
          Space.page,
          Space.xl,
        ),
        children: children,
      ),
    ),
  );
}

/// A page's big title (SPEC §7.3; Boot Camp Mix, #85): white stencil
/// capitals in a thick ink outline on a hard shadow (`OutlinedText`), 50
/// stepping down to fit, turned -2°, 20 px from the left, on up to two lines
/// ("NOTIFICATIONS FOR THIS TEAM"), as it scrolls away rather than holding
/// the top. The route's heading for screen readers.
class PageTitle extends StatelessWidget {
  const new(this.title, {super.key});

  final String title;

  /// The sizes tried, largest first: each must hold every word whole and
  /// the title in two lines; with large text a long word steps it down.
  static const List<double> sizes = [50, 42, 36, 30, 25];

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.headlineMedium!;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // No word broken across the lines.
          bool wordsFit(TextStyle style) {
            for (final word in title.split(RegExp(r'\s+'))) {
              final painter = TextPainter(
                text: TextSpan(text: word, style: style),
                maxLines: 1,
                textDirection: direction,
                textScaler: scaler,
              )..layout();
              final ok = painter.width <= constraints.maxWidth;
              painter.dispose();
              if (!ok) return false;
            }
            return true;
          }

          bool fits(TextStyle style) {
            final whole = TextPainter(
              text: TextSpan(text: title, style: style),
              maxLines: 2,
              textDirection: direction,
              textScaler: scaler,
            )..layout(maxWidth: constraints.maxWidth);
            final ok = !whole.didExceedMaxLines;
            whole.dispose();
            return ok && wordsFit(style);
          }

          TextStyle styleAt(double size) => base.copyWith(
            fontSize: size,
            height: 54 / 50,
            letterSpacing: size * 0.025,
          );
          final size = sizes.firstWhere(
            (size) => fits(styleAt(size)),
            orElse: () => -1,
          );
          // Too long even at the smallest: two lines that end in "…" while
          // every word still fits a line ("Riverside Thunder 10U Blue is
          // ready!" with large text, #16), else one, rather than a word
          // split in two.
          final lines = size >= 0 || wordsFit(styleAt(sizes.last)) ? 2 : 1;
          final at = size < 0 ? sizes.last : size;
          return Transform.rotate(
            angle: -2 * math.pi / 180,
            alignment: const Alignment(-1, 0.4),
            child: OutlinedText(
              title,
              header: true,
              namesRoute: true,
              maxLines: lines,
              overflow: TextOverflow.ellipsis,
              // The outline and shadow grow with the size.
              stroke: at * 0.11,
              shadow: at >= 36 ? 4 : 3,
              style: styleAt(at),
            ),
          );
        },
      ),
    );
  }
}

/// The page's name in the back row once its big title has scrolled away:
/// stencil 19, centered on the row, and only where it fits between what's
/// [left] and [right] of the middle. The back label matters more.
class _SmallTitle extends StatelessWidget {
  const new({
    required this.title,
    required this.shown,
    required this.left,
    required this.right,
  });

  final String title;
  final bool shown;
  final double left;
  final double right;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium
        ?.copyWith(fontSize: 19, height: 1.2, shadows: const []);
    // It grows with the text size only so far, to stay in the 48 px row;
    // the big title above the page carries the large size.
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Room centered on the row, clear of both sides by 8.
        final room = constraints.maxWidth - 2 * (math.max(left, right) + 8);
        final painter = TextPainter(
          text: TextSpan(text: title, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout();
        final fits = painter.width <= room;
        painter.dispose();
        return AnimatedSwitcher(
          duration: Motion.of(context, Motion.fast),
          child: shown && fits
              // The big title is the heading; this is only its echo.
              ? ExcludeSemantics(
                  key: const ValueKey('title'),
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      textScaler: scaler,
                      style: style,
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('none')),
        );
      },
    );
  }
}

/// Where a screen goes back to when nothing is under it (SPEC §7.3), as
/// when it was opened from a link, a web reload, or a notification on a
/// cold start: a team's screens to its chat, Settings and Profile's pages
/// to Profile, a direct conversation to Messages, and the rest to Teams.
String upFrom(Uri location) => switch (location.pathSegments) {
  ['g', final id, ...] when id != 'new' => '/g/$id/chat',
  ['settings' || 'profile', ...] => '/profile',
  ['messages', _, ...] => '/messages',
  _ => '/teams',
};

/// Goes [upFrom] where the app is: the screen at [context], which has
/// nothing under it. Null when it isn't a GoRouter page (a test pumping it
/// alone), or is a team tab's own page (Plays for a member), whose header
/// already has the back to Teams.
VoidCallback? _goUp(BuildContext context) {
  if (ModalRoute.of(context)?.settings is! Page<Object?>) return null;
  if (Navigator.maybeOf(context) !=
      Navigator.maybeOf(context, rootNavigator: true)) {
    return null;
  }
  final router = GoRouter.maybeOf(context);
  if (router == null) return null;
  // Read on the tap, when this screen is the one showing.
  return () => router.go(upFrom(router.state.uri));
}

/// A plain [AppBar]'s `leading`: when nothing is under the screen, the
/// chevron that goes [upFrom] it; otherwise null, for the app bar's own
/// back button.
Widget? upButton(BuildContext context) {
  if (ModalRoute.of(context)?.impliesAppBarDismissal ?? true) return null;
  final up = _goUp(context);
  if (up == null) return null;
  return Center(child: _UpChevron(up: up));
}

/// The chevron that goes [up] from a screen with nothing under it, and
/// Android's Back with it while the screen is the one showing: without
/// this, Back closed the app (#14, 2026-11-16). A dialog or a page over
/// the screen keeps Back for itself.
class _UpChevron extends StatelessWidget {
  const new({required this.up});

  final VoidCallback up;

  @override
  Widget build(BuildContext context) => BackButtonListener(
    onBackButtonPressed: () {
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
        return SynchronousFuture(false);
      }
      up();
      return SynchronousFuture(true);
    },
    child: BackChevron(onPressed: up),
  );
}

/// What a pushed screen's back label says, passed as GoRouter `extra` by
/// an opener other than the usual one ([label] null: the chevron alone).
@immutable
class BackLabel {
  const new(this.label);

  final String? label;
}

/// The back label of a screen with several ways in (SPEC §7.3), like a
/// player card or a person's page: its opener's [BackLabel], or null for
/// the chevron alone when the opener is unknown (a link, a notification).
String? openerLabel(BuildContext context) =>
    switch (backLabelFrom(context, '')) {
      final from? when from.isNotEmpty => from,
      _ => null,
    };

/// The back label for the screen at [context]: its opener's [BackLabel],
/// else [usual] (the screen it's normally opened from).
String? backLabelFrom(BuildContext context, String usual) {
  // A screen outside a GoRouter page (a test pumping it alone) has none.
  if (ModalRoute.of(context)?.settings is! Page<Object?>) return usual;
  final extra = GoRouterState.of(context).extra;
  return extra is BackLabel ? extra.label : usual;
}

/// The top bar of Teams and Profile (SPEC §7.3): 52 px, the [title] in
/// stencil 27 outlined, 20 px from the left, and [actions]
/// (48 px icon buttons) on the right.
class TopLevelBar extends StatelessWidget {
  const new({
    required this.title,
    this.actions = const [],
    this.maxWidth,
    super.key,
  });

  final String title;
  final List<Widget> actions;

  /// The width of the page's centered column under the bar, for a page
  /// that keeps to one (Teams and Profile, 560): the title and icons keep
  /// to it on a wide screen, at its left and right, instead of the
  /// window's far edges (#29, 2026-11-20). Null for the whole width.
  final double? maxWidth;

  // Boot Camp Mix (#85): on the camouflage, up under the status bar, the
  // name outlined in white.
  @override
  Widget build(BuildContext context) => CampHeader(
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 56,
          maxWidth: maxWidth ?? double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 18, right: 8),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  // Level with the icons' center.
                  padding: const EdgeInsets.only(top: 3),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedText(
                      title,
                      header: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium!
                          .copyWith(
                            fontSize: 32.5,
                            height: 37 / 32.5,
                            letterSpacing: 32.5 * 0.04,
                          ),
                    ),
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    ),
  );
}

/// A list of rows in one ink panel (Boot Camp Mix, #85, SPEC §7.3): the
/// panel color in a 3 px ink outline on a hard 4/4 shadow, the rows split
/// by 3 px ink lines, each set in 8 from the left and 9 from the right.
class PageRows extends StatelessWidget {
  const new({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final c = GumdropColors.of(context);
    final line = Container(height: 3, color: c.ink);
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: c.pageShadow, offset: const Offset(4, 4))],
      ),
      child: Material(
        color: c.surface,
        shape: Border.all(color: c.ink, width: 3),
        clipBehavior: Clip.antiAlias,
        child: GumdropSurface(
          // Inside the 3 px outline, which the shape draws over its edge.
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) line,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 9, 0),
                    child: child,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Row [index] of a list of rows on the page built as it scrolls, like
/// notifications and Messages (SPEC §7.3): [child] with a 1 px hairline
/// under it, and one above it too when it's the first, as [PageRows] draws
/// them.
class PageListRow extends StatelessWidget {
  const new({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final line = BorderSide(color: GumdropColors.of(context).divider);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: index == 0 ? line : BorderSide.none, bottom: line),
      ),
      child: child,
    );
  }
}

/// A row in a panel of rows (SPEC §7.3; Boot Camp Mix, #85): at least 52
/// tall, its [icon] in ink on a 36 px mustard round badge in an ink outline
/// (or [leading]), the title in Comic Neue Bold 16.5/21, the subtitle 14/17
/// muted, and a 20 px chevron when it opens something. [destructive] puts
/// the badge in the red and the title in the accent text.
/// Screen readers hear the row as one item, or as [semanticsLabel] when
/// it's given (a sentence: "Luke #7, Uniforms, $25 left of $45"); with
/// [trailingActions], the buttons in [trailing] stay items of their own.
/// At large text sizes a [trailing] widget other than an icon goes under
/// the text, which keeps the row's width.
class PageRow extends StatelessWidget {
  const new({
    required this.title,
    this.icon,
    this.leading,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.trailingActions = false,
    this.chevron = true,
    this.destructive = false,
    this.subtitleMaxLines = 1,
    this.subtitleSpan,
    this.bold = false,
    this.titleColor,
    this.semanticsLabel,
    super.key,
  });

  final String title;

  /// What screen readers hear in place of the row's text, which still
  /// taps the row.
  final String? semanticsLabel;

  /// The title at 800 (a highlighted row), and in [titleColor].
  final bool bold;
  final Color? titleColor;

  /// Null lets the subtitle wrap (an address).
  final int? subtitleMaxLines;
  final IconData? icon;
  final Widget? leading;
  final String? subtitle;

  /// [subtitle] with a part styled ("3 open", SPEC §7.3), drawn in its
  /// place.
  final InlineSpan? subtitleSpan;
  final VoidCallback? onTap;

  /// In place of the chevron.
  final Widget? trailing;

  /// [trailing] has buttons of its own (Copy, Clear date): they stay out of
  /// the row's one screen-reader item, which taps the row, so each can be
  /// reached and pressed. The row's ink and tap then end where they start.
  final bool trailingActions;
  final bool chevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme;
    final color = titleColor ?? (destructive ? c.cherry.text : c.textOnPage);
    final sub = subtitle;
    final lead =
        leading ??
        (icon == null
            ? null
            : Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: destructive ? c.cherry.face : c.roles.palette.mustard,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.ink, width: 2.5),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: destructive ? c.inkOn(c.cherry) : c.ink,
                ),
              ));
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
    final apart = trailingActions && end != null;
    // Gives way to the title at large text sizes, at most under half the
    // row.
    final endBox = BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width * 0.45,
    );
    final below =
        !apart &&
        end != null &&
        end is! Icon &&
        MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final item = MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: FocusRingInk(
          onTap: onTap,
          child: _Spoken(
            label: semanticsLabel,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    if (lead != null) ...[lead, const SizedBox(width: 11)],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: text.bodyLarge?.copyWith(
                              fontSize: 16.5,
                              height: 21 / 16.5,
                              fontWeight: bold
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: color,
                            ),
                          ),
                          if (sub != null && sub.isNotEmpty)
                            Text.rich(
                              subtitleSpan ?? TextSpan(text: sub),
                              maxLines: subtitleMaxLines,
                              overflow: subtitleMaxLines == null
                                  ? null
                                  : TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(
                                fontSize: 14,
                                height: 17 / 14,
                                fontWeight: FontWeight.w700,
                                color: c.textMutedOnPage,
                              ),
                            ),
                          if (below)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: end,
                            ),
                        ],
                      ),
                    ),
                    if (end != null && !apart && !below) ...[
                      const SizedBox(width: 14),
                      ConstrainedBox(constraints: endBox, child: end),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!apart) return item;
    return Row(
      children: [
        Expanded(child: item),
        const SizedBox(width: 14),
        ConstrainedBox(constraints: endBox, child: end),
      ],
    );
  }
}

/// [child], heard by screen readers as [label] when there is one. The tap
/// of the ink around it stays.
class _Spoken extends StatelessWidget {
  const new({required this.label, required this.child});

  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) => label == null
      ? child
      : Semantics(
          label: label,
          child: ExcludeSemantics(child: child),
        );
}

/// A section heading on the page (SPEC §7.3; Boot Camp Mix, #85): stencil
/// 900 20/25, spaced 0.045 em, capitals, in the text color ("JUST FOR
/// YOU"). Screen readers hear it in plain case.
class SectionLabel extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    // Its own node, so the text after it isn't read as part of it.
    container: true,
    header: true,
    child: Text(
      text.toUpperCase(),
      semanticsLabel: text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 20,
        height: 25 / 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 20 * 0.045,
        color: GumdropColors.of(context).textOnPage,
      ),
    ),
  );
}

/// A true card (SPEC §7.3): the team card, a player card, drawn as a Boot
/// Camp Mix panel (#85): the panel color, a 3 px ink outline on a hard 4/4
/// shadow, square, and its [child] in the card context. A [Material], so
/// list tiles, switches, and ink inside draw on it.
class SettingsPanel extends StatelessWidget {
  const new({
    required this.child,
    this.radius = 0,
    this.padding = const EdgeInsets.all(12),
    super.key,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final rim = BorderSide(color: c.ink, width: 3);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: c.pageShadow, offset: const Offset(4, 4))],
      ),
      child: Material(
        color: c.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: rim,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: GumdropSurface(
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A group of rows in one ink panel (SPEC §7.3, #85), as [PageRows] draws
/// them. [padding] insets the panel; [divided] is kept for callers and
/// always on. A [ListTile] among the rows has no inset of its own, so it
/// lines up with the rows around it.
class SettingsCard extends StatelessWidget {
  const new({
    required this.children,
    this.padding = EdgeInsets.zero,
    this.divided = true,
    super.key,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  /// Always ruled now (SPEC §7.3).
  final bool divided;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: ListTileTheme.merge(
      contentPadding: EdgeInsets.zero,
      child: PageRows(children: children),
    ),
  );
}

/// A settings row (SPEC §7.3): a [PageRow], its icon on a mustard badge,
/// the title in Comic Neue Bold, the subtitle muted, and a chevron when it
/// opens something. [highlighted] sets the title bold; a cherry
/// [accent] (Delete) puts the icon and title in the accent text. A
/// [ListTile]'s semantics, through [PageRow].
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

  /// Null lets the subtitle wrap (a line that says what a row does, #16).
  final int? subtitleLines;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final color = titleColor ?? accent?.text;
    return PageRow(
      title: title,
      icon: icon,
      leading: icon != null && color != null
          ? Icon(icon, size: 22, color: color)
          : null,
      subtitle: subtitle,
      subtitleMaxLines: subtitleLines,
      onTap: onTap,
      trailing: trailing,
      chevron: chevron,
      bold: highlighted,
      titleColor: color,
      destructive: accent == c.cherry,
    );
  }
}

/// A permission row's text style (design §3.8, §3.11): Comic Neue 800 15, in
/// the card's text color (a switch row sits on a card).
TextStyle? switchRowTitle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      // The panel's lettering: switch rows sit in a panel of rows (#85),
      // whose lettering is Candy Pop's navy on white (#86).
      color: GumdropColors.of(context).card.textPrimary,
    );

/// A heading inside a card (SPEC §7.3): the stencil 20 in the text color,
/// with no drop.
class CardHeading extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context).card;
    return Semantics(
      container: true,
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 20,
          height: 1.1,
          color: c.headingTextOnCard,
          shadows: const [],
        ),
      ),
    );
  }
}

/// A section heading on the page (SPEC §7.3): the stencil 25/30 with the
/// scheme's drop.
class PageHeading extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    header: true,
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontSize: 25, height: 30 / 25),
    ),
  );
}

/// A field with its caps label above it (design §3.13): stencil 600 12,
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 13,
              height: 16 / 13,
              letterSpacing: 13 * 0.12,
              color: c.onCard ? c.textMuted : c.textMutedOnPage,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

/// The settings field look (design §3.13): 44 tall, 14 px corners, Comic Neue
/// 800 16. The fill and outline come from the theme.
InputDecoration gumdropField({String? hint, Widget? suffixIcon}) =>
    InputDecoration(
      hintText: hint,
      isDense: true,
      counterText: '',
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    );

/// The settings field text: Comic Neue 800 16.
TextStyle? gumdropFieldText(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge
        ?.copyWith(fontWeight: FontWeight.w800, height: 1.2);

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
              border: Border.all(color: c.outline, width: 2),
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
