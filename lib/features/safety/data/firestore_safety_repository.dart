import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:battleplan/features/safety/domain/safety_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Blocks are written directly (rules let people manage only their own);
/// reports go through the `reportContent` and `resolveReport` callables.
class FirestoreSafetyRepository implements SafetyRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  DocumentReference<Map<String, dynamic>> _block(UserId uid, UserId other) =>
      _db.collection(Collections.userBlocks).doc('${uid.value}_${other.value}');

  @override
  Stream<List<BlockedPerson>> watchBlocked(UserId uid) => _db
      .collection(Collections.userBlocks)
      .where('uid', isEqualTo: uid.value)
      .limit(Limits.queryLimitMax)
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs)
            BlockedPerson(
              uid: UserId(d.data()['blockedUid'] as String),
              name: d.data()['blockedName'] as String? ?? '',
            ),
        ],
      );

  @override
  Future<void> block(UserId uid, UserId blocked, {required String name}) =>
      _write(
        () => _block(uid, blocked).set({
          'uid': uid.value,
          'blockedUid': blocked.value,
          'blockedName': name.length > 60 ? name.substring(0, 60) : name,
          'createdAt': FieldValue.serverTimestamp(),
        }),
      );

  @override
  Future<void> unblock(UserId uid, UserId blocked) =>
      _write(() => _block(uid, blocked).delete());

  Future<void> _write(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> report(
    GroupId groupId, {
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? details,
  }) => _call('reportContent', {
    'groupId': groupId.value,
    'targetType': targetType.name,
    'targetId': targetId,
    'reason': reason.value,
    if (details != null && details.trim().isNotEmpty) 'details': details,
  });

  @override
  Stream<List<Report>> watchOpenReports(GroupId groupId) => _db
      .collection(Collections.reports)
      .where('groupId', isEqualTo: groupId.value)
      .where('status', isEqualTo: 'open')
      // SAFE-1: reports about one of the team's admins are for super
      // admins only; the rules refuse a list without this.
      .where('teamVisible', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(Limits.queryLimitMax)
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs)
            Report(
              id: d.id,
              groupId: groupId,
              targetType:
                  ReportTargetType.values.asNameMap()[d.data()['targetType']] ??
                  ReportTargetType.message,
              targetId: d.data()['targetId'] as String? ?? '',
              reason:
                  ReportReason.tryParse(d.data()['reason'] as String?) ??
                  ReportReason.other,
              subjectId: d.data()['subjectId'] as String? ?? '',
              subjectName: d.data()['subjectName'] as String? ?? '',
              excerpt: d.data()['excerpt'] as String? ?? '',
              details: d.data()['details'] as String?,
              createdAt: (d.data()['createdAt'] as Timestamp?)?.toDate(),
            ),
        ],
      );

  @override
  Future<void> resolveReport(
    String reportId, {
    required bool actioned,
    ReportResolution resolution = ReportResolution.none,
  }) => _call('resolveReport', {
    'reportId': reportId,
    'outcome': actioned ? 'actioned' : 'dismissed',
    'resolution': resolution.name,
  });

  Future<void> _call(String name, Map<String, Object?> data) async {
    try {
      await _functions.httpsCallable(name).call<Object?>(data);
    } on FirebaseFunctionsException catch (e) {
      final message = serverMessage(e.message);
      throw switch (e.code) {
        'resource-exhausted' => RateLimited(message),
        'permission-denied' => PermissionDenied(message),
        'unavailable' || 'deadline-exceeded' => Offline(message),
        _ => UnknownFailure('${e.code}: $message'),
      };
    }
  }
}
