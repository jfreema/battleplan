import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/groups/presentation/team_switcher.dart';
import 'package:battleplan/features/notifications/notifications.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The tab names in route order: `/g/:groupId/<tab>` (ARCH §5.4).
const teamTabs = ['chat', 'schedule', 'documents'];

/// The team view: header with the switcher, then Chat · Schedule · Documents
/// as a bottom bar on phones or a left rail at 840 px and up (SPEC §5).
///
/// A super admin who isn't on the team sees it read-only instead, under
/// "Viewing as super admin" (ADMIN-3 View team): no switcher, team menu,
/// or composer, but the moderation the tabs offer them.
class TeamShell extends ConsumerWidget {
  const new({required this.groupId, required this.navigationShell, super.key});

  final GroupId groupId;
  final StatefulNavigationShell navigationShell;

  void _switchTo(BuildContext context, GroupId id) {
    final tab = teamTabs[navigationShell.currentIndex];
    context.go('/g/${id.value}/$tab');
  }

  Future<void> _openSwitcher(BuildContext context) async {
    final selected = await showAdaptiveSheet<GroupId>(
      context,
      builder: (sheetContext) => TeamSwitcherList(
        currentGroupId: groupId,
        onSelect: (id) => Navigator.of(sheetContext).pop(id),
        onCreateTeam: () {
          Navigator.of(sheetContext).pop();
          unawaited(context.push('/g/new'));
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
  Widget build(BuildContext context, WidgetRef ref) {
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
          onAction: () => context.go('/'),
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
      // Never a dead end: the account menu (Settings, Sign out) and the
      // person's other teams, to switch, join, or create one.
      return Scaffold(
        appBar: AppBar(actions: const [_AccountButton()]),
        body: ListView(
          children: [
            EmptyState(icon: AppIcons.group, message: l10n.teamSuspended),
            TeamSwitcherList(
              currentGroupId: groupId,
              onSelect: (id) => context.go('/g/${id.value}/chat'),
              onCreateTeam: () => unawaited(context.push('/g/new')),
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

    final destinations = [
      (AppIcons.chat, l10n.tabChat),
      (AppIcons.schedule, l10n.tabSchedule),
      (AppIcons.documents, l10n.tabDocuments),
    ];
    // The Chat tab shows this team's unread count (CHAT-9).
    final unread = viewing
        ? 0
        : ref.watch(unreadCountProvider(groupId)).value ?? 0;
    Widget tabIcon(int index, Widget icon) => index == 0 && unread > 0
        ? Badge(label: Text(unreadLabel(unread)), child: icon)
        : icon;

    Future<void> leave() async {
      final current = team;
      if (current == null) return;
      final ok = await showConfirmDialog(
        context,
        title: l10n.leaveTeamTitle(current.group.name),
        message: l10n.leaveTeamBody,
        confirmLabel: l10n.leaveTeamMenu,
        cancelLabel: l10n.cancel,
        destructive: true,
      );
      if (!ok) return;
      try {
        await ref.read(groupRepositoryProvider).leave(current.group.id);
        if (context.mounted) context.go('/');
      } on OwnerMustTransfer {
        if (context.mounted) showAppSnackBar(context, l10n.ownerMustTransfer);
      } on AppFailure {
        if (context.mounted) showAppSnackBar(context, l10n.signInUnknownError);
      }
    }

    final Widget header = viewing
        ? _ViewingHeader(group: viewed)
        : _TeamHeader(
            team: team,
            showOtherUnreadDot: otherUnread,
            onOpenSwitcher: () => _openSwitcher(context),
            onLeave: leave,
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
              NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: navigationShell.goBranch,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.sm),
                  child: viewing
                      ? TeamBadge(
                          name: viewed?.name ?? '',
                          color: viewed?.color == null
                              ? null
                              : Color(viewed!.color!),
                        )
                      : _SwitcherButton(
                          team: team,
                          showDot: otherUnread,
                          compact: true,
                          onPressed: () => _openSwitcher(context),
                        ),
                ),
                trailing: const Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: Space.lg),
                      child: _AccountButton(),
                    ),
                  ),
                ),
                destinations: [
                  for (final (i, (icon, label)) in destinations.indexed)
                    NavigationRailDestination(
                      icon: tabIcon(i, Icon(icon)),
                      selectedIcon: tabIcon(i, Icon(icon, fill: 1)),
                      label: Text(label),
                    ),
                ],
              ),
              Expanded(
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
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
            destinations: [
              for (final (i, (icon, label)) in destinations.indexed)
                NavigationDestination(
                  icon: tabIcon(i, Icon(icon)),
                  selectedIcon: tabIcon(i, Icon(icon, fill: 1)),
                  label: label,
                ),
            ],
          ),
        ),
      );
    }
    // Asks for notification permission once the person is in a team
    // (NOTIF-1); viewing someone else's team doesn't count.
    return viewing ? shell : NotificationPrePrompt(child: shell);
  }
}

