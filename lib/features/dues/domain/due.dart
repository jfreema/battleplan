import 'dart:math';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'due.freezed.dart';

/// A due or fee a team's admins track (DUES-1): uniforms, the league fee,
/// tournament entry. Only admins read it; each person reads their own
/// [DueCharge], which copies its title, amount, date and note.
@freezed
abstract class Due with _$Due {
  const factory({
    required String id,
    required GroupId groupId,
    required String title,

    /// In cents, so $45.50 is 4550 (US only, DUES-1).
    required int amountCents,

    /// The day it's due, "2026-11-30", or null for no date.
    String? dueOn,
    @Default('') String note,
    @Default('') String createdBy,
    DateTime? createdAt,
  }) = _Due;
}

/// One payment on a share (DUES-2), as an admin records it once the money
/// arrives, outside Battleplan: part of what's owed, or all of what's left.
@freezed
abstract class DuePayment with _$DuePayment {
  const factory({
    /// The app's ID for it, the same on every try, so a retry never
    /// records it twice ([newRequestId]).
    required String id,

    /// In cents, from 1 up to what was left.
    required int amountCents,

    /// The day it was paid, "2026-11-05".
    required String paidOn,

    /// Who recorded it (a uid), or empty for a share marked paid before
    /// payments were recorded, which became one payment when its amount
    /// changed.
    @Default('') String by,

    /// A short note, like "Venmo" or "Cash at practice" (up to
    /// [Limits.duePaymentNoteMax]).
    @Default('') String note,
  }) = _DuePayment;
}

/// Where a share stands (DUES-2), as everyone sees it: owes all of it,
/// partly paid, paid in full, or waived.
enum DueShareState { owes, partlyPaid, paid, waived }

/// One person's share of a [Due] (DUES-2): a player on a team, or a member
/// of a basic group. Admins see everyone's; a member sees their own, and a
/// parent or guardian their players'.
@freezed
abstract class DueCharge with _$DueCharge {
  const factory({
    required String id,
    required GroupId groupId,
    required String dueId,
    required String title,
    required int amountCents,
    required ParticipantType participantType,
    required String participantId,
    required String participantName,
    String? dueOn,

    /// The due's note, for everyone who owes it (DUES-2).
    @Default('') String note,
    @Default(DueStatus.owed) DueStatus status,
    DateTime? paidAt,
    DateTime? updatedAt,

    /// What's been recorded as paid, oldest first (DUES-2).
    @Default(<DuePayment>[]) List<DuePayment> payments,

    /// Their total, in cents, as stored; null on a share from before
    /// payments were recorded, where Paid means paid in full.
    int? recordedCents,
  }) = _DueCharge;

  const new _();

  /// Paid in full.
  bool get paid => status == DueStatus.paid;

  /// Whether payments are recorded on it (or it's never been paid): not a
  /// share marked paid before payments were recorded.
  bool get recordsPayments => recordedCents != null || status != DueStatus.paid;

  /// What's been paid, in cents: the payments recorded, or all of it on a
  /// share marked paid before payments were recorded.
  int get paidCents => status == DueStatus.paid && recordedCents == null
      ? amountCents
      : min(recordedCents ?? 0, amountCents);

  /// What's still owed, in cents: nothing once paid in full or waived.
  int get owedCents =>
      status == DueStatus.owed ? max(0, amountCents - paidCents) : 0;

  /// What counts toward what's owed in all: the amount, or on a waived
  /// share only what was paid before the rest was let go.
  int get chargedCents => status == DueStatus.waived ? paidCents : amountCents;

  /// Owed, with some of it paid.
  bool get partlyPaid => status == DueStatus.owed && paidCents > 0;

  DueShareState get state => switch (status) {
    DueStatus.paid => DueShareState.paid,
    DueStatus.waived => DueShareState.waived,
    DueStatus.owed =>
      paidCents > 0 ? DueShareState.partlyPaid : DueShareState.owes,
  };

  /// Who it's for: one person or player across every due.
  String get personKey => '${participantType.value}/$participantId';
}

/// A share's payments, total, and status after a change (DUES-2), as the
/// app writes them.
typedef DueChargePayments = ({
  List<DuePayment> payments,
  int paidCents,
  DueStatus status,
});

/// Why a payment can't be recorded.
enum DuePaymentRefusal implements Exception {
  /// Paid in full, or waived: nothing left to record.
  nothingLeft,

  /// More than what's left, or no amount at all.
  tooMuch,

  /// [Limits.duePaymentsMax] payments already.
  full,
}

