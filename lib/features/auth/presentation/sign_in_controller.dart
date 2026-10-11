import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/auth/application/providers.dart';
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

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}

/// Which message to show for a sign-in failure.
enum SignInError { badCredentials, offline, rateLimited, disabled, unknown }

SignInError signInErrorOf(Object error) => switch (error) {
  InvalidInput() => SignInError.badCredentials,
  Offline() => SignInError.offline,
  RateLimited() => SignInError.rateLimited,
  PermissionDenied() => SignInError.disabled,
  _ => SignInError.unknown,
};
