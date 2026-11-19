import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/core/widgets/team_switcher_button.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The stencil eyebrow over the team name (SPEC §7.3): what the tab is
/// ("Team chat", "Fall schedule"), in Black Ops One capitals. Screen
/// readers hear it in plain case.
abstract final class HeaderEyebrow {
  /// The eyebrow for tab [index] (Chat, Schedule, Documents, Plays, Team)
  /// of a team, or of a group ([group]); a team's schedule names the
  /// season it's in on [now].
  static String labelFor(
    AppLocalizations l10n,
    int index,
    DateTime now, {
    bool group = false,
  }) => switch (index) {
    0 => group ? l10n.stickerGroupChat : l10n.stickerChat,
    1 when group => l10n.stickerGroupSchedule,
    1 => switch (now.month) {
      12 || 1 || 2 => l10n.stickerScheduleWinter,
      3 || 4 || 5 => l10n.stickerScheduleSpring,
      6 || 7 || 8 => l10n.stickerScheduleSummer,
      _ => l10n.stickerScheduleFall,
    },
    2 => group ? l10n.stickerGroupDocuments : l10n.stickerDocuments,
    3 => l10n.stickerPlays,
    // The Team tab: a team's roster, a group's people (SPEC §5.3).
    _ => group ? l10n.stickerGroupPeople : l10n.stickerTeam,
  };

  /// The eyebrow's text style: Black Ops One 12/14, spaced 0.18 em, in the
  /// page's muted text, the switcher's. It was coral until #12
  /// (2026-11-16): a label, not "you" or a warning.
  static TextStyle style(GumdropColors c) => TeamSwitcherButton.eyebrowStyle(c);
}

/// One tab of `OpenFieldTabBar` or `OpenFieldRail`: its icon (and the icon
/// when it's the current tab), and its label.
///
/// `short` is what the phone's tab bar shows where five tabs share 320
/// points ("Docs" for Documents, #64), or null for the label; screen
/// readers and the rail have the whole label. `badge` is what the tab's
/// count says to a screen reader ("3 unread messages"), or null.
typedef OpenFieldTab = ({
  Widget icon,
  Widget selectedIcon,
  String label,
  String? short,
  String? badge,
});

/// A link at the foot of `OpenFieldRail`, under its tabs: the Admin panel
/// for super admins (SPEC §5.5). It isn't a tab, so it's never the current
/// one, and screen readers hear a plain button.
typedef OpenFieldRailLink = ({IconData icon, String label, VoidCallback onTap});

