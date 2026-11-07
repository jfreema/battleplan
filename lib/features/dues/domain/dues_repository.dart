import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/dues/domain/due.dart';

/// Owns `dues`, `dueCharges` and `duesPayments` (DUES-1 to DUES-3, ARCH
/// §6.2). A due and its charges are created, edited and deleted together
/// by the `saveDue` and `deleteDue` callables; admins record payments on
/// charges, waive them, and write how to pay straight to Firestore, each
/// change to a charge in a transaction on the charge as it is now. The
/// rules let each person read only their own charges. Each write throws a
/// failure when refused.
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
  /// to every one of its charges, keeping what each person paid, and adds
  /// an owed charge for each of [add] not on it yet (a player who joined
  /// later). Nobody is taken off. An amount below what someone already
  /// paid is refused with an `InvalidInput` (`due-amount-below-paid`).
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

  /// Records a payment on [charge] (DUES-2), in [by]'s name: [amountCents],
  /// or, with none, everything still owed (paid in full), paid on [paidOn]
  /// ("2026-11-05"), with a short [note]. It reads the share as it is now,
  /// so a payment another admin just recorded counts too. [id]
  /// ([newRequestId], one per payment) makes trying again safe. Throws
  /// an `InvalidInput` naming a [DuePaymentRefusal] when it can't be recorded
  /// now: more than what's left, nothing left, or too many payments.
  Future<void> recordPayment(
    DueCharge charge, {
    required String id,
    required String paidOn,
    required UserId by,
    int? amountCents,
    String note = '',
  });

  /// Takes the payment [paymentId] off [charge] (a mistake): it's owed
  /// again for that much, or stays waived.
  Future<void> undoPayment(
    DueCharge charge,
    String paymentId, {
    required UserId by,
  });

  /// Waives what's still owed on [charge] ([DueStatus.waived]), or owes it
  /// again ([DueStatus.owed]): a waived share goes back to Paid when its
  /// payments cover it, and one marked paid before payments were recorded
  /// to owing all of it. A share paid with payments recorded takes them
  /// back one at a time instead ([undoPayment]).
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
