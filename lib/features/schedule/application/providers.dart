import 'dart:async';

import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_repository.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/rsvp_repository.dart';
import 'package:battleplan/features/schedule/domain/schedule_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.freezed.dart';
part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
RsvpRepository rsvpRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// The viewer's own time zone: times show in it (SCHED-9).
@Riverpod(keepAlive: true)
Future<String> viewerTimeZone(Ref ref) =>
    ref.watch(timeZonesProvider).deviceTimeZone();

/// The instant today began in [zone]: Upcoming starts here, Past ends here.
DateTime startOfDay(String zone, DateTime now) {
  final wall = ZonedTime.wallClock(zone, now);
  return ZonedTime.instantOf(zone, wall, 0);
}

/// The day [e] starts on in [zone], as a date-only value; all-day
/// events use their own date, which never shifts (SCHED-9).
DateTime dayOf(Event e, String zone) {
  if (e.allDay && e.startDate != null) return parseDateKey(e.startDate!);
  final w = ZonedTime.wallClock(zone, e.startAt);
  return DateTime.utc(w.year, w.month, w.day);
}

/// One event, live (SCHED-4). Null once it's deleted.
@riverpod
Stream<Event?> event(Ref ref, EventId id) =>
    ref.watch(eventRepositoryProvider).watchEvent(id);

/// A series' next event from now on, live, for its chat card once the
/// card's own event is gone (CHAT-11). Null when none is left.
@riverpod
Stream<Event?> nextSeriesEvent(Ref ref, GroupId groupId, String seriesId) => ref
    .watch(eventRepositoryProvider)
    .watchNextInSeries(groupId, seriesId, DateTime.now());

/// A repeating series, live, for "Repeats weekly…" (SCHED-4).
@riverpod
Stream<EventSeries?> eventSeries(Ref ref, String seriesId) =>
    ref.watch(eventRepositoryProvider).watchSeries(seriesId);

/// Everyone's answers on an event, live (SCHED-4).
@riverpod
Stream<List<Rsvp>> eventRsvps(Ref ref, GroupId groupId, EventId eventId) =>
    ref.watch(rsvpRepositoryProvider).watchForEvent(groupId, eventId);

/// The people the signed-in person answers for on a team (PLAYER-6): the
/// players they're linked to, and themselves when they're an admin or
/// aren't linked to any player ([participantsFor]).
@riverpod
List<Participant> myParticipants(Ref ref, GroupId groupId) {
  final me = ref.watch(myMembershipProvider(groupId));
  if (me == null) return const [];
  return participantsFor(
    me: me,
    players: ref.watch(playersProvider(groupId)).value ?? const [],
    links: ref.watch(guardianLinksProvider(groupId)).value ?? const [],
  );
}

/// My answers (and my players') on a team's events starting in
/// [from, until), by event ID then participant ID (ARCH §6.2 "My RSVPs").
@riverpod
Stream<Map<String, Map<String, Rsvp>>> myRsvps(
  Ref ref,
  GroupId groupId, {
  DateTime? from,
  DateTime? until,
}) {
  final ids = [
    for (final p in ref.watch(myParticipantsProvider(groupId))) p.id,
  ];
  return ref
      .watch(rsvpRepositoryProvider)
      .watchMine(groupId, ids, from: from, until: until)
      .map((list) {
        final byEvent = <String, Map<String, Rsvp>>{};
        for (final r in list) {
          (byEvent[r.eventId.value] ??= {})[r.participantId] = r;
        }
        return byEvent;
      });
}

/// Whether [e] belongs in Upcoming for a viewer in [zone] at [now]: timed
/// events from the start of today; all-day events through their last day,
/// by their own dates, which never shift (SCHED-9). The rest is Past.
bool isUpcoming(Event e, String zone, DateTime now) {
  if (e.allDay && e.startDate != null) {
    final today = dateKey(ZonedTime.wallClock(zone, now));
    return (e.endDate ?? e.startDate!).compareTo(today) >= 0;
  }
  return !e.startAt.isBefore(startOfDay(zone, now));
}

