import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Pulls email addresses out of pasted text: one per line, or separated by
/// commas, semicolons, or spaces. Lowercased and de-duplicated, in order.
List<String> emailsFrom(String text) {
  final email = RegExp(r'^[^@\s<>]+@[^@\s<>]+\.[^@\s<>]+$');
  final seen = <String>{};
  return [
    for (final raw in text.split(RegExp(r'[\s,;<>]+')))
      if (email.hasMatch(raw.trim()) && seen.add(raw.trim().toLowerCase()))
        raw.trim().toLowerCase(),
  ];
}

/// INV-4 at `/g/:groupId/invite/email`: send single-use invites to up to 50
/// addresses at a time (each link expires in 14 days), then see who is
/// pending, joined, or expired, with Resend and Revoke.
class EmailInvitesScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<EmailInvitesScreen> createState() => _EmailInvitesScreenState();
}

class _EmailInvitesScreenState extends ConsumerState<EmailInvitesScreen> {
  static const _max = 50;
  final _emails = TextEditingController();
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emails.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Runs [action], then refreshes the list or shows what went wrong.
  Future<void> _run(Future<String?> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final done = await action();
      ref.invalidate(emailInvitesProvider(widget.groupId));
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on AppFailure catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (e) {
            EmailNotVerified() => l10n.emailInvitesNeedVerified,
            RateLimited() => l10n.emailInvitesRateLimited,
            PermissionDenied() => l10n.invitesAdminsOnly,
            _ => l10n.signInUnknownError,
          }),
        ),
      );
    }
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    await _run(() async {
      final n = await ref
          .read(inviteRepositoryProvider)
          .sendEmailInvites(
            widget.groupId,
            emailsFrom(_emails.text),
            note: _note.text.trim(),
          );
      _emails.clear();
      _note.clear();
      return l10n.emailInvitesSent(n);
    });
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final emails = emailsFrom(_emails.text);
    final invites = ref.watch(emailInvitesProvider(widget.groupId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.emailInvites)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(Space.xl),
            children: [
              Text(l10n.emailInvitesHelp),
              const SizedBox(height: Space.md),
              TextField(
                controller: _emails,
                minLines: 3,
                maxLines: 10,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.emailAddresses,
                  hintText: 'sam@example.com, alex@example.com',
                  helperText: emails.length > _max
                      ? l10n.emailInvitesTooMany(_max)
                      : null,
                ),
              ),
              const SizedBox(height: Space.md),
              TextField(
                controller: _note,
                maxLength: 300,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(labelText: l10n.inviteNote),
              ),
              const SizedBox(height: Space.sm),
              FilledButton(
                onPressed: _sending || emails.isEmpty || emails.length > _max
                    ? null
                    : () => unawaited(_send()),
                child: Text(l10n.sendInvitesCount(emails.length)),
              ),
              const Divider(height: Space.xxl),
              Text(
                l10n.sentInvites,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...switch (invites) {
                AsyncData(:final value) when value.isEmpty => [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.md),
                    child: Text(l10n.noEmailInvites),
                  ),
                ],
                AsyncData(:final value) => [
                  for (final invite in value) _row(context, invite),
                ],
                AsyncError() => [Text(l10n.signInUnknownError)],
                _ => [const LinearProgressIndicator()],
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, EmailInvite invite) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(inviteRepositoryProvider);
    final canResend =
        invite.status == EmailInviteStatus.pending ||
        invite.status == EmailInviteStatus.expired ||
        invite.status == EmailInviteStatus.revoked;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(invite.email),
      subtitle: Text(switch (invite.status) {
        EmailInviteStatus.pending => l10n.invitePending,
        EmailInviteStatus.joined => l10n.inviteJoined,
        EmailInviteStatus.expired => l10n.emailInviteExpired,
        EmailInviteStatus.revoked => l10n.emailInviteRevoked,
      }),
      trailing: Wrap(
        children: [
          if (canResend)
            TextButton(
              onPressed: () => unawaited(
                _run(() async {
                  await repo.resendEmailInvite(invite.code);
                  return l10n.inviteResent;
                }),
              ),
              child: Text(l10n.resend),
            ),
          if (invite.status == EmailInviteStatus.pending)
            TextButton(
              onPressed: () => unawaited(
                _run(() async {
                  await repo.revokeInvite(invite.code);
                  return null;
                }),
              ),
              child: Text(l10n.revoke),
            ),
        ],
      ),
    );
  }
}
