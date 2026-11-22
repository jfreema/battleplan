// A new team opens with its next steps (owner's go 2026-11-16, "do #3";
// SPEC TEAM-1, TEAM-14, CHAT-1, SCHED-1, §5.3, §7.5): the setup card at the
// top of a new team's chat for its admins, ticking itself off, and one
// labeled next step on the empty Chat, Schedule and Team tabs.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/domain/team_setup.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/contrast.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const sam = AuthUser(
    uid: 'sam',
    email: 'sam@example.com',
    emailVerified: true,
  );

  // A Thursday afternoon, three days after Hornets was made.
  final now = DateTime.utc(2026, 11, 20, 20);
  final made = DateTime.utc(2026, 11, 17, 18);

  /// Hornets, made this week, with only its owner on it.
  final hornets = testGroup(
    'a',
    'Hornets',
  ).copyWith(memberCount: 1, createdAt: made);

  const ready = 'Hornets is ready';
  const title = 'Get Hornets ready';
  const importLink = 'Coming from TeamSnap or GroupMe? Import your team';

  Membership owner({bool setupClosed = false}) => testMembership(
    'a',
    'coach',
    role: MemberRole.owner,
    name: 'Coach Kim',
  ).copyWith(setupClosed: setupClosed);

  Event event(String id, DateTime start) => Event(
    id: EventId(id),
    groupId: const GroupId('a'),
    type: EventType.practice,
    title: 'Practice',
    startAt: start,
    endAt: start.add(const Duration(minutes: 90)),
    timeZone: 'America/Chicago',
    createdBy: 'coach',
  );

  /// The app as [user], opening in the team's chat (or on [route]).
  Future<
    ({
      FakeGroupRepository groups,
      FakeMemberRepository members,
      FakeEventRepository events,
    })
  >
  open(
    WidgetTester tester, {
    Group? group,
    List<Membership>? members,
    AuthUser user = coach,
    List<Event> events = const [],
    List<Message> messages = const [],
    String? route,
    Size size = const Size(390, 844),
  }) async {
    final groups = FakeGroupRepository({'a': group ?? hornets});
    final memberRepo = FakeMemberRepository(members ?? [owner()]);
    final eventRepo = FakeEventRepository(events);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: user),
      prefs: route == null ? null : (FakeLocalPrefs()..lastTeamRoute = route),
      groupRepo: groups,
      memberRepo: memberRepo,
      eventRepo: eventRepo,
      messageRepo: FakeMessageRepository([...messages]),
      size: size,
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    return (groups: groups, members: memberRepo, events: eventRepo);
  }

  /// Where the router is, pushed screens included.
  String location(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Navigator).first)).state.uri
          .toString();

  /// What a screen reader hears for the step called [name].
  Finder step(String label) => find.bySemanticsLabel(RegExp('^$label'));

  group('which teams get it', () {
    test('made since it shipped, for its first 30 days', () {
      Group team(DateTime? at) =>
          testGroup('a', 'Hornets').copyWith(createdAt: at);
      expect(team(null).inSetupWindow(now), isFalse);
      // Made the evening before it shipped, in Chicago.
      expect(team(DateTime.utc(2026, 11, 17, 5)).inSetupWindow(now), isFalse);
      expect(team(setupCardSince).inSetupWindow(now), isTrue);
      final day29 = made.add(const Duration(days: 29, hours: 23));
      expect(team(made).inSetupWindow(day29), isTrue);
      expect(
        team(made).inSetupWindow(made.add(const Duration(days: 30))),
        isFalse,
      );
      expect(team(made).copyWith(archivedAt: now).inSetupWindow(now), isFalse);
      expect(team(made).copyWith(suspendedAt: now).inSetupWindow(now), isFalse);
      expect(
        team(made).copyWith(kind: GroupKind.direct).inSetupWindow(now),
        isFalse,
      );
    });

    test('its steps, in order, the next one, and when it is ready', () {
      const fresh = (
        group: false,
        players: false,
        invited: false,
        event: false,
      );
      expect(fresh.steps, SetupStep.values);
      expect(fresh.next, SetupStep.players);
      expect(fresh.ready, isFalse);
      const twoDone = (
        group: false,
        players: true,
        invited: false,
        event: true,
      );
      expect(twoDone.next, SetupStep.invite);
      const all = (group: false, players: true, invited: true, event: true);
      expect(all.next, isNull);
      expect(all.ready, isTrue);
      // A group has no players step.
      const group = (group: true, players: false, invited: true, event: true);
      expect(group.steps, [SetupStep.invite, SetupStep.event]);
      expect(group.ready, isTrue);
    });
  });

  group('the card at the top of a new team’s chat', () {
    testWidgets('its owner gets three steps and Import, in the empty chat’s '
        'place, players before inviting', (tester) async {
      await open(tester);
      expect(location(tester), '/g/a/chat');
      expect(find.text(title), findsOneWidget);
      expect(find.byType(TeamSetupCard), findsOneWidget);
      final players = tester.getTopLeft(find.text('Add your players')).dy;
      final invite = tester.getTopLeft(find.text('Invite families')).dy;
      final first = tester
          .getTopLeft(find.text('Add your first practice or game'))
          .dy;
      expect(players, lessThan(invite));
      expect(invite, lessThan(first));
      expect(
        find.text('So parents can pick theirs when they join'),
        findsOneWidget,
      );
      expect(find.text('Share the link or QR code'), findsOneWidget);
      expect(find.text(importLink), findsOneWidget);
      // One Invite on the screen: the card replaces the empty chat's.
      expect(find.text('No messages yet. Say hi to the team!'), findsNothing);
      expect(find.text('Only you so far. Invite your team.'), findsNothing);
      // Right under the header, above the composer.
      expect(
        tester.getTopLeft(find.text(title)).dy,
        lessThan(tester.getTopLeft(find.byTooltip('Add photos or a poll')).dy),
      );
    });

    testWidgets('not for a member, a super admin viewing, a team over 30 days '
        'old, or one made before it shipped', (tester) async {
      final members = [owner(), testMembership('a', 'sam', name: 'Sam Lee')];
      await open(tester, user: sam, members: members);
      expect(find.text(title), findsNothing);
      expect(find.text('No messages yet. Say hi to the team!'), findsOneWidget);

      await open(
        tester,
        user: const AuthUser(
          uid: 'boss',
          email: 'boss@example.com',
          emailVerified: true,
          isSuperAdmin: true,
        ),
        members: [owner()],
      );
      GoRouter.of(tester.element(find.byType(Navigator).first)).go('/g/a/chat');
      await tester.pumpAndSettle();
      expect(find.textContaining('Viewing as super admin'), findsWidgets);
      expect(find.text(title), findsNothing);

      await open(
        tester,
        group: hornets.copyWith(
          createdAt: now.subtract(const Duration(days: 31)),
        ),
      );
      expect(find.text(title), findsNothing);
      // Still alone on it: the empty chat's own Invite.
      expect(find.text('Only you so far. Invite your team.'), findsOneWidget);

      await open(
        tester,
        group: hornets.copyWith(createdAt: DateTime.utc(2026, 10)),
      );
      expect(find.text(title), findsNothing);
    });

    testWidgets('each step ticks itself off as the team gets it, and '
        '"Hornets is ready" is put away for good once shown', (tester) async {
      final app = await open(tester);
      expect(step('Add your players, not done'), findsOneWidget);
      expect(step('Invite families, not done'), findsOneWidget);

      // A player added, or brought in by an import.
      app.groups.setGroup(hornets.copyWith(playerCount: 1));
      await tester.pumpAndSettle();
      expect(step('Add your players, done'), findsOneWidget);
      expect(step('Invite families, not done'), findsOneWidget);

      // Someone joined.
      app.groups.setGroup(hornets.copyWith(playerCount: 1, memberCount: 2));
      await tester.pumpAndSettle();
      expect(step('Invite families, done'), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(app.members.calls, isEmpty);

      // An event saved: every step done.
      app.events.put(event('e1', now.add(const Duration(days: 2))));
      await tester.pumpAndSettle();
      expect(find.text(ready), findsOneWidget);
      expect(step('Add your first practice or game, done'), findsOneWidget);
      expect(find.text(importLink), findsNothing);
      expect(find.byTooltip('Hide setup'), findsNothing);
      // Saved as closed as soon as it says so, so leaving the chat puts it
      // away; it stays until then.
      expect(app.members.calls, ['setupClosed a']);
      expect(find.text(ready), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();
      expect(find.byType(TeamSetupCard), findsNothing);
    });

    testWidgets('a past event ticks the last step too', (tester) async {
      await open(
        tester,
        events: [event('old', now.subtract(const Duration(days: 1)))],
      );
      expect(step('Add your first practice or game, done'), findsOneWidget);
      expect(step('Add your players, not done'), findsOneWidget);
    });

    testWidgets('the X puts it away, and it stays away after a restart', (
      tester,
    ) async {
      final app = await open(tester);
      await tester.tap(find.byTooltip('Hide setup'));
      await tester.pumpAndSettle();
      expect(app.members.calls, ['setupClosed a']);
      expect(find.byType(TeamSetupCard), findsNothing);
      // The empty chat's Invite instead.
      expect(find.text('Only you so far. Invite your team.'), findsOneWidget);

      // A restart, with the saved membership.
      await open(tester, members: [owner(setupClosed: true)]);
      expect(find.byType(TeamSetupCard), findsNothing);
    });

    testWidgets('Done stays away after a restart too', (tester) async {
      final app = await open(
        tester,
        group: hornets.copyWith(playerCount: 3, memberCount: 4),
        events: [event('e1', now.add(const Duration(days: 1)))],
      );
      expect(find.text(ready), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();
      expect(find.byType(TeamSetupCard), findsNothing);
      expect(app.members.memberships.single.setupClosed, isTrue);

      await open(
        tester,
        group: hornets.copyWith(playerCount: 3, memberCount: 4),
        members: [app.members.memberships.single],
      );
      expect(find.byType(TeamSetupCard), findsNothing);
    });

    testWidgets('a group gets two steps in group words', (tester) async {
      await open(
        tester,
        group: hornets.copyWith(name: 'Book club', kind: GroupKind.group),
      );
      expect(find.text('Get Book club ready'), findsOneWidget);
      expect(find.text('Add your players'), findsNothing);
      expect(find.text('Invite people'), findsOneWidget);
      expect(find.text('Add your first event'), findsOneWidget);
      expect(find.text('Coming from GroupMe? Import'), findsOneWidget);
    });

    testWidgets('each step opens its screen, and comes back to the chat', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Add your players'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/players/add');
      expect(find.text('Chat'), findsWidgets);
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/chat');

      await tester.tap(find.text('Invite families'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/invite');
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text(importLink));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/import');
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add your first practice or game'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/schedule/new');
    });

    testWidgets('with storage full, the event step says why', (tester) async {
      await open(
        tester,
        group: hornets.copyWith(storageBytes: 300, storageQuotaBytes: 200),
      );
      await tester.tap(find.text('Add your first practice or game'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/chat');
      expect(find.textContaining('Storage is full'), findsWidgets);
    });

    testWidgets('once the chat has messages, it sits above the first one', (
      tester,
    ) async {
      await open(
        tester,
        messages: [
          Message(
            id: 'm1',
            groupId: const GroupId('a'),
            authorId: 'coach',
            authorName: 'Coach Kim',
            type: MessageType.text,
            text: 'Welcome, Hornets!',
            createdAt: now.subtract(const Duration(minutes: 5)),
          ),
        ],
      );
      expect(find.text(title), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(TeamSetupCard)).dy,
        lessThan(tester.getTopLeft(find.text('Welcome, Hornets!')).dy),
      );
    });

    testWidgets('reads well: a heading, done or not done, 48 px targets, '
        'contrast, and 200% text', (tester) async {
      final handle = tester.ensureSemantics();
      final app = await open(tester);
      app.groups.setGroup(hornets.copyWith(playerCount: 2));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text(title)),
        matchesSemantics(label: title, isHeader: true),
      );
      expect(
        find.bySemanticsLabel(
          'Add your players, done, So parents can pick theirs when they join',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Invite families, not done, Share the link or QR code',
        ),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();

      for (final width in [320.0, 360.0]) {
        await open(tester, size: Size(width, 700));
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(title), findsOneWidget);
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      }
    });
  });

  group('the empty chat', () {
    testWidgets('an admin alone on the team is asked to invite it', (
      tester,
    ) async {
      await open(tester, members: [owner(setupClosed: true)]);
      expect(find.text('Only you so far. Invite your team.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Invite'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/invite');
    });

    testWidgets('a group says "Invite people"; with others on it, everyone '
        'is asked to say hi', (tester) async {
      await open(
        tester,
        group: hornets.copyWith(kind: GroupKind.group),
        members: [owner(setupClosed: true)],
      );
      expect(find.text('Only you so far. Invite people.'), findsOneWidget);

      await open(
        tester,
        group: hornets.copyWith(memberCount: 2),
        members: [owner(setupClosed: true)],
      );
      expect(find.text('No messages yet. Say hi to the team!'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Invite'), findsNothing);
    });
  });

  group('the empty Schedule', () {
    Future<void> toSchedule(WidgetTester tester) async {
      await tester.tap(find.text('Schedule').last);
      await tester.pumpAndSettle();
    }

    testWidgets('an admin gets Add an event and a quiet Import a schedule', (
      tester,
    ) async {
      await open(tester, members: [owner(setupClosed: true)]);
      await toSchedule(tester);
      expect(find.text('No upcoming events.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add an event'), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Import a schedule'),
        findsOneWidget,
      );
      await tester.tap(find.text('Import a schedule'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/import');
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add an event'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/schedule/new');
    });

    testWidgets('Add an event with full storage says why', (tester) async {
      await open(
        tester,
        group: hornets.copyWith(storageBytes: 300, storageQuotaBytes: 200),
        members: [owner(setupClosed: true)],
      );
      await toSchedule(tester);
      await tester.tap(find.text('Add an event'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/schedule');
      expect(find.textContaining('Storage is full'), findsWidgets);
    });

    testWidgets('a member who can add events gets the button without Import; '
        "one who can't is told who will", (tester) async {
      final members = [owner(), testMembership('a', 'sam', name: 'Sam Lee')];
      await open(
        tester,
        user: sam,
        members: members,
        group: hornets.copyWith(
          memberCount: 2,
          settings: const GroupSettings(membersCanCreateEvents: true),
        ),
      );
      await toSchedule(tester);
      expect(find.text('Add an event'), findsOneWidget);
      expect(find.text('Import a schedule'), findsNothing);

      await open(
        tester,
        user: sam,
        members: members,
        group: hornets.copyWith(memberCount: 2),
      );
      await toSchedule(tester);
      expect(
        find.text('No upcoming events. Your coaches will add them here.'),
        findsOneWidget,
      );
      expect(find.text('Add an event'), findsNothing);

      await open(
        tester,
        user: sam,
        members: members,
        group: hornets.copyWith(memberCount: 2, kind: GroupKind.group),
      );
      await toSchedule(tester);
      expect(
        find.text('No upcoming events. Admins will add them here.'),
        findsOneWidget,
      );
    });

    testWidgets('Past just says there is nothing', (tester) async {
      await open(tester, members: [owner(setupClosed: true)]);
      await toSchedule(tester);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('No past events.'), findsOneWidget);
      expect(find.text('Add an event'), findsNothing);
    });
  });

  group('the empty Team tab', () {
    Future<void> toTeam(WidgetTester tester) async {
      await tester.tap(find.text('Team').last);
      await tester.pumpAndSettle();
    }

    testWidgets('admins get Add your players under Players, below the card', (
      tester,
    ) async {
      await open(tester, members: [owner(setupClosed: true)]);
      await toTeam(tester);
      expect(find.text('No players yet.'), findsOneWidget);
      final button = find.widgetWithText(FilledButton, 'Add your players');
      expect(button, findsOneWidget);
      // Inline, under the team's card and its Invite.
      expect(
        tester.getTopLeft(button).dy,
        greaterThan(tester.getTopLeft(find.text('Invite').first).dy),
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(location(tester), '/g/a/players/add');
    });

    testWidgets('members get Add your player', (tester) async {
      await open(
        tester,
        user: sam,
        members: [
          owner(),
          testMembership('a', 'sam', name: 'Sam Lee'),
        ],
        group: hornets.copyWith(memberCount: 2),
      );
      await toTeam(tester);
      expect(
        find.widgetWithText(FilledButton, 'Add your player'),
        findsOneWidget,
      );
      expect(find.text('Add your players'), findsNothing);
    });
  });
}
