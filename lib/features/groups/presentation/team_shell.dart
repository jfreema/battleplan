import 'dart:async';
import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/open_sheets.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/back_chevron.dart';
import 'package:battleplan/core/widgets/chat_icon.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/gumdrop_icon_button.dart';
import 'package:battleplan/core/widgets/plays_icon.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/team_switcher_button.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/chat.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/groups/presentation/shell_parts.dart';
import 'package:battleplan/features/groups/presentation/team_switcher.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/notifications.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The tab names in route order: `/g/:groupId/<tab>` (ARCH §5.4). Plays
/// keeps its place for links and the branch it's built in, though a group
/// shows no Plays tab (TEAM-14): the Team tab comes after it either way.
const teamTabs = ['chat', 'schedule', 'documents', 'plays', 'team'];

/// The team view: header with the back arrow to Teams, the switcher, and
/// the Team settings gear, then Chat · Schedule · Documents · Plays · Team
/// as a bottom bar on phones or a left rail at 840 px and up (SPEC §5).
///
/// A super admin who isn't on the team sees it read-only instead, under
/// "Viewing as super admin" (ADMIN-3 View team): no switcher or composer,
/// but Team settings and the moderation the tabs offer them.
class TeamShell extends ConsumerStatefulWidget {
  const new({
    required this.groupId,
    required this.navigationShell,
    this.inTab = false,
    super.key,
  });

  final GroupId groupId;
  final StatefulNavigationShell navigationShell;

  /// A page inside the tab is showing, like Saved plays, with its own back
  /// button: the header leaves out its arrow to Teams, so only one back
  /// shows at a time.
  final bool inTab;

  @override
  ConsumerState<TeamShell> createState() => _TeamShellState();
}

class _TeamShellState extends ConsumerState<TeamShell> {
  /// The header's switcher, which the wide-screen dropdown hangs from
  /// (SPEC §5.2), Ctrl/⌘+K's included.
  final GlobalKey _switcherKey = GlobalKey();

  GroupId get groupId => widget.groupId;
  StatefulNavigationShell get navigationShell => widget.navigationShell;

  /// The team each branch last showed, by branch. A tab keeps its place
  /// (Saved plays, say) while I go from tab to tab, but that place is on
  /// the team it was opened on.
  final Map<int, GroupId> _branchTeams = {};

  /// Opens [branch]'s tab where it was left when that was on this team;
  /// otherwise (another team's place, or not opened yet) at its start on
  /// this team, never back on the team I switched away from. [restart]
  /// starts it over anyway, as tapping the tab that's showing does on
  /// phones.
  void _openBranch(int branch, {bool restart = false}) =>
      navigationShell.goBranch(
        branch,
        initialLocation: restart || _branchTeams[branch] != groupId,
      );

