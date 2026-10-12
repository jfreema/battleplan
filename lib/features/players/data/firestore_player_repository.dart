import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Players from Firestore; adding and removing through callables.
class FirestorePlayerRepository implements PlayerRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<List<Player>> watchPlayers(GroupId groupId) => _db
      .collection(Collections.players)
      .where('groupId', isEqualTo: groupId.value)
      .limit(Limits.queryLimitMax)
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs)
            Player(
              id: PlayerId(d.id),
              groupId: groupId,
              displayName: d.data()['displayName'] as String? ?? '',
              jerseyNumber: d.data()['jerseyNumber'] as String?,
              position: d.data()['position'] as String?,
            ),
        ],
      );

  @override
  Stream<List<GuardianLink>> watchGuardianLinks(GroupId groupId) => _db
      .collection(Collections.playerGuardians)
      .where('groupId', isEqualTo: groupId.value)
      .limit(Limits.queryLimitMax)
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs)
            GuardianLink(
              playerId: PlayerId(d.data()['playerId'] as String),
              groupId: groupId,
              uid: UserId(d.data()['uid'] as String),
            ),
        ],
      );

  @override
  Future<AddPlayersResult> addPlayers(
    GroupId groupId,
    List<NewPlayer> players,
  ) async {
    final data = await _call('addPlayers', {
      'groupId': groupId.value,
      'players': [
        for (final p in players)
          {
            'name': p.name,
            'jerseyNumber': p.jerseyNumber,
            'position': p.position,
            'guardians': [
              for (final g in p.guardians) {'name': g.name, 'email': g.email},
            ],
          },
      ],
    });
    return AddPlayersResult(
      playersAdded: (data['playersAdded'] as num).toInt(),
      guardiansLinked: (data['guardiansLinked'] as num).toInt(),
      guardiansInvited: (data['guardiansInvited'] as num).toInt(),
      problems: [for (final p in (data['problems'] as List?) ?? const []) '$p'],
    );
  }

  @override
  Future<void> updatePlayer(
    PlayerId id, {
    required String name,
    String? jerseyNumber,
    String? position,
  }) async {
    final trimmed = name.trim();
    try {
      await _db.collection(Collections.players).doc(id.value).update({
        'displayName': trimmed,
        'displayNameLower': trimmed.toLowerCase(),
        'jerseyNumber': (jerseyNumber?.trim().isEmpty ?? true)
            ? null
            : jerseyNumber!.trim(),
        'position': (position?.trim().isEmpty ?? true)
            ? null
            : position!.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> removePlayer(GroupId groupId, PlayerId id) =>
      _call('removePlayer', {'groupId': groupId.value, 'playerId': id.value});

  @override
  Stream<List<GuardianRequest>> watchPendingRequests(GroupId groupId) =>
      _requests(
        _db
            .collection(Collections.guardianRequests)
            .where('groupId', isEqualTo: groupId.value)
            .where('status', isEqualTo: 'pending'),
      );

  @override
  Stream<List<GuardianRequest>> watchMyRequests(GroupId groupId, UserId uid) =>
      _requests(
        _db
            .collection(Collections.guardianRequests)
            .where('groupId', isEqualTo: groupId.value)
            .where('uid', isEqualTo: uid.value),
      );

  Stream<List<GuardianRequest>> _requests(Query<Map<String, dynamic>> query) =>
      query
          .limit(Limits.queryLimitMax)
          .snapshots()
          .map(
            (q) => [
              for (final d in q.docs)
                GuardianRequest(
                  playerId: PlayerId(d.data()['playerId'] as String),
                  groupId: GroupId(d.data()['groupId'] as String),
                  uid: UserId(d.data()['uid'] as String),
                  status:
                      GuardianRequestStatus.values.asNameMap()[d
                          .data()['status']] ??
                      GuardianRequestStatus.pending,
                ),
            ],
          );

  @override
  Future<void> requestGuardianLink(GroupId groupId, List<PlayerId> players) =>
      _call('requestGuardianLink', {
        'groupId': groupId.value,
        'playerIds': [for (final p in players) p.value],
      });

  @override
  Future<void> resolveGuardianRequest(
    GroupId groupId,
    PlayerId playerId,
    UserId uid, {
    required bool approve,
  }) => _call('resolveGuardianLink', {
    'groupId': groupId.value,
    'playerId': playerId.value,
    'uid': uid.value,
    'approve': approve,
  });

  @override
  Future<void> addMyPlayer(
    GroupId groupId, {
    required String name,
    String? jerseyNumber,
  }) => _call('addMyPlayer', {
    'groupId': groupId.value,
    'name': name,
    'jerseyNumber': jerseyNumber,
  });

  @override
  Future<bool> inviteGuardian(
    GroupId groupId,
    PlayerId playerId, {
    required String email,
    String? name,
  }) async {
    final d = await _call('inviteGuardian', {
      'groupId': groupId.value,
      'playerId': playerId.value,
      'email': email,
      'name': name,
    });
    return d['invited'] as bool? ?? false;
  }

  @override
  Future<void> removeGuardian(GroupId groupId, PlayerId playerId, UserId uid) =>
      _call('removeGuardian', {
        'groupId': groupId.value,
        'playerId': playerId.value,
        'uid': uid.value,
      });

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>(data);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw switch ((e.code, e.message)) {
        ('failed-precondition', 'too-many-players' || 'too-many-guardians') =>
          InvalidInput(e.message),
        // SAFE-5: adding guardians by email needs a verified email.
        ('failed-precondition', 'email-not-verified') => EmailNotVerified(
          e.message,
        ),
        ('resource-exhausted', _) => RateLimited(e.message),
        ('permission-denied', _) => PermissionDenied(e.message),
        ('invalid-argument', _) => InvalidInput(e.message),
        ('unavailable' || 'deadline-exceeded', _) => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }
}
