import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/plan_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Licenses read from Firestore (holders may read their own) and changed
/// through the plans callables.
class FunctionsPlanRepository implements PlanRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<List<HeldLicense>> watchMyLicenses(UserId uid) => _db
      .collection(Collections.licenses)
      .where('holderId', isEqualTo: uid.value)
      .limit(Limits.queryLimitMax)
      .snapshots()
      .map((q) {
        final now = DateTime.now();
        return [
          for (final d in q.docs)
            if (d.data()['revokedAt'] == null &&
                (d.data()['endsAt'] as Timestamp?)?.toDate().isAfter(now) ==
                    true)
              (
                id: d.id,
                groupId: switch (d.data()['groupId']) {
                  final String g => GroupId(g),
                  _ => null,
                },
                endsAt: (d.data()['endsAt'] as Timestamp).toDate(),
              ),
        ];
      });

  @override
  Future<void> moveLicense(String licenseId, GroupId toGroupId) => _call(
    'moveLicense',
    {'licenseId': licenseId, 'toGroupId': toGroupId.value},
  );

  @override
  Future<void> grantLicense(
    GroupId groupId,
    UserId holder, {
    int months = 12,
  }) => _call('adminGrantLicense', {
    'groupId': groupId.value,
    'holderId': holder.value,
    'months': months,
  });

  @override
  Future<void> extendLicense(String licenseId, {int months = 12}) =>
      _call('adminExtendLicense', {'licenseId': licenseId, 'months': months});

  @override
  Future<void> revokeLicense(String licenseId) =>
      _call('adminRevokeLicense', {'licenseId': licenseId});

  Future<void> _call(String name, Map<String, Object?> data) async {
    try {
      await _functions.httpsCallable(name).call<Object?>(data);
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        'failed-precondition' => InvalidInput(e.message),
        'permission-denied' => PermissionDenied(e.message),
        'unavailable' || 'deadline-exceeded' => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }
}
