import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/auth/presentation/sign_in_controller.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// AUTH-1. Google and email work now; Apple arrives in M1. Facebook is
/// deferred until after M8 (SPEC Q16), so it isn't shown.
class SignInScreen extends ConsumerStatefulWidget {
  const new({this.showEmulatorHint = false, super.key});

  final bool showEmulatorHint;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showEmail = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => ref
      .read(signInControllerProvider.notifier)
      .signInWithEmail(_email.text, _password.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(signInControllerProvider);
    final loading = state.isLoading;
    final error = state.hasError ? signInErrorOf(state.error!) : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Logo(),
                    const SizedBox(height: Space.lg),
                    Text(
                      l10n.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      l10n.tagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Space.xxl),
                    OutlinedButton(
                      onPressed: loading
                          ? null
                          : () => ref
                                .read(signInControllerProvider.notifier)
                                .signInWithGoogle(),
                      child: Text(l10n.continueWithGoogle),
                    ),
                    const SizedBox(height: Space.md),
                    // Apple arrives in M1 (roadmap task 29, verified in 109).
                    // Facebook is deferred until after M8 (SPEC Q16).
                    Tooltip(
                      message: l10n.comingSoon,
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text(l10n.continueWithApple),
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    if (!_showEmail)
                      FilledButton.icon(
                        onPressed: () => setState(() => _showEmail = true),
                        icon: const Icon(AppIcons.email),
                        label: Text(l10n.continueWithEmail),
                      )
                    else ...[
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        autofocus: true,
                        decoration: InputDecoration(labelText: l10n.emailLabel),
                      ),
                      const SizedBox(height: Space.md),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.passwordLabel,
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? l10n.showPassword
                                : l10n.hidePassword,
                            icon: Icon(
                              _obscure
                                  ? AppIcons.visibility
                                  : AppIcons.visibilityOff,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.lg),
                      FilledButton(
                        onPressed: loading ? null : _submit,
                        child: Text(l10n.signIn),
                      ),
                      if (widget.showEmulatorHint) ...[
                        const SizedBox(height: Space.md),
                        Text(
                          l10n.emulatorHint,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                    if (error != null) ...[
                      const SizedBox(height: Space.lg),
                      Text(
                        switch (error) {
                          SignInError.badCredentials => l10n.signInFailed,
                          SignInError.offline => l10n.signInOffline,
                          SignInError.rateLimited => l10n.signInRateLimited,
                          SignInError.disabled => l10n.signInDisabled,
                          SignInError.popupBlocked => l10n.signInPopupBlocked,
                          SignInError.otherMethod => l10n.signInOtherMethod,
                          SignInError.unknown => l10n.signInUnknownError,
                        },
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: Space.xxl),
                    Text(
                      l10n.signInTermsFooter,
                      textAlign: TextAlign.center,
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
      ),
    );
  }
}

/// Placeholder mark until the logo is designed (SPEC Q9).
class _Logo extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppTokens.brand,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(AppIcons.group, color: Colors.white, size: 40),
    ),
  );
}
