import 'dart:async';
import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
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
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;

    // Each tab's icon, outlined on every tab: the coral color and bar mark
    // the one that's showing.
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
            team: team,
            switcherKey: _switcherKey,
            showOtherUnreadDot: otherUnread,
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
    final selected = math.min(
      navigationShell.currentIndex,
      destinations.length - 1,
    );

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
                onSelect: navigationShell.goBranch,
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
            onSelect: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
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
/// Messages, notifications and Team info.
class _TeamHeader extends StatelessWidget {
  const new({
    required this.team,
    required this.switcherKey,
    required this.showOtherUnreadDot,
    required this.tabIndex,
    required this.isGroup,
    required this.showBack,
    required this.onOpenSwitcher,
  });

  final MyTeam? team;
  final GlobalKey switcherKey;
  final bool showOtherUnreadDot;

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
                child: BackChevron(onPressed: () => context.go('/teams')),
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
            // Direct conversations, with how many are unread (CHAT-19).
            const _Low(child: MessagesButton()),
            // Unread notification-center items across all teams (NOTIF-11).
            const _Low(child: NotificationBell()),
            _Low(child: _TeamInfoButton(groupId: group?.id)),
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
/// the team's name, without the switcher, and Team info to manage it.
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
            _Low(child: _TeamInfoButton(groupId: group?.id)),
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

/// Team info (SPEC §5.2): a 48 px header icon button that opens the
/// team's page of Roster, Invite, Notifications, Calendar link, and the
/// admin rows.
class _TeamInfoButton extends StatelessWidget {
  const new({required this.groupId});

  final GroupId? groupId;

  @override
  Widget build(BuildContext context) => GumdropIconButton(
    tooltip: AppLocalizations.of(context).teamInfo,
    icon: AppIcons.info,
    onPressed: () {
      final id = groupId;
      if (id != null) unawaited(context.push('/g/${id.value}/info'));
    },
  );
}
