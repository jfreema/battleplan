import 'package:battleplan/features/auth/domain/auth_user.dart';

abstract interface class AuthRepository {
  /// Emits on sign-in, sign-out, and token refresh (claims may change).
  Stream<AuthUser?> watchUser();

  AuthUser? get currentUser;

  /// Throws an AppFailure on bad credentials or no connection.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// Google sign-in: a popup on web, the system browser sheet on iOS and
  /// Android. Returns normally if the person cancels (no error is shown).
  Future<void> signInWithGoogle();

  Future<void> signOut();
}
