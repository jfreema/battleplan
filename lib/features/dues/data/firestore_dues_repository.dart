import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/dues/domain/dues_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Dues in Firestore (DUES-1 to DUES-3, ARCH §6.2): `dues` for the admins,
/// `dueCharges` (one per person, id `<dueId>_<participantId>`) that each
/// person reads their own of, and `duesPayments/<groupId>`. Dues and
/// their charges change through the `saveDue` and `deleteDue` callables;
/// payments and waivers are written to a charge in a transaction, which
/// the rules check is one payment added or taken back.
class FirestoreDuesRepository implements DuesRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _dues =>
      _db.collection(Collections.dues);
  CollectionReference<Map<String, dynamic>> get _charges =>
      _db.collection(Collections.dueCharges);

  @override
  Stream<List<Due>> watchDues(GroupId groupId) => _dues
      .where('groupId', isEqualTo: groupId.value)
      .orderBy('createdAt', descending: true)
      .limit(Limits.queryLimitMax)
      .snapshots()
      .map((snap) {
        final list = [
          for (final d in snap.docs) dueFromFirestore(d.id, d.data()),
        ];
        // Newest first; one just added (no server time yet) on top.
        int at(Due d) => d.createdAt?.millisecondsSinceEpoch ?? 1 << 53;
        return list..sort((a, b) => at(b).compareTo(at(a)));
      });

  @override
  Stream<List<DueCharge>> watchDueCharges(GroupId groupId, String dueId) =>
      _charges
          .where('groupId', isEqualTo: groupId.value)
          .where('dueId', isEqualTo: dueId)
          .limit(Limits.duesChargesMax)
          .snapshots()
          .map(
            (snap) => [
              for (final d in snap.docs) dueChargeFromFirestore(d.id, d.data()),
            ],
          );

  @override
  Stream<List<DueCharge>> watchMine(GroupId groupId, List<DuePayer> payers) {
    if (payers.isEmpty) return Stream.value(const []);
    return mergePayerCharges([
      for (final p in payers)
        _charges
            .where('groupId', isEqualTo: groupId.value)
            .where('participantType', isEqualTo: p.type.value)
            .where('participantId', isEqualTo: p.id)
            .limit(Limits.queryLimitMax)
            .snapshots()
            .map(
              (snap) => [
                for (final d in snap.docs)
                  dueChargeFromFirestore(d.id, d.data()),
              ],
            ),
    ]);
  }

  @override
  Stream<DuesPayments> watchPayments(GroupId groupId) => _db
      .collection(Collections.duesPayments)
      .doc(groupId.value)
      .snapshots()
      .map((d) => duesPaymentsFromFirestore(d.data()));

  @override
  Future<void> create(
    GroupId groupId, {
    required String title,
    required int amountCents,
    required String? dueOn,
    required String note,
    required List<DuePayer> payers,
    String? requestId,
  }) => _call('saveDue', {
    'groupId': groupId.value,
    'title': _clip(title, Limits.dueTitleMax),
    'amountCents': amountCents,
    'dueOn': dueOn,
    'note': _clip(note, Limits.dueNoteMax),
    'participantIds': [for (final p in payers) p.id],
    'requestId': ?requestId,
  });

  @override
  Future<void> edit(
    Due due, {
    required String title,
    required int amountCents,
    required String? dueOn,
    required String note,
    List<DuePayer> add = const [],
  }) => _call('saveDue', {
    'groupId': due.groupId.value,
    'dueId': due.id,
    'title': _clip(title, Limits.dueTitleMax),
    'amountCents': amountCents,
    'dueOn': dueOn,
    'note': _clip(note, Limits.dueNoteMax),
    if (add.isNotEmpty) 'participantIds': [for (final p in add) p.id],
  });

  @override
  Future<void> remove(Due due) => _call('deleteDue', {'dueId': due.id});

  /// Calls [name], turning its refusals into the app's failures.
  Future<void> _call(String name, Map<String, Object?> input) async {
    try {
      await _functions.httpsCallable(name).call<Object?>(input);
    } on FirebaseFunctionsException catch (e) {
      final message = serverMessage(e.message);
      throw switch (e.code) {
        // An amount below what someone already paid (DUES-1).
        'failed-precondition' when message == 'due-amount-below-paid' =>
          InvalidInput(message),
        'permission-denied' => PermissionDenied(message),
        'not-found' => NotFound(message),
        'invalid-argument' => InvalidInput(message),
        'unauthenticated' => Unauthenticated(message),
        'unavailable' || 'deadline-exceeded' => Offline(message),
        _ => UnknownFailure('${e.code}: $message'),
      };
    }
  }

  @override
  Future<void> recordPayment(
    DueCharge charge, {
    required String id,
    required String paidOn,
    required UserId by,
    int? amountCents,
    String note = '',
  }) => _change(charge, by, (now, raw) {
    // A retry of one already recorded.
    if (now.payments.any((p) => p.id == id)) return null;
    final payment = DuePayment(
      id: id,
      amountCents: amountCents ?? now.owedCents,
      paidOn: paidOn,
      by: by.value,
      note: _clip(note, Limits.duePaymentNoteMax),
    );
    return {
      ..._totals(addDuePayment(now, payment), now),
      'payments': [...raw, _paymentMap(payment)],
    };
  });

  @override
  Future<void> undoPayment(
    DueCharge charge,
    String paymentId, {
    required UserId by,
  }) => _change(charge, by, (now, raw) {
    if (!now.payments.any((p) => p.id == paymentId)) return null;
    return {
      ..._totals(removeDuePayment(now, paymentId), now),
      // As stored, but for the one taken back.
      'payments': [
        for (final p in raw)
          if (p is! Map || p['id'] != paymentId) p,
      ],
    };
  });

  @override
  Future<void> setStatus(
    DueCharge charge,
    DueStatus status, {
    required UserId by,
  }) => _change(charge, by, (now, _) {
    // Paid comes from payments recorded (recordPayment).
    if (status == DueStatus.paid) throw const InvalidInput('due-status');
    if (status == now.status) return null;
    final next = switch (status) {
      DueStatus.waived => DueStatus.waived,
      DueStatus.owed when now.status == DueStatus.waived => unwaivedStatus(now),
      // Marked paid before payments were recorded: owes all of it again.
      DueStatus.owed when !now.recordsPayments => DueStatus.owed,
      _ => throw const InvalidInput('due-status'),
    };
    return {
      'status': next.value,
      'paidAt': next == DueStatus.paid ? FieldValue.serverTimestamp() : null,
    };
  });

  /// Changes [charge] in a transaction: [change] gets the charge as it is
  /// now, and its payments as stored, and returns the fields to write, or
  /// null for nothing to do. One refused because another admin changed the
  /// share after it was read is read and made again ([retryRefused]). A
  /// refusal becomes [InvalidInput]; a charge that's gone, [NotFound].
  Future<void> _change(
    DueCharge charge,
    UserId by,
    Map<String, Object?>? Function(DueCharge now, List<Object?> raw) change,
  ) => _write(() async {
    try {
      await retryRefused(
        () => _db.runTransaction<void>((tx) async {
          final ref = _charges.doc(charge.id);
          final snap = await tx.get(ref);
          final data = snap.data();
          if (data == null) throw const NotFound();
          final fields = change(
            dueChargeFromFirestore(snap.id, data),
            List<Object?>.of(data['payments'] as List? ?? const []),
          );
          if (fields == null) return;
          tx.update(ref, {
            ...fields,
            'updatedBy': by.value,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }),
      );
    } on DuePaymentRefusal catch (e) {
      throw InvalidInput(e.name);
    }
  });

  /// A share's total, status, and when it was paid, after [next].
  static Map<String, Object?> _totals(DueChargePayments next, DueCharge now) =>
      {
        'paidCents': next.paidCents,
        'status': next.status.value,
        // When it was paid in full; kept while it stays paid.
        if (next.status != DueStatus.paid)
          'paidAt': null
        else if (!now.paid)
          'paidAt': FieldValue.serverTimestamp(),
      };

  static Map<String, Object?> _paymentMap(DuePayment p) => {
    'id': p.id,
    'amountCents': p.amountCents,
    'paidOn': p.paidOn,
    'by': p.by,
    'note': p.note,
  };

  @override
  Future<void> savePayments(
    GroupId groupId,
    DuesPayments payments, {
    required UserId by,
  }) => _write(
    () => _db.collection(Collections.duesPayments).doc(groupId.value).set({
      'groupId': groupId.value,
      'venmo': _clip(payments.venmo, Limits.duePayHandleMax),
      'cashApp': _clip(payments.cashApp, Limits.duePayHandleMax),
      'appleCash': _clip(payments.appleCash, Limits.duePayHandleMax),
      'note': _clip(payments.note, Limits.dueNoteMax),
      'updatedBy': by.value,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  static String _clip(String s, int max) {
    final t = s.trim();
    return t.length <= max ? t : t.substring(0, max);
  }

  /// Runs a write, turning Firestore's refusals into the app's failures.
  static Future<void> _write(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'unavailable' => Offline(e.code),
        'not-found' => const NotFound(),
        _ => UnknownFailure(e.code),
      };
    }
  }
}

/// Runs [attempt], and again while it's refused with `permission-denied`,
/// up to [tries] times in all (DUES-2). The rules check a change to a share
/// against the share as it is, so a change made from a copy another admin
/// changed a moment later is refused rather than retried by the
/// transaction: each new attempt reads the share again, so two admins
/// recording at once both count. A refusal for any other reason (no longer
/// an admin, an archived team) is the same each time, and the last one is
/// thrown.
Future<T> retryRefused<T>(Future<T> Function() attempt, {int tries = 3}) async {
  for (var i = 1; ; i++) {
    try {
      return await attempt();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied' || i >= tries) rethrow;
    }
  }
}

/// Every payer's charges together (DUES-2), once each of [perPayer] has
/// answered. A payer whose query fails (a player link just removed, say)
/// counts as owing nothing, so one bad query never holds up the rest; the
/// stream fails only when every one does.
Stream<List<DueCharge>> mergePayerCharges(
  List<Stream<List<DueCharge>>> perPayer,
) {
  final latest = <int, List<DueCharge>>{};
  final failed = <int>{};
  final out = StreamController<List<DueCharge>>();
  final subs = <StreamSubscription<void>>[];
  void emit() {
    if (latest.length + failed.length < perPayer.length) return;
    out.add([for (final l in latest.values) ...l]);
  }

  out
    ..onListen = () {
      for (var i = 0; i < perPayer.length; i++) {
        subs.add(
          perPayer[i].listen(
            (list) {
              failed.remove(i);
              latest[i] = list;
              emit();
            },
            onError: (Object e, StackTrace st) {
              latest.remove(i);
              failed.add(i);
              if (failed.length == perPayer.length) {
                out.addError(e, st);
              } else {
                emit();
              }
            },
          ),
        );
      }
    }
    ..onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };
  return out.stream;
}

DateTime? _time(Object? v) => v is Timestamp ? v.toDate() : null;

/// Reads a `dues` document (ARCH §6.2).
Due dueFromFirestore(String id, Map<String, dynamic> x) => Due(
  id: id,
  groupId: GroupId(x['groupId'] as String? ?? ''),
  title: x['title'] as String? ?? '',
  amountCents: (x['amountCents'] as num?)?.toInt() ?? 0,
  dueOn: x['dueOn'] as String?,
  note: x['note'] as String? ?? '',
  createdBy: x['createdBy'] as String? ?? '',
  createdAt: _time(x['createdAt']),
);

/// Reads a `dueCharges` document (ARCH §6.2).
DueCharge dueChargeFromFirestore(String id, Map<String, dynamic> x) =>
    DueCharge(
      id: id,
      groupId: GroupId(x['groupId'] as String? ?? ''),
      dueId: x['dueId'] as String? ?? '',
      title: x['title'] as String? ?? '',
      amountCents: (x['amountCents'] as num?)?.toInt() ?? 0,
      dueOn: x['dueOn'] as String?,
      note: x['note'] as String? ?? '',
      participantType:
          ParticipantType.tryParse(x['participantType'] as String?) ??
          ParticipantType.member,
      participantId: x['participantId'] as String? ?? '',
      participantName: x['participantName'] as String? ?? '',
      status: DueStatus.tryParse(x['status'] as String?) ?? DueStatus.owed,
      paidAt: _time(x['paidAt']),
      updatedAt: _time(x['updatedAt']),
      payments: [
        for (final p in x['payments'] as List? ?? const [])
          if (p is Map) duePaymentFromFirestore(p),
      ],
      recordedCents: (x['paidCents'] as num?)?.toInt(),
    );

/// Reads one payment on a charge (ARCH §6.2).
DuePayment duePaymentFromFirestore(Map<Object?, Object?> x) => DuePayment(
  id: x['id'] as String? ?? '',
  amountCents: (x['amountCents'] as num?)?.toInt() ?? 0,
  paidOn: x['paidOn'] as String? ?? '',
  by: x['by'] as String? ?? '',
  note: x['note'] as String? ?? '',
);

/// Reads a `duesPayments` document, or empty when there's none.
DuesPayments duesPaymentsFromFirestore(Map<String, dynamic>? x) => DuesPayments(
  venmo: x?['venmo'] as String? ?? '',
  cashApp: x?['cashApp'] as String? ?? '',
  appleCash: x?['appleCash'] as String? ?? '',
  note: x?['note'] as String? ?? '',
  updatedBy: x?['updatedBy'] as String? ?? '',
);
