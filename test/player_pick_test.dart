// "Who are you here for?" prompts for a team's new members (SPEC PLAYER-3;
// owner's go 2026-11-16, "Do #11"): the card at the top of the chat, the
// line on schedule cards, the Team tab's row, and coming back to where
// they started after asking. The event page's part is in
// schedule_test.dart, and Dues' in dues_test.dart.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/players.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const pat = AuthUser(
    uid: 'pat',
    email: 'pat@example.com',
    emailVerified: true,
  );
  const zone = 'America/Chicago';
  const ask = "Here for a player? Pick who's yours so you can answer RSVPs.";
  const hint = 'Pick your player to answer';

  final thunder = testGroup('a', 'Thunder');

  /// Pat, a member of Thunder who isn't linked to a player.
  Membership member({
    MemberRole role = MemberRole.member,
    HereFor? hereFor,
    bool? coach,
  }) => testMembership(
    'a',
    'pat',
    role: role,
    name: 'Pat Lee',
  ).copyWith(hereFor: hereFor, coach: coach);

  /// Max #4 and Sofia #9 on Thunder's roster; Pat's claims are kept.
  FakePlayerRepository roster() => FakePlayerRepository(const [
    Player(
      id: PlayerId('max'),
      groupId: GroupId('a'),
      displayName: 'Max Lee',
      jerseyNumber: '4',
    ),
    Player(
      id: PlayerId('sofia'),
      groupId: GroupId('a'),
      displayName: 'Sofia Cruz',
      jerseyNumber: '9',
    ),
  ])..claimsAs = 'pat';

  GuardianRequest claim(String player) => GuardianRequest(
    playerId: PlayerId(player),
    groupId: const GroupId('a'),
    uid: const UserId('pat'),
    status: GuardianRequestStatus.pending,
  );

  GuardianLink link(String player) => GuardianLink(
    playerId: PlayerId(player),
    groupId: const GroupId('a'),
    uid: const UserId('pat'),
  );

  /// An event [days] from today at 6 PM in Chicago, 90 minutes long.
  Event event(String id, {int days = 1, String title = 'Practice'}) {
    final w = ZonedTime.wallClock(zone, DateTime.now());
    final day = addDays(DateTime.utc(w.year, w.month, w.day), days);
    final start = ZonedTime.instantOf(zone, day, 18 * 60);
    return Event(
      id: EventId(id),
      groupId: const GroupId('a'),
      type: EventType.practice,
      title: title,
      startAt: start,
      endAt: start.add(const Duration(minutes: 90)),
      timeZone: zone,
      createdBy: 'coach',
    );
  }

  /// The app as [user], with [me] on [group], opening in the team's chat
  /// (or on [route]).
  Future<({FakeMemberRepository members, FakePlayerRepository players})> open(
    WidgetTester tester, {
    Membership? me,
    FakePlayerRepository? players,
    Group? group,
    List<Event> events = const [],
    AuthUser user = pat,
    String? route,
  }) async {
    final members = FakeMemberRepository([
      me ?? member(),
      testMembership('a', 'coach', role: MemberRole.owner, name: 'Coach Kim'),
    ]);
    final playerRepo = players ?? roster();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: user),
      prefs: route == null ? null : (FakeLocalPrefs()..lastTeamRoute = route),
      groups: {'a': group ?? thunder},
      memberRepo: members,
      playerRepo: playerRepo,
      rsvpRepo: FakeRsvpRepository(FakeEventRepository(events)),
    );
    return (members: members, players: playerRepo);
  }

  /// Where the router is, pushed screens included.
  String location(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Navigator).first)).state.uri
          .toString();

  /// From the card (or anywhere) through "Who are you here for?": I'm here
  /// for a player, [names] ticked, Ask to link.
  Future<void> askToLink(WidgetTester tester, List<String> names) async {
    await tester.tap(find.text("I'm here for a player"));
    await tester.pumpAndSettle();
    for (final name in names) {
      await tester.tap(find.text(name));
      await tester.pump();
    }
    await tester.tap(
      find.text(
        names.length == 1
            ? 'Ask to link 1 player'
            : 'Ask to link ${names.length} players',
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the card at the top of the chat', () {
    testWidgets('tells a new member of a team how to answer RSVPs', (
      tester,
    ) async {
      await open(tester);
      expect(location(tester), '/g/a/chat');
      expect(find.text(ask), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Pick my player'), findsOne);
      expect(find.widgetWithText(OutlinedButton, 'Not now'), findsOne);
      // It's above the chat, not in the way of it.
      expect(find.byTooltip('Add photos or a poll'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(PlayerPickCard)).dy,
        lessThan(
          tester
              .getTopLeft(find.text('No messages yet. Say hi to the team!'))
              .dy,
        ),
      );
    });

    testWidgets('not for an admin, a coach, a super admin, someone linked, '
        'an archived team, or a group', (tester) async {
      await open(tester, me: member(role: MemberRole.admin));
      expect(find.text(ask), findsNothing);

      await open(tester, me: member(coach: true));
      expect(find.text(ask), findsNothing);

      await open(
        tester,
        user: const AuthUser(
          uid: 'pat',
          email: 'pat@example.com',
          emailVerified: true,
          isSuperAdmin: true,
        ),
      );
      expect(find.text(ask), findsNothing);

      await open(tester, players: roster()..links.add(link('max')));
      expect(find.text(ask), findsNothing);

      await open(
        tester,
        group: thunder.copyWith(archivedAt: DateTime.utc(2026)),
      );
      expect(find.text(ask), findsNothing);

      await open(tester, group: thunder.copyWith(kind: GroupKind.group));
      expect(find.text(ask), findsNothing);
      // Each of them still has their chat.
      expect(find.byType(PlayerPickCard), findsOneWidget);
    });

    testWidgets('Not now closes it, saved on their membership', (tester) async {
      final app = await open(tester);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(app.members.calls, ['hereFor a later']);
      expect(find.text(ask), findsNothing);
      expect(find.text('Pick my player'), findsNothing);
    });

    testWidgets("already answered, it isn't shown", (tester) async {
      await open(tester, me: member(hereFor: HereFor.later));
      expect(find.text(ask), findsNothing);
      await open(tester, me: member(hereFor: HereFor.nobody));
      expect(find.text(ask), findsNothing);
    });

    testWidgets('Pick my player, then Ask to link, comes back to the chat, '
        'which says who they wait on; closing that is saved too', (
      tester,
    ) async {
      final app = await open(tester);
      await tester.tap(find.text('Pick my player'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/who');
      await askToLink(tester, ['Max Lee', 'Sofia Cruz']);
      expect(app.players.calls, ['claim max guardian', 'claim sofia guardian']);
      // Back where they started, not just anywhere in the team.
      expect(location(tester), '/g/a/chat');
      expect(find.text('Request sent to the team admins'), findsOneWidget);
      expect(
        find.text('Waiting for the coach to approve Max and Sofia'),
        findsOneWidget,
      );
      expect(find.text(ask), findsNothing);
      expect(find.text('Pick my player'), findsNothing);

      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();
      expect(app.members.calls, ['hereFor a later']);
      expect(find.textContaining('Waiting for the coach'), findsNothing);
    });

    testWidgets("I'm a coach or another adult comes back too, and is "
        'remembered', (tester) async {
      final app = await open(tester);
      await tester.tap(find.text('Pick my player'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("I'm a coach or another adult"));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/chat');
      expect(app.members.calls, ['hereFor a nobody']);
      expect(find.text(ask), findsNothing);
    });

    testWidgets('once a team admin approves, it is gone', (tester) async {
      final players = roster()..requests.add(claim('max'));
      await open(tester, players: players);
      expect(find.text('Waiting for the coach to approve Max'), findsOneWidget);
      // The server links them and takes the claim away.
      players
        ..requests.clear()
        ..links.add(link('max'));
      ProviderScope.containerOf(tester.element(find.byType(PlayerPickCard)))
        ..invalidate(guardianLinksProvider(const GroupId('a')))
        ..invalidate(myGuardianRequestsProvider(const GroupId('a')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Waiting for the coach'), findsNothing);
      expect(find.text(ask), findsNothing);
    });

    testWidgets('a player they added themselves is waited on by name', (
      tester,
    ) async {
      await open(
        tester,
        players: FakePlayerRepository(const [
          Player(
            id: PlayerId('noah'),
            groupId: GroupId('a'),
            displayName: 'Noah Lee',
            status: PlayerStatus.pending,
            proposedBy: 'pat',
          ),
        ]),
      );
      expect(
        find.text('Waiting for the coach to approve Noah'),
        findsOneWidget,
      );
    });

    testWidgets('fits a narrow phone at 200% text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester);
      tester.view.physicalSize = const Size(320, 1400);
      await tester.pumpAndSettle();
      expect(find.text(ask), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the line on schedule cards', () {
    Future<void> openSchedule(
      WidgetTester tester, {
      Membership? me,
      FakePlayerRepository? players,
      Group? group,
      List<Event>? events,
    }) async {
      await open(
        tester,
        me: me,
        players: players,
        group: group,
        events: events ?? [event('e1'), event('e2', days: 2, title: 'Game')],
      );
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
    }

    testWidgets('says how to get answer buttons, where a card shows a count '
        'and none', (tester) async {
      await openSchedule(
        tester,
        events: [
          event('e1'),
          event('e2', days: 2, title: 'Game'),
          // Canceled, and one that takes no RSVPs: nothing to answer.
          event('e3', days: 3).copyWith(canceledAt: DateTime.now()),
          event('e4', days: 4).copyWith(rsvpEnabled: false),
        ],
      );
      expect(find.text('0/2 going'), findsNWidgets(2));
      expect(find.text(hint), findsNWidgets(2));
      await tester.tap(find.text(hint).first);
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/who');
      // Asking comes back to the schedule, whose cards now say who for.
      await askToLink(tester, ['Max Lee']);
      expect(location(tester), '/g/a/schedule');
      expect(find.text(hint), findsNothing);
      expect(
        find.text('Waiting for the coach to approve Max'),
        findsNWidgets(2),
      );
    });

    testWidgets('not after Not now, nor for a coach or another adult, an '
        'admin, a team with no players yet, or a group', (tester) async {
      await openSchedule(tester, me: member(hereFor: HereFor.later));
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text(hint), findsNothing);

      await openSchedule(tester, me: member(hereFor: HereFor.nobody));
      expect(find.text(hint), findsNothing);

      await openSchedule(tester, me: member(coach: true));
      expect(find.text(hint), findsNothing);

      await openSchedule(tester, me: member(role: MemberRole.admin));
      expect(find.text(hint), findsNothing);

      await openSchedule(tester, players: FakePlayerRepository());
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text(hint), findsNothing);

      await openSchedule(
        tester,
        group: thunder.copyWith(kind: GroupKind.group),
      );
      expect(find.text(hint), findsNothing);
    });

    testWidgets('a waiting claim shows whatever they answered before', (
      tester,
    ) async {
      await openSchedule(
        tester,
        me: member(hereFor: HereFor.later),
        players: roster()..requests.add(claim('sofia')),
      );
      expect(
        find.text('Waiting for the coach to approve Sofia'),
        findsNWidgets(2),
      );
      expect(find.text(hint), findsNothing);
    });

    testWidgets('linked, the card has the buttons and no line', (tester) async {
      await openSchedule(tester, players: roster()..links.add(link('max')));
      expect(find.text(hint), findsNothing);
      // One set of Going, Maybe, and Not going on each of the two cards.
      expect(find.byType(SegmentedButton<RsvpStatus>), findsNWidgets(2));
    });

    testWidgets('Your schedule on Teams says it too, and comes back there', (
      tester,
    ) async {
      await open(tester, events: [event('e1')], route: '/teams');
      expect(location(tester), '/teams');
      expect(find.text(hint), findsOneWidget);
      await tester.tap(find.text(hint));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/who');
      await askToLink(tester, ['Sofia Cruz']);
      expect(location(tester), '/teams');
      expect(
        find.text('Waiting for the coach to approve Sofia'),
        findsOneWidget,
      );
    });
  });

  group('the Team tab row', () {
    SettingsRow row(WidgetTester tester) => tester.widget<SettingsRow>(
      find.widgetWithText(SettingsRow, 'Who are you here for?'),
    );

    testWidgets('is bold until they answer, and stays so they can link '
        'later', (tester) async {
      await open(tester);
      await openTeamTab(tester);
      expect(row(tester).highlighted, isTrue);

      for (final answer in HereFor.values) {
        await open(tester, me: member(hereFor: answer));
        await openTeamTab(tester);
        expect(row(tester).highlighted, isFalse, reason: answer.value);
      }
    });

    testWidgets('says who they wait on, where it used to vanish, and asking '
        'from it comes back to it', (tester) async {
      await open(tester);
      await openTeamTab(tester);
      await tester.tap(find.text('Who are you here for?'));
      await tester.pumpAndSettle();
      await askToLink(tester, ['Max Lee']);
      expect(location(tester), '/g/a/team');
      expect(find.text('Who are you here for?'), findsNothing);
      // It still opens the screen, for a second player.
      await tester.tap(find.text('Waiting for the coach to approve Max'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/who');
    });
  });

  testWidgets('opened by its address, with nothing to go back to, it leaves '
      "for the team's chat", (tester) async {
    final app = await open(tester);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/g/a/who');
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm a coach or another adult"));
    await tester.pumpAndSettle();
    expect(location(tester), '/g/a/chat');
    expect(app.members.calls, ['hereFor a nobody']);
  });

  group('playerPickOf (PLAYER-3)', () {
    const players = [
      Player(
        id: PlayerId('max'),
        groupId: GroupId('a'),
        displayName: 'Max Lee',
      ),
      Player(
        id: PlayerId('sofia'),
        groupId: GroupId('a'),
        displayName: 'Sofia Cruz',
      ),
    ];
    PlayerPick pick({
      Membership? me,
      bool archived = false,
      List<GuardianLink> links = const [],
      List<GuardianRequest> requests = const [],
      List<Player> pending = const [],
    }) => playerPickOf(
      me: me ?? member(),
      archived: archived,
      links: links,
      requests: requests,
      pendingPlayers: pending,
      players: players,
    );

    test('asks someone who is not linked and has not said', () {
      expect(pick(), const PlayerPick(stage: PlayerPickStage.ask, card: true));
      expect(pick().unlinked, isTrue);
    });

    test('stops asking once they answer, but still offers it', () {
      final later = pick(me: member(hereFor: HereFor.later));
      expect(later, const PlayerPick(stage: PlayerPickStage.later));
      final adult = pick(me: member(hereFor: HereFor.nobody));
      expect(adult, const PlayerPick(stage: PlayerPickStage.adult));
      // A coach an admin marked needs no asking either.
      expect(pick(me: member(coach: true)), adult);
      expect([later.unlinked, adult.unlinked], [true, true]);
    });

    test('has nothing for admins, the linked, or an archived team', () {
      expect(pick(me: member(role: MemberRole.admin)), const PlayerPick());
      expect(pick(me: member(role: MemberRole.owner)), const PlayerPick());
      expect(pick(links: [link('max')]), const PlayerPick());
      // Linked wins over a second claim still waiting.
      expect(
        pick(links: [link('max')], requests: [claim('sofia')]),
        const PlayerPick(),
      );
      expect(pick(archived: true), const PlayerPick());
      expect(const PlayerPick().unlinked, isFalse);
    });

    test('waits by name: claims in roster order, then players they added', () {
      const noah = Player(
        id: PlayerId('noah'),
        groupId: GroupId('a'),
        displayName: 'Noah Lee',
        status: PlayerStatus.pending,
        proposedBy: 'pat',
      );
      final waiting = pick(
        requests: [claim('sofia'), claim('max')],
        pending: [noah],
      );
      expect(waiting.stage, PlayerPickStage.waiting);
      expect(waiting.waitingFor, ['Max', 'Sofia', 'Noah']);
      expect(waiting.card, isTrue);
      expect(waiting.unlinked, isFalse);
      // Someone else's claim, a decided one, and someone else's player
      // aren't theirs to wait on.
      expect(
        pick(
          requests: [
            claim('max').copyWith(uid: const UserId('sam')),
            claim('sofia').copyWith(status: GuardianRequestStatus.declined),
          ],
          pending: [noah.copyWith(proposedBy: 'sam')],
        ).stage,
        PlayerPickStage.ask,
      );
    });

    test('a closed card stays closed while they wait, even on an archived '
        'team', () {
      final waiting = pick(
        me: member(hereFor: HereFor.later),
        archived: true,
        requests: [claim('max')],
      );
      expect(
        waiting,
        const PlayerPick(stage: PlayerPickStage.waiting, waitingFor: ['Max']),
      );
    });
  });
}
