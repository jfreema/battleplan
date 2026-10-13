import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/auth/presentation/sign_in_controller.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The message for a sign-in failure, shared by the sign-in screens. Each
/// says what happened and what to do next (SPEC §7.7).
String signInErrorMessage(AppLocalizations l10n, SignInError error) =>
    switch (error) {
      SignInError.badCredentials => l10n.signInFailed,
      SignInError.offline => l10n.signInOffline,
      SignInError.rateLimited => l10n.signInRateLimited,
      SignInError.disabled => l10n.signInDisabled,
      SignInError.popupBlocked => l10n.signInPopupBlocked,
      SignInError.otherMethod => l10n.signInOtherMethod,
      SignInError.emailInUse => l10n.signInEmailInUse,
      SignInError.weakPassword => l10n.passwordTooShort,
      SignInError.unknown => l10n.signInUnknownError,
    };

/// The error line under a sign-in form, or nothing. Offline errors offer
/// Retry ([onRetry]); errors an admin-added person may hit point them to
/// their setup email (AUTH edge cases).
class SignInErrorText extends StatelessWidget {
  const new({required this.error, this.onRetry, super.key});

  final SignInError? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final e = error;
    if (e == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            signInErrorMessage(l10n, e),
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
          // A person an admin added has an account but no password yet;
          // their setup email signs them in (AUTH-6). Shown to everyone
          // who hits these, so it never reveals whose account it is.
          if (e == SignInError.badCredentials ||
              e == SignInError.emailInUse) ...[
            const SizedBox(height: Space.sm),
            Text(
              l10n.signInAddedByAdminHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (e == SignInError.offline && onRetry != null)
            Center(
              child: TextButton(onPressed: onRetry, child: Text(l10n.retry)),
            ),
        ],
      ),
    );
  }
}

/// AUTH-11: a disabled account's sign-in shows only the disabled screen,
/// with the support address. Call from a sign-in screen's build.
void listenForDisabledAccount(BuildContext context, WidgetRef ref) {
  ref.listen(signInControllerProvider, (_, next) {
    if (next.hasError && signInErrorOf(next.error!) == SignInError.disabled) {
      context.go('/disabled');
    }
  });
}
