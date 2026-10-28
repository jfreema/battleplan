import 'dart:convert';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/domain/play_repository.dart';
import 'package:battleplan/features/plays/domain/shared_play.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Plays in Firestore (ARCH §6.2 `plays`, §6.14), written directly under
/// the rules. Elements are kept compact: a play is a few kilobytes. The
/// `sharePlay` callable shares them, and anyone reads `sharedPlays`
/// (BOARD-6).
class FirestorePlayRepository implements PlayRepository {
  const new(this._db, [this._functions]);

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functions;

  CollectionReference<Map<String, dynamic>> get _plays =>
      _db.collection(Collections.plays);

  @override
  Stream<List<Play>> watchPlays(GroupId groupId) => _plays
      .where('groupId', isEqualTo: groupId.value)
      .orderBy('updatedAt', descending: true)
      .limit(Limits.queryLimitMax)
      .snapshots()
      .map((q) => [for (final d in q.docs) playFromFirestore(d.id, d.data())]);

  @override
  Stream<Play?> watchPlay(PlayId id) => _plays
      .doc(id.value)
      .snapshots()
      .map((d) => d.exists ? playFromFirestore(d.id, d.data()!) : null);

  @override
  Future<PlayId> create(GroupId groupId, UserId uid, PlayDraft draft) async {
    final ref = _plays.doc();
    try {
      await ref.set({
        ...playToFirestore(draft),
        'groupId': groupId.value,
        'createdBy': uid.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
    return PlayId(ref.id);
  }

  @override
  Future<void> update(PlayId id, PlayDraft draft) async {
    try {
      await _plays.doc(id.value).update({
        ...playToFirestore(draft),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> delete(PlayId id) async {
    try {
      await _plays.doc(id.value).delete();
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<String> share(PlayId id, {Uint8List? image}) async {
    final data = await _callShare({
      'playId': id.value,
      'action': 'share',
      'image': image == null ? null : base64Encode(image),
    });
    return data['shareId'] as String;
  }

  @override
  Future<void> stopSharing(PlayId id) =>
      _callShare({'playId': id.value, 'action': 'stop'});

  Future<Map<String, dynamic>> _callShare(Map<String, Object?> input) async {
    try {
      final result = await _functions!
          .httpsCallable('sharePlay')
          .call<Map<String, dynamic>>(input);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'unavailable' || 'deadline-exceeded' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<PlayDraft?> sharedPlay(String shareId) async {
    if (!isShareId(shareId)) return null;
    try {
      final snap = await _db
          .collection(Collections.sharedPlays)
          .doc(shareId)
          .get();
      final data = snap.data();
      return data == null ? null : sharedPlayFromFirestore(data);
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }
}

AppFailure _failure(FirebaseException e) => switch (e.code) {
  'permission-denied' => PermissionDenied(e.code),
  'unavailable' => Offline(e.code),
  _ => UnknownFailure(e.code),
};

/// A coordinate rounded to 4 places: a tenth of a millimeter on a tablet.
double _r(double v) => (v * 10000).round() / 10000;

List<double> _flat(List<BoardPoint> points) => [
  for (final p in points) ...[_r(p.x), _r(p.y)],
];

List<BoardPoint> _points(Object? raw) {
  final v = raw is List ? raw : const <Object?>[];
  return [
    for (var i = 0; i + 1 < v.length; i += 2)
      if (v[i] case final num x)
        if (v[i + 1] case final num y) (x: x.toDouble(), y: y.toDouble()),
  ];
}

/// An element as Firestore keeps it: `k` its kind (m, a, l, n), points as
/// x, y pairs in one list.
Map<String, Object?> elementToFirestore(BoardElement e) => switch (e) {
  MarkerElement() => {
    'k': 'm',
    'id': e.id,
    'x': _r(e.at.x),
    'y': _r(e.at.y),
    's': e.side.value,
    if (e.label.isNotEmpty) 'l': e.label,
    if (e.playerId case final p?) 'p': p.value,
  },
  ArrowElement() => {
    'k': 'a',
    'id': e.id,
    't': e.kind.value,
    'pts': _flat(e.points),
  },
  LineElement() => {'k': 'l', 'id': e.id, 'pts': _flat(e.points)},
  NoteElement() => {
    'k': 'n',
    'id': e.id,
    'x': _r(e.at.x),
    'y': _r(e.at.y),
    'text': e.text,
  },
};

/// [m] as an element, or null for a kind this version doesn't know.
BoardElement? elementFromFirestore(Map<String, dynamic> m) {
  final id = '${m['id'] ?? ''}';
  BoardPoint at() => (
    x: (m['x'] as num?)?.toDouble() ?? 0,
    y: (m['y'] as num?)?.toDouble() ?? 0,
  );
  return switch (m['k']) {
    'm' => BoardElement.marker(
      id: id,
      at: at(),
      side: MarkerSide.tryParse(m['s'] as String?) ?? MarkerSide.team,
      label: '${m['l'] ?? ''}',
      playerId: switch (m['p']) {
        final String p => PlayerId(p),
        _ => null,
      },
    ),
    'a' => BoardElement.arrow(
      id: id,
      kind: ArrowKind.tryParse(m['t'] as String?) ?? ArrowKind.run,
      points: _points(m['pts']),
    ),
    'l' => BoardElement.line(id: id, points: _points(m['pts'])),
    'n' => BoardElement.note(id: id, at: at(), text: '${m['text'] ?? ''}'),
    _ => null,
  };
}

/// A play's own fields, as the rules check them.
Map<String, Object?> playToFirestore(PlayDraft d) => {
  'board': d.board.value,
  'variant': d.variant.value,
  'title': d.title.trim(),
  'note': d.note.trim(),
  'steps': [
    for (final s in d.steps)
      {
        'elements': [for (final e in s.elements) elementToFirestore(e)],
      },
  ],
};

Play playFromFirestore(String id, Map<String, dynamic> x) {
  final steps = [
    for (final s in (x['steps'] as List?) ?? const <Object?>[])
      if (s case final Map<Object?, Object?> step)
        PlayStep(
          elements: [
            for (final e in (step['elements'] as List?) ?? const <Object?>[])
              if (e case final Map<Object?, Object?> m)
                ?elementFromFirestore(m.cast<String, dynamic>()),
          ],
        ),
  ];
  return Play(
    id: PlayId(id),
    groupId: GroupId('${x['groupId'] ?? ''}'),
    board: PlayBoard.tryParse(x['board'] as String?) ?? PlayBoard.blank,
    variant:
        BoardVariant.tryParse(x['variant'] as String?) ?? BoardVariant.full,
    title: '${x['title'] ?? ''}',
    note: '${x['note'] ?? ''}',
    steps: steps.isEmpty ? const [PlayStep()] : steps,
    createdBy: x['createdBy'] as String?,
    createdAt: (x['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (x['updatedAt'] as Timestamp?)?.toDate(),
    shareId: x['shareId'] as String?,
  );
}

/// A shared play (BOARD-6) as the app draws it: a play's own fields, as
/// [playFromFirestore] reads them, with no team.
PlayDraft sharedPlayFromFirestore(Map<String, dynamic> x) {
  final play = playFromFirestore('', x);
  return (
    board: play.board,
    variant: play.variant,
    title: play.title,
    note: play.note,
    steps: play.steps,
  );
}
