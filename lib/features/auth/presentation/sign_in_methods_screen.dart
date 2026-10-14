import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/auth/presentation/email_sign_in_screen.dart';
import 'package:battleplan/features/auth/presentation/fresh_sign_in.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings → Sign-in methods (AUTH-8, SET-4): link or remove Google, set or
/// change a password, and change the account email. Actions that need a
/// fresh sign-in ask for one first, then carry on (AUTH-7).
class SignInMethodsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SignInMethodsScreen> createState() =>
      _SignInMethodsScreenState();
}

class _SignInMethodsScreenState extends ConsumerState<SignInMethodsScreen> {
  bool _busy = false;

  /// Runs [action], asking for a fresh sign-in first if needed. Shows
  /// [done] on success and a plain message on failure.
  Future<void> _run(Future<void> Function() action, {String? done}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final ran = await withFreshSignIn(context, ref, action);
      if (ran && mounted && done != null) showAppSnackBar(context, done);
    } on AppFailure catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, switch (e) {
        CredentialInUse() => l10n.methodInUse,
        WeakPassword() => l10n.passwordTooShort,
        InvalidInput() => l10n.methodInvalid,
        Offline() => l10n.signInOffline,
        RateLimited() => l10n.signInRateLimited,
        _ => l10n.signInUnknownError,
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeMethod(
    AuthUser user,
    String providerId,
    String name,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.removeMethodTitle(name),
      message: l10n.removeMethodBody(name),
      confirmLabel: l10n.removeMethod,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(() async {
      await ref.read(authRepositoryProvider).unlink(providerId);
      if (providerId == 'password') await markPasswordSet(ref, value: false);
    }, done: l10n.methodRemoved(name));
  }

  Future<void> _setPassword(bool hasPassword) async {
    final l10n = AppLocalizations.of(context);
    final password = await askText(
      context,
      title: hasPassword ? l10n.changePassword : l10n.setPassword,
      label: l10n.newPasswordLabel,
      helper: l10n.passwordRule,
      obscure: true,
    );
    if (password == null || !mounted) return;
    if (password.length < minPasswordLength) {
      showAppSnackBar(context, l10n.passwordTooShort);
      return;
    }
    await _run(() async {
      await ref.read(authRepositoryProvider).setPassword(password);
      await markPasswordSet(ref);
    }, done: l10n.passwordSaved);
  }

  Future<void> _changeEmail() async {
    final l10n = AppLocalizations.of(context);
    final email = await askText(
      context,
      title: l10n.changeEmail,
      label: l10n.newEmailLabel,
    );
    if (email == null || !mounted) return;
    final address = email.trim();
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(address)) {
      showAppSnackBar(context, l10n.emailInvalid);
      return;
    }
    await _run(
      () => ref.read(authRepositoryProvider).changeEmail(address),
      done: l10n.changeEmailSent(address),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authUserProvider).value;
    if (user == null) return const Scaffold();
    final ids = user.providerIds;
    final onlyOne = ids.length <= 1;
    final hasGoogle = ids.contains('google.com');
    final hasPassword = ids.contains('password');

    Widget removeButton(String providerId, String name) => TextButton(
      onPressed: _busy || onlyOne
          ? null
          : () => _removeMethod(user, providerId, name),
      child: Text(l10n.removeMethod),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInMethods)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        children: [
          ListTile(
            title: const Text('Google'),
            subtitle: Text(
              hasGoogle ? l10n.methodLinked : l10n.methodNotLinked,
            ),
            trailing: hasGoogle
                ? removeButton('google.com', 'Google')
                : TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => ref.read(authRepositoryProvider).linkGoogle(),
                            done: l10n.methodLinkedDone('Google'),
                          ),
                    child: Text(l10n.linkMethod),
                  ),
          ),
          // Apple shows only on an account that already has it, until
          // Sign in with Apple is turned on (task 187).
          if (ids.contains('apple.com'))
            ListTile(
              title: const Text('Apple'),
              subtitle: Text(l10n.methodLinked),
            ),
          ListTile(
            title: Text(l10n.passwordLabel),
            subtitle: Text(
              hasPassword ? l10n.methodLinked : l10n.methodNotLinked,
            ),
            trailing: Wrap(
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _setPassword(hasPassword),
                  child: Text(
                    hasPassword ? l10n.changePassword : l10n.setPassword,
                  ),
                ),
                if (hasPassword) removeButton('password', l10n.passwordLabel),
              ],
            ),
          ),
          if (onlyOne)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: Text(
                l10n.lastMethodNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const Divider(height: Space.xxl),
          ListTile(
            title: Text(l10n.emailLabel),
            subtitle: Text(user.email ?? ''),
            trailing: TextButton(
              onPressed: _busy ? null : _changeEmail,
              child: Text(l10n.changeEmail),
            ),
          ),
        ],
      ),
    );
  }
}
