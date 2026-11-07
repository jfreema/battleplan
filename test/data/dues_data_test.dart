// The Firestore dues repository (DUES-1 to DUES-3, ARCH §6.2): what it
// sends the saveDue and deleteDue callables, what it writes (payments on a
// charge, in a transaction on the charge as it is now), and how it reads
// dues, charges, their payments, and how to pay.
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
      requestId: 'req-12345678',
    );
    expect(fns.lastData('saveDue'), {
      'groupId': 'a',
      'title': 'Uniform fee',
      'amountCents': 4500,
      'dueOn': '2026-11-30',
      'note': 'Cash is fine too',
      'participantIds': ['emma', 'liam'],
      'requestId': 'req-12345678',
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
    // Adding people to it sends only them.
    await repo.edit(
      due,
      title: 'Uniforms',
      amountCents: 5000,
      dueOn: null,
      note: '',
      add: const [liam],
    );
    expect(fns.lastData('saveDue'), containsPair('participantIds', ['liam']));
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

    await repo.recordPayment(
      mine.first,
      id: 'pay-12345678',
      paidOn: '2026-11-05',
      by: by,
    );
    final paid = (await repo.watchDueCharges(g, mine.first.dueId).first)
        .firstWhere((c) => c.id == mine.first.id);
    expect(paid.status, DueStatus.paid);
    expect(paid.paidAt, isNotNull);
    expect(paid.paidCents, 4500);
  });

  group('payments (DUES-2)', () {
    Future<Map<String, dynamic>> doc(
      FakeFirebaseFirestore db,
      String id,
    ) async => (await db.doc('dueCharges/$id').get()).data()!;

    test('a part at a time, the rest in one go, and a mistake taken back, '
        'each from the charge as it is now', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreDuesRepository(db, FakeFunctions());
      await db.doc('dueCharges/d1_emma').set(charge('d1', 'emma'));
      // What the app had loaded before anything was paid.
      final stale = (await repo.watchDueCharges(g, 'd1').first).single;
      expect(stale.state, DueShareState.owes);

      await repo.recordPayment(
        stale,
        id: 'pay-aaaaaaaa',
        amountCents: 2000,
        paidOn: '2026-11-05',
        note: '  Venmo  ',
        by: by,
      );
      var x = await doc(db, 'd1_emma');
      expect(x['payments'], [
        {
          'id': 'pay-aaaaaaaa',
          'amountCents': 2000,
          'paidOn': '2026-11-05',
          'by': 'coach',
          'note': 'Venmo',
        },
      ]);
      expect(x['paidCents'], 2000);
      expect(x['status'], 'owed');
      expect(x['paidAt'], isNull);
      expect(x['updatedBy'], 'coach');

      // A retry of the same payment records nothing more.
      await repo.recordPayment(
        stale,
        id: 'pay-aaaaaaaa',
        amountCents: 2000,
        paidOn: '2026-11-05',
        by: by,
      );
      expect((await doc(db, 'd1_emma'))['paidCents'], 2000);

      // More than the $25 left now, though the stale copy shows $45.
      await expectLater(
        repo.recordPayment(
          stale,
          id: 'pay-bbbbbbbb',
          amountCents: 3000,
          paidOn: '2026-11-05',
          by: by,
        ),
        throwsA(
          isA<InvalidInput>().having((e) => e.message, 'message', 'tooMuch'),
        ),
      );

      // All that's left, from the stale copy: $25, not $45.
      await repo.recordPayment(
        stale,
        id: 'pay-cccccccc',
        paidOn: '2026-11-06',
        by: by,
      );
      x = await doc(db, 'd1_emma');
      expect(x['paidCents'], 4500);
      expect(x['status'], 'paid');
      expect(x['paidAt'], isA<Timestamp>());
      expect(
        [
          for (final p in x['payments'] as List<Object?>)
            (p! as Map)['amountCents'],
        ],
        [2000, 2500],
      );
      final read = (await repo.watchDueCharges(g, 'd1').first).single;
      expect(read.payments.map((p) => p.id), ['pay-aaaaaaaa', 'pay-cccccccc']);
      expect(read.payments.first.note, 'Venmo');
      expect(read.recordedCents, 4500);
      expect(read.state, DueShareState.paid);

      // Nothing left to pay.
      await expectLater(
        repo.recordPayment(
          stale,
          id: 'pay-dddddddd',
          paidOn: '2026-11-06',
          by: by,
        ),
        throwsA(
          isA<InvalidInput>().having(
            (e) => e.message,
            'message',
            'nothingLeft',
          ),
        ),
      );

      // The first was a mistake.
      await repo.undoPayment(stale, 'pay-aaaaaaaa', by: by);
      x = await doc(db, 'd1_emma');
      expect(
        [for (final p in x['payments'] as List<Object?>) (p! as Map)['id']],
        ['pay-cccccccc'],
      );
      expect(x['paidCents'], 2500);
      expect(x['status'], 'owed');
      expect(x['paidAt'], isNull);
      // Already taken back: nothing changes.
      await repo.undoPayment(stale, 'pay-aaaaaaaa', by: by);
      expect((await doc(db, 'd1_emma'))['paidCents'], 2500);

      // Waived: nothing more is recorded, and back to owed it owes the rest.
      await repo.setStatus(stale, DueStatus.waived, by: by);
      expect((await doc(db, 'd1_emma'))['status'], 'waived');
      await expectLater(
        repo.recordPayment(
          stale,
          id: 'pay-eeeeeeee',
          amountCents: 100,
          paidOn: '2026-11-06',
          by: by,
        ),
        throwsA(isA<InvalidInput>()),
      );
      await repo.setStatus(stale, DueStatus.owed, by: by);
      x = await doc(db, 'd1_emma');
      expect(x['status'], 'owed');
      expect(x['paidCents'], 2500);
    });

    test('waived no more, a share its payments cover is paid again', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreDuesRepository(db, FakeFunctions());
      await db.doc('dueCharges/d1_emma').set({
        ...charge('d1', 'emma'),
        'status': 'waived',
        'payments': [
          {
            'id': 'pay-aaaaaaaa',
            'amountCents': 4500,
            'paidOn': '2026-11-05',
            'by': 'coach',
            'note': '',
          },
        ],
        'paidCents': 4500,
      });
      final c = (await repo.watchDueCharges(g, 'd1').first).single;
      await repo.setStatus(c, DueStatus.owed, by: by);
      final x = await doc(db, 'd1_emma');
      expect(x['status'], 'paid');
      expect(x['paidAt'], isA<Timestamp>());
    });

    test('a share marked paid before payments were recorded reads as paid in '
        'full, and is marked not paid without any', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreDuesRepository(db, FakeFunctions());
      await db.doc('dueCharges/d1_emma').set({
        ...charge('d1', 'emma'),
        'status': 'paid',
        'paidAt': Timestamp.fromDate(DateTime.utc(2026, 11, 3)),
      });
      final c = (await repo.watchDueCharges(g, 'd1').first).single;
      expect(c.paidCents, 4500);
      expect(c.owedCents, 0);
      expect(c.recordsPayments, isFalse);
      expect(c.state, DueShareState.paid);
      // Paid in full: there's nothing to record, and no status of Paid
      // without a payment.
      await expectLater(
        repo.recordPayment(c, id: 'pay-aaaaaaaa', paidOn: '2026-11-06', by: by),
        throwsA(isA<InvalidInput>()),
      );
      await expectLater(
        repo.setStatus(c, DueStatus.paid, by: by),
        throwsA(isA<InvalidInput>()),
      );
      await repo.setStatus(c, DueStatus.owed, by: by);
      final x = await doc(db, 'd1_emma');
      expect(x['status'], 'owed');
      expect(x['paidAt'], isNull);
      expect(x.containsKey('payments'), isFalse);
      expect(x.containsKey('paidCents'), isFalse);
    });

    test('a share that is gone is not found; the cap is kept', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreDuesRepository(db, FakeFunctions());
      final gone = dueChargeFromFirestore('d9_x', charge('d9', 'x'));
      await expectLater(
        repo.recordPayment(
          gone,
          id: 'pay-aaaaaaaa',
          paidOn: '2026-11-06',
          by: by,
        ),
        throwsA(isA<NotFound>()),
      );
      await db.doc('dueCharges/d1_emma').set({
        ...charge('d1', 'emma'),
        'payments': [
          for (var i = 0; i < Limits.duePaymentsMax; i++)
            {
              'id': 'pay-$i-aaaaaa',
              'amountCents': 1,
              'paidOn': '2026-11-05',
              'by': 'coach',
              'note': '',
            },
        ],
        'paidCents': Limits.duePaymentsMax,
      });
      final full = (await repo.watchDueCharges(g, 'd1').first).single;
      await expectLater(
        repo.recordPayment(
          full,
          id: 'pay-bbbbbbbb',
          amountCents: 1,
          paidOn: '2026-11-06',
          by: by,
        ),
        throwsA(
          isA<InvalidInput>().having((e) => e.message, 'message', 'full'),
        ),
      );
    });

    test(
      'an amount below what someone paid comes back as InvalidInput',
      () async {
        final fns = FakeFunctions()
          ..fail('saveDue', 'failed-precondition', 'due-amount-below-paid');
        final repo = FirestoreDuesRepository(FakeFirebaseFirestore(), fns);
        const due = Due(id: 'd1', groupId: g, title: 'Fee', amountCents: 4500);
        await expectLater(
          repo.edit(due, title: 'Fee', amountCents: 100, dueOn: null, note: ''),
          throwsA(
            isA<InvalidInput>().having(
              (e) => e.message,
              'message',
              'due-amount-below-paid',
            ),
          ),
        );
        // Any other refusal of the kind stays unknown.
        fns.fail('saveDue', 'failed-precondition', 'team-archived');
        await expectLater(
          repo.edit(due, title: 'Fee', amountCents: 100, dueOn: null, note: ''),
          throwsA(isA<UnknownFailure>()),
        );
      },
    );
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
    // Everyone sees who saved it last.
    expect(p.updatedBy, 'coach');
  });

  test('reads unknown values safely', () {
    final c = dueChargeFromFirestore('x', const {'status': 'nope'});
    expect(c.payments, isEmpty);
    expect(c.recordedCents, isNull);
    final odd = dueChargeFromFirestore('x', const {
      'payments': [
        'not a payment',
        <String, Object?>{'id': 'p1'},
      ],
      'paidCents': 12.0,
    });
    expect(odd.payments.single.amountCents, 0);
    expect(odd.payments.single.paidOn, '');
    expect(odd.recordedCents, 12);
    expect(c.status, DueStatus.owed);
    expect(c.participantType, ParticipantType.member);
    expect(dueFromFirestore('d', const {}).title, '');
    expect(duesPaymentsFromFirestore(null).isEmpty, isTrue);
    expect(dueChargeFromFirestore('x', const {}).note, '');
    expect(
      dueChargeFromFirestore('x', const {'note': 'Jersey and hat.'}).note,
      'Jersey and hat.',
    );
  });
}
