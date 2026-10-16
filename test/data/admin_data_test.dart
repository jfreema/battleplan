// Data-layer tests (SPEC §8.1): the super-admin panel's callables and reads.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/admin/data/functions_admin_repository.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_functions.dart';

const _g = GroupId('g1');
const _u = UserId('alex');

void main() {
  late FakeFirebaseFirestore db;
  late FakeFunctions functions;
  late FunctionsAdminRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    functions = FakeFunctions();
    repo = FunctionsAdminRepository(db, functions);
  });

  test('reads the dashboard totals (ADMIN-2)', () async {
    functions.handlers['adminDashboard'] = (_) => <Object?, Object?>{
      'users': 10,
      'teams': 3,
      'openReports': 1,
      'storageBytes': 2048.0,
    };
    final t = await repo.totals();
    expect(t.users, 10);
    expect(t.teams, 3);
    expect(t.openReports, 1);
    expect(t.storageBytes, 2048);
    expect(t.messages, 0);
  });

  test('lists and opens teams (ADMIN-3)', () async {
    functions.handlers['adminListTeams'] = (_) => {
      'rows': [
        {
          'id': 'g1',
          'name': 'Thunder',
          'sport': 'softball',
          'teamType': 'youth',
          'owner': {'uid': 'coach', 'name': 'Jordan'},
          'memberCount': 12,
          'lastMessageAt': '2026-10-01T12:00:00Z',
          'status': 'suspended',
          'createdAt': 1700000000000,
        },
        {'id': 'g2', 'name': 'Other', 'ownerId': 'x', 'ownerName': 'Pat'},
      ],
      'nextCursor': 'g2',
    };
    final page = await repo.listTeams(
      const AdminTeamQuery(query: ' thu ', status: TeamStatus.suspended),
    );
    expect(page.items.first.ownerName, 'Jordan');
    expect(page.items.first.status, TeamStatus.suspended);
    expect(
      page.items.first.lastMessageAt?.toUtc(),
      DateTime.utc(2026, 10, 1, 12),
    );
    expect(page.items.last.ownerId, 'x');
    expect(page.items.last.status, TeamStatus.active);
    expect(page.next!.handle, 'g2');
    expect(functions.lastData('adminListTeams'), {
      'query': 'thu',
      'sort': 'created',
      'status': 'suspended',
      'limit': adminPageSize,
    });
    functions.handlers['adminListTeams'] = (_) => {
      'rows': <Object?>[],
      'nextCursor': '',
    };
    final last = await repo.listTeams(const AdminTeamQuery(), after: page.next);
    expect(last.next, isNull);
    expect((functions.lastData('adminListTeams')! as Map)['cursor'], 'g2');

    functions.handlers['adminGetTeam'] = (_) => {
      'team': {
        'ownerName': 'Jordan',
        'status': 'archived',
        'createdAt': '2026-01-01T00:00:00Z',
      },
      'members': [
        {
          'uid': 'coach',
          'role': 'owner',
          'displayName': 'Jordan',
          'title': 'Head coach',
        },
        {'uid': 'sam', 'displayName': 'Sam', 'pending': true},
      ],
      'players': [
        {'id': 'emma', 'displayName': 'Emma', 'jerseyNumber': '7'},
        {'id': 'jared', 'displayName': 'Jared', 'status': 'pending'},
      ],
      'guardians': [
        {'playerId': 'emma', 'uid': 'maria'},
        {'playerId': 'emma', 'uid': 'emma1', 'relation': 'self'},
      ],
      'invites': [
        {'id': 'K7XP', 'type': 'link', 'useCount': 3, 'maxUses': 10},
        {
          'code': 'EM1',
          'type': 'email',
          'email': 'a@example.com',
          'expiresAt': '2026-11-01T00:00:00Z',
        },
      ],
      'counts': {'events': 4, 'documents': 2, 'polls': 1},
    };
    final detail = await repo.team(_g);
    expect(detail.ownerName, 'Jordan');
    expect(detail.status, TeamStatus.archived);
    expect(detail.members.first.role, MemberRole.owner);
    expect(detail.members.last.pending, isTrue);
    expect(detail.players.first.jerseyNumber, '7');
    // Players without a status are active; links without a relation are
    // guardians (one team type).
    expect(detail.players.first.status, PlayerStatus.active);
    expect(detail.players.last.isPending, isTrue);
    expect(detail.guardians.first.uid, const UserId('maria'));
    expect(detail.guardians.first.relation, PlayerRelation.guardian);
    expect(detail.guardians.last.isSelf, isTrue);
    expect(detail.invites.first.isLink, isTrue);
    expect(detail.invites.first.code, 'K7XP');
    expect(detail.invites.last.email, 'a@example.com');
    expect(detail.eventCount, 4);
    expect(detail.pollCount, 1);
  });

  test(
    'changes teams and players through audited callables (ADMIN-3)',
    () async {
      await repo.openGroup(_g);
      await repo.setGroupSuspended(_g, suspended: true, note: ' spam ');
      expect(functions.lastData('adminSetGroupSuspended'), {
        'groupId': 'g1',
        'suspended': true,
        'note': 'spam',
      });
      await repo.setGroupSuspended(_g, suspended: false, note: ' ');
      expect(
        (functions.lastData('adminSetGroupSuspended')! as Map).containsKey(
          'note',
        ),
        isFalse,
      );
      await repo.setGroupArchived(_g, archived: true);
      await repo.deleteGroup(_g, 'Thunder');
      await repo.updateGroup(
        _g,
        name: ' Thunder ',
        sport: Sport.soccer,
        settings: const GroupSettings(allowMaybe: false),
        chatTheme: const ChatTheme(
          bubbleColor: 0xFF0F8A5F,
          background: ChatBackground.pattern,
        ),
        photoPath: 'groups/g1/avatar/1.jpg',
      );
      final sent = functions.lastData('adminUpdateGroup')! as Map;
      expect(sent['name'], 'Thunder');
      expect(sent['sport'], 'soccer');
      expect((sent['settings'] as Map)['allowMaybe'], isFalse);
      expect(sent['chatTheme'], {
        'bubbleColor': '#0F8A5F',
        'background': 'pattern',
        'backgroundPath': null,
      });
      expect(sent.containsKey('description'), isFalse);
      await repo.updateGroup(_g, chatTheme: const ChatTheme());
      expect(
        ((functions.lastData('adminUpdateGroup')! as Map)['chatTheme']
            as Map)['bubbleColor'],
        isNull,
      );
      await repo.updatePlayer(
        const PlayerId('emma'),
        name: ' Emma ',
        jerseyNumber: ' 7 ',
      );
      expect(functions.lastData('adminUpdatePlayer'), {
        'playerId': 'emma',
        'displayName': 'Emma',
        'jerseyNumber': '7',
      });
      expect(
        functions.calls.map((c) => c.$1),
        containsAll([
          'adminOpenGroup',
          'adminArchiveGroup',
          'adminDeleteGroup',
        ]),
      );
    },
  );

  test('lists, reads, and manages people (ADMIN-4)', () async {
    functions.handlers['adminListUsers'] = (_) => {
      'rows': [
        {
          'id': 'alex',
          'displayName': 'Alex',
          'email': 'a@example.com',
          'status': 'disabled',
          'superAdmin': true,
        },
      ],
    };
    final users = await repo.listUsers(
      const AdminUserQuery(query: 'al', filter: AdminUserFilter.disabled),
    );
    expect(users.items.single.uid, _u);
    expect(users.items.single.status, UserStatus.disabled);
    expect(users.items.single.superAdmin, isTrue);
    expect(users.next, isNull);

    functions.handlers['adminGetUser'] = (_) => {
      'user': {'displayName': 'Alex', 'email': 'a@example.com'},
      'signInMethods': ['password'],
      'teams': [
        {'groupId': 'g1', 'groupName': 'Thunder', 'role': 'admin'},
        {'groupId': 'g2', 'name': 'Hawks'},
      ],
    };
    final detail = await repo.user(_u);
    expect(detail.user.uid, _u);
    expect(detail.signInMethods, ['password']);
    expect(detail.teams.first.name, 'Thunder');
    expect(detail.teams.last.role, MemberRole.member);
    functions.handlers['adminGetUser'] = (_) => {'displayName': 'Flat'};
    expect((await repo.user(_u)).user.displayName, 'Flat');

    functions.handlers['adminCreateUser'] = (_) => {'uid': 'new1'};
    expect(
      await repo.createUser(
        email: ' p@example.com ',
        displayName: ' Pat ',
        groupId: _g,
        role: MemberRole.admin,
      ),
      const UserId('new1'),
    );
    expect(functions.lastData('adminCreateUser'), {
      'email': 'p@example.com',
      'displayName': 'Pat',
      'groupId': 'g1',
      'role': 'admin',
    });
    await repo.createUser(
      email: 'q@example.com',
      displayName: 'Q',
      role: MemberRole.admin,
    );
    expect(
      (functions.lastData('adminCreateUser')! as Map).containsKey('role'),
      isFalse,
    );

    await repo.renameUser(_u, ' Alex K ');
    await repo.addUserToGroup(_u, _g, MemberRole.member);
    expect(functions.lastData('adminUpdateUser'), {
      'uid': 'alex',
      'addToGroup': {'groupId': 'g1', 'role': 'member'},
    });
    await repo.setUserDisabled(_u, disabled: true);
    await repo.revokeSessions(_u);
    await repo.sendPasswordReset(_u);
    await repo.deleteUser(_u);
    await repo.setSuperAdmin(_u, superAdmin: false);
    expect(
      functions.calls.map((c) => c.$1),
      containsAll([
        'adminSetUserDisabled',
        'adminRevokeSessions',
        'adminSendPasswordReset',
        'adminDeleteUser',
        'adminSetSuperAdmin',
      ]),
    );
  });

  test('lists and resolves reports (ADMIN-5)', () async {
    functions.handlers['adminListReports'] = (_) => {
      'rows': [
        {
          'id': 'r1',
          'groupId': 'g1',
          'groupName': 'Thunder',
          'targetType': 'user',
          'reason': 'harassment',
          'subjectName': 'Sam',
          'reporterName': 'Alex',
          'status': 'actioned',
          'resolution': 'removeMember',
        },
        {'id': 'r2', 'targetType': 'mystery', 'reason': 'mystery'},
      ],
    };
    final reports = await repo.listReports(ReportStatus.actioned);
    expect(reports.items.first.targetType, ReportTargetType.user);
    expect(reports.items.first.status, ReportStatus.actioned);
    expect(reports.items.last.targetType, ReportTargetType.message);
    expect(reports.items.last.reason, ReportReason.other);
    await repo.resolveReport('r1', AdminReportAction.dismiss, ' ok ');
    expect(functions.lastData('adminResolveReport'), {
      'reportId': 'r1',
      'action': 'dismiss',
      'note': 'ok',
    });
  });

  test('maps refusals to failures', () async {
    for (final (code, message, type) in [
      ('failed-precondition', 'last-super-admin', isA<LastSuperAdmin>()),
      ('failed-precondition', 'owner-must-transfer', isA<OwnerMustTransfer>()),
      ('failed-precondition', 'team-archived', isA<ActionRefused>()),
      ('invalid-argument', 'bad', isA<InvalidInput>()),
      ('permission-denied', 'no', isA<PermissionDenied>()),
      ('not-found', 'gone', isA<NotFound>()),
      ('already-exists', 'taken', isA<EmailAlreadyInUse>()),
      ('resource-exhausted', 'slow', isA<RateLimited>()),
      ('unavailable', 'offline', isA<Offline>()),
      ('internal', 'boom', isA<UnknownFailure>()),
    ]) {
      functions.fail('adminDeleteUser', code, message);
      await expectLater(repo.deleteUser(_u), throwsA(type));
    }
  });

  test('reads the audit log with filters, newest first (ADMIN-6)', () async {
    for (var i = 0; i < 3; i++) {
      await db.doc('auditLogs/a$i').set({
        'actorId': 'admin',
        'action': i == 2 ? 'group.delete' : 'user.disable',
        'groupId': i == 2 ? 'g1' : null,
        'targetType': 'user',
        'targetId': 'alex',
        'before': {
          'status': 'active',
          'at': Timestamp.fromDate(DateTime.utc(2026)),
          'nested': <Object?, Object?>{'x': 1},
        },
        'after': {'status': 'disabled'},
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1 + i, 12)),
      });
    }
    final all = await repo.auditLog(const AuditFilter(), limit: 2);
    expect(all.items.map((e) => e.id), ['a2', 'a1']);
    expect(all.items.first.groupId, _g);
    expect(all.items.last.groupId, isNull);
    expect(all.items.first.before!['at'], isA<String>());
    expect(all.items.first.before!['nested'], {'x': 1});
    expect(all.items.first.after, {'status': 'disabled'});
    final rest = await repo.auditLog(
      const AuditFilter(),
      after: all.next,
      limit: 2,
    );
    expect(rest.items.map((e) => e.id), ['a0']);
    final filtered = await repo.auditLog(
      AuditFilter(
        actorId: 'admin',
        action: 'user.disable',
        from: DateTime(2026, 10),
        until: DateTime(2026, 10),
      ),
    );
    expect(filtered.items.map((e) => e.id), ['a0']);
    final byTeam = await repo.auditLog(const AuditFilter(groupId: _g));
    expect(byTeam.items.map((e) => e.id), ['a2']);
  });

  test('watches and updates config/app (ADMIN-7)', () async {
    expect(await repo.watchConfig().first, const AppConfig());
    await db.doc('config/app').set({
      'allowUserGroupCreation': false,
      'maxUploadMb': 5,
      'supportEmail': 'help@example.com',
      'emailAdminAlerts': false,
      'announcementBanner': {
        'text': 'Maintenance',
        'severity': 'warning',
        'expiresAt': Timestamp.fromDate(DateTime.utc(2026, 11)),
      },
    });
    final config = await repo.watchConfig().first;
    expect(config.allowUserGroupCreation, isFalse);
    expect(config.maxUploadMb, 5);
    expect(config.emailAdminAlerts, isFalse);
    expect(const AppConfig().emailAdminAlerts, isTrue);
    expect(config.announcementBanner!.severity, BannerSeverity.warning);
    expect(
      appConfigFromFirestore(const {
        'announcementBanner': {'text': 'x'},
      }).announcementBanner,
      isNull,
    );

    await repo.updateConfig(config.copyWith(supportEmail: ' s@example.com '));
    final sent = functions.lastData('adminUpdateConfig')! as Map;
    expect(sent['supportEmail'], 's@example.com');
    expect(sent['emailAdminAlerts'], isFalse);
    expect(
      (sent['announcementBanner'] as Map)['expiresAt'],
      '2026-11-01T00:00:00.000Z',
    );
    await repo.updateConfig(const AppConfig());
    expect(
      (functions.lastData('adminUpdateConfig')! as Map)['announcementBanner'],
      isNull,
    );
  });
}
