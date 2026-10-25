import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// INV-1 at `/g/:groupId/invite`: the team's link, QR code, and code, with
/// Copy, Share, and a full-screen QR to hold up at practice. Admins set an
/// expiry and use limit on the current link, reset it, or turn it off (INV-2,
/// §3); Team settings opens this screen to manage it (TEAM-5). Links lead
/// to email invites (INV-4) and, for admins, adding people by email (TEAM-7).
class InviteScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invite = ref.watch(teamInviteProvider(groupId));
    final isAdmin =
        (ref.watch(myMembershipProvider(groupId))?.isAdmin ?? false) ||
        (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);
    final group = ref.watch(groupProvider(groupId)).value;
    // Right after creating a team there's nothing to go back to, so a clear
    // way into the new team (its chat) sits at the bottom.
    final dead = !context.canPop();
    return Scaffold(
      appBar: gumdropAppBar(context, title: l10n.inviteMenu),
      bottomNavigationBar: dead
          ? SafeArea(
              minimum: const EdgeInsets.all(Space.lg),
              child: FilledButton(
                onPressed: () => context.go('/g/${groupId.value}/chat'),
                child: Text(
                  (group?.name ?? '').isEmpty
                      ? l10n.inviteContinue
                      : l10n.inviteContinueTo(group!.name),
                ),
              ),
            )
          : null,
      body: invite.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => e is InviteUnusable && e.reason == 'link-off'
            ? _LinkOff(groupId: groupId, isAdmin: isAdmin)
            : EmptyState(
                icon: AppIcons.invite,
                message: e is PermissionDenied
                    ? l10n.invitesAdminsOnly
                    : l10n.loadError,
              ),
        data: (inv) => _InviteBody(
          invite: inv,
          groupId: groupId,
          teamName: group?.name ?? '',
          isAdmin: isAdmin,
        ),
      ),
    );
  }
}

class _InviteBody extends ConsumerWidget {
  const new({
    required this.invite,
    required this.groupId,
    required this.teamName,
    required this.isAdmin,
  });

  final TeamInvite invite;
  final GroupId groupId;
  final String teamName;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final link = invite.url.toString();

    Future<void> copy() async {
      await Clipboard.setData(ClipboardData(text: link));
      if (context.mounted) showAppSnackBar(context, l10n.linkCopied);
    }

    Future<void> share() async {
      final shared = await ref
          .read(sharerProvider)
          .shareLink(invite.url, subject: l10n.inviteShareSubject(teamName));
      if (!shared) await copy();
    }

    final c = GumdropColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, Space.xl),
      children: [
        Center(
          // The code stays black on white in every theme, so any camera
          // reads it (INV-1).
          child: Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Corners.panel),
              boxShadow: [BoxShadow(color: c.divider, spreadRadius: 2)],
            ),
            child: QrImageView(
              data: link,
              size: 200,
              semanticsLabel: l10n.qrCodeLabel,
            ),
          ),
        ),
        const SizedBox(height: Space.lg),
        Text(
          l10n.inviteCodeLabel.toUpperCase(),
          semanticsLabel: l10n.inviteCodeLabel,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 12 * 0.07,
            color: c.textMutedOnPage,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          invite.display,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: Space.sm),
        SelectableText(
          link,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: c.textMutedOnPage),
        ),
        const SizedBox(height: Space.xl),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            FilledButton.icon(
              onPressed: () => unawaited(copy()),
              icon: const Icon(AppIcons.check),
              label: Text(l10n.copyLink),
            ),
            OutlinedButton(
              onPressed: () => unawaited(share()),
              child: Text(l10n.share),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) =>
                      _FullScreenQr(invite: invite, teamName: teamName),
                ),
              ),
              child: Text(l10n.showQr),
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        SettingsCard(
          children: [
            SettingsRow(
              icon: AppIcons.email,
              highlighted: true,
              title: l10n.emailInvites,
              subtitle: l10n.emailInvitesSubtitle,
              subtitleLines: 2,
              onTap: () => context.push('/g/${groupId.value}/invite/email'),
            ),
            if (isAdmin)
              SettingsRow(
                icon: AppIcons.invite,
                title: l10n.addByEmail,
                onTap: () => context.push('/g/${groupId.value}/members/add'),
              ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: 18),
          PageHeading(l10n.linkSettings),
          const SizedBox(height: 10),
          Text(
            _linkSummary(context, invite),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: c.textMutedOnPage,
            ),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              OutlinedButton(
                onPressed: () => unawaited(_change(context, ref)),
                child: Text(l10n.linkChangeOptions),
              ),
              OutlinedButton(
                onPressed: () => unawaited(_reset(context, ref)),
                child: Text(l10n.resetLink),
              ),
              TextButton(
                onPressed: () => unawaited(_turnOff(context, ref)),
                child: Text(l10n.linkTurnOff),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _linkSummary(BuildContext context, TeamInvite invite) {
    final l10n = AppLocalizations.of(context);
    final expires = invite.expiresAt == null
        ? l10n.linkNeverExpires
        : l10n.linkExpires(
            MaterialLocalizations.of(context)
                .formatShortDate(invite.expiresAt!.toLocal()),
          );
    final uses = invite.maxUses == null
        ? l10n.linkUses(invite.useCount)
        : l10n.linkUsesOf(invite.useCount, invite.maxUses!);
    return '$expires · $uses';
  }

  /// Sets the expiry and use limit on the link people already have (INV-2).
  Future<void> _change(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final options = await askLinkOptions(
      context,
      title: l10n.linkChangeOptions,
      body: l10n.linkChangeOptionsBody,
      confirm: l10n.save,
      maxUses: invite.maxUses,
    );
    if (options == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(inviteRepositoryProvider)
          .updateTeamInvite(
            groupId,
            expiry: options.expiry,
            maxUses: options.maxUses,
          );
      ref.invalidate(teamInviteProvider(groupId));
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
    } on AppFailure {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorResetLink)));
    }
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final options = await askLinkOptions(
      context,
      title: l10n.resetLink,
      body: l10n.resetLinkBody,
      confirm: l10n.resetLink,
    );
    if (options == null || !context.mounted) return;
    await resetTeamLink(context, ref, groupId, options);
  }

  /// Turns the link off with no new one (§3 "revoke").
  Future<void> _turnOff(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.linkTurnOff,
      message: l10n.linkTurnOffBody,
      confirmLabel: l10n.linkTurnOff,
      cancelLabel: l10n.cancel,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(inviteRepositoryProvider).revokeTeamInvite(groupId);
      ref.invalidate(teamInviteProvider(groupId));
      messenger.showSnackBar(SnackBar(content: Text(l10n.linkTurnedOff)));
    } on AppFailure {
      messenger.showSnackBar(SnackBar(content: Text(l10n.signInUnknownError)));
    }
  }
}

