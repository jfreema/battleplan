import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/groups/presentation/plus.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Team settings → Plan (PLAN-4): Free or Plus and until when, who holds
/// the license, What Plus adds, and Move to another team for the holder.
/// Super admins also get Grant, Add 12 months, and End now (PLAN-2) until
/// the admin panel has them (M8).
class PlanSection extends ConsumerWidget {
  const new({required this.group, super.key});

  final Group group;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await action();
      if (context.mounted) showAppSnackBar(context, done);
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, switch (e) {
        InvalidInput(message: 'moved-recently') => l10n.licenseMovedRecently,
        PermissionDenied() => l10n.notAllowed,
        _ => l10n.signInUnknownError,
      });
    }
  }

  Future<void> _move(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final licenseId = group.plan.licenseId;
    if (licenseId == null) return;
    // Teams I own or admin that are on Free.
    final targets = (ref.read(myTeamsProvider).value ?? const <MyTeam>[])
        .where(
          (t) =>
              t.group.id != group.id &&
              t.membership.isAdmin &&
              !t.group.isPlus &&
              !t.group.isArchived,
        )
        .toList();
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(group.plan.endsAt!.toLocal());
    final picked = await showDialog<MyTeam>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(l10n.moveLicenseTitle),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.sm),
            child: Text(l10n.moveLicenseHelp(date)),
          ),
          if (targets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Text(l10n.noTeamsToMoveTo),
            ),
          for (final t in targets)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialog).pop(t),
              child: Text(t.group.name),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    await _run(
      context,
      () => ref
          .read(planRepositoryProvider)
          .moveLicense(licenseId, picked.group.id),
      l10n.licenseMoved(picked.group.name),
    );
  }

  Future<void> _grant(
    BuildContext context,
    WidgetRef ref,
    List<Membership> roster,
  ) async {
    final l10n = AppLocalizations.of(context);
    final admins = roster.where((m) => m.isAdmin).toList();
    final holder = await showDialog<Membership>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(l10n.grantPlusTo),
        children: [
          for (final m in admins)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialog).pop(m),
              child: Text(m.displayName),
            ),
        ],
      ),
    );
    if (holder == null || !context.mounted) return;
    await _run(
      context,
      () => ref.read(planRepositoryProvider).grantLicense(group.id, holder.uid),
      l10n.plusGranted,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authUserProvider).value;
    final superAdmin = user?.isSuperAdmin ?? false;
    final plan = group.plan;
    final plus = group.isPlus;
    final roster = ref.watch(rosterProvider(group.id)).value ?? const [];
    final holderName = plan.holderId == null
        ? null
        : roster
              .where((m) => m.uid == UserId(plan.holderId!))
              .firstOrNull
              ?.displayName;
    final licenseId = plan.licenseId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                plus
                    ? l10n.planPlusUntil(
                        MaterialLocalizations.of(context)
                            .formatMediumDate(plan.endsAt!.toLocal()),
                      )
                    : l10n.planFree,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            if (plus) ...[const SizedBox(width: Space.sm), const PlusBadge()],
          ],
        ),
        if (plus && holderName != null)
          Text(l10n.planHolder(holderName), style: theme.textTheme.bodySmall),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            OutlinedButton(
              onPressed: () =>
                  unawaited(showWhatPlusAdds(context, isAdmin: true)),
              child: Text(l10n.whatPlusAdds),
            ),
            if (plus && plan.holderId == user?.uid)
              OutlinedButton(
                onPressed: () => unawaited(_move(context, ref)),
                child: Text(l10n.moveLicense),
              ),
          ],
        ),
        if (superAdmin) ...[
          const SizedBox(height: Space.sm),
          if (!plus)
            TextButton(
              onPressed: () => unawaited(_grant(context, ref, roster)),
              child: Text(l10n.grantPlus),
            )
          else if (licenseId != null) ...[
            TextButton(
              onPressed: () => unawaited(
                _run(
                  context,
                  () =>
                      ref.read(planRepositoryProvider).extendLicense(licenseId),
                  l10n.plusExtended,
                ),
              ),
              child: Text(l10n.extendPlus),
            ),
            TextButton(
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: l10n.revokePlusTitle,
                  message: l10n.revokePlusBody,
                  confirmLabel: l10n.revokePlus,
                  cancelLabel: l10n.cancel,
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                await _run(
                  context,
                  () =>
                      ref.read(planRepositoryProvider).revokeLicense(licenseId),
                  l10n.plusRevoked,
                );
              },
              child: Text(l10n.revokePlus),
            ),
          ],
        ],
      ],
    );
  }
}
