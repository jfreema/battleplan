import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/auth/domain/user_profile.dart';
import 'package:battleplan/features/auth/domain/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Reads `users/{uid}` from Firestore and writes it through the
/// `ensureUserProfile` callable.
class FirestoreUserRepository implements UserRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

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
