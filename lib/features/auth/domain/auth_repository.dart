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

  /// Emails a one-tap sign-in link (ARCH §6.6). The link opens the app
  /// through App Links, or the web app, on `/activate`.
  Future<void> sendSignInLink(String email);

  /// Whether [link] (a full URL, or the path and query the app was opened
  /// with) is a sign-in link this project sent.
  bool isSignInLink(Uri link);

  /// Finishes sign-in from an emailed link. [email] must be the address the
  /// link was sent to.
  Future<void> signInWithLink({required String email, required Uri link});

  Future<void> signOut();
}
