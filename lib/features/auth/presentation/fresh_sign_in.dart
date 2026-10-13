import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Runs [action]; if it needs a fresh sign-in (AUTH-7), asks for one and
/// runs it once more. Returns false if the person cancelled the sign-in,
/// or it goes on by an emailed link they open first ([_reauthenticate]).
Future<bool> withFreshSignIn(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } on RequiresRecentLogin {
    if (!context.mounted) return false;
    if (!await _reauthenticate(context, ref)) return false;
    await action();
    return true;
  }
}

/// A fresh sign-in with a method the account really has: Google or Apple
/// when linked, since they always work; else the password when there is
/// one. A `password` method can also be just an emailed sign-in link with
/// no password behind it (an added account, AUTH-6), so the password is
/// asked for only when this session signed in with it or it was set on
/// this device. Otherwise a sign-in link is emailed: opening it is the
/// fresh sign-in, and the person tries again (returns false).
Future<bool> _reauthenticate(BuildContext context, WidgetRef ref) async {
  final user = ref.read(authUserProvider).value;
  if (user == null) return false;
  final l10n = AppLocalizations.of(context);
  final auth = ref.read(authRepositoryProvider);
  final ids = user.providerIds;
  final oauth = ids.contains('google.com')
      ? 'google.com'
      : ids.contains('apple.com')
      ? 'apple.com'
      : null;
  if (oauth != null) {
    await auth.reauthenticateWithProvider(oauth);
    return true;
  }
  final prefs = ref.read(localPrefsRepositoryProvider);
  final hasPassword =
      ids.contains('password') &&
      (user.signInProvider == 'password' || prefs.passwordSet(user.uid));
  if (hasPassword) {
    final password = await askText(
      context,
      title: l10n.reauthTitle,
      label: l10n.passwordLabel,
      obscure: true,
    );
    if (password == null) return false;
    await auth.reauthenticateWithPassword(password);
    return true;
  }
  final email = user.email;
  if (email == null) return false;
  await auth.sendSignInLink(email);
  await prefs.setPendingSignInEmail(email);
  if (context.mounted) showAppSnackBar(context, l10n.reauthLinkSent(email));
  return false;
}

/// Remembers that the signed-in account now has a password, set on this
/// device, so a fresh sign-in may ask for it (AUTH-7).
Future<void> markPasswordSet(WidgetRef ref, {bool value = true}) async {
  final uid = ref.read(authUserProvider).value?.uid;
  if (uid == null) return;
  await ref
      .read(localPrefsRepositoryProvider)
      .setPasswordSet(uid, value: value);
}

/// A small dialog asking for one line of text, or null if cancelled.
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String label,
  bool obscure = false,
  String? helper,
}) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label, helperText: helper),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(l10n.activateContinue),
        ),
      ],
    ),
  );
}
