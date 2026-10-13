// Each player's RSVP history (SPEC PLAYER-11): which past events count, the
// totals, and the screen the player card opens for the player's people and
// the team's admins.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/rsvp_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart' show coach;

void main() {
  final now = DateTime.now();

  /// An event [days] from now (negative: in the past), an hour long.
  Event event(
    String id,
    int days, {
    String title = 'Practice',
    bool rsvpEnabled = true,
    DateTime? canceledAt,
  }) {
    final start = now.add(Duration(days: days));
    return Event(
      id: EventId(id),
      groupId: const GroupId('y'),
      type: EventType.practice,
      title: title,
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      timeZone: 'America/Chicago',
      createdBy: 'coach',
      rsvpEnabled: rsvpEnabled,
      canceledAt: canceledAt,
    );
  }

  Rsvp answer(String eventId, RsvpStatus status, {int days = -1}) => Rsvp(
    eventId: EventId(eventId),
    groupId: const GroupId('y'),
    participantType: ParticipantType.player,
    participantId: 'emma',
    participantName: 'Emma Rodriguez',
    status: status,
    respondedBy: 'maria',
    eventStartAt: now.add(Duration(days: days)),
  );

  group('rsvpHistoryOf', () {
    test('past events that took RSVPs, newest first, with their answers', () {
      final history = rsvpHistoryOf(
        events: [
          event('old', -20),
          event('new', -2),
          event('soon', 2),
          event('off', -5, rsvpEnabled: false),
          event('called', -9, canceledAt: now),
        ],
        answers: {'old': answer('old', RsvpStatus.going, days: -20)},
        now: now,
      );
      expect(history.entries.map((e) => e.event.id.value), [
        'new',
        'called',
        'old',
      ]);
      expect(history.entries.last.answer?.status, RsvpStatus.going);
      // Canceled events are listed but not counted.
      expect(history.eventCount, 2);
      expect(history.count(RsvpStatus.going), 1);
      expect(history.count(null), 1);
      expect(history.count(RsvpStatus.notGoing), 0);
    });

    test('nothing from before the player was added', () {
      final history = rsvpHistoryOf(
        events: [event('before', -30), event('after', -3)],
        answers: const {},
        now: now,
        since: now.subtract(const Duration(days: 10)),
      );
      expect(history.entries.map((e) => e.event.id.value), ['after']);
    });
  });

  group('the history screen (PLAYER-11)', () {
    const maria = AuthUser(
      uid: 'maria',
      email: 'maria@example.com',
      emailVerified: true,
    );
    const sam = AuthUser(
      uid: 'sam',
      email: 'sam@example.com',
      emailVerified: true,
    );
    final people = [
      testMembership('y', 'coach', role: MemberRole.owner, name: 'Jordan'),
      testMembership('y', 'maria', name: 'Maria Rodriguez'),
      testMembership('y', 'sam', name: 'Sam Lee'),
    ];

    Future<FakeRsvpRepository> open(
      WidgetTester tester, {
      AuthUser user = maria,
    }) async {
      final players =
          FakePlayerRepository([
              Player(
                id: const PlayerId('emma'),
                groupId: const GroupId('y'),
                displayName: 'Emma Rodriguez',
                jerseyNumber: '7',
                addedAt: now.subtract(const Duration(days: 365)),
              ),
            ])
            ..links.add(
              const GuardianLink(
                playerId: PlayerId('emma'),
                groupId: GroupId('y'),
                uid: UserId('maria'),
              ),
            );
      final events = FakeEventRepository([
        event('e1', -3, title: 'Practice A'),
        event('e2', -10, title: 'Game B'),
        event('e3', -17, title: 'Practice C'),
        event('e4', -24, title: 'Practice D', canceledAt: now),
        // Past the first 3 months.
        event('e5', -150, title: 'Spring kickoff'),
      ]);
      final rsvps = FakeRsvpRepository(events)
        ..put(answer('e1', RsvpStatus.going, days: -3))
        ..put(answer('e2', RsvpStatus.notGoing, days: -10))
        ..put(answer('e5', RsvpStatus.going, days: -150));
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: user),
        groups: {'y': testGroup('y', 'Lightning U10')},
        memberships: people,
        playerRepo: players,
        eventRepo: events,
        rsvpRepo: rsvps,
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/g/y/roster/players/emma');
      await tester.pumpAndSettle();
      return rsvps;
    }

    testWidgets('a guardian opens it from the player card: totals and each '
        'event, the last 3 months first', (tester) async {
      await open(tester);
      await tester.tap(find.text('RSVP history'));
      await tester.pumpAndSettle();
      expect(find.text('3 past events'), findsOneWidget);
      expect(find.text('Going · 1'), findsOneWidget);
      expect(find.text('Not going · 1'), findsOneWidget);
      expect(find.text('No answer · 1'), findsOneWidget);
      expect(find.text('Practice A'), findsOneWidget);
      expect(find.text('Practice C'), findsOneWidget);
      // Listed, struck through, not counted.
      expect(find.text('Practice D'), findsOneWidget);
      expect(find.text('Canceled'), findsOneWidget);
      expect(find.text('Spring kickoff'), findsNothing);

      await tester.tap(find.text('6 months'));
      await tester.pumpAndSettle();
      expect(find.text('Spring kickoff'), findsOneWidget);
      expect(find.text('4 past events'), findsOneWidget);
      expect(find.text('Going · 2'), findsOneWidget);
    });

    testWidgets('an admin sees it too', (tester) async {
      await open(tester, user: coach);
      expect(find.text('RSVP history'), findsOneWidget);
    });

    testWidgets("other members don't, even from a link", (tester) async {
      await open(tester, user: sam);
      expect(find.text('RSVP history'), findsNothing);
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/g/y/roster/players/emma/history');
      await tester.pumpAndSettle();
      expect(find.textContaining('Only this player'), findsOneWidget);
      expect(find.text('Practice A'), findsNothing);
    });
  });
}
