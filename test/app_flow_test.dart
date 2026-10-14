import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/domain/media.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );

  testWidgets('signed out lands on sign-in with Google and email; Apple stays '
      'hidden until Phase 3 (task 187)', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Continue with email'), findsOneWidget);
  });

  testWidgets('sign-in links the Terms of Use and Privacy Policy (LEGAL-1)', (
    tester,
  ) async {
    final links = FakeLinkOpener();
    await pumpApp(tester, auth: FakeAuthRepository(), linkOpener: links);
    await tester.tap(find.widgetWithText(TextButton, 'Terms of Use'));
    await tester.tap(find.widgetWithText(TextButton, 'Privacy Policy'));
    await tester.pumpAndSettle();
    expect(links.opened.map((u) => u.path), ['/terms', '/privacy']);
  });

  testWidgets(
    'email sign-in reaches the welcome screen when there are no teams',
    (tester) async {
      await pumpApp(tester, auth: FakeAuthRepository());
      await tester.tap(find.text('Continue with email'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'coach@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Battleplan'), findsOneWidget);
    },
  );

  testWidgets('email sign-in opens the team when there is one', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach')],
    );
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'coach@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Thunder'), findsOneWidget);
    expect(find.text('Welcome to Battleplan'), findsNothing);
  });

  testWidgets('Google sign-in reaches the app', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Battleplan'), findsOneWidget);
  });

  testWidgets('cancelling Google sign-in stays on sign-in with no error', (
    tester,
  ) async {
    await pumpApp(tester, auth: FakeAuthRepository()..googleCancels = true);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.textContaining('went wrong'), findsNothing);
  });

  testWidgets('creating an account signs the person in', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Sam Rivera');
    await tester.enterText(find.byType(TextField).at(1), 'sam@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'longenough');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Battleplan'), findsOneWidget);
    // AUTH-3: the new email account sees the verification banner.
    expect(find.textContaining('Verify your email'), findsOneWidget);
  });

  testWidgets('password reset always shows the same confirmation', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, auth: auth);
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'nobody@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset password'), findsOneWidget);
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(auth.resetEmails, ['nobody@example.com']);
    expect(find.textContaining('If an account exists'), findsOneWidget);
  });

  testWidgets('a short password is caught before sending', (tester) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, auth: auth);
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Sam Rivera');
    await tester.enterText(find.byType(TextField).at(1), 'sam@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('at least 8 characters'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('an email that already has an account says so', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Jordan');
    await tester.enterText(find.byType(TextField).at(1), 'coach@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'longenough');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('already an account'), findsOneWidget);
  });

  testWidgets('first-run setup comes first and needs both confirmations', (
    tester,
  ) async {
    final users = FakeUserRepository(needsSetup: true);
    final links = FakeLinkOpener();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      users: users,
      linkOpener: links,
    );
    expect(find.textContaining('set up your profile'), findsOneWidget);
    // The Terms and Privacy Policy can be read before agreeing (SAFE-3).
    await tester.tap(find.widgetWithText(TextButton, 'Terms of Use'));
    await tester.tap(find.widgetWithText(TextButton, 'Privacy Policy'));
    await tester.pumpAndSettle();
    expect(links.opened.map((u) => u.path), ['/terms', '/privacy']);
    final next = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.tap(find.text("I'm 18 or older"));
    await tester.tap(find.textContaining('I agree to the Terms'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(users.savedName, 'Jordan Coach');
    expect(find.text('Welcome to Battleplan'), findsOneWidget);
  });

  testWidgets('after creating a team, Continue leads from the invite screen '
      'into the team', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
    );
    // Creating a team replaces the stack with its invite screen, so there's
    // no back button (TEAM-1).
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/g/a/invite');
    await tester.pumpAndSettle();
    final go = find.widgetWithText(FilledButton, 'Continue to Thunder');
    expect(go, findsOneWidget);
    await tester.tap(go);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add photos or a poll'), findsOneWidget);

    // Opened from the team menu, the screen has Back instead.
    await tester.tap(find.byTooltip('Team menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite').last);
    await tester.pumpAndSettle();
    expect(find.text('Continue to Thunder'), findsNothing);
  });

  testWidgets('creating a team from the welcome screen', (tester) async {
    final groupRepo = FakeGroupRepository({});
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groupRepo,
    );
    await tester.tap(find.text('Create a team'));
    await tester.pumpAndSettle();
    // One team type: nothing to pick (TEAM-1).
    expect(find.text('Team type'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, 'Thunder U14');
    await tester.pumpAndSettle();
    final create = find.widgetWithText(FilledButton, 'Create a team');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(groupRepo.created, ['Thunder U14']);
    // TEAM-1: the next screen is "Invite your team" (the fake team has no
    // membership yet, so the shell guard shows instead).
  });

  testWidgets('a team needs a name', (tester) async {
    final groupRepo = FakeGroupRepository({});
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groupRepo,
    );
    await tester.tap(find.text('Create a team'));
    await tester.pumpAndSettle();
    final create = find.widgetWithText(FilledButton, 'Create a team');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text('Enter a team name.'), findsOneWidget);
    expect(groupRepo.created, isEmpty);
  });

  testWidgets('roster: the owner can make a member an admin', (tester) async {
    final members = FakeMemberRepository([
      testMembership('a', 'coach', role: MemberRole.owner, name: 'Jordan'),
      testMembership('a', 'sam', name: 'Sam Rivera'),
    ]);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberRepo: members,
    );
    await tester.tap(find.byTooltip('Team menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roster'));
    await tester.pumpAndSettle();
    expect(find.text('Admins'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    await tester.tap(find.text('Sam Rivera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make admin'));
    await tester.pumpAndSettle();
    expect(members.calls, ['update sam admin']);
  });

  testWidgets('roster: an admin cannot remove another admin', (tester) async {
    final members = FakeMemberRepository([
      testMembership('a', 'owner', role: MemberRole.owner, name: 'Olive'),
      testMembership('a', 'coach', role: MemberRole.admin, name: 'Jordan'),
      testMembership('a', 'alex', role: MemberRole.admin, name: 'Alex Kim'),
    ]);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberRepo: members,
    );
    await tester.tap(find.byTooltip('Team menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roster'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex Kim'));
    await tester.pumpAndSettle();
    expect(find.text('Remove admin'), findsNothing);
    expect(find.text('Remove from team'), findsNothing);
    expect(find.text('Edit title'), findsOneWidget);
  });

  testWidgets('team settings: an admin turns a member permission on', (
    tester,
  ) async {
    final groupRepo = FakeGroupRepository({'a': testGroup('a', 'Thunder')});
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groupRepo,
      memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
    );
    await tester.tap(find.byTooltip('Team menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team settings'));
    await tester.pumpAndSettle();
    final perm = find.text('Members can create events');
    await tester.ensureVisible(perm);
    await tester.tap(perm);
    await tester.pumpAndSettle();
    expect(groupRepo.updates, ['settings']);
    expect(groupRepo.groups['a']!.settings.membersCanCreateEvents, isTrue);
  });

  testWidgets('the owner is told to transfer before leaving', (tester) async {
    final groupRepo = FakeGroupRepository({'a': testGroup('a', 'Thunder')})
      ..callerIsOwner = true;
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groupRepo,
      memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
    );
    await tester.tap(find.byTooltip('Team menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave team'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Leave team'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Transfer ownership'), findsOneWidget);
  });

  testWidgets('deleting a team needs its exact name', (tester) async {
    final groupRepo = FakeGroupRepository({'a': testGroup('a', 'Thunder')});
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groupRepo,
      memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
    );
    await tester.tap(find.byTooltip('Team menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team settings'));
    await tester.pumpAndSettle();
    final delete = find.text('Delete team');
    await tester.scrollUntilVisible(
      delete,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Thunder');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(groupRepo.updates, ['delete Thunder']);
  });

  testWidgets('invite screen: code, QR, and an admin reset', (tester) async {
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
    expect(find.text('K7XP-M2QR'), findsOneWidget);
    expect(find.text('Show QR code'), findsOneWidget);
    final reset = find.widgetWithText(OutlinedButton, 'Reset link');
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset link'));
    await tester.pumpAndSettle();
    expect(invites.resets, 1);
  });

  testWidgets('email invites: send, list, and revoke (INV-4)', (tester) async {
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
    await tester.tap(find.text('Email invites'));
    await tester.pumpAndSettle();
    expect(find.text('No email invites yet.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).first,
      'Sam@Example.com, alex@example.com sam@example.com',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send 2 invites'));
    await tester.pumpAndSettle();
    expect(invites.sent.map((i) => i.email), [
      'alex@example.com',
      'sam@example.com',
    ]);
    expect(find.text('Pending'), findsNWidgets(2));
    final revoke = find.widgetWithText(TextButton, 'Revoke').first;
    await tester.ensureVisible(revoke);
    await tester.tap(revoke);
    await tester.pumpAndSettle();
    expect(invites.sent.first.status, EmailInviteStatus.revoked);
    expect(find.text('Revoked'), findsOneWidget);
  });

  testWidgets('joining a team by typing its code', (tester) async {
    final invites = FakeInviteRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      invites: invites,
    );
    await tester.tap(find.text('Join a team'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'k7xp-m2qr');
    await tester.tap(find.widgetWithText(FilledButton, 'Join team'));
    await tester.pumpAndSettle();
    expect(find.text('Thunder'), findsOneWidget);
    expect(find.text('Invited by Alex Kim'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Join team'));
    await tester.pumpAndSettle();
    expect(invites.redeemed, ['K7XPM2QR']);
    // Every team asks next (PLAYER-3).
    expect(find.text('Who are you here for?'), findsOneWidget);
    expect(find.text("I'm a player"), findsOneWidget);
  });

  testWidgets('someone already on the team skips "Who are you here for?"', (
    tester,
  ) async {
    final invites = FakeInviteRepository()..joinedAlready = true;
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      invites: invites,
    );
    await tester.tap(find.text('Join a team'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'k7xp-m2qr');
    await tester.tap(find.widgetWithText(FilledButton, 'Join team'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Join team'));
    await tester.pumpAndSettle();
    expect(invites.redeemed, ['K7XPM2QR']);
    expect(find.text('Who are you here for?'), findsNothing);
  });

  testWidgets('people an admin already linked skip "Who are you here for?"', (
    tester,
  ) async {
    final players =
        FakePlayerRepository([
            const Player(
              id: PlayerId('emma'),
              groupId: GroupId('a'),
              displayName: 'Emma',
            ),
          ])
          ..links.add(
            const GuardianLink(
              playerId: PlayerId('emma'),
              groupId: GroupId('a'),
              uid: UserId('coach'),
            ),
          );
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach')],
      playerRepo: players,
    );
    unawaited(
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/g/a/who'),
    );
    await tester.pumpAndSettle();
    expect(find.text("I'm a player"), findsNothing);
    expect(find.byTooltip('Add photos or a poll'), findsOneWidget);
  });

  testWidgets('a wrong code explains what to do', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository(user: coach));
    await tester.tap(find.text('Join a team'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ZZZZ-ZZZZ');
    await tester.tap(find.widgetWithText(FilledButton, 'Join team'));
    await tester.pumpAndSettle();
    expect(find.textContaining("couldn't find that invite"), findsOneWidget);
  });

  testWidgets('every roster has players, and admins paste a roster', (
    tester,
  ) async {
    final playerRepo = FakePlayerRepository([
      const Player(
        id: PlayerId('emma'),
        groupId: GroupId('y'),
        displayName: 'Emma Rodriguez',
        jerseyNumber: '7',
      ),
    ]);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'y': testGroup('y', 'Lightning U10')},
      memberships: [testMembership('y', 'coach', role: MemberRole.owner)],
      playerRepo: playerRepo,
    );
    await tester.tap(find.byTooltip('Team menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roster'));
    await tester.pumpAndSettle();
    expect(find.text('Players'), findsOneWidget);
    expect(find.text('Emma Rodriguez'), findsOneWidget);
    await tester.tap(find.text('Add players'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paste a list'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Arjun Shah, Priya Shah, priya@example.com\n'
      'Noah Bennett, Ann Bennett, ann@example.com\n'
      'Noah Bennett, Bo Bennett, bo@example.com',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add 2 players'));
    await tester.pumpAndSettle();
    expect(playerRepo.added.single.map((p) => p.name), [
      'Arjun Shah',
      'Noah Bennett',
    ]);
    expect(find.text('Players added'), findsOneWidget);
  });

  testWidgets('adding guardians by email asks for a verified email first '
      '(SAFE-5)', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'y': testGroup('y', 'Lightning U10')},
      memberships: [testMembership('y', 'coach', role: MemberRole.owner)],
      playerRepo: RefusingPlayerRepository(const EmailNotVerified()),
    );
    await tester.tap(find.byTooltip('Team menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roster'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add players'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paste a list'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Arjun Shah, Priya Shah, priya@example.com',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add 1 player'));
    await tester.pumpAndSettle();
    expect(
      find.text('Verify your email first, then you can add people by email.'),
      findsOneWidget,
    );
  });

  group('players, claims, and approvals (PLAYER-3 to PLAYER-5)', () {
    final team = {'y': testGroup('y', 'Lightning U10')};
    FakePlayerRepository emmaTeam() => FakePlayerRepository([
      const Player(
        id: PlayerId('emma'),
        groupId: GroupId('y'),
        displayName: 'Emma Rodriguez',
        jerseyNumber: '7',
      ),
    ]);

    Future<void> openRoster(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Team menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Roster'));
      await tester.pumpAndSettle();
    }

    Future<void> go(WidgetTester tester, String path) async {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
      await tester.pumpAndSettle();
    }

    Future<void> openWho(WidgetTester tester) async {
      await openRoster(tester);
      await tester.tap(find.text('Who are you here for?'));
      await tester.pumpAndSettle();
    }

    testWidgets('a parent asks to be linked to their player', (tester) async {
      final playerRepo = emmaTeam();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('y', 'coach')],
        playerRepo: playerRepo,
      );
      await openWho(tester);
      expect(find.text("I'm a player"), findsOneWidget);
      expect(find.text("I'm a coach or another adult"), findsOneWidget);
      await tester.tap(find.text("I'm here for a player"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emma Rodriguez'));
      await tester.pump();
      await tester.tap(find.text('Ask to link 1 player'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['claim emma guardian']);
      expect(find.text('Request sent to the team admins'), findsOneWidget);
    });

    testWidgets('an adult player claims themselves (PLAYER-3)', (tester) async {
      final playerRepo = emmaTeam()
        ..players.add(
          const Player(
            id: PlayerId('ava'),
            groupId: GroupId('y'),
            displayName: 'Ava Kim',
          ),
        )
        // Ava already has her member, so she isn't offered.
        ..links.add(
          const GuardianLink(
            playerId: PlayerId('ava'),
            groupId: GroupId('y'),
            uid: UserId('ava1'),
            relation: PlayerRelation.self,
          ),
        );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('y', 'coach')],
        playerRepo: playerRepo,
      );
      await openWho(tester);
      await tester.tap(find.text("I'm a player"));
      await tester.pumpAndSettle();
      expect(find.text('Ava Kim'), findsNothing);
      await tester.tap(find.text('Emma Rodriguez'));
      await tester.pump();
      await tester.tap(find.text('Ask to be linked as this player'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['claim emma self']);
    });

    testWidgets('a player who is not listed adds themselves, pending', (
      tester,
    ) async {
      final playerRepo = emmaTeam();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('y', 'coach', name: 'Coach Lee')],
        playerRepo: playerRepo,
      );
      await openWho(tester);
      await tester.tap(find.text("I'm a player"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("I'm not listed: add me"));
      await tester.pumpAndSettle();
      // Their own name is filled in; no link question, it's "self".
      expect(find.text('Coach Lee'), findsOneWidget);
      expect(find.text('How are you linked?'), findsNothing);
      await tester.enterText(find.byType(TextField).at(1), '12');
      await tester.tap(find.widgetWithText(FilledButton, 'Add player'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['propose Coach Lee #12  self']);
      expect(find.text('Sent to the team admins to approve'), findsOneWidget);
    });

    testWidgets('a parent adds a player who is not listed', (tester) async {
      final playerRepo = emmaTeam();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('y', 'coach')],
        playerRepo: playerRepo,
      );
      await openWho(tester);
      await tester.tap(find.text("I'm here for a player"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Add a player who isn't listed"));
      await tester.pumpAndSettle();
      // A name is needed first.
      await tester.tap(find.widgetWithText(FilledButton, 'Add player'));
      await tester.pumpAndSettle();
      expect(find.text("Enter the player's name."), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'Liam Rodriguez');
      await tester.enterText(find.byType(TextField).at(1), '23');
      await tester.enterText(find.byType(TextField).at(2), 'Keeper');
      await tester.tap(find.widgetWithText(FilledButton, 'Add player'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['propose Liam Rodriguez #23 Keeper guardian']);
    });

    testWidgets('back from a choice, and coaches skip it', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('y', 'coach')],
        playerRepo: emmaTeam(),
      );
      await openWho(tester);
      await tester.tap(find.text("I'm here for a player"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Add a player who isn't listed"));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Emma Rodriguez'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text("I'm a coach or another adult"));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Add photos or a poll'), findsOneWidget);
    });

    testWidgets('a refused claim says why', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('y', 'coach')],
        playerRepo: RefusingPlayerRepository(
          const InvalidInput('player-already-claimed'),
          [
            const Player(
              id: PlayerId('emma'),
              groupId: GroupId('y'),
              displayName: 'Emma Rodriguez',
            ),
          ],
        ),
      );
      await openWho(tester);
      await tester.tap(find.text("I'm a player"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emma Rodriguez'));
      await tester.pump();
      await tester.tap(find.text('Ask to be linked as this player'));
      await tester.pumpAndSettle();
      expect(
        find.text("Someone already said they're this player."),
        findsOneWidget,
      );
    });

    testWidgets('admins approve claims and pending players from the roster', (
      tester,
    ) async {
      final playerRepo = emmaTeam()
        ..players.add(
          const Player(
            id: PlayerId('noah'),
            groupId: GroupId('y'),
            displayName: 'Noah Park',
            jerseyNumber: '4',
            status: PlayerStatus.pending,
            proposedBy: 'pat',
            proposedRelation: PlayerRelation.guardian,
          ),
        )
        ..requests.addAll(const [
          GuardianRequest(
            playerId: PlayerId('emma'),
            groupId: GroupId('y'),
            uid: UserId('pat'),
            status: GuardianRequestStatus.pending,
          ),
          GuardianRequest(
            playerId: PlayerId('emma'),
            groupId: GroupId('y'),
            uid: UserId('emma1'),
            status: GuardianRequestStatus.pending,
            relation: PlayerRelation.self,
          ),
        ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [
          testMembership('y', 'coach', role: MemberRole.owner),
          testMembership('y', 'pat', name: 'Pat Lee'),
          testMembership('y', 'emma1', name: 'Emma Rodriguez'),
        ],
        playerRepo: playerRepo,
      );
      await openRoster(tester);
      expect(find.text('Waiting for approval'), findsOneWidget);
      expect(find.text('Noah Park #4'), findsOneWidget);
      expect(
        find.text('Added by Pat Lee as their parent or guardian'),
        findsOneWidget,
      );
      expect(
        find.text('Pat Lee: parent or guardian of Emma #7'),
        findsOneWidget,
      );
      expect(find.text("Emma Rodriguez says they're Emma #7"), findsOneWidget);
      // Admins add players and pasted lists.
      expect(find.text('Add players'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Decline').at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
      await tester.pumpAndSettle();
      expect(playerRepo.calls, [
        'approvePlayer noah',
        'decline emma pat',
        'approve emma emma1',
      ]);
    });

    testWidgets('a full player link says so when approving', (tester) async {
      final playerRepo =
          RefusingPlayerRepository(const InvalidInput('too-many-guardians'), [
              const Player(
                id: PlayerId('emma'),
                groupId: GroupId('y'),
                displayName: 'Emma Rodriguez',
              ),
            ])
            ..requests.add(
              const GuardianRequest(
                playerId: PlayerId('emma'),
                groupId: GroupId('y'),
                uid: UserId('pat'),
                status: GuardianRequestStatus.pending,
              ),
            );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [
          testMembership('y', 'coach', role: MemberRole.owner),
          testMembership('y', 'pat', name: 'Pat Lee'),
        ],
        playerRepo: playerRepo,
      );
      await openRoster(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining("the player's links are full"),
        findsOneWidget,
      );
    });

    for (final (code, said) in [
      (
        'already-a-player',
        "Can't approve this: Pat Lee is already a player on this team. "
            'Decline it.',
      ),
      (
        'player-already-claimed',
        "Can't approve this: someone is already this player. Decline it, "
            'or remove their link first.',
      ),
    ]) {
      testWidgets('an approval refused with $code says why', (tester) async {
        final playerRepo =
            RefusingPlayerRepository(InvalidInput(code), [
                const Player(
                  id: PlayerId('emma'),
                  groupId: GroupId('y'),
                  displayName: 'Emma Rodriguez',
                ),
              ])
              ..requests.add(
                const GuardianRequest(
                  playerId: PlayerId('emma'),
                  groupId: GroupId('y'),
                  uid: UserId('pat'),
                  status: GuardianRequestStatus.pending,
                  relation: PlayerRelation.self,
                ),
              );
        await pumpApp(
          tester,
          auth: FakeAuthRepository(user: coach),
          groups: team,
          memberships: [
            testMembership('y', 'coach', role: MemberRole.owner),
            testMembership('y', 'pat', name: 'Pat Lee'),
          ],
          playerRepo: playerRepo,
        );
        await openRoster(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
        await tester.pumpAndSettle();
        expect(find.text(said), findsOneWidget);
        expect(find.textContaining('links are full'), findsNothing);
      });
    }

    testWidgets('approving a pending player from someone who is already a '
        'player says so', (tester) async {
      final playerRepo = RefusingPlayerRepository(
        const InvalidInput('already-a-player'),
        [
          const Player(
            id: PlayerId('sam2'),
            groupId: GroupId('y'),
            displayName: 'Sam Ortiz',
            status: PlayerStatus.pending,
            proposedBy: 'sam',
            proposedRelation: PlayerRelation.self,
          ),
        ],
      );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [
          testMembership('y', 'coach', role: MemberRole.owner),
          testMembership('y', 'sam', name: 'Sam Ortiz'),
        ],
        playerRepo: playerRepo,
      );
      await openRoster(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "Can't approve this: Sam Ortiz is already a player on this team. "
          'Decline it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an approved player whose member could not be linked says '
        'so (PLAYER-4)', (tester) async {
      final playerRepo = FakePlayerRepository([
        const Player(
          id: PlayerId('sam2'),
          groupId: GroupId('y'),
          displayName: 'Sam Ortiz',
          status: PlayerStatus.pending,
          proposedBy: 'sam',
          proposedRelation: PlayerRelation.self,
        ),
      ])..proposerLinked = false;
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [
          testMembership('y', 'coach', role: MemberRole.owner),
          testMembership('y', 'sam', name: 'Sam Ortiz'),
        ],
        playerRepo: playerRepo,
      );
      await openRoster(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['approvePlayer sam2']);
      expect(
        find.text('Sam Ortiz was added without a link to Sam Ortiz.'),
        findsOneWidget,
      );
    });

    testWidgets('members add a player, pending, and see it as theirs', (
      tester,
    ) async {
      final playerRepo = emmaTeam()
        ..players.add(
          const Player(
            id: PlayerId('liam'),
            groupId: GroupId('y'),
            displayName: 'Liam Rodriguez',
            status: PlayerStatus.pending,
            proposedBy: 'coach',
            proposedRelation: PlayerRelation.guardian,
          ),
        );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('y', 'coach')],
        playerRepo: playerRepo,
      );
      await openRoster(tester);
      // My pending player shows, waiting; nothing to approve for members.
      expect(find.text('Liam Rodriguez'), findsOneWidget);
      expect(find.text('Waiting for approval'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Approve'), findsNothing);
      // With something waiting, the "Who are you here for?" hint is gone.
      expect(find.text('Who are you here for?'), findsNothing);
      await tester.tap(find.text('Add player'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Mia Rodriguez');
      await tester.tap(find.widgetWithText(FilledButton, 'Add player'));
      await tester.pumpAndSettle();
      // How they're linked is required.
      expect(
        find.text("Choose how you're linked to this player."),
        findsOneWidget,
      );
      await tester.tap(find.text("I'm their parent or guardian"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add player'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['propose Mia Rodriguez #  guardian']);
      expect(find.text('Sent to the team admins to approve'), findsOneWidget);
    });

    testWidgets('a member claims a player from its card', (tester) async {
      final playerRepo = emmaTeam()
        ..links.add(
          const GuardianLink(
            playerId: PlayerId('emma'),
            groupId: GroupId('y'),
            uid: UserId('maria'),
          ),
        );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [
          testMembership('y', 'coach'),
          testMembership('y', 'maria', name: 'Maria Rodriguez'),
        ],
        playerRepo: playerRepo,
      );
      await openRoster(tester);
      await tester.tap(find.text('Emma Rodriguez'));
      await tester.pumpAndSettle();
      expect(find.text('Player and guardians'), findsOneWidget);
      expect(find.text('Guardian'), findsOneWidget);
      // Members who aren't guardians can't add one.
      expect(find.text('Add a guardian'), findsNothing);
      await tester.tap(find.text('Claim this player'));
      await tester.pumpAndSettle();
      expect(
        find.text('How are you linked to Emma Rodriguez?'),
        findsOneWidget,
      );
      await tester.tap(find.text('I am this player'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['claim emma self']);
      expect(find.text('Request sent to the team admins'), findsOneWidget);
    });

    testWidgets('an admin claim links at once; a waiting claim says so', (
      tester,
    ) async {
      final playerRepo = emmaTeam()
        ..claimOutcome = ClaimOutcome.linked
        ..links.add(
          const GuardianLink(
            playerId: PlayerId('emma'),
            groupId: GroupId('y'),
            uid: UserId('emma1'),
            relation: PlayerRelation.self,
          ),
        );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [
          testMembership('y', 'coach', role: MemberRole.owner),
          testMembership('y', 'emma1', name: 'Emma Rodriguez'),
        ],
        playerRepo: playerRepo,
      );
      await go(tester, '/g/y/roster/players/emma');
      expect(find.text('Player'), findsOneWidget);
      await tester.tap(find.text('Claim this player'));
      await tester.pumpAndSettle();
      // Emma already has her member, so only the guardian choice is left.
      expect(find.text('I am this player'), findsNothing);
      await tester.tap(find.text("I'm their parent or guardian"));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['claim emma guardian']);
      expect(find.text("You're linked to this player"), findsOneWidget);
    });

    group('"I am this player" waits on a claim or player of my own', () {
      // Two players named alike; I asked to be one of them, or added
      // myself, and the other must not offer "I am this player" too.
      FakePlayerRepository twoJareds({required bool claimed}) {
        final repo = FakePlayerRepository([
          const Player(
            id: PlayerId('jared'),
            groupId: GroupId('y'),
            displayName: 'Jared Freeman',
            jerseyNumber: '12',
          ),
          if (claimed)
            const Player(
              id: PlayerId('jared2'),
              groupId: GroupId('y'),
              displayName: 'Jared Freeman',
            )
          else
            const Player(
              id: PlayerId('mine'),
              groupId: GroupId('y'),
              displayName: 'Jared Freeman',
              status: PlayerStatus.pending,
              proposedBy: 'coach',
              proposedRelation: PlayerRelation.self,
            ),
        ]);
        if (claimed) {
          repo.requests.add(
            const GuardianRequest(
              playerId: PlayerId('jared2'),
              groupId: GroupId('y'),
              uid: UserId('coach'),
              status: GuardianRequestStatus.pending,
              relation: PlayerRelation.self,
            ),
          );
        }
        return repo;
      }

      for (final claimed in [true, false]) {
        final why = claimed ? 'a claim' : 'a player of my own';
        testWidgets('on the player card, with $why waiting', (tester) async {
          await pumpApp(
            tester,
            auth: FakeAuthRepository(user: coach),
            groups: team,
            memberships: [testMembership('y', 'coach')],
            playerRepo: twoJareds(claimed: claimed),
          );
          await go(tester, '/g/y/roster/players/jared');
          await tester.tap(find.text('Claim this player'));
          await tester.pumpAndSettle();
          expect(find.text('I am this player'), findsNothing);
          expect(find.text("I'm their parent or guardian"), findsOneWidget);
        });

        testWidgets('when adding a player, with $why waiting', (tester) async {
          await pumpApp(
            tester,
            auth: FakeAuthRepository(user: coach),
            groups: team,
            memberships: [testMembership('y', 'coach')],
            playerRepo: twoJareds(claimed: claimed),
          );
          await go(tester, '/g/y/players/add');
          expect(find.text('I am this player'), findsNothing);
          expect(find.text("I'm their parent or guardian"), findsOneWidget);
        });

        testWidgets('on "Who are you here for?", with $why waiting', (
          tester,
        ) async {
          await pumpApp(
            tester,
            auth: FakeAuthRepository(user: coach),
            groups: team,
            memberships: [testMembership('y', 'coach')],
            playerRepo: twoJareds(claimed: claimed),
          );
          await go(tester, '/g/y/who');
          await tester.tap(find.text("I'm a player"));
          await tester.pumpAndSettle();
          expect(
            find.text(
              "You've already asked to be a player on this team. A team "
              'admin will decide.',
            ),
            findsOneWidget,
          );
          final add = find.widgetWithText(
            OutlinedButton,
            "I'm not listed: add me",
          );
          expect(tester.widget<OutlinedButton>(add).onPressed, isNull);
          await tester.tap(find.text('Jared Freeman').first);
          await tester.pump();
          final ask = find.widgetWithText(
            FilledButton,
            'Ask to be linked as this player',
          );
          expect(tester.widget<FilledButton>(ask).onPressed, isNull);
        });
      }
    });

    testWidgets('a claim waiting for an admin shows on the card', (
      tester,
    ) async {
      final playerRepo = emmaTeam()
        ..requests.add(
          const GuardianRequest(
            playerId: PlayerId('emma'),
            groupId: GroupId('y'),
            uid: UserId('coach'),
            status: GuardianRequestStatus.pending,
          ),
        );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('y', 'coach')],
        playerRepo: playerRepo,
      );
      await go(tester, '/g/y/roster/players/emma');
      expect(
        find.text('Your claim is waiting for a team admin.'),
        findsOneWidget,
      );
      expect(find.text('Claim this player'), findsNothing);
    });

    testWidgets('a guardian adds a co-parent from the player card', (
      tester,
    ) async {
      final playerRepo = emmaTeam()
        ..links.add(
          const GuardianLink(
            playerId: PlayerId('emma'),
            groupId: GroupId('y'),
            uid: UserId('coach'),
          ),
        );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('y', 'coach', name: 'Maria')],
        playerRepo: playerRepo,
      );
      await openRoster(tester);
      expect(find.text('Who are you here for?'), findsNothing);
      await tester.tap(find.text('Emma Rodriguez'));
      await tester.pumpAndSettle();
      expect(find.text('Claim this player'), findsNothing);
      await tester.tap(find.text('Add a guardian'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'leo@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['inviteGuardian emma leo@example.com']);
    });

    testWidgets('the member who is the player edits it, adds a guardian, '
        'and unlinks themselves (PLAYER-5)', (tester) async {
      final playerRepo = emmaTeam()
        ..links.add(
          const GuardianLink(
            playerId: PlayerId('emma'),
            groupId: GroupId('y'),
            uid: UserId('coach'),
            relation: PlayerRelation.self,
          ),
        );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('y', 'coach', name: 'Emma Rodriguez')],
        playerRepo: playerRepo,
      );
      await go(tester, '/g/y/roster/players/emma');
      expect(find.byTooltip('Edit player'), findsOneWidget);
      // Any linked member vouches for a guardian, the player included.
      await tester.tap(find.text('Add a guardian'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'mom@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove link'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unlink Emma Rodriguez as this player?'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Remove link'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, [
        'inviteGuardian emma mom@example.com',
        'removeGuardian emma coach',
      ]);
    });

    testWidgets("adding the player's own member as a guardian says they're "
        'linked already, not that guardians are full', (tester) async {
      final playerRepo =
          RefusingPlayerRepository(const InvalidInput('already-linked'), [
              const Player(
                id: PlayerId('emma'),
                groupId: GroupId('y'),
                displayName: 'Emma Rodriguez',
              ),
            ])
            ..links.add(
              const GuardianLink(
                playerId: PlayerId('emma'),
                groupId: GroupId('y'),
                uid: UserId('emma1'),
                relation: PlayerRelation.self,
              ),
            );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [
          testMembership('y', 'coach', role: MemberRole.owner),
          testMembership('y', 'emma1', name: 'Emma Rodriguez'),
        ],
        playerRepo: playerRepo,
      );
      await go(tester, '/g/y/roster/players/emma');
      await tester.tap(find.text('Add a guardian'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'emma@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      expect(
        find.text("They're already linked to this player."),
        findsOneWidget,
      );
      expect(find.text('A player can have up to 4 guardians.'), findsNothing);
    });
  });

  testWidgets('adding people by email, and resending a setup email', (
    tester,
  ) async {
    final members = FakeMemberRepository([
      testMembership('a', 'coach', role: MemberRole.owner, name: 'Jordan'),
      testMembership('a', 'ann', name: 'Ann Lee').copyWith(pending: true),
    ]);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberRepo: members,
    );
    await tester.tap(find.byTooltip('Team menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roster'));
    await tester.pumpAndSettle();
    expect(find.text('Not joined yet'), findsOneWidget);
    await tester.tap(find.text('Ann Lee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resend setup email'));
    await tester.pumpAndSettle();
    expect(members.calls, ['resend ann']);
  });

  testWidgets('wrong password shows an error and stays put', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'coach@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'nope');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.textContaining("don't match"), findsOneWidget);
  });

  group('chat (CHAT-1, CHAT-2, CHAT-10)', () {
    Message msg(
      int i, {
      String author = 'sam',
      String name = 'Sam Rivera',
      DateTime? at,
      MessageType type = MessageType.text,
    }) => Message(
      id: 'm$i',
      groupId: const GroupId('a'),
      authorId: author,
      authorName: name,
      type: type,
      text: 'Message $i',
      createdAt: at ?? DateTime.now().subtract(Duration(minutes: 200 - i)),
    );

    Future<void> openChat(WidgetTester tester, FakeMessageRepository repo) =>
        pumpApp(
          tester,
          auth: FakeAuthRepository(user: coach),
          groups: {'a': testGroup('a', 'Thunder')},
          memberships: [
            testMembership('a', 'coach', role: MemberRole.owner),
            testMembership('a', 'sam', name: 'Sam Rivera'),
          ],
          messageRepo: repo,
        );

    testWidgets('shows messages grouped by sender with a date separator', (
      tester,
    ) async {
      final now = DateTime.now();
      final repo = FakeMessageRepository([
        msg(3, at: now.subtract(const Duration(minutes: 1))),
        msg(2, at: now.subtract(const Duration(minutes: 2))),
        msg(
          1,
          type: MessageType.system,
          author: 'system',
          name: '',
          at: now.subtract(const Duration(minutes: 3)),
        ).copyWith(text: 'Sam joined'),
      ]);
      await openChat(tester, repo);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Sam joined'), findsOneWidget);
      expect(find.text('Message 2'), findsOneWidget);
      expect(find.text('Message 3'), findsOneWidget);
      // One header for Sam's two messages in a row.
      expect(find.textContaining('Sam Rivera'), findsOneWidget);
    });

    testWidgets('sending puts the message in the chat', (tester) async {
      final repo = FakeMessageRepository();
      await openChat(tester, repo);
      await tester.enterText(find.byType(TextField), '  Practice moved to 6  ');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(repo.sent, ['Practice moved to 6']);
      expect(find.text('Practice moved to 6'), findsOneWidget);
    });

    testWidgets('photos from the + menu post as one message (CHAT-3)', (
      tester,
    ) async {
      final repo = FakeMessageRepository();
      // A 1x1 PNG.
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
        messageRepo: repo,
        photoPicker: FakePhotoPicker([
          (bytes: tinyPng, contentType: 'image/png'),
          (bytes: tinyPng, contentType: 'image/png'),
        ]),
      );
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo library'));
      await tester.pumpAndSettle();
      expect(repo.photoBatches, [2]);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('delivery states: sent, and not sent with retry (CHAT-4)', (
      tester,
    ) async {
      final repo = FakeMessageRepository()
        ..failSends = const PermissionDenied('test');
      await openChat(tester, repo);
      await tester.enterText(find.byType(TextField), 'Rain check?');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Not sent'), findsOneWidget);
      repo.failSends = null;
      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Not sent'), findsNothing);
      expect(repo.sent, ['Rain check?']);
      expect(find.text('Rain check?'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
    });

    testWidgets('reactions from the message menu, one per person (CHAT-6)', (
      tester,
    ) async {
      final repo = FakeMessageRepository([
        msg(1).copyWith(reactions: {'sam': Reaction.like}),
      ]);
      await openChat(tester, repo);
      expect(find.text('👍 1'), findsOneWidget);
      await tester.longPress(find.text('Message 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('👍'));
      await tester.pumpAndSettle();
      expect(find.text('👍 2'), findsOneWidget);
      // Picking another replaces mine.
      await tester.longPress(find.text('Message 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('😂'));
      await tester.pumpAndSettle();
      expect(find.text('👍 1'), findsOneWidget);
      expect(find.text('😂 1'), findsOneWidget);
      // Picking the same one removes it.
      await tester.longPress(find.text('Message 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('😂').last);
      await tester.pumpAndSettle();
      expect(find.text('😂 1'), findsNothing);
      // Tapping a chip shows who reacted.
      await tester.tap(find.text('👍 1'));
      await tester.pumpAndSettle();
      expect(find.text('Sam Rivera'), findsWidgets);
    });

    testWidgets('double-tap loves a message', (tester) async {
      final repo = FakeMessageRepository([msg(1)]);
      await openChat(tester, repo);
      await tester.tap(find.text('Message 1'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Message 1'));
      await tester.pumpAndSettle();
      expect(find.text('❤️ 1'), findsOneWidget);
    });

    testWidgets('replying quotes the original, and the quote jumps back', (
      tester,
    ) async {
      final repo = FakeMessageRepository([
        for (var i = 120; i > 0; i--) msg(i),
      ]);
      // A reply near the bottom to message 2, 118 messages back.
      repo.messages.insert(
        0,
        msg(121).copyWith(
          text: 'Answering the old one',
          replyToId: 'm2',
          replyPreview: const ReplyPreview(
            authorName: 'Sam Rivera',
            text: 'Message 2',
          ),
        ),
      );
      await openChat(tester, repo);
      // Reply to the newest plain message from the menu.
      await tester.longPress(find.text('Message 120'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Cancel reply'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Got it');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(repo.messages.first.replyToId, 'm120');
      expect(find.byTooltip('Cancel reply'), findsNothing);
      // Tapping the old quote loads older pages and scrolls to message 2.
      // Only the quote shows "Message 2" until the original is on screen.
      expect(find.text('Message 2'), findsOneWidget);
      await tester.tap(find.text('Message 2'));
      // Past the double-tap window, then let the jump run.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Message 2'), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.textSpan?.toPlainText() == 'Message 2',
        ),
        findsOneWidget,
      );
    });

    testWidgets('deleting your message leaves a placeholder (CHAT-8)', (
      tester,
    ) async {
      final repo = FakeMessageRepository([
        msg(2, author: 'coach', name: 'Coach'),
        msg(1),
      ]);
      await openChat(tester, repo);
      await tester.longPress(find.text('Message 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this message?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete message'));
      await tester.pumpAndSettle();
      expect(repo.deleted, ['m2']);
      expect(find.text('This message was deleted.'), findsOneWidget);
    });

    testWidgets('an archived team offers no Delete, as deleteMessage refuses '
        'it there (TEAM-9)', (tester) async {
      final repo = FakeMessageRepository([
        msg(2, author: 'coach', name: 'Coach'),
        msg(1),
      ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          'a': testGroup('a', 'Thunder').copyWith(archivedAt: DateTime(2026)),
        },
        memberships: [
          testMembership('a', 'coach', role: MemberRole.owner),
          testMembership('a', 'sam', name: 'Sam Rivera'),
        ],
        messageRepo: repo,
      );
      // My own message, and as the team's owner.
      await tester.longPress(find.text('Message 2'));
      await tester.pumpAndSettle();
      expect(find.text('Copy text'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets("members can't delete other people's messages", (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach')],
        messageRepo: FakeMessageRepository([msg(1)]),
      );
      await tester.longPress(find.text('Message 1'));
      await tester.pumpAndSettle();
      expect(find.text('Copy text'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('unread: divider, Chat tab count, and marking read (CHAT-9)', (
      tester,
    ) async {
      final now = DateTime.now();
      final members = FakeMemberRepository([
        testMembership(
          'a',
          'coach',
          role: MemberRole.owner,
        ).copyWith(lastReadAt: now.subtract(const Duration(minutes: 3))),
        testMembership('a', 'sam', name: 'Sam Rivera'),
      ]);
      final repo = FakeMessageRepository([
        msg(3, at: now.subtract(const Duration(minutes: 1))),
        msg(2, at: now.subtract(const Duration(minutes: 2))),
        msg(1, at: now.subtract(const Duration(minutes: 5))),
      ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          'a': testGroup(
            'a',
            'Thunder',
          ).copyWith(lastMessageAt: now.subtract(const Duration(minutes: 1))),
        },
        memberRepo: members,
        messageRepo: repo,
      );
      expect(find.text('New messages'), findsOneWidget);
      // Messages 2 and 3 are unread: the Chat tab shows 2.
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('2')),
        findsOneWidget,
      );
      // The newest messages are on screen, so the chat is marked read.
      await tester.pump(const Duration(seconds: 3));
      expect(members.reads, contains('a'));
    });

    testWidgets(
      'reporting a message and blocking its author (SAFE-1, SAFE-2)',
      (tester) async {
        final safety = FakeSafetyRepository();
        await pumpApp(
          tester,
          auth: FakeAuthRepository(user: coach),
          groups: {'a': testGroup('a', 'Thunder')},
          memberships: [
            testMembership('a', 'coach'),
            testMembership('a', 'sam', name: 'Sam Rivera'),
          ],
          messageRepo: FakeMessageRepository([msg(1)]),
          safety: safety,
        );
        await tester.longPress(find.text('Message 1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Report'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spam'));
        await tester.pump();
        await tester.tap(find.text('Send report'));
        await tester.pumpAndSettle();
        expect(safety.reports, ['message m1 spam']);
        expect(find.textContaining('admins will review'), findsOneWidget);
        // Let the confirmation go away.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        // Block Sam: the message collapses, and Show reveals it.
        await tester.longPress(find.text('Message 1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Block Sam Rivera'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Block'));
        await tester.pumpAndSettle();
        expect(find.text('Message 1'), findsNothing);
        expect(find.text('Message from someone you blocked'), findsOneWidget);
        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();
        expect(find.text('Message 1'), findsOneWidget);
      },
    );

    testWidgets('anyone edits their own message, which shows "edited" '
        '(CHAT-15)', (tester) async {
      final repo = FakeMessageRepository([
        msg(2, author: 'coach', name: 'Coach'),
        msg(1),
      ]);
      // A plain member of a team that never set anything up.
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [
          testMembership('a', 'coach'),
          testMembership('a', 'sam', name: 'Sam Rivera'),
        ],
        messageRepo: repo,
      );
      await tester.longPress(find.text('Message 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Message two, fixed');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(repo.edits, ['m2 Message two, fixed']);
      expect(find.text('Message two, fixed'), findsOneWidget);
      expect(find.textContaining('edited'), findsOneWidget);
      // Not on other people's messages.
      await tester.longPress(find.text('Message 1'));
      await tester.pumpAndSettle();
      expect(find.text('Copy text'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('the picker has all 16 reactions on every team (CHAT-6)', (
      tester,
    ) async {
      final repo = FakeMessageRepository([msg(1)]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach')],
        messageRepo: repo,
      );
      await tester.longPress(find.text('Message 1'));
      await tester.pumpAndSettle();
      for (final e in [
        '👍', '❤️', '👎', '😂', '🔥', '👏', '🎉', '💯', //
        '🙏', '😮', '😢', '😡', '⚾', '🏀', '⚽', '🏆',
      ]) {
        expect(find.text(e), findsOneWidget, reason: e);
      }
      expect(find.text('More reactions'), findsNothing);
      expect(find.text('Plus'), findsNothing);
      // The rest wrap in rows of buttons, not one per line, so the menu's
      // actions stay close below them.
      final fire = tester.getRect(find.text('🔥'));
      final clap = tester.getRect(find.text('👏'));
      expect(clap.top, fire.top);
      expect(
        tester.getRect(find.text('🏆')).bottom - fire.top,
        lessThan(4 * kMinInteractiveDimension),
      );
      await tester.tap(find.text('⚾'));
      await tester.pumpAndSettle();
      expect(find.text('⚾ 1'), findsOneWidget);
    });

    testWidgets('full storage stops photos, and text still sends (STORE-4)', (
      tester,
    ) async {
      final repo = FakeMessageRepository();
      final picker = FakePhotoPicker([
        (bytes: Uint8List(4), contentType: 'image/jpeg'),
      ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          'a': testGroup('a', 'Thunder').copyWith(
            storageBytes: 500 * bytesPerMb,
            storageQuotaBytes: 500 * bytesPerMb,
          ),
        },
        memberships: [testMembership('a', 'coach')],
        messageRepo: repo,
        photoPicker: picker,
      );
      const full =
          'Storage is full. Uploads, attachments, and scheduling new events '
          'are disabled until storage is freed up.';
      // The banner says it once; Photo library says it again instead of
      // opening the picker. Polls still work (STORE-4).
      expect(find.text(full), findsOneWidget);
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      expect(find.text('Create poll'), findsOneWidget);
      await tester.tap(find.text('Photo library'));
      await tester.pumpAndSettle();
      expect(find.text(full), findsNWidgets(2));
      expect(picker.opened, 0);
      expect(repo.photoBatches, isEmpty);
      // Let the message go away from over the composer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Still here');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(repo.sent, ['Still here']);
    });

    testWidgets('storage filling up while picking stops the upload '
        '(STORE-4)', (tester) async {
      final repo = FakeMessageRepository();
      final groupRepo = FakeGroupRepository({
        'a': testGroup(
          'a',
          'Thunder',
        ).copyWith(storageBytes: 0, storageQuotaBytes: 500 * bytesPerMb),
      });
      // Someone else's upload fills the team while the picker is open.
      final picker =
          FakePhotoPicker([(bytes: Uint8List(4), contentType: 'image/jpeg')])
            ..whilePicking = () => groupRepo.setGroup(
              groupRepo.groups['a']!.copyWith(storageBytes: 500 * bytesPerMb),
            );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: groupRepo,
        memberships: [testMembership('a', 'coach')],
        messageRepo: repo,
        photoPicker: picker,
      );
      const full =
          'Storage is full. Uploads, attachments, and scheduling new events '
          'are disabled until storage is freed up.';
      expect(find.text(full), findsNothing);
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo library'));
      await tester.pumpAndSettle();
      expect(picker.opened, 1);
      // The banner, plus the message saying why the photo didn't go.
      expect(find.text(full), findsNWidgets(2));
      expect(repo.photoBatches, isEmpty);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('Retry on a failed photo waits while storage is full '
        '(STORE-4)', (tester) async {
      final repo = FakeMessageRepository()..failUploads = 1;
      Group using(int mb) => testGroup('a', 'Thunder').copyWith(
        storageBytes: mb * bytesPerMb,
        storageQuotaBytes: 500 * bytesPerMb,
      );
      final groupRepo = FakeGroupRepository({'a': using(0)});
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: groupRepo,
        memberships: [testMembership('a', 'coach')],
        messageRepo: repo,
        photoPicker: FakePhotoPicker([
          (bytes: tinyPng, contentType: 'image/png'),
        ]),
      );
      const full =
          'Storage is full. Uploads, attachments, and scheduling new events '
          'are disabled until storage is freed up.';
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo library'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);

      groupRepo.setGroup(using(500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      // The banner, plus the message saying why Retry didn't upload.
      expect(find.text(full), findsNWidgets(2));
      expect(repo.photoBatches, isEmpty);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Once space is freed, Retry sends it.
      groupRepo.setGroup(using(100));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(repo.photoBatches, [1]);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('a deleted message says who removed it (CHAT-8, STORE-5)', (
      tester,
    ) async {
      final gone = DateTime.now();
      await openChat(
        tester,
        FakeMessageRepository([
          msg(3).copyWith(text: '', deletedAt: gone, deletedReason: 'media'),
          msg(2).copyWith(text: '', deletedAt: gone, deletedReason: 'admin'),
          msg(1).copyWith(text: '', deletedAt: gone, deletedReason: 'author'),
        ]),
      );
      expect(find.text('Photo removed by a team admin.'), findsOneWidget);
      expect(find.text('Removed by a team admin.'), findsOneWidget);
      expect(find.text('This message was deleted.'), findsOneWidget);
    });

    testWidgets('my bubbles take the team color unless admins pick another, '
        'whatever the background (CHAT-18)', (tester) async {
      const green = 0xFF2E7D32;
      const purple = 0xFF6A1B9A;
      Future<Color?> myBubble(Group team) async {
        await pumpApp(
          tester,
          auth: FakeAuthRepository(user: coach),
          groups: {'a': team},
          memberships: [testMembership('a', 'coach')],
          messageRepo: FakeMessageRepository([
            msg(1, author: 'coach', name: 'Coach'),
          ]),
        );
        final box = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('Message 1'),
                matching: find.byWidgetPredicate(
                  (w) => w is Container && w.decoration is BoxDecoration,
                ),
              )
              .first,
        );
        return (box.decoration! as BoxDecoration).color;
      }

      final thunder = testGroup('a', 'Thunder');
      // No team color and no look: the brand color.
      final plain = await myBubble(thunder);
      expect(
        plain,
        Theme.of(tester.element(find.text('Message 1'))).colorScheme.primary,
      );
      // The team color, before and after an admin sets only a background.
      expect(
        await myBubble(thunder.copyWith(color: green)),
        const Color(green),
      );
      expect(
        await myBubble(
          thunder.copyWith(
            color: green,
            chatTheme: const ChatTheme(background: ChatBackground.pattern),
          ),
        ),
        const Color(green),
      );
      // A palette color the admins picked.
      expect(
        await myBubble(
          thunder.copyWith(
            color: green,
            chatTheme: const ChatTheme(bubbleColor: purple),
          ),
        ),
        const Color(purple),
      );
    });

    testWidgets('scrolling up loads older messages 50 at a time', (
      tester,
    ) async {
      final repo = FakeMessageRepository([
        for (var i = 120; i > 0; i--) msg(i),
      ]);
      await openChat(tester, repo);
      expect(find.text('Message 120'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Message 2'),
        2000,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 200,
      );
      expect(find.text('Message 2'), findsOneWidget);
    });
  });

  testWidgets('a member opens their most recent team on the Chat tab', (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {
        'a': testGroup('a', 'Thunder', lastMessageAt: DateTime(2026, 10)),
        'b': testGroup('b', 'Lightning U10', lastMessageAt: DateTime(2026, 9)),
      },
      memberships: [
        testMembership('b', 'coach'),
        testMembership('a', 'coach', role: MemberRole.owner),
      ],
    );
    expect(find.text('Thunder'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('No messages yet. Say hi to the team!'), findsOneWidget);
  });

  testWidgets('switching teams keeps the current tab', (tester) async {
    final prefs = await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {
        'a': testGroup('a', 'Thunder', lastMessageAt: DateTime(2026, 10)),
        'b': testGroup('b', 'Lightning U10', lastMessageAt: DateTime(2026, 9)),
      },
      memberships: [testMembership('a', 'coach'), testMembership('b', 'coach')],
    );
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(prefs.lastTeamRoute, '/g/a/schedule');

    await tester.tap(find.text('Thunder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lightning U10'));
    await tester.pumpAndSettle();
    expect(prefs.lastTeamRoute, '/g/b/schedule');
    expect(find.text('No upcoming events.'), findsOneWidget);
  });

  testWidgets('signing out of all devices asks first, then signs out', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: coach);
    final push = FakePushRepository();
    await pumpApp(tester, auth: auth, push: push);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sign out of all devices'), 100);
    await tester.tap(find.text('Sign out of all devices'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out of all devices?'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Sign out of all devices'),
    );
    await tester.pumpAndSettle();
    expect(auth.signedOutEverywhere, isTrue);
    expect(push.tokensDeleted, 1);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('sign-in methods: the only method cannot be removed', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: coach.copyWith(providerIds: ['google.com']),
    );
    await pumpApp(tester, auth: auth);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign-in methods'));
    await tester.pumpAndSettle();
    final remove = find.widgetWithText(TextButton, 'Remove');
    expect(tester.widget<TextButton>(remove).onPressed, isNull);
    expect(find.textContaining("can't be removed"), findsOneWidget);
  });

  testWidgets('linking Google asks for a fresh sign-in, then links', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: coach.copyWith(
        providerIds: ['password'],
        signInProvider: 'password',
      ),
    )..needsRecentLogin = true;
    await pumpApp(tester, auth: auth);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign-in methods'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Link'));
    await tester.pumpAndSettle();
    // Linking Google needed a fresh sign-in: the password prompt appears.
    expect(find.text("Confirm it's you"), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(auth.reauthedWith, 'password');
    expect(auth.currentUser!.providerIds, contains('google.com'));
    expect(find.text('Google linked.'), findsOneWidget);
  });

  testWidgets('a fresh sign-in uses Google when linked, even beside the '
      "setup link's password method (AUTH-6, AUTH-7)", (tester) async {
    // An added account that chose Google: no password behind `password`.
    final auth = FakeAuthRepository(
      user: coach.copyWith(
        providerIds: ['password', 'google.com'],
        signInProvider: 'emailLink',
      ),
    )..needsRecentLogin = true;
    await pumpApp(tester, auth: auth);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign-in methods'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'new@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text("Confirm it's you"), findsNothing);
    expect(auth.reauthedWith, 'google.com');
    expect(auth.emailChangeTo, 'new@example.com');
  });

  testWidgets('with no password and no Google, a fresh sign-in goes by an '
      'emailed link (AUTH-7)', (tester) async {
    final auth = FakeAuthRepository(
      user: coach.copyWith(
        providerIds: ['password'],
        signInProvider: 'emailLink',
      ),
    )..needsRecentLogin = true;
    final prefs = await pumpApp(tester, auth: auth);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign-in methods'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Link'));
    await tester.pumpAndSettle();
    expect(find.text("Confirm it's you"), findsNothing);
    expect(auth.sentLinks, ['coach@example.com']);
    expect(prefs.pendingSignInEmail, 'coach@example.com');
    expect(find.textContaining('we emailed a sign-in link'), findsOneWidget);
    expect(auth.currentUser!.providerIds, isNot(contains('google.com')));

    // Opening the link while signed in is the fresh sign-in.
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .go('/activate?mode=signIn');
    await tester.pumpAndSettle();
    expect(prefs.pendingSignInEmail, isNull);
    expect(auth.needsRecentLogin, isFalse);
    expect(find.text('Signing you in…'), findsNothing);
  });

  testWidgets('a password set on this device is asked for again (AUTH-7)', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: coach.copyWith(
        providerIds: ['password'],
        signInProvider: 'emailLink',
      ),
    );
    await pumpApp(tester, auth: auth);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign-in methods'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    auth.needsRecentLogin = true;
    await tester.tap(find.text('Link'));
    await tester.pumpAndSettle();
    expect(find.text("Confirm it's you"), findsOneWidget);
    expect(auth.sentLinks, isEmpty);
  });

  testWidgets('deleting the account confirms, signs in again, then deletes', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: coach.copyWith(providerIds: ['google.com']),
    )..needsRecentLogin = true;
    await pumpApp(tester, auth: auth);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete account'), 100);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(auth.reauthedWith, 'google.com');
    expect(auth.deleted, isTrue);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('the theme switch applies at once and is remembered', (
    tester,
  ) async {
    final users = FakeUserRepository();
    final prefs = await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      users: users,
    );
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(prefs.themePreference, ThemePreference.dark);
    expect(users.themeMode, ThemePreference.dark);
  });

  testWidgets('admins act on reports from the Reports screen (SAFE-4)', (
    tester,
  ) async {
    final safety = FakeSafetyRepository()
      ..open.add(
        const Report(
          id: 'r1',
          groupId: GroupId('a'),
          targetType: ReportTargetType.message,
          targetId: 'm1',
          reason: ReportReason.harassment,
          subjectId: 'sam',
          subjectName: 'Sam Rivera',
          excerpt: 'Something mean',
        ),
      );
    final messages = FakeMessageRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [
        testMembership('a', 'coach', role: MemberRole.owner),
        testMembership('a', 'sam', name: 'Sam Rivera'),
      ],
      messageRepo: messages,
      safety: safety,
    );
    await tester.tap(find.byTooltip('Team menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Something mean'), findsOneWidget);
    expect(find.text('A message from Sam Rivera'), findsOneWidget);
    await tester.tap(find.text('Delete message'));
    await tester.pumpAndSettle();
    expect(messages.deleted, ['m1']);
    expect(safety.resolved, ['r1 deletedMessage']);
    expect(find.text('No open reports.'), findsOneWidget);
  });

  testWidgets('Settings lists blocked people with Unblock (SET-5)', (
    tester,
  ) async {
    final safety = FakeSafetyRepository()
      ..blocks.add(const BlockedPerson(uid: UserId('sam'), name: 'Sam Rivera'));
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      safety: safety,
    );
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blocked people'));
    await tester.pumpAndSettle();
    expect(find.text('Sam Rivera'), findsOneWidget);
    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();
    expect(safety.blocks, isEmpty);
    expect(find.text("You haven't blocked anyone."), findsOneWidget);
  });

  group('team storage and the chat look (STORE-1 to STORE-6, CHAT-18)', () {
    const full =
        'Storage is full. Uploads, attachments, and scheduling new events '
        'are disabled until storage is freed up.';
    const warning = 'Storage is 90% full. Free up space in Media.';

    Group teamUsing(int usedMb, {int quotaMb = 500}) =>
        testGroup('a', 'Thunder').copyWith(
          storageBytes: usedMb * bytesPerMb,
          storageQuotaBytes: quotaMb * bytesPerMb,
        );

    Future<void> openSettings(WidgetTester tester, {Finder? until}) async {
      await tester.tap(find.byTooltip('Team menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Team settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        until ?? find.textContaining('MB used'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('admins set the chat look on any team (CHAT-18)', (
      tester,
    ) async {
      final groupRepo = FakeGroupRepository({'a': testGroup('a', 'Thunder')});
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: groupRepo,
        memberships: [testMembership('a', 'coach', role: MemberRole.admin)],
      );
      final pattern = find.text('Pattern');
      await openSettings(tester, until: pattern);
      await tester.ensureVisible(pattern);
      await tester.pumpAndSettle();
      expect(find.text('Plus'), findsNothing);
      await tester.tap(pattern);
      await tester.pumpAndSettle();
      expect(groupRepo.savedTheme?.background, ChatBackground.pattern);
    });

    testWidgets('the meter shows use, amber at 90% and red when full '
        '(STORE-2, STORE-3)', (tester) async {
      Future<Color?> meterAt(int usedMb) async {
        await pumpApp(
          tester,
          auth: FakeAuthRepository(user: coach),
          groups: {'a': teamUsing(usedMb)},
          memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
        );
        await openSettings(tester);
        return tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .color;
      }

      final ok = await meterAt(212);
      final scheme = Theme.of(
        tester.element(find.byType(LinearProgressIndicator)),
      ).colorScheme;
      expect(find.text('212 MB of 500 MB used'), findsOneWidget);
      expect(ok, scheme.primary);
      expect(find.textContaining('Nearly full'), findsNothing);

      expect(await meterAt(460), AppColors.light.maybe);
      expect(find.text('460 MB of 500 MB used'), findsOneWidget);
      expect(find.textContaining('Nearly full'), findsOneWidget);

      expect(await meterAt(500), scheme.error);
      expect(find.text('500 MB of 500 MB used'), findsOneWidget);
      expect(find.textContaining('Full.'), findsOneWidget);
    });

    testWidgets("at 90%, admins see the warning with Media; members don't "
        '(STORE-3)', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': teamUsing(460)},
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
      );
      expect(find.text(warning), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Media'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nothing stored yet'), findsOneWidget);

      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': teamUsing(460)},
        memberships: [testMembership('a', 'coach')],
      );
      expect(find.text(warning), findsNothing);
      // Media isn't in a member's team menu either.
      await tester.tap(find.byTooltip('Team menu'));
      await tester.pumpAndSettle();
      expect(find.text('Media'), findsNothing);
    });

    testWidgets('dismissing the 90% warning still shows the full banner '
        'later (STORE-4)', (tester) async {
      final groupRepo = FakeGroupRepository({'a': teamUsing(460)});
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: groupRepo,
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
      );
      expect(find.text(warning), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text(warning), findsNothing);

      groupRepo.setGroup(teamUsing(500));
      await tester.pumpAndSettle();
      expect(find.text(full), findsOneWidget);
    });

    testWidgets('when full, everyone sees why; admins also get Media '
        '(STORE-4)', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': teamUsing(500)},
        memberships: [testMembership('a', 'coach')],
      );
      expect(find.text(full), findsOneWidget);
      expect(find.text(warning), findsNothing);
      expect(find.widgetWithText(TextButton, 'Media'), findsNothing);
      // Dismissed for the session.
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text(full), findsNothing);

      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': teamUsing(512)},
        memberships: [testMembership('a', 'coach', role: MemberRole.admin)],
      );
      expect(find.text(full), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Media'), findsOneWidget);
    });

    testWidgets('when full, a new logo or chat background is off (STORE-4)', (
      tester,
    ) async {
      final picker = FakePhotoPicker([
        (bytes: Uint8List(4), contentType: 'image/jpeg'),
      ]);
      final groupRepo = FakeGroupRepository({'a': teamUsing(500)});
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: groupRepo,
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
        photoPicker: picker,
      );
      await tester.tap(find.byTooltip('Team menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Team settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change logo'));
      await tester.pumpAndSettle();
      expect(find.text(full), findsOneWidget);
      final photo = find.text('Photo');
      await tester.scrollUntilVisible(
        photo,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(photo);
      await tester.pumpAndSettle();
      await tester.tap(photo);
      await tester.pumpAndSettle();
      expect(picker.opened, 0);
      expect(groupRepo.logosUploaded, 0);
      expect(groupRepo.savedTheme, isNull);
    });

    testWidgets('Media lists files largest first and deletes after '
        'confirming (STORE-5)', (tester) async {
      final media = FakeMediaRepository([
        MediaItem(
          path: 'groups/a/avatar/1.jpg',
          size: 300 * 1024,
          kind: MediaKind.logo,
          contentType: 'image/jpeg',
          current: true,
          createdAt: DateTime(2026, 10),
        ),
        MediaItem(
          path: 'groups/a/messages/m1/0.jpg',
          size: 2 * bytesPerMb,
          kind: MediaKind.chatPhoto,
          contentType: 'image/jpeg',
          messageId: 'm1',
          authorName: 'Sam Rivera',
          current: true,
          createdAt: DateTime(2026, 10, 2),
        ),
        // Uploaded for a send that never posted: no message shows it.
        const MediaItem(
          path: 'groups/a/messages/m9/0.jpg',
          size: bytesPerMb,
          kind: MediaKind.chatPhoto,
          contentType: 'image/jpeg',
          messageId: 'm9',
          current: false,
        ),
        const MediaItem(
          path: 'groups/a/stray.bin',
          size: 5 * bytesPerMb,
          kind: MediaKind.other,
        ),
        // Who added it, from the file's uploadedBy tag.
        const MediaItem(
          path: 'groups/a/theme/1.jpg',
          size: 200 * 1024,
          kind: MediaKind.background,
          contentType: 'image/jpeg',
          authorName: 'Alex Kim',
          current: true,
        ),
      ])..truncated = true;
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': teamUsing(7)},
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
        media: media,
      );
      await tester.tap(find.byTooltip('Team menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Media'));
      await tester.pumpAndSettle();
      expect(find.text('7.0 MB of 500 MB used'), findsOneWidget);
      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(top('Unused file'), lessThan(top('Chat photo · Sam Rivera')));
      expect(top('Chat photo · Sam Rivera'), lessThan(top('Team logo')));
      expect(top('Team logo'), lessThan(top('Chat background · Alex Kim')));
      expect(find.text('5.0 MB'), findsOneWidget);
      expect(find.textContaining('2.0 MB · '), findsOneWidget);
      expect(find.textContaining('Showing the largest files'), findsOneWidget);

      // A photo nothing shows isn't described as leaving the chat.
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Chat photo not in the chat'),
          matching: find.byTooltip('Delete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delete this file?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(media.deleted, isEmpty);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Chat photo · Sam Rivera'),
          matching: find.byTooltip('Delete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delete this photo?'), findsOneWidget);
      expect(
        find.text("It's removed from the chat for everyone."),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Delete photo'));
      await tester.pumpAndSettle();
      expect(media.deleted, ['groups/a/messages/m1/0.jpg']);
      // Read again after the delete.
      expect(media.lists, 2);
      expect(find.text('Chat photo · Sam Rivera'), findsNothing);
      expect(find.text('Unused file'), findsOneWidget);
      expect(find.text('Team logo'), findsOneWidget);
    });

    testWidgets("only a super admin can change one team's limit (STORE-6)", (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': teamUsing(212)},
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
      );
      await openSettings(tester);
      expect(find.text('Change storage limit'), findsNothing);

      final groupRepo = FakeGroupRepository({'a': teamUsing(212)});
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach.copyWith(isSuperAdmin: true)),
        groupRepo: groupRepo,
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
      );
      await openSettings(tester, until: find.text('Change storage limit'));
      await tester.tap(find.text('Change storage limit'));
      await tester.pumpAndSettle();
      final field = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      final save = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Save'),
      );
      // Out of range is caught before asking the server.
      await tester.enterText(field, '0');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a whole number from 1 to 51,200.'),
        findsOneWidget,
      );
      expect(groupRepo.updates, isEmpty);
      await tester.enterText(field, '2048');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(groupRepo.updates, ['quota a 2048']);
      expect(find.text('Storage limit is now 2.0 GB.'), findsOneWidget);
    });
  });
}
