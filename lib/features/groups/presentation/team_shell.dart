import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/groups/presentation/team_switcher.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The tab names in route order: `/g/:groupId/<tab>` (ARCH §5.4).
const teamTabs = ['chat', 'schedule', 'docs'];

/// The team view: header with the switcher, then Chat · Schedule · Documents
/// as a bottom bar on phones or a left rail at 840 px and up (SPEC §5).
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
      ),
    );
    if (selected != null && context.mounted) _switchTo(context, selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final teams = ref.watch(myTeamsProvider);
    final memberships = ref.watch(myMembershipsProvider);

    // Membership guard (ARCH §5.4): non-members see a "not a member" screen.
    final isMember =
        memberships.value?.any((m) => m.groupId == groupId) ?? true;
    if (!isMember) {
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

    final team = teams.value?.where((t) => t.group.id == groupId).firstOrNull;
    final otherUnread =
        teams.value?.any((t) => t.group.id != groupId && t.hasUnread) ?? false;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;

    final destinations = [
      (AppIcons.chat, l10n.tabChat),
      (AppIcons.schedule, l10n.tabSchedule),
      (AppIcons.documents, l10n.tabDocuments),
    ];

    final header = _TeamHeader(
      team: team,
      showOtherUnreadDot: otherUnread,
      onOpenSwitcher: () => _openSwitcher(context),
    );

    final body = team == null && teams.isLoading
        ? const SkeletonList()
        : navigationShell;

    // Ctrl/⌘+K opens the team switcher on web and desktop (SPEC §4.2).
    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
          _openSwitcher(context),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
          _openSwitcher(context),
    };

    if (wide) {
      return CallbackShortcuts(
        bindings: shortcuts,
        child: Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: navigationShell.goBranch,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.sm),
                  child: _SwitcherButton(
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
                  for (final (icon, label) in destinations)
                    NavigationRailDestination(
                      icon: Icon(icon),
                      selectedIcon: Icon(icon, fill: 1),
                      label: Text(label),
                    ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    header,
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
    }

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              header,
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
            for (final (icon, label) in destinations)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(icon, fill: 1),
                label: label,
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamHeader extends StatelessWidget {
  const new({
    required this.team,
    required this.showOtherUnreadDot,
    required this.onOpenSwitcher,
  });

  final MyTeam? team;
  final bool showOtherUnreadDot;
  final VoidCallback onOpenSwitcher;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          IconButton(
            tooltip: l10n.notificationsTooltip,
            icon: const Icon(AppIcons.notifications),
            onPressed: () => context.push('/notifications'),
          ),
          _TeamMenu(isAdmin: team?.membership.isAdmin ?? false),
          if (!wide) const _AccountButton(),
        ],
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
  const new({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (AppIcons.roster, l10n.rosterMenu),
      (AppIcons.invite, l10n.inviteMenu),
      (AppIcons.notifications, l10n.teamNotificationsMenu),
      if (isAdmin) (AppIcons.settings, l10n.teamSettingsMenu),
      (AppIcons.leave, l10n.leaveTeamMenu),
    ];
    return PopupMenuButton<int>(
      tooltip: l10n.teamMenuTooltip,
      icon: const Icon(AppIcons.more),
      // Team menu screens arrive in M2.
      onSelected: (_) => showAppSnackBar(context, l10n.comingSoon),
      itemBuilder: (_) => [
        for (final (i, (icon, label)) in items.indexed)
          PopupMenuItem(
            value: i,
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
    return PopupMenuButton<String>(
      tooltip: l10n.accountMenuTooltip,
      onSelected: (value) => switch (value) {
        'settings' => context.push('/settings'),
        'admin' => context.push('/admin'),
        'signOut' => ref.read(authRepositoryProvider).signOut(),
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
        child: Avatar(name: name, colorKey: user?.uid, size: 32),
      ),
    );
  }
}