/// [charge] with [payment] added at the end (DUES-2): Paid once it covers
/// the amount. A payment already on it (a retry) leaves it as it is.
/// Refused with a [DuePaymentRefusal] otherwise.
DueChargePayments addDuePayment(DueCharge charge, DuePayment payment) {
  final now = (
    payments: charge.payments,
    paidCents: charge.recordedCents ?? 0,
    status: charge.status,
  );
  if (charge.payments.any((p) => p.id == payment.id)) return now;
  if (charge.status != DueStatus.owed || charge.owedCents == 0) {
    throw DuePaymentRefusal.nothingLeft;
  }
  if (payment.amountCents < 1 || payment.amountCents > charge.owedCents) {
    throw DuePaymentRefusal.tooMuch;
  }
  if (charge.payments.length >= Limits.duePaymentsMax) {
    throw DuePaymentRefusal.full;
  }
  final paid = now.paidCents + payment.amountCents;
  return (
    payments: [...charge.payments, payment],
    paidCents: paid,
    status: paid == charge.amountCents ? DueStatus.paid : DueStatus.owed,
  );
}

/// [charge] without the payment [paymentId] (DUES-2), a mistake taken
/// back: owed again for its amount, unless waived. One that isn't there
/// (already taken back) leaves it as it is.
DueChargePayments removeDuePayment(DueCharge charge, String paymentId) {
  final gone = charge.payments.where((p) => p.id == paymentId).firstOrNull;
  final paid = charge.recordedCents ?? 0;
  if (gone == null) {
    return (payments: charge.payments, paidCents: paid, status: charge.status);
  }
  return (
    payments: [
      for (final p in charge.payments)
        if (p.id != paymentId) p,
    ],
    paidCents: paid - gone.amountCents,
    status: charge.status == DueStatus.waived
        ? DueStatus.waived
        : DueStatus.owed,
  );
}

/// The status a share goes back to when it's no longer waived: Paid when
/// its payments cover it, else owed.
DueStatus unwaivedStatus(DueCharge charge) =>
    charge.recordedCents != null && charge.recordedCents! >= charge.amountCents
    ? DueStatus.paid
    : DueStatus.owed;

/// Who a new due is for (DUES-1): a player, or a member of a group.
typedef DuePayer = ({ParticipantType type, String id, String name});

/// How to pay the team (DUES-3): handles the admins or coaches share.
/// Payments happen between people in those apps, never through Battleplan.
@freezed
abstract class DuesPayments with _$DuesPayments {
  const factory({
    @Default('') String venmo,
    @Default('') String cashApp,
    @Default('') String appleCash,
    @Default('') String note,

    /// Who saved it last, which everyone sees ("Updated by Coach Lee").
    @Default('') String updatedBy,
  }) = _DuesPayments;

  const new _();

  bool get isEmpty =>
      venmo.isEmpty && cashApp.isEmpty && appleCash.isEmpty && note.isEmpty;
}

/// Totals across shares (DUES-2): how many are paid in full and partly
/// paid, of how many not waived, and in cents what's owed in all, what's
/// been paid, and what's still owed. A waived share counts only what was
/// paid before the rest was let go.
typedef DueTotals = ({
  int paid,
  int partly,
  int count,
  int chargedCents,
  int paidCents,
  int owedCents,
});

/// The totals of [charges].
DueTotals dueTotals(Iterable<DueCharge> charges) {
  var paid = 0;
  var partly = 0;
  var count = 0;
  var charged = 0;
  var paidCents = 0;
  var owed = 0;
  for (final c in charges) {
    charged += c.chargedCents;
    paidCents += c.paidCents;
    owed += c.owedCents;
    if (c.status == DueStatus.waived) continue;
    count++;
    if (c.paid) paid++;
    if (c.partlyPaid) partly++;
  }
  return (
    paid: paid,
    partly: partly,
    count: count,
    chargedCents: charged,
    paidCents: paidCents,
    owedCents: owed,
  );
}

/// One person (or player) across every due (DUES-5): their shares, with
/// the due's title on each, and their totals.
typedef DuePerson = ({
  String key,
  String name,
  List<DueCharge> shares,
  DueTotals totals,
});