/// Schedule order (SCHED-1): by day in [zone], all-day events by their own
/// dates, all-day ones first within a day, then by start. [past] reverses
/// it, newest first.
int compareEvents(Event a, Event b, String zone, {bool past = false}) {
  var c = dayOf(a, zone).compareTo(dayOf(b, zone));
  if (c == 0 && a.allDay != b.allDay) c = a.allDay ? -1 : 1;
  if (c == 0) c = a.startAt.compareTo(b.startAt);
  return past ? -c : c;
}

/// A schedule list (Upcoming or Past, SCHED-1).
@freezed
abstract class EventListState with _$EventListState {
  const factory({
    /// Upcoming: soonest first. Past: newest first.
    @Default(<Event>[]) List<Event> events,
    @Default(true) bool loading,
    @Default(false) bool loadingMore,

    /// True once there's nothing more to load.
    @Default(false) bool reachedEnd,
  }) = _EventListState;
}

/// One team's Upcoming (from the start of today) or Past (before it, newest
/// first): the first 50 live, then pages of 50 (ARCH §5.3). All-day events
/// go by their dates instead (see [isUpcoming]).
@riverpod
class TeamEvents extends _$TeamEvents {
  final Map<String, Event> _known = {};

  /// All-day events from the other side of the start of today that belong
  /// here, live: in Upcoming, ones still running or dated today or later
  /// that start before it (a tournament since Saturday, or a day dated in
  /// a zone further east); in Past, ones already over that start after it
  /// (dated in a zone far to the west).
  Map<String, Event> _edge = {};
  Set<String> _liveIds = {};
  PageCursor? _liveCursor;
  PageCursor? _moreCursor;
  bool _loadedMore = false;

  /// The last event of the latest page loaded.
  Event? _tail;
  String _zone = 'UTC';
  DateTime _now = DateTime.now();

  @override
  EventListState build(GroupId groupId, {required bool past}) {
    final zone = ref.watch(viewerTimeZoneProvider).value;
    if (zone == null) return const EventListState();
    _zone = zone;
    _now = DateTime.now();
    final today = startOfDay(zone, _now);
    final repo = ref.watch(eventRepositoryProvider);
    final stream = past
        ? repo.watchPast(groupId, today)
        : repo.watchUpcoming(groupId, today);
    final edge = past
        // Zones are at most 26 hours apart.
        ? repo.watchRange(groupId, today, today.add(const Duration(days: 2)))
        : repo.watchPast(groupId, today).map((p) => p.events);
    final sub = stream.listen((page) {
      final ids = {for (final e in page.events) e.id.value};
      final gone = _liveIds.difference(ids);
      _liveIds = ids;
      for (final e in page.events) {
        _known[e.id.value] = e;
      }
      _liveCursor = page.next;
      if (_loadedMore) {
        // Deleted and moved events leave the live page, but so do ones
        // that slid past its end as others arrived; ask which.
        if (gone.isNotEmpty) unawaited(_recheck(gone));
      } else {
        gone.forEach(_known.remove);
      }
      _publish(
        reachedEnd: _loadedMore ? _moreCursor == null : page.next == null,
      );
    }, onError: (Object _) => state = state.copyWith(loading: false));
    final edgeSub = edge.listen((events) {
      _edge = {for (final e in events) e.id.value: e};
      _publish();
    }, onError: (Object _) {});
    ref.onDispose(() {
      unawaited(sub.cancel());
      unawaited(edgeSub.cancel());
    });
    return const EventListState();
  }

  bool _belongs(Event e) =>
      e.groupId == groupId && isUpcoming(e, _zone, _now) != past;

  int _compare(Event a, Event b) => compareEvents(a, b, _zone, past: past);

  /// Keeps the events that left the live page only if they still exist,
  /// still belong here, and fall within what's loaded.
  Future<void> _recheck(Set<String> ids) async {
    final repo = ref.read(eventRepositoryProvider);
    for (final id in ids) {
      Event? now;
      try {
        now = await repo.watchEvent(EventId(id)).first;
      } on Object {
        continue;
      }
      if (!ref.mounted) return;
      if (_liveIds.contains(id)) continue;
      final tail = _tail;
      final keep =
          now != null &&
          _belongs(now) &&
          (_moreCursor == null || tail == null || _compare(now, tail) <= 0);
      if (keep) {
        _known[id] = now;
      } else {
        _known.remove(id);
      }
    }
    _publish();
  }

