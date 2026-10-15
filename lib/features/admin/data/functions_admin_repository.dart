import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/domain/admin_repository.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// The admin callables (`functions/src/admin`), plus the two collections
/// the app reads directly: `auditLogs` (super admins, ADMIN-6) and
/// `config/app` (everyone signed in, ADMIN-7). Callables send dates as ISO
/// 8601 and page with the last row's ID (`nextCursor`).
class FunctionsAdminRepository implements AdminRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  DocumentReference<Map<String, dynamic>> get _config =>
      _db.collection(Collections.config).doc('app');

  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, Object?> data = const {},
  ]) async {
    try {
      final r = await _functions.httpsCallable(name).call<Object?>(data);
      return _map(r.data);
    } on FirebaseFunctionsException catch (e) {
      throw switch ((e.code, e.message)) {
        ('failed-precondition', 'last-super-admin') => LastSuperAdmin(
          e.message,
        ),
        ('failed-precondition', 'owner-must-transfer') => OwnerMustTransfer(
          e.message,
        ),
        ('failed-precondition', final reason?) => ActionRefused(reason),
        ('invalid-argument' || 'failed-precondition', _) => InvalidInput(
          e.message,
        ),
        ('permission-denied', _) => PermissionDenied(e.message),
        ('not-found', _) => NotFound(e.message),
        ('already-exists', _) => EmailAlreadyInUse(e.message),
        ('resource-exhausted', _) => RateLimited(e.message),
        ('unavailable' || 'deadline-exceeded', _) => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }

  /// A list callable's rows and the cursor for the next page.
  Future<AdminPage<T>> _page<T>(
    String name,
    Map<String, Object?> data,
    T Function(Map<String, dynamic>) read, {
    PageCursor? after,
  }) async {
    final r = await _call(name, {
      ...data,
      if (after != null) 'cursor': after.handle,
    });
    final next = r['nextCursor'];
    return (
      items: [for (final row in _list(r['rows'])) read(_map(row))],
      next: next is String && next.isNotEmpty ? PageCursor(next) : null,
    );
  }

  @override
  Future<AdminTotals> totals() async {
    final r = await _call('adminDashboard');
    return AdminTotals(
      users: _int(r['users']),
      teams: _int(r['teams']),
      newTeams: _int(r['newTeams']),
      activeTeams: _int(r['activeTeams']),
      messages: _int(r['messages']),
      storageBytes: _int(r['storageBytes']),
      openReports: _int(r['openReports']),
    );
  }

  @override
  Future<AdminPage<AdminTeamRow>> listTeams(
    AdminTeamQuery query, {
    PageCursor? after,
    int limit = adminPageSize,
  }) => _page(
    'adminListTeams',
    {
      if (query.query.trim().isNotEmpty) 'query': query.query.trim(),
      'sort': query.sort.name,
      'status': ?query.status?.name,
      'limit': limit,
    },
    _teamRow,
    after: after,
  );

  @override
  Future<AdminTeamDetail> team(GroupId id) async {
    final r = await _call('adminGetTeam', {'groupId': id.value});
    final team = _map(r['team']);
    final counts = _map(r['counts']);
    return AdminTeamDetail(
      id: id,
      ownerName: _str(r['ownerName'] ?? team['ownerName']),
      status: _teamStatus(r['status'] ?? team['status']),
      createdAt: _date(team['createdAt']),
      members: [for (final m in _list(r['members'])) _member(id, _map(m))],
      players: [
        for (final p in _list(r['players']))
          Player(
            id: PlayerId(_str(_map(p)['id'])),
            groupId: id,
            displayName: _str(_map(p)['displayName']),
            jerseyNumber: _map(p)['jerseyNumber'] as String?,
            status:
                PlayerStatus.tryParse(_map(p)['status'] as String?) ??
                PlayerStatus.active,
          ),
      ],
      guardians: [
        for (final g in _list(r['guardians']))
          GuardianLink(
            playerId: PlayerId(_str(_map(g)['playerId'])),
            groupId: id,
            uid: UserId(_str(_map(g)['uid'])),
            relation:
                PlayerRelation.tryParse(_map(g)['relation'] as String?) ??
                PlayerRelation.guardian,
          ),
      ],
      invites: [
        for (final i in _list(r['invites']))
          AdminInvite(
            code: _str(_map(i)['code'] ?? _map(i)['id']),
            isLink: _map(i)['type'] != 'email',
            email: _map(i)['email'] as String?,
            useCount: _int(_map(i)['useCount']),
            maxUses: (_map(i)['maxUses'] as num?)?.toInt(),
            expiresAt: _date(_map(i)['expiresAt']),
            createdAt: _date(_map(i)['createdAt']),
          ),
      ],
      recentMessages: [
        for (final m in _list(r['recentMessages']))
          AdminMessage(
            id: _str(_map(m)['id']),
            authorName: _str(_map(m)['authorName']),
            text: _str(_map(m)['text']),
            photoCount: _int(_map(m)['photoCount']),
            createdAt: _date(_map(m)['createdAt']),
          ),
      ],
      eventCount: _int(counts['events']),
      documentCount: _int(counts['documents']),
      pollCount: _int(counts['polls']),
    );
  }

  @override
  Future<void> openGroup(GroupId id) =>
      _call('adminOpenGroup', {'groupId': id.value});

  @override
  Future<void> setGroupSuspended(
    GroupId id, {
    required bool suspended,
    String? note,
  }) => _call('adminSetGroupSuspended', {
    'groupId': id.value,
    'suspended': suspended,
    if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
  });

  @override
  Future<void> setGroupArchived(GroupId id, {required bool archived}) =>
      _call('adminArchiveGroup', {'groupId': id.value, 'archived': archived});

  @override
  Future<void> deleteGroup(GroupId id, String confirmName) => _call(
    'adminDeleteGroup',
    {'groupId': id.value, 'confirmName': confirmName},
  );

  @override
  Future<void> updateGroup(
    GroupId id, {
    String? name,
    String? description,
    String? color,
    Sport? sport,
    String? timeZone,
    GroupSettings? settings,
    ChatTheme? chatTheme,
    String? photoPath,
  }) => _call('adminUpdateGroup', {
    'groupId': id.value,
    'name': ?name?.trim(),
    'description': ?description?.trim(),
    'color': ?color,
    'sport': ?sport?.value,
    'timeZone': ?timeZone,
    if (settings != null)
      'settings': {
        'membersCanCreateEvents': settings.membersCanCreateEvents,
        'membersCanCreatePolls': settings.membersCanCreatePolls,
        'membersCanUploadDocs': settings.membersCanUploadDocs,
        'membersCanInvite': settings.membersCanInvite,
        'allowMaybe': settings.allowMaybe,
        'defaultReminderOffsets': settings.defaultReminderOffsets,
      },
    if (chatTheme != null)
      'chatTheme': {
        'bubbleColor': _hex(chatTheme.bubbleColor),
        'background': chatTheme.background.name,
        'backgroundPath': chatTheme.backgroundPath,
      },
    'photoPath': ?photoPath,
  });

  @override
  Future<void> updatePlayer(
    PlayerId id, {
    required String name,
    String? jerseyNumber,
  }) => _call('adminUpdatePlayer', {
    'playerId': id.value,
    'displayName': name.trim(),
    'jerseyNumber': jerseyNumber?.trim() ?? '',
  });

  @override
  Future<AdminPage<AdminUserRow>> listUsers(
    AdminUserQuery query, {
    PageCursor? after,
    int limit = adminPageSize,
  }) => _page(
    'adminListUsers',
    {
      if (query.query.trim().isNotEmpty) 'query': query.query.trim(),
      'filter': ?query.filter?.name,
      'limit': limit,
    },
    _userRow,
    after: after,
  );

  @override
  Future<AdminUserDetail> user(UserId uid) async {
    final r = await _call('adminGetUser', {'uid': uid.value});
    final user = r['user'] is Map ? _map(r['user']) : r;
    return AdminUserDetail(
      user: _userRow({'uid': uid.value, ...user}),
      signInMethods: [for (final m in _list(r['signInMethods'])) '$m'],
      teams: [
        for (final t in _list(r['teams']))
          AdminUserTeam(
            groupId: GroupId(_str(_map(t)['groupId'])),
            name: _str(_map(t)['name'] ?? _map(t)['groupName']),
            role:
                MemberRole.tryParse(_map(t)['role'] as String?) ??
                MemberRole.member,
          ),
      ],
    );
  }

  @override
  Future<UserId> createUser({
    required String email,
    required String displayName,
    GroupId? groupId,
    MemberRole? role,
  }) async {
    final r = await _call('adminCreateUser', {
      'email': email.trim(),
      'displayName': displayName.trim(),
      'groupId': ?groupId?.value,
      if (groupId != null) 'role': ?role?.value,
    });
    return UserId(_str(r['uid']));
  }

  @override
  Future<void> renameUser(UserId uid, String displayName) => _call(
    'adminUpdateUser',
    {'uid': uid.value, 'displayName': displayName.trim()},
  );

  @override
  Future<void> addUserToGroup(UserId uid, GroupId groupId, MemberRole role) =>
      _call('adminUpdateUser', {
        'uid': uid.value,
        'addToGroup': {'groupId': groupId.value, 'role': role.value},
      });

  @override
  Future<void> setUserDisabled(UserId uid, {required bool disabled}) =>
      _call('adminSetUserDisabled', {'uid': uid.value, 'disabled': disabled});

  @override
  Future<void> revokeSessions(UserId uid) =>
      _call('adminRevokeSessions', {'uid': uid.value});

  @override
  Future<void> sendPasswordReset(UserId uid) =>
      _call('adminSendPasswordReset', {'uid': uid.value});

  @override
  Future<void> deleteUser(UserId uid) =>
      _call('adminDeleteUser', {'uid': uid.value});

  @override
  Future<void> setSuperAdmin(UserId uid, {required bool superAdmin}) =>
      _call('adminSetSuperAdmin', {'uid': uid.value, 'superAdmin': superAdmin});

  @override
  Future<AdminPage<AdminReport>> listReports(
    ReportStatus status, {
    PageCursor? after,
    int limit = adminPageSize,
  }) => _page(
    'adminListReports',
    {'status': status.value, 'limit': limit},
    _report,
    after: after,
  );

  @override
  Future<void> resolveReport(
    String reportId,
    AdminReportAction action,
    String note,
  ) => _call('adminResolveReport', {
    'reportId': reportId,
    'action': action.name,
    'note': note.trim(),
  });

  @override
  Future<AdminPage<AuditEntry>> auditLog(
    AuditFilter filter, {
    PageCursor? after,
    int limit = adminPageSize,
  }) async {
    // Each filter is an equality or a range on createdAt, newest first;
    // each combination has its index (firestore.indexes.json).
    Query<Map<String, dynamic>> q = _db.collection(Collections.auditLogs);
    if (filter.actorId case final actor?) {
      q = q.where('actorId', isEqualTo: actor);
    }
    if (filter.action case final action?) {
      q = q.where('action', isEqualTo: action);
    }
    if (filter.groupId case final group?) {
      q = q.where('groupId', isEqualTo: group.value);
    }
    if (filter.from case final from?) {
      q = q.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime(from.year, from.month, from.day),
        ),
      );
    }
    if (filter.until case final until?) {
      q = q.where(
        'createdAt',
        isLessThan: Timestamp.fromDate(
          DateTime(until.year, until.month, until.day + 1),
        ),
      );
    }
    q = q.orderBy('createdAt', descending: true);
    if (after != null) {
      q = q.startAfterDocument(after.handle as DocumentSnapshot<Object?>);
    }
    try {
      final snap = await q.limit(limit).get();
      return (
        items: [for (final d in snap.docs) _audit(d.id, d.data())],
        next: snap.docs.length < limit ? null : PageCursor(snap.docs.last),
      );
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'unavailable' => Offline(e.code),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }

  @override
  Stream<AppConfig> watchConfig() => _config.snapshots().map(
    (s) => s.exists ? appConfigFromFirestore(s.data()!) : const AppConfig(),
  );

  @override
  Future<void> updateConfig(AppConfig config) {
    final banner = config.announcementBanner;
    return _call('adminUpdateConfig', {
      'allowUserGroupCreation': config.allowUserGroupCreation,
      'maxGroupsCreatedPerUserPerDay': config.maxGroupsCreatedPerUserPerDay,
      'defaultStorageQuotaMb': config.defaultStorageQuotaMb,
      'maxUploadMb': config.maxUploadMb,
      'supportEmail': config.supportEmail.trim(),
      'announcementBanner': banner == null
          ? null
          : {
              'text': banner.text.trim(),
              'severity': banner.severity.name,
              'expiresAt': banner.expiresAt.toUtc().toIso8601String(),
            },
    });
  }
}