/// Replaces the team's link with a new one with [options] (INV-2), which
/// also turns a link that was turned off back on.
Future<void> resetTeamLink(
  BuildContext context,
  WidgetRef ref,
  GroupId groupId,
  ({InviteExpiry expiry, int? maxUses}) options,
) async {
  final l10n = AppLocalizations.of(context);
  // The screen reloads after the reset, so keep the messenger now.
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref
        .read(inviteRepositoryProvider)
        .resetTeamInvite(
          groupId,
          expiry: options.expiry,
          maxUses: options.maxUses,
        );
    ref.invalidate(teamInviteProvider(groupId));
    messenger.showSnackBar(SnackBar(content: Text(l10n.linkReset)));
  } on AppFailure {
    messenger.showSnackBar(SnackBar(content: Text(l10n.signInUnknownError)));
  }
}

/// Asks for a link's expiry and use limit (INV-2). Null when cancelled.
Future<({InviteExpiry expiry, int? maxUses})?> askLinkOptions(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  int? maxUses,
}) async {
  final l10n = AppLocalizations.of(context);
  var expiry = InviteExpiry.never;
  final usesController = TextEditingController(text: maxUses?.toString());
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            const SizedBox(height: Space.lg),
            DropdownButtonFormField<InviteExpiry>(
              initialValue: expiry,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.linkExpiryLabel),
              items: [
                for (final e in InviteExpiry.values)
                  DropdownMenuItem(
                    value: e,
                    child: Text(switch (e) {
                      InviteExpiry.never => l10n.expiryNever,
                      InviteExpiry.oneDay => l10n.expiry1d,
                      InviteExpiry.sevenDays => l10n.expiry7d,
                      InviteExpiry.thirtyDays => l10n.expiry30d,
                    }),
                  ),
              ],
              onChanged: (e) => setState(() => expiry = e ?? expiry),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: usesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.linkMaxUsesLabel),
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
            child: Text(confirm),
          ),
        ],
      ),
    ),
  );
  // Not disposed here: the dialog still uses it while it animates away.
  final uses = int.tryParse(usesController.text.trim());
  if (ok != true) return null;
  return (expiry: expiry, maxUses: uses != null && uses > 0 ? uses : null);
}

/// The team's link is turned off (§3): admins can turn a new one on.
class _LinkOff extends ConsumerWidget {
  const new({required this.groupId, required this.isAdmin});

  final GroupId groupId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, Space.xl),
      children: [
        EmptyState(icon: AppIcons.invite, message: l10n.linkIsOff),
        if (isAdmin)
          Center(
            child: FilledButton(
              onPressed: () async {
                final options = await askLinkOptions(
                  context,
                  title: l10n.linkTurnOn,
                  body: l10n.linkTurnOnBody,
                  confirm: l10n.linkTurnOn,
                );
                if (options == null || !context.mounted) return;
                await resetTeamLink(context, ref, groupId, options);
              },
              child: Text(l10n.linkTurnOn),
            ),
          ),
        const SizedBox(height: Space.xl),
        SettingsCard(
          children: [
            SettingsRow(
              icon: AppIcons.email,
              highlighted: true,
              title: l10n.emailInvites,
              subtitle: l10n.emailInvitesSubtitle,
              subtitleLines: 2,
              onTap: () => context.push('/g/${groupId.value}/invite/email'),
            ),
          ],
        ),
      ],
    );
  }
}

/// The QR code filling the screen, to hold up at practice (INV-1).
class _FullScreenQr extends StatelessWidget {
  const new({required this.invite, required this.teamName});

  final TeamInvite invite;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context).shortestSide * 0.8;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(teamName),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: invite.url.toString(),
              size: size,
              semanticsLabel: l10n.qrCodeLabel,
            ),
            const SizedBox(height: Space.lg),
            Text(
              invite.display,
              style: const TextStyle(
                color: Colors.black,
                fontSize: TypeScale.headline,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
