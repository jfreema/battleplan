// Data-layer tests (SPEC §8.1): players and the schedule.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/data/firestore_player_repository.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
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
    test('watches active and pending players, links, and claims', () async {
      await db.doc('players/emma').set({
        'groupId': 'g1',
        'displayName': 'Emma',
        'jerseyNumber': '7',
        'position': 'Forward',
        'status': 'active',
      });
      await db.doc('players/noah').set({
        'groupId': 'g1',
        'displayName': 'Noah',
        'status': 'pending',
        'proposedBy': 'luis',
        'proposedRelation': 'guardian',
      });
      await db.doc('players/sam').set({
        'groupId': 'g1',
        'displayName': 'Sam',
        'status': 'pending',
        'proposedBy': 'sam',
        'proposedRelation': 'self',
      });
      await db.doc('players/x').set({
        'groupId': 'g2',
        'displayName': 'Other',
        'status': 'active',
      });
      await db.doc('playerGuardians/emma_maria').set({
        'groupId': 'g1',
        'playerId': 'emma',
        'uid': 'maria',
      });
      await db.doc('playerGuardians/emma_emma1').set({
        'groupId': 'g1',
        'playerId': 'emma',
        'uid': 'emma1',
        'relation': 'self',
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
        'relation': 'self',
      });
      final repo = FirestorePlayerRepository(db, functions);

      // Members ask for active players only (the rules hide pending ones).
      final players = await repo.watchPlayers(_g).first;
      expect(players.single.displayName, 'Emma');
      expect(players.single.jerseyNumber, '7');
      expect(players.single.status, PlayerStatus.active);
      final pending = await repo.watchPendingPlayers(_g).first;
      expect(pending.map((p) => p.displayName), ['Noah', 'Sam']);
      expect(pending.first.isPending, isTrue);
      expect(pending.first.proposedBy, 'luis');
      expect(pending.first.proposedRelation, PlayerRelation.guardian);
      final mine = await repo
          .watchMyPendingPlayers(_g, const UserId('sam'))
          .first;
      expect(mine.single.proposedRelation, PlayerRelation.self);

      // Old links without a relation are guardians.
      final links = await repo.watchGuardianLinks(_g).first;
      expect(
        {for (final l in links) l.uid.value: l.relation},
        {'maria': PlayerRelation.guardian, 'emma1': PlayerRelation.self},
      );
      final open = (await repo.watchPendingRequests(_g).first).single;
      expect(open.uid, const UserId('luis'));
      expect(open.relation, PlayerRelation.guardian);
      final asked = await repo.watchMyRequests(_g, const UserId('sam')).first;
      expect(asked.single.status, GuardianRequestStatus.declined);
      expect(asked.single.relation, PlayerRelation.self);
    });

    test('reads a player without a status as active', () {
      final p = playerFromFirestore('old', _g, const {'displayName': 'Old'});
      expect(p.status, PlayerStatus.active);
      expect(p.proposedRelation, isNull);
      expect(relationFromFirestore(null), PlayerRelation.guardian);
      expect(relationFromFirestore('self'), PlayerRelation.self);
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
        'selfLinked': 1,
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
        // An adult player's own email (PLAYER-1).
        NewPlayer(name: 'Arjun', email: 'arjun@example.com'),
      ]);
      expect(result.playersAdded, 2);
      expect(result.playersLinked, 1);
      expect(result.playersInvited, 0);
      expect(result.problems, ['Line 3: no name']);
      final sent = functions.lastData('addPlayers')! as Map;
      expect((sent['players'] as List).first, {
        'name': 'Emma',
        'jerseyNumber': '7',
        'position': null,
        'email': null,
        'guardians': [
          {'name': 'Maria', 'email': 'm@example.com'},
        ],
      });
      expect((sent['players'] as List).last, {
        'name': 'Arjun',
        'jerseyNumber': null,
        'position': null,
        'email': 'arjun@example.com',
        'guardians': <Object>[],
      });

      await repo.removePlayer(_g, const PlayerId('emma'));
      functions.handlers['claimPlayer'] = (_) => {'status': 'requested'};
      expect(
        await repo.claimPlayer(
          _g,
          const PlayerId('emma'),
          PlayerRelation.guardian,
        ),
        ClaimOutcome.requested,
      );
      expect(functions.lastData('claimPlayer'), {
        'groupId': 'g1',
        'playerId': 'emma',
        'relation': 'guardian',
      });
      // An admin's claim is approved at once (PLAYER-3).
      functions.handlers['claimPlayer'] = (_) => {'status': 'linked'};
      expect(
        await repo.claimPlayer(_g, const PlayerId('emma'), PlayerRelation.self),
        ClaimOutcome.linked,
      );
      await repo.resolvePlayerClaim(
        _g,
        const PlayerId('emma'),
        const UserId('luis'),
        approve: true,
      );
      functions.handlers['proposePlayer'] = (_) => {
        'playerId': 'p9',
        'status': 'pending',
      };
      expect(
        await repo.proposePlayer(
          _g,
          name: ' Noah ',
          relation: PlayerRelation.guardian,
          jerseyNumber: '4',
          position: ' ',
        ),
        PlayerStatus.pending,
      );
      expect(functions.lastData('proposePlayer'), {
        'groupId': 'g1',
        'displayName': 'Noah',
        'jerseyNumber': '4',
        'position': null,
        'relation': 'guardian',
      });
      functions.handlers['proposePlayer'] = (_) => {'status': 'active'};
      expect(
        await repo.proposePlayer(
          _g,
          name: 'Jared',
          relation: PlayerRelation.self,
        ),
        PlayerStatus.active,
      );
      // Whether the member who added it got linked (PLAYER-4).
      functions.handlers['resolvePendingPlayer'] = (_) => {
        'ok': true,
        'linked': false,
      };
      expect(
        await repo.resolvePendingPlayer(
          _g,
          const PlayerId('p9'),
          approve: true,
        ),
        isFalse,
      );
      functions.handlers['resolvePendingPlayer'] = (_) => {
        'ok': true,
        'linked': true,
      };
      expect(
        await repo.resolvePendingPlayer(
          _g,
          const PlayerId('p9'),
          approve: true,
        ),
        isTrue,
      );
      await repo.resolvePendingPlayer(_g, const PlayerId('p9'), approve: false);
      expect(functions.lastData('resolvePendingPlayer'), {
        'groupId': 'g1',
        'playerId': 'p9',
        'approve': false,
      });
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
      expect(functions.lastData('resolvePlayerClaim'), {
        'groupId': 'g1',
        'playerId': 'emma',
        'uid': 'luis',
        'approve': true,
      });
      expect(
        functions.calls.map((c) => c.$1),
        containsAll(['removePlayer', 'removeGuardian']),
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
        ('failed-precondition', 'player-already-claimed', isA<InvalidInput>()),
        ('failed-precondition', 'already-a-player', isA<InvalidInput>()),
        ('failed-precondition', 'already-linked', isA<InvalidInput>()),
        ('failed-precondition', 'team-archived', isA<PermissionDenied>()),
        ('not-found', 'no-player', isA<NotFound>()),
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

  group('FirestorePlayerRepository player details (PLAYER-12)', () {
    const emma = PlayerId('emma');
    const maria = UserId('maria');
    const coach = UserId('coach');

    /// Exactly the keys the rules allow (ARCH §6.2 `playerDetails`).
    const allowed = {
      'groupId',
      'dateOfBirth',
      'emergencyContacts',
      'medicalNotes',
      'medicalConsentAt',
      'medicalConsentBy',
      'notes',
      'updatedBy',
      'updatedAt',
    };

    Future<Map<String, dynamic>> stored() async =>
        (await db.doc('playerDetails/emma').get()).data()!;

    test('saves the shape the rules want, recording consent for new medical '
        'notes', () async {
      final repo = FirestorePlayerRepository(db, functions);
      await repo.savePlayerDetails(
        const PlayerDetails(
          playerId: emma,
          groupId: _g,
          dateOfBirth: '2014-03-03',
          emergencyContacts: [
            EmergencyContact(
              name: ' Maria R ',
              phone: ' 555-0100 ',
              relationship: 'Mom',
            ),
            // No relationship: the key is left out.
            EmergencyContact(name: 'Luis', phone: '555-0101', relationship: ''),
            // Nothing filled in: dropped.
            EmergencyContact(name: ' ', phone: ''),
          ],
          medicalNotes: ' Peanut allergy ',
          notes: 'Wears glasses',
        ),
        by: maria,
      );
      final d = await stored();
      expect(d.keys.toSet(), allowed);
      expect(d['groupId'], 'g1');
      expect(d['dateOfBirth'], '2014-03-03');
      expect(d['emergencyContacts'], [
        {'name': 'Maria R', 'phone': '555-0100', 'relationship': 'Mom'},
        {'name': 'Luis', 'phone': '555-0101'},
      ]);
      expect(d['medicalNotes'], 'Peanut allergy');
      expect(d['medicalConsentAt'], isA<Timestamp>());
      expect(d['medicalConsentBy'], 'maria');
      expect(d['notes'], 'Wears glasses');
      expect(d['updatedBy'], 'maria');
      expect(d['updatedAt'], isA<Timestamp>());
    });

    test('without medical notes, writes no consent at all', () async {
      final repo = FirestorePlayerRepository(db, functions);
      await repo.savePlayerDetails(
        const PlayerDetails(playerId: emma, groupId: _g, notes: 'Lefty'),
        by: coach,
      );
      final d = await stored();
      expect(
        d.keys.toSet(),
        allowed.difference({'medicalConsentAt', 'medicalConsentBy'}),
      );
      expect(d['dateOfBirth'], isNull);
      expect(d['medicalNotes'], isNull);
      expect(d['emergencyContacts'], isEmpty);
    });

    test('keeps the consent when the medical notes are unchanged, records it '
        'again when they change, and clears it with them', () async {
      final first = Timestamp.fromDate(DateTime.utc(2026));
      await db.doc('playerDetails/emma').set({
        'groupId': 'g1',
        'dateOfBirth': null,
        'emergencyContacts': <Object>[],
        'medicalNotes': 'Peanut allergy',
        'medicalConsentAt': first,
        'medicalConsentBy': 'maria',
        'notes': null,
        'updatedBy': 'maria',
        'updatedAt': first,
      });
      final repo = FirestorePlayerRepository(db, functions);
      final before = await repo.watchPlayerDetails(emma).first;
      expect(before!.medicalConsentAt, first.toDate());

      // The same notes, by someone else: the consent stays as it was.
      await repo.savePlayerDetails(
        before.copyWith(notes: 'Wears glasses'),
        by: coach,
        stored: before,
      );
      var d = await stored();
      expect(d['medicalConsentAt'], first);
      expect(d['medicalConsentBy'], 'maria');
      expect(d['notes'], 'Wears glasses');
      expect(d['updatedBy'], 'coach');

      // Changed notes: consent recorded now, by whoever changed them.
      final kept = (await repo.watchPlayerDetails(emma).first)!;
      await repo.savePlayerDetails(
        kept.copyWith(medicalNotes: 'Peanut and egg allergy'),
        by: coach,
        stored: kept,
      );
      d = await stored();
      expect(d['medicalNotes'], 'Peanut and egg allergy');
      expect(d['medicalConsentAt'], isNot(first));
      expect(d['medicalConsentAt'], isA<Timestamp>());
      expect(d['medicalConsentBy'], 'coach');

      // Cleared notes clear the consent with them.
      final changed = (await repo.watchPlayerDetails(emma).first)!;
      await repo.savePlayerDetails(
        changed.copyWith(medicalNotes: '  '),
        by: maria,
        stored: changed,
      );
      d = await stored();
      expect(d.keys.toSet(), allowed);
      expect(d['medicalNotes'], isNull);
      expect(d['medicalConsentAt'], isNull);
      expect(d['medicalConsentBy'], isNull);
    });

    test("watches one player's details, and a team's", () async {
      await db.doc('playerDetails/emma').set({
        'groupId': 'g1',
        'dateOfBirth': '2014-03-03',
        'emergencyContacts': [
          {'name': 'Maria', 'phone': '555-0100', 'relationship': 'Mom'},
          {'name': 'Luis', 'phone': '555-0101'},
          'not a contact',
        ],
        'medicalNotes': 'Peanut allergy',
        'medicalConsentAt': Timestamp.fromDate(DateTime.utc(2026)),
        'medicalConsentBy': 'maria',
        'notes': 'Wears glasses',
        'updatedBy': 'maria',
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 2)),
      });
      await db.doc('playerDetails/noah').set({
        'groupId': 'g1',
        'dateOfBirth': '2015-06-01',
      });
      await db.doc('playerDetails/x').set({
        'groupId': 'g2',
        'dateOfBirth': '2010-01-01',
      });
      final repo = FirestorePlayerRepository(db, functions);
      final d = (await repo.watchPlayerDetails(emma).first)!;
      expect(d.playerId, emma);
      expect(d.groupId, _g);
      expect(d.dateOfBirth, '2014-03-03');
      expect(d.emergencyContacts, const [
        EmergencyContact(name: 'Maria', phone: '555-0100', relationship: 'Mom'),
        EmergencyContact(name: 'Luis', phone: '555-0101'),
      ]);
      expect(d.medicalNotes, 'Peanut allergy');
      expect(d.medicalConsentAt!.toUtc(), DateTime.utc(2026));
      expect(d.medicalConsentBy, 'maria');
      expect(d.notes, 'Wears glasses');
      expect(d.updatedBy, 'maria');
      expect(d.updatedAt!.toUtc(), DateTime.utc(2026, 2));
      // A player with no details yet.
      expect(
        await repo.watchPlayerDetails(const PlayerId('liam')).first,
        isNull,
      );

      final team = await repo.watchTeamPlayerDetails(_g).first;
      expect(team.map((d) => d.playerId.value), ['emma', 'noah']);
      expect(team.last.emergencyContacts, isEmpty);
      expect(team.last.medicalConsentAt, isNull);
    });

    test('a missing field reads as empty', () {
      final d = playerDetailsFromFirestore('emma', const {});
      expect(d.groupId, const GroupId(''));
      expect(d.dateOfBirth, isNull);
      expect(d.emergencyContacts, isEmpty);
      expect(d.updatedAt, isNull);
      final contact = playerDetailsFromFirestore('emma', const {
        'emergencyContacts': [<String, Object?>{}],
      }).emergencyContacts.single;
      expect(contact, const EmergencyContact(name: '', phone: ''));
    });

    test('deletes them', () async {
      await db.doc('playerDetails/emma').set({'groupId': 'g1'});
      final repo = FirestorePlayerRepository(db, functions);
      await repo.deletePlayerDetails(emma);
      expect((await db.doc('playerDetails/emma').get()).exists, isFalse);
    });

    test('maps refused writes to failures', () async {
      for (final (code, type) in [
        ('permission-denied', isA<PermissionDenied>()),
        ('unavailable', isA<Offline>()),
        ('aborted', isA<UnknownFailure>()),
      ]) {
        final db = FakeFirebaseFirestore();
        final doc = db.doc('playerDetails/emma');
        whenCalling(Invocation.method(#set, null)).on(doc).thenThrow(_fs(code));
        whenCalling(Invocation.method(#delete, null))
            .on(doc)
            .thenThrow(_fs(code));
        final repo = FirestorePlayerRepository(db, functions);
        await expectLater(
          repo.savePlayerDetails(
            const PlayerDetails(playerId: emma, groupId: _g, notes: 'Lefty'),
            by: maria,
          ),
          throwsA(type),
        );
        await expectLater(repo.deletePlayerDetails(emma), throwsA(type));
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
      );
      final d = (await db.doc('events/${id.value}').get()).data()!;
      // One team type: every event takes per-player RSVPs, so it's not
      // written any more.
      expect(d.containsKey('rsvpFor'), isFalse);
      expect(d['rsvpCounts'], {'going': 0, 'maybe': 0, 'notGoing': 0});
      expect(d['startDate'], isNull);
      expect(d['location'], {'name': 'Field 3', 'address': '1 Main St'});

      final e = (await repo.watchEvent(id).first)!;
      expect(e.type, EventType.game);
      expect(e.title, 'vs. Hawks');
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
