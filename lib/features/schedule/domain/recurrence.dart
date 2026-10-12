import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurrence.freezed.dart';

/// How often a series repeats (SCHED-3).
enum RepeatFreq {
  /// Every N days, for tournaments and camps.
  daily('daily'),

  /// On chosen weekdays every N weeks, for practices.
  weekly('weekly');

  new(this.value);

  /// The string stored in Firestore.
  final String value;

  static RepeatFreq? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

/// A repeating series' rule (`eventSeries.recurrence`, ARCH §6.2). Exactly
/// one of [untilDate] and [count] is set.
@freezed
abstract class Recurrence with _$Recurrence {
  const factory({
    required RepeatFreq freq,
    required String startDate,
    @Default(1) int interval,

    /// ISO weekdays, Monday = 1 (weekly only).
    @Default(<int>[]) List<int> byWeekday,

    /// The last day it may fall on, 'YYYY-MM-DD'.
    String? untilDate,

    /// How many events, counting only the dates kept after [skipDates].
    int? count,

    /// Holidays and breaks (SCHED-3), 'YYYY-MM-DD'.
    @Default(<String>[]) List<String> skipDates,
  }) = _Recurrence;

  const new _();

  /// Whether the server would accept it: interval 1 to 8, at least one day
  /// for weekly, one way to end, and skip dates within the limit.
  bool get isValid =>
      interval >= 1 &&
      interval <= Limits.seriesIntervalMax &&
      (freq == RepeatFreq.daily ||
          (byWeekday.isNotEmpty && byWeekday.every((d) => d >= 1 && d <= 7))) &&
      (untilDate == null) != (count == null) &&
      (count == null || count! >= 1) &&
      (untilDate == null || untilDate!.compareTo(startDate) >= 0) &&
      skipDates.length <= Limits.seriesSkipDatesMax;
}

/// A repeating series (`eventSeries/{id}`). Members read it for the line
/// "Repeats weekly on Tue and Thu until Dec 17" (SCHED-4).
@freezed
abstract class EventSeries with _$EventSeries {
  const factory({
    required String id,
    required GroupId groupId,
    required String timeZone,
    required Recurrence recurrence,
    required String createdBy,
  }) = _EventSeries;
}

/// What a series rule makes: the dates of its events, and the skip dates
/// that fell on the rule (shown crossed out, tap to bring back).
typedef SeriesDates = ({List<String> dates, List<String> skipped});

/// The dates [rule] makes, in order (ARCH §6.4, identical to the server's
/// expansion; the two share test vectors). Walks from the start date: daily
/// every `interval` days; weekly on `byWeekday`, counting weeks from the
/// Monday of the start date's week and keeping every `interval`-th, never
/// before the start date. Stops after `untilDate`, after `count` kept
/// dates, 12 months after the start, or at 400 events; skip dates are left
/// out and don't count.
SeriesDates expandRecurrence(Recurrence rule) {
  final start = parseDateKey(rule.startDate);
  final until = rule.untilDate == null ? null : parseDateKey(rule.untilDate!);
  final last = lastAllowedDate(start);
  final monday = addDays(start, 1 - start.weekday);
  final skip = rule.skipDates.toSet();
  final interval = rule.interval < 1 ? 1 : rule.interval;
  final dates = <String>[];
  final skipped = <String>[];
  for (var d = start; !d.isAfter(last); d = addDays(d, 1)) {
    if (until != null && d.isAfter(until)) break;
    final matches = switch (rule.freq) {
      RepeatFreq.daily => daysBetween(start, d) % interval == 0,
      RepeatFreq.weekly =>
        rule.byWeekday.contains(d.weekday) &&
            (daysBetween(monday, d) ~/ 7) % interval == 0,
    };
    if (!matches) continue;
    final key = dateKey(d);
    if (skip.contains(key)) {
      skipped.add(key);
      continue;
    }
    dates.add(key);
    if (rule.count != null && dates.length >= rule.count!) break;
    if (dates.length >= Limits.seriesEventsMax) break;
  }
  return (dates: dates, skipped: skipped);
}

/// The last day a series starting on [start] may reach: 12 months on,
/// with month-end days clamped (2028-02-29 → 2029-02-28), as the server
/// counts it.
DateTime lastAllowedDate(DateTime start) {
  final month = start.month + Limits.seriesMaxMonths;
  // Day 0 of the month after is the target month's last day.
  final lastDay = DateTime.utc(start.year, month + 1, 0).day;
  return DateTime.utc(
    start.year,
    month,
    start.day < lastDay ? start.day : lastDay,
  );
}

/// 'YYYY-MM-DD' for a date (only its year, month, and day count).
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// A 'YYYY-MM-DD' date as midnight UTC, so day arithmetic never meets a
/// daylight-saving change.
DateTime parseDateKey(String key) {
  final p = key.split('-');
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// [d] moved by [days] calendar days, as a UTC date.
DateTime addDays(DateTime d, int days) =>
    DateTime.utc(d.year, d.month, d.day + days);

/// Whole days from [a] to [b], counted by calendar date.
int daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// "This event" or "This and following events" (SCHED-6, SCHED-7).
enum SeriesScope {
  thisEvent('this'),
  following('following');

  new(this.value);

  /// The string the `saveEventSeries` callable takes.
  final String value;
}

/// What `saveEventSeries` did, or would do on a dry run (the confirmation
/// "Removes 4 practices; 9 people had answered", SCHED-6).
@freezed
abstract class SeriesResult with _$SeriesResult {
  const factory({
    String? seriesId,
    @Default(0) int created,
    @Default(0) int updated,
    @Default(0) int removed,
    @Default(0) int removedRsvps,
    @Default(0) int canceled,
  }) = _SeriesResult;
}
