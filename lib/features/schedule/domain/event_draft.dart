import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_draft.freezed.dart';

/// The event form (SCHED-3): everything the person typed, before it
/// becomes an event, a series, or an edit. Dates are date-only values
/// (midnight UTC); times are minutes after midnight in [timeZone].
@freezed
abstract class EventDraft with _$EventDraft {
  const factory({
    required String timeZone,
    @Default(EventType.practice) EventType type,

    /// Left blank on a game, it becomes "vs. Opponent" (see [effectiveTitle]).
    @Default('') String title,
    @Default('') String description,
    @Default('') String locationName,
    @Default('') String locationAddress,
    @Default(false) bool allDay,

    /// Empty on a duplicate until picked (SCHED-3 Duplicate).
    DateTime? date,

    /// An all-day event's last day; null means the same day as [date].
    DateTime? endDate,
    @Default(18 * 60) int startMinutes,
    @Default(19 * 60 + 30) int endMinutes,
    @Default('') String opponent,
    HomeAway? homeAway,
    int? arriveMinutesBefore,
    @Default(true) bool rsvpEnabled,

    /// A deadline picked as a day and time. See [deadline].
    DateTime? rsvpDeadline,

    /// On a duplicate, the original's deadline as days before the start
    /// at a time of day in [timeZone]: it lands as far before the copy's
    /// date once one is picked (SCHED-3 copies the RSVP settings).
    int? deadlineDaysBefore,
    int? deadlineMinutes,
    @Default(<int>[]) List<int> reminderOffsets,
    @Default(true) bool notifyTeam,
    @Default(true) bool postToChat,

    /// Null: doesn't repeat (the default).
    RepeatRule? repeat,

    /// On a "This and following" edit, the edited event's series date: the
    /// new rule starts there, as the server starts it, even when the event
    /// was moved to another day (SCHED-6).
    String? seriesFrom,

    /// On a "This and following" edit, how many of the old series' events
    /// fall before [seriesFrom]. A rule that ends after N events counts
    /// the whole series, so the server leaves these out (SCHED-6).
    @Default(0) int countBefore,
  }) = _EventDraft;

  const new _();

  /// A copy of [event] for editing it, or for Duplicate ([duplicate]):
  /// everything but the date, which stays empty, and nothing of its RSVPs,
  /// canceled state, or series (SCHED-3).
  factory fromEvent(Event event, {bool duplicate = false}) {
    final start = ZonedTime.wallClock(event.timeZone, event.startAt);
    final end = ZonedTime.wallClock(event.timeZone, event.endAt);
    final firstDay = event.allDay && event.startDate != null
        ? parseDateKey(event.startDate!)
        : DateTime.utc(start.year, start.month, start.day);
    final lastDay = event.allDay && event.endDate != null
        ? parseDateKey(event.endDate!)
        : null;
    final deadline = event.rsvpDeadline == null
        ? null
        : ZonedTime.wallClock(event.timeZone, event.rsvpDeadline!);
    final deadlineDay = deadline == null
        ? null
        : DateTime.utc(deadline.year, deadline.month, deadline.day);
    // A game titled as it would title itself stays automatic, so changing
    // the opponent changes the title ("duplicate last week's game, change
    // the date and opponent", SCHED-3 acceptance).
    final autoTitle =
        event.isGame &&
        event.title.trim() ==
            autoGameTitle(event.opponent ?? '', event.homeAway);
    return EventDraft(
      timeZone: event.timeZone,
      type: event.type,
      title: autoTitle ? '' : event.title,
      description: event.description,
      locationName: event.location?.name ?? '',
      locationAddress: event.location?.address ?? '',
      allDay: event.allDay,
      date: duplicate ? null : firstDay,
      endDate: duplicate || lastDay == firstDay ? null : lastDay,
      startMinutes: event.allDay ? 18 * 60 : start.hour * 60 + start.minute,
      endMinutes: event.allDay ? 19 * 60 + 30 : end.hour * 60 + end.minute,
      opponent: event.opponent ?? '',
      homeAway: event.homeAway,
      arriveMinutesBefore: event.arriveMinutesBefore,
      rsvpEnabled: event.rsvpEnabled,
      // A copy's deadline follows its own date, as far before it.
      rsvpDeadline: duplicate ? null : event.rsvpDeadline,
      deadlineDaysBefore: duplicate && deadlineDay != null
          ? firstDay.difference(deadlineDay).inDays
          : null,
      deadlineMinutes: duplicate && deadline != null
          ? deadline.hour * 60 + deadline.minute
          : null,
      reminderOffsets: event.reminderOffsets,
      notifyTeam: event.notifyTeam,
      postToChat: event.postToChat,
    );
  }

