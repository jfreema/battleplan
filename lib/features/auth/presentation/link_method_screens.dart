import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/presentation/email_sign_in_screen.dart';
import 'package:battleplan/features/auth/presentation/fresh_sign_in.dart';
import 'package:battleplan/features/auth/presentation/sign_in_screen.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The message for a failed link or password change on these screens.
String _failureText(AppLocalizations l10n, AppFailure e) => switch (e) {
  CredentialInUse() => l10n.methodInUse,
  WeakPassword() => l10n.passwordTooShort,
  Offline() => l10n.signInOffline,
  RateLimited() => l10n.signInRateLimited,
  _ => l10n.signInUnknownError,
};

/// AUTH-6 at `/choose-sign-in`: someone an admin added signed in with the
/// link in their setup email. Before anything else, they choose how to sign
/// in from now on: Google, Apple, or a password they create. The router
/// sends them here until they've chosen.
class ChooseSignInScreen extends ConsumerStatefulWidget {
  const new({this.appleEnabled = false, super.key});

  /// Sign in with Apple needs the Apple Developer membership (roadmap task
  /// 109).
  final bool appleEnabled;

  @override
  ConsumerState<ChooseSignInScreen> createState() => _ChooseSignInScreenState();
}

class _ChooseSignInScreenState extends ConsumerState<ChooseSignInScreen> {
  bool _busy = false;

  /// Runs [change], then, if it went through (not cancelled), records the
  /// choice so the router moves on.
  Future<void> _choose(Future<bool> Function() change) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      var changed = false;
      final ran = await withFreshSignIn(
        context,
        ref,
        () async => changed = await change(),
      );
      if (!ran || !changed) return;
      await ref.read(userRepositoryProvider).ensureProfile(signInChosen: true);
    } on AppFailure catch (e) {
      if (mounted) showAppSnackBar(context, _failureText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPassword() async {
    final l10n = AppLocalizations.of(context);
    final password = await askText(
      context,
      title: l10n.createPassword,
      label: l10n.newPasswordLabel,
      helper: l10n.passwordRule,
      obscure: true,
    );
    if (password == null || !mounted) return;
    if (password.length < minPasswordLength) {
      showAppSnackBar(context, l10n.passwordTooShort);
      return;
    }
    await _choose(() async {
      await ref.read(authRepositoryProvider).setPassword(password);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.read(authRepositoryProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.chooseSignInTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    l10n.chooseSignInBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Space.xxl),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => unawaited(_choose(auth.linkGoogle)),
                    child: Text(l10n.continueWithGoogle),
                  ),
                  const SizedBox(height: Space.md),
                  Tooltip(
                    message: widget.appleEnabled ? '' : l10n.comingSoon,
                    child: AppleSignInButton(label: l10n.continueWithApple),
                  ),
                  const SizedBox(height: Space.md),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => unawaited(_createPassword()),
                    child: Text(l10n.createPassword),
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

/// AUTH-7 at `/finish-link`: someone tried Google with an email that
/// already has an account, so the app emailed a link instead of merging.
/// The link proved the email and signed them in; now they finish adding
/// Google by completing Google's own sign-in, or skip it.
class FinishLinkScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<FinishLinkScreen> createState() => _FinishLinkScreenState();
}

class _FinishLinkScreenState extends ConsumerState<FinishLinkScreen> {
  bool _busy = false;

  Future<void> _done() async {
    await ref.read(localPrefsRepositoryProvider).setPendingLink(null);
    if (mounted) context.go('/');
  }

  Future<void> _link() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      var linked = false;
      final ran = await withFreshSignIn(
        context,
        ref,
        () async =>
            linked = await ref.read(authRepositoryProvider).linkGoogle(),
      );
      if (!ran || !linked || !mounted) return;
      showAppSnackBar(context, l10n.methodLinkedDone('Google'));
      await _done();
    } on AppFailure catch (e) {
      if (mounted) showAppSnackBar(context, _failureText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.finishLinkTitle('Google'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    l10n.finishLinkBody('Google'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.xxl),
                  FilledButton(
                    onPressed: _busy ? null : () => unawaited(_link()),
                    child: Text(l10n.continueWithGoogle),
                  ),
                  const SizedBox(height: Space.sm),
                  TextButton(
                    onPressed: _busy ? null : () => unawaited(_done()),
                    child: Text(l10n.notNow),
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
