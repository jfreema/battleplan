// How the chat lays out messages, polls, event cards, quotes, reactions and
// photos in Open Field (SPEC §5.4.6, CHAT-1, CHAT-6, CHAT-11, CHAT-13,
// CHAT-18, POLL-3).
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/chat_screen.dart';
import 'package:battleplan/features/chat/presentation/message_tile.dart';
import 'package:battleplan/features/chat/presentation/photo_grid.dart';
import 'package:battleplan/features/chat/presentation/sprinkles.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/polls/presentation/poll_card.dart';
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart';

void main() {
  final start = DateTime.now().subtract(const Duration(hours: 2));

  Message msg(
    String id,
    int minute, {
    String author = 'sam',
    String name = 'Sam Rivera',
    String text = '',
    MessageType type = MessageType.text,
    Map<String, Reaction> reactions = const {},
    List<Attachment> attachments = const [],
    String? pollId,
    String? eventId,
  }) => Message(
    id: id,
    groupId: const GroupId('a'),
    authorId: author,
    authorName: name,
    type: type,
    text: text,
    reactions: reactions,
    attachments: attachments,
    pollId: pollId,
    eventId: eventId,
    createdAt: start.add(Duration(minutes: minute)),
  );

  Poll poll(String id, String by, {String option = 'Pizza'}) => Poll(
    id: PollId(id),
    groupId: const GroupId('a'),
    createdBy: by,
    question: 'Dinner?',
    options: [
      PollOption(id: '0', text: option),
      const PollOption(id: '1', text: 'Tacos'),
    ],
    voteCounts: const {'0': 2, '1': 1},
    voterCount: 3,
  );

  Future<void> openChat(
    WidgetTester tester,
    List<Message> messages, {
    List<Poll> polls = const [],
    Size size = phoneSize,
    Group? group,
    List<Membership>? members,
  }) async {
    final pollRepo = FakePollRepository();
    polls.forEach(pollRepo.put);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': group ?? testGroup('a', 'Thunder')},
      memberships:
          members ??
          [
            testMembership(
              'a',
              'coach',
              role: MemberRole.owner,
              name: 'Coach Lee',
            ).copyWith(lastReadAt: DateTime.now()),
            testMembership('a', 'sam', name: 'Sam Rivera'),
          ],
      messageRepo: FakeMessageRepository(messages),
      pollRepo: pollRepo,
      size: size,
    );
    await tester.pumpAndSettle();
  }

  group('polls', () {
    testWidgets("an option's text has the row but the count's width", (
      tester,
    ) async {
      const option = 'Saturday morning at the big park';
      await openChat(
        tester,
        [msg('p1', 1, type: MessageType.poll, text: 'Dinner?', pollId: 'p1')],
        polls: [poll('p1', 'sam', option: option)],
      );
      final row = tester.getSize(
        find.ancestor(of: find.text(option), matching: find.byType(Row)).first,
      );
      final text = tester.getSize(find.text(option));
      final count = tester.getSize(find.text('2 votes · 67%'));
      // The marker (18) and two gaps (8 each) are all that's left out: no
      // share of the row sits empty beside the count.
      expect(text.width + count.width, closeTo(row.width - 18 - 8 - 8, 1));
      expect(count.width, lessThanOrEqualTo(row.width / 2));
      expect(
        find.descendant(
          of: find
              .ancestor(of: find.text(option), matching: find.byType(Row))
              .first,
          matching: find.byType(Flexible),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a wide screen my poll sits on the right, as my other '
        "messages do, and others' on the left", (tester) async {
      await openChat(
        tester,
        [
          msg('t1', 3, author: 'coach', name: 'Coach Lee', text: 'Hi all'),
          msg(
            'p2',
            2,
            author: 'coach',
            name: 'Coach Lee',
            type: MessageType.poll,
            text: 'Dinner?',
            pollId: 'p2',
          ),
          msg('p1', 1, type: MessageType.poll, text: 'Dinner?', pollId: 'p1'),
        ],
        polls: [poll('p1', 'sam'), poll('p2', 'coach')],
        size: const Size(1024, 1400),
      );
      final cards = find.byType(PollCard);
      final mine = cards.evaluate().firstWhere(
        (e) => (e.widget as PollCard).mine,
      );
      final theirs = cards.evaluate().firstWhere(
        (e) => !(e.widget as PollCard).mine,
      );
      final myBox = mine.renderObject! as RenderBox;
      final theirBox = theirs.renderObject! as RenderBox;
      final myRight = myBox.localToGlobal(Offset(myBox.size.width, 0)).dx;
      final bubble = tester.getTopRight(
        find
            .ancestor(of: find.text('Hi all'), matching: find.byType(Padding))
            .first,
      );
      expect(myBox.size.width, 420);
      expect(myRight, closeTo(bubble.dx, 1));
      expect(theirBox.size.width, 420);
      expect(
        theirBox.localToGlobal(Offset.zero).dx,
        lessThan(myBox.localToGlobal(Offset.zero).dx - 100),
      );
    });

    testWidgets('my poll keeps an ink edge on a page close to its color, as '
        'my text bubbles do (CHAT-18)', (tester) async {
      await openChat(
        tester,
        [
          msg(
            'p2',
            2,
            author: 'coach',
            name: 'Coach Lee',
            type: MessageType.poll,
            text: 'Dinner?',
            pollId: 'p2',
          ),
        ],
        polls: [poll('p2', 'coach')],
        // The Army page's own color: it can't stand out without an edge.
        group: testGroup(
          'a',
          'Thunder',
        ).copyWith(chatTheme: const ChatTheme(bubbleColor: 0xFF474C2B)),
      );
      final edges = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(PollCard),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((b) => b.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border != null);
      expect(edges, isNotEmpty);
    });

    testWidgets("the votes sheet's icons have the person's initials, not "
        '"S#" from their number (POLL-3)', (tester) async {
      await openChat(
        tester,
        [msg('p1', 1, type: MessageType.poll, text: 'Dinner?', pollId: 'p1')],
        polls: [poll('p1', 'sam')],
        members: [
          testMembership('a', 'coach', role: MemberRole.owner),
          testMembership(
            'a',
            'sam',
            name: 'Sam Rivera',
          ).copyWith(playerSummary: '#12'),
        ],
      );
      await tester.tap(find.text('See votes'));
      await tester.pumpAndSettle();
      expect(find.text('Sam R. #12'), findsWidgets);
      final names = tester
          .widgetList<Avatar>(find.byType(Avatar))
          .map((a) => a.name);
      expect(names, contains('Sam Rivera'));
      expect(names.where((n) => n.contains('#')), isEmpty);
    });
  });

  group("others' messages on the page", () {
    testWidgets('a run of one-line messages sits close, with the menu as a '
        "screen reader's action", (tester) async {
      final handle = tester.ensureSemantics();
      await openChat(tester, [
        msg('m3', 3, text: 'save me a cone'),
        msg('m2', 2, text: 'on my way'),
        msg('m1', 1, text: 'ok'),
      ]);
      final a = tester.getRect(find.text('on my way'));
      final b = tester.getRect(find.text('save me a cone'));
      // 23 px lines, 3 + 3 between them.
      expect(b.top - a.top, closeTo(29, 0.5));
      final data = tester
          .getSemantics(find.text('on my way'))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.customAction), isTrue);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      // Long-press still opens the menu.
      await tester.longPress(find.text('on my way'));
      await tester.pumpAndSettle();
      expect(find.text('Copy text'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('reactions start under the text, just below it, each a 48 px '
        'target (CHAT-6)', (tester) async {
      final handle = tester.ensureSemantics();
      await openChat(tester, [
        msg('m2', 2, text: 'next one'),
        msg(
          'm1',
          1,
          text: 'Great hustle today',
          reactions: const {'coach': Reaction.like, 'jo': Reaction.fire},
        ),
      ]);
      final text = tester.getRect(find.text('Great hustle today'));
      final chip = find.bySemanticsLabel(RegExp('^Like, 1'));
      final target = tester.getSemantics(chip).rect;
      final area = tester.getRect(chip);
      expect(target.height, greaterThanOrEqualTo(48));
      expect(area.left, closeTo(text.left, 0.5));
      // The emoji sit 4 px under the text, and the tap area reaches up over
      // the text's last 10 px.
      expect(area.top, closeTo(text.bottom - 10, 0.5));
      final next = tester.getRect(find.text('next one'));
      expect(next.top - text.bottom, lessThan(48));
      // The reaction gets the tap there, and gives my reaction.
      await tester.tapAt(Offset(area.left + 8, area.top + 3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('their photos sit side by side, 100 tall and 6 apart', (
      tester,
    ) async {
      await openChat(tester, [
        msg(
          'm1',
          1,
          attachments: const [
            Attachment(path: 'groups/a/messages/m1/0.jpg', width: 8, height: 6),
            Attachment(path: 'groups/a/messages/m1/1.jpg', width: 8, height: 6),
            Attachment(path: 'groups/a/messages/m1/2.jpg', width: 8, height: 6),
          ],
        ),
      ]);
      final tiles = find.byType(StoredPhoto);
      expect(tiles, findsNWidgets(3));
      final first = tester.getRect(tiles.at(0));
      final second = tester.getRect(tiles.at(1));
      expect(first.height, 100);
      expect(second.left - first.right, closeTo(6, 0.5));
      expect(tester.widget<PhotoGrid>(find.byType(PhotoGrid)).onPage, isTrue);
    });

    testWidgets("a reply's quote on the page and in my bubble reads well "
        '(CHAT-13)', (tester) async {
      Message reply(String id, int minute, String author, String name) =>
          msg(id, minute, author: author, name: name, text: 'Yes!').copyWith(
            replyToId: 'q',
            replyPreview: const ReplyPreview(
              authorName: 'Jo Park',
              text: 'Who is driving?',
            ),
          );
      await openChat(tester, [
        reply('r2', 3, 'coach', 'Coach Lee'),
        reply('r1', 2, 'sam', 'Sam Rivera'),
      ]);
      final c = GumdropColors.of(
        tester.element(find.byType(MessageTile).first),
      );
      for (final quote in find.text('Who is driving?').evaluate()) {
        final style = (quote.widget as Text).style!;
        final well = tester
            .widget<Material>(
              find
                  .ancestor(
                    of: find.byWidget(quote.widget),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color!;
        final ink = Color.alphaBlend(style.color!, well);
        expect(ColorMath.contrast(ink, well), greaterThanOrEqualTo(4.5));
        // A solid well, not the card's see-through track.
        expect(well.a, 1);
        expect(well, isNot(c.cardTrack));
      }
    });
  });

  group('event cards', () {
    testWidgets("the chat's card has the schedule's attendance line, with "
        "who I answer for that hasn't answered", (tester) async {
      await pumpTeam(
        tester,
        scheme: TeamScheme.army,
        messages: FakeMessageRepository([
          msg('e', 1, type: MessageType.event, text: 'Practice', eventId: 'e2'),
        ]),
      );
      await tester.pumpAndSettle();
      // Noah, the coach's player, hasn't answered the practice.
      expect(find.byType(GoingBar), findsOneWidget);
      expect(
        find.textContaining("Noah hasn't answered", findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('3/4 going', findRichText: true), findsOne);
      // Sam's name over it, in the head line others' messages have.
      final head = tester.widget<RichText>(
        find.textContaining('Sam Rivera', findRichText: true).first,
      );
      // Text.rich puts its span under one with the line's style.
      final line = (head.text as TextSpan).children!.first as TextSpan;
      final name = line.children!.first as TextSpan;
      expect(name.style?.fontSize, 16);
      expect(name.style?.fontWeight, FontWeight.w800);
    });
  });

  group('the Chat look (CHAT-18)', () {
    test('the sprinkles and the photo are scrimmed enough for AA text in '
        'every scheme', () {
      for (final scheme in TeamScheme.values) {
        final c = GumdropColors.forScheme(scheme);
        for (final photo in [true, false]) {
          final scrim = chatBackdropScrim(c, photo: photo);
          final under = photo
              ? const [Color(0xFFFFFFFF), Color(0xFF000000)]
              : [
                  for (final s in Sprinkles.paletteOf(c))
                    Color.alphaBlend(s.withValues(alpha: 0.8), c.page),
                ];
          for (final u in under) {
            final ground = Color.alphaBlend(c.page.withValues(alpha: scrim), u);
            expect(
              ColorMath.contrast(c.textOnPage, ground),
              greaterThanOrEqualTo(4.5),
              reason: '$scheme $photo',
            );
            expect(
              ColorMath.contrast(
                Color.alphaBlend(c.textMutedOnPage, ground),
                ground,
              ),
              greaterThanOrEqualTo(4.5),
              reason: '$scheme $photo muted',
            );
          }
          if (photo) expect(scrim, greaterThanOrEqualTo(0.78));
        }
      }
    });

    testWidgets('the sprinkles sit under a page-colored scrim', (tester) async {
      await openChat(
        tester,
        [msg('m1', 1, text: 'hello')],
        group: testGroup('a', 'Thunder').copyWith(
          chatTheme: const ChatTheme(background: ChatBackground.pattern),
        ),
      );
      final stack = tester.widget<Stack>(
        find
            .ancestor(of: find.byType(Sprinkles), matching: find.byType(Stack))
            .first,
      );
      expect(stack.children.first, isA<Sprinkles>());
      final scrim = stack.children.last as ColoredBox;
      expect(scrim.color.a, greaterThan(0.5));
    });

    testWidgets("the team admin's preview draws others' message as the chat "
        'does: no bubble', (tester) async {
      await pumpTeam(tester, scheme: TeamScheme.army);
      await goTo(tester, '/g/a/settings');
      final preview = find.text('Practice moved to 6:30 tonight.');
      await tester.ensureVisible(preview);
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Avatar && w.name == 'Coach'),
        findsOneWidget,
      );
      // No card around it.
      final boxes = tester
          .widgetList<Container>(
            find.ancestor(of: preview, matching: find.byType(Container)),
          )
          .map((b) => b.decoration)
          .whereType<BoxDecoration>()
          .where(
            (d) => d.color == GumdropColors.of(tester.element(preview)).surface,
          );
      expect(boxes, isEmpty);
    });
  });

  testWidgets("an icon's initials keep their size at large text, so the "
      'circle never clips them', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Center(child: Avatar(name: 'Alex Kim', size: 36)),
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('AK')).textScaler,
      TextScaler.noScaling,
    );
  });

  testWidgets("the composer's hint is one line, however long the team's "
      'name', (tester) async {
    await openChat(
      tester,
      [msg('m1', 1, text: 'hello')],
      group: testGroup('a', 'Thunder U14 Girls Premier Select Blue'),
      size: const Size(320, 700),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintMaxLines, 1);
  });
}
