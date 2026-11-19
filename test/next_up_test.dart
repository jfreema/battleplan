// Next up (#43, SPEC CHAT-21, §5.3): the team's next event in two weeks at
// the top of its chat, with Going and Not going while it waits on me, and
// the same line on its card on Teams, with a coral dot and "Needs your
// answer". Both come from nextUpProvider, so they agree with the Schedule.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/presentation/next_up.dart';
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

const _a = GroupId('a');

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const zone = 'America/Chicago';

  /// An event [days] from now at 4:00 PM, an hour long, at Field 3.
  Event event(
    String id,
    int days, {
    String title = 'Practice',
    EventType type = EventType.practice,
    DateTime? canceledAt,
    DateTime? rsvpDeadline,
  }) {
    final day = DateTime.now().add(Duration(days: days));
    final start = DateTime(day.year, day.month, day.day, 16);
    return Event(
      id: EventId(id),
      groupId: _a,
      type: type,
      title: title,
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      timeZone: zone,
      createdBy: 'boss',
      location: const EventLocation(name: 'Field 3'),
      canceledAt: canceledAt,
      rsvpDeadline: rsvpDeadline,
    );
  }

  Player player(String id, String name) =>
      Player(id: PlayerId(id), groupId: _a, displayName: name);
  GuardianLink link(String id) => GuardianLink(
    playerId: PlayerId(id),
    groupId: _a,
    uid: const UserId('coach'),
  );

  /// The coach, a member linked to [players] (Noah alone by default).
  FakePlayerRepository linked([List<Player>? players]) {
    final list = players ?? [player('p1', 'Noah Diaz')];
    return FakePlayerRepository(list)
      ..links.addAll([for (final p in list) link(p.id.value)]);
  }

  Future<FakeRsvpRepository> open(
    WidgetTester tester,
    String path, {
    List<Event> events = const [],
    FakePlayerRepository? players,
    Group? group,
    List<Rsvp> answers = const [],
    Size size = const Size(400, 1000),
  }) async {
    final eventRepo = FakeEventRepository(events);
    final rsvps = FakeRsvpRepository(eventRepo)..rsvps.addAll(answers);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      prefs: FakeLocalPrefs()..pushPrePromptShown = true,
      groups: {'a': group ?? testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach')],
      eventRepo: eventRepo,
      rsvpRepo: rsvps,
      playerRepo: players ?? linked(),
      size: size,
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
    return rsvps;
  }

  Finder pill(String label) =>
      find.descendant(of: find.byType(NextUpStrip), matching: find.text(label));

  group('the strip at the top of the chat', () {
    testWidgets('names the next event, and answers it in one tap', (
      tester,
    ) async {
      final rsvps = await open(tester, '/g/a/chat', events: [event('e1', 1)]);
      final strip = find.byType(NextUpStrip);
      expect(strip, findsOneWidget);
      expect(
        find.descendant(of: strip, matching: find.textContaining('Practice')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: strip, matching: find.textContaining('Field 3')),
        findsOneWidget,
      );
      expect(pill('Going'), findsOneWidget);
      expect(pill('Not going'), findsOneWidget);
      // Maybe is on the event's page.
      expect(pill('Maybe'), findsNothing);

      await tester.tap(pill('Going'));
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.status, RsvpStatus.going);
      expect(rsvps.rsvps.single.participantId, 'p1');
      // The answer, as a tag, in place of the buttons.
      expect(pill('Not going'), findsNothing);
      expect(pill('Going'), findsOneWidget);
      expect(find.byType(RsvpChoice), findsNothing);
    });

    testWidgets('screen readers hear what, when, where, and the state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, '/g/a/chat', events: [event('e1', 1)]);
      expect(
        find.bySemanticsLabel(
          // The time in the viewer's zone, whatever the machine's.
          RegExp(
            r'^Next up: Practice, \w+ \d+:\d\d.[AP]M, Field 3\. Needs your answer\.$',
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a tap on the line opens the event', (tester) async {
      await open(tester, '/g/a/chat', events: [event('e1', 1)]);
      await tester.tap(
        find.descendant(
          of: find.byType(NextUpStrip),
          matching: find.textContaining('Field 3'),
        ),
      );
      await tester.pumpAndSettle();
      // The event's page, asking about Noah.
      expect(find.text('Is Noah going?'), findsOneWidget);
    });

    testWidgets(
      'answering for several says "Answer for…" and opens the event',
      (tester) async {
        await open(
          tester,
          '/g/a/chat',
          events: [event('e1', 2)],
          players: linked([
            player('p1', 'Noah Diaz'),
            player('p2', 'Leo Diaz'),
          ]),
        );
        expect(find.text('Answer for Leo and Noah'), findsOneWidget);
        expect(find.byType(RsvpChoice), findsNothing);
        await tester.tap(find.text('Answer for Leo and Noah'));
        await tester.pumpAndSettle();
        expect(find.text('Are your players going?'), findsOneWidget);
      },
    );

    testWidgets('canceled and past the deadline offer no buttons', (
      tester,
    ) async {
      await open(
        tester,
        '/g/a/chat',
        events: [event('e1', 1, canceledAt: DateTime(2026))],
      );
      expect(pill('Canceled'), findsOneWidget);
      expect(find.byType(RsvpChoice), findsNothing);

      await open(
        tester,
        '/g/a/chat',
        events: [
          event(
            'e1',
            1,
            rsvpDeadline: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      );
      expect(find.byType(NextUpStrip), findsOneWidget);
      expect(find.byType(RsvpChoice), findsNothing);
    });

    testWidgets('a member not linked to a player sees the event, no buttons', (
      tester,
    ) async {
      await open(
        tester,
        '/g/a/chat',
        events: [event('e1', 1)],
        players: FakePlayerRepository([player('p1', 'Noah Diaz')]),
      );
      expect(find.byType(NextUpStrip), findsOneWidget);
      expect(find.byType(RsvpChoice), findsNothing);
      expect(find.textContaining('Needs your answer'), findsNothing);
    });

    testWidgets('nothing in the next two weeks, or the next is over: no '
        'strip', (tester) async {
      await open(tester, '/g/a/chat', events: [event('e1', 20)]);
      expect(find.text('Next up'), findsNothing);
      expect(find.textContaining('Practice'), findsNothing);

      await open(tester, '/g/a/chat', events: [event('e1', -1)]);
      expect(find.textContaining('Next up'), findsNothing);
    });

    testWidgets('an archived team has none', (tester) async {
      await open(
        tester,
        '/g/a/chat',
        events: [event('e1', 1)],
        group: testGroup('a', 'Thunder').copyWith(archivedAt: DateTime(2026)),
      );
      expect(find.byType(NextUpStrip), findsOneWidget);
      expect(find.textContaining('Practice'), findsNothing);
    });

    testWidgets('goes while the keyboard is up', (tester) async {
      await open(tester, '/g/a/chat', events: [event('e1', 1)]);
      expect(pill('Going'), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(pill('Going'), findsNothing);
    });

    testWidgets('fits at 200% text on a small phone', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(
        tester,
        '/g/a/chat',
        events: [event('e1', 1, title: 'vs. Hornets', type: EventType.game)],
        size: const Size(320, 900),
      );
      expect(tester.takeException(), isNull);
      expect(pill('Going'), findsOneWidget);
      // The buttons under the line, each 48 tall to tap.
      expect(
        tester.getSize(find.byType(RsvpChoice)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('the line on Teams', () {
    testWidgets('says what is next, with a coral dot while it needs me', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, '/teams', events: [event('e1', 1)]);
      expect(
        find.textContaining(RegExp(r'Next: Practice · \w+ \d+:\d\d')),
        findsOneWidget,
      );
      expect(find.textContaining('Needs your answer'), findsOneWidget);
      // The card's label carries the line.
      expect(
        find.bySemanticsLabel(
          RegExp(r'Next: Practice, \w+ \d+:\d\d.[AP]M, needs your answer'),
        ),
        findsOneWidget,
      );
      // No buttons on the card: answering is in Your schedule.
      expect(
        find.descendant(
          of: find.byType(TeamCardNextLine),
          matching: find.byType(RsvpChoice),
        ),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('no dot once answered, and no line with nothing next', (
      tester,
    ) async {
      final e = event('e1', 1);
      await open(
        tester,
        '/teams',
        events: [e],
        answers: [
          Rsvp(
            groupId: _a,
            eventId: e.id,
            participantType: ParticipantType.player,
            participantId: 'p1',
            participantName: 'Noah Diaz',
            status: RsvpStatus.going,
            eventStartAt: e.startAt,
          ),
        ],
      );
      expect(find.textContaining('Next: Practice'), findsOneWidget);
      expect(find.textContaining('Needs your answer'), findsNothing);

      await open(tester, '/teams');
      expect(find.textContaining('Next:'), findsNothing);
    });

    testWidgets('a canceled one says so', (tester) async {
      await open(
        tester,
        '/teams',
        events: [event('e1', 3, canceledAt: DateTime(2026))],
      );
      expect(find.textContaining('· Canceled'), findsOneWidget);
      expect(find.textContaining('Needs your answer'), findsNothing);
    });
  });
}
