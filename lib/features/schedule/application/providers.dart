import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
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

/// A repeating series, live, for "Repeats weekly…" (SCHED-4).
@riverpod
Stream<EventSeries?> eventSeries(Ref ref, String seriesId) =>
    ref.watch(eventRepositoryProvider).watchSeries(seriesId);

/// Everyone's answers on an event, live (SCHED-4).
@riverpod
Stream<List<Rsvp>> eventRsvps(Ref ref, GroupId groupId, EventId eventId) =>
    ref.watch(rsvpRepositoryProvider).watchForEvent(groupId, eventId);

/// The people the signed-in person answers for on a team (PLAYER-6):
/// themselves, or on youth teams their players (and themselves when an
/// admin, Q14).
@riverpod
List<Participant> myParticipants(Ref ref, GroupId groupId) {
  final group = ref.watch(groupProvider(groupId)).value;
  final me = ref.watch(myMembershipProvider(groupId));
  if (group == null || me == null) return const [];
  if (group.teamType != TeamType.youth) {
    return participantsFor(group: group, me: me);
  }
  return participantsFor(
    group: group,
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
/// first): the first 50 live, then pages of 50 (ARCH §5.3).
@riverpod
class TeamEvents extends _$TeamEvents {
  final Map<String, Event> _known = {};
  Set<String> _liveIds = {};
  PageCursor? _liveCursor;
  PageCursor? _moreCursor;
  bool _loadedMore = false;

  @override
  EventListState build(GroupId groupId, {required bool past}) {
    final zone = ref.watch(viewerTimeZoneProvider).value;
    if (zone == null) return const EventListState();
    final today = startOfDay(zone, DateTime.now());
    final repo = ref.watch(eventRepositoryProvider);
    final stream = past
        ? repo.watchPast(groupId, today)
        : repo.watchUpcoming(groupId, today);
    final sub = stream.listen((page) {
      final ids = {for (final e in page.events) e.id.value};
      // Deleted events leave the live page; ones that slid out as others
      // arrived stay only if a later page has them.
      for (final gone in _liveIds.difference(ids)) {
        if (!_loadedMore) _known.remove(gone);
      }
      _liveIds = ids;
      for (final e in page.events) {
        _known[e.id.value] = e;
      }
      _liveCursor = page.next;
      _publish(reachedEnd: !_loadedMore && page.next == null);
    }, onError: (Object _) => state = state.copyWith(loading: false));
    ref.onDispose(() => unawaited(sub.cancel()));
    return const EventListState();
  }

  void _publish({bool? loadingMore, bool? reachedEnd}) {
    final sorted = _known.values.toList()
      ..sort(
        (a, b) => past
            ? b.startAt.compareTo(a.startAt)
            : a.startAt.compareTo(b.startAt),
      );
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
  final all = [for (final l in lists) ...l.events]
    ..sort(
      (a, b) => past
          ? b.startAt.compareTo(a.startAt)
          : a.startAt.compareTo(b.startAt),
    );
  DateTime? cut;
  for (final l in lists) {
    if (l.reachedEnd || l.events.isEmpty) continue;
    final last = l.events.last.startAt;
    if (cut == null || (past ? last.isAfter(cut) : last.isBefore(cut))) {
      cut = last;
    }
  }
  return EventListState(
    events: cut == null
        ? all
        : [
            for (final e in all)
              if (past ? !e.startAt.isBefore(cut) : !e.startAt.isAfter(cut)) e,
          ],
    loading: lists.any((l) => l.loading),
    loadingMore: lists.any((l) => l.loadingMore),
    reachedEnd: lists.every((l) => l.reachedEnd),
  );
}

/// A month of one team's events for the calendar (SCHED-1). [month] is
/// any day in it (date-only); the month runs midnight to midnight in the
/// viewer's zone.
@riverpod
Stream<List<Event>> monthEvents(Ref ref, GroupId groupId, DateTime month) {
  final zone = ref.watch(viewerTimeZoneProvider).value;
  if (zone == null) return const Stream.empty();
  // A day either side, so all-day events, dated in their own zone, aren't
  // missed at the month's edges.
  final from = ZonedTime.instantOf(
    zone,
    DateTime.utc(month.year, month.month, 0),
    0,
  );
  final until = ZonedTime.instantOf(
    zone,
    DateTime.utc(month.year, month.month + 1, 2),
    0,
  );
  return ref.watch(eventRepositoryProvider).watchRange(groupId, from, until);
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
Uri eventLink(Ref ref, GroupId groupId, EventId eventId) {
  final base = ref.watch(appWebBaseProvider);
  return base.replace(
    path: '${base.path}/g/${groupId.value}/schedule/e/${eventId.value}',
  );
}
