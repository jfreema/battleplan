// The Firestore dues repository (DUES-1 to DUES-3, ARCH §6.2): what it
// sends the saveDue and deleteDue callables, what it writes, and how it
// reads dues, charges, and how to pay.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/dues/data/firestore_dues_repository.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_functions.dart';

void main() {
  const g = GroupId('a');
  const by = UserId('coach');

  const emma = (type: ParticipantType.player, id: 'emma', name: 'Emma #7');
  const liam = (type: ParticipantType.player, id: 'liam', name: 'Liam #9');

  Map<String, Object?> charge(String dueId, String who, {String g = 'a'}) => {
    'groupId': g,
    'dueId': dueId,
    'title': 'Uniform fee',
    'amountCents': 4500,
    'dueOn': '2026-11-30',
    'participantType': 'player',
    'participantId': who,
    'participantName': who,
    'status': 'owed',
    'paidAt': null,
    'updatedBy': 'coach',
  };

  test('new, edited and deleted dues go through the callables', () async {
    final db = FakeFirebaseFirestore();
    final fns = FakeFunctions();
    final repo = FirestoreDuesRepository(db, fns);
    await repo.create(
      g,
      title: '  Uniform fee  ',
      amountCents: 4500,
      dueOn: '2026-11-30',
      note: 'Cash is fine too',
      payers: const [emma, liam],
    );
    expect(fns.lastData('saveDue'), {
      'groupId': 'a',
      'title': 'Uniform fee',
      'amountCents': 4500,
      'dueOn': '2026-11-30',
      'note': 'Cash is fine too',
      'participantIds': ['emma', 'liam'],
    });
    const due = Due(
      id: 'd1',
      groupId: g,
      title: 'Uniform fee',
      amountCents: 4500,
    );
    await repo.edit(
      due,
      title: 'Uniforms',
      amountCents: 5000,
      dueOn: null,
      note: '',
    );
    expect(fns.lastData('saveDue'), {
      'groupId': 'a',
      'dueId': 'd1',
      'title': 'Uniforms',
      'amountCents': 5000,
      'dueOn': null,
      'note': '',
    });
    await repo.remove(due);
    expect(fns.lastData('deleteDue'), {'dueId': 'd1'});
    // Nothing written from the app: the server writes the due and charges.
    expect((await db.collection('dues').get()).docs, isEmpty);
    expect((await db.collection('dueCharges').get()).docs, isEmpty);
  });

  test("the callables' refusals become failures", () async {
    final fns = FakeFunctions();
    final repo = FirestoreDuesRepository(FakeFirebaseFirestore(), fns);
    const due = Due(id: 'd1', groupId: g, title: 'Fee', amountCents: 100);
    for (final (code, type) in [
      ('permission-denied', PermissionDenied),
      ('not-found', NotFound),
      ('invalid-argument', InvalidInput),
      ('unauthenticated', Unauthenticated),
      ('unavailable', Offline),
      ('failed-precondition', UnknownFailure),
    ]) {
      fns.fail('deleteDue', code);
      await expectLater(
        repo.remove(due),
        throwsA(isA<AppFailure>().having((f) => f.runtimeType, 'type', type)),
      );
    }
  });

  test('one due shows its own charges, and mine only mine', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreDuesRepository(db, FakeFunctions());
    await db.doc('dueCharges/d1_emma').set(charge('d1', 'emma'));
    await db.doc('dueCharges/d1_liam').set(charge('d1', 'liam'));
    await db.doc('dueCharges/d2_emma').set(charge('d2', 'emma'));
    await db.doc('dueCharges/dx_emma').set(charge('d1', 'emma', g: 'b'));
    await db.doc('dues/d1').set({
      'groupId': 'a',
      'title': 'Uniform fee',
      'amountCents': 4500,
      'dueOn': '2026-11-30',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11)),
    });
    final dues = await repo.watchDues(g).first;
    expect(dues.single.amountCents, 4500);
    final one = await repo.watchDueCharges(g, 'd1').first;
    expect(one.map((c) => c.id).toSet(), {'d1_emma', 'd1_liam'});
    final mine = await repo.watchMine(g, const [emma]).first;
    expect(mine.map((c) => c.id).toSet(), {'d1_emma', 'd2_emma'});
    expect(await repo.watchMine(g, const []).first, isEmpty);

    await repo.setStatus(mine.first, DueStatus.paid, by: by);
    final paid = (await repo.watchDueCharges(g, mine.first.dueId).first)
        .firstWhere((c) => c.id == mine.first.id);
    expect(paid.status, DueStatus.paid);
    expect(paid.paidAt, isNotNull);
  });

  test('past the limit, the newest dues show, newest first', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreDuesRepository(db, FakeFunctions());
    const n = Limits.queryLimitMax + 1;
    // Written oldest first, so the store's own order starts with the oldest.
    for (var i = 0; i < n; i++) {
      await db.doc('dues/d$i').set({
        'groupId': 'a',
        'title': 'Due $i',
        'amountCents': 100,
        'createdAt': Timestamp.fromDate(
          DateTime.utc(2026).add(Duration(hours: i)),
        ),
      });
    }
    final dues = await repo.watchDues(g).first;
    expect(dues, hasLength(Limits.queryLimitMax));
    expect(dues.first.id, 'd${n - 1}');
    expect(dues.last.id, 'd1');
    expect(dues.any((d) => d.id == 'd0'), isFalse);
  });

  group('mergePayerCharges', () {
    DueCharge c(String id) => dueChargeFromFirestore(id, charge('d', id));

    test('waits for every payer, then shows them all', () async {
      final a = StreamController<List<DueCharge>>();
      final b = StreamController<List<DueCharge>>();
      final out = <List<DueCharge>>[];
      final sub = mergePayerCharges([a.stream, b.stream]).listen(out.add);
      a.add([c('emma')]);
      await pumpEventQueue();
      expect(out, isEmpty);
      b.add([c('liam')]);
      await pumpEventQueue();
      expect(out.single.map((x) => x.id), ['emma', 'liam']);
      await sub.cancel();
    });

    test(
      'a payer whose query fails owes nothing, and the rest still show',
      () async {
        final a = StreamController<List<DueCharge>>();
        final b = StreamController<List<DueCharge>>();
        final out = <List<DueCharge>>[];
        Object? error;
        final sub = mergePayerCharges([a.stream, b.stream])
            .listen(out.add, onError: (Object e) => error = e);
        a.add([c('emma')]);
        b.addError(const PermissionDenied());
        await pumpEventQueue();
        expect(out.single.map((x) => x.id), ['emma']);
        expect(error, isNull);
        await sub.cancel();
      },
    );

    test('fails only when every payer does', () async {
      final a = StreamController<List<DueCharge>>();
      final b = StreamController<List<DueCharge>>();
      Object? error;
      final sub = mergePayerCharges([a.stream, b.stream])
          .listen((_) {}, onError: (Object e) => error = e);
      a.addError(const Offline());
      await pumpEventQueue();
      expect(error, isNull);
      b.addError(const Offline());
      await pumpEventQueue();
      expect(error, isA<Offline>());
      await sub.cancel();
    });
  });

  test('how to pay is one doc per team, empty until saved', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreDuesRepository(db, FakeFunctions());
    expect((await repo.watchPayments(g).first).isEmpty, isTrue);
    await repo.savePayments(
      g,
      const DuesPayments(venmo: '@thunder', appleCash: '555-0100'),
      by: by,
    );
    final p = await repo.watchPayments(g).first;
    expect(p.venmo, '@thunder');
    expect(p.appleCash, '555-0100');
    expect(p.cashApp, '');
    final doc = await db.doc('duesPayments/a').get();
    expect(doc.data(), containsPair('updatedBy', 'coach'));
  });

  test('reads unknown values safely', () {
    final c = dueChargeFromFirestore('x', const {'status': 'nope'});
    expect(c.status, DueStatus.owed);
    expect(c.participantType, ParticipantType.member);
    expect(dueFromFirestore('d', const {}).title, '');
    expect(duesPaymentsFromFirestore(null).isEmpty, isTrue);
  });
}
