// Event assignments in Firestore (SCHED-15): what the app writes and reads,
// and how a refused write reads in the app.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/schedule/data/firestore_assignment_repository.dart';
import 'package:battleplan/features/schedule/domain/assignment.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

FirebaseException _fs(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreAssignmentRepository repo;
  const g = GroupId('g1');
  const coach = UserId('coach');
  const alex = UserId('alex');

  final event = Event(
    id: const EventId('e1'),
    groupId: g,
    type: EventType.game,
    title: 'vs. Eagles',
    startAt: DateTime.utc(2026, 11, 1, 15),
    endAt: DateTime.utc(2026, 11, 1, 16, 30),
    timeZone: 'America/Chicago',
    createdBy: 'coach',
  );

  Future<List<Assignment>> current() => repo.watchForEvent(g, event.id).first;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreAssignmentRepository(db);
  });

  test('adds a task with every field the rules expect', () async {
    await repo.add(
      event,
      kind: AssignmentKind.snacks,
      label: '  Halftime oranges ',
      by: coach,
    );
    final docs = (await db.collection(Collections.assignments).get()).docs;
    expect(docs, hasLength(1));
    final x = docs.single.data();
    expect(x.keys.toSet(), {
      'groupId',
      'eventId',
      'kind',
      'label',
      'assigneeUid',
      'assignedBy',
      'createdBy',
      'createdAt',
      'updatedAt',
    });
    expect(x['groupId'], 'g1');
    expect(x['eventId'], 'e1');
    expect(x['kind'], 'snacks');
    expect(x['label'], 'Halftime oranges');
    expect(x['assigneeUid'], isNull);
    expect(x['assignedBy'], isNull);
    expect(x['createdBy'], 'coach');
  });

  test('a blank label is none, and a long one is cut to the limit', () async {
    await repo.add(event, kind: AssignmentKind.drinks, label: '   ', by: coach);
    await repo.add(
      event,
      kind: AssignmentKind.other,
      label: 'x' * 60,
      by: coach,
    );
    final list = await current();
    expect(list.first.label, isNull);
    expect(list.last.label, hasLength(Limits.assignmentLabelMax));
  });

  test('an admin can add a task with someone on it', () async {
    await repo.add(
      event,
      kind: AssignmentKind.scorekeeper,
      assignee: alex,
      by: coach,
    );
    final a = (await current()).single;
    expect(a.assigneeUid, 'alex');
    expect(a.assignedBy, 'coach');
    expect(a.volunteered, isFalse);
    expect(a.isHeldBy('alex'), isTrue);
  });

  test(
    'volunteering, giving it up, assigning, editing, and removing',
    () async {
      await repo.add(event, kind: AssignmentKind.snacks, by: coach);
      var a = (await current()).single;
      expect(a.isOpen, isTrue);

      await repo.volunteer(a, alex);
      a = (await current()).single;
      expect(a.assigneeUid, 'alex');
      expect(a.assignedBy, 'alex');
      expect(a.volunteered, isTrue);

      await repo.giveUp(a);
      a = (await current()).single;
      expect(a.isOpen, isTrue);
      expect(a.assignedBy, isNull);

      await repo.assign(a, alex, by: coach);
      a = (await current()).single;
      expect(a.assigneeUid, 'alex');
      expect(a.assignedBy, 'coach');

      await repo.assign(a, null, by: coach);
      a = (await current()).single;
      expect(a.isOpen, isTrue);

      await repo.edit(a, kind: AssignmentKind.other, label: 'Field setup');
      a = (await current()).single;
      expect(a.kind, AssignmentKind.other);
      expect(a.label, 'Field setup');

      await repo.remove(a);
      expect(await current(), isEmpty);
    },
  );

  test("lists only this event's tasks, in the order they were added", () async {
    final other = event.copyWith(id: const EventId('e2'));
    await db.collection(Collections.assignments).doc('b').set({
      'groupId': 'g1',
      'eventId': 'e1',
      'kind': 'drinks',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 2)),
    });
    await db.collection(Collections.assignments).doc('a').set({
      'groupId': 'g1',
      'eventId': 'e1',
      'kind': 'snacks',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10)),
    });
    await repo.add(other, kind: AssignmentKind.scorekeeper, by: coach);
    final list = await current();
    expect(
      [for (final a in list) a.kind],
      [AssignmentKind.snacks, AssignmentKind.drinks],
    );
  });

  test('reads a sparse document with defaults', () {
    final a = assignmentFromFirestore('x', const {});
    expect(a.kind, AssignmentKind.other);
    expect(a.isOpen, isTrue);
    expect(a.createdBy, '');
    expect(a.createdAt, isNull);
  });

  test('maps refusals to failures', () async {
    for (final (code, type) in [
      ('permission-denied', isA<PermissionDenied>()),
      ('unavailable', isA<Offline>()),
      ('not-found', isA<NotFound>()),
      ('aborted', isA<UnknownFailure>()),
    ]) {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreAssignmentRepository(db);
      await db.collection(Collections.assignments).doc('a1').set({
        'groupId': 'g1',
        'eventId': 'e1',
        'kind': 'snacks',
      });
      final a = assignmentFromFirestore('a1', const {
        'groupId': 'g1',
        'eventId': 'e1',
        'kind': 'snacks',
      });
      whenCalling(Invocation.method(#update, null))
          .on(db.collection(Collections.assignments).doc('a1'))
          .thenThrow(_fs(code));
      await expectLater(repo.volunteer(a, alex), throwsA(type));
      whenCalling(Invocation.method(#delete, null))
          .on(db.collection(Collections.assignments).doc('a1'))
          .thenThrow(_fs(code));
      await expectLater(repo.remove(a), throwsA(type));
    }
  });
}
