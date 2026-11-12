// The schedule's lists and calendar as providers (SPEC SCHED-1, SCHED-2,
// ARCH §5.3): Load more, events that leave the live page, the calendar's
// window, the day turning over, and Your schedule's merge of my teams.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/groups/application/providers.dart'
    show myTeamsProvider;
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_repository.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

const _zone = 'America/Chicago';
const _g = GroupId('a');
const _b = GroupId('b');

/// An archived team.
const _old = GroupId('c');

/// Upcoming that answers only once [open] completes, after the past page
/// has: a cached query ahead of one from the network.
class _SlowUpcoming extends FakeEventRepository {
  new(super.events);

  final open = Completer<void>();

  @override
  Stream<EventPage> watchUpcoming(
    GroupId groupId,
    DateTime from, {
    int limit = 50,
  }) async* {
    await open.future;
    yield* super.watchUpcoming(groupId, from, limit: limit);
  }
}

/// The time the app thinks it is, set by the test.
class _Clock extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  DateTime get now => state;
  set now(DateTime now) => state = now;
}

final _clock = NotifierProvider<_Clock, DateTime>(_Clock.new);

/// Me on Thunder, Lightning, and an archived team.
final List<MyTeam> _myTeams = [
  for (final (id, name, archived) in [
    (_g, 'Thunder', false),
    (_b, 'Lightning', false),
    (_old, 'Spring Storm', true),
  ])
    MyTeam(
      group: testGroup(
        id.value,
        name,
      ).copyWith(archivedAt: archived ? DateTime.utc(2026, 6) : null),
      membership: testMembership(id.value, 'coach'),
    ),
];

/// Events in pages of 2, whatever size is asked for, as Firestore pages
/// them: the first page live, the rest read one at a time after a cursor.
class _PagedEvents extends FakeEventRepository {
  new(super.events);

  final _pages = StreamController<void>.broadcast();

  @override
  void put(Event e) {
    super.put(e);
    _pages.add(null);
  }

  Future<void> remove(String id) async {
    await deleteEvent(events[id]!);
    _pages.add(null);
  }

  List<Event> _upcoming(DateTime from) => [
    for (final e in events.values)
      if (!e.startAt.isBefore(from)) e,
  ]..sort((a, b) => a.startAt.compareTo(b.startAt));

  static const _size = 2;

  EventPage _page(List<Event> list) => (
    events: list.take(_size).toList(),
    next: list.length > _size ? PageCursor(list[_size - 1]) : null,
  );

  @override
  Stream<EventPage> watchUpcoming(
    GroupId groupId,
    DateTime from, {
    int limit = 50,
  }) async* {
    yield _page(_upcoming(from));
    await for (final _ in _pages.stream) {
      yield _page(_upcoming(from));
    }
  }

  @override
  Future<EventPage> loadMore(
    GroupId groupId,
    PageCursor cursor, {
    required bool past,
    int limit = 50,
  }) async {
    final after = cursor.handle as Event;
    return _page([
      for (final e in _upcoming(DateTime(2000)))
        if (e.startAt.isAfter(after.startAt)) e,
    ]);
  }
}

DateTime _today() {
  final w = ZonedTime.wallClock(_zone, DateTime.now());
  return DateTime.utc(w.year, w.month, w.day);
}

Event _event(String id, int days, {int hour = 18, GroupId groupId = _g}) {
  final start = ZonedTime.instantOf(_zone, addDays(_today(), days), hour * 60);
  return Event(
    id: EventId(id),
    groupId: groupId,
    type: EventType.practice,
    title: id,
    startAt: start,
    endAt: start.add(const Duration(minutes: 90)),
    timeZone: _zone,
    createdBy: 'coach',
  );
}

/// An all-day event from [first] to [last], days from today.
Event _allDay(String id, int first, int last, {GroupId groupId = _g}) =>
    _event(id, first, hour: 0, groupId: groupId).copyWith(
      allDay: true,
      startDate: dateKey(addDays(_today(), first)),
      endDate: dateKey(addDays(_today(), last)),
      endAt: ZonedTime.instantOf(_zone, addDays(_today(), last + 1), 0),
    );

