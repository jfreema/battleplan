import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// ADMIN-3 at `/admin/teams/:id`: the team at a glance, with its actions
/// (View team, Edit, Archive or Restore, Suspend or Unsuspend, Delete),
/// storage, people, players, invites, and content. Profile, settings,
/// Media, adding people, and players open the team's own screens, which
/// let super admins act as the owner.
class AdminTeamScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  /// After any change: this page and the lists it shows up in.
  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(adminTeamProvider(groupId))
      ..invalidate(adminTeamsProvider)
      ..invalidate(adminTotalsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupProvider(groupId));
    final detail = ref.watch(adminTeamProvider(groupId));
    final g = group.value;
    return AdminScaffold(
      section: AdminSection.teams,
      title: g?.name ?? l10n.adminTeams,
      actions: [
        IconButton(
          tooltip: l10n.retry,
          icon: const Icon(AppIcons.retry),
          onPressed: () => _refresh(ref),
        ),
      ],
      body: g == null
          ? group.isLoading
                ? const Center(child: CircularProgressIndicator())
                : EmptyState(icon: AppIcons.group, message: l10n.adminNotFound)
          : AdminBody(
              maxWidth: 960,
              children: [
                _Summary(group: g, detail: detail.value),
                _Actions(group: g, onChanged: () => _refresh(ref)),
                _Storage(group: g, onChanged: () => _refresh(ref)),
                switch (detail) {
                  AsyncValue(:final AdminTeamDetail value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _People(
                        group: g,
                        detail: value,
                        onChanged: () => _refresh(ref),
                      ),
                      _Players(detail: value),
                      _Invites(
                        group: g,
                        detail: value,
                        onChanged: () => _refresh(ref),
                      ),
                      _Content(
                        group: g,
                        detail: value,
                        onChanged: () => _refresh(ref),
                      ),
                    ],
                  ),
                  AsyncError() => Text(l10n.loadError),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ],
            ),
    );
  }
}

TeamStatus _statusOf(Group g) => g.suspendedAt != null
    ? TeamStatus.suspended
    : g.isArchived
    ? TeamStatus.archived
    : TeamStatus.active;

class _Summary extends ConsumerWidget {
  const new({required this.group, required this.detail});

