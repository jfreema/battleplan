import 'dart:async';

import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/auth/domain/auth_repository.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Authentication behind [AuthRepository]. Firebase types and
/// exceptions stay in this file; callers get [AuthUser] and [AppFailure]s.
class FirebaseAuthRepository implements AuthRepository {
  new(this._auth);

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
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    try {
      // Web uses a popup (redirects break under browser storage
      // partitioning, ARCH §6.1). Mobile opens the provider's page in the
      // system browser sheet and returns through the app's URL scheme.
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
  Future<void> signOut() => _auth.signOut();
}
