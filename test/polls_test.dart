// Polls in the app (SPEC POLL-1 to POLL-5, CHAT-11).
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/polls/presentation/poll_card.dart';
import 'package:battleplan/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );

  group('poll rules of thumb', () {
    test('tapping picks, switches, or removes a vote (POLL-2)', () {
      expect(toggledVote({}, '1', allowMultiple: false), {'1'});
      expect(toggledVote({'0'}, '1', allowMultiple: false), {'1'});
      expect(toggledVote({'1'}, '1', allowMultiple: false), <String>{});
      expect(toggledVote({'0'}, '1', allowMultiple: true), {'0', '1'});
      expect(toggledVote({'0', '1'}, '0', allowMultiple: true), {'1'});
    });

    test('a new poll needs a question and 2 to 10 options (POLL-1)', () {
      final now = DateTime(2026, 10, 12, 9);
      const ok = NewPoll(question: ' Dinner? ', options: ['Yes', ' No ', '']);
      expect(ok.isValidAt(now), isTrue);
      expect(ok.tidy.question, 'Dinner?');
      expect(ok.tidy.options, ['Yes', 'No']);
      expect(ok.copyWith(question: ' ').isValidAt(now), isFalse);
      expect(ok.copyWith(options: ['Yes', '']).isValidAt(now), isFalse);
      expect(
        ok.copyWith(options: List.generate(11, (i) => '$i')).isValidAt(now),
        isFalse,
      );
      expect(ok.copyWith(options: ['Yes', 'x' * 81]).isValidAt(now), isFalse);
      expect(ok.copyWith(question: 'x' * 201).isValidAt(now), isFalse);
      expect(
        ok
            .copyWith(closesAt: now.subtract(const Duration(minutes: 1)))
            .isValidAt(now),
        isFalse,
      );
      expect(
        ok.copyWith(closesAt: now.add(const Duration(hours: 1))).isValidAt(now),
        isTrue,
      );
    });

    test('shares, leaders, and closing time', () async {
      await initializeDateFormatting('en');
      final poll = Poll(
        id: const PollId('p'),
        groupId: const GroupId('a'),
        createdBy: 'coach',
        question: 'Q',
        options: const [
          PollOption(id: '0', text: 'A'),
          PollOption(id: '1', text: 'B'),
        ],
        voteCounts: const {'0': 3, '1': 1},
        voterCount: 4,
        closesAt: DateTime(2026, 10, 12, 17),
      );
      expect(poll.shareOf('0'), 0.75);
      expect(poll.leaders, {'0'});
      expect(poll.isClosedAt(DateTime(2026, 10, 12, 16, 59)), isFalse);
      expect(poll.isClosedAt(DateTime(2026, 10, 12, 17)), isTrue);
      expect(poll.copyWith(voterCount: 0, voteCounts: {}).leaders, isEmpty);

      final l10n = AppLocalizationsEn();
      // intl puts a narrow no-break space before AM and PM.
      final now = DateTime(2026, 10, 12, 9); // a Monday
      expect(
        closesLabel(l10n, DateTime(2026, 10, 12, 17), now),
        '5:00\u202fPM',
      );
      expect(
        closesLabel(l10n, DateTime(2026, 10, 16, 17), now),
        'Fri 5:00\u202fPM',
      );
      expect(
        closesLabel(l10n, DateTime(2026, 10, 23, 17), now),
        'Fri, Oct 23 5:00\u202fPM',
      );
    });
  });

  group('polls in chat', () {
    Poll poll({
      String createdBy = 'sam',
      bool anonymous = false,
      bool allowMultiple = false,
      DateTime? closedAt,
    }) => Poll(
      id: const PollId('p1'),
      groupId: const GroupId('a'),
      createdBy: createdBy,
      question: 'Saturday or Sunday?',
      options: const [
        PollOption(id: '0', text: 'Saturday'),
        PollOption(id: '1', text: 'Sunday'),
      ],
      anonymous: anonymous,
      allowMultiple: allowMultiple,
      closedAt: closedAt,
    );

    Message pollMessage({String author = 'sam'}) => Message(
      id: 'p1',
      groupId: const GroupId('a'),
      authorId: author,
      authorName: author == 'sam' ? 'Sam Rivera' : author,
      type: MessageType.poll,
      text: 'Saturday or Sunday?',
      pollId: 'p1',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    Future<FakePollRepository> openChat(
      WidgetTester tester, {
      Poll? existing,
      MemberRole role = MemberRole.member,
      bool membersCanCreatePolls = true,
      FakeMessageRepository? messages,
    }) async {
      final polls = FakePollRepository();
      if (existing != null) polls.put(existing);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          'a': testGroup('a', 'Thunder').copyWith(
            settings: GroupSettings(
              membersCanCreatePolls: membersCanCreatePolls,
            ),
          ),
        },
        memberships: [
          testMembership('a', 'coach', role: role, name: 'Coach Lee'),
          testMembership('a', 'sam', name: 'Sam Rivera'),
          testMembership('a', 'pat', name: 'Pat Kim'),
        ],
        messageRepo:
            messages ??
            FakeMessageRepository(existing == null ? [] : [pollMessage()]),
        pollRepo: polls,
      );
      return polls;
    }

    testWidgets('posting a poll from the + menu (POLL-1)', (tester) async {
      final messages = FakeMessageRepository();
      final polls = await openChat(tester, messages: messages);
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Poll'));
      await tester.pumpAndSettle();
      expect(find.text('New poll'), findsOneWidget);
      FilledButton post() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Post'),
      );
      expect(post().onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(0), 'Team dinner?');
      await tester.enterText(find.byType(TextField).at(1), 'Pizza');
      await tester.enterText(find.byType(TextField).at(2), 'Tacos');
      await tester.tap(find.text('Add option'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(3), 'Burgers');
      await tester.tap(find.text('Allow multiple answers'));
      await tester.pumpAndSettle();
      expect(post().onPressed, isNotNull);
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      final created = polls.polls.values.single;
      expect(created.question, 'Team dinner?');
      expect(created.options.map((o) => o.text), ['Pizza', 'Tacos', 'Burgers']);
      expect(created.allowMultiple, isTrue);
      expect(messages.messages.first.type, MessageType.poll);
      // The card shows in the chat.
      expect(find.text('Team dinner?'), findsOneWidget);
      expect(find.text('Poll · Choose any'), findsOneWidget);
      expect(find.text('No votes yet'), findsOneWidget);
    });

    testWidgets('closing the new-poll screen after typing asks first', (
      tester,
    ) async {
      final polls = await openChat(tester);
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Poll'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Half typed');
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard this poll?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('New poll'), findsNothing);
      expect(polls.polls, isEmpty);
    });

    testWidgets('only admins see Poll when members may not make them '
        '(TEAM-5)', (tester) async {
      await openChat(tester, membersCanCreatePolls: false);
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      expect(find.text('Poll'), findsNothing);

      await openChat(
        tester,
        membersCanCreatePolls: false,
        role: MemberRole.admin,
      );
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      expect(find.text('Poll'), findsOneWidget);
    });

    testWidgets('tap to vote, tap again to remove it (POLL-2)', (tester) async {
      final polls = await openChat(tester, existing: poll());
      expect(find.text('Saturday or Sunday?'), findsOneWidget);
      await tester.tap(find.text('Sunday'));
      await tester.pumpAndSettle();
      expect(polls.votes['p1']?['coach'], {'1'});
      expect(find.text('1 · 100%'), findsOneWidget);
      expect(find.text('1 person voted'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Changing my mind moves the vote.
      await tester.tap(find.text('Saturday'));
      await tester.pumpAndSettle();
      expect(polls.votes['p1']?['coach'], {'0'});

      await tester.tap(find.text('Saturday'));
      await tester.pumpAndSettle();
      expect(polls.votes['p1']?['coach'], isNull);
      expect(find.text('No votes yet'), findsOneWidget);
    });

    testWidgets('several answers on a multiple-answer poll', (tester) async {
      final polls = await openChat(tester, existing: poll(allowMultiple: true));
      await tester.tap(find.text('Saturday'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sunday'));
      await tester.pumpAndSettle();
      expect(polls.votes['p1']?['coach'], {'0', '1'});
      expect(find.byIcon(Icons.check_box), findsNWidgets(2));
    });

    testWidgets('who voted, and who has not (POLL-3)', (tester) async {
      final polls = await openChat(tester, existing: poll());
      await polls.setVote(poll(), const UserId('sam'), {'0'});
      await tester.pumpAndSettle();
      await tester.tap(find.text('See votes'));
      await tester.pumpAndSettle();
      expect(find.text('Saturday · 1 vote'), findsOneWidget);
      expect(find.text('Sunday · 0 votes'), findsOneWidget);
      expect(find.text('Sam Rivera'), findsWidgets);
      expect(find.text("Hasn't voted · 2"), findsOneWidget);
      expect(find.text('Coach Lee'), findsOneWidget);
      expect(find.text('Pat Kim'), findsOneWidget);
    });

    testWidgets('anonymous polls show only counts (POLL-3)', (tester) async {
      final polls = await openChat(tester, existing: poll(anonymous: true));
      await polls.setVote(poll(anonymous: true), const UserId('sam'), {'0'});
      await tester.pumpAndSettle();
      expect(find.text('Poll · Anonymous'), findsOneWidget);
      expect(find.text('1 · 100%'), findsOneWidget);
      expect(find.text('See votes'), findsNothing);
      await tester.longPress(find.text('Saturday'));
      await tester.pumpAndSettle();
      expect(find.text('Votes'), findsNothing);
    });

    testWidgets('the creator or an admin can close it; closed polls take no '
        'votes (POLL-4)', (tester) async {
      // A member who didn't create it can't close it.
      await openChat(tester, existing: poll());
      expect(find.text('Close poll'), findsNothing);

      // The creator can.
      var polls = await openChat(tester, existing: poll(createdBy: 'coach'));
      await tester.tap(find.text('Close poll'));
      await tester.pumpAndSettle();
      expect(find.text('Close this poll?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Close poll'));
      await tester.pumpAndSettle();
      expect(polls.closed, ['p1']);
      expect(find.text('No votes yet · Closed'), findsOneWidget);
      expect(find.text('Close poll'), findsNothing);
      await tester.tap(find.text('Saturday'));
      await tester.pumpAndSettle();
      expect(polls.votes['p1'], isNull);

      // So can an admin.
      polls = await openChat(tester, existing: poll(), role: MemberRole.admin);
      expect(find.text('Close poll'), findsOneWidget);
    });

    testWidgets('a deleted poll says so (POLL-5)', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach')],
        messageRepo: FakeMessageRepository([pollMessage()]),
      );
      expect(find.text('This poll was deleted.'), findsOneWidget);
    });

    testWidgets('a failed post says so', (tester) async {
      await openChat(
        tester,
        messages: FakeMessageRepository()..failPolls = true,
      );
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Poll'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Dinner?');
      await tester.enterText(find.byType(TextField).at(1), 'Yes');
      await tester.enterText(find.byType(TextField).at(2), 'No');
      await tester.pump();
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();
      expect(
        find.text("The poll didn't post. Check your connection and try again."),
        findsOneWidget,
      );
    });
  });

  test('message limits stay in step with the poll limits', () {
    expect(Limits.pollOptionsMax, 10);
  });
}