  void _publish({bool? loadingMore, bool? reachedEnd}) {
    final all = {..._known, ..._edge};
    final sorted = [
      for (final e in all.values)
        if (_belongs(e)) e,
    ]..sort(_compare);
    state = state.copyWith(
      events: sorted,
      loading: false,
      loadingMore: loadingMore ?? state.loadingMore,
      reachedEnd: reachedEnd ?? state.reachedEnd,
    );
  }

  /// Loads the next 50.
  Future<void> loadMore() async {
    if (state.loadingMore || state.reachedEnd || state.loading) return;
    final cursor = _loadedMore ? _moreCursor : _liveCursor;
    if (cursor == null) {
      state = state.copyWith(reachedEnd: true);
      return;
    }
    state = state.copyWith(loadingMore: true);
    try {
      final page = await ref
          .read(eventRepositoryProvider)
          .loadMore(groupId, cursor, past: past);
      for (final e in page.events) {
        _known.putIfAbsent(e.id.value, () => e);
      }
      _loadedMore = true;
      _moreCursor = page.next;
      if (page.events.isNotEmpty) _tail = page.events.last;
      _publish(loadingMore: false, reachedEnd: page.next == null);
    } on Object {
      state = state.copyWith(loadingMore: false);
      rethrow;
    }
  }
}

/// The teams "All my teams" merges (SCHED-2): every team I'm on.
@riverpod
List<Group> scheduleTeams(Ref ref) => [
  for (final t in ref.watch(myTeamsProvider).value ?? const <MyTeam>[]) t.group,
];

/// Every team's Upcoming or Past merged (SCHED-2), one query per team.
/// The merged list stops where the team with the least loaded runs out,
/// so loading more never fills in a gap above what's shown.
@riverpod
EventListState allTeamsEvents(Ref ref, {required bool past}) {
  final teams = ref.watch(scheduleTeamsProvider);
  final lists = [
    for (final g in teams) ref.watch(teamEventsProvider(g.id, past: past)),
  ];
  if (lists.isEmpty) {
    return EventListState(loading: ref.watch(myTeamsProvider).isLoading);
  }
  final zone = ref.watch(viewerTimeZoneProvider).value;
  if (zone == null) return const EventListState();
  int compare(Event a, Event b) => compareEvents(a, b, zone, past: past);
  final all = [for (final l in lists) ...l.events]..sort(compare);
  Event? cut;
  for (final l in lists) {
    if (l.reachedEnd || l.events.isEmpty) continue;
    final last = l.events.last;
    if (cut == null || compare(last, cut) < 0) cut = last;
  }
  return EventListState(
    events: cut == null
        ? all
        : [
            for (final e in all)
              if (compare(e, cut) <= 0) e,
          ],
    loading: lists.any((l) => l.loading),
    loadingMore: lists.any((l) => l.loadingMore),
    reachedEnd: lists.every((l) => l.reachedEnd),
  );
}

/// What the calendar reads for [month] (any day in it, date-only): every
/// cell of its grid, which shows days of the months either side whatever
/// the first day of the week, and a day more each way, since all-day
/// events are dated in their own zone (SCHED-1).
({DateTime from, DateTime until, String firstDay}) calendarWindow(
  String zone,
  DateTime month,
) {
  final first = DateTime.utc(month.year, month.month);
  final next = DateTime.utc(month.year, month.month + 1);
  final firstDay = addDays(first, -7);
  return (
    from: ZonedTime.instantOf(zone, firstDay, 0),
    until: ZonedTime.instantOf(zone, addDays(next, 8), 0),
    firstDay: dateKey(firstDay),
  );
}

/// A team's events starting in [from, until), live.
@riverpod
Stream<List<Event>> eventsInRange(
  Ref ref,
  GroupId groupId,
  DateTime from,
  DateTime until,
) => ref.watch(eventRepositoryProvider).watchRange(groupId, from, until);

/// A team's latest 50 events starting before [before], live.
@riverpod
Stream<List<Event>> eventsBefore(Ref ref, GroupId groupId, DateTime before) =>
    ref
        .watch(eventRepositoryProvider)
        .watchPast(groupId, before)
        .map((p) => p.events);

