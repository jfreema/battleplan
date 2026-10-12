import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/notifications/domain/device_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// `devices/{installationId}` in Firestore. Rules require exactly these
/// five fields and `updatedAt` at the request time.
class FirestoreDeviceRepository implements DeviceRepository {
  new(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String installId) =>
      _db.collection(Collections.devices).doc(installId);

  @override
  Future<void> register(
    String installId, {
    required String uid,
    required String token,
    required DevicePlatform platform,
    required String appVersion,
  }) => _guard(
    () => _doc(installId).set({
      'uid': uid,
      'token': token,
      'platform': platform.value,
      // Rules cap it at 32 characters.
      'appVersion': appVersion.length > 32
          ? appVersion.substring(0, 32)
          : appVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> remove(String installId) =>
      _guard(() => _doc(installId).delete());

  Future<void> _guard(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'unavailable' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }
}
