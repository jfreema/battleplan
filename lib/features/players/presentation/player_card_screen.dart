import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// PLAYER-2 at `/g/:groupId/roster/players/:playerId`: name, number,
/// position, and guardians. Guardians and admins can edit the details and
/// add a guardian (PLAYER-5); admins remove guardians and the player, and a
/// guardian can remove themself. Upcoming RSVPs join with the schedule.
class PlayerCardScreen extends ConsumerWidget {
  const new({required this.groupId, required this.playerId, super.key});

  final GroupId groupId;
  final PlayerId playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final player = ref
        .watch(playersProvider(groupId))
        .value
        ?.where((p) => p.id == playerId)
        .firstOrNull;
    final links = ref.watch(guardianLinksProvider(groupId)).value ?? const [];
    final roster = ref.watch(rosterProvider(groupId)).value ?? const [];
    final me = ref.watch(authUserProvider).value?.uid;
    // Super admins manage players and guardians from the admin panel too
    // (ADMIN-3).
    final isAdmin =
        (ref.watch(myMembershipProvider(groupId))?.isAdmin ?? false) ||
        (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);
    if (player == null) {
      return Scaffold(appBar: AppBar());
    }
    final guardianIds = {
      for (final l in links)
        if (l.playerId == playerId) l.uid,
    };
    final guardians = roster.where((m) => guardianIds.contains(m.uid)).toList();
    final isGuardian = me != null && guardianIds.contains(UserId(me));
    final canEdit = isAdmin || isGuardian;

    return Scaffold(
      appBar: AppBar(
        title: Text(player.displayName),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: l10n.editPlayer,
              icon: const Icon(AppIcons.edit),
              onPressed: () => unawaited(_edit(context, ref, player)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.jerseyNumberLabel),
            subtitle: Text(player.jerseyNumber ?? '—'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.positionLabel),
            subtitle: Text(player.position ?? '—'),
          ),
          const SizedBox(height: Space.lg),
          Text(
            l10n.guardiansLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (guardians.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Text(l10n.noGuardians),
            ),
          for (final g in guardians)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Avatar(name: g.displayName, colorKey: g.uid.value),
              title: Text(g.displayName),
              subtitle: g.pending ? Text(l10n.notJoinedYet) : null,
              // Admins remove any guardian; a guardian can remove themself.
              trailing: isAdmin || g.uid.value == me
                  ? IconButton(
                      tooltip: l10n.removeGuardian,
                      icon: const Icon(AppIcons.close),
                      onPressed: () => unawaited(
                        _removeGuardian(context, ref, g.uid, g.displayName),
                      ),
                    )
                  : null,
            ),
          // A guardian vouches for a co-parent; admins can add anyone
          // (PLAYER-5, PLAYER-2).
          if (canEdit && guardians.length < Limits.guardiansPerPlayerMax)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => unawaited(_addGuardian(context, ref)),
                icon: const Icon(AppIcons.invite),
                label: Text(l10n.addGuardian),
              ),
            ),
          if (isAdmin) ...[
            const SizedBox(height: Space.xl),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: l10n.removePlayerTitle(player.displayName),
                  confirmLabel: l10n.removePlayer,
                  cancelLabel: l10n.cancel,
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                try {
                  await ref
                      .read(playerRepositoryProvider)
                      .removePlayer(groupId, playerId);
                  if (context.mounted) context.pop();
                } on AppFailure {
                  if (context.mounted) {
                    showAppSnackBar(context, l10n.signInUnknownError);
                  }
                }
              },
              child: Text(l10n.removePlayer),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addGuardian(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final email = TextEditingController();
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addGuardian),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.addGuardianHelp),
            TextField(
              controller: email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.guardianEmailLabel),
            ),
            TextField(
              controller: name,
              maxLength: 60,
              decoration: InputDecoration(labelText: l10n.guardianNameLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    final address = email.text.trim();
    if (ok != true || !address.contains('@') || !context.mounted) return;
    try {
      final invited = await ref
          .read(playerRepositoryProvider)
          .inviteGuardian(
            groupId,
            playerId,
            email: address,
            name: name.text.trim().isEmpty ? null : name.text.trim(),
          );
      if (context.mounted) {
        showAppSnackBar(
          context,
          invited ? l10n.guardianInvited : l10n.guardianAdded,
        );
      }
    } on AppFailure catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, switch (e) {
          InvalidInput() => l10n.tooManyGuardians,
          RateLimited() => l10n.signInRateLimited,
          _ => l10n.signInUnknownError,
        });
      }
    }
  }

  Future<void> _removeGuardian(
    BuildContext context,
    WidgetRef ref,
    UserId uid,
    String name,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.removeGuardianTitle(name),
      confirmLabel: l10n.removeGuardian,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref
          .read(playerRepositoryProvider)
          .removeGuardian(groupId, playerId, uid);
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.signInUnknownError);
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Player player) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController(text: player.displayName);
    final number = TextEditingController(text: player.jerseyNumber);
    final position = TextEditingController(text: player.position);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editPlayer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: l10n.playerNameLabel),
            ),
            TextField(
              controller: number,
              maxLength: 4,
              decoration: InputDecoration(labelText: l10n.jerseyNumberLabel),
            ),
            TextField(
              controller: position,
              decoration: InputDecoration(labelText: l10n.positionLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (save != true || name.text.trim().isEmpty) return;
    try {
      await ref
          .read(playerRepositoryProvider)
          .updatePlayer(
            player.id,
            name: name.text,
            jerseyNumber: number.text,
            position: position.text,
          );
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.profileSaveFailed);
    }
  }
}