  bool get isGame => type == EventType.game;

  /// The title as saved: what was typed, or "vs. Eagles" / "@ Eagles" for a
  /// game left blank.
  String get effectiveTitle {
    final typed = title.trim();
    if (typed.isNotEmpty || !isGame) return typed;
    return autoGameTitle(opponent, homeAway);
  }

  /// The RSVP deadline as saved: the one picked, or on a duplicate the
  /// original's, as far before this date. Null without either.
  DateTime? get deadline {
    if (rsvpDeadline != null) return rsvpDeadline;
    final days = deadlineDaysBefore;
    final minutes = deadlineMinutes;
    if (days == null || minutes == null || date == null) return null;
    return ZonedTime.instantOf(timeZone, addDays(date!, -days), minutes);
  }

  /// The location, or null when both parts are empty.
  EventLocation? get location {
    final name = locationName.trim();
    final address = locationAddress.trim();
    if (name.isEmpty && address.isEmpty) return null;
    return EventLocation(name: name, address: address);
  }

  /// The last day of an all-day event.
  DateTime? get lastDay => endDate ?? date;

  /// When it starts: the time in [timeZone] on [date], or midnight there
  /// for all-day events. Null until a date is picked.
  DateTime? get startAt => date == null ? null : startOn(date!);

  /// When it ends: an end time at or before the start means the next day;
  /// all-day events end at the midnight after their last day.
  DateTime? get endAt => date == null ? null : endOn(date!, lastDay: lastDay);

  /// The start on [day], for each date of a series.
  DateTime startOn(DateTime day) =>
      ZonedTime.instantOf(timeZone, day, allDay ? 0 : startMinutes);

  /// The end for an event starting on [day].
  DateTime endOn(DateTime day, {DateTime? lastDay}) {
    if (allDay) {
      return ZonedTime.instantOf(timeZone, addDays(lastDay ?? day, 1), 0);
    }
    final nextDay = endMinutes <= startMinutes;
    return ZonedTime.instantOf(
      timeZone,
      nextDay ? addDays(day, 1) : day,
      endMinutes,
    );
  }

  /// The series rule as sent, starting on [date] (on a "This and
  /// following" edit, on [seriesFrom]); null when it doesn't repeat or has
  /// no date yet. Its count is the whole series' (see [savedRecurrence]).
  Recurrence? get recurrence {
    final r = repeat;
    final d = date;
    if (r == null || d == null) return null;
    return Recurrence(
      freq: r.freq,
      startDate: seriesFrom ?? dateKey(d),
      interval: r.interval,
      byWeekday: r.freq == RepeatFreq.weekly
          ? ([...r.byWeekday]..sort())
          : const [],
      untilDate: r.endsOnDate ? r.untilDate : null,
      count: r.endsOnDate ? null : r.count,
      skipDates: [...r.skipDates]..sort(),
    );
  }

  /// The rule as the server saves it: on a "This and following" edit, a
  /// rule that ends after N events keeps only those left after the
  /// [countBefore] that came before this one, at least one (SCHED-6).
  Recurrence? get savedRecurrence {
    final r = recurrence;
    if (r == null || seriesFrom == null || r.count == null) return r;
    return r.copyWith(count: math.max(1, r.count! - countBefore));
  }

  /// The series' dates for the form's preview (SCHED-3): exactly what
  /// saving makes.
  SeriesDates? get seriesDates =>
      savedRecurrence == null ? null : expandRecurrence(savedRecurrence!);