/// The docked tab bar (SPEC §7.3): full width, 48 px plus the bottom safe
/// area, in the scheme's tab bar color with a 1 px rule on top. The tabs
/// share the width; the current one has a coral icon, a text-colored label
/// and a 40 × 3 coral bar on the bar's top edge.
///
/// Its labels share one size (#64, owner's request 2026-11-17: "the words
/// collide with each other"): the text size asked for, or smaller where
/// the longest label wouldn't fit its tab with [labelGap] on each side, so
/// no two labels ever touch and none is smaller than its neighbors.
class OpenFieldTabBar extends StatelessWidget {
  const new({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  final List<OpenFieldTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// The least room on each side of a label, so neighbors stay apart.
  static const double labelGap = 4;

  /// The labels' one text scale for tabs [cell] wide: the [asked] scale, or
  /// less where the longest label wouldn't fit with [labelGap] each side.
  static double labelScale(
    BuildContext context,
    List<OpenFieldTab> tabs, {
    required double cell,
    required double asked,
    bool short = true,
  }) {
    final style = _Tab.labelStyle(context);
    var widest = 0.0;
    for (final tab in tabs) {
      final painter = TextPainter(
        text: TextSpan(
          text: short ? tab.short ?? tab.label : tab.label,
          style: style,
        ),
        maxLines: 1,
        textDirection: Directionality.of(context),
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    final room = cell - 2 * labelGap;
    if (widest <= 0 || room <= 0) return asked;
    return room / widest < asked ? room / widest : asked;
  }

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      // A Material, so the tabs' ink draws over the fill. The rule goes
      // under the tabs, so the current tab's coral bar covers it.
      child: Material(
        color: c.tabBar,
        shape: Border(top: BorderSide(color: c.tabBarLine)),
        borderOnForeground: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 0, 6, bottom),
          child: LayoutBuilder(
            builder: (context, box) {
              final scale = labelScale(
                context,
                tabs,
                cell: box.maxWidth / tabs.length,
                asked:
                    MediaQuery.textScalerOf(context).scale(_Tab.labelSize) /
                    _Tab.labelSize,
              );
              return Row(
                children: [
                  for (final (i, tab) in tabs.indexed)
                    Expanded(
                      child: _Tab(
                        tab: tab,
                        index: i,
                        count: tabs.length,
                        selected: i == selectedIndex,
                        onTap: () => onSelect(i),
                        marker: Alignment.topCenter,
                        labelScale: scale,
                        short: true,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The wide layout's rail (840 px and up), as [OpenFieldTabBar]: a 1 px
/// rule along its inner edge, and the current tab marked by a 3 × 40 coral
/// bar on the outer edge. [links] sit at its foot, drawn as the tabs are.
class OpenFieldRail extends StatelessWidget {
  const new({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
    this.links = const [],
    super.key,
  });

  final List<OpenFieldTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<OpenFieldRailLink> links;

  /// The rail's width.
  static const double width = 88;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final linkTabs = <OpenFieldTab>[
      for (final link in links)
        (
          icon: Icon(link.icon),
          selectedIcon: Icon(link.icon),
          label: link.label,
          short: null,
          badge: null,
        ),
    ];
    // One size for every label, the whole label, as the tab bar's (#64). A
    // link may wrap ("Super Admin / Panel", #67), so only its longest word
    // has to fit.
    final scale = OpenFieldTabBar.labelScale(
      context,
      [
        ...tabs,
        for (final link in linkTabs)
          (
            icon: link.icon,
            selectedIcon: link.selectedIcon,
            label: link.label
                .split(' ')
                .reduce((a, b) => b.length > a.length ? b : a),
            short: null,
            badge: null,
          ),
      ],
      cell: width,
      asked:
          MediaQuery.textScalerOf(context).scale(_Tab.labelSize) /
          _Tab.labelSize,
      short: false,
    );
    final items = [
      const SizedBox(height: 12),
      for (final (i, tab) in tabs.indexed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _Tab(
            tab: tab,
            index: i,
            count: tabs.length,
            selected: i == selectedIndex,
            onTap: () => onSelect(i),
            marker: Alignment.centerLeft,
            labelScale: scale,
          ),
        ),
    ];
    return Material(
      color: c.tabBar,
      shape: Border(right: BorderSide(color: c.tabBarLine)),
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: width,
          // The links at the foot. On a window too short for every tab and
          // link, such as a phone on its side with large text, the rail
          // scrolls rather than overflows.
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: false),
            child: CustomScrollView(
              primary: false,
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      ...items,
                      const Spacer(),
                      for (final (i, link) in links.indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _Tab(
                            tab: linkTabs[i],
                            selected: false,
                            onTap: link.onTap,
                            marker: Alignment.centerLeft,
                            labelScale: scale,
                            // "Super Admin / Panel", or a word a line with
                            // large text (#67).
                            lines: 3,
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
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

class _Tab extends StatelessWidget {
  const new({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.marker,
    this.index,
    this.count,
    this.labelScale,
    this.short = false,
    this.lines = 1,
  });

  /// A label's size before the text size scales it.
  static const double labelSize = 13;

  /// A label's style, before the text size scales it.
  static TextStyle labelStyle(BuildContext context, {Color? color}) =>
      GumdropStyle.of(context).label(
        TextStyle(
          fontSize: labelSize,
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );

  final OpenFieldTab tab;

  /// The bar's or the rail's one scale for every label (#64); null shrinks
  /// this label alone, and only if it must.
  final double? labelScale;

  /// The phone bar's shorter label where there is one ("Docs").
  final bool short;

  /// How many lines the label may take: one for a tab, more for a rail
  /// link ("Super Admin / Panel", #67).
  final int lines;

  /// Which tab this is, of [count]; both null for a rail link, which isn't
  /// a tab.
  final int? index;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  /// Where the current tab's coral bar sits: the top edge, or the left.
  final Alignment marker;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final color = selected ? c.textOnPage : c.textMutedOnPage;
    final top = marker == Alignment.topCenter;
    // As a NavigationBar destination reads: the label, its count, and
    // "Tab 1 of 4". A rail link is a plain button: no place among the
    // tabs, and no selected state.
    final (i, n) = (index, count);
    final isTab = i != null && n != null;
    final label = [
      tab.label,
      ?tab.badge,
      if (isTab)
        MaterialLocalizations.of(context)
            .tabLabel(tabIndex: i + 1, tabCount: n),
    ].join(', ');
    return Semantics(
      button: true,
      selected: isTab ? selected : null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: FocusRingInk(
        onTap: onTap,
        radius: BorderRadius.circular(12),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 48,
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: top ? 4 : 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconTheme.merge(
                      data: IconThemeData(
                        size: 24,
                        color: selected ? c.you.face : c.textMutedOnPage,
                      ),
                      child: selected ? tab.selectedIcon : tab.icon,
                    ),
                    const SizedBox(height: 4),
                    // Whole, never cut off ("Docume…"), and at the bar's or
                    // rail's one size, apart from its neighbors (#64).
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OpenFieldTabBar.labelGap,
                      ),
                      child: lines > 1
                          ? Text(
                              tab.label,
                              maxLines: lines,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              textScaler: switch (labelScale) {
                                final scale? => TextScaler.linear(scale),
                                null => null,
                              },
                              style: labelStyle(context, color: color),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                short ? tab.short ?? tab.label : tab.label,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                textScaler: switch (labelScale) {
                                  final scale? => TextScaler.linear(scale),
                                  null => null,
                                },
                                style: labelStyle(context, color: color),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected)
              Positioned.fill(
                child: Align(
                  alignment: marker,
                  child: Container(
                    width: top ? 40 : 3,
                    height: top ? 3 : 40,
                    decoration: BoxDecoration(
                      color: c.you.face,
                      borderRadius: top
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(3),
                            )
                          : const BorderRadius.horizontal(
                              right: Radius.circular(3),
                            ),
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

/// Android's Back from a team, or from Profile, goes [to] Teams, as the
/// header's arrow does (#18, 2026-11-16): Teams opens a team with `go`, so
/// the team is the only page, and Back closed the app. What's over it
/// closes first, as the router does it: a sheet or dialog, a page opened
/// on top, or a tab's own page (Saved plays). While viewing a team as a
/// super admin, it goes where the banner's Done does. The web's Back
/// follows the browser's history, and iOS has no system Back.
class ShellBack extends StatelessWidget {
  const new({required this.to, required this.child, super.key});

  final String to;
  final Widget child;

  @override
  Widget build(BuildContext context) => BackButtonListener(
    onBackButtonPressed: () {
      final router = GoRouter.of(context);
      final showing = ModalRoute.of(context)?.isCurrent ?? false;
      if (!showing || router.canPop()) return SynchronousFuture(false);
      router.go(to);
      return SynchronousFuture(true);
    },
    child: child,
  );
}
