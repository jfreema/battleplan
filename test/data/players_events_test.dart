// Data-layer tests (SPEC §8.1): players and the schedule.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/data/firestore_player_repository.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/data/firestore_event_repository.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_draft.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import '../helpers/fake_functions.dart';

const _g = GroupId('g1');

FirebaseException _fs(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  late FakeFirebaseFirestore db;
  late FakeFunctions functions;

  setUp(() {
    db = FakeFirebaseFirestore();
    functions = FakeFunctions();
  });

  group('FirestorePlayerRepository', () {
    test('watches players, guardian links, and requests', () async {
      await db.doc('players/emma').set({
        'groupId': 'g1',
        'displayName': 'Emma',
        'jerseyNumber': '7',
        'position': 'Forward',
      });
      await db.doc('players/x').set({'groupId': 'g2', 'displayName': 'Other'});
      await db.doc('playerGuardians/emma_maria').set({
        'groupId': 'g1',
        'playerId': 'emma',
        'uid': 'maria',
      });
      await db.doc('guardianRequests/emma_luis').set({
        'groupId': 'g1',
        'playerId': 'emma',
        'uid': 'luis',
        'status': 'pending',
      });
      await db.doc('guardianRequests/emma_sam').set({
        'groupId': 'g1',
        'playerId': 'emma',
        'uid': 'sam',
        'status': 'declined',
      });
      final repo = FirestorePlayerRepository(db, functions);

      final players = await repo.watchPlayers(_g).first;
      expect(players.single.displayName, 'Emma');
      expect(players.single.jerseyNumber, '7');
      expect(
        (await repo.watchGuardianLinks(_g).first).single.uid,
        const UserId('maria'),
      );
      expect(
        (await repo.watchPendingRequests(_g).first).single.uid,
        const UserId('luis'),
      );
      final mine = await repo.watchMyRequests(_g, const UserId('sam')).first;
      expect(mine.single.status, GuardianRequestStatus.declined);
    });

    test('edits a player, blanking empty number and position', () async {
      await db.doc('players/emma').set({
        'groupId': 'g1',
        'displayName': 'Emma',
      });
      final repo = FirestorePlayerRepository(db, functions);
      await repo.updatePlayer(
        const PlayerId('emma'),
        name: ' Emma R ',
        jerseyNumber: ' 9 ',
        position: ' ',
      );
      final d = (await db.doc('players/emma').get()).data()!;
      expect(d['displayName'], 'Emma R');
      expect(d['displayNameLower'], 'emma r');
      expect(d['jerseyNumber'], '9');
      expect(d['position'], isNull);
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('aborted', isA<UnknownFailure>()),
      ]) {
        final db = FakeFirebaseFirestore();
        whenCalling(Invocation.method(#update, null))
            .on(db.doc('players/emma'))
            .thenThrow(_fs(code));
        await expectLater(
          FirestorePlayerRepository(
            db,
            functions,
          ).updatePlayer(const PlayerId('emma'), name: 'E'),
          throwsA(type),
        );
      }
    });

    test('adds players and guardians through the callables', () async {
      functions.handlers['addPlayers'] = (_) => {
        'playersAdded': 2,
        'guardiansLinked': 1,
        'guardiansInvited': 1,
        'problems': ['Line 3: no name'],
      };
      functions.handlers['inviteGuardian'] = (_) => {'invited': true};
      final repo = FirestorePlayerRepository(db, functions);
      final result = await repo.addPlayers(_g, const [
        NewPlayer(
          name: 'Emma',
          jerseyNumber: '7',
          guardians: [NewGuardian(name: 'Maria', email: 'm@example.com')],
        ),
        NewPlayer(name: 'Arjun'),
      ]);
      expect(result.playersAdded, 2);
      expect(result.problems, ['Line 3: no name']);
      final sent = functions.lastData('addPlayers')! as Map;
      expect((sent['players'] as List).first, {
        'name': 'Emma',
        'jerseyNumber': '7',
        'position': null,
        'guardians': [
          {'name': 'Maria', 'email': 'm@example.com'},
        ],
      });

      await repo.removePlayer(_g, const PlayerId('emma'));
      await repo.requestGuardianLink(_g, const [PlayerId('emma')]);
      await repo.resolveGuardianRequest(
        _g,
        const PlayerId('emma'),
        const UserId('luis'),
        approve: true,
      );
      await repo.addMyPlayer(_g, name: 'Noah', jerseyNumber: '4');
      expect(
        await repo.inviteGuardian(
          _g,
          const PlayerId('emma'),
          email: 'l@example.com',
        ),
        isTrue,
      );
      await repo.removeGuardian(
        _g,
        const PlayerId('emma'),
        const UserId('luis'),
      );
      expect(functions.lastData('requestGuardianLink'), {
        'groupId': 'g1',
        'playerIds': ['emma'],
      });
      expect(functions.lastData('resolveGuardianLink'), {
        'groupId': 'g1',
        'playerId': 'emma',
        'uid': 'luis',
        'approve': true,
      });
      expect(
        functions.calls.map((c) => c.$1),
        containsAll(['removePlayer', 'addMyPlayer', 'removeGuardian']),
      );
      functions.handlers['inviteGuardian'] = (_) => <String, dynamic>{};
      expect(
        await repo.inviteGuardian(
          _g,
          const PlayerId('emma'),
          email: 'l@example.com',
        ),
        isFalse,
      );
    });

    test('maps refusals to failures', () async {
      final repo = FirestorePlayerRepository(db, functions);
      for (final (code, message, type) in [
        ('failed-precondition', 'too-many-players', isA<InvalidInput>()),
        ('failed-precondition', 'too-many-guardians', isA<InvalidInput>()),
        ('failed-precondition', 'other', isA<UnknownFailure>()),
        ('resource-exhausted', 'slow', isA<RateLimited>()),
        ('permission-denied', 'no', isA<PermissionDenied>()),
        ('invalid-argument', 'bad', isA<InvalidInput>()),
        ('unavailable', 'offline', isA<Offline>()),
      ]) {
        functions.fail('removePlayer', code, message);
        await expectLater(
          repo.removePlayer(_g, const PlayerId('emma')),
          throwsA(type),
        );
      }
    });
  });

  group('FirestoreEventRepository', () {
    const tz = 'America/Chicago';
    EventDraft draft({DateTime? date, bool allDay = false}) => EventDraft(
      timeZone: tz,
      type: EventType.game,
      opponent: 'Hawks',
      homeAway: HomeAway.home,
      locationName: 'Field 3',
      locationAddress: '1 Main St',
      date: date ?? DateTime(2026, 10, 20),
      allDay: allDay,
      arriveMinutesBefore: 30,
      rsvpDeadline: DateTime.utc(2026, 10, 19),
      reminderOffsets: const [60],
    );

    test('creates, reads, updates, cancels, and deletes an event', () async {
      final repo = FirestoreEventRepository(db, functions);
      final id = await repo.createEvent(
        _g,
        draft(),
        createdBy: const UserId('coach'),
        youth: true,
      );
      final d = (await db.doc('events/${id.value}').get()).data()!;
      expect(d['rsvpFor'], 'players');
      expect(d['rsvpCounts'], {'going': 0, 'maybe': 0, 'notGoing': 0});
      expect(d['startDate'], isNull);
      expect(d['location'], {'name': 'Field 3', 'address': '1 Main St'});

      final e = (await repo.watchEvent(id).first)!;
      expect(e.type, EventType.game);
      expect(e.title, 'vs. Hawks');
      expect(e.rsvpFor, RsvpFor.players);
      expect(e.location!.name, 'Field 3');
      expect(e.homeAway, HomeAway.home);
      expect(e.reminderOffsets, [60]);
      expect(e.canceledAt, isNull);

      await repo.updateEvent(e, draft(allDay: true));
      final updated = (await db.doc('events/${id.value}').get()).data()!;
      expect(updated['allDay'], isTrue);
      expect(updated['startDate'], '2026-10-20');

      await repo.cancelEvent(e, const UserId('coach'));
      expect((await repo.watchEvent(id).first)!.canceledBy, 'coach');
      await repo.deleteEvent(e);
      expect(await repo.watchEvent(id).first, isNull);
    });

    test('lists upcoming, past, ranges, and the next in a series', () async {
      for (var day = 1; day <= 6; day++) {
        await db.doc('events/e$day').set({
          'groupId': 'g1',
          'type': 'practice',
          'title': 'Practice $day',
          'startAt': Timestamp.fromDate(DateTime.utc(2026, 10, day, 18)),
          'endAt': Timestamp.fromDate(DateTime.utc(2026, 10, day, 19)),
          'seriesId': 's1',
          'rsvpCounts': {'going': day},
        });
      }
      final repo = FirestoreEventRepository(db, functions);
      final now = DateTime.utc(2026, 10, 3, 12);
      final upcoming = await repo.watchUpcoming(_g, now, limit: 2).first;
      expect(upcoming.events.map((e) => e.id.value), ['e3', 'e4']);
      expect(upcoming.events.first.rsvpCounts.going, 3);
      final more = await repo.loadMore(
        _g,
        upcoming.next!,
        past: false,
        limit: 2,
      );
      expect(more.events.map((e) => e.id.value), ['e5', 'e6']);
      final past = await repo.watchPast(_g, now).first;
      expect(past.events.map((e) => e.id.value), ['e2', 'e1']);
      expect(past.next, isNull);
      final range = await repo
          .watchRange(_g, DateTime.utc(2026, 10, 2), DateTime.utc(2026, 10, 4))
          .first;
      expect(range.map((e) => e.id.value), ['e2', 'e3']);
      final next = await repo.watchNextInSeries(_g, 's1', now).first;
      expect(next!.id.value, 'e3');
      expect(await repo.watchNextInSeries(_g, 'none', now).first, isNull);
    });

    test('reads a series', () async {
      await db.doc('eventSeries/s1').set({
        'groupId': 'g1',
        'timeZone': tz,
        'createdBy': 'coach',
        'recurrence': {
          'freq': 'weekly',
          'interval': 2,
          'byWeekday': [2, 4],
          'startDate': '2026-10-01',
          'count': 8,
          'skipDates': ['2026-10-15'],
        },
      });
      final repo = FirestoreEventRepository(db, functions);
      final s = (await repo.watchSeries('s1').first)!;
      expect(s.recurrence.byWeekday, [2, 4]);
      expect(s.recurrence.count, 8);
      expect(s.recurrence.skipDates, ['2026-10-15']);
      expect(await repo.watchSeries('none').first, isNull);
      final sparse = seriesFromFirestore('s', const {});
      expect(sparse.recurrence.startDate, '1970-01-01');
    });

    test('reads a sparse or locally canceled event', () {
      final e = eventFromFirestore('e', const {
        'canceledBy': 'coach',
        'rsvpEnabled': false,
      });
      expect(e.type, EventType.other);
      expect(e.canceledAt, isNotNull);
      expect(e.rsvpEnabled, isFalse);
      expect(e.rsvpCounts, const RsvpCounts());
    });

    test('maps write refusals to failures', () async {
      final event = eventFromFirestore('e1', const {'groupId': 'g1'});
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('not-found', isA<NotFound>()),
        ('unavailable', isA<Offline>()),
        ('aborted', isA<UnknownFailure>()),
      ]) {
        final db = FakeFirebaseFirestore();
        whenCalling(Invocation.method(#delete, null))
            .on(db.doc('events/e1'))
            .thenThrow(_fs(code));
        await expectLater(
          FirestoreEventRepository(db, functions).deleteEvent(event),
          throwsA(type),
        );
      }
    });

    test('saves series through saveEventSeries', () async {
      functions.handlers['saveEventSeries'] = (_) => {
        'seriesId': 's1',
        'created': 8,
        'removedRsvps': 2,
      };
      final repo = FirestoreEventRepository(db, functions);
      const rule = Recurrence(
        freq: RepeatFreq.weekly,
        startDate: '2026-10-01',
        byWeekday: [2],
        count: 8,
      );
      final template = draft().template;
      final created = await repo.createSeries(_g, rule, template, dryRun: true);
      expect(created.seriesId, 's1');
      expect(created.created, 8);
      expect(created.removedRsvps, 2);
      final sent = functions.lastData('saveEventSeries')! as Map;
      expect(sent['action'], 'create');
      expect(sent['dryRun'], isTrue);
      expect((sent['recurrence'] as Map)['byWeekday'], [2]);
      expect((sent['template'] as Map)['opponent'], 'Hawks');

      await repo.updateSeries(
        const EventId('e1'),
        SeriesScope.following,
        template,
        recurrence: rule,
        date: '2026-10-08',
      );
      final update = functions.lastData('saveEventSeries')! as Map;
      expect(update['scope'], 'following');
      expect((update['template'] as Map)['date'], '2026-10-08');
      expect(update.containsKey('recurrence'), isTrue);
      await repo.updateSeries(
        const EventId('e1'),
        SeriesScope.thisEvent,
        template,
        recurrence: rule,
      );
      expect(
        (functions.lastData('saveEventSeries')! as Map).containsKey(
          'recurrence',
        ),
        isFalse,
      );
      await repo.cancelSeries(const EventId('e1'), SeriesScope.thisEvent);
      expect(
        (functions.lastData('saveEventSeries')! as Map)['action'],
        'cancel',
      );
      functions.handlers.remove('saveEventSeries');
      final deleted = await repo.deleteSeries(
        const EventId('e1'),
        SeriesScope.following,
      );
      expect(deleted.created, 0);
      expect(
        recurrenceToJson(
          const Recurrence(
            freq: RepeatFreq.daily,
            startDate: '2026-10-01',
            byWeekday: [1],
          ),
        )['byWeekday'],
        isEmpty,
      );
    });

    test('maps series refusals to failures', () async {
      final repo = FirestoreEventRepository(db, functions);
      for (final (code, message, type) in [
        ('permission-denied', 'no', isA<PermissionDenied>()),
        ('not-found', 'gone', isA<NotFound>()),
        ('invalid-argument', 'bad', isA<InvalidInput>()),
        ('failed-precondition', 'Team storage is full', isA<StorageFull>()),
        ('resource-exhausted', 'storage full', isA<StorageFull>()),
        ('resource-exhausted', 'slow down', isA<RateLimited>()),
        ('deadline-exceeded', 'late', isA<Offline>()),
        ('internal', 'boom', isA<UnknownFailure>()),
      ]) {
        functions.fail('saveEventSeries', code, message);
        await expectLater(
          repo.cancelSeries(const EventId('e1'), SeriesScope.thisEvent),
          throwsA(type),
        );
      }
    });
  });
}
