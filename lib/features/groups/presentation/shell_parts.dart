import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The stencil eyebrow over the team name (SPEC §7.3): what the tab is
/// ("Team chat", "Fall schedule"), in Black Ops One capitals. Screen
/// readers hear it in plain case.
abstract final class HeaderEyebrow {
  /// The eyebrow for tab [index] (Chat, Schedule, Documents, Plays) of a
  /// team, or of a group ([group]); a team's schedule names the season it's
  /// in on [now].
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
    _ => l10n.stickerPlays,
  };

  /// The eyebrow's text style: Black Ops One 12/14, spaced 0.18 em, in the
  /// scheme's accent text.
  static TextStyle style(GumdropColors c) => TextStyle(
    fontFamily: AppFonts.sticker,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 14 / 12,
    letterSpacing: 12 * 0.18,
    color: c.you.text,
  );
}

/// One tab of `OpenFieldTabBar` or `OpenFieldRail`: its icon (and the icon
/// when it's the current tab), and its label.
///
/// `badge` is what the tab's count says to a screen reader ("3 unread
/// messages"), or null.
typedef OpenFieldTab = ({
  Widget icon,
  Widget selectedIcon,
  String label,
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
          child: Row(
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
                  ),
                ),
            ],
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

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
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
          ),
        ),
    ];
    return Material(
      color: c.tabBar,
      shape: Border(right: BorderSide(color: c.tabBarLine)),
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: 88,
          child: links.isEmpty
              ? Column(children: items)
              // The links at the foot; on a window too short for them all,
              // the rail scrolls rather than overflows.
              : ScrollConfiguration(
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
                            for (final link in links)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: _Tab(
                                  tab: (
                                    icon: Icon(link.icon),
                                    selectedIcon: Icon(link.icon),
                                    label: link.label,
                                    badge: null,
                                  ),
                                  selected: false,
                                  onTap: link.onTap,
                                  marker: Alignment.centerLeft,
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
  });

  final OpenFieldTab tab;

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
                    Text(
                      tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GumdropStyle.of(context).label(
                        TextStyle(
                          fontSize: 13,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: color,
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
