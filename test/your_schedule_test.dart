// Your schedule (SPEC SCHED-2): what's next across every team on Teams,
// and the whole of it behind See all at /teams/schedule. A team's own
// schedule, which no longer merges them, is in schedule_test.dart.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_repository.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/features/schedule/presentation/schedule_screen.dart';
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
import 'package:battleplan/features/schedule/presentation/your_schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// Counts who is listening to a team's events, and how many each asked
/// for (ARCH §10.2).
class _CountingEvents extends FakeEventRepository {
  new(super.events);

  /// Each list asked for, as "upcoming a 10".
  final List<String> asked = [];

  /// The lists being listened to now.
  int live = 0;

  Stream<T> _counted<T>(Stream<T> source) {
    late final StreamController<T> out;
    StreamSubscription<T>? sub;
    out = StreamController<T>(
      onListen: () {
        live++;
        sub = source.listen(out.add, onError: out.addError);
      },
      onCancel: () {
        live--;
        return sub?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Stream<EventPage> watchUpcoming(
    GroupId groupId,
    DateTime from, {
    int limit = 50,
  }) {
    asked.add('upcoming ${groupId.value} $limit');
    return _counted(super.watchUpcoming(groupId, from, limit: limit));
  }

  @override
  Stream<EventPage> watchPast(
    GroupId groupId,
    DateTime before, {
    int limit = 50,
  }) {
    asked.add('past ${groupId.value} $limit');
    return _counted(super.watchPast(groupId, before, limit: limit));
  }

  @override
  Stream<List<Event>> watchRange(
    GroupId groupId,
    DateTime from,
    DateTime until,
  ) {
    asked.add('range ${groupId.value}');
    return _counted(super.watchRange(groupId, from, until));
  }
}

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const zone = 'America/Chicago';

  /// Today in the teams' zone.
  DateTime today() {
    final w = ZonedTime.wallClock(zone, DateTime.now());
    return DateTime.utc(w.year, w.month, w.day);
  }

  /// An event [days] from today at [hour] in Chicago, 90 minutes long.
  Event event(
    String id, {
    int days = 1,
    int hour = 18,
    String title = 'Practice',
    EventType type = EventType.practice,
    String groupId = 'a',
  }) {
    final start = ZonedTime.instantOf(zone, addDays(today(), days), hour * 60);
    return Event(
      id: EventId(id),
      groupId: GroupId(groupId),
      type: type,
      title: title,
      startAt: start,
      endAt: start.add(const Duration(minutes: 90)),
      timeZone: zone,
      createdBy: 'coach',
      location: const EventLocation(
        name: 'Riverside Park',
        address: '100 River Rd',
      ),
    );
  }

  /// [e] moved to start [from] now (negative: already under way or over),
  /// so it's on today's date whatever the time zones.
  Event now(Event e, {Duration from = Duration.zero}) {
    final start = DateTime.now().add(from);
    return e.copyWith(
      startAt: start,
      endAt: start.add(const Duration(minutes: 1)),
    );
  }

  final thunder = testGroup('a', 'Thunder');
  final lightning = testGroup('b', 'Lightning U10');

  /// Emma, on Lightning, whose guardian is the coach.
  FakePlayerRepository emma() =>
      FakePlayerRepository(const [
          Player(
            id: PlayerId('p1'),
            groupId: GroupId('b'),
            displayName: 'Emma Rivera',
          ),
        ])
        ..links.add(
          const GuardianLink(
            playerId: PlayerId('p1'),
            groupId: GroupId('b'),
            uid: UserId('coach'),
          ),
        );

  /// The app on Teams, as the coach, a member of every team in [groups].
  Future<FakeRsvpRepository> openTeams(
    WidgetTester tester, {
    required Map<String, Group> groups,
    List<Event> events = const [],
    FakeEventRepository? eventRepo,
    FakePlayerRepository? players,
  }) async {
    final rsvps = FakeRsvpRepository(eventRepo ?? FakeEventRepository(events));
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      prefs: FakeLocalPrefs()..lastTeamRoute = '/teams',
      groups: groups,
      memberships: [
        for (final id in groups.keys)
          testMembership(id, 'coach', name: 'Coach Lee'),
      ],
      rsvpRepo: rsvps,
      playerRepo: players,
    );
    return rsvps;
  }

  Future<void> seeAll(WidgetTester tester) async {
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
  }

  /// Where the router is, pushed screens included.
  String location(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Navigator).first)).state.uri
          .toString();

  double top(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  /// The answer [label] on the card of the event titled [title].
  Finder answer(String title, String label) => find.descendant(
    of: find.ancestor(
      of: find.text(title),
      matching: find.byType(ScheduleEventRow),
    ),
    matching: find.descendant(
      of: find.byType(RsvpChoice),
      matching: find.text(label),
    ),
  );

  group('on Teams', () {
    testWidgets("Your schedule is under my teams: what's next across every "
        'team, soonest first, naming the team and my player (SCHED-2, '
        'PLAYER-9)', (tester) async {
      final semantics = tester.ensureSemantics();
      await openTeams(
        tester,
        groups: {'a': thunder, 'b': lightning},
        players: emma(),
        events: [
          event('b1', days: 2, title: 'Lightning game', groupId: 'b'),
          event('a1', title: 'Thunder practice'),
        ],
      );
      expect(location(tester), '/teams');
      expect(
        tester.getSemantics(find.text('Your schedule')),
        isSemantics(isHeader: true),
      );
      // Under both team cards, over Join and Create.
      final heading = top(tester, find.text('Your schedule'));
      expect(heading, greaterThan(top(tester, find.text('Thunder').first)));
      expect(heading, greaterThan(top(tester, find.text('Lightning U10'))));
      expect(heading, lessThan(top(tester, find.text('Join a Team or Group'))));
      // Soonest first, between the heading and See all.
      final first = top(tester, find.text('Thunder practice'));
      final second = top(tester, find.text('Lightning game'));
      expect(first, greaterThan(heading));
      expect(second, greaterThan(first));
      expect(top(tester, find.text('See all')), greaterThan(second));
      expect(
        top(tester, find.text('See all')),
        lessThan(top(tester, find.text('Join a Team or Group'))),
      );
      // Each names its team: Thunder's card and its event's label, and
      // Lightning's with the player I'm there for.
      expect(find.text('Thunder'), findsNWidgets(2));
      expect(find.text('Lightning U10 · For Emma'), findsOneWidget);
      // The cards line up with the team cards.
      final card = tester.getRect(
        find
            .ancestor(
              of: find.text('Thunder practice'),
              matching: find.byType(TapCard),
            )
            .first,
      );
      expect(card.left, 16);
      expect(card.right, 400 - 16);
      // See all says what of, to a screen reader.
      expect(
        tester.getSemantics(find.text('See all')),
        isSemantics(
          label: 'See all of your schedule',
          isButton: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('only the next five show, and See all opens the whole '
        'schedule', (tester) async {
      final semantics = tester.ensureSemantics();
      await openTeams(
        tester,
        groups: {'a': thunder, 'b': lightning},
        events: [
          for (var i = 1; i <= 7; i++)
            event(
              'e$i',
              days: i,
              title: 'Event $i',
              groupId: i.isEven ? 'b' : 'a',
            ),
        ],
      );
      for (var i = 1; i <= 5; i++) {
        expect(find.text('Event $i'), findsOneWidget);
      }
      expect(find.text('Event 6'), findsNothing);
      expect(find.text('Event 7'), findsNothing);
      expect(find.byType(ScheduleEventRow), findsNWidgets(5));

      await seeAll(tester);
      expect(location(tester), '/teams/schedule');
      expect(find.byType(YourScheduleScreen), findsOneWidget);
      for (var i = 1; i <= 7; i++) {
        expect(find.text('Event $i'), findsOneWidget);
      }
      // Each names its team, and nothing more is left to load.
      expect(find.text('Thunder'), findsNWidgets(4));
      expect(find.text('Lightning U10'), findsNWidgets(3));
      expect(find.text('Load more'), findsNothing);
      // No +: events are made in a team.
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.bySemanticsLabel('Back, Teams'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(location(tester), '/teams');
      expect(find.byType(TopLevelBar), findsOneWidget);
      semantics.dispose();
    });

    testWidgets("Going on a card answers that team's event, for my player "
        'or for me, and stays on Teams (SCHED-4)', (tester) async {
      final rsvps = await openTeams(
        tester,
        groups: {
          'b': lightning,
          // A basic group: everyone answers for themselves (TEAM-14).
          'p': testGroup(
            'p',
            'Thunder Parents',
          ).copyWith(kind: GroupKind.group),
        },
        players: emma(),
        events: [
          event('b1', title: 'Lightning game', groupId: 'b'),
          event('p1', days: 2, title: 'Fall party', groupId: 'p'),
        ],
      );
      await tester.tap(answer('Lightning game', 'Going'));
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.eventId, const EventId('b1'));
      expect(rsvps.rsvps.single.groupId, const GroupId('b'));
      expect(rsvps.rsvps.single.participantId, 'p1');
      expect(rsvps.rsvps.single.status, RsvpStatus.going);
      // The card counts it, as on the schedule.
      expect(find.text('1/1 going', findRichText: true), findsOneWidget);

      await tester.tap(answer('Fall party', 'Not going'));
      await tester.pumpAndSettle();
      final mine = rsvps.rsvps.singleWhere((r) => r.groupId.value == 'p');
      expect(mine.eventId, const EventId('p1'));
      expect(mine.participantId, 'coach');
      expect(mine.status, RsvpStatus.notGoing);
      expect(rsvps.rsvps, hasLength(2));
      expect(location(tester), '/teams');

      // The chosen one again clears it.
      await tester.tap(answer('Lightning game', 'Going'));
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.groupId, const GroupId('p'));
      // Teams read my answers on the events shown, and no further.
      final last = rsvps.events.events['p1']!.startAt;
      expect(rsvps.windows, isNotEmpty);
      for (final w in rsvps.windows) {
        expect(w.from, rsvps.events.events['b1']!.startAt);
        expect(w.until, last.add(const Duration(milliseconds: 1)));
      }
    });

    testWidgets('a card opens the event in its own team, and Back comes '
        'back', (tester) async {
      final semantics = tester.ensureSemantics();
      await openTeams(
        tester,
        groups: {'a': thunder, 'b': lightning},
        events: [
          event('a1', title: 'Thunder practice'),
          event('b1', days: 2, title: 'Lightning game', groupId: 'b'),
        ],
      );
      await tester.tap(find.text('Lightning game'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/b/schedule/e/b1');
      expect(find.text('100 River Rd'), findsOneWidget);
      expect(find.bySemanticsLabel('Back, Teams'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(location(tester), '/teams');
      expect(find.byType(TopLevelBar), findsOneWidget);

      // From the page, back to the page.
      await seeAll(tester);
      await tester.tap(find.text('Lightning game'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/b/schedule/e/b1');
      expect(find.bySemanticsLabel('Back, Your schedule'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(location(tester), '/teams/schedule');
      semantics.dispose();
    });

    testWidgets('with nothing coming up it says so, and See all still has '
        'the past', (tester) async {
      await openTeams(
        tester,
        groups: {'a': thunder, 'b': lightning},
        events: [
          event('a1', days: -3, title: 'Thunder practice'),
          event('b1', days: -2, title: 'Lightning game', groupId: 'b'),
        ],
      );
      expect(find.text('Your schedule'), findsOneWidget);
      expect(find.text('No upcoming events.'), findsOneWidget);
      expect(find.byType(ScheduleEventRow), findsNothing);
      await seeAll(tester);
      expect(find.text('No upcoming events.'), findsOneWidget);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      // Newest first.
      expect(
        top(tester, find.text('Lightning game')),
        lessThan(top(tester, find.text('Thunder practice'))),
      );
    });

    testWidgets("an event that's over isn't what's next: it's left to the "
        'page', (tester) async {
      await openTeams(
        tester,
        groups: {'a': thunder},
        events: [
          now(
            event('a0', title: 'Morning game'),
            from: const Duration(minutes: -5),
          ),
          // Under way: still on Teams.
          now(event('a1', title: 'Scrimmage'))
              .copyWith(endAt: DateTime.now().add(const Duration(hours: 1))),
          event('a2', title: 'Thunder practice'),
        ],
      );
      expect(find.text('Morning game'), findsNothing);
      expect(find.text('Scrimmage'), findsOneWidget);
      expect(find.text('Thunder practice'), findsOneWidget);
      // The page's Upcoming runs from the start of today, as a team's
      // does (Past, in the minutes after midnight).
      await seeAll(tester);
      if (find.text('Morning game').evaluate().isEmpty) {
        await tester.tap(find.text('Past'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Morning game'), findsOneWidget);
    });

    testWidgets('no teams, no Your schedule; nor with only archived ones', (
      tester,
    ) async {
      await pumpApp(tester, auth: FakeAuthRepository(user: coach));
      expect(find.text('Welcome to Battleplan'), findsOneWidget);
      expect(find.text('Join a Team or Group'), findsOneWidget);
      expect(find.text('Your schedule'), findsNothing);
      expect(find.text('See all'), findsNothing);

      await openTeams(
        tester,
        groups: {'a': thunder.copyWith(archivedAt: DateTime.utc(2026, 6))},
        events: [event('a1', title: 'Alumni game')],
      );
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('Your schedule'), findsNothing);
      expect(find.text('See all'), findsNothing);
    });

    testWidgets('archived teams are left out, on Teams and behind See all', (
      tester,
    ) async {
      await openTeams(
        tester,
        groups: {
          'a': thunder,
          'c': testGroup(
            'c',
            'Spring Storm',
          ).copyWith(archivedAt: DateTime.utc(2026, 6)),
        },
        events: [
          now(event('a0', title: 'Thunder scrimmage')),
          event('a1', title: 'Thunder practice'),
          now(event('c0', title: 'Storm scrimmage', groupId: 'c')),
          event('c1', title: 'Alumni game', groupId: 'c'),
          event('c2', days: -2, title: 'Storm final', groupId: 'c'),
        ],
      );
      expect(find.text('Thunder practice'), findsOneWidget);
      expect(find.text('Alumni game'), findsNothing);
      await seeAll(tester);
      expect(find.text('Thunder practice'), findsOneWidget);
      expect(find.text('Alumni game'), findsNothing);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Storm final'), findsNothing);
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dot-a0')), findsOneWidget);
      expect(find.byKey(const ValueKey('dot-c0')), findsNothing);
    });

    testWidgets("someone on one team still gets it: it's their what's next", (
      tester,
    ) async {
      await openTeams(
        tester,
        groups: {'a': thunder},
        events: [event('a1', title: 'Thunder practice')],
      );
      expect(find.text('Your schedule'), findsOneWidget);
      expect(find.text('Thunder practice'), findsOneWidget);
      // The team's card, and the event's label.
      expect(find.text('Thunder'), findsNWidgets(2));
      expect(find.text('See all'), findsOneWidget);
    });

    testWidgets("a team's type filter doesn't hide events on Teams; See "
        'all keeps it, and shows that it is on', (tester) async {
      await openTeams(
        tester,
        groups: {'a': thunder},
        events: [
          event('g', title: 'vs. Eagles', type: EventType.game),
          event('p', days: 2),
        ],
      );
      // In Thunder: Games only.
      await tester.tap(find.text('Thunder').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Games'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ModalBarrier).last);
      await tester.pumpAndSettle();
      expect(find.text('Practice'), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(location(tester), '/teams');
      expect(find.text('vs. Eagles'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);

      await seeAll(tester);
      expect(find.text('vs. Eagles'), findsOneWidget);
      expect(find.text('Practice'), findsNothing);
      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byTooltip('Filter')),
        isSemantics(value: 'On', isButton: true, hasTapAction: true),
      );
      semantics.dispose();
      // Off again from here.
      await tester.tap(find.byTooltip('Filter'));
      await tester.pumpAndSettle();
      expect(find.text('All my teams'), findsNothing);
      await tester.tap(find.widgetWithText(FilterChip, 'Games'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ModalBarrier).last);
      await tester.pumpAndSettle();
      expect(find.text('Practice'), findsOneWidget);
    });

    testWidgets("the cards wait for who I answer for, so they don't grow "
        'their RSVP rows after they show', (tester) async {
      final held = StreamController<List<Player>>();
      addTearDown(held.close);
      final players = emma()..playersStream = held.stream;
      await openTeams(
        tester,
        groups: {'b': lightning},
        players: players,
        events: [event('b1', title: 'Lightning game', groupId: 'b')],
      );
      // The heading and See all hold the place; no card, and no "No
      // upcoming events." either.
      expect(find.text('Your schedule'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
      expect(find.text('Lightning game'), findsNothing);
      expect(find.text('No upcoming events.'), findsNothing);
      held.add(players.players);
      await tester.pumpAndSettle();
      expect(find.text('Lightning game'), findsOneWidget);
      expect(answer('Lightning game', 'Going'), findsOneWidget);
    });
  });

  group('See all, at /teams/schedule', () {
    testWidgets('has Past and Calendar across teams, each event naming its '
        'team', (tester) async {
      await openTeams(
        tester,
        groups: {'a': thunder, 'b': lightning},
        players: emma(),
        events: [
          event('a9', days: -2, title: 'Old Thunder game'),
          event('b9', days: -1, title: 'Old Lightning game', groupId: 'b'),
          now(event('a0', title: 'Thunder scrimmage')),
          now(event('b0', title: 'Lightning scrimmage', groupId: 'b')),
        ],
      );
      await seeAll(tester);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      // Newest first, with their teams.
      expect(
        top(tester, find.text('Old Lightning game')),
        lessThan(top(tester, find.text('Old Thunder game'))),
      );
      expect(find.text('Thunder'), findsOneWidget);
      expect(find.text('Lightning U10 · For Emma'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      // Today is picked: a dot for each team's event, and their cards.
      expect(find.byKey(const ValueKey('dot-a0')), findsOneWidget);
      expect(find.byKey(const ValueKey('dot-b0')), findsOneWidget);
      expect(find.text('Thunder scrimmage'), findsOneWidget);
      expect(find.text('Lightning scrimmage'), findsOneWidget);
      expect(find.text('Thunder'), findsOneWidget);
      expect(find.text('Lightning U10 · For Emma'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('opened from a link, its chevron goes up to Teams', (
      tester,
    ) async {
      await openTeams(
        tester,
        groups: {'a': thunder},
        events: [event('a1', title: 'Thunder practice')],
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/teams/schedule');
      await tester.pumpAndSettle();
      expect(find.byType(YourScheduleScreen), findsOneWidget);
      expect(find.text('Thunder practice'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(location(tester), '/teams');
    });
  });

  testWidgets("Teams listens to each active team's next ten, only while "
      "it's showing (ARCH §10.2)", (tester) async {
    final repo = _CountingEvents([
      event('a1', title: 'Thunder practice'),
      event('b1', days: 2, title: 'Lightning game', groupId: 'b'),
      event('c1', days: 3, title: 'Alumni game', groupId: 'c'),
    ]);
    await openTeams(
      tester,
      groups: {
        'a': thunder,
        'b': lightning,
        'c': testGroup(
          'c',
          'Spring Storm',
        ).copyWith(archivedAt: DateTime.utc(2026, 6)),
      },
      eventRepo: repo,
    );
    expect(find.text('Lightning game'), findsOneWidget);
    // Upcoming, and the all-day events still running among the latest
    // past ones: ten of each for each active team, none for the archived.
    expect(
      repo.asked,
      unorderedEquals([
        'upcoming a 10',
        'past a 10',
        'upcoming b 10',
        'past b 10',
      ]),
    );
    expect(repo.live, 4);

    // In a team, nothing of Teams' is left listening.
    await tester.tap(find.text('Thunder').first);
    await tester.pumpAndSettle();
    expect(location(tester), '/g/a/chat');
    expect(repo.live, 0);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(repo.live, 4);
    // See all is a schedule: 50 a page, over Teams' own.
    repo.asked.clear();
    await seeAll(tester);
    expect(
      repo.asked,
      unorderedEquals([
        'upcoming a 50',
        'past a 50',
        'upcoming b 50',
        'past b 50',
      ]),
    );
    expect(repo.live, 8);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(repo.live, 4);
  });
}