  @override
  void didUpdateWidget(TeamShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId == widget.groupId) return;
    // A sheet or dialog left open (a person's card, a message's menu) is
    // about the team it was opened on, and neither the tab's page nor the
    // shell's own page under it is replaced when the team changes, from
    // the switcher, a notification or link, or leaving for another team:
    // close every one, in the tabs' navigators and the app's, even one a
    // notification's page now covers, so it can't act on the team I left
    // (OpenSheets). Only routes without a page are closed, never the
    // router's pages, and the switcher's own sheet has closed by now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      GoRouter.of(context).observers
          ?.whereType<OpenSheets>()
          .firstOrNull
          ?.closeAll();
    });
  }

  void _switchTo(BuildContext context, GroupId id) {
    final tab = teamTabs[navigationShell.currentIndex];
    context.go('/g/${id.value}/$tab');
  }

  /// A bottom sheet on phones; a dropdown panel under the switcher on wide
  /// screens (SPEC §5.2).
  Future<void> _openSwitcher(
    BuildContext context, {
    BuildContext? anchor,
  }) async {
    final selected = await showAdaptiveSheet<GroupId>(
      context,
      anchor: anchor ?? _switcherKey.currentContext,
      builder: (sheetContext) => TeamSwitcherList(
        currentGroupId: groupId,
        onSelect: (id) => Navigator.of(sheetContext).pop(id),
        onCreate: (kind) {
          Navigator.of(sheetContext).pop();
          unawaited(context.push(createPath(kind)));
        },
        onJoinTeam: () {
          Navigator.of(sheetContext).pop();
          unawaited(context.push('/join'));
        },
      ),
    );
    if (selected != null && context.mounted) _switchTo(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teams = ref.watch(myTeamsProvider);
    final memberships = ref.watch(myMembershipsProvider);

    // Membership guard (ARCH §5.4): non-members see a "not a member" screen,
    // except super admins viewing the team (ADMIN-3).
    final isMember =
        memberships.value?.any((m) => m.groupId == groupId) ?? true;
    final viewing = ref.watch(viewingAsSuperAdminProvider(groupId));
    if (!isMember && !viewing) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: AppIcons.group,
          message: l10n.notAMember,
          actionLabel: l10n.goToMyTeams,
          onAction: () => context.go('/teams'),
        ),
      );
    }

    // A suspended team can't be read by its members (the rules' isMember),
    // while their membership still can: say so rather than load forever
    // (ADMIN-3). Super admins still read it. Read only once the membership
    // is known, so a team just joined isn't read (and refused) too early.
    final onTeam = memberships.value?.any((m) => m.groupId == groupId) ?? false;
    final group = onTeam || viewing
        ? ref.watch(groupProvider(groupId))
        : const AsyncLoading<Group?>();
    if (onTeam && !viewing && group.hasValue && group.value == null) {
      // Never a dead end: back to Teams (and Profile beside it: Settings,
      // Sign out), and the person's other teams, to switch, join, or
      // create one.
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Center(
            child: BackChevron(onPressed: () => context.go('/teams')),
          ),
        ),
        body: ListView(
          children: [
            EmptyState(icon: AppIcons.group, message: l10n.teamSuspended),
            TeamSwitcherList(
              currentGroupId: groupId,
              onSelect: (id) => context.go('/g/${id.value}/chat'),
              onCreate: (kind) => unawaited(context.push(createPath(kind))),
              onJoinTeam: () => unawaited(context.push('/join')),
            ),
          ],
        ),
      );
    }

    final team = teams.value?.where((t) => t.group.id == groupId).firstOrNull;
    final viewed = viewing ? group.value : null;
    final otherUnread =
        teams.value?.any((t) => t.group.id != groupId && t.hasUnread) ?? false;
    // This team's bell counts only its own notifications, so the arrow back
    // to Teams, whose bell has every team's, shows when that one has more
    // (NOTIF-11).
    final elsewhere =
        !viewing &&
        (ref.watch(unreadNotificationsElsewhereProvider(groupId)).value ??
            false);
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
    final superAdmin = watchSuperAdmin(ref);

    // Each tab's icon, outlined on every tab: the coral color and bar mark
    // the one that's showing.
    Widget Function({required bool selected}) glyph(IconData icon) =>
        ({required selected}) => Icon(icon);
    // A basic group has no Plays (TEAM-14): its tabs skip that branch, and
    // a link to a group's Plays goes to its chat.
    final shownGroup = viewing ? viewed : team?.group;
    final plays = shownGroup?.hasPlayers ?? true;
    if (!plays && navigationShell.currentIndex == teamTabs.indexOf('plays')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/g/${groupId.value}/chat');
      });
    }
    // The branch each shown tab opens, in the order they show: every tab
    // but Plays in a group.
    final branches = [
      for (final (i, tab) in teamTabs.indexed)
        if (plays || tab != 'plays') i,
    ];
    final destinations = <(Widget Function({required bool selected}), String)>[
      (({required selected}) => const ChatIcon(), l10n.tabChat),
      (glyph(AppIcons.schedule), l10n.tabSchedule),
      (glyph(AppIcons.documents), l10n.tabDocuments),
      // Drawn: no icon font has a coach's play, an O, its route, and an X
      // (BOARD-1).
      if (plays) (({required selected}) => const PlaysIcon(), l10n.tabPlays),
      // The roster, Invite, and Dues (SPEC §5.3); a group's is People.
      (
        glyph(AppIcons.group),
        (shownGroup?.isGroup ?? false) ? l10n.groupPeople : l10n.tabTeam,
      ),
    ];
    // The Chat tab shows this team's unread count (CHAT-9).
    final unread = viewing
        ? 0
        : ref.watch(unreadCountProvider(groupId)).value ?? 0;
    // The count sits at the tab icon's top right.
    Widget tabIcon(int index, Widget icon) => switch (index) {
      0 when unread > 0 => unreadBadge(
        context,
        label: unreadLabel(unread),
        offset: const Offset(4, -4),
        child: icon,
      ),
      // Only Chat counts; Schedule's waiting RSVPs were too noisy (owner's
      // request, 2026-10-15).
      _ => icon,
    };

    final Widget header = viewing
        ? _ViewingHeader(group: viewed, tabIndex: navigationShell.currentIndex)
        : _TeamHeader(
            groupId: groupId,
            team: team,
            switcherKey: _switcherKey,
            showOtherUnreadDot: otherUnread,
            showBackDot: elsewhere,
            tabIndex: navigationShell.currentIndex,
            isGroup: team?.group.isGroup ?? false,
            showBack: !widget.inTab,
            onOpenSwitcher: (anchor) => _openSwitcher(context, anchor: anchor),
          );
    // Under the header: "Viewing as super admin", or the storage warning.
    final Widget banner = viewing
        ? ViewingAsSuperAdminBanner(groupId: groupId)
        : _StorageBanner(team: team);

    final loading = viewing ? viewed == null : team == null && teams.isLoading;
    final body = loading ? const SkeletonList() : navigationShell;

    // Ctrl/⌘+K opens the team switcher on web and desktop (SPEC §4.2), and
    // on the Chat tab, Ctrl/⌘+F its search (CHAT-20).
    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
          _openSwitcher(context),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
          _openSwitcher(context),
      if (!viewing && navigationShell.currentIndex == teamTabs.indexOf('chat'))
        ...chatSearchShortcuts(
          () => openChatSearch(context, groupId, direct: false),
        ),
    };

    final tabs = <OpenFieldTab>[
      for (final (i, (icon, label)) in destinations.indexed)
        (
          icon: tabIcon(i, icon(selected: false)),
          selectedIcon: tabIcon(i, icon(selected: true)),
          label: label,
          badge: i == 0 && unread > 0 ? l10n.unreadCount(unread) : null,
        ),
    ];
    // The shown tab for the branch that's open; Plays in a group shows as
    // Chat for the frame before it goes there.
    final selected = math.max(
      branches.indexOf(navigationShell.currentIndex),
      0,
    );
    // The branch showing is on this team now.
    _branchTeams[navigationShell.currentIndex] = groupId;

    final Widget shell;
    if (wide) {
      shell = CallbackShortcuts(
        bindings: shortcuts,
        child: Scaffold(
          body: Row(
            children: [
              OpenFieldRail(
                tabs: tabs,
                selectedIndex: selected,
                onSelect: (i) => _openBranch(branches[i]),
                // The header's Admin panel button, for super admins, is
                // here on wide screens (SPEC §5.5).
                links: [
                  if (superAdmin)
                    (
                      icon: AppIcons.admin,
                      label: l10n.adminPanel,
                      onTap: () => openAdminPanel(context),
                    ),
                ],
              ),
              // Below the status bar on an iPad, as the narrow layout is;
              // the rail keeps the left edge, and screens their own bottom.
              Expanded(
                child: SafeArea(
                  left: false,
                  bottom: false,
                  child: Column(
                    children: [
                      header,
                      banner,
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: Breakpoints.contentMax,
                            ),
                            child: body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      shell = CallbackShortcuts(
        bindings: shortcuts,
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                header,
                banner,
                Expanded(child: body),
              ],
            ),
          ),
          bottomNavigationBar: OpenFieldTabBar(
            tabs: tabs,
            selectedIndex: selected,
            onSelect: (i) => _openBranch(
              branches[i],
              restart: branches[i] == navigationShell.currentIndex,
            ),
          ),
        ),
      );
    }
    // The router puts the whole shell, header and tabs, in the scheme I see
    // the team in (SET-2, TeamSchemeTheme), around this widget, so the
    // switcher and the prompt below open in it too, and the status bar's
    // icons follow it.
    // Asks for notification permission once the person is in a team
    // (NOTIF-1); viewing someone else's team doesn't count.
    return SchemeStatusBar(
      child: viewing ? shell : NotificationPrePrompt(child: shell),
    );
  }
}

/// The team header (SPEC §7.3): one 52 px row with the chevron back to
/// Teams, the tab's stencil eyebrow over the team name (the switcher), and
/// the Admin panel for super admins on phones, Messages, this team's
/// notifications and the Team settings gear.
class _TeamHeader extends StatelessWidget {
  const new({
    required this.groupId,
    required this.team,
    required this.switcherKey,
    required this.showOtherUnreadDot,
    required this.showBackDot,
    required this.tabIndex,
    required this.isGroup,
    required this.showBack,
    required this.onOpenSwitcher,
  });

  final GroupId groupId;
  final MyTeam? team;
  final GlobalKey switcherKey;
  final bool showOtherUnreadDot;

  /// The dot on the arrow back to Teams: its bell has unread items this
  /// team's doesn't.
  final bool showBackDot;

  /// The arrow back to Teams.
  final bool showBack;

  /// The tab showing, which the eyebrow names.
  final int tabIndex;

  /// A group, whose eyebrows say "Group".
  final bool isGroup;

  /// Opens the switcher from the button given.
  final void Function(BuildContext anchor) onOpenSwitcher;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
    final group = team?.group;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: EdgeInsets.only(left: showBack ? 4 : 18, right: 8),
        child: Row(
          children: [
            if (showBack) ...[
              Padding(
                // On the optical center of the two-line name.
                padding: const EdgeInsets.only(top: 3),
                child: BackChevron(
                  onPressed: () => context.go('/teams'),
                  showDot: showBackDot,
                  dotLabel: l10n.notificationsElsewhere,
                ),
              ),
              const SizedBox(width: 2),
            ],
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TeamSwitcherButton(
                  key: switcherKey,
                  name: group?.name ?? '',
                  eyebrow: HeaderEyebrow.labelFor(
                    l10n,
                    tabIndex,
                    DateTime.now(),
                    group: isGroup,
                  ),
                  showDot: showOtherUnreadDot && !wide,
                  onPressed: () {
                    final anchor = switcherKey.currentContext;
                    if (anchor != null) onOpenSwitcher(anchor);
                  },
                ),
              ),
            ),
            // The God admin panel in one tap, for super admins (ADMIN).
            const _Low(child: AdminPanelButton()),
            // Direct conversations, with how many are unread (CHAT-19).
            const _Low(child: MessagesButton()),
            // This team's unread notification-center items (NOTIF-11).
            _Low(child: NotificationBell(groupId: groupId)),
            _Low(child: _TeamSettingsButton(group: group)),
          ],
        ),
      ),
    );
  }
}

