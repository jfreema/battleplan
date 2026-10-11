import 'package:battleplan/features/auth/presentation/sign_in_controller.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
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

/// The error line under a sign-in form, or nothing.
class SignInErrorText extends StatelessWidget {
  const new({required this.error, super.key});

  final SignInError? error;

  @override
  Widget build(BuildContext context) {
    final e = error;
    if (e == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Text(
        signInErrorMessage(AppLocalizations.of(context), e),
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
