// Data-layer tests (SPEC §8.1): teams and memberships.
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/data/firestore_group_repository.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import '../helpers/fake_functions.dart';

const _g = GroupId('g1');
const _me = UserId('alex');

FirebaseException _fs(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  late FakeFirebaseFirestore db;
  late FakeFunctions functions;
  late MockFirebaseStorage storage;

  setUp(() async {
    db = FakeFirebaseFirestore();
    functions = FakeFunctions();
    storage = MockFirebaseStorage();
    await db.doc('groups/g1').set({
      'name': 'Thunder',
      'sport': 'softball',
      'teamType': 'adult',
      'memberCount': 3,
      'color': '#2F5BEA',
      'lastMessageAt': Timestamp.fromDate(DateTime.utc(2026, 10)),
      'lastMessagePreview': {'authorName': 'Sam', 'text': 'See you there'},
      'ownerId': 'coach',
      'timeZone': 'America/Denver',
      'settings': {
        'membersCanCreateEvents': true,
        'defaultReminderOffsets': [60, 1440],
      },
      'storageBytes': 1024,
      'storageQuotaBytes': 0,
      'chatTheme': {'bubbleColor': '#0F8A5F', 'background': 'pattern'},
      'pinnedMessageIds': ['m1', 7, 'm2'],
    });
  });

  group('FirestoreGroupRepository', () {
    test('reads a team with its settings, quota, and chat look', () async {
      final repo = FirestoreGroupRepository(db, functions, storage);
      final g = (await repo.watchGroup(_g).first)!;
      expect(g.name, 'Thunder');
      expect(g.sport, Sport.softball);
      expect(g.color, 0xFF2F5BEA);
      expect(g.lastMessagePreview, 'Sam: See you there');
      expect(g.timeZone, 'America/Denver');
      expect(g.settings.membersCanCreateEvents, isTrue);
      expect(g.settings.membersCanCreatePolls, isTrue);
      expect(g.settings.defaultReminderOffsets, [60, 1440]);
      expect(g.storageQuotaBytes, Limits.defaultStorageQuotaMb * bytesPerMb);
      expect(g.chatTheme!.background, ChatBackground.pattern);
      expect(g.chatTheme!.bubbleColor, 0xFF0F8A5F);
      // Pinned messages, oldest pin first (CHAT-15); anything but an ID
      // is skipped.
      expect(g.pinnedMessageIds, ['m1', 'm2']);
      // An old team's teamType is ignored; a missing kind is a team.
      expect(g.kind, GroupKind.team);
      expect(await repo.watchGroup(const GroupId('none')).first, isNull);
      final sparse = groupFromFirestore('x', const {
        'color': 'blue',
        'storageQuotaBytes': 5,
        'storageQuotaCustom': true,
      });
      expect(sparse.color, isNull);
      expect(sparse.storageQuotaBytes, 5);
      expect(sparse.storageQuotaCustom, isTrue);
      expect(g.storageQuotaCustom, isFalse);
      expect(sparse.settings, const GroupSettings());
      expect(sparse.pinnedMessageIds, isEmpty);
    });

    test('reads a retired team color as its replacement (TEAM-5)', () {
      // Royal blue reads as Blue, Violet as Purple, as the team color and
      // as the chat look's message color; the stored value stays.
      final royal = groupFromFirestore('x', const {
        'color': '#1D4ED8',
        'chatTheme': {'bubbleColor': '#9333EA'},
      });
      expect(royal.color, 0xFF2F5BEA);
      expect(royal.chatTheme!.bubbleColor, 0xFF7C3AED);
      expect(
        groupFromFirestore('x', const {'color': '#9333EA'}).color,
        0xFF7C3AED,
      );
      // Colors still in the palette read as they are.
      for (final argb in teamColorValues) {
        final hex =
            '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
        expect(groupFromFirestore('x', {'color': hex}).color, argb);
      }
    });

    test('creates a team through createGroup', () async {
      functions.handlers['createGroup'] = (_) => {'groupId': 'new1'};
      final repo = FirestoreGroupRepository(db, functions, storage);
      final id = await repo.createGroup(
        name: 'Hawks',
        sport: Sport.basketball,
        timeZone: 'America/Chicago',
        color: '#C2410C',
        description: '',
      );
      expect(id, const GroupId('new1'));
      expect(functions.lastData('createGroup'), {
        'name': 'Hawks',
        'sport': 'basketball',
        'timeZone': 'America/Chicago',
        'color': '#C2410C',
      });
      await repo.createGroup(
        name: 'H',
        sport: Sport.other,
        timeZone: 'UTC',
        description: 'Rec league',
      );
      expect(
        (functions.lastData('createGroup')! as Map)['description'],
        'Rec league',
      );
      // The attempt's ID goes along, so a retry can't make a second team.
      await repo.createGroup(
        name: 'H',
        sport: Sport.other,
        timeZone: 'UTC',
        requestId: 'attempt-0001',
      );
      expect(
        (functions.lastData('createGroup')! as Map)['requestId'],
        'attempt-0001',
      );
      // On the web too, where the message arrives with its status.
      for (final web in [false, true]) {
        functions.web = web;
        for (final (code, message, type) in [
          (
            'failed-precondition',
            'email-not-verified',
            isA<EmailNotVerified>(),
          ),
          ('failed-precondition', 'too-many-teams', isA<TooManyTeams>()),
          ('resource-exhausted', 'slow', isA<RateLimited>()),
          ('permission-denied', 'no', isA<PermissionDenied>()),
          ('invalid-argument', 'bad', isA<InvalidInput>()),
          ('unavailable', 'offline', isA<Offline>()),
          ('internal', 'boom', isA<UnknownFailure>()),
        ]) {
          functions.fail('createGroup', code, message);
          await expectLater(
            repo.createGroup(name: 'X', sport: Sport.other, timeZone: 'UTC'),
            throwsA(
              type.having((f) => f.message, 'message', isNot(contains('['))),
            ),
          );
        }
      }
    });

    test('updates details, settings, logo, and chat look', () async {
      final repo = FirestoreGroupRepository(db, functions, storage);
      await repo.updateGroup(
        _g,
        name: ' Thunder FC ',
        sport: Sport.soccer,
        description: ' Rec ',
        settings: const GroupSettings(
          allowMaybe: false,
          defaultReminderOffsets: [30],
        ),
      );
      var d = (await db.doc('groups/g1').get()).data()!;
      expect(d['name'], 'Thunder FC');
      expect(d['nameLower'], 'thunder fc');
      expect(d['description'], 'Rec');
      expect((d['settings'] as Map)['allowMaybe'], isFalse);
      expect(d['color'], '#2F5BEA');

      await repo.uploadLogo(_g, Uint8List.fromList([1]));
      d = (await db.doc('groups/g1').get()).data()!;
      expect(d['photoPath'], startsWith('groups/g1/avatar/'));
      expect(await repo.photoUrl(d['photoPath'] as String), isNotNull);
      expect(await repo.photoUrl('missing'), isNull);

      final background = await repo.uploadChatBackground(
        _g,
        Uint8List.fromList([2]),
      );
      expect(background, startsWith('groups/g1/theme/'));
      await repo.updateChatTheme(
        _g,
        ChatTheme(
          bubbleColor: 0xFF0A0B0C,
          background: ChatBackground.photo,
          backgroundPath: background,
        ),
      );
      d = (await db.doc('groups/g1').get()).data()!;
      expect(d['chatTheme'], {
        'bubbleColor': '#0A0B0C',
        'background': 'photo',
        'backgroundPath': background,
      });
      await repo.updateChatTheme(_g, const ChatTheme());
      expect(
        ((await db.doc('groups/g1').get()).data()!['chatTheme']
            as Map)['bubbleColor'],
        isNull,
      );
    });

    test('maps write refusals to failures', () async {
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('unavailable', isA<Offline>()),
        ('aborted', isA<UnknownFailure>()),
      ]) {
        final db = FakeFirebaseFirestore();
        final repo = FirestoreGroupRepository(db, functions, storage);
        whenCalling(Invocation.method(#update, null))
            .on(db.doc('groups/g1'))
            .thenThrow(_fs(code));
        await expectLater(repo.updateGroup(_g, name: 'X'), throwsA(type));
        if (code != 'unavailable') {
          await expectLater(
            repo.updateChatTheme(_g, const ChatTheme()),
            throwsA(type),
          );
          await expectLater(repo.uploadLogo(_g, Uint8List(1)), throwsA(type));
        }
      }
    });

    test('runs owner actions through callables', () async {
      final repo = FirestoreGroupRepository(db, functions, storage);
      await repo.transferOwnership(_g, _me);
      await repo.leave(_g);
      await repo.setArchived(_g, archived: true);
      await repo.deleteGroup(_g, 'Thunder');
      await repo.setStorageQuota(_g, 750);
      expect(functions.calls.map((c) => c.$1), [
        'transferOwnership',
        'leaveGroup',
        'archiveGroup',
        'deleteGroup',
        'adminSetGroupQuota',
      ]);
      expect(functions.lastData('adminSetGroupQuota'), {
        'groupId': 'g1',
        'quotaMb': 750,
      });
      // Back on the default (STORE-6).
      await repo.setStorageQuota(_g, null);
      expect(functions.lastData('adminSetGroupQuota'), {
        'groupId': 'g1',
        'quotaMb': null,
      });
      for (final (code, message, type) in [
        (
          'failed-precondition',
          'owner-must-transfer',
          isA<OwnerMustTransfer>(),
        ),
        ('invalid-argument', 'bad', isA<InvalidInput>()),
        ('permission-denied', 'no', isA<PermissionDenied>()),
        ('not-found', 'gone', isA<NotFound>()),
        ('deadline-exceeded', 'late', isA<Offline>()),
        ('internal', 'boom', isA<UnknownFailure>()),
      ]) {
        functions.fail('leaveGroup', code, message);
        await expectLater(repo.leave(_g), throwsA(type));
      }
    });
  });

  group('FirestoreMemberRepository', () {
    setUp(() async {
      await db.doc('groupMembers/g1_alex').set({
        'groupId': 'g1',
        'uid': 'alex',
        'role': 'admin',
        'displayName': 'Alex Kim',
        'notificationLevel': 'important',
        'title': 'Assistant coach',
      });
      await db.doc('groupMembers/g1_sam').set({
        'groupId': 'g1',
        'uid': 'sam',
        'displayName': 'Sam',
        'pending': true,
      });
      await db.doc('groupMembers/g2_alex').set({
        'groupId': 'g2',
        'uid': 'alex',
        'role': 'owner',
      });
    });

    test('watches the roster and my memberships', () async {
      final repo = FirestoreMemberRepository(db, functions);
      final roster = await repo.watchRoster(_g).first;
      expect(roster.length, 2);
      final alex = roster.firstWhere((m) => m.uid == _me);
      expect(alex.role, MemberRole.admin);
      expect(alex.notificationLevel, NotificationLevel.important);
      expect(alex.title, 'Assistant coach');
      expect(roster.firstWhere((m) => m.uid != _me).pending, isTrue);
      final mine = await repo.watchMyMemberships(_me).first;
      expect(mine.map((m) => m.groupId.value), unorderedEquals(['g1', 'g2']));
    });

    test('edits my own notification settings and read marker', () async {
      final repo = FirestoreMemberRepository(db, functions);
      await repo.setNotificationLevel(_g, _me, NotificationLevel.none);
      await repo.setMutedUntil(_g, _me, DateTime.utc(2026, 10, 13));
      await repo.markRead(_g, _me);
      var d = (await db.doc('groupMembers/g1_alex').get()).data()!;
      expect(d['notificationLevel'], 'none');
      expect(d['mutedUntil'], isA<Timestamp>());
      expect(d['lastReadAt'], isNotNull);
      await repo.setMutedUntil(_g, _me, null);
      d = (await db.doc('groupMembers/g1_alex').get()).data()!;
      expect(d['mutedUntil'], isNull);
    });

    test('shares and stops sharing my phone and email (TEAM-10)', () async {
      final repo = FirestoreMemberRepository(db, functions);
      await repo.setContact(
        _g,
        _me,
        phone: ' 555 0100 ',
        email: 'alex@example.com',
      );
      var d = (await db.doc('groupMembers/g1_alex').get()).data()!;
      expect(d['contactPhone'], '555 0100');
      expect(d['contactEmail'], 'alex@example.com');
      var alex = (await repo.watchRoster(_g).first).firstWhere(
        (m) => m.uid == _me,
      );
      expect(alex.contactPhone, '555 0100');
      expect(alex.sharesContact, isTrue);
      // Blank is the same as not shared.
      await repo.setContact(_g, _me, phone: '  ');
      d = (await db.doc('groupMembers/g1_alex').get()).data()!;
      expect(d['contactPhone'], isNull);
      expect(d['contactEmail'], isNull);
      alex = (await repo.watchRoster(_g).first).firstWhere((m) => m.uid == _me);
      expect(alex.sharesContact, isFalse);
      // A blank stored value reads as not shared.
      expect(
        membershipFromFirestore(const {
          'groupId': 'g1',
          'uid': 'x',
          'contactEmail': ' ',
        }).sharesContact,
        isFalse,
      );
    });

    test(
      'maps my-settings refusals to failures, and ignores a missed read marker',
      () async {
        for (final (code, type) in [
          ('permission-denied', isA<PermissionDenied>()),
          ('not-found', isA<NotFound>()),
          ('unavailable', isA<Offline>()),
          ('aborted', isA<UnknownFailure>()),
        ]) {
          final db = FakeFirebaseFirestore();
          final repo = FirestoreMemberRepository(db, functions);
          whenCalling(Invocation.method(#update, null))
              .on(db.doc('groupMembers/g1_alex'))
              .thenThrow(_fs(code));
          await expectLater(
            repo.setNotificationLevel(_g, _me, NotificationLevel.all),
            throwsA(type),
          );
          await repo.markRead(_g, _me);
        }
      },
    );

    test(
      'changes roles, removes, and adds by email through callables',
      () async {
        functions.handlers['addMemberByEmail'] = (_) => {
          'added': 1,
          'invited': 2,
          'alreadyMembers': 0,
          'problems': ['bad@'],
        };
        final repo = FirestoreMemberRepository(db, functions);
        await repo.updateMember(
          _g,
          _me,
          role: MemberRole.member,
          title: 'Coach',
        );
        expect(functions.lastData('updateGroupMember'), {
          'groupId': 'g1',
          'uid': 'alex',
          'role': 'member',
          'title': 'Coach',
        });
        await repo.updateMember(_g, _me, clearTitle: true);
        expect(functions.lastData('updateGroupMember'), {
          'groupId': 'g1',
          'uid': 'alex',
          'title': null,
        });
        await repo.removeMember(_g, const UserId('sam'));
        await repo.resendSetupEmail(_g, const UserId('sam'));
        final added = await repo.addByEmail(_g, const [
          (name: 'Pat', email: 'pat@example.com'),
        ]);
        expect(added.invited, 2);
        expect(added.problems, ['bad@']);
        for (final (code, type) in [
          ('permission-denied', isA<PermissionDenied>()),
          ('not-found', isA<NotFound>()),
          ('invalid-argument', isA<InvalidInput>()),
          ('unavailable', isA<Offline>()),
          ('internal', isA<UnknownFailure>()),
        ]) {
          functions.fail('removeMember', code);
          await expectLater(repo.removeMember(_g, _me), throwsA(type));
        }
        for (final (code, message, type) in [
          (
            'failed-precondition',
            'email-not-verified',
            isA<EmailNotVerified>(),
          ),
          ('resource-exhausted', 'slow', isA<RateLimited>()),
          ('permission-denied', 'no', isA<PermissionDenied>()),
          ('internal', 'boom', isA<UnknownFailure>()),
        ]) {
          functions.fail('addMemberByEmail', code, message);
          await expectLater(repo.addByEmail(_g, const []), throwsA(type));
        }
      },
    );
  });
}
