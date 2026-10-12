import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/polls/domain/poll_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Polls and votes in Firestore (ARCH §6.2). Votes are written straight to
/// `pollVotes/{pollId}_{uid}`; the rules check them and a trigger counts
/// them.
class FirestorePollRepository implements PollRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  DocumentReference<Map<String, dynamic>> _vote(PollId pollId, UserId uid) =>
      _db
          .collection(Collections.pollVotes)
          .doc(CompositeIds.pollVote(pollId, uid));

  @override
  Stream<Poll?> watchPoll(PollId pollId) => _db
      .collection(Collections.polls)
      .doc(pollId.value)
      .snapshots()
      .map((d) => d.exists ? pollFromFirestore(d.id, d.data()!) : null);

  @override
  Stream<Set<String>> watchMyVote(PollId pollId, UserId uid) =>
      _vote(pollId, uid).snapshots().map(
        (d) => {
          for (final id in (d.data()?['optionIds'] as List?) ?? const [])
            if (id is String) id,
        },
      );

  @override
  Future<void> setVote(Poll poll, UserId uid, Set<String> optionIds) async {
    final ref = _vote(poll.id, uid);
    // The local write shows at once (offline too); this completes when the
    // server has it, and throws if the rules refuse it, for example because
    // the poll closed meanwhile.
    try {
      if (optionIds.isEmpty) {
        await ref.delete();
      } else {
        await ref.set({
          'pollId': poll.id.value,
          'groupId': poll.groupId.value,
          'uid': uid.value,
          'optionIds': [
            for (final o in poll.options)
              if (optionIds.contains(o.id)) o.id,
          ],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'unavailable' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<List<PollVote>> loadVotes(PollId pollId) async {
    // A team has at most 500 members; queries are capped at 100 (ARCH
    // §10.2), so read a page at a time.
    final votes = <PollVote>[];
    DocumentSnapshot<Object?>? last;
    for (;;) {
      var q = _db
          .collection(Collections.pollVotes)
          .where('pollId', isEqualTo: pollId.value)
          .orderBy(FieldPath.documentId)
          .limit(Limits.queryLimitMax);
      if (last != null) q = q.startAfterDocument(last);
      final page = await q.get();
      for (final d in page.docs) {
        votes.add(
          PollVote(
            uid: d.data()['uid'] as String? ?? '',
            optionIds: {
              for (final id in (d.data()['optionIds'] as List?) ?? const [])
                if (id is String) id,
            },
          ),
        );
      }
      if (page.docs.length < Limits.queryLimitMax) return votes;
      last = page.docs.last;
    }
  }

  @override
  Future<void> closePoll(PollId pollId) async {
    try {
      await _functions.httpsCallable('closePoll').call<Object?>({
        'pollId': pollId.value,
      });
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.message),
        'unavailable' || 'deadline-exceeded' => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }
}

/// Reads a `polls` document (ARCH §6.2).
Poll pollFromFirestore(String id, Map<String, dynamic> x) => Poll(
  id: PollId(id),
  groupId: GroupId(x['groupId'] as String? ?? ''),
  createdBy: x['createdBy'] as String? ?? '',
  question: x['question'] as String? ?? '',
  options: [
    for (final o in (x['options'] as List?) ?? const [])
      if (o is Map && o['id'] is String)
        PollOption(id: o['id'] as String, text: o['text'] as String? ?? ''),
  ],
  allowMultiple: x['allowMultiple'] == true,
  anonymous: x['anonymous'] == true,
  closesAt: (x['closesAt'] as Timestamp?)?.toDate(),
  closedAt: (x['closedAt'] as Timestamp?)?.toDate(),
  voteCounts: {
    for (final e in ((x['voteCounts'] as Map?) ?? const {}).entries)
      '${e.key}': (e.value as num?)?.toInt() ?? 0,
  },
  voterCount: (x['voterCount'] as num?)?.toInt() ?? 0,
);
