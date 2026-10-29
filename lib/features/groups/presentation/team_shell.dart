import 'dart:async';
import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
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
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/shell_parts.dart';
import 'package:battleplan/features/groups/presentation/team_switcher.dart';
import 'package:battleplan/features/notifications/notifications.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The tab names in route order: `/g/:groupId/<tab>` (ARCH §5.4).
const teamTabs = ['chat', 'schedule', 'documents', 'plays'];

/// The team view: header with the back arrow to Teams, the switcher, and
/// Team info, then Chat · Schedule · Documents · Plays as a bottom bar on
/// phones or a left rail at 840 px and up (SPEC §5).
///
/// A super admin who isn't on the team sees it read-only instead, under
/// "Viewing as super admin" (ADMIN-3 View team): no switcher or composer,
/// but Team info and the moderation the tabs offer them.
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
            child: GumdropBackButton(onPressed: () => context.go('/teams')),
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
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;

    // Each tab's icon, outlined on every tab: the gumdrop indicator marks
    // the one that's showing (design §3.2).
    Widget Function({required bool selected}) glyph(IconData icon) =>
        ({required selected}) => Icon(icon);
    // A basic group has no Plays (TEAM-14); it's the last tab, so the
    // others keep their places. A link to a group's Plays goes to its chat.
    final plays = (viewing ? viewed : team?.group)?.hasPlayers ?? true;
    if (!plays && navigationShell.currentIndex == teamTabs.indexOf('plays')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/g/${groupId.value}/chat');
      });
    }
    final destinations = <(Widget Function({required bool selected}), String)>[
      (({required selected}) => const ChatIcon(), l10n.tabChat),
      (glyph(AppIcons.schedule), l10n.tabSchedule),
      (glyph(AppIcons.documents), l10n.tabDocuments),
      // Drawn: no icon font has a coach's play, an O, its route, and an X
      // (BOARD-1).
      if (plays) (({required selected}) => const PlaysIcon(), l10n.tabPlays),
    ];
    // The Chat tab shows this team's unread count (CHAT-9).
    final unread = viewing
        ? 0
        : ref.watch(unreadCountProvider(groupId)).value ?? 0;
    // The count sits at the tab icon's top right, 6 px out from its
    // 21 px glyph (design §3.6, §3.12).
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
        ? _ViewingHeader(group: viewed)
        : _TeamHeader(
            team: team,
            switcherKey: _switcherKey,
            showOtherUnreadDot: otherUnread,
            tabIndex: navigationShell.currentIndex,
            showBack: !widget.inTab,
            onOpenSwitcher: (anchor) => _openSwitcher(context, anchor: anchor),
          );
    // Under the header: "Viewing as super admin", or the storage warning.
    final Widget banner = viewing
        ? ViewingAsSuperAdminBanner(groupId: groupId)
        : _StorageBanner(team: team);

    final loading = viewing ? viewed == null : team == null && teams.isLoading;
    final body = loading ? const SkeletonList() : navigationShell;

    // Ctrl/⌘+K opens the team switcher on web and desktop (SPEC §4.2).
    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
          _openSwitcher(context),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
          _openSwitcher(context),
    };

    final Widget shell;
    if (wide) {
      shell = CallbackShortcuts(
        bindings: shortcuts,
        child: Scaffold(
          body: Row(
            children: [
              // A floating rounded panel, as the phone's tab bar is.
              FloatingRail(
                child: NavigationRail(
                  backgroundColor: Colors.transparent,
                  selectedIndex: math.min(
                    navigationShell.currentIndex,
                    destinations.length - 1,
                  ),
                  onDestinationSelected: navigationShell.goBranch,
                  destinations: [
                    for (final (i, (icon, label)) in destinations.indexed)
                      NavigationRailDestination(
                        icon: tabIcon(i, icon(selected: false)),
                        selectedIcon: tabIcon(i, icon(selected: true)),
                        label: Text(label),
                      ),
                  ],
                ),
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
          // A floating rounded panel (design §3.12).
          bottomNavigationBar: FloatingTabBar(
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              selectedIndex: math.min(
                navigationShell.currentIndex,
                destinations.length - 1,
              ),
              onDestinationSelected: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
              destinations: [
                for (final (i, (icon, label)) in destinations.indexed)
                  NavigationDestination(
                    icon: tabIcon(i, icon(selected: false)),
                    selectedIcon: tabIcon(i, icon(selected: true)),
                    label: label,
                  ),
              ],
            ),
          ),
        ),
      );
    }
    // The whole shell, header and tabs, in the team's colors (TEAM-1).
    final tinted = TeamTheme(
      teamColor: viewing ? viewed?.color : team?.group.color,
      child: shell,
    );
    // Asks for notification permission once the person is in a team
    // (NOTIF-1); viewing someone else's team doesn't count.
    return viewing ? tinted : NotificationPrePrompt(child: tinted);
  }
}

