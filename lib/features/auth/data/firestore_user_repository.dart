import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/auth/domain/user_profile.dart';
import 'package:battleplan/features/auth/domain/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Reads `users/{uid}` from Firestore and writes it through the
/// `ensureUserProfile` callable.
class FirestoreUserRepository implements UserRepository {
  new(this._db, this._functions, this._storage);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;
  final _urls = <String, String>{};

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(Collections.users).doc(uid);

  @override
  Stream<UserProfile?> watchProfile(String uid) => _db
      .collection(Collections.users)
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? userProfileFromFirestore(s.id, s.data()!) : null);

  @override
  Future<void> ensureProfile({
    String? displayName,
    bool finishSetup = false,
  }) async {
    try {
      await _functions.httpsCallable('ensureUserProfile').call<void>({
        if (finishSetup)
          'setup': {
            'displayName': displayName,
            'confirmAdult': true,
            'acceptTerms': true,
          },
      });
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        'invalid-argument' => InvalidInput(e.message),
        'unauthenticated' => Unauthenticated(e.message),
        'unavailable' || 'deadline-exceeded' => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }

  @override
  Future<void> updateDisplayName(String uid, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 50) {
      throw const InvalidInput('Names are 1 to 50 characters.');
    }
    return _update(uid, {
      'displayName': trimmed,
      'displayNameLower': trimmed.toLowerCase(),
    });
  }

  @override
  Future<void> setThemeMode(String uid, ThemePreference mode) =>
      _update(uid, {'themeMode': mode.value});

  @override
  Future<void> uploadPhoto(String uid, Uint8List jpegBytes) async {
    final previous = (await _doc(uid).get()).data()?['photoPath'] as String?;
    final path =
        'users/$uid/avatar/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _storage
          .ref(path)
          .putData(jpegBytes, SettableMetadata(contentType: 'image/jpeg'));
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'unauthorized' => PermissionDenied(e.code),
        'retry-limit-exceeded' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
    await _update(uid, {'photoPath': path});
    if (previous != null && previous != path) {
      await _storage.ref(previous).delete().catchError((Object _) {});
    }
  }

  @override
  Future<String?> photoUrl(String path) async {
    final cached = _urls[path];
    if (cached != null) return cached;
    try {
      return _urls[path] = await _storage.ref(path).getDownloadURL();
    } on FirebaseException {
      return null;
    }
  }
}

extension on FirestoreUserRepository {
  Future<void> _update(String uid, Map<String, Object?> fields) async {
    try {
      await _doc(uid)
          .update({...fields, 'updatedAt': FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'unavailable' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }
}

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

UserProfile userProfileFromFirestore(String uid, Map<String, dynamic> d) =>
    UserProfile(
      uid: uid,
      displayName: d['displayName'] as String? ?? '',
      status: UserStatus.tryParse(d['status'] as String?) ?? UserStatus.active,
      email: d['email'] as String?,
      photoPath: d['photoPath'] as String?,
      themeMode:
          ThemePreference.tryParse(d['themeMode'] as String?) ??
          ThemePreference.system,
      signInMethods: [
        for (final m in (d['signInMethods'] as List?) ?? const []) '$m',
      ],
      adultConfirmedAt: _date(d['adultConfirmedAt']),
      acceptedTermsAt: _date(d['acceptedTermsAt']),
    );
