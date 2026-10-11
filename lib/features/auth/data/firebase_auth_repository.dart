import 'dart:async';

import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/auth/domain/auth_repository.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Authentication behind [AuthRepository]. Firebase types and
/// exceptions stay in this file; callers get [AuthUser] and [AppFailure]s.
class FirebaseAuthRepository implements AuthRepository {
  new(this._auth, this._functions, {required this.linkHost});

  final FirebaseFunctions _functions;

  /// The Hosting domain email links point at (never a Dynamic Links domain).
  final String linkHost;

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
        ActionCodeSettings(url: 'https://$linkHost/'),
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
    await user.reload();
    // reload() doesn't emit on idTokenChanges; a forced token refresh does,
    // so watchUser picks up the new emailVerified value.
    await user.getIdToken(true);
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
  Future<void> signInWithApple() => _signInWithProvider(
    AppleAuthProvider()
      ..addScope('email')
      ..addScope('name'),
  );

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
      throw switch (e.code) {
        'popup-blocked' => PopupBlocked(e.code),
        'account-exists-with-different-credential' =>
          AccountExistsWithOtherMethod(e.code),
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
          url: 'https://$linkHost/activate',
          handleCodeInApp: true,
          // Firebase accepts only a custom Hosting domain here (M0 spike 2).
          // Without one, links use the project's firebaseapp.com domain.
          linkDomain: _customDomain ? linkHost : null,
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

  /// Deep links arrive as a path and query; Firebase wants a full URL.
  String _absolute(Uri link) =>
      link.hasScheme ? link.toString() : 'https://$linkHost$link';

  bool get _customDomain =>
      !linkHost.endsWith('.web.app') && !linkHost.endsWith('.firebaseapp.com');

  /// The app that should open the link: prod for the prod domain, else dev.
  String get _androidPackage => linkHost == 'getbattleplan.app'
      ? 'app.getbattleplan'
      : 'app.getbattleplan.dev';
  String get _iosBundleId => _androidPackage;

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> signOutEverywhere() async {
    try {
      await _functions.httpsCallable('signOutEverywhere').call<void>();
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        'unavailable' || 'deadline-exceeded' => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
    await _auth.signOut();
  }
}
