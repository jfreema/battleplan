// The schedule in the app (SPEC SCHED-1 to SCHED-10, PLAYER-6, PLAYER-9,
// CHAT-11, STORE-4, Q12).
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
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

  /// Today in the team's zone, which is also the viewer's in tests.
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
    RsvpFor rsvpFor = RsvpFor.members,
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
      rsvpFor: rsvpFor,
      rsvpCounts: counts,
      reminderOffsets: const [1440],
    );
  }

  Future<FakeRsvpRepository> openSchedule(
    WidgetTester tester, {
    List<Event> events = const [],
    MemberRole role = MemberRole.member,
    GroupSettings settings = const GroupSettings(),
    TeamType teamType = TeamType.adult,
    bool storageFull = false,
    FakePlayerRepository? players,
    Map<String, Group> extraGroups = const {},
    FakeCalendarAdder? calendar,
    FakeMessageRepository? messages,
    bool tapSchedule = true,
  }) async {
    final eventRepo = FakeEventRepository(events);
    final rsvps = FakeRsvpRepository(eventRepo);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {
        'a': testGroup('a', 'Thunder').copyWith(
          teamType: teamType,
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
      // Another day of the month has nothing.
      final other = today().day == 1 ? 2 : 1;
      await tester.tap(find.text('$other').first);
      await tester.pumpAndSettle();
      expect(find.text('Late practice'), findsNothing);
      expect(find.text('Nothing on this day.'), findsOneWidget);
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
      // The event's page.
      expect(find.text('@ Eagles'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
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
        teamType: TeamType.youth,
        players: players,
        events: [event('e1', rsvpFor: RsvpFor.players)],
      );
      // The list shows an answer per player.
      expect(find.text('Emma: No response'), findsOneWidget);
      expect(find.text('Liam: No response'), findsOneWidget);
      await openDetails(tester, 'Practice');
      expect(find.byType(SegmentedButton<RsvpStatus>), findsNWidgets(2));
      expect(find.text('Emma #7'), findsWidgets);
      await tester.tap(find.text('Going').first);
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.participantId, 'p1');
      expect(rsvps.rsvps.single.participantType, ParticipantType.player);
      expect(find.text('1 of 3 players going'), findsOneWidget);
      expect(find.text('Answered by Coach L.'), findsOneWidget);
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

    testWidgets("members can't edit, cancel, or delete", (tester) async {
      await openSchedule(tester, events: [event('e1')]);
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
      extraGroups: {
        'b': testGroup('b', 'Lightning U10').copyWith(teamType: TeamType.youth),
      },
      events: [
        event('a1', title: 'Thunder practice'),
        event(
          'b1',
          days: 2,
          title: 'Lightning game',
          groupId: 'b',
          rsvpFor: RsvpFor.players,
        ),
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
    Message card(String eventId) => Message(
      id: 'm-$eventId',
      groupId: const GroupId('a'),
      authorId: 'coach',
      authorName: 'Coach Lee',
      type: MessageType.event,
      text: 'Practice',
      eventId: eventId,
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

    testWidgets('says when the event was deleted', (tester) async {
      await openSchedule(
        tester,
        tapSchedule: false,
        messages: FakeMessageRepository([card('gone')]),
      );
      expect(find.text('Event deleted'), findsOneWidget);
    });
  });
}
