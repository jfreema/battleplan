// Data-layer tests (SPEC §8.1): profiles and RSVPs.
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/data/firestore_user_repository.dart';
import 'package:battleplan/features/schedule/data/firestore_rsvp_repository.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import '../helpers/fake_functions.dart';

FirebaseException _fs(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  group('FirestoreUserRepository', () {
    late FakeFirebaseFirestore db;
    late FakeFunctions functions;
    late MockFirebaseStorage storage;
    late FirestoreUserRepository repo;

    setUp(() async {
      db = FakeFirebaseFirestore();
      functions = FakeFunctions();
      storage = MockFirebaseStorage();
      repo = FirestoreUserRepository(db, functions, storage);
      await db.doc('users/u1').set({
        'displayName': 'Alex Kim',
        'status': 'active',
        'email': 'alex@example.com',
        'themeMode': 'dark',
        'signInMethods': ['password', 'google.com'],
        'adultConfirmedAt': Timestamp.fromDate(DateTime.utc(2026)),
        'notificationPrefs': {
          'events': false,
          'eventsNew': true,
          'polls': false,
          'junk': 'x',
        },
      });
    });

    test('watches the profile, and reads legacy event switches', () async {
      final p = await repo.watchProfile('u1').first;
      expect(p!.displayName, 'Alex Kim');
      expect(p.themeMode, ThemePreference.dark);
      expect(p.signInMethods, ['password', 'google.com']);
      expect(p.adultConfirmedAt, isNotNull);
      expect(p.notificationPrefs, {
        NotificationPref.eventsNew: true,
        NotificationPref.eventsChanged: false,
        NotificationPref.polls: false,
      });
      expect(await repo.watchProfile('nobody').first, isNull);
      expect(notificationPrefsFromFirestore(null), isEmpty);
      final sparse = userProfileFromFirestore('x', const {});
      expect(sparse.status, UserStatus.active);
      // A profile with no theme yet is on the default, Gumdrop Pop Olive.
      expect(sparse.themeMode, ThemePreference.system);
      expect(
        userProfileFromFirestore('z', const {'themeMode': 'olive'}).themeMode,
        ThemePreference.olive,
      );
      expect(
        userProfileFromFirestore('y', const {'themeMode': 'candy'}).themeMode,
        ThemePreference.candy,
      );
    });

    test(
      'creates and finishes the profile through ensureUserProfile',
      () async {
        await repo.ensureProfile();
        expect(functions.lastData('ensureUserProfile'), isEmpty);
        await repo.ensureProfile(displayName: 'Alex', finishSetup: true);
        expect(functions.lastData('ensureUserProfile'), {
          'setup': {
            'displayName': 'Alex',
            'confirmAdult': true,
            'acceptTerms': true,
          },
        });
        for (final (code, type) in [
          ('invalid-argument', isA<InvalidInput>()),
          ('unauthenticated', isA<Unauthenticated>()),
          ('unavailable', isA<Offline>()),
          ('internal', isA<UnknownFailure>()),
        ]) {
          functions.fail('ensureUserProfile', code);
          await expectLater(repo.ensureProfile(), throwsA(type));
        }
      },
    );

    test('updates the name, theme, and notification switches', () async {
      await repo.updateDisplayName('u1', '  Alex K  ');
      await repo.setThemeMode('u1', ThemePreference.light);
      await repo.setNotificationPref(
        'u1',
        NotificationPref.reminders,
        enabled: false,
      );
      final d = (await db.doc('users/u1').get()).data()!;
      expect(d['displayName'], 'Alex K');
      expect(d['displayNameLower'], 'alex k');
      expect(d['themeMode'], 'light');
      expect((d['notificationPrefs'] as Map)['reminders'], isFalse);
      expect(
        () => repo.updateDisplayName('u1', '  '),
        throwsA(isA<InvalidInput>()),
      );
      expect(
        () => repo.updateDisplayName('u1', 'x' * 51),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('maps update refusals to failures', () async {
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('unavailable', isA<Offline>()),
        ('aborted', isA<UnknownFailure>()),
      ]) {
        final db = FakeFirebaseFirestore();
        final repo = FirestoreUserRepository(db, functions, storage);
        whenCalling(Invocation.method(#update, null))
            .on(db.doc('users/u1'))
            .thenThrow(_fs(code));
        await expectLater(
          repo.setThemeMode('u1', ThemePreference.dark),
          throwsA(type),
        );
      }
    });

    test('uploads a photo, replaces the old one, and caches its URL', () async {
      await repo.uploadPhoto('u1', Uint8List.fromList([1, 2, 3]));
      final first =
          (await db.doc('users/u1').get()).data()!['photoPath'] as String;
      expect(first, startsWith('users/u1/avatar/'));
      final url = await repo.photoUrl(first);
      expect(url, contains('users/u1/avatar'));
      expect(await repo.photoUrl(first), url);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repo.uploadPhoto('u1', Uint8List.fromList([4]));
      final second =
          (await db.doc('users/u1').get()).data()!['photoPath'] as String;
      expect(second, isNot(first));
      expect(await repo.photoUrl('users/u1/avatar/missing.jpg'), isNull);
    });
  });

  group('FirestoreRsvpRepository', () {
    late FakeFirebaseFirestore db;
    late FirestoreRsvpRepository repo;
    const g = GroupId('g1');

    Event event(String id, DateTime start) => Event(
      id: EventId(id),
      groupId: g,
      type: EventType.practice,
      title: 'Practice',
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      timeZone: 'America/Chicago',
      createdBy: 'coach',
    );

    RsvpAnswer answer(String id, RsvpStatus status, {String note = ''}) =>
        RsvpAnswer(
          participant: Participant(
            type: ParticipantType.member,
            id: id,
            name: 'P $id',
          ),
          status: status,
          note: note,
        );

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = FirestoreRsvpRepository(db);
    });

    test(
      'writes one record per event and participant, and watches it',
      () async {
        final e = event('e1', DateTime.utc(2026, 10, 20, 18));
        await repo.setRsvp(
          e,
          answer('alex', RsvpStatus.maybe, note: ' late '),
          by: const UserId('alex'),
        );
        await repo.setRsvp(
          e,
          answer('alex', RsvpStatus.going),
          by: const UserId('alex'),
        );
        await repo.setRsvp(
          e,
          answer('sam', RsvpStatus.notGoing),
          by: const UserId('sam'),
        );
        final d = (await db.doc('rsvps/e1_alex').get()).data()!;
        expect(d['status'], 'going');
        expect(d['respondedBy'], 'alex');

        final all = await repo.watchForEvent(g, e.id).first;
        expect(all.map((r) => r.participantId), ['alex', 'sam']);
        expect(all.last.status, RsvpStatus.notGoing);

        final mine = await repo
            .watchMine(
              g,
              ['alex'],
              from: DateTime.utc(2026, 10),
              until: DateTime.utc(2026, 11),
            )
            .first;
        expect(mine.single.participantName, 'P alex');
        expect(await repo.watchMine(g, const []).first, isEmpty);
        expect(
          await repo.watchMine(g, [
            'alex',
          ], until: DateTime.utc(2026, 10)).first,
          isEmpty,
        );
      },
    );

    test('writes several answers in one batch (PLAYER-11)', () async {
      final e = event('e1', DateTime.utc(2026, 10, 20, 18));
      await repo.setRsvps(e, [
        answer('p1', RsvpStatus.going, note: ' late '),
        answer('p2', RsvpStatus.going),
      ], by: const UserId('maria'));
      final p1 = (await db.doc('rsvps/e1_p1').get()).data()!;
      final p2 = (await db.doc('rsvps/e1_p2').get()).data()!;
      expect(p1['status'], 'going');
      expect(p1['note'], 'late');
      expect(p2['respondedBy'], 'maria');
      expect(p2['eventStartAt'], Timestamp.fromDate(e.startAt));
      // Nothing to write is nothing done.
      await repo.setRsvps(e, const [], by: const UserId('maria'));
      expect((await repo.watchForEvent(g, e.id).first).length, 2);
    });

    test('reads past the first 100 of my answers', () async {
      for (var i = 0; i < 105; i++) {
        await repo.setRsvp(
          event(
            'e${i.toString().padLeft(3, '0')}',
            DateTime.utc(2026, 10).add(Duration(hours: i)),
          ),
          answer('alex', RsvpStatus.going),
          by: const UserId('alex'),
        );
      }
      expect((await repo.watchMine(g, ['alex']).first).length, 105);
      expect(
        (await repo.watchForEvent(g, const EventId('e000')).first).length,
        1,
      );
    });

    test('maps refusals to failures', () async {
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('unavailable', isA<Offline>()),
        ('aborted', isA<UnknownFailure>()),
      ]) {
        final db = FakeFirebaseFirestore();
        whenCalling(Invocation.method(#set, null))
            .on(db.doc('rsvps/e1_alex'))
            .thenThrow(_fs(code));
        await expectLater(
          FirestoreRsvpRepository(db).setRsvp(
            event('e1', DateTime.utc(2026)),
            answer('alex', RsvpStatus.going),
            by: const UserId('alex'),
          ),
          throwsA(type),
        );
      }
    });

    test('reads a sparse record with defaults', () {
      final r = rsvpFromFirestore(const {});
      expect(r.status, RsvpStatus.going);
      expect(r.participantType, ParticipantType.member);
      expect(r.eventStartAt, isNull);
    });
  });
}
