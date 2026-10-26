import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'assignment.freezed.dart';

/// A task on an event (`assignments/{id}`, SCHED-15): snacks, drinks,
/// scorekeeper, or the admin's own ([AssignmentKind.other], with a
/// [label]). It has at most one person: someone who volunteered for it,
/// or whom an admin assigned.
@freezed
abstract class Assignment with _$Assignment {
  const factory({
    required String id,
    required GroupId groupId,
    required EventId eventId,
    required AssignmentKind kind,

    /// The task's own name for [AssignmentKind.other] ("Field setup"), or a
    /// detail for the others ("Halftime oranges"). Null when there's none.
    String? label,

    /// Who has it; null while it's open.
    String? assigneeUid,

    /// Who put [assigneeUid] there: the person themselves when they
    /// volunteered, or the admin who assigned them.
    String? assignedBy,
    @Default('') String createdBy,
    DateTime? createdAt,

    /// True until the server has it.
    @Default(false) bool pending,
  }) = _Assignment;

  const new _();

  bool get isOpen => assigneeUid == null;

  /// Whether [uid] has it.
  bool isHeldBy(String uid) => assigneeUid == uid;

  /// Whether its person volunteered, rather than being assigned.
  bool get volunteered => assigneeUid != null && assignedBy == assigneeUid;
}
