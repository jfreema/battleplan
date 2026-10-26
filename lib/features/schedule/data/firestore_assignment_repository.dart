import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/schedule/domain/assignment.dart';
import 'package:battleplan/features/schedule/domain/assignment_repository.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Event assignments in Firestore (SCHED-15, ARCH §6.2): one document per
/// task in `assignments`, written straight from the app; the rules decide
/// who may write what, and Functions clear them with their event, their
/// team, a member who leaves, and a deleted account.
class FirestoreAssignmentRepository implements AssignmentRepository {
  new(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _assignments =>
      _db.collection(Collections.assignments);

  @override
  Stream<List<Assignment>> watchForEvent(GroupId groupId, EventId eventId) =>
      _assignments
          .where('groupId', isEqualTo: groupId.value)
          .where('eventId', isEqualTo: eventId.value)
          // An event has at most assignmentsPerEventMax (20) tasks.
          .limit(Limits.queryLimitMax)
          .snapshots(includeMetadataChanges: true)
          .map((snap) {
            final list = [
              for (final d in snap.docs)
                assignmentFromFirestore(
                  d.id,
                  d.data(),
                  pending: d.metadata.hasPendingWrites,
                ),
            ];
            // In the order they were added; one just added (no server time
            // yet) goes last.
            int at(Assignment a) =>
                a.createdAt?.millisecondsSinceEpoch ?? 1 << 53;
            list.sort((a, b) {
              final byTime = at(a).compareTo(at(b));
              return byTime != 0 ? byTime : a.id.compareTo(b.id);
            });
            return list;
          });

  @override
  Future<void> add(
    Event event, {
    required AssignmentKind kind,
    required UserId by,
    String? label,
    UserId? assignee,
  }) => _write(
    () => _assignments.doc().set({
      'groupId': event.groupId.value,
      'eventId': event.id.value,
      'kind': kind.value,
      'label': _label(label),
      'assigneeUid': assignee?.value,
      'assignedBy': assignee == null ? null : by.value,
      'createdBy': by.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> edit(
    Assignment assignment, {
    required AssignmentKind kind,
    String? label,
  }) => _update(assignment, {'kind': kind.value, 'label': _label(label)});

  @override
  Future<void> volunteer(Assignment assignment, UserId me) =>
      _update(assignment, {'assigneeUid': me.value, 'assignedBy': me.value});

  @override
  Future<void> giveUp(Assignment assignment) =>
      _update(assignment, {'assigneeUid': null, 'assignedBy': null});

  @override
  Future<void> assign(
    Assignment assignment,
    UserId? assignee, {
    required UserId by,
  }) => _update(assignment, {
    'assigneeUid': assignee?.value,
    'assignedBy': assignee == null ? null : by.value,
  });

  @override
  Future<void> remove(Assignment assignment) =>
      _write(() => _assignments.doc(assignment.id).delete());

  Future<void> _update(Assignment assignment, Map<String, Object?> data) =>
      _write(
        () => _assignments.doc(assignment.id).update({
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );

  /// A label trimmed to [Limits.assignmentLabelMax], or null when blank.
  static String? _label(String? label) {
    final t = label?.trim() ?? '';
    if (t.isEmpty) return null;
    return t.length <= Limits.assignmentLabelMax
        ? t
        : t.substring(0, Limits.assignmentLabelMax);
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

/// Reads an `assignments` document (ARCH §6.2).
Assignment assignmentFromFirestore(
  String id,
  Map<String, dynamic> x, {
  bool pending = false,
}) => Assignment(
  id: id,
  groupId: GroupId(x['groupId'] as String? ?? ''),
  eventId: EventId(x['eventId'] as String? ?? ''),
  kind: AssignmentKind.tryParse(x['kind'] as String?) ?? AssignmentKind.other,
  label: x['label'] as String?,
  assigneeUid: x['assigneeUid'] as String?,
  assignedBy: x['assignedBy'] as String?,
  createdBy: x['createdBy'] as String? ?? '',
  createdAt: (x['createdAt'] as Timestamp?)?.toDate(),
  pending: pending,
);
