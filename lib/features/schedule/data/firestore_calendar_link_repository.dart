import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/schedule/domain/calendar_link.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Calendar links (SCHED-11, ARCH §6.15): read from `calendarLinks`, where
/// only their owner can, and made, reset, and turned off by the
/// `setCalendarLink` callable, which makes the token.
class FirestoreCalendarLinkRepository implements CalendarLinkRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<List<CalendarLink>> watchMine(UserId uid) => _db
      .collection(Collections.calendarLinks)
      .where('uid', isEqualTo: uid.value)
      .limit(Limits.queryLimitMax)
      .snapshots()
      .map((snap) => [for (final d in snap.docs) _link(d.id, d.data())]);

  static CalendarLink _link(String token, Map<String, dynamic> data) {
    final groupId = data['groupId'];
    final fetchedAt = data['fetchedAt'];
    return CalendarLink(
      token: token,
      groupId: groupId is String ? GroupId(groupId) : null,
      fetchedAt: fetchedAt is Timestamp ? fetchedAt.toDate() : null,
    );
  }

  @override
  Future<String?> set(GroupId? groupId, CalendarLinkAction action) async {
    try {
      final result = await _functions
          .httpsCallable('setCalendarLink')
          .call<Map<String, dynamic>>({
            'groupId': groupId?.value,
            'action': action.name,
          });
      return result.data['token'] as String?;
    } on FirebaseFunctionsException catch (e) {
      final message = serverMessage(e.message);
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(message),
        'failed-precondition' || 'invalid-argument' => InvalidInput(message),
        'unavailable' || 'deadline-exceeded' => Offline(message),
        _ => UnknownFailure('${e.code}: $message'),
      };
    }
  }
}
