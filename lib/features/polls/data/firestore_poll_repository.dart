import 'dart:async';

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
      // Offline, a poll that was never cached reads as missing; wait for the
      // server rather than call a live poll deleted.
      .where((d) => d.exists || !d.metadata.isFromCache)
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
      throw _failure(e);
    }
  }

  DocumentReference<Map<String, dynamic>> _playerVote(
    PollId pollId,
    PlayerId playerId,
  ) => _db
      .collection(Collections.pollPlayerVotes)
      .doc('${pollId.value}_${playerId.value}');

  @override
  Stream<Map<PlayerId, PlayerPollVote>> watchPlayerVotes(
    PollId pollId,
    List<PlayerId> playerIds,
  ) {
    if (playerIds.isEmpty) return Stream.value(const {});
    // One listener per player (a guardian has a few), each a get the rules
    // allow for my own players, anonymous polls included; together, one
    // map of whichever have a vote, sent once each has been read.
    late final StreamController<Map<PlayerId, PlayerPollVote>> out;
    final seen = <PlayerId, PlayerPollVote?>{};
    final subs = <StreamSubscription<Object?>>[];
    out = StreamController<Map<PlayerId, PlayerPollVote>>(
      onListen: () {
        for (final player in playerIds) {
          subs.add(
            _playerVote(pollId, player).snapshots().listen((d) {
              seen[player] = d.exists
                  ? playerPollVoteFromFirestore(d.data()!)
                  : null;
              if (seen.length == playerIds.length) {
                out.add({
                  for (final MapEntry(:key, :value) in seen.entries)
                    key: ?value,
                });
              }
            }, onError: out.addError),
          );
        }
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      },
    );
    return out.stream;
  }

  @override
  Future<List<PlayerPollVote>> loadPlayerVotes(PollId pollId) async {
    // A team has at most 200 players; queries are capped at 100 (ARCH
    // §10.2), so read a page at a time.
    final votes = <PlayerPollVote>[];
    DocumentSnapshot<Object?>? last;
    for (;;) {
      var q = _db
          .collection(Collections.pollPlayerVotes)
          .where('pollId', isEqualTo: pollId.value)
          .orderBy(FieldPath.documentId)
          .limit(Limits.queryLimitMax);
      if (last != null) q = q.startAfterDocument(last);
      final page = await q.get();
      votes.addAll([
        for (final d in page.docs) playerPollVoteFromFirestore(d.data()),
      ]);
      if (page.docs.length < Limits.queryLimitMax) return votes;
      last = page.docs.last;
    }
  }

  @override
  Future<int> setPlayerVotes(
    Poll poll,
    Map<PlayerId, Set<String>> votes,
  ) async {
    try {
      final result = await _functions
          .httpsCallable('votePollForPlayers')
          .call<Object?>({
            'pollId': poll.id.value,
            'votes': {
              for (final MapEntry(:key, :value) in votes.entries)
                key.value: [
                  // In the poll's order, as the server keeps them.
                  for (final o in poll.options)
                    if (value.contains(o.id)) o.id,
                ],
            },
          });
      final data = result.data;
      return data is Map ? (data['replaced'] as num?)?.toInt() ?? 0 : 0;
    } on FirebaseFunctionsException catch (e) {
      throw _failure(e);
    }
  }

  /// A callable's error as the app's failures; a vote on a poll that closed
  /// meanwhile is refused as the rules refuse a direct vote.
  AppFailure _failure(FirebaseFunctionsException e) {
    final message = serverMessage(e.message);
    return switch (e.code) {
      'permission-denied' => PermissionDenied(message),
      'failed-precondition' when message == 'poll-closed' => PermissionDenied(
        message,
      ),
      'unavailable' || 'deadline-exceeded' => Offline(message),
      _ => UnknownFailure('${e.code}: $message'),
    };
  }
}

/// Reads a `pollPlayerVotes` document (#96).
PlayerPollVote playerPollVoteFromFirestore(Map<String, dynamic> x) =>
    PlayerPollVote(
      playerId: PlayerId(x['playerId'] as String? ?? ''),
      optionIds: {
        for (final id in (x['optionIds'] as List?) ?? const [])
          if (id is String) id,
      },
      uid: x['uid'] as String? ?? '',
    );

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
  perPlayer: x['perPlayer'] == true,
  closesAt: (x['closesAt'] as Timestamp?)?.toDate(),
  closedAt: (x['closedAt'] as Timestamp?)?.toDate(),
  voteCounts: {
    for (final e in ((x['voteCounts'] as Map?) ?? const {}).entries)
      '${e.key}': (e.value as num?)?.toInt() ?? 0,
  },
  voterCount: (x['voterCount'] as num?)?.toInt() ?? 0,
);