/// A palette color as the team docs store it, `#RRGGBB`, or null.
String? _hex(int? argb) => argb == null
    ? null
    : '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Reads `config/app` (ARCH §6.2). Missing fields keep the defaults.
AppConfig appConfigFromFirestore(Map<String, dynamic> d) {
  const defaults = AppConfig();
  final banner = d['announcementBanner'];
  final expires = banner is Map ? _date(banner['expiresAt']) : null;
  return AppConfig(
    allowUserGroupCreation:
        d['allowUserGroupCreation'] as bool? ?? defaults.allowUserGroupCreation,
    maxGroupsCreatedPerUserPerDay:
        (d['maxGroupsCreatedPerUserPerDay'] as num?)?.toInt() ??
        defaults.maxGroupsCreatedPerUserPerDay,
    defaultStorageQuotaMb:
        (d['defaultStorageQuotaMb'] as num?)?.toInt() ??
        defaults.defaultStorageQuotaMb,
    maxUploadMb: (d['maxUploadMb'] as num?)?.toInt() ?? defaults.maxUploadMb,
    supportEmail: d['supportEmail'] as String? ?? '',
    announcementBanner: banner is Map && expires != null
        ? Announcement(
            text: _str(banner['text']),
            severity:
                BannerSeverity.values.asNameMap()[banner['severity']] ??
                BannerSeverity.info,
            expiresAt: expires,
          )
        : null,
  );
}

