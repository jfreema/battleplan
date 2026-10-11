import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/players/domain/player.dart';
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

  testWidgets('signed out lands on sign-in with Google, Apple, and email', (
    tester,
  ) async {
    await pumpApp(tester, auth: FakeAuthRepository());
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsNothing);
    expect(find.text('Continue with email'), findsOneWidget);
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
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      users: users,
    );
    expect(find.textContaining('set up your profile'), findsOneWidget);
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

  testWidgets('creating a team from the welcome screen', (tester) async {
    final groupRepo = FakeGroupRepository({});
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groupRepo,
    );
    await tester.tap(find.text('Create a team'));
    await tester.pumpAndSettle();
    expect(find.text('Team type'), findsOneWidget);
    await tester.tap(find.text('Youth team'));
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

  testWidgets('youth roster: players section and a pasted roster', (
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
      groups: {
        'y': testGroup('y', 'Lightning U10').copyWith(teamType: TeamType.youth),
      },
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

  group('youth guardians (PLAYER-3 to PLAYER-5)', () {
    final youthTeam = {
      'y': testGroup('y', 'Lightning U10').copyWith(teamType: TeamType.youth),
    };
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

    testWidgets('a parent asks to be linked to their player', (tester) async {
      final playerRepo = emmaTeam();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youthTeam,
        memberships: [testMembership('y', 'coach')],
        playerRepo: playerRepo,
      );
      await openRoster(tester);
      await tester.tap(find.text('Who are you here for?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emma Rodriguez'));
      await tester.pump();
      await tester.tap(find.text('Ask to link 1 player'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['request emma']);
    });

    testWidgets('a parent adds a player who is not listed', (tester) async {
      final playerRepo = emmaTeam();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: youthTeam,
        memberships: [testMembership('y', 'coach')],
        playerRepo: playerRepo,
      );
      await openRoster(tester);
      await tester.tap(find.text('Who are you here for?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Add a player who isn't listed"));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Liam Rodriguez');
      await tester.enterText(find.byType(TextField).last, '23');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['addMine Liam Rodriguez #23']);
    });

    testWidgets('admins approve guardian requests from the roster', (
      tester,
    ) async {
      final playerRepo = emmaTeam()
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
        groups: youthTeam,
        memberships: [
          testMembership('y', 'coach', role: MemberRole.owner),
          testMembership('y', 'pat', name: 'Pat Lee'),
        ],
        playerRepo: playerRepo,
      );
      await openRoster(tester);
      expect(find.text('Guardian requests'), findsOneWidget);
      expect(find.text('Pat Lee for Emma #7'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['approve emma pat']);
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
        groups: youthTeam,
        memberships: [testMembership('y', 'coach', name: 'Maria')],
        playerRepo: playerRepo,
      );
      await openRoster(tester);
      expect(find.text('Who are you here for?'), findsNothing);
      await tester.tap(find.text('Emma Rodriguez'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a guardian'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'leo@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      expect(playerRepo.calls, ['inviteGuardian emma leo@example.com']);
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
          memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
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
      final png = Uint8List.fromList(const [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        0,
        0,
        0,
        13,
        73,
        72,
        68,
        82,
        0,
        0,
        0, //
        1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65,
        84, 120, 156, 99, 248, 15, 4, 0, 9, 251, 3, 253, 227, 85, 242, 156, 0,
        0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
      ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
        messageRepo: repo,
        photoPicker: FakePhotoPicker([
          (bytes: png, contentType: 'image/png'),
          (bytes: png, contentType: 'image/png'),
        ]),
      );
      await tester.tap(find.byTooltip('Add photos'));
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
    expect(
      find.text('Practices, games, and RSVPs will appear here.'),
      findsOneWidget,
    );
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
    expect(push.unregistered, 1);
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
      user: coach.copyWith(providerIds: ['password']),
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
}
