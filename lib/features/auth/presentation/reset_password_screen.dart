import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// AUTH-4 at `/reset-password`: enter an email and get a reset link. The
/// confirmation never says whether an account exists for that email.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const new({this.initialEmail, super.key});

  final String? initialEmail;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
      setState(() => _error = l10n.emailInvalid);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) setState(() => _sent = true);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e) {
            Offline() => l10n.signInOffline,
            RateLimited() => l10n.signInRateLimited,
            InvalidInput() => l10n.emailInvalid,
            _ => l10n.signInUnknownError,
          },
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_sent)
                    Text(
                      l10n.resetPasswordSent,
                      key: const Key('resetSent'),
                      style: theme.textTheme.bodyLarge,
                    )
                  else ...[
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autofocus: true,
                      onSubmitted: (_) => unawaited(_send()),
                      decoration: InputDecoration(labelText: l10n.emailLabel),
                    ),
                    const SizedBox(height: Space.lg),
                    if (error != null) ...[
                      Text(
                        error,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: Space.md),
                    ],
                    FilledButton(
                      onPressed: _sending ? null : () => unawaited(_send()),
                      child: Text(l10n.sendResetLink),
                    ),
                  ],
                  const SizedBox(height: Space.xl),
                  Text(
                    l10n.resetPasswordProviderNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
