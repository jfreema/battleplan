import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/live_pages.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Players, player links, and claims from Firestore; adding, claiming,
/// deciding, and removing through callables.
class FirestorePlayerRepository implements PlayerRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  /// Members see active players only, so they ask for them by status
  /// (the rules hide pending ones, PLAYER-4).
  @override
  Stream<List<Player>> watchPlayers(GroupId groupId) => _allPages(
    _players(groupId).where('status', isEqualTo: PlayerStatus.active.value),
    (d) => playerFromFirestore(d.id, groupId, d.data()),
  );

  @override
  Stream<List<Player>> watchPendingPlayers(GroupId groupId) => _allPages(
    _players(groupId).where('status', isEqualTo: PlayerStatus.pending.value),
    (d) => playerFromFirestore(d.id, groupId, d.data()),
  );

  @override
  Stream<List<Player>> watchMyPendingPlayers(GroupId groupId, UserId uid) =>
      _allPages(
        _players(groupId)
            .where('status', isEqualTo: PlayerStatus.pending.value)
            .where('proposedBy', isEqualTo: uid.value),
        (d) => playerFromFirestore(d.id, groupId, d.data()),
      );

  Query<Map<String, dynamic>> _players(GroupId groupId) => _db
      .collection(Collections.players)
      .where('groupId', isEqualTo: groupId.value);

  @override
  Stream<List<GuardianLink>> watchGuardianLinks(GroupId groupId) => _allPages(
    _db
        .collection(Collections.playerGuardians)
        .where('groupId', isEqualTo: groupId.value),
    (d) => GuardianLink(
      playerId: PlayerId(d.data()['playerId'] as String),
      groupId: groupId,
      uid: UserId(d.data()['uid'] as String),
      relation: relationFromFirestore(d.data()['relation']),
    ),
  );

  /// Every match, 100 to a page, each page live. A team can have 200
  /// players with 4 guardians each, past the query cap; a guardian missing
  /// from the list couldn't answer for their player (TEAM-3, PLAYER-6).
  Stream<List<T>> _allPages<T>(
    Query<Map<String, dynamic>> query,
    T Function(QueryDocumentSnapshot<Map<String, dynamic>> d) map,
  ) {
    final q = query.orderBy(FieldPath.documentId);
    return livePages<T, String>((after) {
      final page = after == null ? q : q.startAfter([after]);
      return page
          .limit(Limits.queryLimitMax)
          .snapshots()
          .map(
            (snap) => (
              items: [for (final d in snap.docs) map(d)],
              next: snap.docs.length < Limits.queryLimitMax
                  ? null
                  : snap.docs.last.id,
            ),
          );
    });
  }

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
      guardiansWithoutEmail: [
        for (final p in (data['guardiansWithoutEmail'] as List?) ?? const [])
          '$p',
      ],
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
                  relation: relationFromFirestore(d.data()['relation']),
                ),
            ],
          );

  @override
  Future<ClaimOutcome> claimPlayer(
    GroupId groupId,
    PlayerId playerId,
    PlayerRelation relation,
  ) async {
    final d = await _call('claimPlayer', {
      'groupId': groupId.value,
      'playerId': playerId.value,
      'relation': relation.value,
    });
    return d['status'] == 'linked'
        ? ClaimOutcome.linked
        : ClaimOutcome.requested;
  }

  @override
  Future<void> resolvePlayerClaim(
    GroupId groupId,
    PlayerId playerId,
    UserId uid, {
    required bool approve,
  }) => _call('resolvePlayerClaim', {
    'groupId': groupId.value,
    'playerId': playerId.value,
    'uid': uid.value,
    'approve': approve,
  });

  @override
  Future<PlayerStatus> proposePlayer(
    GroupId groupId, {
    required String name,
    required PlayerRelation relation,
    String? jerseyNumber,
    String? position,
  }) async {
    String? blankToNull(String? v) =>
        (v?.trim().isEmpty ?? true) ? null : v!.trim();
    final d = await _call('proposePlayer', {
      'groupId': groupId.value,
      'displayName': name.trim(),
      'jerseyNumber': blankToNull(jerseyNumber),
      'position': blankToNull(position),
      'relation': relation.value,
    });
    return PlayerStatus.tryParse(d['status'] as String?) ??
        PlayerStatus.pending;
  }

  @override
  Future<void> resolvePendingPlayer(
    GroupId groupId,
    PlayerId playerId, {
    required bool approve,
  }) => _call('resolvePendingPlayer', {
    'groupId': groupId.value,
    'playerId': playerId.value,
    'approve': approve,
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
        (
          'failed-precondition',
          'too-many-players' ||
              'too-many-guardians' ||
              'player-already-claimed' ||
              'already-a-player' ||
              'already-linked',
        ) =>
          InvalidInput(e.message),
        ('failed-precondition', 'too-many-teams') => TooManyTeams(e.message),
        ('failed-precondition', 'email-not-verified') => EmailNotVerified(
          e.message,
        ),
        // The team was archived (TEAM-9).
        ('failed-precondition', 'team-archived') => PermissionDenied(e.message),
        // The player was removed, or a pending one was decided (PLAYER-4).
        ('not-found', _) => NotFound(e.message),
        ('resource-exhausted', _) => RateLimited(e.message),
        ('permission-denied', _) => PermissionDenied(e.message),
        ('invalid-argument', _) => InvalidInput(e.message),
        ('unavailable' || 'deadline-exceeded', _) => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }
}

/// A player from its Firestore fields (ARCH §6.2 `players`).
Player playerFromFirestore(
  String id,
  GroupId groupId,
  Map<String, dynamic> d,
) => Player(
  id: PlayerId(id),
  groupId: groupId,
  displayName: d['displayName'] as String? ?? '',
  jerseyNumber: d['jerseyNumber'] as String?,
  position: d['position'] as String?,
  status: PlayerStatus.tryParse(d['status'] as String?) ?? PlayerStatus.active,
  proposedBy: d['proposedBy'] as String?,
  proposedRelation: PlayerRelation.tryParse(d['proposedRelation'] as String?),
);

/// A link's or claim's relation; old ones without it are guardians.
PlayerRelation relationFromFirestore(Object? value) =>
    PlayerRelation.tryParse(value as String?) ?? PlayerRelation.guardian;
