import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'due.freezed.dart';

/// A due or fee a team's admins track (DUES-1): uniforms, the league fee,
/// tournament entry. Only admins read it; each person reads their own
/// [DueCharge], which copies its title, amount and date.
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
    @Default(DueStatus.owed) DueStatus status,
    DateTime? paidAt,
    DateTime? updatedAt,
  }) = _DueCharge;

  const new _();

  bool get paid => status == DueStatus.paid;

  /// What's still owed, in cents: nothing once paid or waived.
  int get owedCents => status == DueStatus.owed ? amountCents : 0;
}

/// Who a new due is for (DUES-1): a player, or a member of a group.
typedef DuePayer = ({ParticipantType type, String id, String name});

/// How to pay the team (DUES-3): handles the admins share. Payments happen
/// between people in those apps, never through Battleplan.
@freezed
abstract class DuesPayments with _$DuesPayments {
  const factory({
    @Default('') String venmo,
    @Default('') String cashApp,
    @Default('') String appleCash,
    @Default('') String note,
  }) = _DuesPayments;

  const new _();

  bool get isEmpty =>
      venmo.isEmpty && cashApp.isEmpty && appleCash.isEmpty && note.isEmpty;
}

/// A due's totals for the admins' list: how many paid, of how many, and
/// what's still owed.
typedef DueTotals = ({int paid, int count, int owedCents});

/// The totals of [charges].
DueTotals dueTotals(Iterable<DueCharge> charges) {
  var paid = 0;
  var count = 0;
  var owed = 0;
  for (final c in charges) {
    if (c.status == DueStatus.waived) continue;
    count++;
    if (c.paid) paid++;
    owed += c.owedCents;
  }
  return (paid: paid, count: count, owedCents: owed);
}

/// [handle] as a Venmo username, without a leading "@".
String venmoUser(String handle) => handle.trim().replaceFirst(RegExp('^@'), '');

/// [handle] as a Cash App cashtag, without a leading "$".
String cashTag(String handle) => handle.trim().replaceFirst(RegExp(r'^\$'), '');

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
