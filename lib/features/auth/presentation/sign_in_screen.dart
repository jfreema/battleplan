import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/auth/presentation/legal_links.dart';
import 'package:battleplan/features/auth/presentation/sign_in_controller.dart';
import 'package:battleplan/features/auth/presentation/sign_in_error_text.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// AUTH-1: Continue with Google, Apple, or email, in that order, with the
/// Terms footer. The same screen on every platform. Apple shows only once
/// it's turned on (Phase 3, roadmap tasks 187 and 109).
class SignInScreen extends ConsumerWidget {
  const new({this.appleEnabled = false, super.key});

  /// Sign in with Apple needs the Apple Developer membership (roadmap task
  /// 109). Until then the button is hidden (task 187).
  final bool appleEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(signInControllerProvider);
    final controller = ref.read(signInControllerProvider.notifier);
    final loading = state.isLoading;
    final error = state.hasError ? signInErrorOf(state.error!) : null;
    listenForDisabledAccount(context, ref);

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
                  if (appleEnabled) ...[
                    AppleSignInButton(
                      label: l10n.continueWithApple,
                      onPressed: loading ? null : controller.signInWithApple,
                    ),
                    const SizedBox(height: Space.md),
                  ],
                  FilledButton.icon(
                    onPressed: loading
                        ? null
                        // Keep where to go back to, such as an invite
                        // link (INV-5 step 2).
                        : () => context.push(
                            Uri(
                              path: '/sign-in/email',
                              queryParameters: _from(context),
                            ).toString(),
                          ),
                    icon: const Icon(AppIcons.email),
                    label: Text(l10n.continueWithEmail),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: Space.lg),
                    SignInErrorText(error: error, onRetry: controller.retry),
                  ],
                  const SizedBox(height: Space.xxl),
                  Text(
                    l10n.signInTermsFooter,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const LegalLinks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Apple button as Apple's design rules ask (AUTH-1): black with white
/// text in light mode, white with black text in dark mode, the Apple logo
/// before the title, and the same size and shape as the other buttons.
class AppleSignInButton extends StatelessWidget {
  const new({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  /// The Apple logo. Brand marks aren't in Material Symbols (AppIcons).
  static const IconData _logo = Icons.apple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? Colors.white : Colors.black;
    final foreground = dark ? Colors.black : Colors.white;
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        // Disabled keeps Apple's colors, faded, rather than turning gray.
        disabledBackgroundColor: background.withValues(alpha: 0.38),
        disabledForegroundColor: foreground.withValues(alpha: 0.9),
      ),
      icon: const Icon(_logo),
      label: Text(label),
    );
  }
}

/// The `from` the router put on `/sign-in`, to carry on to email sign-in.
Map<String, String>? _from(BuildContext context) {
  final from = GoRouterState.of(context).uri.queryParameters['from'];
  return from == null ? null : {'from': from};
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