  final Group group;
  final AdminTeamDetail? detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final logo = group.photoPath == null
        ? null
        : ref.watch(teamPhotoUrlProvider(group.photoPath!)).value;
    final facts = [
      sportName(l10n, group.sport),
      if (detail?.ownerName.isNotEmpty ?? false)
        l10n.adminOwnedBy(detail!.ownerName),
      l10n.membersCount(group.memberCount),
      l10n.adminCreatedOn(adminDate(l10n, detail?.createdAt)),
      l10n.adminLastActive(adminDate(l10n, group.lastMessageAt)),
    ];
    return AdminSectionCard(
      title: group.name,
      trailing: TeamStatusChip(status: _statusOf(group)),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TeamBadge(
              name: group.name,
              color: group.color == null ? null : Color(group.color!),
              imageUrl: logo,
              size: 56,
            ),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in facts) Text(f),
                  if (group.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: Space.sm),
                    Text(group.description!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// View team, Edit, Archive or Restore, Suspend or Unsuspend, Delete
/// (ADMIN-3). Each destructive one asks first (ADMIN-8).
class _Actions extends ConsumerWidget {
  const new({required this.group, required this.onChanged});

  final Group group;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(adminRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;
    final id = group.id;
    final suspended = group.suspendedAt != null;

    Future<void> archive() async {
      final ok = await confirmAndRun(
        context,
        title: group.isArchived ? l10n.restoreTeam : l10n.archiveTeam,
        message: group.isArchived ? null : l10n.archiveTeamBody,
        confirmLabel: group.isArchived ? l10n.restoreTeam : l10n.archiveTeam,
        action: () => repo.setGroupArchived(id, archived: !group.isArchived),
        done: group.isArchived ? l10n.adminRestored : l10n.adminArchived,
      );
      if (ok) onChanged();
    }

    Future<void> suspend() async {
      if (suspended) {
        final ok = await confirmAndRun(
          context,
          title: l10n.adminUnsuspendTitle(group.name),
          confirmLabel: l10n.adminUnsuspend,
          action: () => repo.setGroupSuspended(id, suspended: false),
          done: l10n.adminUnsuspended,
        );
        if (ok) onChanged();
        return;
      }
      // A note for the audit log, optional.
      final note = await askNote(
        context,
        title: l10n.adminSuspendTitle(group.name),
        message: l10n.adminSuspendBody,
        confirmLabel: l10n.adminSuspend,
        destructive: true,
      );
      if (note == null || !context.mounted) return;
      final ok = await runAdminAction(
        context,
        () => repo.setGroupSuspended(id, suspended: true, note: note),
        done: l10n.adminSuspended,
      );
      if (ok) onChanged();
    }

    Future<void> delete() async {
      // Type the name to confirm (ADMIN-3).
      final confirmed = await confirmByTyping(
        context,
        title: l10n.adminDeleteTeamTitle(group.name),
        message: l10n.deleteTeamBody,
        expected: group.name,
        confirmLabel: l10n.deleteTeam,
      );
      if (!confirmed || !context.mounted) return;
      final ok = await runAdminAction(
        context,
        () => repo.deleteGroup(id, group.name),
        done: l10n.adminTeamDeleted(group.name),
      );
      if (!ok || !context.mounted) return;
      onChanged();
      context.go(AdminSection.teams.path);
    }

    return AdminSectionCard(
      title: l10n.adminActions,
      children: [
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            // Opens the team's tabs, read-only, without joining.
            FilledButton.icon(
              onPressed: () => unawaited(context.push('/g/${id.value}/chat')),
              icon: const Icon(AppIcons.visibility),
              label: Text(l10n.adminViewTeam),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  unawaited(context.push('/g/${id.value}/settings')),
              icon: const Icon(AppIcons.edit),
              label: Text(l10n.adminEditTeam),
            ),
            OutlinedButton.icon(
              onPressed: () => unawaited(archive()),
              icon: Icon(
                group.isArchived ? AppIcons.unarchive : AppIcons.archive,
              ),
              label: Text(
                group.isArchived ? l10n.restoreTeam : l10n.archiveTeam,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => unawaited(suspend()),
              icon: const Icon(AppIcons.suspend),
              label: Text(suspended ? l10n.adminUnsuspend : l10n.adminSuspend),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
              onPressed: () => unawaited(delete()),
              icon: const Icon(AppIcons.delete),
              label: Text(l10n.deleteTeam),
            ),
          ],
        ),
      ],
    );
  }
}

/// Storage used against the limit, Media, and changing the limit
/// (STORE-6).
class _Storage extends ConsumerWidget {
  const new({required this.group, required this.onChanged});

  final Group group;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AdminSectionCard(
      title: l10n.storageSection,
      children: [
        StorageMeter(
          usedBytes: group.storageBytes,
          quotaBytes: group.storageQuotaBytes,
        ),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  unawaited(context.push('/g/${group.id.value}/media')),
              icon: const Icon(AppIcons.media),
              label: Text(l10n.mediaMenu),
            ),
            TextButton(
              onPressed: () async {
                if (await changeStorageQuota(context, ref, group)) {
                  onChanged();
                }
              },
              child: Text(l10n.changeStorageLimit),
            ),
          ],
        ),
      ],
    );
  }
}

/// Everyone on the team with their role, and what a super admin can
/// change: roles, ownership, removal (ADMIN-3). Adding people and the
/// roster's players and guardians open the team's own screens.
class _People extends ConsumerWidget {
  const new({
    required this.group,
    required this.detail,
    required this.onChanged,
  });

