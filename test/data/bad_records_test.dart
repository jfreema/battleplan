// Data-layer tests (SPEC §8.1): one record the app can't read (a field of
// the wrong type) is left out of its list and told once to the crash log,
// by its kind and id, and never stops the rest, or Load more (#40).
import 'package:battleplan/core/bad_records.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/documents/data/firestore_document_repository.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/schedule/data/firestore_assignment_repository.dart';
import 'package:battleplan/features/schedule/data/firestore_event_repository.dart';
import 'package:battleplan/features/schedule/data/firestore_rsvp_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_functions.dart';

const _g = GroupId('g1');

void main() {
  late FakeFirebaseFirestore db;
  late List<String> told;
  late BadRecords bad;

  setUp(() {
    db = FakeFirebaseFirestore();
    told = [];
    bad = BadRecords((e, _) => told.add('$e'));
  });

  Future<void> event(String id, int day, {Object? title}) =>
      db.doc('events/$id').set({
        'groupId': 'g1',
        'type': 'practice',
        'title': title ?? 'Practice $day',
        'startAt': Timestamp.fromDate(DateTime.utc(2030, 10, day, 18)),
        'endAt': Timestamp.fromDate(DateTime.utc(2030, 10, day, 19)),
        'timeZone': 'America/Chicago',
      });

  group('events', () {
    late FirestoreEventRepository repo;
    setUp(
      () =>
          repo = FirestoreEventRepository(db, FakeFunctions(), badRecords: bad),
    );

    test('a bad one is left out and told once; the rest show', () async {
      await event('a', 1);
      await event('bad', 2, title: 42);
      await event('c', 3);
      final from = DateTime.utc(2030);
      final page = await repo.watchUpcoming(_g, from).first;
      expect([for (final e in page.events) e.id.value], ['a', 'c']);
      expect(told, hasLength(1));
      expect(told.single, contains('Unreadable event bad'));
      // Its contents never: only the kind and the id.
      expect(told.single, isNot(contains('42')));
      // Read again, live or by range, it isn't told again.
      await repo.watchUpcoming(_g, from).first;
      final range = await repo.watchRange(_g, from, DateTime.utc(2031)).first;
      expect(range, hasLength(2));
      final between = await repo.eventsBetween(_g, from, DateTime.utc(2031));
      expect(between, hasLength(2));
      expect(told, hasLength(1));
    });

    test('a bad one at the end of a page never stops Load more', () async {
      await event('a', 1);
      await event('bad', 2, title: 42);
      await event('c', 3);
      final from = DateTime.utc(2030);
      final first = await repo.watchUpcoming(_g, from, limit: 2).first;
      expect([for (final e in first.events) e.id.value], ['a']);
      expect(first.next, isNotNull);
      final more = await repo.loadMore(_g, first.next!, past: false, limit: 2);
      expect([for (final e in more.events) e.id.value], ['c']);
    });

    test("one event's page errors, so it can say so; told once", () async {
      await event('bad', 2, title: 42);
      await expectLater(
        repo.watchEvent(const EventId('bad')).first,
        throwsA(anything),
      );
      expect(told.single, contains('Unreadable event bad'));
    });
  });

  test('answers: a bad one is left out and told', () async {
    final repo = FirestoreRsvpRepository(db, badRecords: bad);
    for (final (id, name) in [('e1_a', 'Ann'), ('e1_b', 42), ('e1_c', 'Cy')]) {
      await db.doc('rsvps/$id').set({
        'groupId': 'g1',
        'eventId': 'e1',
        'participantType': 'member',
        'participantId': id,
        'participantName': name,
        'status': 'going',
      });
    }
    final answers = await repo.watchForEvent(_g, const EventId('e1')).first;
    expect([for (final r in answers) r.participantName], ['Ann', 'Cy']);
    expect(told.single, contains('Unreadable rsvp e1_b'));
  });

  test('tasks: a bad one is left out and told', () async {
    final repo = FirestoreAssignmentRepository(db, badRecords: bad);
    for (final (id, label) in [('t1', 'Snacks'), ('t2', 42)]) {
      await db.doc('assignments/$id').set({
        'groupId': 'g1',
        'eventId': 'e1',
        'kind': 'other',
        'label': label,
        'createdBy': 'coach',
        'createdAt': Timestamp.fromDate(DateTime.utc(2030)),
      });
    }
    final tasks = await repo.watchForEvent(_g, const EventId('e1')).first;
    expect([for (final t in tasks) t.label], ['Snacks']);
    expect(told.single, contains('Unreadable assignment t2'));
  });

  group('documents', () {
    late FirestoreDocumentRepository repo;
    setUp(
      () => repo = FirestoreDocumentRepository(
        db,
        MockFirebaseStorage(),
        badRecords: bad,
      ),
    );

    Future<void> doc(String id, Object name, {bool pinned = false}) =>
        db.doc('groupDocuments/$id').set({
          'groupId': 'g1',
          'kind': 'link',
          'name': name,
          'nameLower': '$name'.toLowerCase(),
          'url': 'https://example.com',
          'pinned': pinned,
          'uploadedBy': 'coach',
          'createdAt': Timestamp.fromDate(DateTime.utc(2030)),
        });

    test(
      'a bad one is left out of the list and the pinned, told once',
      () async {
        await doc('d1', 'Roster', pinned: true);
        await doc('d2', 42, pinned: true);
        await doc('d3', 'Waiver');
        final page = await repo.watchFirstPage(_g, DocumentSort.name).first;
        expect([for (final d in page.documents) d.name], ['Roster', 'Waiver']);
        final pinned = await repo.watchPinned(_g).first;
        expect([for (final d in pinned) d.name], ['Roster']);
        expect(told, hasLength(1));
        expect(told.single, contains('Unreadable document d2'));
      },
    );

    test("one document's page errors, so it can say so", () async {
      await doc('d2', 42);
      await expectLater(
        repo.watchDocument(const DocumentId('d2')).first,
        throwsA(anything),
      );
      expect(told.single, contains('Unreadable document d2'));
    });
  });
}
