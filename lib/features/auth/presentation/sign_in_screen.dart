import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/auth/presentation/sign_in_controller.dart';
import 'package:battleplan/features/auth/presentation/sign_in_error_text.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// AUTH-1: Continue with Google, Apple, or email, in that order, with the
/// Terms footer. The same screen on every platform.
class SignInScreen extends ConsumerWidget {
  const new({this.appleEnabled = false, super.key});

  /// Sign in with Apple needs the Apple Developer membership (roadmap task
  /// 109). Until then the button shows but is disabled.
  final bool appleEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(signInControllerProvider);
    final controller = ref.read(signInControllerProvider.notifier);
    final loading = state.isLoading;
    final error = state.hasError ? signInErrorOf(state.error!) : null;

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
                  const AppLogo(),
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
                    onPressed: loading ? null : controller.signInWithGoogle,
                    child: Text(l10n.continueWithGoogle),
                  ),
                  const SizedBox(height: Space.md),
                  Tooltip(
                    message: appleEnabled ? '' : l10n.comingSoon,
                    child: OutlinedButton(
                      onPressed: appleEnabled && !loading
                          ? controller.signInWithApple
                          : null,
                      child: Text(l10n.continueWithApple),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  FilledButton.icon(
                    onPressed: loading
                        ? null
                        : () => context.push('/sign-in/email'),
                    icon: const Icon(AppIcons.email),
                    label: Text(l10n.continueWithEmail),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: Space.lg),
                    SignInErrorText(error: error),
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
    );
  }
}

/// Placeholder mark until the logo is designed (SPEC Q9).
class AppLogo extends StatelessWidget {
  const new({super.key});

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