  final Group group;
  final AdminTeamDetail detail;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final members = [...detail.members]
      ..sort((a, b) {
        int rank(Membership m) => m.role.index;
        final byRole = rank(a).compareTo(rank(b));
        return byRole != 0
            ? byRole
            : a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              );
      });

    Future<void> act(Membership m, _MemberAction action) async {
      final members = ref.read(memberRepositoryProvider);
      final groups = ref.read(groupRepositoryProvider);
      final name = m.displayName;
      if (action == _MemberAction.openUser) {
        unawaited(context.push('/admin/users/${m.uid.value}'));
        return;
      }
      final run = switch (action) {
        // Giving admin takes nothing away, so it doesn't ask first.
        _MemberAction.makeAdmin => runAdminAction(
          context,
          () => members.updateMember(group.id, m.uid, role: MemberRole.admin),
          done: l10n.madeAdminDone(name),
        ),
        _MemberAction.removeAdmin => confirmAndRun(
          context,
          title: l10n.adminRemoveAdminTitle(name),
          confirmLabel: l10n.removeAdmin,
          action: () =>
              members.updateMember(group.id, m.uid, role: MemberRole.member),
          done: l10n.removedAdminDone(name),
        ),
        _MemberAction.makeOwner => confirmAndRun(
          context,
          title: '${l10n.transferOwnership}: $name?',
          message: l10n.adminTransferBody,
          confirmLabel: l10n.transferOwnership,
          action: () => groups.transferOwnership(group.id, m.uid),
          done: l10n.transferDone(name),
        ),
        _MemberAction.remove => confirmAndRun(
          context,
          title: l10n.removeFromTeamTitle(name),
          confirmLabel: l10n.removeFromTeam,
          action: () => members.removeMember(group.id, m.uid),
          done: l10n.removedDone(name),
          destructive: true,
        ),
        _MemberAction.openUser => Future.value(false),
      };
      if (await run) onChanged();
    }

    List<_MemberAction> actionsFor(Membership m) => [
      _MemberAction.openUser,
      if (m.role == MemberRole.member) _MemberAction.makeAdmin,
      if (m.role == MemberRole.admin) _MemberAction.removeAdmin,
      if (m.role != MemberRole.owner && !m.pending) _MemberAction.makeOwner,
      if (m.role != MemberRole.owner) _MemberAction.remove,
    ];

    Widget menu(Membership m) => PopupMenuButton<_MemberAction>(
      tooltip: l10n.adminMemberActions(m.displayName),
      icon: const Icon(AppIcons.more),
      onSelected: (a) => unawaited(act(m, a)),
      itemBuilder: (_) => [
        for (final a in actionsFor(m))
          PopupMenuItem(value: a, child: Text(_memberActionLabel(l10n, a))),
      ],
    );

    String roleLabel(Membership m) =>
        roleBadge(l10n, m.role) ?? l10n.adminRoleMember;

    return AdminSectionCard(
      title: l10n.adminPeople,
      trailing: Text(l10n.membersCount(members.length)),
      children: [
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  unawaited(context.push('/g/${group.id.value}/members/add')),
              icon: const Icon(AppIcons.invite),
              label: Text(l10n.addByEmail),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  unawaited(context.push('/g/${group.id.value}/roster')),
              icon: const Icon(AppIcons.roster),
              label: Text(l10n.adminRosterPlayers),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        if (isWide(context))
          DataTable(
            columns: [
              DataColumn(label: Text(l10n.adminColName)),
              DataColumn(label: Text(l10n.adminColRole)),
              DataColumn(label: Text(l10n.adminColStatus)),
              const DataColumn(label: SizedBox.shrink()),
            ],
            rows: [
              for (final m in members)
                DataRow(
                  cells: [
                    DataCell(Text(m.displayName)),
                    DataCell(Text(roleLabel(m))),
                    DataCell(
                      Text(m.pending ? l10n.notJoinedYet : l10n.inviteJoined),
                    ),
                    DataCell(menu(m)),
                  ],
                ),
            ],
          )
        else
          for (final m in members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Avatar(name: m.displayName, colorKey: m.uid.value),
              title: Text(m.displayName),
              subtitle: Text(
                [roleLabel(m), if (m.pending) l10n.notJoinedYet].join(' · '),
              ),
              trailing: menu(m),
            ),
      ],
    );
  }
}

enum _MemberAction { openUser, makeAdmin, removeAdmin, makeOwner, remove }

String _memberActionLabel(AppLocalizations l10n, _MemberAction a) =>
    switch (a) {
      _MemberAction.openUser => l10n.adminOpenUser,
      _MemberAction.makeAdmin => l10n.makeAdmin,
      _MemberAction.removeAdmin => l10n.removeAdmin,
      _MemberAction.makeOwner => l10n.transferOwnership,
      _MemberAction.remove => l10n.removeFromTeam,
    };

/// Each player, pending ones marked, and who's linked to them: the member
/// who is the player and their guardians (ADMIN-3). Changes go through the
/// roster.
class _Players extends StatelessWidget {
  const new({required this.detail});

