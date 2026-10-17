import 'dart:async';

import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/links.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/features/auth/domain/auth_repository.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Authentication behind [AuthRepository]. Firebase types and
/// exceptions stay in this file; callers get [AuthUser] and [AppFailure]s.
class FirebaseAuthRepository implements AuthRepository {
  new(this._auth, this._functions, {required this.links});

  final FirebaseFunctions _functions;

  /// Builds the email links, on our Hosting domain (never a Dynamic Links
  /// domain). They open the web app under `/app` (D40).
  final LinkService links;

  final FirebaseAuth _auth;
  AuthUser? _current;

  @override
  AuthUser? get currentUser => _current;

  /// Uses idTokenChanges (not authStateChanges) so a refreshed token with a
  /// new superAdmin claim is picked up without signing out.
  @override
  Stream<AuthUser?> watchUser() =>
      _auth.idTokenChanges().asyncMap((user) async {
        return _current = user == null ? null : await _map(user);
      });

  /// Converts a Firebase user, reading custom claims from the ID token.
  Future<AuthUser> _map(User user) async {
    final token = await user.getIdTokenResult();
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
      isSuperAdmin: token.claims?['superAdmin'] == true,
      providerIds: [for (final p in user.providerData) p.providerId],
      authTime: token.authTime,
      signInProvider: token.signInProvider,
    );
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Map Firebase error codes to the app's failure types. Wrong email and
      // wrong password look the same, so we never reveal which accounts exist.
      throw switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'invalid-email' => InvalidInput(e.code),
        'user-disabled' => PermissionDenied(e.code),
        'too-many-requests' => RateLimited(e.code),
        'network-request-failed' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      // AUTH-3: email accounts start unverified; send the link right away.
      await sendEmailVerification();
      // The token refresh carries the new name to watchUser listeners.
      await credential.user?.reload();
    } on FirebaseAuthException catch (e) {
      throw switch (e.code) {
        'email-already-in-use' => EmailAlreadyInUse(e.code),
        'weak-password' ||
        'password-does-not-meet-requirements' => WeakPassword(e.code),
        'invalid-email' => InvalidInput(e.code),
        'too-many-requests' => RateLimited(e.code),
        'network-request-failed' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    try {
      await user.sendEmailVerification(
        ActionCodeSettings(url: links.appRoot.toString()),
      );
    } on FirebaseAuthException catch (e) {
      throw switch (e.code) {
        'too-many-requests' => RateLimited(e.code),
        'network-request-failed' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.reload();
      // reload() doesn't emit on idTokenChanges; a forced token refresh
      // does, so watchUser picks up the new emailVerified value.
      await user.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      // A revoked or disabled session fails here, and the SDK signs out.
      throw switch (e.code) {
        'user-token-expired' ||
        'user-disabled' ||
        'user-not-found' ||
        'invalid-user-token' => Unauthenticated(e.code),
        'network-request-failed' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // With enumeration protection, unknown emails don't error. If a project
      // without it does, still show the generic "if an account exists" note.
      if (e.code == 'user-not-found') return;
      throw switch (e.code) {
        'invalid-email' || 'missing-email' => InvalidInput(e.code),
        'too-many-requests' => RateLimited(e.code),
        'network-request-failed' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> signInWithGoogle() => _signInWithProvider(
    GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}),
  );

  @override
  Future<void> signInWithApple() => _signInWithProvider(_apple());

  /// Apple's provider, asking for the email and, the first time only, the
  /// name (AUTH-1).
  static AppleAuthProvider _apple() => AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  /// Shared by every OAuth provider. Web uses a popup (redirects break under
  /// browser storage partitioning, ARCH §6.1). Mobile opens the provider in
  /// the system sheet and returns through the app's URL scheme.
  Future<void> _signInWithProvider(AuthProvider provider) async {
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(provider);
      } else {
        await _auth.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) return;
      // AUTH-7: never merge on matching emails. Prove the email instead:
      // send a sign-in link; once it's opened, the app offers to link this
      // provider (the caller remembers which one).
      final email = e.email;
      if (e.code == 'account-exists-with-different-credential' &&
          email != null) {
        await sendSignInLink(email);
        throw AccountExistsWithOtherMethod(email);
      }
      throw switch (e.code) {
        'popup-blocked' => PopupBlocked(e.code),
        // No email to send a link to: nothing was sent.
        'account-exists-with-different-credential' =>
          const AccountExistsWithOtherMethod(),
        'user-disabled' => PermissionDenied(e.code),
        'network-request-failed' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  /// Codes Firebase uses when the person closes the sign-in sheet or popup.
  static const _cancelCodes = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'web-context-canceled',
    'web-context-cancelled',
    'canceled',
    'user-cancelled',
  };

  @override
  Future<void> sendSignInLink(String email) async {
    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: links.activate.toString(),
          handleCodeInApp: true,
          // Firebase accepts only a custom Hosting domain here (M0 spike 2).
          // Without one, links use the project's firebaseapp.com domain.
          linkDomain: links.isCustomDomain ? links.host : null,
          androidPackageName: _androidPackage,
          iOSBundleId: _iosBundleId,
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw switch (e.code) {
        'invalid-email' || 'missing-email' => InvalidInput(e.code),
        'too-many-requests' => RateLimited(e.code),
        'network-request-failed' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  bool isSignInLink(Uri link) => _auth.isSignInWithEmailLink(_absolute(link));

  @override
  Future<void> signInWithLink({
    required String email,
    required Uri link,
  }) async {
    try {
      await _auth.signInWithEmailLink(email: email, emailLink: _absolute(link));
    } on FirebaseAuthException catch (e) {
      throw switch (e.code) {
        'invalid-action-code' || 'expired-action-code' => NotFound(e.code),
        'invalid-email' => InvalidInput(e.code),
        'user-disabled' => PermissionDenied(e.code),
        'network-request-failed' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  /// Deep links arrive as an app route and query; Firebase wants a full URL.
  String _absolute(Uri link) =>
      link.hasScheme ? link.toString() : links.app('$link').toString();

  /// The app that should open the link: prod for the prod domain, else dev.
  String get _androidPackage => links.host == LinkService.prodHost
      ? 'app.getbattleplan'
      : 'app.getbattleplan.dev';
  String get _iosBundleId => _androidPackage;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw const Unauthenticated();
    return user;
  }

  /// Maps errors shared by the sign-in method actions.
  Never _throwMethodError(FirebaseAuthException e) => throw switch (e.code) {
    'requires-recent-login' ||
    'user-token-expired' => RequiresRecentLogin(e.code),
    'credential-already-in-use' ||
    'email-already-in-use' ||
    'account-exists-with-different-credential' => CredentialInUse(e.code),
    'weak-password' ||
    'password-does-not-meet-requirements' => WeakPassword(e.code),
    'wrong-password' || 'invalid-credential' => InvalidInput(e.code),
    'invalid-email' => InvalidInput(e.code),
    'network-request-failed' => Offline(e.code),
    'too-many-requests' => RateLimited(e.code),
    _ => UnknownFailure(e.code),
  };

  /// How recent the sign-in must be to change sign-in methods, the email,
  /// or the password (AUTH-7). The server asks the same for deleting.
  static const _recentSignIn = Duration(minutes: 5);

  /// AUTH-7: a fresh sign-in first. Firebase asks for one only for some
  /// changes (not linking or unlinking), so the app checks every time.
  /// A fresh token's issue time is the server's clock, like its auth_time,
  /// so a device clock that's off never blocks the change.
  Future<void> _requireRecentSignIn() async {
    final IdTokenResult token;
    try {
      token = await _user.getIdTokenResult(true);
    } on FirebaseAuthException catch (e) {
      _throwMethodError(e);
    }
    if (!isRecentSignIn(token.authTime, token.issuedAtTime)) {
      throw const RequiresRecentLogin('requires-recent-login');
    }
  }

  /// Tells the server the methods changed, so `users.signInMethods` stays a
  /// true copy and the security notice can go out (AUTH-7). With
  /// [passwordChanged], the notice says the password changed.
  Future<void> _recordMethodChange({bool passwordChanged = false}) async {
    await _user.getIdToken(true);
    try {
      await _functions.httpsCallable('recordSignInMethodChange').call<void>({
        if (passwordChanged) 'passwordChanged': true,
      });
    } on FirebaseFunctionsException catch (e) {
      // The daily reconcile job catches anything missed (ARCH §6.1).
      throw UnknownFailure('recordSignInMethodChange: ${e.code}');
    }
  }

  @override
  Future<bool> linkGoogle({bool checkRecent = true}) => _link(
    GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}),
    checkRecent: checkRecent,
  );

  @override
  Future<bool> linkApple({bool checkRecent = true}) =>
      _link(_apple(), checkRecent: checkRecent);

  Future<bool> _link(AuthProvider provider, {required bool checkRecent}) async {
    if (checkRecent) await _requireRecentSignIn();
    try {
      if (kIsWeb) {
        await _user.linkWithPopup(provider);
      } else {
        await _user.linkWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) return false;
      _throwMethodError(e);
    }
    await _recordMethodChange();
    return true;
  }

  @override
  Future<void> unlink(String providerId) async {
    final user = _user;
    if (user.providerData.length <= 1) {
      throw const InvalidInput('The last sign-in method stays.');
    }
    await _requireRecentSignIn();
    try {
      await user.unlink(providerId);
    } on FirebaseAuthException catch (e) {
      _throwMethodError(e);
    }
    await _recordMethodChange();
  }

  @override
  Future<void> setPassword(
    String newPassword, {
    bool checkRecent = true,
  }) async {
    final user = _user;
    final hasPassword = user.providerData.any(
      (p) => p.providerId == 'password',
    );
    if (checkRecent) await _requireRecentSignIn();
    try {
      if (hasPassword) {
        await user.updatePassword(newPassword);
      } else {
        final email = user.email;
        if (email == null) throw const InvalidInput('No email on the account.');
        await user.linkWithCredential(
          EmailAuthProvider.credential(email: email, password: newPassword),
        );
      }
    } on FirebaseAuthException catch (e) {
      _throwMethodError(e);
    }
    await _recordMethodChange(passwordChanged: hasPassword);
  }

  /// The new address confirms the link, then Firebase changes the email
  /// and ends this session. At the next sign-in, ensureUserProfile copies
  /// the new address into the profile and emails both addresses (AUTH-8).
  @override
  Future<void> changeEmail(String newEmail) async {
    await _requireRecentSignIn();
    try {
      await _user.verifyBeforeUpdateEmail(
        newEmail,
        ActionCodeSettings(url: links.appRoot.toString()),
      );
    } on FirebaseAuthException catch (e) {
      _throwMethodError(e);
    }
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _user;
    final email = user.email;
    if (email == null) throw const InvalidInput('No email on the account.');
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (e) {
      _throwMethodError(e);
    }
  }

  @override
  Future<void> reauthenticateWithProvider(String providerId) async {
    final provider = switch (providerId) {
      'apple.com' => _apple(),
      _ => GoogleAuthProvider(),
    };
    try {
      if (kIsWeb) {
        await _user.reauthenticateWithPopup(provider);
      } else {
        await _user.reauthenticateWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) throw const RequiresRecentLogin();
      _throwMethodError(e);
    }
  }

  @override
  Future<void> deleteAccount({Map<String, String> newOwners = const {}}) async {
    await _revokeAppleSignIn();
    try {
      await _functions.httpsCallable('deleteAccount').call<void>({
        if (newOwners.isNotEmpty) 'newOwners': newOwners,
      });
    } on FirebaseFunctionsException catch (e) {
      final message = serverMessage(e.message);
      throw switch (e.code) {
        'failed-precondition' => RequiresRecentLogin(message),
        'unavailable' || 'deadline-exceeded' => Offline(message),
        _ => UnknownFailure('${e.code}: $message'),
      };
    }
    // The Auth user is gone; clear the local session too.
    await _auth.signOut();
  }

  /// App Review 5.1.1(v): in the iPhone, iPad, and Mac apps, an account
  /// that signs in with Apple has Apple's tokens revoked before it's
  /// deleted. Revoking takes the authorization code from a fresh Apple
  /// sign-in, which is also the recent sign-in deleting needs. The web and
  /// Android SDKs can't revoke (ARCH §6.1).
  Future<void> _revokeAppleSignIn() async {
    final apple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final user = _auth.currentUser;
    if (kIsWeb ||
        !apple ||
        user == null ||
        !user.providerData.any((p) => p.providerId == 'apple.com')) {
      return;
    }
    final UserCredential fresh;
    try {
      fresh = await user.reauthenticateWithProvider(_apple());
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) throw const SignInCanceled();
      _throwMethodError(e);
    }
    final code = fresh.additionalUserInfo?.authorizationCode;
    if (code == null) return;
    try {
      await _auth.revokeTokenWithAuthorizationCode(code);
    } on FirebaseAuthException catch (e) {
      // Deleting still goes ahead: the account is what they asked to
      // remove, and without it Apple's tokens open nothing. They can also
      // remove Battleplan under Sign in with Apple in their Apple Account.
      Log.error('Revoking Apple sign-in failed', e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> signOutEverywhere() async {
    try {
      await _functions.httpsCallable('signOutEverywhere').call<void>();
    } on FirebaseFunctionsException catch (e) {
      final message = serverMessage(e.message);
      throw switch (e.code) {
        'unavailable' || 'deadline-exceeded' => Offline(message),
        _ => UnknownFailure('${e.code}: $message'),
      };
    }
    await _auth.signOut();
  }
}

/// Whether a sign-in at [authTime] is recent enough to change sign-in
/// methods, the email, or the password (AUTH-7), judged at [issuedAt], when
/// the server issued a fresh token. Both come from the server, so the
/// device clock plays no part.
@visibleForTesting
bool isRecentSignIn(DateTime? authTime, DateTime? issuedAt) =>
    authTime != null &&
    issuedAt != null &&
    issuedAt.difference(authTime) <= FirebaseAuthRepository._recentSignIn;