class _TeamHeader extends StatelessWidget {
  const new({
    required this.team,
    required this.switcherKey,
    required this.showOtherUnreadDot,
    required this.tabIndex,
    required this.showBack,
    required this.onOpenSwitcher,
  });

  final MyTeam? team;
  final GlobalKey switcherKey;
  final bool showOtherUnreadDot;

  /// The arrow back to Teams.
  final bool showBack;

  /// The tab showing, which the sticker names.
  final int tabIndex;

  /// Opens the switcher from the button given.
  final void Function(BuildContext anchor) onOpenSwitcher;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= Breakpoints.wide;
    final group = team?.group;
    // The back arrow to Teams, the team name with its chevron, then the
    // round buttons, and the tab's sticker under the name (Gumdrop Pop
    // design §3.2, §3.3, §3.4).
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.gutter(width) - (showBack ? 6 : 2),
        Space.xs,
        Space.gutter(width) - 5,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBack)
                Padding(
                  // Room for the button's hard shadow.
                  padding: const EdgeInsets.only(
                    right: Space.sm + 2,
                    bottom: 4,
                  ),
                  child: GumdropBackButton(
                    onPressed: () => context.go('/teams'),
                  ),
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TeamSwitcherButton(
                    key: switcherKey,
                    name: group?.name ?? '',
                    // An uploaded logo; initials would repeat the name.
                    badge: group?.photoPath == null
                        ? null
                        : GroupBadge(group: group, size: 36),
                    showDot: showOtherUnreadDot && !wide,
                    onPressed: () {
                      final anchor = switcherKey.currentContext;
                      if (anchor != null) onOpenSwitcher(anchor);
                    },
                  ),
                ),
              ),
              // Direct conversations, with how many are unread (CHAT-19).
              const MessagesButton(),
              // Unread notification-center items across all teams (NOTIF-11).
              const NotificationBell(),
              _TeamInfoButton(groupId: group?.id),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: showBack ? 6 : 2, bottom: 2),
            child: TeamSticker(
              TeamSticker.labelFor(l10n, tabIndex, DateTime.now()),
            ),
          ),
        ],
      ),
    );
  }
}

/// The header while viewing as a super admin (ADMIN-3): the team's badge
/// and name, without the switcher, and Team info to manage it.
class _ViewingHeader extends StatelessWidget {
  const new({required this.group});

  final Group? group;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.gutter(width) - 2,
        Space.xs,
        Space.gutter(width) - 5,
        Space.xs,
      ),
      child: Row(
        children: [
          GroupBadge(group: group, size: 36),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Padding(
              // Room for the heading's 4 px shadow.
              padding: const EdgeInsets.only(right: 4, bottom: 4),
              child: Text(
                group?.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          _TeamInfoButton(groupId: group?.id),
        ],
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

/// Team info (SPEC §5.2): a 38 px round gumdrop that opens the team's
/// page of Roster, Invite, Notifications, Calendar link, and the admin
/// rows.
class _TeamInfoButton extends StatelessWidget {
  const new({required this.groupId});

  final GroupId? groupId;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return IconButton(
      tooltip: AppLocalizations.of(context).teamInfo,
      style: GumdropButtons.of(context).icon(),
      iconSize: 19,
      color: c.textPrimary,
      icon: const Icon(AppIcons.info),
      onPressed: () {
        final id = groupId;
        if (id != null) unawaited(context.push('/g/${id.value}/info'));
      },
    );
  }
}
