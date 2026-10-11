import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Runs [action]; if it needs a fresh sign-in (AUTH-7), asks for one (the
/// password if the account has one, otherwise Google or Apple) and runs it
/// once more. Returns false if the person cancelled the sign-in.
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

Future<bool> _reauthenticate(BuildContext context, WidgetRef ref) async {
  final user = ref.read(authUserProvider).value;
  if (user == null) return false;
  final auth = ref.read(authRepositoryProvider);
  if (user.providerIds.contains('password')) {
    final password = await askText(
      context,
      title: AppLocalizations.of(context).reauthTitle,
      label: AppLocalizations.of(context).passwordLabel,
      obscure: true,
    );
    if (password == null) return false;
    await auth.reauthenticateWithPassword(password);
  } else {
    final provider = user.providerIds.contains('google.com')
        ? 'google.com'
        : user.providerIds.first;
    await auth.reauthenticateWithProvider(provider);
  }
  return true;
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
