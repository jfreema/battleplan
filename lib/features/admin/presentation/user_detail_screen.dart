import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/features/admin/presentation/users_screen.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/auth.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// ADMIN-4 at `/admin/users/:uid`: the person's profile, status, sign-in
/// methods, teams and roles, joined date, and last active, with every
/// action: edit name, add to a team, password reset, sign out everywhere,
/// disable or enable, super admin, and delete. Each one that takes
/// something away asks first (ADMIN-8). Nobody sees or sets a password.
class AdminUserScreen extends ConsumerWidget {
  const new({required this.uid, super.key});

  final UserId uid;

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(adminUserProvider(uid))
      ..invalidate(adminUsersProvider)
      ..invalidate(adminTotalsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(adminUserProvider(uid));
    final name = detail.value?.user.displayName;
    return AdminScaffold(
      section: AdminSection.users,
      title: name == null || name.isEmpty ? l10n.adminUsers : name,
      actions: [
        IconButton(
          tooltip: l10n.retry,
          icon: const Icon(AppIcons.retry),
          onPressed: () => _refresh(ref),
        ),
      ],
      body: switch (detail) {
        AsyncValue(:final AdminUserDetail value) => AdminBody(
          maxWidth: 960,
          children: [
            _Profile(detail: value),
            _Actions(detail: value, onChanged: () => _refresh(ref)),
            _Teams(detail: value),
          ],
        ),
        AsyncError() => EmptyState(
          icon: AppIcons.person,
          message: l10n.adminNotFound,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// "Email and password", "Google", "Apple".
String _methodLabel(AppLocalizations l10n, String id) => switch (id) {
  'password' => l10n.adminMethodPassword,
  'google.com' => l10n.adminMethodGoogle,
  'apple.com' => l10n.adminMethodApple,
  'emailLink' => l10n.adminMethodEmailLink,
  _ => id,
};

class _Profile extends StatelessWidget {
  const new({required this.detail});

  final AdminUserDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final u = detail.user;
    final methods = detail.signInMethods.isEmpty
        ? l10n.adminNoSignInYet
        : detail.signInMethods.map((m) => _methodLabel(l10n, m)).join(', ');
    return AdminSectionCard(
      title: l10n.profile,
      trailing: UserStatusChip(status: u.status),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(name: u.displayName, colorKey: u.uid.value, size: 56),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.displayName, style: theme.textTheme.titleLarge),
                  if (u.email != null) SelectableText(u.email!),
                  if (u.superAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.xs),
                      child: StatusChip(
                        label: l10n.adminSuperAdmin,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  const SizedBox(height: Space.sm),
                  Text(l10n.adminSignInMethods(methods)),
                  Text(l10n.adminJoinedOn(adminDate(l10n, u.createdAt))),
                  Text(l10n.adminLastActive(adminDate(l10n, u.lastActiveAt))),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const new({required this.detail, required this.onChanged});

  final AdminUserDetail detail;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final repo = ref.read(adminRepositoryProvider);
    final u = detail.user;
    final name = u.displayName;
    final isMe = ref.watch(authUserProvider).value?.uid == u.uid.value;
    final disabled = u.status == UserStatus.disabled;

    Future<void> after(Future<bool> run) async {
      if (await run) onChanged();
    }

    Future<void> rename() async {
      final next = await askText(
        context,
        title: l10n.adminEditName,
        label: l10n.adminColName,
      );
      if (next == null || next.trim().isEmpty || !context.mounted) return;
      await after(
        runAdminAction(
          context,
          () => repo.renameUser(u.uid, next),
          done: l10n.profileSaved,
        ),
      );
    }

    Future<void> addToTeam() async {
      final team = await pickTeam(context);
      if (team == null || !context.mounted) return;
      final role = await showDialog<MemberRole>(
        context: context,
        builder: (_) => _RoleDialog(team: team.name),
      );
      if (role == null || !context.mounted) return;
      await after(
        runAdminAction(
          context,
          () => repo.addUserToGroup(u.uid, team.id, role),
          done: l10n.adminAddedToTeam(name, team.name),
        ),
      );
    }

    Future<void> deleteAccount() async {
      final ok = await confirmAndRun(
        context,
        title: l10n.adminDeleteUserTitle(name),
        message: l10n.adminDeleteUserBody,
        confirmLabel: l10n.deleteAccount,
        action: () => repo.deleteUser(u.uid),
        done: l10n.adminUserDeleted(name),
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      onChanged();
      context.go(AdminSection.users.path);
    }

    return AdminSectionCard(
      title: l10n.adminActions,
      children: [
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () => unawaited(rename()),
              icon: const Icon(AppIcons.edit),
              label: Text(l10n.adminEditName),
            ),
            OutlinedButton.icon(
              onPressed: () => unawaited(addToTeam()),
              icon: const Icon(AppIcons.addedToTeam),
              label: Text(l10n.adminAddToTeam),
            ),
            // A reset link by email; nobody sees or sets the password
            // (AUTH-6, ADMIN-8).
            OutlinedButton.icon(
              onPressed: () => unawaited(
                after(
                  confirmAndRun(
                    context,
                    title: l10n.adminResetTitle(name),
                    message: l10n.adminResetBody,
                    confirmLabel: l10n.sendResetLink,
                    action: () => repo.sendPasswordReset(u.uid),
                    done: l10n.adminResetSent,
                  ),
                ),
              ),
              icon: const Icon(AppIcons.key),
              label: Text(l10n.adminSendReset),
            ),
            OutlinedButton.icon(
              onPressed: () => unawaited(
                after(
                  confirmAndRun(
                    context,
                    title: l10n.adminSignOutTitle(name),
                    message: l10n.adminSignOutBody,
                    confirmLabel: l10n.signOutEverywhere,
                    action: () => repo.revokeSessions(u.uid),
                    done: l10n.adminSignedOut,
                  ),
                ),
              ),
              icon: const Icon(AppIcons.signOut),
              label: Text(l10n.signOutEverywhere),
            ),
            OutlinedButton.icon(
              onPressed: () => unawaited(
                after(
                  confirmAndRun(
                    context,
                    title: disabled
                        ? l10n.adminEnableTitle(name)
                        : l10n.adminDisableTitle(name),
                    message: disabled ? null : l10n.adminDisableBody,
                    confirmLabel: disabled
                        ? l10n.adminEnable
                        : l10n.adminDisable,
                    action: () =>
                        repo.setUserDisabled(u.uid, disabled: !disabled),
                    done: disabled ? l10n.adminEnabled : l10n.adminDisabled,
                    destructive: !disabled,
                  ),
                ),
              ),
              icon: Icon(disabled ? AppIcons.check : AppIcons.block),
              label: Text(disabled ? l10n.adminEnable : l10n.adminDisable),
            ),
            // Granting or revoking needs confirmation, and the server
            // refuses to revoke the last one (ADMIN-4).
            OutlinedButton.icon(
              onPressed: () => unawaited(
                after(
                  confirmAndRun(
                    context,
                    title: u.superAdmin
                        ? l10n.adminRevokeSuperTitle(name)
                        : l10n.adminGrantSuperTitle(name),
                    message: u.superAdmin
                        ? l10n.adminRevokeSuperBody
                        : l10n.adminGrantSuperBody,
                    confirmLabel: u.superAdmin
                        ? l10n.adminRevokeSuper
                        : l10n.adminGrantSuper,
                    action: () async {
                      await repo.setSuperAdmin(
                        u.uid,
                        superAdmin: !u.superAdmin,
                      );
                      // Your own change applies once your token refreshes.
                      // Revoking your own also ends this session (the
                      // server revokes it), so the refresh fails and the
                      // sign-out takes over; the change itself worked.
                      if (isMe) {
                        try {
                          await ref.read(authRepositoryProvider).reloadUser();
                        } on AppFailure {
                          // Signed out; nothing more to do here.
                        }
                      }
                    },
                    done: u.superAdmin
                        ? l10n.adminSuperRevoked(name)
                        : l10n.adminSuperGranted(name),
                    destructive: u.superAdmin,
                  ),
                ),
              ),
              icon: const Icon(AppIcons.admin),
              label: Text(
                u.superAdmin ? l10n.adminRevokeSuper : l10n.adminGrantSuper,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  unawaited(context.push('/admin/audit?actor=${u.uid.value}')),
              icon: const Icon(AppIcons.history),
              label: Text(l10n.adminSeeAudit),
            ),
            // The server refuses deleting yourself; the account's own
            // Settings does that, with a fresh sign-in.
            if (!isMe)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                onPressed: () => unawaited(deleteAccount()),
                icon: const Icon(AppIcons.delete),
                label: Text(l10n.deleteAccount),
              ),
          ],
        ),
      ],
    );
  }
}

/// Member or Admin on [team].
class _RoleDialog extends StatefulWidget {
  const new({required this.team});

  final String team;

  @override
  State<_RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends State<_RoleDialog> {
  MemberRole _role = MemberRole.member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.adminAddToTeamTitle(widget.team)),
      content: RolePicker(
        value: _role,
        onChanged: (r) => setState(() => _role = r),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_role),
          child: Text(l10n.add),
        ),
      ],
    );
  }
}

/// The person's teams and roles; each opens the team's admin page.
class _Teams extends StatelessWidget {
  const new({required this.detail});

  final AdminUserDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdminSectionCard(
      title: l10n.adminTeams,
      trailing: Text('${detail.teams.length}'),
      children: [
        if (detail.teams.isEmpty) Text(l10n.adminNoTeamsForUser),
        for (final t in detail.teams)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(AppIcons.group),
            title: Text(t.name.isEmpty ? t.groupId.value : t.name),
            subtitle: Text(roleBadge(l10n, t.role) ?? l10n.adminRoleMember),
            trailing: const Icon(AppIcons.chevronRight),
            onTap: () =>
                unawaited(context.push('/admin/teams/${t.groupId.value}')),
          ),
      ],
    );
  }
}
