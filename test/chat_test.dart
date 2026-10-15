// The chat's paging, read position, delivery, and photo input (SPEC CHAT-1,
// CHAT-2, CHAT-4, CHAT-9, CHAT-12, CHAT-18, CHAT acceptance, §8.1).
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/chat_queue_store.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/message_tile.dart';
import 'package:battleplan/features/chat/presentation/photo_grid.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart';

void main() {
  final start = DateTime.now().subtract(const Duration(days: 1));

  /// Message [i] from Sam, [i] minutes after [start].
  Message msg(
    int i, {
    String author = 'sam',
    String name = 'Sam Rivera',
    MessageType type = MessageType.text,
  }) => Message(
    id: 'm$i',
    groupId: const GroupId('a'),
    authorId: author,
    authorName: name,
    type: type,
    text: 'Message $i',
    createdAt: start.add(Duration(minutes: i)),
  );

  /// Messages 1 to [count], newest first, as the repository keeps them.
  List<Message> chat(int count) => [for (var i = count; i >= 1; i--) msg(i)];

  Future<void> openChat(
    WidgetTester tester,
    FakeMessageRepository repo, {
    DateTime? readAt,
    FakeMemberRepository? members,
    FakeSafetyRepository? safety,
    Group? group,
    FakePhotoPicker? picker,
    List<Override> overrides = const [],
  }) => pumpApp(
    tester,
    auth: FakeAuthRepository(user: coach),
    groups: {'a': group ?? testGroup('a', 'Thunder')},
    memberRepo:
        members ??
        FakeMemberRepository([
          testMembership(
            'a',
            'coach',
            role: MemberRole.owner,
          ).copyWith(lastReadAt: readAt),
          testMembership('a', 'sam', name: 'Sam Rivera'),
        ]),
    messageRepo: repo,
    safety: safety,
    photoPicker: picker,
    overrides: overrides,
  );

  /// Team a's chat as the screen has it.
  ChatState chatState(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(CustomScrollView)))
          .read(chatMessagesProvider(const GroupId('a')));

  /// Whether [text] is on screen, not just built off it.
  bool onScreen(WidgetTester tester, String text) =>
      find.text(text).hitTestable().evaluate().isNotEmpty;

  group('opening at the first unread message (CHAT-1, CHAT-9)', () {
    testWidgets('with more unread than one page holds, it opens at the '
        'first unread and loads the rest scrolling down', (tester) async {
      // 100 unread after message 20: twice what the newest page holds.
      final repo = FakeMessageRepository(chat(120));
      await openChat(tester, repo, readAt: msg(20).createdAt);
      await tester.pumpAndSettle();
      // It read the 50 after the marker, as well as the newest 50.
      expect(repo.newerReads, [msg(20).createdAt]);
      expect(find.text('New messages'), findsOneWidget);
      expect(onScreen(tester, 'Message 21'), isTrue);
      expect(onScreen(tester, 'Message 120'), isFalse);
      // The divider sits right above the first unread message.
      final divider = tester.getRect(find.text('New messages'));
      final first = tester.getRect(find.text('Message 21'));
      expect(first.top, greaterThan(divider.bottom));
      expect(
        tester.getRect(find.text('Message 20')).bottom,
        lessThan(divider.top),
      );

      // Scrolling down loads the messages in between, then reaches the
      // newest ones.
      for (var i = 0; i < 40 && !onScreen(tester, 'Message 120'); i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
        await tester.pumpAndSettle();
      }
      expect(repo.newerReads, hasLength(greaterThan(1)));
      expect(onScreen(tester, 'Message 120'), isTrue);
      // Nothing missing between the first unread and the newest.
      final state = chatState(tester);
      expect(state.gapAfter, isNull);
      expect(
        state.messages.map((m) => m.id),
        containsAll([for (var i = 21; i <= 120; i++) 'm$i']),
      );
    });

    testWidgets('cards that fill in after it opens leave it at the first '
        'unread, not stuck to the newest', (tester) async {
      // The coach's polls after the marker, still on their way when the
      // chat opens: everything unread fits, so it opens at the bottom.
      Message poll(int i) => msg(
        i,
        author: 'coach',
        name: 'Jordan Coach',
        type: MessageType.poll,
      ).copyWith(text: 'Poll $i', pollId: 'p$i');
      final repo = FakeMessageRepository([
        msg(5),
        poll(4),
        poll(3),
        msg(2),
        msg(1),
      ]);
      final polls = FakePollRepository();
      final members = FakeMemberRepository([
        testMembership(
          'a',
          'coach',
          role: MemberRole.owner,
        ).copyWith(lastReadAt: msg(1).createdAt),
        testMembership('a', 'sam', name: 'Sam Rivera'),
      ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberRepo: members,
        messageRepo: repo,
        pollRepo: polls,
        size: const Size(390, 844),
      );
      await tester.pumpAndSettle();
      expect(onScreen(tester, 'Message 2'), isTrue);
      // They arrive, more than a screen of them, with the read marker the
      // chat wrote: the first unread stays in view.
      for (final i in [3, 4]) {
        polls.put(
          Poll(
            id: PollId('p$i'),
            groupId: const GroupId('a'),
            createdBy: 'coach',
            question: 'Poll $i',
            options: [
              for (var o = 0; o < 4; o++) PollOption(id: '$o', text: 'Day $o'),
            ],
          ),
        );
      }
      members.echoRead(
        const GroupId('a'),
        const UserId('coach'),
        msg(2).createdAt!,
      );
      await tester.pumpAndSettle();
      expect(onScreen(tester, 'New messages'), isTrue);
      expect(onScreen(tester, 'Message 2'), isTrue);
      expect(onScreen(tester, 'Message 5'), isFalse);
      // Scrolling down from there reaches the newest, and stays with it.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(onScreen(tester, 'Message 5'), isTrue);
      repo
        ..messages.insert(0, msg(6))
        ..refresh();
      await tester.pumpAndSettle();
      expect(onScreen(tester, 'Message 6'), isTrue);
    });

    testWidgets("switching teams opens the other team's chat at its own "
        'first unread', (tester) async {
      Message inB(int i) => msg(i)
          .copyWith(id: 'b$i', groupId: const GroupId('b'), text: 'Team B $i');
      final repo = FakeMessageRepository([
        inB(3),
        msg(3),
        inB(2),
        msg(2),
        inB(1),
        msg(1),
      ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          'a': testGroup('a', 'Thunder'),
          'b': testGroup('b', 'Cyclone'),
        },
        memberRepo: FakeMemberRepository([
          // All of Thunder's read; Cyclone's from its second message on.
          testMembership(
            'a',
            'coach',
            role: MemberRole.owner,
          ).copyWith(lastReadAt: msg(3).createdAt),
          testMembership(
            'b',
            'coach',
            role: MemberRole.owner,
          ).copyWith(lastReadAt: inB(1).createdAt),
          testMembership('a', 'sam', name: 'Sam Rivera'),
          testMembership('b', 'sam', name: 'Sam Rivera'),
        ]),
        messageRepo: repo,
      );
      await tester.pumpAndSettle();
      expect(find.text('Message 3'), findsOneWidget);
      expect(find.text('New messages'), findsNothing);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/g/b/chat');
      await tester.pumpAndSettle();
      expect(find.text('Team B 3'), findsOneWidget);
      final divider = tester.getRect(find.text('New messages'));
      expect(
        tester.getRect(find.text('Team B 1')).bottom,
        lessThan(divider.top),
      );
      expect(
        tester.getRect(find.text('Team B 2')).top,
        greaterThan(divider.bottom),
      );
    });

    testWidgets('a stale offline page first still opens at the first unread '
        'once the server page arrives', (tester) async {
      // The cache has only what was seen last time, up to the marker.
      final repo = FakeMessageRepository(chat(30))..offline = true;
      await openChat(tester, repo, readAt: msg(30).createdAt);
      await tester.pumpAndSettle();
      expect(repo.newerReads, isEmpty);
      // The server has 120 more since.
      repo
        ..messages.insertAll(0, [for (var i = 150; i > 30; i--) msg(i)])
        ..offline = false
        ..refresh();
      await tester.pumpAndSettle();
      expect(repo.newerReads, [msg(30).createdAt]);
      expect(find.text('New messages'), findsOneWidget);
      expect(onScreen(tester, 'Message 31'), isTrue);
      expect(onScreen(tester, 'Message 150'), isFalse);
    });

    testWidgets('scrolling up from the first unread loads older messages', (
      tester,
    ) async {
      final repo = FakeMessageRepository(chat(200));
      await openChat(tester, repo, readAt: msg(120).createdAt);
      await tester.pumpAndSettle();
      for (var i = 0; i < 40 && repo.olderReads.isEmpty; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 800));
        await tester.pumpAndSettle();
      }
      // Older pages continue from the first unread message back.
      expect(repo.olderReads.first, 80);
      expect(chatState(tester).messages.map((m) => m.id), contains('m75'));
    });

    testWidgets('reading partway up moves the marker to the newest message '
        'on screen', (tester) async {
      final members = FakeMemberRepository([
        testMembership(
          'a',
          'coach',
          role: MemberRole.owner,
        ).copyWith(lastReadAt: msg(20).createdAt),
      ]);
      final repo = FakeMessageRepository(chat(120));
      await openChat(tester, repo, members: members);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      // Not everything: up to a message on screen, past the old marker.
      expect(members.readsUpTo, isNotEmpty);
      final upTo = members.readsUpTo.last;
      expect(upTo.isAfter(msg(21).createdAt!), isTrue);
      expect(upTo.isBefore(msg(120).createdAt!), isTrue);
      final shown = upTo.difference(start).inMinutes;
      expect(onScreen(tester, 'Message $shown'), isTrue);
    });
  });

  testWidgets('jumping to a quote waits for a gap page already loading, '
      'then still reaches older messages (CHAT-13)', (tester) async {
    final repo = FakeMessageRepository(chat(500));
    await openChat(tester, repo, readAt: msg(300).createdAt);
    await tester.pumpAndSettle();
    expect(chatState(tester).gapAfter, isNotNull);
    expect(chatState(tester).messages.map((m) => m.id), isNot(contains('m5')));
    final controller = ProviderScope.containerOf(
      tester.element(find.byType(CustomScrollView)),
    ).read(chatMessagesProvider(const GroupId('a')).notifier);
    // Scrolling down started loading the gap; then a quote is tapped.
    final hold = repo.holdNewer = Completer<void>();
    unawaited(controller.loadNewer());
    var found = false;
    unawaited(controller.loadUntil('m5').then((f) => found = f));
    await tester.pump();
    repo.holdNewer = null;
    hold.complete();
    await tester.pumpAndSettle();
    expect(found, isTrue);
    expect(chatState(tester).gapAfter, isNull);
  });

  testWidgets('a chat with 10,000 messages opens with one page (CHAT '
      'acceptance)', (tester) async {
    final repo = FakeMessageRepository(chat(10000));
    await openChat(tester, repo, readAt: msg(10000).createdAt);
    await tester.pumpAndSettle();
    expect(repo.olderReads, isEmpty);
    expect(repo.newerReads, isEmpty);
    expect(onScreen(tester, 'Message 10000'), isTrue);
    expect(
      find.byType(MessageTile, skipOffstage: false).evaluate().length,
      lessThanOrEqualTo(50),
    );
  });

  testWidgets('unread counts leave out system lines and blocked people '
      '(CHAT-9, CHAT-12)', (tester) async {
    final safety = FakeSafetyRepository()
      ..blocks.add(const BlockedPerson(uid: UserId('pat'), name: 'Pat Kim'));
    final repo = FakeMessageRepository([
      msg(5, author: 'pat', name: 'Pat Kim'),
      msg(4, type: MessageType.system, author: 'system', name: ''),
      msg(3),
      msg(2),
    ]);
    await openChat(
      tester,
      repo,
      readAt: msg(2).createdAt,
      safety: safety,
      group: testGroup('a', 'Thunder', lastMessageAt: msg(5).createdAt),
    );
    // Only Sam's message 3 counts.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
    );
  });

  group('delivery (CHAT-4)', () {
    testWidgets('each of my messages says it was sent, with its time', (
      tester,
    ) async {
      final repo = FakeMessageRepository([
        for (final i in [3, 2, 1]) msg(i, author: 'coach', name: 'Coach'),
      ]);
      await openChat(tester, repo, readAt: msg(3).createdAt);
      // Under my newest message.
      expect(find.text('Sent'), findsOneWidget);
      await tester.tap(find.text('Message 2'));
      // Past the wait for a double tap (which loves it, CHAT-6).
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.textContaining(' · Sent'), findsOneWidget);
    });

    testWidgets('texts queued offline survive the app closing, and go out '
        'when it opens the chat again', (tester) async {
      final store = MemoryChatQueueStore();
      await store.save(const GroupId('a'), [
        const SavedText(id: 'q1', text: 'Running late'),
        // Already in the chat (the offline cache kept it): not sent twice.
        const SavedText(id: 'm1', text: 'Message 1'),
      ]);
      final repo = FakeMessageRepository([msg(1)]);
      await openChat(
        tester,
        repo,
        readAt: msg(1).createdAt,
        overrides: [chatQueueStoreProvider.overrideWithValue(store)],
      );
      await tester.pump(const Duration(seconds: 2));
      // The fake's live page can miss a send this early; the server's won't.
      repo.refresh();
      await tester.pumpAndSettle();
      expect(repo.sent, ['Running late']);
      expect(store.load(const GroupId('a')), isEmpty);
      expect(find.text('Running late'), findsOneWidget);
    });

    testWidgets('a message not sent yet stays saved on the device', (
      tester,
    ) async {
      final store = MemoryChatQueueStore();
      final repo = FakeMessageRepository()..failSends = const Offline('test');
      await openChat(
        tester,
        repo,
        overrides: [chatQueueStoreProvider.overrideWithValue(store)],
      );
      await tester.enterText(find.byType(TextField), 'See you at 6');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(store.load(const GroupId('a')).single.text, 'See you at 6');
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(store.load(const GroupId('a')), isEmpty);
    });

    testWidgets('photos wait for a connection, then send by themselves', (
      tester,
    ) async {
      final repo = FakeMessageRepository()..offline = true;
      await openChat(
        tester,
        repo,
        picker: FakePhotoPicker([(bytes: tinyPng, contentType: 'image/png')]),
      );
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo library'));
      await tester.pumpAndSettle();
      expect(repo.photoBatches, isEmpty);
      expect(find.text('Waiting for a connection…'), findsOneWidget);

      repo
        ..offline = false
        ..refresh();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(repo.photoBatches, [1]);
      expect(find.text('Waiting for a connection…'), findsNothing);
    });
  });

  testWidgets('photos pasted or dragged in send as one message (CHAT-2)', (
    tester,
  ) async {
    final drops = FakePhotoDrops();
    final repo = FakeMessageRepository();
    await openChat(
      tester,
      repo,
      overrides: [photoDropsProvider.overrideWithValue(drops)],
    );
    drops.drop([
      (bytes: tinyPng, contentType: 'image/jpeg'),
      (bytes: tinyPng, contentType: 'image/jpeg'),
    ]);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(repo.photoBatches, [2]);
  });

  testWidgets('phones save a photo to the photo library (CHAT-3)', (
    tester,
  ) async {
    final saver = FakePhotoSaver();
    final repo = FakeMessageRepository([
      msg(1).copyWith(
        type: MessageType.image,
        text: '',
        attachments: const [Attachment(path: 'groups/a/messages/m1/0.jpg')],
      ),
    ])..photoBytes = tinyPng;
    await openChat(
      tester,
      repo,
      readAt: msg(1).createdAt,
      overrides: [photoSaverProvider.overrideWithValue(saver)],
    );
    await tester.tap(find.byType(StoredPhoto));
    // Past the wait for a double tap (which loves it, CHAT-6).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save photo'));
    await tester.pumpAndSettle();
    expect(saver.saved, ['battleplan-photo-1']);
    expect(find.text('Photo saved.'), findsOneWidget);
  });

  group('mentions, pins, and announcements (CHAT-14, CHAT-15)', () {
    /// A plain member's view of the team: Coach isn't an admin.
    FakeMemberRepository asMember() => FakeMemberRepository([
      testMembership('a', 'coach', name: 'Coach Lee'),
      testMembership('a', 'sam', name: 'Sam Rivera'),
    ]);

    /// The composer's text field.
    Finder composer() => find.byType(TextField).last;

    String typed(WidgetTester tester) =>
        tester.widget<TextField>(composer()).controller!.text;

    Future<void> send(WidgetTester tester) async {
      // Typing enables Send on the next frame.
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    testWidgets('typing @ suggests people; the one picked is named', (
      tester,
    ) async {
      final repo = FakeMessageRepository([msg(1)]);
      await openChat(tester, repo, readAt: msg(1).createdAt);
      await tester.enterText(composer(), 'Thanks @sa');
      await tester.pumpAndSettle();
      final suggestion = find.widgetWithText(ListTile, 'Sam Rivera');
      expect(suggestion, findsOneWidget);
      // Nobody is offered themselves.
      expect(find.widgetWithText(ListTile, 'Coach Lee'), findsNothing);
      await tester.tap(suggestion);
      await tester.pumpAndSettle();
      expect(typed(tester), 'Thanks @Sam Rivera ');
      expect(suggestion, findsNothing);
      await send(tester);
      expect(repo.sent, ['Thanks @Sam Rivera']);
      expect(repo.sentDetails.single.mentions, ['sam']);
      expect(repo.sentDetails.single.everyone, isFalse);
    });

    testWidgets('a name typed out in full counts too, and Escape closes the '
        'list', (tester) async {
      final repo = FakeMessageRepository([msg(1)]);
      await openChat(tester, repo, readAt: msg(1).createdAt);
      await tester.enterText(composer(), '@sam');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Sam Rivera'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Sam Rivera'), findsNothing);
      await tester.enterText(composer(), '@sam rivera, can you drive?');
      await tester.pumpAndSettle();
      await send(tester);
      expect(repo.sentDetails.single.mentions, ['sam']);
    });

    testWidgets('the arrow keys and Enter pick a suggestion', (tester) async {
      final repo = FakeMessageRepository([msg(1)]);
      await openChat(
        tester,
        repo,
        readAt: msg(1).createdAt,
        members: FakeMemberRepository([
          testMembership('a', 'coach', role: MemberRole.owner),
          testMembership('a', 'sam', name: 'Sam Rivera'),
          testMembership('a', 'sal', name: 'Sal Ortiz'),
        ]),
      );
      await tester.enterText(composer(), '@sa');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      // Sal comes before Sam; the arrow moved to Sam, and Enter picked
      // him instead of sending.
      expect(typed(tester), '@Sam Rivera ');
      expect(repo.sent, isEmpty);
    });

    testWidgets('strong language goes out masked unless the team turned '
        'the filter off (SAFE-7)', (tester) async {
      final repo = FakeMessageRepository([msg(1)]);
      await openChat(tester, repo, readAt: msg(1).createdAt);
      await tester.enterText(composer(), 'What the fuck, ref');
      await send(tester);
      expect(repo.sent, ['What the f***, ref']);

      final unfiltered = FakeMessageRepository([msg(1)]);
      await openChat(
        tester,
        unfiltered,
        readAt: msg(1).createdAt,
        group: testGroup(
          'a',
          'Thunder',
        ).copyWith(settings: const GroupSettings(filterLanguage: false)),
      );
      await tester.enterText(composer(), 'What the fuck, ref');
      await send(tester);
      expect(unfiltered.sent, ['What the fuck, ref']);
    });

    testWidgets('@everyone is for admins', (tester) async {
      final repo = FakeMessageRepository([msg(1)]);
      await openChat(tester, repo, readAt: msg(1).createdAt);
      await tester.enterText(composer(), '@ev');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, '@everyone'));
      await tester.pumpAndSettle();
      await tester.enterText(composer(), '${typed(tester)}game moved to 5');
      await send(tester);
      expect(repo.sent, ['@everyone game moved to 5']);
      expect(repo.sentDetails.single.everyone, isTrue);
    });

    testWidgets('a member gets no @everyone, and typing it names nobody', (
      tester,
    ) async {
      final repo = FakeMessageRepository([msg(1)]);
      await openChat(
        tester,
        repo,
        readAt: msg(1).createdAt,
        members: asMember(),
      );
      await tester.enterText(composer(), '@ev');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, '@everyone'), findsNothing);
      await tester.enterText(composer(), '@everyone hi');
      await send(tester);
      expect(repo.sentDetails.single.everyone, isFalse);
    });

    testWidgets('an admin sends an announcement from the + menu', (
      tester,
    ) async {
      final repo = FakeMessageRepository([msg(1)]);
      await openChat(tester, repo, readAt: msg(1).createdAt);
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Announcement'));
      await tester.pumpAndSettle();
      expect(find.textContaining('notifies everyone'), findsOneWidget);
      await tester.enterText(composer(), 'No practice Friday');
      await send(tester);
      expect(repo.sentDetails.single.announcement, isTrue);
      // The banner goes with it; the next message is plain.
      expect(find.textContaining('notifies everyone'), findsNothing);
      // Shown as an announcement in the chat.
      expect(find.text('Announcement'), findsOneWidget);
      await tester.enterText(composer(), 'And bring water');
      await send(tester);
      expect(repo.sentDetails.last.announcement, isFalse);
    });

    testWidgets('✕ cancels an announcement; members have none', (tester) async {
      final repo = FakeMessageRepository([msg(1)]);
      await openChat(tester, repo, readAt: msg(1).createdAt);
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Announcement'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancel announcement'));
      await tester.pumpAndSettle();
      await tester.enterText(composer(), 'Just a message');
      await send(tester);
      expect(repo.sentDetails.single.announcement, isFalse);

      await openChat(
        tester,
        FakeMessageRepository([msg(1)]),
        readAt: msg(1).createdAt,
        members: asMember(),
      );
      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      expect(find.text('Announcement'), findsNothing);
    });

    testWidgets('admins pin a message to the bar at the top, and unpin it', (
      tester,
    ) async {
      final repo = FakeMessageRepository([msg(2), msg(1)]);
      await openChat(tester, repo, readAt: msg(2).createdAt);
      await tester.longPress(find.text('Message 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pin'));
      await tester.pumpAndSettle();
      expect(repo.pins, ['m1 pinned']);
      expect(find.text('Pinned message'), findsOneWidget);
      expect(find.text('Sam Rivera: Message 1'), findsOneWidget);
      expect(find.textContaining('Pinned', findRichText: true), findsWidgets);

      await tester.longPress(find.text('Message 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unpin'));
      await tester.pumpAndSettle();
      expect(repo.pins, ['m1 pinned', 'm1 unpinned']);
      expect(find.text('Pinned message'), findsNothing);
    });

    testWidgets('an imported message says where it came from; it can be '
        'reported, but its author has no account to block (IMPORT-9)', (
      tester,
    ) async {
      final imported = msg(
        1,
        author: 'groupme:22',
        name: 'Riley',
      ).copyWith(importedFrom: 'groupme');
      final repo = FakeMessageRepository([msg(2), imported]);
      await openChat(tester, repo, readAt: msg(2).createdAt);
      expect(
        find.textContaining('from GroupMe', findRichText: true),
        findsOneWidget,
      );
      await tester.longPress(find.text('Message 1'));
      await tester.pumpAndSettle();
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Block Riley'), findsNothing);
    });

    testWidgets('the bar shows the newest pin first and steps through them', (
      tester,
    ) async {
      final repo = FakeMessageRepository(chat(3));
      await openChat(
        tester,
        repo,
        readAt: msg(3).createdAt,
        group: testGroup(
          'a',
          'Thunder',
        ).copyWith(pinnedMessageIds: ['m1', 'm2']),
      );
      expect(find.text('Pinned 1 of 2'), findsOneWidget);
      expect(find.text('Sam Rivera: Message 2'), findsOneWidget);
      await tester.tap(find.text('Pinned 1 of 2'));
      await tester.pumpAndSettle();
      expect(find.text('Pinned 2 of 2'), findsOneWidget);
      expect(find.text('Sam Rivera: Message 1'), findsOneWidget);
    });

    testWidgets('a full bar says to unpin one first; members get no Pin', (
      tester,
    ) async {
      final repo = FakeMessageRepository([msg(1)])
        ..failPins = const InvalidInput('too-many-pins');
      await openChat(tester, repo, readAt: msg(1).createdAt);
      await tester.longPress(find.text('Message 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pin'));
      await tester.pumpAndSettle();
      expect(
        find.text('Up to 3 messages can be pinned. Unpin one first.'),
        findsOneWidget,
      );

      await openChat(
        tester,
        FakeMessageRepository([msg(1)]),
        readAt: msg(1).createdAt,
        members: asMember(),
      );
      await tester.longPress(find.text('Message 1'));
      await tester.pumpAndSettle();
      expect(find.text('Copy text'), findsOneWidget);
      expect(find.text('Pin'), findsNothing);
    });
  });
}
