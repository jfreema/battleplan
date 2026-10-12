// The schedule's lists and calendar as providers (SPEC SCHED-1, ARCH
// §5.3): Load more, events that leave the live page, and the calendar's
// window.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_repository.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

const _zone = 'America/Chicago';
const _g = GroupId('a');

/// Events in pages of 2, as Firestore pages them: the first page live,
/// the rest read one at a time after a cursor.
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

  EventPage _page(List<Event> list, int limit) => (
    events: list.take(limit).toList(),
    next: list.length > limit ? PageCursor(list[limit - 1]) : null,
  );

  @override
  Stream<EventPage> watchUpcoming(
    GroupId groupId,
    DateTime from, {
    int limit = 2,
  }) async* {
    yield _page(_upcoming(from), limit);
    await for (final _ in _pages.stream) {
      yield _page(_upcoming(from), limit);
    }
  }

  @override
  Future<EventPage> loadMore(
    GroupId groupId,
    PageCursor cursor, {
    required bool past,
    int limit = 2,
  }) async {
    final after = cursor.handle as Event;
    return _page([
      for (final e in _upcoming(DateTime(2000)))
        if (e.startAt.isAfter(after.startAt)) e,
    ], limit);
  }
}

DateTime _today() {
  final w = ZonedTime.wallClock(_zone, DateTime.now());
  return DateTime.utc(w.year, w.month, w.day);
}

Event _event(String id, int days, {int hour = 18}) {
  final start = ZonedTime.instantOf(_zone, addDays(_today(), days), hour * 60);
  return Event(
    id: EventId(id),
    groupId: _g,
    type: EventType.practice,
    title: id,
    startAt: start,
    endAt: start.add(const Duration(minutes: 90)),
    timeZone: _zone,
    createdBy: 'coach',
  );
}

Future<ProviderContainer> _container(EventRepository repo) async {
  final c = ProviderContainer(
    overrides: [eventRepositoryProvider.overrideWithValue(repo)],
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
}