AdminTeamRow _teamRow(Map<String, dynamic> r) {
  final owner = r['owner'] is Map
      ? _map(r['owner'])
      : const <String, dynamic>{};
  return AdminTeamRow(
    id: GroupId(_str(r['id'])),
    name: _str(r['name']),
    sport: Sport.tryParse(r['sport'] as String?) ?? Sport.other,
    ownerId: (owner['uid'] ?? r['ownerId']) as String?,
    ownerName: _str(owner['name'] ?? r['ownerName']),
    memberCount: _int(r['memberCount']),
    lastMessageAt: _date(r['lastMessageAt']),
    storageBytes: _int(r['storageBytes']),
    storageQuotaBytes: _int(r['storageQuotaBytes']),
    status: _teamStatus(r['status']),
    createdAt: _date(r['createdAt']),
  );
}

AdminUserRow _userRow(Map<String, dynamic> r) => AdminUserRow(
  uid: UserId(_str(r['uid'] ?? r['id'])),
  displayName: _str(r['displayName']),
  email: r['email'] as String?,
  status: UserStatus.tryParse(r['status'] as String?) ?? UserStatus.active,
  superAdmin: r['superAdmin'] == true,
  createdAt: _date(r['createdAt']),
  lastActiveAt: _date(r['lastActiveAt']),
);

