import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';

/// A game, practice, or other event on a team's schedule (ARCH §6.2
/// `events`, SCHED-3). Times are instants; [timeZone] says where the
/// wall-clock time was set. All-day events also carry their dates, which
/// never shift with the viewer's zone (SCHED-9).
@freezed
abstract class Event with _$Event {
  const factory({
    required EventId id,
    required GroupId groupId,
    required EventType type,
    required String title,
    required DateTime startAt,
    required DateTime endAt,
    required String timeZone,
    required String createdBy,

    /// The form's Notes; '' when none.
    @Default('') String description,
    EventLocation? location,
    @Default(false) bool allDay,

    /// 'YYYY-MM-DD', set only on all-day events. [endDate] is the last day.
    String? startDate,
    String? endDate,

    /// Games only (SCHED-3): "Arrive 30 min early".
    int? arriveMinutesBefore,
    String? opponent,
    HomeAway? homeAway,
    @Default(true) bool rsvpEnabled,

    DateTime? rsvpDeadline,

    /// Minutes before the start, from [reminderOffsetsMinutes] (SCHED-8).
    @Default(<int>[]) List<int> reminderOffsets,
    @Default(true) bool notifyTeam,
    @Default(true) bool postToChat,

    /// Set by Functions on events of a repeating series (SCHED-6).
    String? seriesId,

    /// The occurrence's date in [timeZone], 'YYYY-MM-DD'.
    String? seriesDate,

    /// Fields edited with "This event"; later series edits leave them be.
    @Default(<String>[]) List<String> seriesOverrides,

    /// Kept by the server from the RSVPs: [rsvpCounts] counts players, and
    /// [staffCounts] everyone answering for themselves, coaches and others
    /// (PLAYER-6, D34). Events made before one team type may still count
    /// members in [rsvpCounts].
    @Default(RsvpCounts()) RsvpCounts rsvpCounts,
    @Default(RsvpCounts()) RsvpCounts staffCounts,

    /// Set once when canceled (SCHED-7); never cleared.
    DateTime? canceledAt,
    String? canceledBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Event;

  const new _();

  bool get isCanceled => canceledAt != null;

  bool get isGame => type == EventType.game;

  bool get inSeries => seriesId != null;

  /// Whether the deadline has passed at [now]; after it only admins can
  /// change answers (SCHED-5).
  bool deadlinePassedAt(DateTime now) =>
      rsvpDeadline != null && !now.isBefore(rsvpDeadline!);

  /// Whether anyone can answer at all: RSVPs on and not canceled.
  bool get takesRsvps => rsvpEnabled && !isCanceled;

  /// Started before [now]; Past lists these (SCHED-1).
  bool startedBefore(DateTime now) => startAt.isBefore(now);
}

/// Where an event is. Either part may be empty, not both.
@freezed
abstract class EventLocation with _$EventLocation {
  const factory({@Default('') String name, @Default('') String address}) =
      _EventLocation;

  const new _();

  /// "Riverside Park", or the address when there's no name.
  String get label => name.isNotEmpty ? name : address;

  /// What Directions searches for in Maps: the address when known.
  String get mapsQuery => address.isNotEmpty
      ? (name.isNotEmpty ? '$name, $address' : address)
      : name;
}

/// Going, maybe, and not going counts (`rsvpCounts`, `staffCounts`).
@freezed
abstract class RsvpCounts with _$RsvpCounts {
  const factory({
    @Default(0) int going,
    @Default(0) int maybe,
    @Default(0) int notGoing,
  }) = _RsvpCounts;

  const new _();

  int get answered => going + maybe + notGoing;

  /// Both counts together, for a team without players.
  RsvpCounts operator +(RsvpCounts other) => RsvpCounts(
    going: going + other.going,
    maybe: maybe + other.maybe,
    notGoing: notGoing + other.notGoing,
  );

  int of(RsvpStatus status) => switch (status) {
    RsvpStatus.going => going,
    RsvpStatus.maybe => maybe,
    RsvpStatus.notGoing => notGoing,
  };
}

/// Which kinds of events the schedule shows (SCHED-2's filter).
enum EventFilter {
  games,
  practices,
  other;

  /// The filter an event falls under: meetings, socials, and other events
  /// are all "Other".
  static EventFilter of(EventType type) => switch (type) {
    EventType.game => games,
    EventType.practice => practices,
    _ => other,
  };
}

/// "vs. Eagles" at home (or when it's not set), "@ Eagles" away: the
/// title a game gets when it's left blank (SCHED-3).
String autoGameTitle(String opponent, HomeAway? homeAway) {
  final o = opponent.trim();
  if (o.isEmpty) return '';
  return homeAway == HomeAway.away ? '@ $o' : 'vs. $o';
}
