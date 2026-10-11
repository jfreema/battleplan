import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Owns `groups` (ARCH §5.2 collection ownership).
class FirestoreGroupRepository implements GroupRepository {
  new(this._db, this._functions, this._storage);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

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
  Future<void> updateGroup(
    GroupId id, {
    String? name,
    Sport? sport,
    String? color,
    String? description,
    String? timeZone,
    GroupSettings? settings,
  }) async {
    final trimmed = name?.trim();
    try {
      await _db.collection(Collections.groups).doc(id.value).update({
        if (trimmed != null) ...{
          'name': trimmed,
          'nameLower': trimmed.toLowerCase(),
        },
        'sport': ?sport?.value,
        'color': ?color,
        'description': ?description?.trim(),
        'timeZone': ?timeZone,
        if (settings != null) 'settings': settingsToFirestore(settings),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'unavailable' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> uploadLogo(GroupId id, Uint8List jpegBytes) async {
    final path =
        'groups/${id.value}/avatar/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _storage
          .ref(path)
          .putData(jpegBytes, SettableMetadata(contentType: 'image/jpeg'));
      await _db.collection(Collections.groups).doc(id.value).update({
        'photoPath': path,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'unauthorized' || 'permission-denied' => PermissionDenied(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> updateChatTheme(GroupId id, ChatTheme theme) async {
    String? hex(int? argb) => argb == null
        ? null
        : '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    try {
      await _db.collection(Collections.groups).doc(id.value).update({
        'chatTheme': {
          'bubbleColor': hex(theme.bubbleColor),
          'background': theme.background.name,
          'backgroundPath': theme.backgroundPath,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<String> uploadChatBackground(GroupId id, Uint8List jpegBytes) async {
    final path =
        'groups/${id.value}/theme/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _storage
          .ref(path)
          .putData(jpegBytes, SettableMetadata(contentType: 'image/jpeg'));
      return path;
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'unauthorized' || 'permission-denied' => PermissionDenied(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> transferOwnership(GroupId id, UserId newOwner) =>
      _call('transferOwnership', {'groupId': id.value, 'uid': newOwner.value});

  @override
  Future<void> leave(GroupId id) => _call('leaveGroup', {'groupId': id.value});

  @override
  Future<void> setArchived(GroupId id, {required bool archived}) =>
      _call('archiveGroup', {'groupId': id.value, 'archived': archived});

  @override
  Future<void> deleteGroup(GroupId id, String confirmName) =>
      _call('deleteGroup', {'groupId': id.value, 'confirmName': confirmName});

  Future<void> _call(String name, Map<String, Object?> data) async {
    try {
      await _functions.httpsCallable(name).call<void>(data);
    } on FirebaseFunctionsException catch (e) {
      throw switch ((e.code, e.message)) {
        ('failed-precondition', 'owner-must-transfer') => OwnerMustTransfer(
          e.message,
        ),
        ('invalid-argument', 'name-mismatch') => InvalidInput(e.message),
        ('permission-denied', _) => PermissionDenied(e.message),
        ('not-found', _) => NotFound(e.message),
        ('unavailable' || 'deadline-exceeded', _) => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }

  @override
  Future<String?> photoUrl(String path) async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } on FirebaseException {
      return null;
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
  Future<void> markRead(GroupId groupId, UserId uid) async {
    try {
      await _db
          .collection(Collections.groupMembers)
          .doc(CompositeIds.groupMember(groupId, uid))
          .update({'lastReadAt': FieldValue.serverTimestamp()});
    } on FirebaseException {
      // A missed read marker only leaves a count up; the next one fixes it.
    }
  }

  @override
  Future<void> removeMember(GroupId groupId, UserId uid) =>
      _call('removeMember', {'groupId': groupId.value, 'uid': uid.value});

  @override
  Future<AddMembersResult> addByEmail(
    GroupId groupId,
    List<({String? name, String email})> entries,
  ) async {
    try {
      final r = await _functions
          .httpsCallable('addMemberByEmail')
          .call<Map<String, dynamic>>({
            'groupId': groupId.value,
            'entries': [
              for (final e in entries) {'name': e.name, 'email': e.email},
            ],
          });
      final d = r.data;
      return AddMembersResult(
        added: (d['added'] as num).toInt(),
        invited: (d['invited'] as num).toInt(),
        alreadyMembers: (d['alreadyMembers'] as num).toInt(),
        problems: [for (final p in (d['problems'] as List?) ?? const []) '$p'],
      );
    } on FirebaseFunctionsException catch (e) {
      throw switch ((e.code, e.message)) {
        ('failed-precondition', 'email-not-verified') => EmailNotVerified(
          e.message,
        ),
        ('resource-exhausted', _) => RateLimited(e.message),
        ('permission-denied', _) => PermissionDenied(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }

  @override
  Future<void> resendSetupEmail(GroupId groupId, UserId uid) =>
      _call('resendSetupEmail', {'groupId': groupId.value, 'uid': uid.value});

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
    ownerId: d['ownerId'] as String?,
    photoPath: d['photoPath'] as String?,
    timeZone: d['timeZone'] as String? ?? 'America/Chicago',
    settings: settingsFromFirestore(d['settings'] as Map<String, dynamic>?),
    storageBytes: (d['storageBytes'] as num?)?.toInt() ?? 0,
    storageQuotaBytes: (d['storageQuotaBytes'] as num?)?.toInt() ?? 0,
    chatTheme: switch (d['chatTheme']) {
      final Map<String, dynamic> t => ChatTheme(
        bubbleColor: _parseColor(t['bubbleColor'] as String?),
        background:
            ChatBackground.values.asNameMap()[t['background']] ??
            ChatBackground.plain,
        backgroundPath: t['backgroundPath'] as String?,
      ),
      _ => null,
    },
    plan: switch (d['plan']) {
      final Map<String, dynamic> p => GroupPlan(
        tier: PlanTier.tryParse(p['tier'] as String?) ?? PlanTier.free,
        endsAt: _date(p['endsAt']),
        licenseId: p['licenseId'] as String?,
        holderId: p['holderId'] as String?,
      ),
      _ => const GroupPlan(),
    },
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
  playerSummary: d['playerSummary'] as String?,
  pending: d['pending'] as bool? ?? false,
);

int? _parseColor(String? hex) {
  if (hex == null || !hex.startsWith('#') || hex.length != 7) return null;
  final rgb = int.tryParse(hex.substring(1), radix: 16);
  return rgb == null ? null : 0xFF000000 | rgb;
}

GroupSettings settingsFromFirestore(Map<String, dynamic>? d) {
  if (d == null) return const GroupSettings();
  bool flag(String key, {required bool fallback}) =>
      d[key] as bool? ?? fallback;
  return GroupSettings(
    membersCanCreateEvents: flag('membersCanCreateEvents', fallback: false),
    membersCanCreatePolls: flag('membersCanCreatePolls', fallback: true),
    membersCanUploadDocs: flag('membersCanUploadDocs', fallback: true),
    membersCanInvite: flag('membersCanInvite', fallback: true),
    allowMaybe: flag('allowMaybe', fallback: true),
    defaultReminderOffsets: [
      for (final m in (d['defaultReminderOffsets'] as List?) ?? const [1440])
        (m as num).toInt(),
    ],
  );
}

Map<String, Object> settingsToFirestore(GroupSettings s) => {
  'membersCanCreateEvents': s.membersCanCreateEvents,
  'membersCanCreatePolls': s.membersCanCreatePolls,
  'membersCanUploadDocs': s.membersCanUploadDocs,
  'membersCanInvite': s.membersCanInvite,
  'allowMaybe': s.allowMaybe,
  'defaultReminderOffsets': s.defaultReminderOffsets,
};
