import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Leaves [group] after asking (TEAM-8), then goes home. The owner is told
/// to transfer ownership first. It's on the person's own card in the
/// roster, not the team menu, so it isn't tapped by accident.
Future<void> leaveTeam(BuildContext context, WidgetRef ref, Group group) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showConfirmDialog(
    context,
    title: l10n.leaveTeamTitle(group.name),
    message: l10n.leaveTeamBody,
    confirmLabel: l10n.leaveTeamMenu,
    cancelLabel: l10n.cancel,
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  try {
    await ref.read(groupRepositoryProvider).leave(group.id);
    if (context.mounted) context.go('/');
  } on OwnerMustTransfer {
    if (context.mounted) showAppSnackBar(context, l10n.ownerMustTransfer);
  } on AppFailure {
    if (context.mounted) showAppSnackBar(context, l10n.errorLeaveTeam);
  }
}
