import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Owns `groups` (ARCH §5.2 collection ownership).
class FirestoreGroupRepository implements GroupRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Future<GroupId> createGroup({
    required String name,
    required Sport sport,
    required TeamType teamType,
    required String timeZone,
    String? color,
    String? description,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('createGroup')
          .call<Map<String, dynamic>>({
            'name': name,
            'sport': sport.value,
            'teamType': teamType.value,
            'timeZone': timeZone,
            'color': ?color,
            if (description != null && description.isNotEmpty)
              'description': description,
          });
      return GroupId(result.data['groupId'] as String);
    } on FirebaseFunctionsException catch (e) {
      throw switch ((e.code, e.message)) {
        ('failed-precondition', 'email-not-verified') => EmailNotVerified(
          e.message,
        ),
        ('failed-precondition', 'too-many-teams') => TooManyTeams(e.message),
        ('resource-exhausted', _) => RateLimited(e.message),
        ('permission-denied', _) => PermissionDenied(e.message),
        ('invalid-argument', _) => InvalidInput(e.message),
        ('unavailable' || 'deadline-exceeded', _) => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }

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

/// Owns `groupMembers`. Role and removal changes go through callables.
class FirestoreMemberRepository implements MemberRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<List<Membership>> watchRoster(GroupId groupId) => _db
      .collection(Collections.groupMembers)
      .where('groupId', isEqualTo: groupId.value)
      .limit(Limits.queryLimitMax)
      .snapshots()
      .map((q) => [for (final d in q.docs) membershipFromFirestore(d.data())]);

  @override
  Future<void> updateMember(
    GroupId groupId,
    UserId uid, {
    MemberRole? role,
    String? title,
    bool clearTitle = false,
  }) => _call('updateGroupMember', {
    'groupId': groupId.value,
    'uid': uid.value,
    if (role != null) 'role': role.value,
    if (clearTitle) 'title': null else 'title': ?title,
  });

  @override
  Future<void> removeMember(GroupId groupId, UserId uid) =>
      _call('removeMember', {'groupId': groupId.value, 'uid': uid.value});

  Future<void> _call(String name, Map<String, Object?> data) async {
    try {
      await _functions.httpsCallable(name).call<void>(data);
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.message),
        'not-found' => NotFound(e.message),
        'invalid-argument' => InvalidInput(e.message),
        'unavailable' || 'deadline-exceeded' => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }

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
