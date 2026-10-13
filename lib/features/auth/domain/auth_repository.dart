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

  /// Creates an email-and-password account (AUTH-2) and sets its display
  /// name. The person is signed in afterwards.
  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  });

  /// Sends (or re-sends) the email verification link (AUTH-3).
  Future<void> sendEmailVerification();

  /// Re-reads the signed-in user from the server, so a just-verified email
  /// shows as verified without signing out.
  Future<void> reloadUser();

  /// Sends a password reset email (AUTH-4). Succeeds whether or not an
  /// account exists for [email], so the app never reveals which emails have
  /// accounts (email enumeration protection, ARCH §6.1).
  Future<void> sendPasswordReset(String email);

  /// Sign in with Apple: the native sheet on iOS, a web flow on Android and
  /// web. Returns normally if the person cancels. Needs the Apple Developer
  /// membership before it works (roadmap task 109).
  Future<void> signInWithApple();

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

  // Sign-in methods (AUTH-7, AUTH-8). Each throws RequiresRecentLogin when
  // the last sign-in is more than 5 minutes old; reauthenticate, then retry.
  // Each change emails the account a security notice.
  //
  // With checkRecent false, linkGoogle and setPassword skip the app's own
  // 5-minute check, leaving only Firebase's: for an added account still
  // choosing how to sign in (AUTH-6), whose only way in was its setup link.

  /// Links Google to the signed-in account by completing Google's sign-in.
  /// Returns false if the person closed Google's sheet.
  Future<bool> linkGoogle({bool checkRecent = true});

  /// Removes a sign-in method. The last one can't be removed.
  Future<void> unlink(String providerId);

  /// Sets a password (adding the password method) or changes it.
  Future<void> setPassword(String newPassword, {bool checkRecent = true});

  /// Changes the account email once the new address confirms a link; the
  /// profile's contact email follows, and both addresses get a notice
  /// (AUTH-8, AUTH-12).
  Future<void> changeEmail(String newEmail);

  /// A fresh sign-in with the account's password.
  Future<void> reauthenticateWithPassword(String password);

  /// A fresh sign-in with Google or Apple ([providerId]).
  Future<void> reauthenticateWithProvider(String providerId);

  /// Deletes the account and its data on the server, then signs out here
  /// (AUTH-10). [newOwners] maps a team the person owns to the member they
  /// picked to take it over; the rest go to the longest-serving admin or
  /// member. Throws RequiresRecentLogin without a fresh sign-in.
  Future<void> deleteAccount({Map<String, String> newOwners = const {}});

  Future<void> signOut();

  /// Ends this account's sessions on every device at once, then signs out
  /// here (AUTH-9). Other devices see `users.sessionsRevokedAt` and sign
  /// out (sessionRevocationWatcher).
  Future<void> signOutEverywhere();
}
