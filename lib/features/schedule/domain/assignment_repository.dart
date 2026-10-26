import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/schedule/domain/assignment.dart';
import 'package:battleplan/features/schedule/domain/event.dart';

/// Owns `assignments` (SCHED-15, ARCH §5.2). Tasks are written straight to
/// Firestore; the rules let admins add, change, and remove them and assign
/// anyone on the team, and let any member take an open one or give up
/// their own. Each write throws a failure when the rules refuse it.
abstract interface class AssignmentRepository {
  /// An event's tasks, live, in the order they were added.
  Stream<List<Assignment>> watchForEvent(GroupId groupId, EventId eventId);

  /// Adds a task to [event], open, or held by [assignee] when an admin
  /// assigns someone as they add it.
  Future<void> add(
    Event event, {
    required AssignmentKind kind,
    required UserId by,
    String? label,
    UserId? assignee,
  });

  /// Changes a task's kind and label (admins).
  Future<void> edit(
    Assignment assignment, {
    required AssignmentKind kind,
    String? label,
  });

  /// [me] takes an open task.
  Future<void> volunteer(Assignment assignment, UserId me);

  /// The person who has a task gives it up, and it's open again.
  Future<void> giveUp(Assignment assignment);

  /// An admin puts [assignee] on a task, or opens it again with null.
  Future<void> assign(
    Assignment assignment,
    UserId? assignee, {
    required UserId by,
  });

  /// Removes a task (admins).
  Future<void> remove(Assignment assignment);
}