  /// The event's fields without dates (`eventSeries.template`).
  EventTemplate get template => EventTemplate(
    type: type,
    title: effectiveTitle,
    description: description.trim(),
    location: location,
    allDay: allDay,
    startTime: allDay ? null : hhmm(startMinutes),
    endTime: allDay ? null : hhmm(endMinutes),
    timeZone: timeZone,
    arriveMinutesBefore: isGame ? arriveMinutesBefore : null,
    opponent: isGame && opponent.trim().isNotEmpty ? opponent.trim() : null,
    homeAway: isGame ? homeAway : null,
    rsvpEnabled: rsvpEnabled,
    reminderOffsets: [
      for (final o in reminderOffsetsMinutes)
        if (reminderOffsets.contains(o)) o,
    ],
    notifyTeam: notifyTeam,
    postToChat: postToChat,
  );

  /// What keeps it from saving at [now], or null when it's ready. Each
  /// check matches a rule the server enforces too.
  DraftProblem? problemAt(DateTime now) {
    final t = effectiveTitle;
    if (t.isEmpty) return DraftProblem.title;
    if (tooLong(t, Limits.eventTitleMax)) return DraftProblem.title;
    if (tooLong(description, Limits.eventNotesMax)) {
      return DraftProblem.notes;
    }
    if (tooLong(locationName, Limits.locationNameMax) ||
        tooLong(locationAddress, Limits.locationAddressMax)) {
      return DraftProblem.location;
    }
    if (isGame && tooLong(opponent, Limits.opponentMax)) {
      return DraftProblem.opponent;
    }
    if (date == null) return DraftProblem.date;
    if (allDay && endDate != null && endDate!.isBefore(date!)) {
      return DraftProblem.date;
    }
    if (reminderOffsets.length > Limits.eventRemindersMax) {
      return DraftProblem.reminders;
    }
    if (rsvpEnabled && repeat == null && deadline != null) {
      if (!deadline!.isBefore(startAt!)) return DraftProblem.deadline;
    }
    if (repeat != null) {
      final rule = savedRecurrence!;
      if (!rule.isValid) return DraftProblem.repeat;
      if (expandRecurrence(rule).dates.isEmpty) return DraftProblem.repeat;
    }
    return null;
  }
}

/// Why an event can't be saved yet; the form marks that field.
enum DraftProblem {
  title,
  notes,
  location,
  opponent,
  date,
  deadline,
  reminders,
  repeat,
}

/// The form's Repeat section (SCHED-3).
@freezed
abstract class RepeatRule with _$RepeatRule {
  const factory({
    @Default(RepeatFreq.weekly) RepeatFreq freq,
    @Default(1) int interval,
    @Default(<int>[]) List<int> byWeekday,

    /// Ends on a date ([untilDate]) or after [count] events.
    @Default(true) bool endsOnDate,
    String? untilDate,
    @Default(10) int count,
    @Default(<String>[]) List<String> skipDates,
  }) = _RepeatRule;

  const new _();

  /// A rule from a series' recurrence, for "This and following" edits.
  factory fromRecurrence(Recurrence r) => RepeatRule(
    freq: r.freq,
    interval: r.interval,
    byWeekday: r.byWeekday,
    endsOnDate: r.untilDate != null,
    untilDate: r.untilDate,
    count: r.count ?? 10,
    skipDates: r.skipDates,
  );
}

/// An event's fields without its dates (`eventSeries.template`, ARCH
/// §6.2): every occurrence gets these, on its own date.
@freezed
abstract class EventTemplate with _$EventTemplate {
  const factory({
    required EventType type,
    required String title,
    required String description,
    required bool allDay,
    required String timeZone,
    required bool rsvpEnabled,
    required List<int> reminderOffsets,
    required bool notifyTeam,
    required bool postToChat,
    EventLocation? location,

    /// 'HH:mm' in [timeZone]; null on all-day events.
    String? startTime,
    String? endTime,
    int? arriveMinutesBefore,
    String? opponent,
    HomeAway? homeAway,
  }) = _EventTemplate;
}

/// 'HH:mm' for [minutes] after midnight.
String hhmm(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';

/// Whether [text] is over [max] characters as the rules count them (code
/// points).
bool tooLong(String text, int max) => text.trim().runes.length > max;