Membership _member(GroupId id, Map<String, dynamic> m) => Membership(
  groupId: id,
  uid: UserId(_str(m['uid'])),
  role: MemberRole.tryParse(m['role'] as String?) ?? MemberRole.member,
  displayName: _str(m['displayName']),
  title: m['title'] as String?,
  playerSummary: m['playerSummary'] as String?,
  pending: m['pending'] == true,
);

AdminReport _report(Map<String, dynamic> r) => AdminReport(
  id: _str(r['id']),
  groupId: GroupId(_str(r['groupId'])),
  groupName: _str(r['groupName']),
  targetType:
      ReportTargetType.values.asNameMap()[r['targetType']] ??
      ReportTargetType.message,
  targetId: _str(r['targetId']),
  reason: ReportReason.tryParse(r['reason'] as String?) ?? ReportReason.other,
  subjectId: _str(r['subjectId']),
  subjectName: _str(r['subjectName']),
  excerpt: _str(r['excerpt']),
  details: r['details'] as String?,
  reporterId: _str(r['reporterId']),
  reporterName: _str(r['reporterName']),
  status: ReportStatus.tryParse(r['status'] as String?) ?? ReportStatus.open,
  resolution: r['resolution'] as String?,
  note: r['note'] as String?,
  createdAt: _date(r['createdAt']),
);

AuditEntry _audit(String id, Map<String, dynamic> d) => AuditEntry(
  id: id,
  actorId: _str(d['actorId']),
  action: _str(d['action']),
  groupId: d['groupId'] is String ? GroupId(d['groupId'] as String) : null,
  targetType: _str(d['targetType']),
  targetId: _str(d['targetId']),
  before: d['before'] is Map ? _plain(_map(d['before'])) : null,
  after: d['after'] is Map ? _plain(_map(d['after'])) : null,
  createdAt: _date(d['createdAt']),
);

TeamStatus _teamStatus(Object? v) =>
    TeamStatus.values.asNameMap()[v] ?? TeamStatus.active;

/// Callable results arrive as `Map<Object?, Object?>`.
Map<String, dynamic> _map(Object? v) =>
    v is Map ? v.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{};

List<Object?> _list(Object? v) => v is List ? v : const [];

String _str(Object? v) => v is String ? v : '';

int _int(Object? v) => v is num ? v.toInt() : 0;

/// A date as callables send it (ISO 8601) or as Firestore stores it.
DateTime? _date(Object? v) => switch (v) {
  final Timestamp t => t.toDate(),
  final String s => DateTime.tryParse(s)?.toLocal(),
  final num ms => DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
  _ => null,
};

/// Audit values with their timestamps as ISO 8601, so they show as text.
Map<String, Object?> _plain(Map<String, dynamic> m) => {
  for (final e in m.entries)
    e.key: switch (e.value) {
      final Timestamp t => t.toDate().toIso8601String(),
      final Map<Object?, Object?> inner => _plain(_map(inner)),
      final Object? other => other,
    },
};
