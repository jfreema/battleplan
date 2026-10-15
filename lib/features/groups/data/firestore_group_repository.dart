import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/live_pages.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Owns `groups` (ARCH §5.2 collection ownership).
class FirestoreGroupRepository implements GroupRepository {
  new(this._db, this._functions, this._storage, {this.currentUid});

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  /// Who's signed in, to tag the logo and chat background they upload so
  /// Media can say who added them (STORE-5).
  final String? Function()? currentUid;

  SettableMetadata _jpeg() => SettableMetadata(
    contentType: 'image/jpeg',
    customMetadata: switch (currentUid?.call()) {
      final uid? => {'uploadedBy': uid},
      null => null,
    },
  );

  @override
  Future<GroupId> createGroup({
    required String name,
    required Sport sport,
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
            'timeZone': timeZone,
            'color': ?color,
            if (description != null && description.isNotEmpty)
              'description': description,
          });
      return GroupId(result.data['groupId'] as String);
    } on FirebaseFunctionsException catch (e) {
      final message = serverMessage(e.message);
      throw switch ((e.code, message)) {
        ('failed-precondition', 'email-not-verified') => EmailNotVerified(
          message,
        ),
        ('failed-precondition', 'too-many-teams') => TooManyTeams(message),
        ('resource-exhausted', _) => RateLimited(message),
        ('permission-denied', _) => PermissionDenied(message),
        ('invalid-argument', _) => InvalidInput(message),
        ('unavailable' || 'deadline-exceeded', _) => Offline(message),
        _ => UnknownFailure('${e.code}: $message'),
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
  Future<String> uploadLogoFile(GroupId id, Uint8List jpegBytes) async {
    final path =
        'groups/${id.value}/avatar/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _storage.ref(path).putData(jpegBytes, _jpeg());
      return path;
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'unauthorized' || 'permission-denied' => PermissionDenied(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> uploadLogo(GroupId id, Uint8List jpegBytes) async {
    final path = await uploadLogoFile(id, jpegBytes);
    try {
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
      await _storage.ref(path).putData(jpegBytes, _jpeg());
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

  @override
  Future<void> setStorageQuota(GroupId id, int quotaMb) =>
      _call('adminSetGroupQuota', {'groupId': id.value, 'quotaMb': quotaMb});

  Future<void> _call(String name, Map<String, Object?> data) async {
    try {
      await _functions.httpsCallable(name).call<void>(data);
    } on FirebaseFunctionsException catch (e) {
      final message = serverMessage(e.message);
      throw switch ((e.code, message)) {
        ('failed-precondition', 'owner-must-transfer') => OwnerMustTransfer(
          message,
        ),
        ('invalid-argument', _) => InvalidInput(message),
        ('permission-denied', _) => PermissionDenied(message),
        ('not-found', _) => NotFound(message),
        ('unavailable' || 'deadline-exceeded', _) => Offline(message),
        _ => UnknownFailure('${e.code}: $message'),
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
  Stream<List<Membership>> watchRoster(GroupId groupId) {
    // Every member, 100 to a page, each page live: a big team's roster
    // isn't cut at the query cap (TEAM-3).
    final q = _db
        .collection(Collections.groupMembers)
        .where('groupId', isEqualTo: groupId.value)
        .orderBy(FieldPath.documentId);
    return livePages<Membership, String>((after) {
      final page = after == null ? q : q.startAfter([after]);
      return page
          .limit(Limits.queryLimitMax)
          .snapshots()
          .map(
            (snap) => (
              items: [
                for (final d in snap.docs) membershipFromFirestore(d.data()),
              ],
              next: snap.docs.length < Limits.queryLimitMax
                  ? null
                  : snap.docs.last.id,
            ),
          );
    });
  }

  @override
  Future<void> updateMember(
    GroupId groupId,
    UserId uid, {
    MemberRole? role,
    String? title,
    bool clearTitle = false,
    bool? coach,
  }) => _call('updateGroupMember', {
    'groupId': groupId.value,
    'uid': uid.value,
    if (role != null) 'role': role.value,
    if (clearTitle) 'title': null else 'title': ?title,
    'coach': ?coach,
  });

  @override
  Future<void> markRead(GroupId groupId, UserId uid, {DateTime? upTo}) async {
    try {
      await _db
          .collection(Collections.groupMembers)
          .doc(CompositeIds.groupMember(groupId, uid))
          .update({
            'lastReadAt': upTo == null
                ? FieldValue.serverTimestamp()
                : Timestamp.fromDate(upTo),
          });
    } on FirebaseException {
      // A missed read marker only leaves a count up; the next one fixes it.
    }
  }

  @override
  Future<void> setNotificationLevel(
    GroupId groupId,
    UserId uid,
    NotificationLevel level,
  ) => _updateMine(groupId, uid, {'notificationLevel': level.value});

  @override
  Future<void> setMutedUntil(GroupId groupId, UserId uid, DateTime? until) =>
      _updateMine(groupId, uid, {
        'mutedUntil': until == null ? null : Timestamp.fromDate(until),
      });

  @override
  Future<void> setContact(
    GroupId groupId,
    UserId uid, {
    String? phone,
    String? email,
  }) => _updateMine(groupId, uid, {
    'contactPhone': _shared(phone),
    'contactEmail': _shared(email),
  });

  /// Members edit their own notification settings directly; rules allow
  /// only those fields (ARCH §6.3).
  Future<void> _updateMine(
    GroupId groupId,
    UserId uid,
    Map<String, Object?> fields,
  ) async {
    try {
      await _db
          .collection(Collections.groupMembers)
          .doc(CompositeIds.groupMember(groupId, uid))
          .update(fields);
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'not-found' => NotFound(e.code),
        'unavailable' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
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
        addedPeople: _people(d['addedPeople']),
        invitedPeople: _people(d['invitedPeople']),
        problems: [for (final p in (d['problems'] as List?) ?? const []) '$p'],
      );
    } on FirebaseFunctionsException catch (e) {
      final message = serverMessage(e.message);
      throw switch ((e.code, message)) {
        ('failed-precondition', 'email-not-verified') => EmailNotVerified(
          message,
        ),
        ('resource-exhausted', _) => RateLimited(message),
        ('permission-denied', _) => PermissionDenied(message),
        _ => UnknownFailure('${e.code}: $message'),
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
      final message = serverMessage(e.message);
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(message),
        'not-found' => NotFound(message),
        'invalid-argument' => InvalidInput(message),
        'unavailable' || 'deadline-exceeded' => Offline(message),
        _ => UnknownFailure('${e.code}: $message'),
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
    kind: GroupKind.tryParse(d['kind'] as String?) ?? GroupKind.team,
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
    // A team written before limits existed has none; it gets the default
    // (STORE-1). A quota a super admin set is kept as is (STORE-6).
    storageQuotaBytes: switch (d['storageQuotaBytes']) {
      final num q when q > 0 => q.toInt(),
      _ => Limits.defaultStorageQuotaMb * bytesPerMb,
    },
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
    pinnedMessageIds: [
      for (final id in (d['pinnedMessageIds'] as List?) ?? const [])
        if (id is String) id,
    ],
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
  photoPath: d['photoPath'] as String?,
  playerSummary: d['playerSummary'] as String?,
  pending: d['pending'] as bool? ?? false,
  contactPhone: _shared(d['contactPhone']),
  contactEmail: _shared(d['contactEmail']),
  coach: d['coach'] as bool?,
);

/// A shared contact field (TEAM-10): its text, or null when it's missing
/// or blank.
String? _shared(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

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

/// `[{name, email}]` from addMemberByEmail (TEAM-7).
List<({String name, String email})> _people(Object? list) => [
  for (final p in ((list as List?) ?? const []).cast<Map<Object?, Object?>>())
    (name: '${p['name'] ?? ''}', email: '${p['email'] ?? ''}'),
];