Future<ProviderContainer> _container(
  EventRepository repo, {
  List<Override> overrides = const [],
}) async {
  final c = ProviderContainer(
    overrides: [eventRepositoryProvider.overrideWithValue(repo), ...overrides],
  );
  addTearDown(c.dispose);
  await c.read(viewerTimeZoneProvider.future);
  return c;
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  // The device's time zone is asked again on each return to the app.
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Load more (ARCH §5.3)', () {
    List<String> ids(ProviderContainer c) => [
      for (final e in c.read(teamEventsProvider(_g, past: false)).events)
        e.id.value,
    ];

    test('events deleted from the live page go, even after Load more; '
        'ones that slid past it stay', () async {
      final repo = _PagedEvents([
        for (var i = 1; i <= 5; i++) _event('e$i', i),
      ]);
      final c = await _container(repo);
      c.listen(teamEventsProvider(_g, past: false), (_, _) {});
      await _settle();
      expect(ids(c), ['e1', 'e2']);
      await c.read(teamEventsProvider(_g, past: false).notifier).loadMore();
      expect(ids(c), ['e1', 'e2', 'e3', 'e4']);

      await repo.remove('e1');
      await _settle();
      expect(ids(c), ['e2', 'e3', 'e4']);

      // A new event pushes e3 out of the live page; it's still there.
      repo.put(_event('e0', 1, hour: 8));
      await _settle();
      expect(ids(c), ['e0', 'e2', 'e3', 'e4']);

      // Moved to last week, it leaves Upcoming.
      repo.put(_event('e2', -7));
      await _settle();
      expect(ids(c), ['e0', 'e3', 'e4']);
    });

    test('Load more stays gone once the end is reached', () async {
      final repo = _PagedEvents([
        for (var i = 1; i <= 3; i++) _event('e$i', i),
      ]);
      final c = await _container(repo);
      c.listen(teamEventsProvider(_g, past: false), (_, _) {});
      await _settle();
      expect(c.read(teamEventsProvider(_g, past: false)).reachedEnd, isFalse);
      await c.read(teamEventsProvider(_g, past: false).notifier).loadMore();
      expect(c.read(teamEventsProvider(_g, past: false)).reachedEnd, isTrue);
      expect(ids(c), ['e1', 'e2', 'e3']);

      // An answer recounts e1, and the live page comes again.
      repo.put(
        repo.events['e1']!.copyWith(rsvpCounts: const RsvpCounts(going: 1)),
      );
      await _settle();
      expect(c.read(teamEventsProvider(_g, past: false)).reachedEnd, isTrue);
    });
  });

  test('the calendar reads every cell of the grid and the all-day events '
      'that began before it (SCHED-1)', () async {
    DateTime at(int month, int day, [int hour = 18]) =>
        ZonedTime.instantOf(_zone, DateTime.utc(2026, month, day), hour * 60);
    Event timed(String id, DateTime start) => Event(
      id: EventId(id),
      groupId: _g,
      type: EventType.practice,
      title: id,
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      timeZone: _zone,
      createdBy: 'coach',
    );
    // October 2026 starts on a Thursday: the grid runs Sep 27 to Nov 7.
    final repo = FakeEventRepository([
      timed('sep28', at(9, 28)),
      timed('nov6', at(11, 6)),
      timed('aug', at(8, 20)),
      timed('dec', at(12, 1)),
      timed('tournament', at(9, 18, 0)).copyWith(
        allDay: true,
        startDate: '2026-09-18',
        endDate: '2026-10-03',
        endAt: at(10, 4, 0),
      ),
      timed('camp', at(9, 1, 0)).copyWith(
        allDay: true,
        startDate: '2026-09-01',
        endDate: '2026-09-05',
        endAt: at(9, 6, 0),
      ),
    ]);
    final c = await _container(repo);
    final month = DateTime.utc(2026, 10);
    c.listen(monthEventsProvider(_g, month), (_, _) {});
    await _settle();
    final shown = {
      for (final e in c.read(monthEventsProvider(_g, month)).value!) e.id.value,
    };
    expect(shown, containsAll(['sep28', 'nov6', 'tournament']));
    expect(shown, isNot(contains('aug')));
    expect(shown, isNot(contains('dec')));
    expect(shown, isNot(contains('camp')));
  });

  test('the list waits for its own page: all-day events found among the '
      "past ones don't end the loading early", () async {
    // A tournament since yesterday, read with the past page, which
    // answers first; Upcoming's own page is still on its way.
    final repo = _SlowUpcoming([_allDay('tournament', -1, 1), _event('e1', 1)]);
    final c = await _container(repo);
    final list = teamEventsProvider(_g, past: false);
    c.listen(list, (_, _) {});
    await _settle();
    expect(c.read(list).loading, isTrue);
    expect(c.read(list).events, isEmpty);
    repo.open.complete();
    await _settle();
    expect(c.read(list).loading, isFalse);
    expect(c.read(list).reachedEnd, isTrue);
    expect(
      [for (final e in c.read(list).events) e.id.value],
      ['tournament', 'e1'],
    );
  });

  test('when the day turns over, Upcoming starts from the new day', () async {
    final soon = DateTime.now().add(const Duration(minutes: 1));
    final repo = FakeEventRepository([
      _event(
        'tonight',
        0,
      ).copyWith(startAt: soon, endAt: soon.add(const Duration(hours: 1))),
      _event('later', 5),
    ]);
    final c = await _container(
      repo,
      overrides: [minuteClockProvider.overrideWith((ref) => ref.watch(_clock))],
    );
    List<String> ids({required bool past}) => [
      for (final e in c.read(teamEventsProvider(_g, past: past)).events)
        e.id.value,
    ];
    c
      ..listen(teamEventsProvider(_g, past: false), (_, _) {})
      ..listen(teamEventsProvider(_g, past: true), (_, _) {});
    await _settle();
    expect(ids(past: false), ['tonight', 'later']);
    expect(ids(past: true), isEmpty);
    // The same day, a minute on: nothing starts over.
    final first = c.read(viewerTodayProvider);
    c.read(_clock.notifier).now = soon;
    await _settle();
    expect(c.read(viewerTodayProvider), first);
    // Two days on (left open over a weekend).
    c.read(_clock.notifier).now = soon.add(const Duration(days: 2));
    await _settle();
    expect(c.read(viewerTodayProvider), isNot(first));
    expect(ids(past: false), ['later']);
    expect(ids(past: true), ['tonight']);
  });

  group('Your schedule (SCHED-2)', () {
    final mine = myTeamsProvider.overrideWithValue(AsyncData(_myTeams));

    test(
      "merges my active teams' events, soonest first, with a "
      "tournament that's still running; archived teams are left out",
      () async {
        final repo = FakeEventRepository([
          _event('a2', 2),
          _event('a-old', -3),
          _event('b1', 1, groupId: _b),
          _event('b-old', -2, groupId: _b),
          _allDay('tournament', -1, 1, groupId: _b),
          _event('c1', 1, groupId: _old),
          _event('c-old', -1, groupId: _old),
        ]);
        final c = await _container(repo, overrides: [mine]);
        expect(
          [for (final g in c.read(yourScheduleTeamsProvider)) g.id],
          [_g, _b],
        );
        // As Teams reads it: ten of each team.
        final next = yourScheduleEventsProvider(
          past: false,
          limit: yourScheduleLive,
        );
        final past = yourScheduleEventsProvider(past: true);
        c
          ..listen(next, (_, _) {})
          ..listen(past, (_, _) {});
        await _settle();
        expect(
          [for (final e in c.read(next).events) e.id.value],
          ['tournament', 'b1', 'a2'],
        );
        expect(c.read(next).loading, isFalse);
        expect(c.read(next).reachedEnd, isTrue);
        // Past: newest first.
        expect(
          [for (final e in c.read(past).events) e.id.value],
          ['b-old', 'a-old'],
        );
      },
    );

    test('is loading until every team has answered', () async {
      final repo = _SlowUpcoming([
        _event('a1', 1),
        _event('b1', 2, groupId: _b),
      ]);
      final c = await _container(repo, overrides: [mine]);
      final next = yourScheduleEventsProvider(past: false);
      c.listen(next, (_, _) {});
      await _settle();
      expect(c.read(next).loading, isTrue);
      repo.open.complete();
      await _settle();
      expect(c.read(next).loading, isFalse);
      expect(c.read(next).events, hasLength(2));
    });

    test(
      'with no team there is nothing to load, and nothing more to',
      () async {
        final c = await _container(
          FakeEventRepository(),
          overrides: [myTeamsProvider.overrideWithValue(const AsyncData([]))],
        );
        final next = yourScheduleEventsProvider(past: false);
        c.listen(next, (_, _) {});
        await _settle();
        expect(c.read(next).events, isEmpty);
        expect(c.read(next).loading, isFalse);
        expect(c.read(next).reachedEnd, isTrue);
      },
    );

    test("its calendar has a month of every active team's events", () async {
      Event on(String id, int day, GroupId groupId) {
        final start = ZonedTime.instantOf(
          _zone,
          DateTime.utc(2026, 10, day),
          18 * 60,
        );
        return _event(
          id,
          0,
          groupId: groupId,
        ).copyWith(startAt: start, endAt: start.add(const Duration(hours: 1)));
      }

      final repo = FakeEventRepository([
        on('a', 10, _g),
        on('b', 12, _b),
        on('c', 14, _old),
      ]);
      final c = await _container(repo, overrides: [mine]);
      final month = yourScheduleMonthEventsProvider(DateTime.utc(2026, 10));
      c.listen(month, (_, _) {});
      await _settle();
      expect([for (final e in c.read(month).value!) e.id.value], ['a', 'b']);
    });
  });
}
