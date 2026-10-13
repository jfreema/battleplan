import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_controller.g.dart';

/// State for the sign-in screen: idle, loading, or the last error.
/// Navigation after success is the router's job (it watches the auth user).
@riverpod
class SignInController extends _$SignInController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// The last attempt, for Retry after an offline error (AUTH edge cases).
  Future<void> Function()? _last;

  /// Runs [attempt], keeping it for [retry].
  Future<void> _run(Future<void> Function() attempt) async {
    _last = attempt;
    state = const AsyncLoading();
    state = await AsyncValue.guard(attempt);
  }

  /// Tries the last sign-in again.
  Future<void> retry() async {
    final last = _last;
    if (last != null) await _run(last);
  }

  Future<void> signInWithEmail(String email, String password) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signInWithEmail(email: email.trim(), password: password),
  );

  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  }) => _run(
    () => ref
        .read(authRepositoryProvider)
        .createAccount(
          name: name.trim(),
          email: email.trim(),
          password: password,
        ),
  );

  Future<void> signInWithApple() => _run(
    () => _withLinkLater(
      'apple.com',
      ref.read(authRepositoryProvider).signInWithApple,
    ),
  );

  Future<void> signInWithGoogle() => _run(
    () => _withLinkLater(
      'google.com',
      ref.read(authRepositoryProvider).signInWithGoogle,
    ),
  );

  /// AUTH-7: when the email already has an account, the repository emails a
  /// sign-in link. Remember the address (so the link finishes here without
  /// asking) and the method, which the app offers to link once it's open.
  Future<void> _withLinkLater(
    String providerId,
    Future<void> Function() signIn,
  ) async {
    try {
      await signIn();
    } on AccountExistsWithOtherMethod catch (e) {
      final email = e.message;
      if (email != null) {
        final prefs = ref.read(localPrefsRepositoryProvider);
        await prefs.setPendingSignInEmail(email);
        await prefs.setPendingLink((providerId: providerId, email: email));
      }
      rethrow;
    }
  }

  /// Emails a sign-in link and remembers the address on this device, so
  /// opening the link here finishes without asking for it again.
  Future<void> sendSignInLink(String email) async {
    final address = email.trim();
    await _run(() async {
      await ref.read(authRepositoryProvider).sendSignInLink(address);
      await ref
          .read(localPrefsRepositoryProvider)
          .setPendingSignInEmail(address);
    });
    if (!state.hasError) ref.read(signInLinkSentProvider.notifier).set(address);
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}

/// The address a sign-in link was just sent to, shown as a confirmation.
@riverpod
class SignInLinkSent extends _$SignInLinkSent {
  @override
  String? build() => null;

  // ignore: use_setters_to_change_properties, Riverpod notifiers expose methods.
  void set(String? email) => state = email;
}

/// Which message to show for a sign-in failure.
enum SignInError {
  badCredentials,
  offline,
  rateLimited,
  disabled,
  popupBlocked,
  otherMethod,
  emailInUse,
  weakPassword,
  unknown,
}

SignInError signInErrorOf(Object error) => switch (error) {
  InvalidInput() => SignInError.badCredentials,
  Offline() => SignInError.offline,
  RateLimited() => SignInError.rateLimited,
  PermissionDenied() => SignInError.disabled,
  PopupBlocked() => SignInError.popupBlocked,
  AccountExistsWithOtherMethod() => SignInError.otherMethod,
  EmailAlreadyInUse() => SignInError.emailInUse,
  WeakPassword() => SignInError.weakPassword,
  _ => SignInError.unknown,
};
