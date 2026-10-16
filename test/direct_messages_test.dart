// A person's page and direct messages (SPEC TEAM-15, CHAT-19): tapping
// someone's photo in a chat opens their page with the teams we share and
// what they are on each, Message opens our conversation, and Messages lists
// the conversations with their unread counts.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/linkified_text.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/direct_chat_screen.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/groups/presentation/person_screen.dart';
import 'package:battleplan/features/notifications/domain/notification_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart';

void main() {
  final earlier = DateTime.now().subtract(const Duration(hours: 3));
  final later = DateTime.now().subtract(const Duration(hours: 1));

  /// Coach Lee's teams: Thunder (owner) and Cyclone; and Rally Possums,
  /// which keeps its people to its admins (TEAM-3). Sam is on all three,
  /// coaching Thunder; Alex is on Thunder only.
  Map<String, Group> teams() => {
    'a': testGroup('a', 'Thunder'),
    'b': testGroup('b', 'Cyclone'),
    'h': testGroup(
      'h',
      'Rally Possums',
    ).copyWith(settings: const GroupSettings(membersCanSeePeople: false)),
  };

  List<Membership> people() => [
    testMembership('a', 'coach', role: MemberRole.owner, name: 'Coach Lee'),
    testMembership('b', 'coach', name: 'Coach Lee'),
    testMembership('h', 'coach', name: 'Coach Lee'),
    testMembership(
      'a',
      'sam',
      name: 'Sam Rivera',
    ).copyWith(coach: true, title: 'Assistant', playerSummary: '#12'),
    testMembership(
      'b',
      'sam',
      name: 'Sam Rivera',
    ).copyWith(playerSummary: 'Emma #7'),
    testMembership('h', 'sam', name: 'Sam Rivera'),
    testMembership('h', 'pat', name: 'Pat Lee').copyWith(coach: true),
    testMembership('h', 'quinn', name: 'Quinn Ray'),
    testMembership('a', 'alex', name: 'Alex Kim'),
    testMembership('a', 'kim', name: 'Kim Park').copyWith(pending: true),
  ];

  Message from(String uid, String name, String text, {String group = 'a'}) =>
      Message(
        id: 'm-$uid-$text',
        groupId: GroupId(group),
        authorId: uid,
        authorName: name,
        type: MessageType.text,
        text: text,
        createdAt: earlier,
      );

  Finder profileButton(String name) => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.label == "Open $name's profile",
  );

  GoRouter router(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Navigator).first));

  group("a person's page (TEAM-15)", () {
    testWidgets('opens from their photo in the chat, with the teams we '
        'share and what they are on each, coaching first', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams(),
        memberRepo: FakeMemberRepository(people()),
        messageRepo: FakeMessageRepository([
          from('sam', 'Sam Rivera', 'Field 3 is open'),
        ]),
        size: phoneSize,
      );
      await tester.tap(profileButton('Sam Rivera'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Sam Rivera'), findsOneWidget);
      expect(find.text('Teams in common'), findsOneWidget);
      expect(find.text('Thunder'), findsOneWidget);
      expect(find.text('Coach · Assistant · Player #12'), findsOneWidget);
      expect(find.text('Cyclone'), findsOneWidget);
      expect(find.text('Parent of Emma #7'), findsOneWidget);
      // Rally Possums keeps its people to its admins, and Sam doesn't coach
      // it (TEAM-3); teams I'm not on never show (TEAM-2).
      expect(find.text('Rally Possums'), findsNothing);
      // Thunder, where they coach, comes first.
      expect(
        tester.getTopLeft(find.text('Thunder')).dy,
        lessThan(tester.getTopLeft(find.text('Cyclone')).dy),
      );
      expect(find.widgetWithText(FilledButton, 'Message'), findsOneWidget);
    });

    testWidgets('a team row opens their card on that team', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams(),
        memberRepo: FakeMemberRepository(people()),
        size: phoneSize,
      );
      unawaited(router(tester).push('/people/sam?team=a'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cyclone'));
      await tester.pumpAndSettle();
      // Coach Lee is only a member of Cyclone: no admin actions there.
      expect(find.text('Make admin'), findsNothing);
      expect(find.text('Report'), findsWidgets);
    });

    testWidgets('lists a private team I came from', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams(),
        memberRepo: FakeMemberRepository(people()),
        size: phoneSize,
      );
      unawaited(router(tester).push('/people/sam?team=h'));
      await tester.pumpAndSettle();
      expect(find.text('Rally Possums'), findsOneWidget);
    });

    testWidgets('my own page lists all my teams, with Edit profile', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams(),
        memberRepo: FakeMemberRepository(people()),
        size: phoneSize,
      );
      unawaited(router(tester).push('/people/coach'));
      await tester.pumpAndSettle();
      expect(find.text('Your teams'), findsOneWidget);
      for (final name in ['Thunder', 'Cyclone', 'Rally Possums']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Message'), findsNothing);
    });

    testWidgets('someone on none of my teams is no one I can see', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams(),
        memberRepo: FakeMemberRepository([
          ...people(),
          testMembership('z', 'stranger', name: 'Stranger'),
        ]),
        size: phoneSize,
      );
      unawaited(router(tester).push('/people/stranger'));
      await tester.pumpAndSettle();
      expect(find.text("This person isn't on any of your teams."), findsOne);
      expect(find.text('Stranger'), findsNothing);
    });

    test('a private team shows a person to its admins and where they coach '
        '(TEAM-3)', () {
      final hidden = testGroup(
        'h',
        'Rally Possums',
      ).copyWith(settings: const GroupSettings(membersCanSeePeople: false));
      MyTeam on(MemberRole role) => MyTeam(
        group: hidden,
        membership: testMembership('h', 'me', role: role),
      );
      final member = testMembership('h', 'sam');
      List<String> listed(MyTeam t, Membership theirs, {GroupId? from}) => [
        for (final s in sharedTeamsOf(
          [t],
          (_) => theirs,
          isMe: false,
          fromTeam: from,
        ))
          s.team.group.name,
      ];
      expect(listed(on(MemberRole.member), member), isEmpty);
      expect(listed(on(MemberRole.admin), member), ['Rally Possums']);
      expect(listed(on(MemberRole.member), member.copyWith(coach: true)), [
        'Rally Possums',
      ]);
      expect(listed(on(MemberRole.member), member, from: const GroupId('h')), [
        'Rally Possums',
      ]);
    });
  });

  group('direct messages (CHAT-19)', () {
    testWidgets("Message on someone's page opens our conversation, for two: "
        'no polls, announcements, or @mentions', (tester) async {
      final groups = FakeGroupRepository(teams());
      final messages = FakeMessageRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: groups,
        memberRepo: FakeMemberRepository(people()),
        messageRepo: messages,
        size: phoneSize,
      );
      unawaited(router(tester).push('/people/sam?team=a'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Message'));
      await tester.pumpAndSettle();
      expect(groups.directOpened, ['sam']);
      final id = FakeGroupRepository.directId('coach', 'sam');
      expect(
        tester.widget<DirectChatScreen>(find.byType(DirectChatScreen)).groupId,
        GroupId(id),
      );
      expect(find.text('Sam Rivera'), findsOneWidget);
      expect(
        find.text(
          'Say hi to Sam Rivera. Only the two of you see this '
          'conversation.',
        ),
        findsOneWidget,
      );
      expect(find.text('Message Sam Rivera…'), findsOneWidget);
      await tester.tap(find.byTooltip('Add photos'));
      await tester.pumpAndSettle();
      expect(find.text('Photo library'), findsOneWidget);
      expect(find.text('Create poll'), findsNothing);
      expect(find.text('Announcement'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '@Sam see you at 6');
      await tester.pumpAndSettle();
      // Nobody to @mention in a conversation.
      expect(find.text('Alex Kim'), findsNothing);
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(messages.sent, ['@Sam see you at 6']);
      expect(messages.sentDetails.single.mentions, isEmpty);
      expect(messages.messages.single.groupId, GroupId(id));
    });

    testWidgets('the header opens their page; the menu mutes and blocks', (
      tester,
    ) async {
      final id = FakeGroupRepository.directId('coach', 'sam');
      final members = FakeMemberRepository([
        ...people(),
        testParticipant(id, 'coach', 'sam', name: 'Coach Lee'),
        testParticipant(id, 'sam', 'coach', name: 'Sam Rivera'),
      ]);
      final safety = FakeSafetyRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          ...teams(),
          id: testDirectChat(id, {'coach': 'Coach Lee', 'sam': 'Sam Rivera'}),
        },
        memberRepo: members,
        safety: safety,
        size: phoneSize,
      );
      unawaited(router(tester).push('/messages/$id'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Conversation options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mute'));
      await tester.pumpAndSettle();
      expect(members.calls, ['mute $id on']);

      await tester.tap(find.byTooltip('Conversation options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block Sam Rivera'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Block'));
      await tester.pumpAndSettle();
      // "Sam Rivera is blocked." goes, uncovering the notice.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      // I can't message someone I blocked (SAFE-2).
      expect(
        find.text('You blocked Sam Rivera. Unblock them to send a message.'),
        findsOneWidget,
      );
      expect(find.text('Message Sam Rivera…'), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Unblock'));
      await tester.pumpAndSettle();
      expect(safety.blocks, isEmpty);
      expect(find.text('Message Sam Rivera…'), findsOneWidget);

      await tester.tap(find.text('Sam Rivera'));
      await tester.pumpAndSettle();
      expect(find.text('Teams in common'), findsOneWidget);
    });

    testWidgets('a conversation whose other person deleted their account is '
        'read-only (AUTH-10)', (tester) async {
      const id = 'dm-closed';
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          ...teams(),
          id: testDirectChat(id, {
            'coach': 'Coach Lee',
            'gone': 'Deleted user',
          }, archivedAt: earlier),
        },
        memberRepo: FakeMemberRepository([
          ...people(),
          testParticipant(id, 'coach', 'gone', name: 'Coach Lee'),
        ]),
        size: phoneSize,
      );
      unawaited(router(tester).push('/messages/$id'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This person deleted their account. You can read your '
          'messages, but not send new ones.',
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Send'), findsNothing);
      expect(find.byTooltip('Conversation options'), findsNothing);
    });

    testWidgets("in a conversation, I delete only my own, there's no Pin, "
        'and a report goes to Battleplan', (tester) async {
      final id = FakeGroupRepository.directId('coach', 'sam');
      final safety = FakeSafetyRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          ...teams(),
          id: testDirectChat(id, {'coach': 'Coach Lee', 'sam': 'Sam Rivera'}),
        },
        memberRepo: FakeMemberRepository([
          ...people(),
          testParticipant(id, 'coach', 'sam', name: 'Coach Lee'),
          testParticipant(id, 'sam', 'coach', name: 'Sam Rivera'),
        ]),
        messageRepo: FakeMessageRepository([
          from('sam', 'Sam Rivera', 'Rude words', group: id),
        ]),
        safety: safety,
        size: phoneSize,
      );
      unawaited(router(tester).push('/messages/$id'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Rude words'));
      await tester.pumpAndSettle();
      expect(find.text('Pin'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Reports from Messages go to the people who run '
          'Battleplan. Nobody is told who reported it.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Harassment or bullying'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Send report'));
      await tester.pumpAndSettle();
      expect(safety.reports, ['message m-sam-Rude words harassment']);
    });
  });

  group('Messages (CHAT-19)', () {
    /// Two conversations: Alex wrote last and I haven't read it; I wrote
    /// last to Sam.
    Future<FakeSafetyRepository> openMessages(
      WidgetTester tester, {
      bool mutedAlex = false,
    }) async {
      final dmAlex = FakeGroupRepository.directId('alex', 'coach');
      final dmSam = FakeGroupRepository.directId('coach', 'sam');
      final safety = FakeSafetyRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          ...teams(),
          dmAlex:
              testDirectChat(dmAlex, {
                'alex': 'Alex Kim',
                'coach': 'Coach Lee',
              }, lastMessageAt: later).copyWith(
                lastMessageAuthorId: 'alex',
                lastMessageText: 'See you at 6',
              ),
          dmSam: testDirectChat(
            dmSam,
            {'coach': 'Coach Lee', 'sam': 'Sam Rivera'},
            lastMessageAt: earlier,
          ).copyWith(lastMessageAuthorId: 'coach', lastMessageText: 'Thanks!'),
        },
        memberRepo: FakeMemberRepository([
          ...people(),
          testParticipant(
            dmAlex,
            'coach',
            'alex',
            lastMessageAt: later,
            lastReadAt: earlier,
          ).copyWith(
            mutedUntil: mutedAlex
                ? DateTime.fromMillisecondsSinceEpoch(Limits.mutedForeverMs)
                : null,
          ),
          testParticipant(
            dmSam,
            'coach',
            'sam',
            lastMessageAt: earlier,
            lastReadAt: earlier,
          ),
        ]),
        messageRepo: FakeMessageRepository([
          Message(
            id: 'x1',
            groupId: GroupId(dmAlex),
            authorId: 'alex',
            authorName: 'Alex Kim',
            type: MessageType.text,
            text: 'See you at 6',
            createdAt: later,
          ),
        ]),
        safety: safety,
        size: phoneSize,
      );
      return safety;
    }

    testWidgets('the header button counts unread conversations and opens '
        'them, newest first, with "You:" before mine', (tester) async {
      await openMessages(tester);
      expect(find.byTooltip('Messages, 1 unread'), findsOneWidget);
      await tester.tap(find.byTooltip('Messages, 1 unread'));
      await tester.pumpAndSettle();
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('See you at 6'), findsOneWidget);
      expect(find.text('You: Thanks!'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Alex Kim')).dy,
        lessThan(tester.getTopLeft(find.text('Sam Rivera')).dy),
      );
      await tester.tap(find.text('Alex Kim'));
      await tester.pumpAndSettle();
      expect(find.text('Message Alex Kim…'), findsOneWidget);
    });

    testWidgets("a muted conversation doesn't count", (tester) async {
      await openMessages(tester, mutedAlex: true);
      expect(find.byTooltip('Messages'), findsOneWidget);
    });

    testWidgets('someone I blocked drops out of Messages (SAFE-2)', (
      tester,
    ) async {
      final safety = await openMessages(tester);
      await safety.block(
        const UserId('coach'),
        const UserId('alex'),
        name: 'Alex Kim',
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Messages'), findsOneWidget);
      await tester.tap(find.byTooltip('Messages'));
      await tester.pumpAndSettle();
      expect(find.text('Alex Kim'), findsNothing);
      expect(find.text('Sam Rivera'), findsOneWidget);
    });

    testWidgets('New message offers the people my rosters show me, and '
        'opens a conversation', (tester) async {
      final groups = FakeGroupRepository(teams());
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: groups,
        memberRepo: FakeMemberRepository(people()),
        size: phoneSize,
      );
      unawaited(router(tester).push('/messages'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No messages yet. Message someone on your teams from '
          'their profile, or tap New message.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('New message').last);
      await tester.pumpAndSettle();
      // Pat coaches Rally Possums; Quinn is hidden there (TEAM-3), Kim
      // hasn't joined yet, and I'm not on my own list.
      expect(find.text('Alex Kim'), findsOneWidget);
      expect(find.text('Pat Lee'), findsOneWidget);
      expect(find.text('Sam Rivera'), findsOneWidget);
      // Sam shares Rally Possums too, but it keeps its people private.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              {'Thunder · Cyclone', 'Cyclone · Thunder'}.contains(w.data),
        ),
        findsOneWidget,
      );
      for (final hidden in ['Quinn Ray', 'Kim Park', 'Coach Lee']) {
        expect(find.text(hidden), findsNothing);
      }
      await tester.enterText(find.byType(TextField), 'pa');
      await tester.pumpAndSettle();
      expect(find.text('Sam Rivera'), findsNothing);
      await tester.tap(find.text('Pat Lee'));
      await tester.pumpAndSettle();
      expect(groups.directOpened, ['pat']);
      expect(find.text('Message Pat Lee…'), findsOneWidget);
    });

    testWidgets("says why a conversation can't open", (tester) async {
      final groups = FakeGroupRepository(teams())
        ..openDirectFailure = const PermissionDenied('no-shared-team');
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: groups,
        memberRepo: FakeMemberRepository(people()),
        size: phoneSize,
      );
      unawaited(router(tester).push('/messages'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New message').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alex Kim'));
      await tester.pumpAndSettle();
      expect(
        find.text('You can message people you share a team with.'),
        findsOneWidget,
      );
    });
  });

  group('messages laid out as iMessage lays them out (CHAT-1)', () {
    Future<void> openThunder(
      WidgetTester tester, {
      required List<Message> messages,
      bool web = false,
    }) => pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams(),
      memberRepo: FakeMemberRepository(people()),
      messageRepo: FakeMessageRepository(messages),
      browser: FakeBrowserInfo(isWeb: web),
      size: phoneSize,
    );

    String? familyOf(WidgetTester tester, String text) {
      final rich = tester.widget<Text>(
        find.descendant(
          of: find.byType(LinkifiedText),
          matching: find.byWidgetPredicate(
            (w) => w is Text && (w.textSpan?.toPlainText() ?? '') == text,
          ),
        ),
      );
      return rich.textSpan?.style?.fontFamily;
    }

    testWidgets("San Francisco in Apple's own apps, Inter in a browser", (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await openThunder(
          tester,
          messages: [from('sam', 'Sam Rivera', 'Field 3 is open')],
        );
        expect(familyOf(tester, 'Field 3 is open'), ChatText.appleSystemFont);
        await openThunder(
          tester,
          messages: [from('sam', 'Sam Rivera', 'Field 3 is open')],
          web: true,
        );
        // The theme's Inter, which a browser on an iPhone gets too.
        expect(familyOf(tester, 'Field 3 is open'), AppTokens.fontFamily);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('a bubble fits its text, and the other side stays free', (
      tester,
    ) async {
      const long =
          'Saturday games are 4pm and 5:45pm on field 5. Let us be there to '
          'start the routines at 3.';
      await openThunder(
        tester,
        messages: [
          from('sam', 'Sam Rivera', long),
          from(
            'coach',
            'Coach Lee',
            'On my\nway!',
          ).copyWith(id: 'mine', createdAt: later),
        ],
      );
      final width = phoneSize.width;
      Rect textOf(String text) => tester.getRect(
        find.byWidgetPredicate((w) => w is LinkifiedText && w.text == text),
      );
      // Others' wrap well short of the right edge; mine stays off the left.
      final theirs = textOf(long);
      expect(theirs.right, lessThan(width - 48));
      final mine = textOf('On my\nway!');
      expect(mine.left, greaterThan(width / 2));
      // Its longest line sets the bubble's width: two short lines make a
      // narrow bubble, not one as wide as it may grow.
      expect(mine.width, lessThan(width / 3));
    });
  });

  testWidgets("the roster card offers Message and the person's page", (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: teams(),
      memberRepo: FakeMemberRepository(people()),
      size: phoneSize,
    );
    unawaited(router(tester).push('/g/a/roster'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex Kim'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Message'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Teams in common'), findsOneWidget);
    expect(find.text('Thunder'), findsOneWidget);
  });

  test('notification taps open a conversation, which then shows no banner '
      '(NOTIF-6, NOTIF-7)', () {
    expect(isAllowedNotificationRoute('/messages/dm1/m/x1'), isTrue);
    expect(isAllowedNotificationRoute('/messages'), isFalse);
    expect(isTeamChatPath('/messages/dm1', 'dm1'), isTrue);
    expect(isTeamChatPath('/messages/dm2', 'dm1'), isFalse);
  });
}
