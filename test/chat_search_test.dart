// Search in the chat (SPEC CHAT-20): finding messages by their words in a
// team's chat and a direct conversation, and opening the chat at one, even
// one from long ago, in a page.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/chat_search_screen.dart';
import 'package:battleplan/features/chat/presentation/message_tile.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart';

void main() {
  final start = DateTime.now().subtract(const Duration(days: 30));

  /// Message [i], [i] minutes after [start], saying [text].
  Message msg(
    int i,
    String text, {
    String author = 'sam',
    String name = 'Sam Rivera',
    String group = 'a',
    MessageType type = MessageType.text,
  }) => Message(
    id: 'm$i',
    groupId: GroupId(group),
    authorId: author,
    authorName: name,
    type: type,
    text: text,
    createdAt: start.add(Duration(minutes: i)),
  );

  /// Team a's chat, newest first, as the repository keeps it.
  List<Message> newestFirst(List<Message> messages) =>
      [...messages]..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

  Future<void> openChat(
    WidgetTester tester,
    FakeMessageRepository repo, {
    FakeSafetyRepository? safety,
  }) => pumpApp(
    tester,
    auth: FakeAuthRepository(user: coach),
    groups: {'a': testGroup('a', 'Thunder')},
    memberRepo: FakeMemberRepository([
      testMembership(
        'a',
        'coach',
        role: MemberRole.owner,
      ).copyWith(lastReadAt: DateTime.now()),
      testMembership('a', 'sam', name: 'Sam Rivera'),
    ]),
    messageRepo: repo,
    safety: safety,
    size: phoneSize,
  );

  Finder field() => find.descendant(
    of: find.byType(ChatSearchScreen),
    matching: find.byType(TextField),
  );

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(field(), query);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  /// Whether [text] is on screen, not just built off it.
  bool onScreen(WidgetTester tester, String text) =>
      find.text(text).hitTestable().evaluate().isNotEmpty;

  String location(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .routerDelegate
          .currentConfiguration
          .uri
          .toString();

  testWidgets('with nothing pinned the row is the search entry; with a pin '
      'the search is a button at its end', (tester) async {
    await openChat(tester, FakeMessageRepository([msg(1, 'Hi')]));
    // The quiet entry, "Search Thunder", which opens the search.
    expect(find.text('Search Thunder'), findsOneWidget);
    await tester.tap(find.text('Search Thunder'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearchScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {
        'a': testGroup('a', 'Thunder').copyWith(pinnedMessageIds: ['m1']),
      },
      memberRepo: FakeMemberRepository([
        testMembership('a', 'coach', role: MemberRole.owner),
      ]),
      messageRepo: FakeMessageRepository([msg(1, 'Hi')]),
      size: phoneSize,
    );
    expect(find.text('Search Thunder'), findsNothing);
    expect(find.byType(ChatSearchButton), findsOneWidget);
    await tester.tap(find.byTooltip('Search the chat'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearchScreen), findsOneWidget);
  });

  testWidgets("the Chat tab's search finds messages by their words, newest "
      'first, and says when it finds none', (tester) async {
    final repo = FakeMessageRepository(
      newestFirst([
        msg(1, 'Tournament this weekend at Riverside'),
        msg(2, "Who's bringing snacks?"),
        msg(3, 'The tournament bracket is posted'),
        msg(4, 'See you at practice'),
      ]),
    );
    await openChat(tester, repo);
    await tester.tap(find.byTooltip('Search the chat'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearchScreen), findsOneWidget);
    expect(
      find.text(
        'Find a message by a word in it, like "tournament" or '
        'a name.',
      ),
      findsOneWidget,
    );

    // A plural finds the singular, and any case.
    await search(tester, 'TOURNAMENTS');
    expect(repo.searches.last, ['tournament']);
    final found = find.descendant(
      of: find.byType(ChatSearchScreen),
      matching: find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('ournament'),
      ),
    );
    expect(found, findsNWidgets(2));
    // Newest first.
    final texts = [
      for (final e in found.evaluate())
        (e.widget as RichText).text.toPlainText(),
    ];
    expect(texts, [
      'The tournament bracket is posted',
      'Tournament this weekend at Riverside',
    ]);
    expect(find.text('Sam Rivera'), findsNWidgets(2));

    await search(tester, 'pizza');
    expect(find.text('No messages with "pizza".'), findsOneWidget);

    // Only everyday or short words: nothing to search for.
    await search(tester, 'the a');
    expect(
      find.text(
        'Try a longer word. Short, everyday words like "the" aren\'t '
        'searched.',
      ),
      findsOneWidget,
    );
    expect(repo.searches.last, ['pizza']);
  });

  testWidgets('tapping a result opens the chat at it, highlighted', (
    tester,
  ) async {
    final repo = FakeMessageRepository(
      newestFirst([
        for (var i = 1; i <= 30; i++) msg(i, 'Message $i'),
        msg(31, 'Bring the oranges for halftime'),
        for (var i = 32; i <= 60; i++) msg(i, 'Message $i'),
      ]),
    );
    await openChat(tester, repo);
    await tester.tap(find.byTooltip('Search the chat'));
    await tester.pumpAndSettle();
    await search(tester, 'oranges');
    // A screen reader hears who sent it, when, and what it says, and can
    // open it.
    final semantics = tester.ensureSemantics();
    final row = find.bySemanticsLabel(RegExp('^Sam Rivera, .*: Bring the'));
    expect(
      tester.getSemantics(row),
      isSemantics(isButton: true, hasTapAction: true),
    );
    semantics.dispose();
    await tester.tap(find.textContaining('halftime'));
    await tester.pumpAndSettle();
    final at = msg(31, '').createdAt!.millisecondsSinceEpoch;
    expect(location(tester), '/g/a/chat/m/m31?at=$at');
    expect(find.byType(ChatSearchScreen), findsNothing);
    final tile = tester.widget<MessageTile>(
      find.byWidgetPredicate((w) => w is MessageTile && w.message.id == 'm31'),
    );
    expect(tile.highlighted, isTrue);
    expect(onScreen(tester, 'Bring the oranges for halftime'), isTrue);
    // The highlight fades.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('a result from long ago opens the chat there in one page, '
      'with a way back to the newest', (tester) async {
    // 500 messages, Sam and Jo taking turns, so a page of 50 more than
    // fills the screen; the one found is the 5th.
    final repo = FakeMessageRepository(
      newestFirst([
        for (var i = 1; i <= 500; i++)
          msg(
            i,
            i == 5 ? 'The trophy is in my trunk' : 'Message $i',
            author: i.isOdd ? 'sam' : 'jo',
            name: i.isOdd ? 'Sam Rivera' : 'Jo Park',
          ),
      ]),
    );
    await openChat(tester, repo);
    await tester.pumpAndSettle();
    expect(onScreen(tester, 'Message 500'), isTrue);
    await tester.tap(find.byTooltip('Search the chat'));
    await tester.pumpAndSettle();
    await search(tester, 'trophy');
    await tester.tap(find.textContaining('trunk'));
    await tester.pumpAndSettle();

    expect(onScreen(tester, 'The trophy is in my trunk'), isTrue);
    // One page from just before it, not 500 messages of older pages: older
    // ones continue from it (the four before it, at 496), not from the
    // newest.
    final at = DateTime.fromMillisecondsSinceEpoch(
      msg(5, '').createdAt!.millisecondsSinceEpoch,
    );
    expect(repo.newerReads, [at.subtract(const Duration(milliseconds: 1))]);
    expect(repo.olderReads, everyElement(496));
    // Nothing new below, but the newest are a gap away: the button goes
    // back down to them.
    expect(find.text('Newest messages'), findsOneWidget);
    await tester.tap(find.text('Newest messages'));
    await tester.pumpAndSettle();
    expect(onScreen(tester, 'Message 500'), isTrue);

    // Scrolling up from it reaches the start of the chat.
    final state = ProviderScope.containerOf(
      tester.element(find.byType(CustomScrollView)),
    ).read(chatMessagesProvider(const GroupId('a')));
    expect(state.messages.map((m) => m.id), contains('m5'));
  });

  testWidgets('it leaves out deleted messages, system lines, and people I '
      'blocked (SAFE-2)', (tester) async {
    final safety = FakeSafetyRepository()
      ..blocks.add(const BlockedPerson(uid: UserId('pat'), name: 'Pat Kim'));
    final repo = FakeMessageRepository(
      newestFirst([
        msg(1, 'Jerseys came in today'),
        msg(2, 'Jerseys are wrong', author: 'pat', name: 'Pat Kim'),
        msg(3, 'Old jerseys message').copyWith(deletedAt: DateTime.now()),
        msg(4, 'Jerseys renamed the team', type: MessageType.system),
      ]),
    );
    await openChat(tester, repo, safety: safety);
    await tester.tap(find.byTooltip('Search the chat'));
    await tester.pumpAndSettle();
    await search(tester, 'jersey');
    expect(find.textContaining('came in today'), findsOneWidget);
    expect(find.textContaining('are wrong'), findsNothing);
    expect(find.textContaining('Old jerseys'), findsNothing);
    expect(find.textContaining('renamed the team'), findsNothing);
  });

  testWidgets('more results load as the list nears its end', (tester) async {
    final repo = FakeMessageRepository(
      newestFirst([for (var i = 1; i <= 45; i++) msg(i, 'Practice number $i')]),
    );
    await openChat(tester, repo);
    await tester.tap(find.byTooltip('Search the chat'));
    await tester.pumpAndSettle();
    await search(tester, 'practice');
    expect(repo.searches, hasLength(1));
    for (var i = 0; i < 20 && repo.searches.length < 3; i++) {
      await tester.drag(
        find.descendant(
          of: find.byType(ChatSearchScreen),
          matching: find.byType(ListView),
        ),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();
    }
    expect(repo.searches, hasLength(3));
    expect(find.textContaining('Practice number 1'), findsWidgets);
  });

  testWidgets('a failed search says so, and Retry searches again', (
    tester,
  ) async {
    final repo = FakeMessageRepository(newestFirst([msg(1, 'Rainout tonight')]))
      ..failSearch = const Offline('search');
    await openChat(tester, repo);
    await tester.tap(find.byTooltip('Search the chat'));
    await tester.pumpAndSettle();
    await search(tester, 'rainout');
    expect(
      find.text("Couldn't search. Check your connection and try again."),
      findsOneWidget,
    );
    repo.failSearch = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tonight'), findsOneWidget);
  });

  testWidgets('Ctrl+F opens it on the Chat tab, and it keeps the last search '
      'when it opens again', (tester) async {
    final repo = FakeMessageRepository(
      newestFirst([msg(1, 'Snacks are on the Lees this week')]),
    );
    await openChat(tester, repo);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearchScreen), findsOneWidget);
    await search(tester, 'snacks');
    expect(find.textContaining('Lees this week'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearchScreen), findsNothing);
    await tester.tap(find.byTooltip('Search the chat'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field()).controller?.text, 'snacks');
    expect(find.textContaining('Lees this week'), findsOneWidget);
    expect(repo.searches, hasLength(1));

    // Clearing starts over.
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field()).controller?.text, isEmpty);
    expect(find.textContaining('Lees this week'), findsNothing);
  });

  testWidgets('a direct conversation has its own search (CHAT-19)', (
    tester,
  ) async {
    final id = FakeGroupRepository.directId('coach', 'sam');
    final repo = FakeMessageRepository([
      msg(2, 'Can Alex get a ride Saturday?', group: id),
      msg(1, 'Ride to practice is set'),
    ]);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {
        'a': testGroup('a', 'Thunder'),
        id: testDirectChat(id, {'coach': 'Coach Lee', 'sam': 'Sam Rivera'}),
      },
      memberRepo: FakeMemberRepository([
        testMembership('a', 'coach', role: MemberRole.owner),
        testMembership('a', 'sam', name: 'Sam Rivera'),
        testParticipant(id, 'coach', 'sam', name: 'Coach Lee'),
        testParticipant(id, 'sam', 'coach', name: 'Sam Rivera'),
      ]),
      messageRepo: repo,
      size: phoneSize,
    );
    GoRouter.of(tester.element(find.byType(Navigator).first))
        .go('/messages/$id');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search this conversation'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: field(),
        matching: find.text('Search your messages with Sam Rivera'),
      ),
      findsOneWidget,
    );
    await search(tester, 'ride');
    // Only this conversation's.
    expect(find.textContaining('Saturday'), findsOneWidget);
    expect(find.textContaining('practice is set'), findsNothing);
    await tester.tap(find.textContaining('Saturday'));
    await tester.pumpAndSettle();
    final at = msg(2, '').createdAt!.millisecondsSinceEpoch;
    expect(location(tester), '/messages/$id/m/m2?at=$at');
  });

  test('the words found are in bold, from a little before the first', () {
    const bold = TextStyle(fontWeight: FontWeight.w800);
    final short = searchSnippet("O'Brien's mom has the snacks", [
      'obrien',
      'snack',
    ], bold);
    final parts = [
      for (final s in short.children!.cast<TextSpan>())
        (s.text, s.style == bold),
    ];
    expect(parts, [
      ("O'Brien's", true),
      (' mom has the ', false),
      ('snacks', true),
    ]);

    final long = searchSnippet(
      '${'Lots of other words before it, ' * 4}then the tournament.',
      ['tournament'],
      bold,
    );
    expect(long.toPlainText(), startsWith('…'));
    expect(long.toPlainText(), endsWith('then the tournament.'));
    expect(long.toPlainText().length, lessThan(70));
  });
}
