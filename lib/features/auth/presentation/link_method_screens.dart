import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
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
/// in from now on: Google, the main way in (AUTH-1), Apple, or a password
/// they create for people without either, which they'll sign in with at
/// `/emaillogin`, as the dialog says. The router sends them here until
/// they've chosen, or they sign out.
///
/// Their only sign-in was the setup link, perhaps long ago, and they have no
/// password to confirm it's them with, so these skip the app's own recent
/// sign-in check (AUTH-7). Firebase still asks where it must, and the fresh
/// sign-in then goes by an emailed link.
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
    final where = ref.read(linkServiceProvider).emailLoginText;
    final password = await askText(
      context,
      title: l10n.createPassword,
      label: l10n.newPasswordLabel,
      helper: '${l10n.passwordRule} ${l10n.passwordSignInAt(where)}',
      obscure: true,
    );
    if (password == null || !mounted) return;
    if (password.length < minPasswordLength) {
      showAppSnackBar(context, l10n.passwordTooShort);
      return;
    }
    await _choose(() async {
      await ref
          .read(authRepositoryProvider)
          .setPassword(password, checkRecent: false);
      await markPasswordSet(ref);
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
                  GoogleSignInButton(
                    label: l10n.continueWithGoogle,
                    onPressed: _busy
                        ? null
                        : () => unawaited(
                            _choose(() => auth.linkGoogle(checkRecent: false)),
                          ),
                  ),
                  const SizedBox(height: Space.md),
                  // Where Sign in with Apple is on (task 109).
                  if (widget.appleEnabled) ...[
                    AppleSignInButton(
                      label: l10n.continueWithApple,
                      onPressed: _busy
                          ? null
                          : () => unawaited(
                              _choose(() => auth.linkApple(checkRecent: false)),
                            ),
                    ),
                    const SizedBox(height: Space.md),
                  ],
                  // For people without Google (or Apple): the sign-in
                  // screen doesn't offer passwords, so it's the quiet one.
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => unawaited(_createPassword()),
                    child: Text(l10n.usePasswordInstead),
                  ),
                  // The router keeps them here until they choose, so this
                  // is the way out.
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => unawaited(
                            ref.read(sessionServiceProvider).signOut(),
                          ),
                    child: Text(l10n.signOut),
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
/// the method they tried, Google or Apple, by completing its own sign-in,
/// or skip it.
class FinishLinkScreen extends ConsumerStatefulWidget {
  const new({this.appleEnabled = false, super.key});

  /// Whether Apple can be linked here (task 109); otherwise it's Google.
  final bool appleEnabled;

  @override
  ConsumerState<FinishLinkScreen> createState() => _FinishLinkScreenState();
}

class _FinishLinkScreenState extends ConsumerState<FinishLinkScreen> {
  bool _busy = false;

  Future<void> _done() async {
    await ref.read(localPrefsRepositoryProvider).setPendingLink(null);
    if (mounted) context.go('/');
  }

  /// The method tried: Apple when that's what the email link was for.
  bool get _apple =>
      widget.appleEnabled &&
      ref.read(localPrefsRepositoryProvider).pendingLink?.providerId ==
          'apple.com';

  Future<void> _link() async {
    final l10n = AppLocalizations.of(context);
    final apple = _apple;
    setState(() => _busy = true);
    try {
      var linked = false;
      final auth = ref.read(authRepositoryProvider);
      final ran = await withFreshSignIn(
        context,
        ref,
        () async =>
            linked = await (apple ? auth.linkApple() : auth.linkGoogle()),
      );
      if (!ran || !linked || !mounted) return;
      showAppSnackBar(
        context,
        l10n.methodLinkedDone(apple ? 'Apple' : 'Google'),
      );
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
    final apple = _apple;
    final name = apple ? 'Apple' : 'Google';
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
                    l10n.finishLinkTitle(name),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Space.sm),
                  Text(l10n.finishLinkBody(name), textAlign: TextAlign.center),
                  const SizedBox(height: Space.xxl),
                  if (apple)
                    AppleSignInButton(
                      label: l10n.continueWithApple,
                      onPressed: _busy ? null : () => unawaited(_link()),
                    )
                  else
                    GoogleSignInButton(
                      label: l10n.continueWithGoogle,
                      onPressed: _busy ? null : () => unawaited(_link()),
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
