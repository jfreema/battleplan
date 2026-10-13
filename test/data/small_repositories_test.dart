// Data-layer tests (SPEC §8.1 Maintainability: >= 80% coverage of the
// domain and data layers) against an in-memory Firestore and fake Functions.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/data/prefs_chat_queue_store.dart';
import 'package:battleplan/features/chat/domain/chat_queue_store.dart';
import 'package:battleplan/features/groups/data/functions_invite_repository.dart';
import 'package:battleplan/features/groups/data/functions_media_repository.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/domain/media.dart';
import 'package:battleplan/features/notifications/data/firestore_device_repository.dart';
import 'package:battleplan/features/notifications/data/firestore_notification_repository.dart';
import 'package:battleplan/features/polls/data/firestore_poll_repository.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/safety/data/firestore_safety_repository.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:battleplan/features/settings/data/shared_prefs_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../helpers/fake_functions.dart';

const _g = GroupId('g1');
const _me = UserId('u1');

FirebaseException _fs(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  late FakeFirebaseFirestore db;
  late FakeFunctions functions;

  setUp(() {
    db = FakeFirebaseFirestore();
    functions = FakeFunctions();
  });

  group('FirestoreDeviceRepository', () {
    test(
      'registers the device with a capped app version, and removes it',
      () async {
        final repo = FirestoreDeviceRepository(db);
        await repo.register(
          'install1',
          uid: 'u1',
          token: 't1',
          platform: DevicePlatform.android,
          appVersion: 'x' * 40,
        );
        final d = (await db.doc('devices/install1').get()).data()!;
        expect(d['uid'], 'u1');
        expect(d['platform'], 'android');
        expect((d['appVersion'] as String).length, 32);
        await repo.register(
          'install1',
          uid: 'u1',
          token: 't2',
          platform: DevicePlatform.web,
          appVersion: '1.0.0',
        );
        expect(
          (await db.doc('devices/install1').get()).data()!['appVersion'],
          '1.0.0',
        );
        await repo.remove('install1');
        expect((await db.doc('devices/install1').get()).exists, isFalse);
      },
    );

    test('maps refusals to failures', () async {
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('unavailable', isA<Offline>()),
        ('aborted', isA<UnknownFailure>()),
      ]) {
        final db = FakeFirebaseFirestore();
        final repo = FirestoreDeviceRepository(db);
        final doc = db.doc('devices/x');
        whenCalling(Invocation.method(#delete, null))
            .on(doc)
            .thenThrow(_fs(code));
        await expectLater(repo.remove('x'), throwsA(type));
      }
    });
  });

  group('FirestoreNotificationRepository', () {
    Future<void> add(
      String id, {
      bool read = false,
      int minute = 0,
      String uid = 'u1',
    }) => db.doc('notifications/$id').set({
      'uid': uid,
      'groupId': 'g1',
      'type': 'message',
      'title': 'Thunder',
      'body': 'Alex: hi',
      'route': '/g/g1/chat',
      'actorId': 'alex',
      'read': read,
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1, 12, minute)),
    });

    test('pages newest first, counts unread, and marks read', () async {
      final repo = FirestoreNotificationRepository(db);
      for (var i = 0; i < 5; i++) {
        await add('n$i', minute: i, read: i == 0);
      }
      await add('other', uid: 'u2');

      final first = await repo.watchNewest(_me, limit: 3).first;
      expect(first.items.map((n) => n.id), ['n4', 'n3', 'n2']);
      expect(first.items.first.kind, NotifyKind.message);
      expect(first.items.first.actorId, 'alex');
      expect(
        first.items.first.createdAt?.toUtc(),
        DateTime.utc(2026, 10, 1, 12, 4),
      );
      expect(first.next, isNotNull);
      final older = await repo.loadOlder(_me, first.next!, limit: 3);
      expect(older.items.map((n) => n.id), ['n1', 'n0']);
      expect(older.next, isNull);

      expect(await repo.countUnread(_me), 4);
      await repo.markRead('n4');
      expect(await repo.countUnread(_me), 3);
      await repo.markAllRead(_me);
      expect(await repo.countUnread(_me), 0);
      expect(await repo.countUnread(const UserId('u2')), 1);
      // Nothing left: one empty round.
      await repo.markAllRead(_me);
    });

    test('marks more than one batch as read', () async {
      final repo = FirestoreNotificationRepository(db);
      for (var i = 0; i < 120; i++) {
        await add('n$i');
      }
      await repo.markAllRead(_me);
      expect(await repo.countUnread(_me), 0);
    });

    test('reads a sparse item with defaults', () {
      final n = notificationFromFirestore('x', const {});
      expect(n.title, '');
      expect(n.read, isFalse);
      expect(n.createdAt, isNull);
    });

    test('maps refusals to failures', () async {
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('not-found', isA<NotFound>()),
        ('unavailable', isA<Offline>()),
        ('internal', isA<UnknownFailure>()),
      ]) {
        final db = FakeFirebaseFirestore();
        final repo = FirestoreNotificationRepository(db);
        final doc = db.collection('notifications').doc('n1');
        whenCalling(Invocation.method(#update, null))
            .on(doc)
            .thenThrow(_fs(code));
        await expectLater(repo.markRead('n1'), throwsA(type));
      }
    });
  });

  group('FunctionsMediaRepository', () {
    test('lists the team media largest first, and deletes', () async {
      functions.handlers['listTeamMedia'] = (_) => {
        'items': [
          {
            'path': 'a',
            'size': 10,
            'kind': 'photo',
            'createdAt': '2026-10-01T00:00:00Z',
          },
          {
            'path': 'b',
            'size': 30,
            'kind': 'brandNew',
            'createdAt': 1700000000000,
          },
          {'path': 'c', 'kind': 'document', 'documentName': 'Plan'},
        ],
        'truncated': true,
        'storageBytes': 40,
        'storageQuotaBytes': 100,
      };
      final repo = FunctionsMediaRepository(functions);
      final media = await repo.list(_g);
      expect(media.items.map((i) => i.path), ['b', 'a', 'c']);
      expect(media.items.first.kind, MediaKind.other);
      expect(media.items.first.createdAt, isNotNull);
      expect(media.items[1].createdAt, DateTime.utc(2026, 10));
      expect(media.items.last.createdAt, isNull);
      expect(media.truncated, isTrue);
      expect(media.storageQuotaBytes, 100);
      expect(functions.lastData('listTeamMedia'), {'groupId': 'g1'});

      await repo.delete(_g, 'groups/g1/x.jpg');
      expect(functions.lastData('deleteTeamMedia'), {
        'groupId': 'g1',
        'path': 'groups/g1/x.jpg',
      });
      expect(
        (await FunctionsMediaRepository(FakeFunctions()).list(_g)).items,
        isEmpty,
      );
    });

    test('maps refusals to failures', () async {
      final repo = FunctionsMediaRepository(functions);
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('not-found', isA<NotFound>()),
        ('invalid-argument', isA<InvalidInput>()),
        ('deadline-exceeded', isA<Offline>()),
        ('internal', isA<UnknownFailure>()),
      ]) {
        functions.fail('deleteTeamMedia', code);
        await expectLater(repo.delete(_g, 'p'), throwsA(type));
      }
    });
  });

  group('FunctionsInviteRepository', () {
    final inviteData = {
      'code': 'K7XPM2QR',
      'display': 'K7XP-M2QR',
      'url': 'https://example.com/join/K7XPM2QR',
      'useCount': 2,
      'expiresAt': '2026-11-01T00:00:00Z',
      'maxUses': 10,
    };

    test('gets and resets the team invite', () async {
      functions.handlers['getTeamInvite'] = (_) => inviteData;
      functions.handlers['resetGroupInvite'] = (_) => {
        ...inviteData,
        'expiresAt': null,
        'maxUses': null,
      };
      final repo = FunctionsInviteRepository(functions);
      final invite = await repo.teamInvite(_g);
      expect(invite.display, 'K7XP-M2QR');
      expect(invite.useCount, 2);
      expect(invite.expiresAt, DateTime.utc(2026, 11));
      expect(invite.maxUses, 10);
      final reset = await repo.resetTeamInvite(
        _g,
        expiry: InviteExpiry.sevenDays,
        maxUses: 5,
      );
      expect(reset.expiresAt, isNull);
      expect(functions.lastData('resetGroupInvite'), {
        'groupId': 'g1',
        'expiresInDays': 7,
        'maxUses': 5,
      });
    });

    test('previews and redeems a code', () async {
      functions.handlers['getInvitePreview'] = (_) => {
        'groupId': 'g1',
        'name': 'Thunder',
        'sport': 'softball',
        'memberCount': 12,
        'color': '#2F5BEA',
        'invitedBy': 'Jordan',
      };
      functions.handlers['redeemInvite'] = (_) => {
        'groupId': 'g1',
        'alreadyMember': true,
      };
      final repo = FunctionsInviteRepository(functions);
      final preview = await repo.preview('K7XPM2QR');
      expect(preview.name, 'Thunder');
      expect(preview.sport, Sport.softball);
      expect(preview.color, 0xFF2F5BEA);
      functions.handlers['getInvitePreview'] = (_) => {
        'groupId': 'g1',
        'name': 'X',
        'color': 'blue',
      };
      final sparse = await repo.preview('K7XPM2QR');
      expect(sparse.color, isNull);
      expect(sparse.sport, Sport.other);
      expect(sparse.memberCount, 0);
      final joined = await repo.redeem('K7XPM2QR');
      expect(joined.alreadyMember, isTrue);
    });

    test('sends, lists, resends, and revokes email invites', () async {
      functions.handlers['sendEmailInvites'] = (_) => {'invited': 2};
      functions.handlers['listEmailInvites'] = (_) => {
        'invites': [
          {
            'code': 'A',
            'email': 'a@example.com',
            'status': 'pending',
            'createdAt': '2026-10-01T00:00:00Z',
          },
          {
            'code': 'B',
            'email': 'b@example.com',
            'status': 'joined',
            'createdAt': null,
          },
        ],
      };
      functions.handlers['resendEmailInvite'] = (_) => <String, dynamic>{};
      functions.handlers['revokeInvite'] = (_) => <String, dynamic>{};
      final repo = FunctionsInviteRepository(functions);
      expect(
        await repo.sendEmailInvites(_g, [
          'a@example.com',
          'b@example.com',
        ], note: 'Hi'),
        2,
      );
      expect((functions.lastData('sendEmailInvites')! as Map)['note'], 'Hi');
      await repo.sendEmailInvites(_g, ['a@example.com'], note: '');
      expect(
        (functions.lastData('sendEmailInvites')! as Map).containsKey('note'),
        isFalse,
      );
      final list = await repo.emailInvites(_g);
      expect(list.map((i) => i.status), [
        EmailInviteStatus.pending,
        EmailInviteStatus.joined,
      ]);
      expect(list.last.createdAt, isNull);
      await repo.resendEmailInvite('A');
      await repo.revokeInvite('B');
      expect(
        functions.calls.map((c) => c.$1),
        containsAll(['resendEmailInvite', 'revokeInvite']),
      );
    });

    test('maps refusals to the INV-8 failures', () async {
      final repo = FunctionsInviteRepository(functions);
      Future<void> expectFailure(
        String code,
        String message,
        Matcher type,
      ) async {
        functions.fail('redeemInvite', code, message);
        await expectLater(repo.redeem('X'), throwsA(type));
      }

      await expectFailure(
        'not-found',
        'expired',
        isA<InviteUnusable>().having((f) => f.reason, 'reason', 'expired'),
      );
      await expectFailure(
        'failed-precondition',
        'too-many-teams',
        isA<TooManyTeams>(),
      );
      await expectFailure(
        'failed-precondition',
        'email-not-verified',
        isA<EmailNotVerified>(),
      );
      await expectFailure(
        'resource-exhausted',
        'slow down',
        isA<RateLimited>(),
      );
      await expectFailure('permission-denied', 'no', isA<PermissionDenied>());
      await expectFailure('invalid-argument', 'bad', isA<InviteUnusable>());
      await expectFailure('unavailable', 'offline', isA<Offline>());
      await expectFailure('internal', 'boom', isA<UnknownFailure>());
    });
  });

  group('FirestoreSafetyRepository', () {
    test('blocks with a capped name, lists, and unblocks', () async {
      final repo = FirestoreSafetyRepository(db, functions);
      await repo.block(_me, const UserId('alex'), name: 'A' * 70);
      final d = (await db.doc('userBlocks/u1_alex').get()).data()!;
      expect((d['blockedName'] as String).length, 60);
      final blocked = await repo.watchBlocked(_me).first;
      expect(blocked.single.uid, const UserId('alex'));
      await repo.unblock(_me, const UserId('alex'));
      expect(await repo.watchBlocked(_me).first, isEmpty);
    });

    test('maps block refusals to failures', () async {
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('aborted', isA<UnknownFailure>()),
      ]) {
        final db = FakeFirebaseFirestore();
        final repo = FirestoreSafetyRepository(db, functions);
        whenCalling(Invocation.method(#delete, null))
            .on(db.doc('userBlocks/u1_alex'))
            .thenThrow(_fs(code));
        await expectLater(
          repo.unblock(_me, const UserId('alex')),
          throwsA(type),
        );
      }
    });

    test('reports through reportContent and resolves', () async {
      final repo = FirestoreSafetyRepository(db, functions);
      await repo.report(
        _g,
        targetType: ReportTargetType.message,
        targetId: 'm1',
        reason: ReportReason.spam,
        details: '  ',
      );
      expect(functions.lastData('reportContent'), {
        'groupId': 'g1',
        'targetType': 'message',
        'targetId': 'm1',
        'reason': 'spam',
      });
      await repo.report(
        _g,
        targetType: ReportTargetType.user,
        targetId: 'alex',
        reason: ReportReason.harassment,
        details: 'Rude',
      );
      expect((functions.lastData('reportContent')! as Map)['details'], 'Rude');
      await repo.resolveReport(
        'r1',
        actioned: true,
        resolution: ReportResolution.deletedMessage,
      );
      expect(functions.lastData('resolveReport'), {
        'reportId': 'r1',
        'outcome': 'actioned',
        'resolution': 'deletedMessage',
      });
      await repo.resolveReport('r1', actioned: false);
      expect(
        (functions.lastData('resolveReport')! as Map)['outcome'],
        'dismissed',
      );

      for (final (code, type) in [
        ('resource-exhausted', isA<RateLimited>()),
        ('permission-denied', isA<PermissionDenied>()),
        ('unavailable', isA<Offline>()),
        ('internal', isA<UnknownFailure>()),
      ]) {
        functions.fail('resolveReport', code);
        await expectLater(
          repo.resolveReport('r1', actioned: true),
          throwsA(type),
        );
      }
    });

    test('lists open reports newest first', () async {
      final repo = FirestoreSafetyRepository(db, functions);
      await db.doc('reports/r1').set({
        'groupId': 'g1',
        'status': 'open',
        'targetType': 'document',
        'targetId': 'd1',
        'reason': 'inappropriate',
        'subjectId': 'alex',
        'subjectName': 'Alex',
        'excerpt': 'Plan.pdf',
        'teamVisible': true,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10)),
      });
      await db.doc('reports/r2').set({
        'groupId': 'g1',
        'status': 'open',
        'targetType': 'mystery',
        'reason': 'mystery',
        'teamVisible': true,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 2)),
      });
      // SAFE-1: a report about one of the team's admins is for super admins.
      await db.doc('reports/r4').set({
        'groupId': 'g1',
        'status': 'open',
        'teamVisible': false,
        'createdAt': Timestamp.now(),
      });
      await db.doc('reports/r3').set({
        'groupId': 'g1',
        'status': 'actioned',
        'createdAt': Timestamp.now(),
      });
      final reports = await repo.watchOpenReports(_g).first;
      expect(reports.map((r) => r.id), ['r2', 'r1']);
      expect(reports.first.targetType, ReportTargetType.message);
      expect(reports.first.reason, ReportReason.other);
      expect(reports.last.targetType, ReportTargetType.document);
      expect(reports.last.excerpt, 'Plan.pdf');
    });
  });

  group('FirestorePollRepository', () {
    const pollId = PollId('p1');
    Poll poll() => const Poll(
      id: pollId,
      groupId: _g,
      createdBy: 'coach',
      question: 'Pizza?',
      options: [
        PollOption(id: '0', text: 'Yes'),
        PollOption(id: '1', text: 'No'),
      ],
    );

    test('reads a poll, votes in option order, and removes the vote', () async {
      await db.doc('polls/p1').set({
        'groupId': 'g1',
        'createdBy': 'coach',
        'question': 'Pizza?',
        'options': [
          {'id': '0', 'text': 'Yes'},
          {'id': '1', 'text': 'No'},
          'junk',
        ],
        'allowMultiple': true,
        'closesAt': Timestamp.fromDate(DateTime.utc(2026, 10, 5)),
        'closedAt': null,
        'voteCounts': {'0': 2},
        'voterCount': 2,
      });
      final repo = FirestorePollRepository(db, functions);
      final p = await repo.watchPoll(pollId).first;
      expect(p!.options.length, 2);
      expect(p.allowMultiple, isTrue);
      expect(p.voteCounts, {'0': 2});
      expect(p.closesAt?.toUtc(), DateTime.utc(2026, 10, 5));
      expect(await repo.watchPoll(const PollId('gone')).first, isNull);

      await repo.setVote(poll(), _me, {'1', '0', 'unknown'});
      expect((await db.doc('pollVotes/p1_u1').get()).data()!['optionIds'], [
        '0',
        '1',
      ]);
      expect(await repo.watchMyVote(pollId, _me).first, {'0', '1'});
      await repo.setVote(poll(), _me, {});
      expect((await db.doc('pollVotes/p1_u1').get()).exists, isFalse);
      expect(await repo.watchMyVote(pollId, _me).first, isEmpty);
    });

    test('maps vote refusals to failures', () async {
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('unavailable', isA<Offline>()),
        ('aborted', isA<UnknownFailure>()),
      ]) {
        final db = FakeFirebaseFirestore();
        final repo = FirestorePollRepository(db, functions);
        final doc = db.doc('pollVotes/p1_u1');
        whenCalling(Invocation.method(#delete, null))
            .on(doc)
            .thenThrow(_fs(code));
        await expectLater(repo.setVote(poll(), _me, {}), throwsA(type));
      }
    });

    test('loads every vote', () async {
      for (var i = 0; i < 30; i++) {
        await db.doc('pollVotes/p1_u${i.toString().padLeft(3, '0')}').set({
          'pollId': 'p1',
          'uid': 'u$i',
          'optionIds': ['0', 7],
        });
      }
      await db.doc('pollVotes/p2_u1').set({
        'pollId': 'p2',
        'uid': 'u1',
        'optionIds': ['1'],
      });
      final votes = await FirestorePollRepository(
        db,
        functions,
      ).loadVotes(pollId);
      expect(votes.length, 30);
      expect(votes.first.optionIds, {'0'});
    });

    test('closes through closePoll', () async {
      final repo = FirestorePollRepository(db, functions);
      await repo.closePoll(pollId);
      expect(functions.lastData('closePoll'), {'pollId': 'p1'});
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('deadline-exceeded', isA<Offline>()),
        ('internal', isA<UnknownFailure>()),
      ]) {
        functions.fail('closePoll', code);
        await expectLater(repo.closePoll(pollId), throwsA(type));
      }
    });

    test('reads a sparse poll with defaults', () {
      final p = pollFromFirestore('p', const {});
      expect(p.question, '');
      expect(p.options, isEmpty);
      expect(p.voterCount, 0);
    });
  });

  group('SharedPrefsRepository', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    Future<SharedPrefsRepository> open() async => SharedPrefsRepository(
      await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: SharedPrefsRepository.keys,
        ),
      ),
    );

    test('keeps theme, last team, pending email, and the pre-prompt', () async {
      final repo = await open();
      expect(repo.themePreference, ThemePreference.system);
      await repo.setThemePreference(ThemePreference.dark);
      expect(repo.themePreference, ThemePreference.dark);
      expect(repo.lastTeamRoute, isNull);
      await repo.setLastTeamRoute('/g/g1/chat');
      expect(repo.lastTeamRoute, '/g/g1/chat');
      await repo.setPendingSignInEmail('a@example.com');
      expect(repo.pendingSignInEmail, 'a@example.com');
      await repo.setPendingSignInEmail(null);
      expect(repo.pendingSignInEmail, isNull);
      expect(repo.pushPrePromptShown, isFalse);
      await repo.setPushPrePromptShown();
      expect(repo.pushPrePromptShown, isTrue);
      // Survives reopening.
      expect((await open()).themePreference, ThemePreference.dark);
    });

    test('remembers which accounts set a password here (AUTH-7)', () async {
      final repo = await open();
      expect(repo.passwordSet('u1'), isFalse);
      await repo.setPasswordSet('u1', value: true);
      await repo.setPasswordSet('u2', value: true);
      expect((await open()).passwordSet('u1'), isTrue);
      await repo.setPasswordSet('u1', value: false);
      expect(repo.passwordSet('u1'), isFalse);
      expect(repo.passwordSet('u2'), isTrue);
    });

    test('makes one stable 24-character install ID', () async {
      final repo = await open();
      final id = repo.installId;
      expect(id, matches(RegExp(r'^[A-Za-z0-9]{24}$')));
      expect(repo.installId, id);
    });

    test('keeps the device registration, and ignores a corrupt one', () async {
      final repo = await open();
      expect(repo.deviceRegistration, isNull);
      final at = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      await repo.setDeviceRegistration((uid: 'u1', token: 't1', at: at));
      expect(repo.deviceRegistration, (uid: 'u1', token: 't1', at: at));
      await repo.setDeviceRegistration(null);
      expect(repo.deviceRegistration, isNull);

      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'deviceRegistration': 'not json',
          });
      expect((await open()).deviceRegistration, isNull);
    });
  });

  group('PrefsChatQueueStore', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    Future<PrefsChatQueueStore> open() async => PrefsChatQueueStore(
      await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: {PrefsChatQueueStore.key},
        ),
      ),
    );

    test(
      "keeps each team's queued messages across restarts (CHAT-4)",
      () async {
        final store = await open();
        expect(store.load(_g), isEmpty);
        await store.save(_g, [
          const SavedText(id: 'm1', text: 'On my way'),
          const SavedText(
            id: 'm2',
            text: 'Yes',
            replyToId: 'm0',
            mentions: ['sam'],
            mentionsEveryone: true,
            announcement: true,
          ),
        ]);
        await store.save(const GroupId('g2'), [
          const SavedText(id: 'm3', text: 'Hi'),
        ]);
        final again = await open();
        // Mentions and announcements stay with the text (CHAT-14, CHAT-15).
        expect(again.load(_g), [
          const SavedText(id: 'm1', text: 'On my way'),
          const SavedText(
            id: 'm2',
            text: 'Yes',
            replyToId: 'm0',
            mentions: ['sam'],
            mentionsEveryone: true,
            announcement: true,
          ),
        ]);
        await again.save(_g, const []);
        expect(again.load(_g), isEmpty);
        expect(again.load(const GroupId('g2')), hasLength(1));
        await again.save(const GroupId('g2'), const []);
        expect((await open()).load(const GroupId('g2')), isEmpty);
      },
    );

    test('ignores a corrupt queue and malformed items', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            PrefsChatQueueStore.key: 'not json',
          });
      expect((await open()).load(_g), isEmpty);

      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            PrefsChatQueueStore.key:
                '{"g1":[{"id":"m1","text":"ok"},{"id":2},"x"],"g2":"nope"}',
          });
      final store = await open();
      expect(store.load(_g), [const SavedText(id: 'm1', text: 'ok')]);
      expect(store.load(const GroupId('g2')), isEmpty);
    });
  });
}
