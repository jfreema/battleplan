import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Owns `groups` (ARCH §5.2 collection ownership).
class FirestoreGroupRepository implements GroupRepository {
  new(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<Group?> watchGroup(GroupId id) => _db
      .collection(Collections.groups)
      .doc(id.value)
      .snapshots()
      .map((s) => s.exists ? groupFromFirestore(s.id, s.data()!) : null)
      // A team you can no longer read (removed, suspended) reads as gone.
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stack, sink) => _isPermissionDenied(error)
              ? sink.add(null)
              : sink.addError(error, stack),
        ),
      );
}

/// Owns `groupMembers`.
class FirestoreMemberRepository implements MemberRepository {
  new(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<Membership>> watchMyMemberships(UserId uid) => _db
      .collection(Collections.groupMembers)
      .where('uid', isEqualTo: uid.value)
      .limit(Limits.groupsPerUserMax)
      .snapshots()
      .map((q) => [for (final d in q.docs) membershipFromFirestore(d.data())]);
}

bool _isPermissionDenied(dynamic e) =>
    e is FirebaseException && e.code == 'permission-denied';

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

Group groupFromFirestore(String id, Map<String, dynamic> d) {
  final preview = d['lastMessagePreview'] as Map<String, dynamic>?;
  return Group(
    id: GroupId(id),
    name: d['name'] as String? ?? '',
    sport: Sport.tryParse(d['sport'] as String?) ?? Sport.other,
    teamType: TeamType.tryParse(d['teamType'] as String?) ?? TeamType.adult,
    memberCount: (d['memberCount'] as num?)?.toInt() ?? 0,
    description: d['description'] as String?,
    color: _parseColor(d['color'] as String?),
    lastMessageAt: _date(d['lastMessageAt']),
    lastMessagePreview: preview == null
        ? null
        : '${preview['authorName']}: ${preview['text'] ?? ''}',
    archivedAt: _date(d['archivedAt']),
    suspendedAt: _date(d['suspendedAt']),
  );
}

Membership membershipFromFirestore(Map<String, dynamic> d) => Membership(
  groupId: GroupId(d['groupId'] as String),
  uid: UserId(d['uid'] as String),
  role: MemberRole.tryParse(d['role'] as String?) ?? MemberRole.member,
  displayName: d['displayName'] as String? ?? '',
  notificationLevel:
      NotificationLevel.tryParse(d['notificationLevel'] as String?) ??
      NotificationLevel.all,
  mutedUntil: _date(d['mutedUntil']),
  lastReadAt: _date(d['lastReadAt']),
  title: d['title'] as String?,
);

int? _parseColor(String? hex) {
  if (hex == null || !hex.startsWith('#') || hex.length != 7) return null;
  final rgb = int.tryParse(hex.substring(1), radix: 16);
  return rgb == null ? null : 0xFF000000 | rgb;
}
