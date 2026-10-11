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

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email.trim(), password: password),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  /// Emails a sign-in link and remembers the address on this device, so
  /// opening the link here finishes without asking for it again.
  Future<void> sendSignInLink(String email) async {
    final address = email.trim();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
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
  unknown,
}

SignInError signInErrorOf(Object error) => switch (error) {
  InvalidInput() => SignInError.badCredentials,
  Offline() => SignInError.offline,
  RateLimited() => SignInError.rateLimited,
  PermissionDenied() => SignInError.disabled,
  PopupBlocked() => SignInError.popupBlocked,
  AccountExistsWithOtherMethod() => SignInError.otherMethod,
  _ => SignInError.unknown,
};
