import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/brand_mark.dart';
import 'package:battleplan/features/auth/presentation/legal_links.dart';
import 'package:battleplan/features/auth/presentation/sign_in_controller.dart';
import 'package:battleplan/features/auth/presentation/sign_in_error_text.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// AUTH-1: Continue with Google, then Apple, with the Terms footer. The
/// same screen on every platform. Apple shows where it's turned on
/// (`AppEnv.appleSignIn`, roadmap task 109). Email sign-in isn't offered
/// here: it's at `/emaillogin`, which nothing links to, for the people who
/// need it (AUTH-2). At `/sign-up` ([signUp], the website's "Sign up, it's
/// free!") it says "Create your free account". Each links to the other.
class SignInScreen extends ConsumerWidget {
  const new({
    this.appleEnabled = false,
    this.signUp = false,
    this.emailButton = false,
    super.key,
  });

  /// Whether Sign in with Apple is on (`AppEnv.appleSignIn`, roadmap task
  /// 109): in dev and on the emulators, and in prod once prod's Firebase
  /// project has Apple's Services ID and key.
  final bool appleEnabled;

  /// The sign-up page. Google and Apple make an account the first time
  /// either way, so only the words differ.
  final bool signUp;

  /// Continue with email, to `/emaillogin`: only against the emulators, so
  /// developers can sign in to the seeded accounts.
  final bool emailButton;

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
                  if (signUp) ...[
                    const SizedBox(height: Space.xl),
                    Text(
                      l10n.signUpTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                  const SizedBox(height: Space.xxl),
                  // The main way in, so the filled button (AUTH-1).
                  GoogleSignInButton(
                    label: signUp
                        ? l10n.signUpWithGoogle
                        : l10n.continueWithGoogle,
                    onPressed: loading ? null : controller.signInWithGoogle,
                  ),
                  const SizedBox(height: Space.md),
                  if (appleEnabled) ...[
                    AppleSignInButton(
                      label: signUp
                          ? l10n.signUpWithApple
                          : l10n.continueWithApple,
                      onPressed: loading ? null : controller.signInWithApple,
                    ),
                    const SizedBox(height: Space.md),
                  ],
                  if (emailButton)
                    FilledButton.icon(
                      onPressed: loading
                          ? null
                          // Keep where to go back to, such as an invite
                          // link (INV-5 step 2).
                          : () => context.push(
                              Uri(
                                path: '/emaillogin',
                                queryParameters: {
                                  ...?_from(context),
                                  if (signUp) 'mode': 'create',
                                },
                              ).toString(),
                            ),
                      icon: const Icon(AppIcons.email),
                      label: Text(
                        signUp ? l10n.signUpWithEmail : l10n.continueWithEmail,
                      ),
                    ),
                  if (error != null) ...[
                    const SizedBox(height: Space.lg),
                    SignInErrorText(error: error, onRetry: controller.retry),
                  ],
                  const SizedBox(height: Space.lg),
                  // The other page, keeping where to go back to.
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => context.go(
                            Uri(
                              path: signUp ? '/sign-in' : '/sign-up',
                              queryParameters: _from(context),
                            ).toString(),
                          ),
                    child: Text(
                      signUp ? l10n.haveAccountSignIn : l10n.newHereSignUp,
                    ),
                  ),
                  const SizedBox(height: Space.xl),
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

/// The Google button (AUTH-1): the theme's main gumdrop, with Google's
/// "G" in its own colors on a white disc before the title, as Google's
/// branding guidelines ask of a button in other colors.
class GoogleSignInButton extends StatelessWidget {
  const new({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const GoogleLogo(size: 17),
    ),
    label: Text(label),
  );
}

/// Google's "G", unaltered, in its four colors (Google's sign-in branding
/// guidelines). Brand marks aren't in Material Symbols (AppIcons).
class GoogleLogo extends StatelessWidget {
  const new({this.size = 18, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    excludeSemantics: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: const _GoogleLogoPainter(),
    ),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  const new();

  @override
  void paint(Canvas canvas, Size size) {
    // Google's 48 x 48 drawing, scaled to the box.
    canvas.scale(size.width / 48, size.height / 48);
    final red = Path()
      ..moveTo(24, 9.5)
      ..relativeCubicTo(3.54, 0, 6.71, 1.22, 9.21, 3.6)
      ..relativeLineTo(6.85, -6.85)
      ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
      ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
      ..relativeLineTo(7.98, 6.19)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
      ..close();
    final blue = Path()
      ..moveTo(46.98, 24.55)
      ..relativeCubicTo(0, -1.57, -0.15, -3.09, -0.38, -4.55)
      ..lineTo(24, 20)
      ..relativeLineTo(0, 9.02)
      ..relativeLineTo(12.94, 0)
      ..relativeCubicTo(-0.58, 2.96, -2.26, 5.48, -4.78, 7.18)
      ..relativeLineTo(7.73, 6)
      ..relativeCubicTo(4.51, -4.18, 7.09, -10.36, 7.09, -17.65)
      ..close();
    final yellow = Path()
      ..moveTo(10.53, 28.59)
      ..relativeCubicTo(-0.48, -1.45, -0.76, -2.99, -0.76, -4.59)
      ..relativeCubicTo(0, -1.6, 0.27, -3.14, 0.76, -4.59)
      ..relativeLineTo(-7.98, -6.19)
      ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24)
      ..relativeCubicTo(0, 3.88, 0.92, 7.54, 2.56, 10.78)
      ..relativeLineTo(7.97, -6.19)
      ..close();
    final green = Path()
      ..moveTo(24, 48)
      ..relativeCubicTo(6.48, 0, 11.93, -2.13, 15.89, -5.81)
      ..relativeLineTo(-7.73, -6)
      ..relativeCubicTo(-2.15, 1.45, -4.92, 2.3, -8.16, 2.3)
      ..relativeCubicTo(-6.26, 0, -11.57, -4.22, -13.47, -9.91)
      ..relativeLineTo(-7.98, 6.19)
      ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
      ..close();
    for (final (path, color) in [
      (red, const Color(0xFFEA4335)),
      (blue, const Color(0xFF4285F4)),
      (yellow, const Color(0xFFFBBC05)),
      (green, const Color(0xFF34A853)),
    ]) {
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
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

/// The `from` the router put on `/sign-in`, to carry on between sign-in
/// and sign-up (and to email sign-in, against the emulators).
Map<String, String>? _from(BuildContext context) {
  final from = GoRouterState.of(context).uri.queryParameters['from'];
  return from == null ? null : {'from': from};
}

/// The brand mark above the app's name (SPEC §7.1).
class AppLogo extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: BrandMark());
}
