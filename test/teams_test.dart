import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/live_pages.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/application/providers.dart'
    show inviteRepositoryProvider;
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/presentation/join_screen.dart';
import 'package:battleplan/features/groups/presentation/results_screen.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/roster_parser.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

// Teams, roster, players and guardians, and invites: TEAM-1, TEAM-3,
// TEAM-5, TEAM-7, PLAYER-1, PLAYER-2, INV-2, INV-5, INV-7.
void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );

  Future<void> go(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
  }

  /// Opens [path] over the current screen, as the app's buttons do.
  Future<void> push(WidgetTester tester, String path) async {
    unawaited(
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push(path),
    );
    await tester.pumpAndSettle();
  }

  // One team type: any team has players (§6.3).
  final youth = {'y': testGroup('y', 'Lightning U10')};
  const emma = Player(
    id: PlayerId('emma'),
    groupId: GroupId('y'),
    displayName: 'Emma Rodriguez',
    jerseyNumber: '7',
  );
  GuardianLink link(String uid) => GuardianLink(
    playerId: emma.id,
    groupId: const GroupId('y'),
    uid: UserId(uid),
  );

  group('create a team (TEAM-1)', () {
    testWidgets('with a logo and no color', (tester) async {
      final groupRepo = FakeGroupRepository({});
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: groupRepo,
        photoPicker: FakePhotoPicker()..profilePhoto = tinyPng,
      );
      await tester.tap(find.text('Create a team'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Thunder');
      await tester.tap(find.text('Add logo'));
      await tester.pumpAndSettle();
      expect(find.text('Change logo'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('No color'));
      await tester.pump();
      final create = find.widgetWithText(FilledButton, 'Create a team');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(groupRepo.created, ['Thunder']);
      // There's no team type to pick (TEAM-1).
      expect(find.text('Team type'), findsNothing);
      expect(groupRepo.createdColors, [null]);
      expect(groupRepo.logosUploaded, 1);
    });

    testWidgets('a color by default, and no logo unless one is added', (
      tester,
    ) async {
      final groupRepo = FakeGroupRepository({});
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: groupRepo,
      );
      await tester.tap(find.text('Create a team'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Hawks');
      final create = find.widgetWithText(FilledButton, 'Create a team');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(groupRepo.createdColors, ['#2F5BEA']);
      expect(groupRepo.logosUploaded, 0);
    });
  });

  group('team settings (TEAM-5)', () {
    Future<FakeGroupRepository> openSettings(WidgetTester tester) async {
      final groupRepo = FakeGroupRepository({
        'a': testGroup('a', 'Thunder').copyWith(timeZone: 'America/Denver'),
      });
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: groupRepo,
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
      );
      await go(tester, '/g/a/settings');
      return groupRepo;
    }

    testWidgets('the time zone can be changed', (tester) async {
      final groupRepo = await openSettings(tester);
      await tester.tap(find.text('America/Denver'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'chic');
      await tester.pumpAndSettle();
      await tester.tap(find.text('America/Chicago'));
      await tester.pumpAndSettle();
      expect(groupRepo.updates, contains('timeZone America/Chicago'));
    });

    testWidgets('there is no team type to change (TEAM-1)', (tester) async {
      await openSettings(tester);
      expect(find.text('Team type'), findsNothing);
      expect(find.text('Youth team'), findsNothing);
      expect(find.text('Adult team'), findsNothing);
    });

    testWidgets('Manage invite link opens the invite screen', (tester) async {
      await openSettings(tester);
      final manage = find.text('Manage invite link');
      await tester.ensureVisible(manage);
      await tester.tap(manage);
      await tester.pumpAndSettle();
      expect(find.text('K7XP-M2QR'), findsOneWidget);
    });
  });

  group('the invite link (INV-2, §3)', () {
    Future<FakeInviteRepository> openInvite(WidgetTester tester) async {
      final invites = FakeInviteRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
        invites: invites,
      );
      await tester.tap(find.byTooltip('Team menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Invite'));
      await tester.pumpAndSettle();
      return invites;
    }

    testWidgets('admins set expiry and uses on the link people have', (
      tester,
    ) async {
      final invites = await openInvite(tester);
      final change = find.widgetWithText(OutlinedButton, 'Expiry and uses');
      await tester.ensureVisible(change);
      await tester.tap(change);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Never'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('After 7 days').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '20');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(invites.expiry, InviteExpiry.sevenDays);
      expect(invites.maxUses, 20);
      expect(invites.resets, 0);
      // Same code: the link and QR already shared still work.
      expect(find.text('K7XP-M2QR'), findsOneWidget);
      expect(find.textContaining('Used 0 of 20 times'), findsOneWidget);
    });

    testWidgets('admins turn the link off, and turn a new one on', (
      tester,
    ) async {
      final invites = await openInvite(tester);
      final off = find.widgetWithText(TextButton, 'Turn off link');
      await tester.ensureVisible(off);
      await tester.tap(off);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Turn off link'));
      await tester.pumpAndSettle();
      expect(invites.linkOff, isTrue);
      expect(
        find.text("The team's invite link is turned off."),
        findsOneWidget,
      );
      expect(find.text('K7XP-M2QR'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Turn on a new link'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Turn on a new link').last,
      );
      await tester.pumpAndSettle();
      expect(invites.linkOff, isFalse);
      expect(invites.resets, 1);
      expect(find.text('NEWC-QDE2'), findsOneWidget);
    });

    testWidgets("members see that it's off, without the switch", (
      tester,
    ) async {
      final invites = FakeInviteRepository()..linkOff = true;
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach')],
        invites: invites,
      );
      await go(tester, '/g/a/invite');
      expect(
        find.text("The team's invite link is turned off."),
        findsOneWidget,
      );
      expect(find.text('Turn on a new link'), findsNothing);
    });
  });

  testWidgets('adding by email lists who was invited (TEAM-7)', (tester) async {
    final members = FakeMemberRepository([
      testMembership('a', 'coach', role: MemberRole.owner, name: 'Jordan'),
    ]);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberRepo: members,
    );
    await push(tester, '/g/a/members/add');
    await tester.enterText(
      find.byType(TextField),
      'Nia Park, nia@example.com\nnot an email',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Add 1 person'));
    await tester.pumpAndSettle();
    expect(
      find.text('Invited (new accounts, sent a setup email) (1)'),
      findsOneWidget,
    );
    expect(find.text('Nia Park · nia@example.com'), findsOneWidget);
    expect(find.text('not an email'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.text('Nia Park · nia@example.com'), findsNothing);
  });

  group('adding players (PLAYER-1)', () {
    Future<FakePlayerRepository> openAdd(WidgetTester tester) async {
      final playerRepo = FakePlayerRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youth,
        memberships: [testMembership('y', 'coach', role: MemberRole.owner)],
        playerRepo: playerRepo,
      );
      await push(tester, '/g/y/players/add');
      return playerRepo;
    }

    testWidgets('a guardian with a name and no email is kept', (tester) async {
      final playerRepo = await openAdd(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Leo Park');
      await tester.enterText(find.byType(TextField).at(4), 'Maria Park');
      await tester.tap(find.widgetWithText(FilledButton, 'Add player'));
      await tester.pumpAndSettle();
      expect(playerRepo.added.single.single.guardians, [
        const NewGuardian(name: 'Maria Park'),
      ]);
      expect(find.text('Players added'), findsOneWidget);
    });

    testWidgets("an adult player's own email links them as the player, and "
        'a refused link says why (PLAYER-1)', (tester) async {
      final playerRepo = await openAdd(tester);
      playerRepo.addProblems = [
        'Jared Freeman: jared@example.com (already-a-player)',
      ];
      await tester.enterText(find.byType(TextField).at(0), 'Jared Freeman');
      expect(find.text("Player's own email (optional)"), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(3), 'jared@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Add player'));
      await tester.pumpAndSettle();
      final added = playerRepo.added.single.single;
      expect(added.email, 'jared@example.com');
      expect(added.guardians, isEmpty);
      expect(find.text('1 player linked by their own email'), findsOneWidget);
      expect(
        find.text(
          'Jared Freeman: jared@example.com: already a player on this team',
        ),
        findsOneWidget,
      );
    });

    /// Picks the 15th of this month in 2015 from the date-of-birth picker.
    Future<void> pickBirthday(WidgetTester tester) async {
      await tester.tap(find.text('Date of birth').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2015'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    testWidgets("a player's date of birth is kept privately (PLAYER-12)", (
      tester,
    ) async {
      final playerRepo = await openAdd(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Mia Park');
      expect(find.textContaining("player's own people see it"), findsOneWidget);
      await pickBirthday(tester);
      expect(find.textContaining('2015'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Add player'));
      await tester.pumpAndSettle();
      expect(
        playerRepo.added.single.single.dateOfBirth,
        matches(RegExp(r'^2015-\d{2}-15$')),
      );
    });

    testWidgets(
      "a member's new player can have one too (PLAYER-4, PLAYER-12)",
      (tester) async {
        final playerRepo = FakePlayerRepository();
        await pumpApp(
          tester,
          auth: FakeAuthRepository(user: coach),
          groups: youth,
          memberships: [testMembership('y', 'coach')],
          playerRepo: playerRepo,
        );
        await push(tester, '/g/y/players/add');
        await tester.enterText(find.byType(TextField).at(0), 'Ava Park');
        await pickBirthday(tester);
        await tester.tap(find.text("I'm their parent or guardian"));
        await tester.tap(find.widgetWithText(FilledButton, 'Add player'));
        await tester.pumpAndSettle();
        expect(
          playerRepo.calls.single,
          matches(RegExp(r'^propose Ava Park .* born 2015-\d{2}-15$')),
        );
      },
    );

    test('problem lines name each refused link', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        [
          for (final code in [
            'too-many-teams',
            'player-already-claimed',
            'too-many-guardians',
            'already-linked',
            'other',
          ])
            describeAddProblem(l10n, 'E: e@x.com ($code)'),
        ],
        [
          'E: e@x.com: already on 100 teams',
          'E: e@x.com: someone is already this player',
          'E: e@x.com: the player has 4 guardians already',
          "E: e@x.com: given as both the player's and a guardian's email",
          'E: e@x.com (other)',
        ],
      );
    });

    testWidgets('the results list lines that could not be read', (
      tester,
    ) async {
      await openAdd(tester);
      await tester.tap(find.text('Paste a list'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Arjun Shah, Priya Shah, priya@example.com\nBad, Name, nope',
      );
      await tester.pump();
      await tester.tap(find.text('Add 1 player'));
      await tester.pumpAndSettle();
      expect(find.text("Lines that couldn't be read (1)"), findsOneWidget);
      expect(find.text('Bad, Name, nope'), findsWidgets);
    });

    testWidgets('more than 200 lines are refused before sending', (
      tester,
    ) async {
      final playerRepo = await openAdd(tester);
      await tester.tap(find.text('Paste a list'));
      await tester.pumpAndSettle();
      final lines = [
        for (var i = 0; i < 101; i++) ...[
          'P$i, A, a$i@example.com',
          'P$i, B, b$i@example.com',
        ],
      ];
      await tester.enterText(find.byType(TextField), lines.join('\n'));
      await tester.pump();
      expect(find.text('Paste up to 200 lines at a time.'), findsOneWidget);
      final add = find.widgetWithText(FilledButton, 'Add 101 players');
      expect(tester.widget<FilledButton>(add).onPressed, isNull);
      expect(playerRepo.added, isEmpty);
    });

    test('the parser counts lines', () {
      expect(parsePastedRoster('A, B, b@x.com\n\nA, C, c@x.com').lines, 2);
    });
  });

  group('roster and player card (TEAM-3, PLAYER-2)', () {
    FakePlayerRepository withEmma() =>
        FakePlayerRepository([emma])..links.add(link('maria'));
    final people = [
      testMembership('y', 'coach', role: MemberRole.owner, name: 'Jordan'),
      testMembership('y', 'maria', name: 'Maria Rodriguez'),
    ];

    testWidgets('player rows show their guardians; cards list players', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youth,
        memberships: people,
        playerRepo: withEmma(),
      );
      await go(tester, '/g/y/roster');
      expect(find.text('Maria Rodriguez'), findsWidgets);
      // Who's who on the row, from the player links (PLAYER-8).
      expect(find.text('Parent of Emma #7'), findsOneWidget);
      await tester.tap(find.text('Maria Rodriguez').last);
      await tester.pumpAndSettle();
      expect(find.text('Parent of Emma #7'), findsNWidgets(2));
    });

    testWidgets('a member who is a player shows their number, and players '
        'show who is the player (PLAYER-8)', (tester) async {
      final repo =
          FakePlayerRepository([
              emma,
              const Player(
                id: PlayerId('jared'),
                groupId: GroupId('y'),
                displayName: 'Jared Freeman',
                jerseyNumber: '12',
                position: 'Pitcher',
              ),
              const Player(
                id: PlayerId('lee'),
                groupId: GroupId('y'),
                displayName: 'Lee Park',
              ),
            ])
            ..links.addAll([
              const GuardianLink(
                playerId: PlayerId('jared'),
                groupId: GroupId('y'),
                uid: UserId('coach'),
                relation: PlayerRelation.self,
              ),
              link('coach'),
              const GuardianLink(
                playerId: PlayerId('lee'),
                groupId: GroupId('y'),
                uid: UserId('maria'),
                relation: PlayerRelation.self,
              ),
            ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youth,
        memberships: people,
        playerRepo: repo,
      );
      await go(tester, '/g/y/roster');
      expect(find.text('Player #12 · Parent of Emma #7'), findsOneWidget);
      // Maria is the player Lee, who has no number.
      expect(find.text('Player'), findsOneWidget);
      expect(find.text('Pitcher · Jordan (player)'), findsOneWidget);
    });

    testWidgets('the player card lists upcoming RSVPs', (tester) async {
      final start = DateTime.now().add(const Duration(days: 2));
      final events = FakeEventRepository([
        Event(
          id: const EventId('e1'),
          groupId: const GroupId('y'),
          type: EventType.game,
          title: 'vs. Eagles',
          startAt: start,
          endAt: start.add(const Duration(hours: 1)),
          timeZone: 'America/Chicago',
          createdBy: 'coach',
        ),
        Event(
          id: const EventId('e2'),
          groupId: const GroupId('y'),
          type: EventType.practice,
          title: 'Practice',
          startAt: start.add(const Duration(days: 1)),
          endAt: start.add(const Duration(days: 1, hours: 1)),
          timeZone: 'America/Chicago',
          createdBy: 'coach',
        ),
      ]);
      final rsvps = FakeRsvpRepository(events)
        ..rsvps.add(
          Rsvp(
            eventId: const EventId('e1'),
            groupId: const GroupId('y'),
            participantType: ParticipantType.player,
            participantId: 'emma',
            participantName: 'Emma',
            status: RsvpStatus.going,
            eventStartAt: start,
          ),
        );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youth,
        memberships: people,
        playerRepo: withEmma(),
        eventRepo: events,
        rsvpRepo: rsvps,
      );
      await go(tester, '/g/y/roster/players/emma');
      expect(find.text('Upcoming RSVPs'), findsOneWidget);
      expect(find.text('vs. Eagles'), findsOneWidget);
      expect(find.text('Going'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('No answer'), findsOneWidget);
      await tester.tap(find.text('vs. Eagles'));
      await tester.pumpAndSettle();
      expect(
        GoRouter.of(tester.element(find.byType(Scaffold).last)).state.uri
            .toString(),
        '/g/y/schedule/e/e1',
      );
    });

    testWidgets('Edit player sets the date of birth in the details '
        '(PLAYER-12)', (tester) async {
      final repo = withEmma();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youth,
        memberships: people,
        playerRepo: repo,
      );
      await go(tester, '/g/y/roster/players/emma');
      await tester.tap(find.byTooltip('Edit player'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Date of birth').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2015'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(
        repo.details[emma.id]?.dateOfBirth,
        matches(RegExp(r'^2015-\d{2}-15$')),
      );
      // Clearing it leaves no details behind.
      await tester.tap(find.byTooltip('Edit player'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear date of birth').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(repo.details[emma.id], isNull);
    });

    testWidgets("a player who isn't there says so", (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youth,
        memberships: people,
        playerRepo: withEmma(),
      );
      await go(tester, '/g/y/roster/players/gone');
      expect(
        find.text("This player isn't on the team anymore."),
        findsOneWidget,
      );
    });
  });

  group('roster details and contact sharing (TEAM-10)', () {
    final people = [
      testMembership('y', 'coach', role: MemberRole.owner, name: 'Jordan'),
      testMembership('y', 'maria', name: 'Maria Rodriguez'),
      testMembership('y', 'ann', role: MemberRole.admin, name: 'Ann Admin'),
    ];
    FakePlayerRepository threePlayers() => FakePlayerRepository([
      emma,
      const Player(
        id: PlayerId('zed'),
        groupId: GroupId('y'),
        displayName: 'Zed Adams',
        jerseyNumber: '2',
      ),
      const Player(
        id: PlayerId('amy'),
        groupId: GroupId('y'),
        displayName: 'Amy Zhou',
      ),
    ]);

    /// The players' names in the order they're on screen.
    List<String> playerOrder(WidgetTester tester) {
      final names = ['Zed Adams', 'Emma Rodriguez', 'Amy Zhou'];
      return names.toList()..sort(
        (a, b) => tester
            .getTopLeft(find.text(a))
            .dy
            .compareTo(tester.getTopLeft(find.text(b)).dy),
      );
    }

    testWidgets('players by number, or by name; people by name, owner first', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youth,
        memberships: people,
        playerRepo: threePlayers(),
      );
      await go(tester, '/g/y/roster');
      // By number, players without one last.
      expect(playerOrder(tester), ['Zed Adams', 'Emma Rodriguez', 'Amy Zhou']);
      final owner = tester.getTopLeft(find.text('Jordan')).dy;
      expect(owner, lessThan(tester.getTopLeft(find.text('Ann Admin')).dy));

      await tester.tap(find.byTooltip('Sort players'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('By name'));
      await tester.pumpAndSettle();
      expect(playerOrder(tester), ['Amy Zhou', 'Emma Rodriguez', 'Zed Adams']);
    });

    testWidgets('I share my phone and email; the team can call, text, and '
        'email me', (tester) async {
      final members = FakeMemberRepository([...people]);
      final links = FakeLinkOpener();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youth,
        memberRepo: members,
        linkOpener: links,
      );
      await go(tester, '/g/y/roster');
      await tester.tap(find.text('Jordan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share my phone and email'));
      await tester.pumpAndSettle();
      // The account's email is offered.
      expect(find.text('coach@example.com'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'),
        '(555) 010-0199',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(members.calls, ['contact coach (555) 010-0199 coach@example.com']);
      expect(find.text('Shared with the team'), findsOneWidget);
      // The card shows them at once, with the buttons.
      expect(find.text('(555) 010-0199'), findsOneWidget);
      await tester.tap(find.byTooltip('Text Jordan'));
      await tester.tap(find.byTooltip('Call Jordan'));
      await tester.tap(find.byTooltip('Email Jordan'));
      expect(links.opened.map((u) => u.toString()), [
        'sms:5550100199',
        'tel:5550100199',
        'mailto:coach@example.com',
      ]);

      // Stop sharing from the same place.
      await tester.tap(find.text('Edit my phone and email'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop sharing'));
      await tester.pumpAndSettle();
      expect(members.calls.last, 'contact coach null null');
      expect(find.text('(555) 010-0199'), findsNothing);
    });

    testWidgets("someone else's card shows what they share, and nothing to "
        'edit', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youth,
        memberships: [
          people.first,
          people[1].copyWith(contactEmail: 'maria@example.com'),
        ],
      );
      await go(tester, '/g/y/roster');
      await tester.tap(find.text('Maria Rodriguez'));
      await tester.pumpAndSettle();
      expect(find.text('maria@example.com'), findsOneWidget);
      expect(find.byTooltip('Email Maria Rodriguez'), findsOneWidget);
      // No phone shared, so no call or text.
      expect(find.byTooltip('Call Maria Rodriguez'), findsNothing);
      expect(find.text('Share my phone and email'), findsNothing);
    });

    testWidgets('bad entries are caught before saving', (tester) async {
      final members = FakeMemberRepository([...people]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youth,
        memberRepo: members,
      );
      await go(tester, '/g/y/roster');
      await tester.tap(find.text('Jordan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share my phone and email'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'),
        'call me',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'not an email',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a phone number, up to 30 characters'), findsOne);
      expect(find.text('Enter an email address'), findsOneWidget);
      expect(members.calls, isEmpty);
    });

    testWidgets('on an archived team I can only stop sharing', (tester) async {
      final members = FakeMemberRepository([
        people.first.copyWith(contactPhone: '555 0100'),
        people[1],
      ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          'y': testGroup(
            'y',
            'Lightning U10',
          ).copyWith(archivedAt: DateTime(2026)),
        },
        memberRepo: members,
      );
      await go(tester, '/g/y/roster');
      await tester.tap(find.text('Jordan'));
      await tester.pumpAndSettle();
      expect(find.text('Edit my phone and email'), findsNothing);
      await tester.tap(find.text('Stop sharing'));
      await tester.pumpAndSettle();
      expect(members.calls, ['contact coach null null']);
    });
  });

  group('joining (INV-5, INV-7)', () {
    testWidgets('people already on the team go straight to it', (tester) async {
      final invites = FakeInviteRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach')],
        invites: invites,
      );
      await go(tester, '/join/K7XPM2QR');
      expect(find.text('Join team'), findsNothing);
      expect(find.byTooltip('Add photos or a poll'), findsOneWidget);
      expect(invites.redeemed, isEmpty);
    });

    testWidgets('a signed-out visitor signs in with email and joins', (
      tester,
    ) async {
      final invites = FakeInviteRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(),
        groups: {'a': testGroup('a', 'Thunder')},
        invites: invites,
      );
      await go(tester, '/join/K7XPM2QR');
      await tester.tap(find.text('Sign in to join'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with email'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'coach@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(invites.redeemed, ['K7XPM2QR']);
    });

    testWidgets('a new account goes on to the invite after setup', (
      tester,
    ) async {
      final users = FakeUserRepository(needsSetup: true);
      final invites = FakeInviteRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(),
        users: users,
        invites: invites,
      );
      await go(tester, '/join/K7XPM2QR');
      await tester.tap(find.text('Sign in to join'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.textContaining('set up your profile'), findsOneWidget);
      await tester.tap(find.text("I'm 18 or older"));
      await tester.tap(find.textContaining('I agree to the Terms'));
      await tester.pumpAndSettle();
      final next = find.widgetWithText(FilledButton, 'Continue');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(invites.redeemed, ['K7XPM2QR']);
    });

    testWidgets('the preview shows the logo; a browser offers Open in app', (
      tester,
    ) async {
      final invites = FakeInviteRepository()
        ..previewed = const InvitePreview(
          groupId: 'a',
          name: 'Thunder',
          sport: Sport.softball,
          memberCount: 12,
          logoUrl: 'https://example.com/logo.jpg',
        );
      final opener = FakeLinkOpener();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(),
        invites: invites,
        linkOpener: opener,
      );
      await go(tester, '/join/K7XPM2QR');
      // Not a browser here: Sign in to join, no Open in app.
      expect(find.text('Open in app'), findsNothing);
      expect(find.text('Sign in to join'), findsOneWidget);
      final badge = tester.widget<TeamBadge>(find.byType(TeamBadge));
      expect(badge.imageUrl, 'https://example.com/logo.jpg');

      // In a browser: Open in app, and Join as Continue in browser.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            inviteRepositoryProvider.overrideWithValue(invites),
            linkOpenerProvider.overrideWithValue(opener),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: JoinScreen(code: 'K7XPM2QR', inBrowser: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue in browser'), findsOneWidget);
      await tester.tap(find.text('Open in app'));
      await tester.pump();
      expect(opener.opened.single.path, '/join/K7XPM2QR');
    });

    test('Open in app uses the app link, or an intent on Android', () {
      final page = Uri.parse('https://getbattleplan.app/app/join/K7XPM2QR');
      expect(
        JoinScreen.openInAppLink(page, 'K7XPM2QR', android: false).toString(),
        'https://getbattleplan.app/join/K7XPM2QR',
      );
      final intent = JoinScreen.openInAppLink(
        page,
        'K7XPM2QR',
        android: true,
      ).toString();
      expect(
        intent,
        startsWith('intent://getbattleplan.app/join/K7XPM2QR#Intent;'),
      );
      expect(intent, contains('scheme=https'));
      expect(intent, contains(Uri.encodeComponent(page.toString())));
    });
  });

  group('live pages (TEAM-3, PLAYER-6 on big teams)', () {
    test('reads every page, and follows changes to any of them', () async {
      final pages = <String?, StreamController<LivePage<int, String>>>{};
      final stream = livePages<int, String>(
        (after) => (pages[after] = StreamController()).stream,
      );
      final seen = <List<int>>[];
      final sub = stream.listen(seen.add);
      await Future<void>.delayed(Duration.zero);
      pages[null]!.add((items: [1, 2], next: 'p1'));
      await Future<void>.delayed(Duration.zero);
      expect(seen, isEmpty); // waits for page 2
      pages['p1']!.add((items: [3], next: null));
      await Future<void>.delayed(Duration.zero);
      expect(seen.last, [1, 2, 3]);
      pages['p1']!.add((items: [3, 4], next: null));
      await Future<void>.delayed(Duration.zero);
      expect(seen.last, [1, 2, 3, 4]);
      // The first page's end moves: later pages start over from it.
      pages[null]!.add((items: [1], next: null));
      await Future<void>.delayed(Duration.zero);
      expect(seen.last, [1]);
      await sub.cancel();
    });
  });
}
