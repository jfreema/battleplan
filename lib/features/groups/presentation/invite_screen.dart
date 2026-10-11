import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// INV-1 at `/g/:groupId/invite`: the team's link, QR code, and code, with
/// Copy, Share, and a full-screen QR to hold up at practice. Admins can set
/// an expiry and use limit and reset the link (INV-2). Email invites and
/// add-by-email arrive with email sending.
class InviteScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invite = ref.watch(teamInviteProvider(groupId));
    final isAdmin = ref.watch(myMembershipProvider(groupId))?.isAdmin ?? false;
    final group = ref.watch(groupProvider(groupId)).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteMenu)),
      body: invite.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
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

    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Corners.card),
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
          l10n.inviteCodeLabel,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall,
        ),
        SelectableText(
          invite.display,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: Space.sm),
        SelectableText(link, textAlign: TextAlign.center),
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
        ListTile(
          leading: const Icon(AppIcons.email),
          title: Text(l10n.emailInvites),
          subtitle: Text(l10n.comingSoon),
          enabled: false,
        ),
        if (isAdmin) ...[
          ListTile(
            leading: const Icon(AppIcons.invite),
            title: Text(l10n.addByEmail),
            subtitle: Text(l10n.comingSoon),
            enabled: false,
          ),
          const Divider(height: Space.xxl),
          Text(l10n.linkSettings, style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.sm),
          Text(_linkSummary(context, invite)),
          const SizedBox(height: Space.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () => unawaited(_reset(context, ref)),
              child: Text(l10n.resetLink),
            ),
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

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    var expiry = InviteExpiry.never;
    final usesController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.resetLink),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.resetLinkBody),
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
              child: Text(l10n.resetLink),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    // The screen reloads after the reset, so keep the messenger now.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(inviteRepositoryProvider)
          .resetTeamInvite(
            groupId,
            expiry: expiry,
            maxUses: int.tryParse(usesController.text.trim()),
          );
      ref.invalidate(teamInviteProvider(groupId));
      messenger.showSnackBar(SnackBar(content: Text(l10n.linkReset)));
    } on AppFailure {
      messenger.showSnackBar(SnackBar(content: Text(l10n.signInUnknownError)));
    }
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
