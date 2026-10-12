import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/notifications/domain/notification_item.dart';
import 'package:battleplan/features/notifications/domain/notification_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// The flat `notifications` collection, queried by uid and createdAt (the
/// (uid, createdAt desc) and (uid, read) indexes).
class FirestoreNotificationRepository implements NotificationRepository {
  new(this._db);

  final FirebaseFirestore _db;

  /// Each "Mark all as read" round marks this many, the most a query may
  /// read (rules' bounded queries).
  static const _markAllBatch = 100;

  /// 1,000 items at most, so a bad cache can't loop forever.
  static const _markAllRounds = 10;

  CollectionReference<Map<String, dynamic>> get _all =>
      _db.collection(Collections.notifications);

  Query<Map<String, dynamic>> _mine(UserId uid) => _all
      .where('uid', isEqualTo: uid.value)
      .orderBy('createdAt', descending: true);

  @override
  Stream<NotificationPage> watchNewest(
    UserId uid, {
    int limit = Limits.notificationPageSize,
  }) => _mine(uid).limit(limit).snapshots().map((q) => _page(q, limit));

  @override
  Future<NotificationPage> loadOlder(
    UserId uid,
    NotificationCursor after, {
    int limit = Limits.notificationPageSize,
  }) async {
    final q = await _guard(
      () =>
          _mine(uid)
              .startAfterDocument(after.handle as DocumentSnapshot<Object?>)
              .limit(limit)
              .get(),
    );
    return _page(q, limit);
  }

  @override
  Future<int> countUnread(UserId uid, {int cap = Limits.unreadCountCap}) async {
    final q = await _guard(
      () => _all
          .where('uid', isEqualTo: uid.value)
          .where('read', isEqualTo: false)
          .limit(cap)
          .count()
          .get(),
    );
    return q.count ?? 0;
  }

  @override
  Future<void> markRead(String id) =>
      _guard(() => _all.doc(id).update({'read': true}));

  @override
  Future<void> markAllRead(UserId uid) async {
    for (var round = 0; round < _markAllRounds; round++) {
      final q = await _guard(
        () => _all
            .where('uid', isEqualTo: uid.value)
            .where('read', isEqualTo: false)
            .limit(_markAllBatch)
            .get(),
      );
      if (q.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in q.docs) {
        batch.update(d.reference, {'read': true});
      }
      await _guard(batch.commit);
      if (q.docs.length < _markAllBatch) return;
    }
  }

  NotificationPage _page(QuerySnapshot<Map<String, dynamic>> q, int limit) =>
      NotificationPage(
        items: [
          for (final d in q.docs) notificationFromFirestore(d.id, d.data()),
        ],
        next: q.docs.length < limit ? null : NotificationCursor(q.docs.last),
      );

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'not-found' => NotFound(e.code),
        'unavailable' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }
}

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

NotificationItem notificationFromFirestore(String id, Map<String, dynamic> d) =>
    NotificationItem(
      id: id,
      groupId: GroupId(d['groupId'] as String? ?? ''),
      kind: NotifyKind.tryParse(d['type'] as String?),
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      route: d['route'] as String? ?? '',
      actorId: d['actorId'] as String?,
      read: d['read'] == true,
      createdAt: _date(d['createdAt']),
      expiresAt: _date(d['expiresAt']),
    );