/// Everyone on [charges], who owes most first, then by name; each one's
/// shares with what's still owed first, then by title. Named as on their
/// newest share.
List<DuePerson> duePeople(Iterable<DueCharge> charges) {
  final byKey = <String, List<DueCharge>>{};
  for (final c in charges) {
    (byKey[c.personKey] ??= []).add(c);
  }
  int byName(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
  final people = [
    for (final MapEntry(:key, value: shares) in byKey.entries)
      (
        key: key,
        name: _newest(shares).participantName,
        shares: [...shares]..sort(compareShares),
        totals: dueTotals(shares),
      ),
  ];
  return people..sort((a, b) {
    final most = b.totals.owedCents.compareTo(a.totals.owedCents);
    return most != 0 ? most : byName(a.name, b.name);
  });
}

DueCharge _newest(List<DueCharge> shares) => shares.reduce(
  (a, b) =>
      (b.updatedAt ?? DateTime(0)).isAfter(a.updatedAt ?? DateTime(0)) ? b : a,
);

/// Who owes most first (what's left, largest first), then partly paid
/// before paid, paid, then waived; then by name, then by title (DUES-2).
int compareShares(DueCharge a, DueCharge b) {
  int rank(DueCharge x) => switch (x.state) {
    DueShareState.owes || DueShareState.partlyPaid => 0,
    DueShareState.paid => 1,
    DueShareState.waived => 2,
  };
  final byRank = rank(a).compareTo(rank(b));
  if (byRank != 0) return byRank;
  final most = b.owedCents.compareTo(a.owedCents);
  if (most != 0) return most;
  final name = a.participantName.toLowerCase().compareTo(
    b.participantName.toLowerCase(),
  );
  return name != 0
      ? name
      : a.title.toLowerCase().compareTo(b.title.toLowerCase());
}

/// [d] as a day, "2026-11-05".
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// [s] without "https://", "www." or anything after "?" or "#", for a
/// pasted profile link.
String _bareLink(String s) => s
    .trim()
    .replaceFirst(RegExp('^https?://', caseSensitive: false), '')
    .replaceFirst(RegExp(r'^www\.', caseSensitive: false), '')
    .split(RegExp('[?#]'))
    .first;

/// [handle] as a Venmo username, without a leading "@" or the rest of a
/// pasted profile link ("https://venmo.com/u/Thunder-U14").
String venmoUser(String handle) => _bareLink(handle)
    .replaceFirst(RegExp(r'^(account\.)?venmo\.com/', caseSensitive: false), '')
    .replaceFirst(RegExp('^u/', caseSensitive: false), '')
    .replaceAll(RegExp(r'/+$'), '')
    .replaceFirst(RegExp('^@'), '')
    .replaceAll(RegExp(r'\s'), '');

/// [handle] as a Cash App cashtag, without a leading "$" or the rest of a
/// pasted profile link ("https://cash.app/$ThunderU14").
String cashTag(String handle) =>
    _bareLink(handle)
        .replaceFirst(RegExp(r'^cash\.app/', caseSensitive: false), '')
        .replaceAll(RegExp(r'/+$'), '')
        .replaceFirst(RegExp(r'^\$'), '')
        .replaceAll(RegExp(r'\s'), '');

/// [dueOn] ("2026-11-30") is before [today]'s date: past due.
bool duePassed(String dueOn, DateTime today) {
  final d = DateTime.tryParse(dueOn);
  return d != null && d.isBefore(DateTime(today.year, today.month, today.day));
}

/// [text] as an amount in cents, 1 to [Limits.dueAmountMaxCents], or null
/// when it isn't one (DUES-1). "$" and spaces are ignored. With both "."
/// and ",", the last is the decimal point ("1,234.50", "1.234,50"). With
/// commas only, groups of three are thousands ("1,234") and one or two
/// digits after a single comma are cents ("12,5", "12,50"). At most two
/// decimals.
int? parseDollars(String text) {
  final t = text.replaceAll(RegExp(r'[\$\s]'), '');
  if (t.isEmpty || !RegExp(r'^[0-9.,]+$').hasMatch(t)) return null;
  final lastDot = t.lastIndexOf('.');
  final lastComma = t.lastIndexOf(',');
  String whole;
  var cents = '';
  String? grouping;
  if (lastDot >= 0 && lastComma >= 0) {
    final point = lastDot > lastComma ? lastDot : lastComma;
    grouping = lastDot > lastComma ? ',' : '.';
    whole = t.substring(0, point);
    cents = t.substring(point + 1);
    if (cents.isEmpty) return null;
  } else if (lastComma >= 0) {
    final commas = ','.allMatches(t).length;
    final after = t.substring(lastComma + 1);
    if (commas == 1 && (after.length == 1 || after.length == 2)) {
      whole = t.substring(0, lastComma);
      cents = after;
    } else {
      whole = t;
      grouping = ',';
    }
  } else if (lastDot >= 0) {
    if ('.'.allMatches(t).length > 1) return null;
    whole = t.substring(0, lastDot);
    cents = t.substring(lastDot + 1);
  } else {
    whole = t;
  }
  if (cents.length > 2 || !RegExp(r'^[0-9]*$').hasMatch(cents)) return null;
  if (grouping != null && whole.contains(grouping)) {
    final g = RegExp.escape(grouping);
    if (!RegExp('^[0-9]{1,3}($g[0-9]{3})+\$').hasMatch(whole)) return null;
    whole = whole.replaceAll(grouping, '');
  }
  if (!RegExp(r'^[0-9]*$').hasMatch(whole)) return null;
  if (whole.isEmpty && cents.isEmpty) return null;
  if (whole.length > 9) return null;
  final total =
      int.parse(whole.isEmpty ? '0' : whole) * 100 +
      int.parse(cents.padRight(2, '0'));
  return total < 1 || total > Limits.dueAmountMaxCents ? null : total;
}
