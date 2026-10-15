// The schedule in the app (SPEC SCHED-1 to SCHED-10, PLAYER-6, PLAYER-9,
// CHAT-11, STORE-4, Q12).
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/presentation/event_details_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const zone = 'America/Chicago';

  /// Today in the team's zone. The viewer's zone is the machine's, so on a
  /// UTC machine (CI) the two days differ in Chicago's evening.
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
    String? seriesId,
    DateTime? canceledAt,
    DateTime? rsvpDeadline,
    RsvpCounts counts = const RsvpCounts(),
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
      seriesId: seriesId,
      seriesDate: seriesId == null ? null : dateKey(addDays(today(), days)),
      canceledAt: canceledAt,
      rsvpDeadline: rsvpDeadline,
      rsvpCounts: counts,
      reminderOffsets: const [1440],
    );
  }

  Future<FakeRsvpRepository> openSchedule(
    WidgetTester tester, {
    List<Event> events = const [],
    MemberRole role = MemberRole.member,
    GroupSettings settings = const GroupSettings(),
    bool storageFull = false,
    FakePlayerRepository? players,
    Map<String, Group> extraGroups = const {},
    FakeCalendarAdder? calendar,
    FakeMessageRepository? messages,
    List<Membership> extraMembers = const [],
    bool tapSchedule = true,
  }) async {
    final eventRepo = FakeEventRepository(events);
    final rsvps = FakeRsvpRepository(eventRepo);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {
        'a': testGroup('a', 'Thunder').copyWith(
          settings: settings,
          storageBytes: storageFull ? 500 * bytesPerMb : 0,
          storageQuotaBytes: 500 * bytesPerMb,
        ),
        ...extraGroups,
      },
      memberships: [
        testMembership('a', 'coach', role: role, name: 'Coach Lee'),
        testMembership('a', 'sam', name: 'Sam Rivera'),
        for (final id in extraGroups.keys)
          testMembership(id, 'coach', name: 'Coach Lee'),
        ...extraMembers,
      ],
      rsvpRepo: rsvps,
      playerRepo: players,
      calendar: calendar,
      messageRepo: messages,
    );
    if (tapSchedule) {
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
    }
    return rsvps;
  }

  Future<void> openDetails(WidgetTester tester, String title) async {
    await tester.tap(find.text(title).first);
    await tester.pumpAndSettle();
  }

  Future<void> menu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  group('the schedule tab (SCHED-1)', () {
    testWidgets('Upcoming groups by day with times, places, counts, and '
        'my answer', (tester) async {
      final rsvps = await openSchedule(
        tester,
        events: [
          event('e1', title: 'vs. Eagles', type: EventType.game),
          event('e2', hour: 20, title: 'Team dinner'),
          event(
            'e3',
            days: 3,
            counts: const RsvpCounts(going: 12, maybe: 3, notGoing: 2),
          ),
          event('old', days: -2, title: 'Last game'),
        ],
      );
      expect(find.text('vs. Eagles'), findsOneWidget);
      expect(find.text('Team dinner'), findsOneWidget);
      expect(find.text('Last game'), findsNothing);
      expect(find.text('6:00 PM – 7:30 PM'), findsNWidgets(2));
      expect(find.text('Riverside Park'), findsNWidgets(3));
      expect(find.text('12 going · 3 maybe · 2 no'), findsOneWidget);
      expect(find.text('No response'), findsNWidgets(3));
      // Two events tomorrow share one date block.
      expect(find.text('${addDays(today(), 1).day}'), findsOneWidget);

      rsvps.put(
        const Rsvp(
          eventId: EventId('e1'),
          groupId: GroupId('a'),
          participantType: ParticipantType.member,
          participantId: 'coach',
          participantName: 'Coach Lee',
          status: RsvpStatus.going,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Going'), findsOneWidget);
      expect(find.text('1 going'), findsOneWidget);
    });

    testWidgets('Past is newest first', (tester) async {
      await openSchedule(
        tester,
        events: [
          event('p1', days: -10, title: 'Older game'),
          event('p2', days: -3, title: 'Newer game'),
          event('u1', days: 2, title: 'Next practice'),
        ],
      );
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Next practice'), findsNothing);
      final newer = tester.getTopLeft(find.text('Newer game')).dy;
      final older = tester.getTopLeft(find.text('Older game')).dy;
      expect(newer, lessThan(older));
    });

    testWidgets("Calendar shows dots and the picked day's events", (
      tester,
    ) async {
      // Today, so it's in this month's grid whatever the date.
      await openSchedule(
        tester,
        events: [event('t', days: 0, hour: 23, title: 'Late practice')],
      );
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      expect(find.text('Late practice'), findsOneWidget);
      expect(find.byKey(const ValueKey('dot-t')), findsOneWidget);
      // Another day of the month has nothing.
      final other = today().day == 1 ? 2 : 1;
      await tester.tap(find.text('$other').first);
      await tester.pumpAndSettle();
      expect(find.text('Late practice'), findsNothing);
      expect(find.text('Nothing on this day.'), findsOneWidget);
    });

    testWidgets('a busy day has a dot for each event', (tester) async {
      await openSchedule(
        tester,
        events: [
          for (var i = 0; i < 5; i++)
            event('busy$i', days: 0, hour: 19 + i, title: 'Session $i'),
        ],
      );
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(ValueKey('dot-busy$i')), findsOneWidget);
      }
    });

    testWidgets('canceled events are struck through with a badge (SCHED-7)', (
      tester,
    ) async {
      await openSchedule(
        tester,
        events: [event('c', canceledAt: DateTime.now())],
      );
      expect(find.text('Canceled'), findsOneWidget);
      final title = tester.widget<Text>(find.text('Practice'));
      expect(title.style?.decoration, TextDecoration.lineThrough);
      // RSVPs are closed: no answer or counts on the row.
      expect(find.text('No response'), findsNothing);
    });

    testWidgets('the type filter (SCHED-2)', (tester) async {
      await openSchedule(
        tester,
        events: [
          event('g', title: 'vs. Eagles', type: EventType.game),
          event('p', days: 2),
        ],
      );
      await tester.tap(find.widgetWithText(FilterChip, 'Games'));
      await tester.pumpAndSettle();
      expect(find.text('vs. Eagles'), findsOneWidget);
      expect(find.text('Practice'), findsNothing);
    });
  });

  group('who sees + (Q12, STORE-4)', () {
    testWidgets('only admins by default', (tester) async {
      await openSchedule(tester);
      expect(find.byTooltip('New event'), findsNothing);
      await openSchedule(tester, role: MemberRole.admin);
      expect(find.byTooltip('New event'), findsOneWidget);
    });

    testWidgets('members too when the team allows it', (tester) async {
      await openSchedule(
        tester,
        settings: const GroupSettings(membersCanCreateEvents: true),
      );
      expect(find.byTooltip('New event'), findsOneWidget);
    });

    testWidgets('full storage says why instead of opening the form', (
      tester,
    ) async {
      await openSchedule(tester, role: MemberRole.admin, storageFull: true);
      await tester.tap(find.byTooltip('New event'));
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('Storage is full.'),
        ),
        findsOneWidget,
      );
    });
  });

  group('making events (SCHED-3)', () {
    testWidgets('a game fills in its title and opens when saved', (
      tester,
    ) async {
      final rsvps = await openSchedule(tester, role: MemberRole.admin);
      await tester.tap(find.byTooltip('New event'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Game'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Opponent'),
        'Eagles',
      );
      await tester.tap(find.text('Away'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Place'),
        'Riverside Park',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved = rsvps.events.events.values.single;
      expect(saved.title, '@ Eagles');
      expect(saved.homeAway, HomeAway.away);
      expect(saved.location?.name, 'Riverside Park');
      expect(saved.reminderOffsets, [1440]);
      expect(saved.seriesId, isNull);
      expect(saved.rsvpEnabled, isTrue);
      expect(saved.notifyTeam, isTrue);
      expect(saved.postToChat, isTrue);
      // The event's page.
      expect(find.text('@ Eagles'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
    });

    testWidgets('RSVPs, Notify team, and Post to chat are checkboxes', (
      tester,
    ) async {
      final rsvps = await openSchedule(tester, role: MemberRole.admin);
      await tester.tap(find.byTooltip('New event'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Dinner');
      for (final label in ['Ask for RSVPs', 'Notify team', 'Post to chat']) {
        final box = find.widgetWithText(CheckboxListTile, label);
        await tester.ensureVisible(box);
        expect(tester.widget<CheckboxListTile>(box).value, isTrue);
        await tester.tap(box);
        await tester.pumpAndSettle();
        expect(tester.widget<CheckboxListTile>(box).value, isFalse);
      }
      expect(find.byType(SwitchListTile), findsOneWidget); // All day
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final saved = rsvps.events.events.values.single;
      expect(saved.rsvpEnabled, isFalse);
      expect(saved.notifyTeam, isFalse);
      expect(saved.postToChat, isFalse);
    });

    testWidgets('weekly practices with a skipped date make one series', (
      tester,
    ) async {
      final rsvps = await openSchedule(tester, role: MemberRole.admin);
      await tester.tap(find.byTooltip('New event'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Practice',
      );
      await tester.tap(find.text("Doesn't repeat"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekly').last);
      await tester.pumpAndSettle();
      // Today's weekday, for 8 weeks.
      expect(find.textContaining('8 practices · '), findsOneWidget);
      final chips = find.byType(ActionChip);
      expect(chips, findsNWidgets(8));
      await tester.ensureVisible(chips.at(1));
      await tester.tap(chips.at(1));
      await tester.pumpAndSettle();
      expect(find.textContaining('7 practices · '), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final repo = rsvps.events;
      expect(repo.calls, ['createSeries 7']);
      expect(repo.lastTemplate?.title, 'Practice');
      expect(repo.lastTemplate?.startTime, '18:00');
      expect(repo.series.values.single.recurrence.skipDates, [
        dateKey(addDays(today(), 7)),
      ]);
      expect(find.text('Added 7 practices.'), findsOneWidget);
    });

    testWidgets('closing after typing asks first', (tester) async {
      await openSchedule(tester, role: MemberRole.admin);
      await tester.tap(find.byTooltip('New event'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Half');
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard this event?'), findsOneWidget);
    });

    testWidgets('Duplicate copies all but the date, which must be picked', (
      tester,
    ) async {
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        events: [event('e1', title: 'vs. Eagles', type: EventType.game)],
      );
      await openDetails(tester, 'vs. Eagles');
      await menu(tester, 'Duplicate');
      expect(find.text('Pick a date'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'vs. Eagles'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(rsvps.events.calls, isEmpty);
      expect(find.text('Pick a date'), findsWidgets);
    });

    testWidgets("duplicating last week's game takes a new date and opponent "
        '(SCHED-3 acceptance)', (tester) async {
      final original = event(
        'e1',
        days: -7,
        title: 'vs. Eagles',
        type: EventType.game,
      ).copyWith(opponent: 'Eagles', homeAway: HomeAway.home);
      // Answers were due the evening before, at 8:00 PM.
      final game = original.copyWith(
        rsvpDeadline: ZonedTime.instantOf(zone, addDays(today(), -8), 20 * 60),
      );
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        events: [game],
      );
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      await openDetails(tester, 'vs. Eagles');
      await menu(tester, 'Duplicate');
      // The title stays automatic, so it follows the new opponent.
      expect(find.widgetWithText(TextField, 'vs. Eagles'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Opponent'),
        'Hawks',
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'vs. Hawks'), findsOneWidget);
      // The deadline waits for the date, then lands as far before it.
      await tester.scrollUntilVisible(
        find.text('Set from the date you pick'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.scrollUntilVisible(
        find.text('Pick a date'),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved = rsvps.events.events.values.firstWhere(
        (e) => e.id.value != 'e1',
      );
      expect(saved.title, 'vs. Hawks');
      expect(saved.opponent, 'Hawks');
      // The picker opens on the device's today, which differs from
      // Chicago's in the evening on a UTC machine (CI).
      final now = DateTime.now();
      final picked = DateTime.utc(now.year, now.month, now.day);
      expect(
        saved.rsvpDeadline,
        ZonedTime.instantOf(zone, addDays(picked, -1), 20 * 60),
      );
    });
  });

  group('event details and RSVPs (SCHED-4, SCHED-5)', () {
    testWidgets('a member answers Going with a note', (tester) async {
      final rsvps = await openSchedule(tester, events: [event('e1')]);
      await openDetails(tester, 'Practice');
      expect(find.text('Riverside Park'), findsOneWidget);
      expect(find.text('100 River Rd'), findsOneWidget);
      expect(find.text('Reminders 1 day before'), findsOneWidget);
      await tester.tap(find.text('Going').first);
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.status, RsvpStatus.going);
      expect(rsvps.rsvps.single.participantId, 'coach');
      expect(find.text('1 going'), findsOneWidget);

      await tester.tap(find.text('Add a note'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Leaving early');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.note, 'Leaving early');
      // Sam hasn't answered.
      expect(find.text('No response · 1'), findsOneWidget);
    });

    testWidgets('Maybe is hidden when the team turns it off', (tester) async {
      await openSchedule(
        tester,
        events: [event('e1')],
        settings: const GroupSettings(allowMaybe: false),
      );
      await openDetails(tester, 'Practice');
      expect(find.text('Going'), findsWidgets);
      expect(find.text('Maybe'), findsNothing);
    });

    testWidgets('after the deadline only admins can answer', (tester) async {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      await openSchedule(tester, events: [event('e1', rsvpDeadline: past)]);
      await openDetails(tester, 'Practice');
      expect(find.textContaining('deadline has passed'), findsOneWidget);
      final buttons = tester.widget<SegmentedButton<RsvpStatus>>(
        find.byType(SegmentedButton<RsvpStatus>),
      );
      expect(buttons.onSelectionChanged, isNull);

      await openSchedule(
        tester,
        role: MemberRole.admin,
        events: [event('e1', rsvpDeadline: past)],
      );
      await openDetails(tester, 'Practice');
      final adminButtons = tester.widget<SegmentedButton<RsvpStatus>>(
        find.byType(SegmentedButton<RsvpStatus>),
      );
      expect(adminButtons.onSelectionChanged, isNotNull);
    });

    testWidgets('canceled events close RSVPs', (tester) async {
      await openSchedule(
        tester,
        events: [event('e1', canceledAt: DateTime.now())],
      );
      await openDetails(tester, 'Practice');
      expect(find.text('Canceled'), findsOneWidget);
      expect(find.text('RSVPs are closed.'), findsOneWidget);
      expect(find.byType(SegmentedButton<RsvpStatus>), findsNothing);
    });

    testWidgets('guardians answer once per player; counts are players '
        '(PLAYER-6)', (tester) async {
      final players =
          FakePlayerRepository(const [
              Player(
                id: PlayerId('p1'),
                groupId: GroupId('a'),
                displayName: 'Emma Rivera',
                jerseyNumber: '7',
              ),
              Player(
                id: PlayerId('p2'),
                groupId: GroupId('a'),
                displayName: 'Liam Rivera',
              ),
              Player(
                id: PlayerId('p3'),
                groupId: GroupId('a'),
                displayName: 'Ava Kim',
              ),
            ])
            ..links.addAll(const [
              GuardianLink(
                playerId: PlayerId('p1'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
              ),
              GuardianLink(
                playerId: PlayerId('p2'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
              ),
            ]);
      final rsvps = await openSchedule(
        tester,
        players: players,
        events: [event('e1')],
      );
      // The list shows an answer per player.
      expect(find.text('Emma: No response'), findsOneWidget);
      expect(find.text('Liam: No response'), findsOneWidget);
      await openDetails(tester, 'Practice');
      // All my players first (PLAYER-11), then one row per player.
      expect(find.byType(SegmentedButton<RsvpStatus>), findsNWidgets(3));
      expect(find.text('Emma #7'), findsWidgets);
      await tester.tap(find.text('Going').at(1));
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.participantId, 'p1');
      expect(rsvps.rsvps.single.participantType, ParticipantType.player);
      expect(find.text('1 of 3 players going'), findsOneWidget);
      expect(find.text('Answered by Coach L.'), findsOneWidget);
    });

    testWidgets('one tap gives all my players the same answer, keeping their '
        'notes; my own answer stays apart (PLAYER-11)', (tester) async {
      final players =
          FakePlayerRepository(const [
              Player(
                id: PlayerId('p1'),
                groupId: GroupId('a'),
                displayName: 'Emma Rivera',
                jerseyNumber: '7',
              ),
              Player(
                id: PlayerId('p2'),
                groupId: GroupId('a'),
                displayName: 'Liam Rivera',
              ),
            ])
            ..links.addAll(const [
              GuardianLink(
                playerId: PlayerId('p1'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
              ),
              GuardianLink(
                playerId: PlayerId('p2'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
              ),
            ]);
      // An admin: a Me row too, which "All my players" leaves alone.
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        players: players,
        events: [event('e1')],
      );
      rsvps.put(
        const Rsvp(
          eventId: EventId('e1'),
          groupId: GroupId('a'),
          participantType: ParticipantType.player,
          participantId: 'p1',
          participantName: 'Emma Rivera',
          status: RsvpStatus.maybe,
          note: 'Might be late',
          respondedBy: 'coach',
        ),
      );
      await openDetails(tester, 'Practice');
      expect(find.text('All my players'), findsOneWidget);
      // Me, then All my players, then each player.
      expect(find.byType(SegmentedButton<RsvpStatus>), findsNWidgets(4));
      Finder allButtons() => find.descendant(
        of: find.ancestor(
          of: find.text('All my players'),
          matching: find.byType(SameAnswerButtons),
        ),
        matching: find.byType(SegmentedButton<RsvpStatus>),
      );
      Set<RsvpStatus> allSelected() =>
          tester.widget<SegmentedButton<RsvpStatus>>(allButtons()).selected;
      // Not all the same yet: nothing selected.
      expect(allSelected(), isEmpty);
      await tester.tap(
        find.descendant(of: allButtons(), matching: find.text('Going')),
      );
      await tester.pumpAndSettle();
      expect(rsvps.batches, [
        ['p1:going', 'p2:going'],
      ]);
      final emma = rsvps.rsvps.firstWhere((r) => r.participantId == 'p1');
      expect(emma.note, 'Might be late');
      expect(rsvps.rsvps.any((r) => r.participantId == 'coach'), isFalse);
      expect(allSelected(), {RsvpStatus.going});
      expect(find.text('2 of 2 players going'), findsOneWidget);

      // One player changed alone: the shared answer clears, and the next
      // tap writes only the player who needs it.
      await tester.tap(find.text('Not going').last);
      await tester.pumpAndSettle();
      expect(allSelected(), isEmpty);
      await tester.tap(
        find.descendant(of: allButtons(), matching: find.text('Going')),
      );
      await tester.pumpAndSettle();
      // One answer to write: a plain write, not a batch.
      expect(rsvps.batches, hasLength(1));
      expect(
        rsvps.rsvps.firstWhere((r) => r.participantId == 'p2').status,
        RsvpStatus.going,
      );
      expect(allSelected(), {RsvpStatus.going});
    });

    testWidgets('one player gets no "All my players" (PLAYER-11)', (
      tester,
    ) async {
      final players =
          FakePlayerRepository(const [
              Player(
                id: PlayerId('p1'),
                groupId: GroupId('a'),
                displayName: 'Emma',
              ),
            ])
            ..links.add(
              const GuardianLink(
                playerId: PlayerId('p1'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
              ),
            );
      await openSchedule(tester, players: players, events: [event('e1')]);
      await openDetails(tester, 'Practice');
      expect(find.text('All my players'), findsNothing);
    });

    testWidgets('a member who is a player answers on their own row, with no '
        'Me row (PLAYER-6)', (tester) async {
      final players =
          FakePlayerRepository(const [
              Player(
                id: PlayerId('p1'),
                groupId: GroupId('a'),
                displayName: 'Coach Lee',
                jerseyNumber: '12',
              ),
              Player(
                id: PlayerId('p2'),
                groupId: GroupId('a'),
                displayName: 'Noah Park',
                status: PlayerStatus.pending,
                proposedBy: 'coach',
              ),
            ])
            ..links.add(
              const GuardianLink(
                playerId: PlayerId('p1'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
                relation: PlayerRelation.self,
              ),
            );
      final rsvps = await openSchedule(
        tester,
        players: players,
        events: [event('e1')],
      );
      expect(find.text('You: No response'), findsOneWidget);
      await openDetails(tester, 'Practice');
      // One set of buttons: their player's. The pending player isn't there.
      expect(find.byType(SegmentedButton<RsvpStatus>), findsOneWidget);
      expect(find.text('Coach #12 (you)'), findsOneWidget);
      expect(find.textContaining('Noah'), findsNothing);
      await tester.tap(find.text('Going').first);
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.participantId, 'p1');
      expect(rsvps.rsvps.single.participantType, ParticipantType.player);
      expect(find.text('1 of 1 players going'), findsOneWidget);
    });

    testWidgets('an admin who is a player has one answer of their own, on '
        'their player, on the list, the chat card, and the event (PLAYER-6)', (
      tester,
    ) async {
      final players =
          FakePlayerRepository(const [
              Player(
                id: PlayerId('p1'),
                groupId: GroupId('a'),
                displayName: 'Pat Lee',
                jerseyNumber: '12',
              ),
            ])
            ..links.add(
              const GuardianLink(
                playerId: PlayerId('p1'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
                relation: PlayerRelation.self,
              ),
            );
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.owner,
        players: players,
        events: [event('e1')],
        tapSchedule: false,
        messages: FakeMessageRepository([
          Message(
            id: 'm-e1',
            groupId: const GroupId('a'),
            authorId: 'coach',
            authorName: 'Coach Lee',
            type: MessageType.event,
            text: 'Practice',
            eventId: 'e1',
            createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
        ]),
      );
      // The chat card: one set of buttons, the player's.
      expect(find.byType(SegmentedButton<RsvpStatus>), findsOneWidget);
      expect(find.text('Pat #12 (you)'), findsOneWidget);
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      // Never "You: No response" twice.
      expect(find.text('You: No response'), findsOneWidget);
      await openDetails(tester, 'Practice');
      expect(find.byType(SegmentedButton<RsvpStatus>), findsOneWidget);
      expect(find.text('Pat #12 (you)'), findsOneWidget);
      // Not also listed under "coaches and others" with no way to answer.
      expect(find.text('Coaches and others'), findsOneWidget);
      expect(find.text('Coach Lee'), findsNothing);
      await tester.tap(find.text('Going').first);
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.participantId, 'p1');
    });

    testWidgets('an answer of my own from before I was a player is listed '
        'and still mine to change (PLAYER-6)', (tester) async {
      final players =
          FakePlayerRepository(const [
              Player(
                id: PlayerId('p1'),
                groupId: GroupId('a'),
                displayName: 'Coach Lee',
                jerseyNumber: '12',
              ),
            ])
            ..links.add(
              const GuardianLink(
                playerId: PlayerId('p1'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
                relation: PlayerRelation.self,
              ),
            );
      final rsvps = await openSchedule(
        tester,
        players: players,
        events: [event('e1')],
        tapSchedule: false,
      );
      rsvps.rsvps.add(
        const Rsvp(
          eventId: EventId('e1'),
          groupId: GroupId('a'),
          participantType: ParticipantType.member,
          participantId: 'coach',
          participantName: 'Coach Lee',
          status: RsvpStatus.going,
        ),
      );
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      await openDetails(tester, 'Practice');
      // The old answer has its own row, apart from the player's.
      expect(find.byType(SegmentedButton<RsvpStatus>), findsNWidgets(2));
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Coach #12 (you)'), findsOneWidget);
      await tester.tap(find.text('Not going').first);
      await tester.pumpAndSettle();
      expect(
        rsvps.rsvps
            .singleWhere((r) => r.participantType == ParticipantType.member)
            .status,
        RsvpStatus.notGoing,
      );
    });

    testWidgets('admins set an answer for someone else', (tester) async {
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        events: [event('e1')],
      );
      await openDetails(tester, 'Practice');
      await tester.tap(find.text('Sam Rivera'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not going').last);
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.participantId, 'sam');
      expect(rsvps.rsvps.single.status, RsvpStatus.notGoing);
      expect(rsvps.rsvps.single.respondedBy, 'coach');
    });

    testWidgets('Add to calendar hands the event to the calendar (SCHED-10)', (
      tester,
    ) async {
      final calendar = FakeCalendarAdder();
      await openSchedule(tester, events: [event('e1')], calendar: calendar);
      await openDetails(tester, 'Practice');
      await tester.tap(find.byTooltip('Add to calendar'));
      await tester.pumpAndSettle();
      expect(calendar.added.single.title, 'Practice');
      expect(calendar.added.single.location, 'Riverside Park, 100 River Rd');
      expect(
        calendar.added.single.url.toString(),
        'https://getbattleplan.app/app/g/a/schedule/e/e1',
      );
    });

    testWidgets("members can't edit, cancel, or delete someone else's", (
      tester,
    ) async {
      await openSchedule(
        tester,
        events: [event('e1').copyWith(createdBy: 'sam')],
      );
      await openDetails(tester, 'Practice');
      expect(find.byTooltip('More actions'), findsNothing);
    });
  });

  group('cancel and delete (SCHED-6, SCHED-7)', () {
    testWidgets('canceling a one-off event keeps it, struck through', (
      tester,
    ) async {
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        events: [event('e1', days: 10)],
      );
      await openDetails(tester, 'Practice');
      await menu(tester, 'Cancel event');
      expect(find.text('Cancel this event?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel event'));
      await tester.pumpAndSettle();
      expect(rsvps.events.calls, ['cancel e1']);
      expect(find.text('Canceled'), findsOneWidget);
    });

    testWidgets('deleting within a week suggests canceling instead', (
      tester,
    ) async {
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        events: [event('e1')],
      );
      await openDetails(tester, 'Practice');
      await menu(tester, 'Delete');
      expect(find.text('Cancel instead'), findsOneWidget);
      await tester.tap(find.text('Cancel instead'));
      await tester.pumpAndSettle();
      expect(rsvps.events.calls, ['cancel e1']);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await openDetails(tester, 'Practice');
      await menu(tester, 'Delete');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(rsvps.events.calls.last, 'delete e1');
      expect(find.text('Event deleted.'), findsOneWidget);
    });

    testWidgets('a series asks "This and following" and says what goes', (
      tester,
    ) async {
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        events: [
          event('s-1', days: 10, seriesId: 's'),
          event('s-2', days: 12, seriesId: 's'),
        ],
      );
      rsvps.events
        ..dryRunResult = const SeriesResult(removed: 4, removedRsvps: 9)
        ..series['s'] = const EventSeries(
          id: 's',
          groupId: GroupId('a'),
          timeZone: zone,
          createdBy: 'coach',
          recurrence: Recurrence(
            freq: RepeatFreq.weekly,
            startDate: '2026-10-13',
            byWeekday: [2, 4],
            untilDate: '2026-12-17',
          ),
        );
      await openDetails(tester, 'Practice');
      expect(
        find.text('Repeats weekly on Tue and Thu until Dec 17'),
        findsOneWidget,
      );
      await menu(tester, 'Delete');
      expect(find.text('This event'), findsOneWidget);
      await tester.tap(find.text('This and following events'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Removes 4 practices; 9 people had answered.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(rsvps.events.calls, [
        'deleteSeries following dry',
        'deleteSeries following',
      ]);
      expect(rsvps.events.events, isEmpty);
    });

    testWidgets('canceling one event of a series leaves the rest', (
      tester,
    ) async {
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        events: [
          event('s-1', days: 10, seriesId: 's'),
          event('s-2', days: 12, seriesId: 's', title: 'Thursday practice'),
        ],
      );
      await openDetails(tester, 'Practice');
      await menu(tester, 'Cancel event');
      await tester.tap(find.text('This event'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel event'));
      await tester.pumpAndSettle();
      expect(rsvps.events.calls, ['cancelSeries this']);
      expect(rsvps.events.events['s-1']!.isCanceled, isTrue);
      expect(rsvps.events.events['s-2']!.isCanceled, isFalse);
    });

    testWidgets('editing a series asks which events first (SCHED-6)', (
      tester,
    ) async {
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        events: [event('s-1', days: 10, seriesId: 's')],
      );
      await openDetails(tester, 'Practice');
      await menu(tester, 'Edit');
      await tester.tap(find.text('This event'));
      await tester.pumpAndSettle();
      expect(find.text('Edit event'), findsOneWidget);
      // One event of a series doesn't get its own repeat rule.
      expect(find.text('Repeat'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'Practice'),
        'Scrimmage',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(rsvps.events.calls, ['updateSeries this']);
      expect(rsvps.events.lastTemplate?.title, 'Scrimmage');
    });
  });

  testWidgets('All my teams merges every team and names my players '
      '(SCHED-2, PLAYER-9)', (tester) async {
    final players =
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
    await openSchedule(
      tester,
      players: players,
      extraGroups: {'b': testGroup('b', 'Lightning U10')},
      events: [
        event('a1', title: 'Thunder practice'),
        event('b1', days: 2, title: 'Lightning game', groupId: 'b'),
      ],
    );
    expect(find.text('Lightning game'), findsNothing);
    await tester.tap(find.widgetWithText(FilterChip, 'All my teams'));
    await tester.pumpAndSettle();
    expect(find.text('Thunder practice'), findsOneWidget);
    expect(find.text('Lightning game'), findsOneWidget);
    expect(find.text('Lightning U10 · For Emma'), findsOneWidget);
    expect(find.text('Thunder'), findsWidgets);
  });

  group('event cards in chat (CHAT-11)', () {
    Message card(
      String eventId, {
      String? seriesId,
      String text = 'Practice',
    }) => Message(
      id: 'm-$eventId',
      groupId: const GroupId('a'),
      authorId: 'coach',
      authorName: 'Coach Lee',
      type: MessageType.event,
      text: text,
      eventId: eventId,
      seriesId: seriesId,
      createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    testWidgets('shows the event and opens it', (tester) async {
      await openSchedule(
        tester,
        tapSchedule: false,
        events: [event('e1', title: 'vs. Eagles', type: EventType.game)],
        messages: FakeMessageRepository([card('e1')]),
      );
      expect(find.text('vs. Eagles'), findsOneWidget);
      expect(find.text('Riverside Park'), findsOneWidget);
      await tester.tap(find.text('vs. Eagles'));
      await tester.pumpAndSettle();
      expect(find.text('Directions'), findsOneWidget);
    });

    testWidgets('answers Going right on the card, with live counts', (
      tester,
    ) async {
      final rsvps = await openSchedule(
        tester,
        tapSchedule: false,
        events: [event('e1', title: 'vs. Eagles', type: EventType.game)],
        messages: FakeMessageRepository([card('e1')]),
      );
      expect(find.byType(SegmentedButton<RsvpStatus>), findsOneWidget);
      expect(find.text('No answers yet'), findsOneWidget);
      await tester.tap(find.text('Going'));
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.status, RsvpStatus.going);
      expect(rsvps.rsvps.single.participantId, 'coach');
      expect(find.text('1 going'), findsOneWidget);
      // Still in the chat: answering doesn't open the event.
      expect(find.text('Directions'), findsNothing);
    });

    testWidgets('guardians answer for each player on the card (PLAYER-6)', (
      tester,
    ) async {
      final players =
          FakePlayerRepository(const [
              Player(
                id: PlayerId('p1'),
                groupId: GroupId('a'),
                displayName: 'Emma Rivera',
                jerseyNumber: '7',
              ),
              Player(
                id: PlayerId('p2'),
                groupId: GroupId('a'),
                displayName: 'Liam Rivera',
              ),
            ])
            ..links.addAll(const [
              GuardianLink(
                playerId: PlayerId('p1'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
              ),
              GuardianLink(
                playerId: PlayerId('p2'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
              ),
            ]);
      final rsvps = await openSchedule(
        tester,
        tapSchedule: false,
        players: players,
        events: [event('e1')],
        messages: FakeMessageRepository([card('e1')]),
      );
      // All my players first (PLAYER-11), then one row per player.
      expect(find.byType(SegmentedButton<RsvpStatus>), findsNWidgets(3));
      expect(find.text('Emma #7'), findsOneWidget);
      await tester.tap(find.text('Going').last);
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.participantId, 'p2');
      expect(find.text('1 of 2 players going'), findsOneWidget);
    });

    testWidgets('one tap answers for all my players on the card (PLAYER-11)', (
      tester,
    ) async {
      final players =
          FakePlayerRepository(const [
              Player(
                id: PlayerId('p1'),
                groupId: GroupId('a'),
                displayName: 'Emma',
              ),
              Player(
                id: PlayerId('p2'),
                groupId: GroupId('a'),
                displayName: 'Liam',
              ),
            ])
            ..links.addAll(const [
              GuardianLink(
                playerId: PlayerId('p1'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
              ),
              GuardianLink(
                playerId: PlayerId('p2'),
                groupId: GroupId('a'),
                uid: UserId('coach'),
              ),
            ]);
      final rsvps = await openSchedule(
        tester,
        tapSchedule: false,
        players: players,
        events: [event('e1')],
        messages: FakeMessageRepository([card('e1')]),
      );
      expect(find.text('All my players'), findsOneWidget);
      await tester.tap(find.text('Not going').first);
      await tester.pumpAndSettle();
      expect(rsvps.batches, [
        ['p1:not_going', 'p2:not_going'],
      ]);
      expect(find.text('0 of 2 players going'), findsOneWidget);
    });

    testWidgets('a canceled event takes no answers on the card', (
      tester,
    ) async {
      await openSchedule(
        tester,
        tapSchedule: false,
        events: [event('e1').copyWith(canceledAt: DateTime.now())],
        messages: FakeMessageRepository([card('e1')]),
      );
      expect(find.byType(SegmentedButton<RsvpStatus>), findsNothing);
    });

    testWidgets('answers from the card, with live counts (SPEC 5.4)', (
      tester,
    ) async {
      final rsvps = await openSchedule(
        tester,
        tapSchedule: false,
        events: [event('e1')],
        messages: FakeMessageRepository([card('e1')]),
      );
      expect(find.text('Going'), findsOneWidget);
      expect(find.text('Maybe'), findsOneWidget);
      expect(find.text('Not going'), findsOneWidget);
      expect(find.text('No answers yet'), findsOneWidget);
      await tester.tap(find.text('Going'));
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.status, RsvpStatus.going);
      expect(rsvps.rsvps.single.participantId, 'coach');
      expect(find.text('1 going'), findsOneWidget);
      // Answering from the card stays in the chat.
      expect(find.text('Directions'), findsNothing);
    });

    testWidgets('canceled and RSVP-off cards take no answers', (tester) async {
      await openSchedule(
        tester,
        tapSchedule: false,
        events: [
          event('e1', title: 'Drill', canceledAt: DateTime.now()),
          event('e2', title: 'Dinner').copyWith(rsvpEnabled: false),
        ],
        messages: FakeMessageRepository([card('e1'), card('e2')]),
      );
      expect(find.text('Drill'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.byType(SegmentedButton<RsvpStatus>), findsNothing);
    });

    testWidgets('says when the event was deleted', (tester) async {
      await openSchedule(
        tester,
        tapSchedule: false,
        messages: FakeMessageRepository([card('gone')]),
      );
      expect(find.text('Event deleted'), findsOneWidget);
    });

    testWidgets("a series' card shows the next event once its own is gone", (
      tester,
    ) async {
      final messages = FakeMessageRepository([
        card(
          'gone',
          seriesId: 's',
          text: 'Practice · Tue and Thu, Oct 13 – Dec 17',
        ),
      ]);
      final rsvps = await openSchedule(
        tester,
        tapSchedule: false,
        events: [
          event('s-old', days: -3, seriesId: 's', title: 'Old practice'),
          event('s-2', days: 2, seriesId: 's', title: 'Thursday practice'),
          event('s-3', days: 4, seriesId: 's', title: 'Later practice'),
        ],
        messages: messages,
      );
      rsvps.events.series['s'] = const EventSeries(
        id: 's',
        groupId: GroupId('a'),
        timeZone: zone,
        createdBy: 'coach',
        recurrence: Recurrence(
          freq: RepeatFreq.daily,
          startDate: '2026-10-13',
          count: 10,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Event deleted'), findsNothing);
      expect(find.text('Thursday practice'), findsOneWidget);
      await tester.tap(find.text('Thursday practice'));
      await tester.pumpAndSettle();
      expect(find.text('Directions'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // With nothing ahead, it shows the series as posted.
      for (final id in ['s-2', 's-3']) {
        await rsvps.events.deleteEvent(rsvps.events.events[id]!);
      }
      await tester.pumpAndSettle();
      expect(
        find.text('Practice · Tue and Thu, Oct 13 – Dec 17'),
        findsOneWidget,
      );
      expect(find.text('Event deleted'), findsNothing);
    });
  });

  group('review fixes', () {
    testWidgets('admins set answers for players and for any member; '
        'coaches and others are listed apart (SCHED-4, Q14)', (tester) async {
      final players = FakePlayerRepository(const [
        Player(
          id: PlayerId('p1'),
          groupId: GroupId('a'),
          displayName: 'Emma Rivera',
        ),
      ]);
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        players: players,
        extraMembers: [
          testMembership('a', 'pat', role: MemberRole.admin, name: 'Pat Kim'),
        ],
        events: [event('e1')],
      );
      await openDetails(tester, 'Practice');
      expect(find.text('Coaches and others'), findsOneWidget);
      expect(find.text('0 of 1 players going'), findsOneWidget);
      // Another coach's row sets their answer, as the rules allow admins.
      await tester.ensureVisible(find.text('Pat Kim'));
      await tester.tap(find.text('Pat Kim'));
      await tester.pumpAndSettle();
      expect(find.text('RSVP for Pat Kim'), findsOneWidget);
      await tester.tap(find.text('Going').last);
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.participantId, 'pat');
      expect(find.text('0 of 1 players going · 1 other'), findsOneWidget);
      // "Set RSVP for someone" lists the players and every member.
      await menu(tester, 'Set RSVP for someone');
      expect(find.textContaining('Emma'), findsWidgets);
      await tester.tap(find.text('Emma').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not going').last);
      await tester.pumpAndSettle();
      expect(
        rsvps.rsvps.where((r) => r.participantId == 'p1').single.status,
        RsvpStatus.notGoing,
      );
    });

    Event allDay(
      String id, {
      required int firstDay,
      int lastDay = 0,
      String timeZone = zone,
      String title = 'Tournament',
      String? seriesId,
    }) {
      final first = addDays(today(), firstDay);
      final last = addDays(today(), lastDay < firstDay ? firstDay : lastDay);
      return event(id, title: title, seriesId: seriesId).copyWith(
        allDay: true,
        timeZone: timeZone,
        startDate: dateKey(first),
        endDate: dateKey(last),
        startAt: ZonedTime.instantOf(timeZone, first, 0),
        endAt: ZonedTime.instantOf(timeZone, addDays(last, 1), 0),
      );
    }

    testWidgets('all-day events stay in Upcoming through their last day, '
        'whatever their zone (SCHED-9)', (tester) async {
      final rsvps = await openSchedule(
        tester,
        events: [
          // Midnight in New York is before midnight in Chicago.
          allDay(
            'ny',
            firstDay: 0,
            timeZone: 'America/New_York',
            title: 'Jamboree',
          ),
          allDay('t', firstDay: -2, lastDay: 1),
          allDay('done', firstDay: -3, lastDay: -1, title: 'Camp'),
          event('p'),
        ],
      );
      rsvps.put(
        Rsvp(
          eventId: const EventId('ny'),
          groupId: const GroupId('a'),
          participantType: ParticipantType.member,
          participantId: 'coach',
          participantName: 'Coach Lee',
          status: RsvpStatus.going,
          eventStartAt: rsvps.events.events['ny']!.startAt,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jamboree'), findsOneWidget);
      expect(find.text('Tournament'), findsOneWidget);
      expect(find.text('Camp'), findsNothing);
      // Its answer is read too, though it starts before today here.
      expect(find.text('Going'), findsOneWidget);
      // By day: the tournament began two days ago, then today, then
      // tomorrow.
      final y = [
        for (final t in ['Tournament', 'Jamboree', 'Practice'])
          tester.getTopLeft(find.text(t)).dy,
      ];
      expect(y[0], lessThan(y[1]));
      expect(y[1], lessThan(y[2]));

      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Camp'), findsOneWidget);
      expect(find.text('Tournament'), findsNothing);
      expect(find.text('Jamboree'), findsNothing);
    });

    testWidgets('Past reads the answers on the events it shows, not the '
        'oldest', (tester) async {
      final rsvps = await openSchedule(
        tester,
        events: [
          event('p1', days: -10, title: 'Older game'),
          event('p2', days: -3, title: 'Newer game'),
        ],
      );
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      final oldest = rsvps.events.events['p1']!.startAt;
      final todayStart = ZonedTime.instantOf(zone, today(), 0);
      expect(rsvps.windows.last, (from: oldest, until: todayStart));
    });

    testWidgets('a "This event" edit of an all-day series event has no '
        'last day', (tester) async {
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        events: [allDay('s-1', firstDay: 10, seriesId: 's')],
      );
      await openDetails(tester, 'Tournament');
      await menu(tester, 'Edit');
      await tester.tap(find.text('This event'));
      await tester.pumpAndSettle();
      expect(find.text('Edit event'), findsOneWidget);
      expect(find.text('Last day'), findsNothing);
      expect(rsvps.events.calls, isEmpty);
    });

    testWidgets('"This and following" on a series that ends after N events '
        'previews what saving makes, and says what it adds (SCHED-6)', (
      tester,
    ) async {
      final rsvps = await openSchedule(
        tester,
        role: MemberRole.admin,
        events: [event('s-5', days: 7, seriesId: 's')],
      );
      // Daily, 10 events; the 5th is a week from today, 4 come before it.
      rsvps.events
        ..dryRunResult = const SeriesResult(created: 2, updated: 4)
        ..series['s'] = EventSeries(
          id: 's',
          groupId: const GroupId('a'),
          timeZone: zone,
          createdBy: 'coach',
          recurrence: Recurrence(
            freq: RepeatFreq.daily,
            startDate: dateKey(addDays(today(), 3)),
            count: 10,
          ),
        );
      await openDetails(tester, 'Practice');
      await menu(tester, 'Edit');
      await tester.tap(find.text('This and following events'));
      await tester.pumpAndSettle();
      // The whole series' count, as it was made...
      expect(find.text('10 events'), findsOneWidget);
      // ...and the 6 left from this one on, as the server keeps them.
      await tester.scrollUntilVisible(
        find.textContaining('6 practices · '),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('6 practices · '), findsOneWidget);
      expect(find.byType(ActionChip), findsNWidgets(6));

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Adds 2 practices.'), findsOneWidget);
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(rsvps.events.calls, [
        'updateSeries following dry',
        'updateSeries following',
      ]);
    });
  });

  group('time zones (SCHED-9)', () {
    testWidgets("rows and chat cards show the event's time and mine", (
      tester,
    ) async {
      // A game in New York, seen from Chicago.
      final away = event(
        'e1',
        title: 'vs. Eagles',
        type: EventType.game,
      ).copyWith(timeZone: 'America/New_York');
      final msg = Message(
        id: 'm-e1',
        groupId: const GroupId('a'),
        authorId: 'coach',
        authorName: 'Coach Lee',
        type: MessageType.event,
        text: 'vs. Eagles',
        eventId: 'e1',
        createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      await openSchedule(
        tester,
        tapSchedule: false,
        events: [away],
        messages: FakeMessageRepository([msg]),
      );
      // Times have a (narrow) space before PM.
      expect(
        find.textContaining(RegExp(r'^7:00\sPM E[DS]T · 6:00\sPM your time$')),
        findsOneWidget,
      );
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(RegExp(r'6:00\sPM your time')),
        findsOneWidget,
      );
    });

    testWidgets('one line when the zones agree', (tester) async {
      await openSchedule(tester, events: [event('e1')]);
      expect(find.textContaining('your time'), findsNothing);
    });
  });
}
