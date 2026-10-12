import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/rsvp_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// RSVPs in Firestore (ARCH §6.2). Each answer is written straight to
/// `rsvps/{eventId}_{participantId}`, so two guardians answering for one
/// player write the same record (PLAYER-6); a trigger recounts the event.
class FirestoreRsvpRepository implements RsvpRepository {
  new(this._db);

  final FirebaseFirestore _db;

  /// Firestore's limit on values in one `in` filter.
  static const _inMax = 30;

  CollectionReference<Map<String, dynamic>> get _rsvps =>
      _db.collection(Collections.rsvps);

  @override
  Stream<List<Rsvp>> watchMine(
    GroupId groupId,
    List<String> participantIds, {
    DateTime? from,
    DateTime? until,
  }) {
    if (participantIds.isEmpty) return Stream.value(const []);
    // Me and my players: a guardian has a handful, far under the limit.
    var q = _rsvps
        .where('groupId', isEqualTo: groupId.value)
        .where('participantId', whereIn: participantIds.take(_inMax).toList());
    if (from != null) {
      q = q.where(
        'eventStartAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      );
    }
    if (until != null) {
      q = q.where('eventStartAt', isLessThan: Timestamp.fromDate(until));
    }
    return q
        .orderBy('eventStartAt')
        .limit(Limits.queryLimitMax)
        .snapshots(includeMetadataChanges: true)
        .map((s) => [for (final d in s.docs) _rsvp(d)]);
  }

  @override
  Stream<List<Rsvp>> watchForEvent(GroupId groupId, EventId eventId) {
    final q = _rsvps
        .where('groupId', isEqualTo: groupId.value)
        .where('eventId', isEqualTo: eventId.value)
        .orderBy(FieldPath.documentId);
    // The first 100 answers are live (queries are capped at 100, ARCH
    // §10.2); a big team's rest are read a page at a time behind them.
    return q
        .limit(Limits.queryLimitMax)
        .snapshots(includeMetadataChanges: true)
        .asyncMap((first) async {
          final all = [for (final d in first.docs) _rsvp(d)];
          var last = first.docs.length < Limits.queryLimitMax
              ? null
              : first.docs.last;
          while (last != null) {
            final page = await q
                .startAfterDocument(last)
                .limit(Limits.queryLimitMax)
                .get();
            all.addAll([for (final d in page.docs) _rsvp(d)]);
            last = page.docs.length < Limits.queryLimitMax
                ? null
                : page.docs.last;
          }
          return all;
        });
  }

  @override
  Future<void> setRsvp(
    Event event,
    RsvpAnswer answer, {
    required UserId by,
  }) async {
    final p = answer.participant;
    final ref = _rsvps.doc(CompositeIds.rsvp(event.id, p.id));
    // The local write shows at once (offline too); this completes when the
    // server has it, and throws if the rules refuse it, for example after
    // the deadline.
    try {
      await ref.set({
        'eventId': event.id.value,
        'groupId': event.groupId.value,
        'participantType': p.type.value,
        'participantId': p.id,
        'participantName': p.name,
        'eventStartAt': Timestamp.fromDate(event.startAt),
        'status': answer.status.value,
        'note': answer.note.trim(),
        'guests': 0,
        'respondedBy': by.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'unavailable' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  Rsvp _rsvp(DocumentSnapshot<Map<String, dynamic>> d) =>
      rsvpFromFirestore(d.data()!, pending: d.metadata.hasPendingWrites);
}

/// Reads an `rsvps` document (ARCH §6.2).
Rsvp rsvpFromFirestore(Map<String, dynamic> x, {bool pending = false}) => Rsvp(
  eventId: EventId(x['eventId'] as String? ?? ''),
  groupId: GroupId(x['groupId'] as String? ?? ''),
  participantType:
      ParticipantType.tryParse(x['participantType'] as String?) ??
      ParticipantType.member,
  participantId: x['participantId'] as String? ?? '',
  participantName: x['participantName'] as String? ?? '',
  status: RsvpStatus.tryParse(x['status'] as String?) ?? RsvpStatus.going,
  note: x['note'] as String? ?? '',
  respondedBy: x['respondedBy'] as String? ?? '',
  eventStartAt: (x['eventStartAt'] as Timestamp?)?.toDate(),
  updatedAt: (x['updatedAt'] as Timestamp?)?.toDate(),
  pending: pending,
);