  final AdminTeamDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final names = {for (final m in detail.members) m.uid: m.displayName};
    return AdminSectionCard(
      title: l10n.rosterPlayers,
      trailing: Text('${detail.players.length}'),
      children: [
        if (detail.players.isEmpty) Text(l10n.adminNoPlayers),
        for (final p in detail.players)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              p.isPending ? '${p.label} · ${l10n.playerPending}' : p.label,
            ),
            subtitle: Text(switch ([
              for (final g in detail.guardians)
                if (g.playerId == p.id && g.isSelf)
                  l10n.playerLinkSelfName(names[g.uid] ?? g.uid.value)
                else if (g.playerId == p.id)
                  names[g.uid] ?? g.uid.value,
            ]) {
              final List<String> gs when gs.isEmpty => l10n.noPlayerLinks,
              final gs => gs.join(', '),
            }),
          ),
      ],
    );
  }
}

/// The team's link and email invites that still work, each revocable
/// (ADMIN-3). Resetting the link is on the team's Invite screen.
class _Invites extends ConsumerWidget {
  const new({
    required this.group,
    required this.detail,
    required this.onChanged,
  });

  final Group group;
  final AdminTeamDetail detail;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AdminSectionCard(
      title: l10n.adminInvites,
      trailing: TextButton(
        onPressed: () => unawaited(context.push('/g/${group.id.value}/invite')),
        child: Text(l10n.linkSettings),
      ),
      children: [
        if (detail.invites.isEmpty) Text(l10n.adminNoInvites),
        for (final i in detail.invites)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(i.isLink ? AppIcons.link : AppIcons.email),
            title: Text(i.isLink ? l10n.linkSettings : i.email ?? i.code),
            subtitle: Text(
              [
                i.code,
                if (i.maxUses != null)
                  l10n.linkUsesOf(i.useCount, i.maxUses!)
                else
                  l10n.linkUses(i.useCount),
                if (i.expiresAt != null)
                  l10n.linkExpires(adminDate(l10n, i.expiresAt)),
              ].join(' · '),
            ),
            trailing: TextButton(
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: l10n.adminRevokeInviteTitle,
                  message: l10n.adminRevokeInviteBody,
                  confirmLabel: l10n.revoke,
                  cancelLabel: l10n.cancel,
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                final done = await runAdminAction(
                  context,
                  () => ref.read(inviteRepositoryProvider).revokeInvite(i.code),
                  done: l10n.adminInviteRevoked,
                );
                if (done) onChanged();
              },
              child: Text(l10n.revoke),
            ),
          ),
      ],
    );
  }
}

/// How much the team has, its latest messages to review and delete, and
/// View team to review the rest (ADMIN-3 Content). Deleting a message asks
/// first (ADMIN-8) and is audited by deleteMessage (ADMIN-6).
class _Content extends ConsumerWidget {
  const new({
    required this.group,
    required this.detail,
    required this.onChanged,
  });

  final Group group;
  final AdminTeamDetail detail;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Future<void> delete(AdminMessage m) async {
      final ok = await confirmAndRun(
        context,
        title: l10n.deleteMessageTitle,
        message: l10n.deleteMessageBody,
        confirmLabel: l10n.deleteMessage,
        action: () => ref.read(messageRepositoryProvider).deleteMessage(m.id),
        done: l10n.adminMessageDeleted,
        destructive: true,
      );
      if (ok) onChanged();
    }

    return AdminSectionCard(
      title: l10n.adminContent,
      children: [
        Text(
          [
            l10n.countEvents(detail.eventCount),
            l10n.adminDocumentsCount(detail.documentCount),
            l10n.adminPollsCount(detail.pollCount),
          ].join(' · '),
        ),
        const SizedBox(height: Space.xs),
        Text(l10n.adminContentHelp, style: theme.textTheme.bodySmall),
        const SizedBox(height: Space.md),
        Text(l10n.adminRecentMessages, style: theme.textTheme.titleSmall),
        if (detail.recentMessages.isEmpty) Text(l10n.adminNoRecentMessages),
        for (final m in detail.recentMessages)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              m.text.isNotEmpty ? m.text : l10n.adminPhotosCount(m.photoCount),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                m.authorName,
                if (m.text.isNotEmpty && m.photoCount > 0)
                  l10n.adminPhotosCount(m.photoCount),
                adminDateTime(l10n, m.createdAt),
              ].join(' · '),
            ),
            trailing: IconButton(
              tooltip: l10n.adminDeleteMessageOf(m.authorName),
              icon: Icon(AppIcons.delete, color: theme.colorScheme.error),
              onPressed: () => unawaited(delete(m)),
            ),
          ),
      ],
    );
  }
}