/// A header icon 3 px low, level with the back chevron.
class _Low extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 3), child: child);
}

/// The header while viewing as a super admin (ADMIN-3): the eyebrow and
/// the team's name, without the switcher, and Team settings to manage it.
class _ViewingHeader extends StatelessWidget {
  const new({required this.group, required this.tabIndex});

  final Group? group;
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final eyebrow = HeaderEyebrow.labelFor(
      l10n,
      tabIndex,
      DateTime.now(),
      group: group?.isGroup ?? false,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    semanticsLabel: eyebrow,
                    maxLines: 1,
                    style: HeaderEyebrow.style(c),
                  ),
                  TeamName(group?.name ?? ''),
                ],
              ),
            ),
            _Low(child: _TeamSettingsButton(group: group)),
          ],
        ),
      ),
    );
  }
}

/// A slim line under the header about the team's storage: nearly full for
/// admins (STORE-3), full for everyone (STORE-4). Admins also get Media.
/// Dismissing hides that level for the rest of the session.
class _StorageBanner extends ConsumerWidget {
  const new({required this.team});

  final MyTeam? team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = team;
    final dismissed = ref.watch(dismissedStorageBannersProvider);
    if (t == null) return const SizedBox.shrink();
    final level = t.group.storageLevel;
    final isAdmin = t.membership.isAdmin;
    final shown =
        level == StorageLevel.full ||
        (level == StorageLevel.nearlyFull && isAdmin);
    if (!shown || dismissed.contains((t.group.id, level))) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final full = level == StorageLevel.full;
    final accent = full ? scheme.error : AppColors.of(context).maybe;
    final width = MediaQuery.sizeOf(context).width;
    return Material(
      color: full
          ? scheme.errorContainer
          : Color.alphaBlend(accent.withValues(alpha: 0.14), scheme.surface),
      child: Padding(
        padding: EdgeInsets.only(left: Space.gutter(width), right: Space.xs),
        child: Row(
          children: [
            Icon(AppIcons.storage, size: 20, color: accent),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.sm),
                child: Text(
                  full
                      ? l10n.storageFullMessage
                      : l10n.storageWarningBanner(Limits.storageWarnPercent),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: full ? scheme.onErrorContainer : scheme.onSurface,
                  ),
                ),
              ),
            ),
            if (isAdmin)
              TextButton(
                onPressed: () =>
                    unawaited(context.push('/g/${t.group.id.value}/media')),
                child: Text(l10n.mediaMenu),
              ),
            IconButton(
              tooltip: l10n.dismiss,
              icon: const Icon(AppIcons.close, size: 20),
              onPressed: () => ref
                  .read(dismissedStorageBannersProvider.notifier)
                  .dismiss(t.group.id, level),
            ),
          ],
        ),
      ),
    );
  }
}

/// Team settings (SPEC §5.1): a 48 px gear in the header that opens the
/// team's settings page at `/g/:groupId/info`: Notifications for this
/// team, Color scheme, and Calendar link, then the admins' rows. It was an
/// ⓘ for Team info, which read as information rather than settings
/// (owner's request 2026-11-10).
class _TeamSettingsButton extends StatelessWidget {
  const new({required this.group});

  final Group? group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GumdropIconButton(
      tooltip: (group?.isGroup ?? false)
          ? l10n.groupSettings
          : l10n.teamSettings,
      icon: AppIcons.settings,
      onPressed: () {
        final id = group?.id;
        if (id != null) unawaited(context.push('/g/${id.value}/info'));
      },
    );
  }
}