/// A month of one team's events for the calendar (SCHED-1), for every cell
/// of its grid (see [calendarWindow]), with the all-day events that began
/// before and run into it, such as a tournament from the last days of the
/// month before.
@riverpod
AsyncValue<List<Event>> monthEvents(Ref ref, GroupId groupId, DateTime month) {
  final zone = ref.watch(viewerTimeZoneProvider).value;
  if (zone == null) return const AsyncLoading();
  final w = calendarWindow(zone, month);
  final inRange = ref.watch(eventsInRangeProvider(groupId, w.from, w.until));
  final before = ref.watch(eventsBeforeProvider(groupId, w.from));
  if (inRange.hasError) {
    return AsyncError(inRange.error!, inRange.stackTrace ?? StackTrace.current);
  }
  if (!inRange.hasValue || !before.hasValue) return const AsyncLoading();
  return AsyncData(
    [
      for (final e in before.value!)
        if (e.allDay &&
            e.startDate != null &&
            (e.endDate ?? e.startDate!).compareTo(w.firstDay) >= 0)
          e,
      ...inRange.value!,
    ]..sort((a, b) => a.startAt.compareTo(b.startAt)),
  );
}

/// A month of every team's events (SCHED-2 with the calendar).
@riverpod
AsyncValue<List<Event>> allTeamsMonthEvents(Ref ref, DateTime month) {
  final teams = ref.watch(scheduleTeamsProvider);
  final months = [
    for (final g in teams) ref.watch(monthEventsProvider(g.id, month)),
  ];
  if (months.any((m) => !m.hasValue)) return const AsyncLoading();
  return AsyncData(
    [for (final m in months) ...m.value!]
      ..sort((a, b) => a.startAt.compareTo(b.startAt)),
  );
}

/// Which views and filters the schedule shows (SCHED-1, SCHED-2), kept
/// while the app runs.
@freezed
abstract class ScheduleOptions with _$ScheduleOptions {
  const factory({
    @Default(false) bool allTeams,

    /// Empty shows everything.
    @Default(<EventFilter>{}) Set<EventFilter> filters,
  }) = _ScheduleOptions;

  const new _();

  bool shows(Event e) =>
      filters.isEmpty || filters.contains(EventFilter.of(e.type));
}

/// The schedule's toggle and filter (SCHED-2).
@Riverpod(keepAlive: true)
class ScheduleView extends _$ScheduleView {
  @override
  ScheduleOptions build() {
    ref.watch(authUserProvider.select((a) => a.value?.uid));
    return const ScheduleOptions();
  }

  void setAllTeams({required bool on}) => state = state.copyWith(allTeams: on);

  void toggleFilter(EventFilter f) => state = state.copyWith(
    filters: state.filters.contains(f)
        ? ({...state.filters}..remove(f))
        : {...state.filters, f},
  );
}

/// A link to an event in the web app, for Share (SCHED-4).
@riverpod
Uri eventLink(Ref ref, GroupId groupId, EventId eventId) => ref
    .watch(linkServiceProvider)
    .app('/g/${groupId.value}/schedule/e/${eventId.value}');

/// The Schedule tab's badge (SPEC §5.3): events in the next 14 days still
/// waiting for my answer or my players'. Reads the team's events and my
/// answers from the start of this hour for 15 days, one live query each,
/// so the window moves only when they change.
@riverpod
AsyncValue<int> awaitingRsvpCount(Ref ref, GroupId groupId) {
  final now = DateTime.now();
  const hour = Duration.millisecondsPerHour;
  final from = DateTime.fromMillisecondsSinceEpoch(
    now.millisecondsSinceEpoch ~/ hour * hour,
    isUtc: true,
  );
  final until = from.add(awaitingRsvpWindow + const Duration(days: 1));
  final group = ref.watch(groupProvider(groupId)).value;
  final me = ref.watch(myMembershipProvider(groupId));
  if (group == null || me == null) return const AsyncData(0);
  final events = ref.watch(eventsInRangeProvider(groupId, from, until));
  final answers = ref.watch(myRsvpsProvider(groupId, from: from, until: until));
  // Until my answers load, every event would look unanswered.
  if (!answers.hasValue) return const AsyncLoading();
  return events.whenData(
    (list) => countAwaitingRsvp(
      events: list,
      group: group,
      me: me,
      participants: ref.watch(myParticipantsProvider(groupId)),
      answers: answers.requireValue,
      now: now,
    ),
  );
}