class _TeamHeader extends StatelessWidget {
  const new({
    required this.team,
    required this.showOtherUnreadDot,
    required this.onOpenSwitcher,
    required this.onLeave,
  });

  final MyTeam? team;
  final bool showOtherUnreadDot;
  final VoidCallback onOpenSwitcher;
  final Future<void> Function() onLeave;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Space.gutter(MediaQuery.sizeOf(context).width) - Space.sm,
        vertical: Space.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SwitcherButton(
                team: team,
                showDot: showOtherUnreadDot && !wide,
                onPressed: onOpenSwitcher,
              ),
            ),
          ),
          // Unread notification-center items across all teams (NOTIF-11).
          const NotificationBell(),
          _TeamMenu(
            groupId: team?.group.id,
            isAdmin: team?.membership.isAdmin ?? false,
            onLeave: onLeave,
          ),
          if (!wide) const _AccountButton(),
        ],
      ),
    );
  }
}

/// The header while viewing as a super admin (ADMIN-3): the team's badge
/// and name, without the switcher or the team menu.
class _ViewingHeader extends StatelessWidget {
  const new({required this.group});

  final Group? group;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final color = group?.color;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Space.gutter(width),
        vertical: Space.sm,
      ),
      child: Row(
        children: [
          TeamBadge(
            name: group?.name ?? '',
            color: color == null ? null : Color(color),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              group?.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (width < Breakpoints.wide) const _AccountButton(),
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

class _SwitcherButton extends StatelessWidget {
  const new({
    required this.team,
    required this.showDot,
    required this.onPressed,
    this.compact = false,
  });

  final MyTeam? team;
  final bool showDot;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = team?.group.name ?? '';
    final color = team?.group.color;
    final badge = Badge(
      isLabelVisible: showDot,
      smallSize: 10,
      child: TeamBadge(name: name, color: color == null ? null : Color(color)),
    );
    if (compact) {
      return IconButton(
        tooltip: l10n.switchTeamTooltip,
        onPressed: onPressed,
        icon: badge,
      );
    }
    return Semantics(
      button: true,
      label: '${l10n.switchTeamTooltip}: $name',
      excludeSemantics: true,
      // The InkWell's own tap is excluded with its semantics.
      onTap: onPressed,
      child: InkWell(
        borderRadius: BorderRadius.circular(Corners.card),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              badge,
              const SizedBox(width: Space.sm),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(AppIcons.expand),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamMenu extends StatelessWidget {
  const new({
    required this.groupId,
    required this.isAdmin,
    required this.onLeave,
  });

  final GroupId? groupId;
  final bool isAdmin;
  final Future<void> Function() onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // (route under /g/<id>/, icon, label). Items without a screen yet say
    // "Coming soon".
    final items = [
      ('roster', AppIcons.roster, l10n.rosterMenu),
      ('invite', AppIcons.invite, l10n.inviteMenu),
      ('notifications', AppIcons.notifications, l10n.teamNotificationsMenu),
      if (isAdmin) ('settings', AppIcons.settings, l10n.teamSettingsMenu),
      if (isAdmin) ('media', AppIcons.media, l10n.mediaMenu),
      if (isAdmin) ('reports', AppIcons.report, l10n.reportsMenu),
      ('leave', AppIcons.leave, l10n.leaveTeamMenu),
    ];
    const built = {
      'roster',
      'settings',
      'media',
      'invite',
      'reports',
      'notifications',
    };
    return PopupMenuButton<String>(
      tooltip: l10n.teamMenuTooltip,
      icon: const Icon(AppIcons.more),
      onSelected: (route) {
        final id = groupId;
        if (id == null) return;
        if (route == 'leave') {
          unawaited(onLeave());
        } else if (built.contains(route)) {
          unawaited(context.push('/g/${id.value}/$route'));
        } else {
          showAppSnackBar(context, l10n.comingSoon);
        }
      },
      itemBuilder: (_) => [
        for (final (route, icon, label) in items)
          PopupMenuItem(
            value: route,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon),
              title: Text(label),
            ),
          ),
      ],
    );
  }
}

class _AccountButton extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authUserProvider).value;
    final name = user?.displayName ?? user?.email ?? '';
    // My photo when I have one (SPEC §5.4), else my initials.
    final photoUrl = ref.watch(myPhotoUrlProvider).value;
    return PopupMenuButton<String>(
      tooltip: l10n.accountMenuTooltip,
      onSelected: (value) => switch (value) {
        'settings' => context.push('/settings'),
        'admin' => context.push('/admin'),
        'signOut' => ref.read(sessionServiceProvider).signOut(),
        _ => null,
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'settings', child: Text(l10n.settings)),
        if (user?.isSuperAdmin ?? false)
          PopupMenuItem(value: 'admin', child: Text(l10n.adminPanel)),
        PopupMenuItem(value: 'signOut', child: Text(l10n.signOut)),
      ],
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Avatar(
          name: name,
          colorKey: user?.uid,
          imageUrl: photoUrl,
          size: 32,
        ),
      ),
    );
  }
}
