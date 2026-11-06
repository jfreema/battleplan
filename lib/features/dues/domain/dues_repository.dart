import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/dues/domain/due.dart';

/// Owns `dues`, `dueCharges` and `duesPayments` (DUES-1 to DUES-3, ARCH
/// §6.2). A due and its charges are created, edited and deleted together
/// by the `saveDue` and `deleteDue` callables; admins mark charges paid and
/// write how to pay straight to Firestore. The rules let each person read
/// only their own charges. Each write throws a failure when refused.
abstract interface class DuesRepository {
  /// The team's dues (admins), newest first.
  Stream<List<Due>> watchDues(GroupId groupId);

  /// Everyone's share of one due (admins), up to [Limits.duesChargesMax].
  Stream<List<DueCharge>> watchDueCharges(GroupId groupId, String dueId);

  /// The charges of [payers] (me, or my players): what I owe. One query
  /// per payer, which the rules can check. A payer whose query fails counts
  /// as owing nothing; the stream fails only when every one does.
  Stream<List<DueCharge>> watchMine(GroupId groupId, List<DuePayer> payers);

  /// How to pay the team, or empty.
  Stream<DuesPayments> watchPayments(GroupId groupId);

  /// Adds a due and a charge for each of [payers] (up to
  /// [Limits.duesChargesMax]), on the server. The server names each payer
  /// from the roster. [requestId] ([newRequestId], one per New due) makes
  /// trying again after a lost reply safe: it never adds a second due.
  Future<void> create(
    GroupId groupId, {
    required String title,
    required int amountCents,
    required String? dueOn,
    required String note,
    required List<DuePayer> payers,
    String? requestId,
  });

  /// Changes a due, and the server copies its title, amount, date and note
  /// to every one of its charges, and adds an owed charge for each of [add]
  /// not on it yet (a player who joined later). Nobody is taken off.
  Future<void> edit(
    Due due, {
    required String title,
    required int amountCents,
    required String? dueOn,
    required String note,
    List<DuePayer> add = const [],
  });

  /// Removes a due and all its charges, on the server.
  Future<void> remove(Due due);

  /// Marks one person's share paid, owed again, or waived.
  Future<void> setStatus(
    DueCharge charge,
    DueStatus status, {
    required UserId by,
  });

  /// Saves how to pay the team, in [by]'s name.
  Future<void> savePayments(
    GroupId groupId,
    DuesPayments payments, {
    required UserId by,
  });
}
