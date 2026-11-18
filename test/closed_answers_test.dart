import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/polls/presentation/poll_card.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/scenes.dart' as scenes;

/// #53 (owner's go 2026-11-17): what can't be pressed stops looking
/// pressable. A closed poll reads as a result: no rings, my plain check, a
/// trophy on the most votes, the other bars gray (POLL-2). A locked RSVP
/// answer is one flat tag, or "No reply", with no coral dot (SCHED-5).
void main() {
  const team = GroupId('a');

  Poll poll(
    Map<String, int> counts, {
    String id = 'p1',
    String createdBy = 'alex',
    bool closed = true,
    bool allowMultiple = false,
  }) => Poll(
    id: PollId(id),
    groupId: team,
    createdBy: createdBy,
    question: 'Saturday or Sunday?',
    options: const [
      PollOption(id: '0', text: 'Saturday'),
      PollOption(id: '1', text: 'Sunday'),
      PollOption(id: '2', text: 'Either'),
    ],
    voteCounts: counts,
    voterCount: counts.values.fold(0, (a, b) => a + b),
    allowMultiple: allowMultiple,
    closedAt: closed ? DateTime(2026, 11) : null,
  );

  Message pollMessage(String id, {String by = 'alex'}) => Message(
    id: id,
    groupId: team,
    authorId: by,
    authorName: by == 'alex' ? 'Alex Kim' : 'Coach Lee',
    type: MessageType.poll,
    pollId: id,
    createdAt: DateTime(2030, 10, 8, 9),
  );

  /// The scene's chat with [p], where the coach voted [mine].
  Future<void> openPoll(
    WidgetTester tester,
    Poll p, {
    Set<String> mine = const {},
    Group? group,
    TeamScheme scheme = TeamScheme.army,
  }) async {
    final polls = FakePollRepository()..put(p);
    polls.votes[p.id.value] = {'coach': mine};
    await scenes.pumpTeam(
      tester,
      scheme: scheme,
      pollRepo: polls,
      messages: FakeMessageRepository([
        pollMessage(p.id.value, by: p.createdBy),
      ]),
      team: group,
    );
  }

  /// An option's row, as screen readers hear it.
  Finder option(String startsWith) => find.byWidgetPredicate(
    (w) =>
        w is Semantics &&
        (w.properties.label?.startsWith('$startsWith, ') ?? false),
  );

  /// The 18 px rings and squares an open poll's options start with.
  Finder rings() => find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).border != null &&
        w.constraints == BoxConstraints.tight(const Size(18, 18)),
  );

  group('a closed poll reads as a result (POLL-2)', () {
    testWidgets('no rings; my check; the trophy and "most votes" on the '
        'winner; the rows are not buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await openPoll(tester, poll({'0': 7, '1': 3, '2': 1}), mine: {'1'});
      expect(rings(), findsNothing);
      expect(find.byIcon(AppIcons.check), findsOneWidget);
      expect(find.byIcon(AppIcons.trophy), findsOneWidget);
      final saturday = tester.widget<Semantics>(option('Saturday'));
      expect(saturday.properties.label, 'Saturday, 7 votes, 64%, most votes');
      expect(saturday.properties.button, isFalse);
      expect(
        tester.widget<Semantics>(option('Sunday')).properties.label,
        'Sunday, 3 votes, 27%, your choice',
      );
      // Not a choice any more: not "selected", and nothing taps it.
      expect(
        tester.widget<Semantics>(option('Sunday')).properties.selected,
        isNull,
      );
      expect(
        tester.widget<Semantics>(option('Sunday')).properties.onTap,
        isNull,
      );
      handle.dispose();
    });

    testWidgets('the winner keeps its mint bar; the others go gray', (
      tester,
    ) async {
      await openPoll(tester, poll({'0': 7, '1': 3, '2': 1}));
      final c = GumdropColors.of(
        tester.element(find.text('Saturday or Sunday?')),
      );
      final fills = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(FractionallySizedBox),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((b) => b.color)
          .toList();
      expect(fills, [
        c.mint.face,
        c.textMuted.withValues(alpha: 0.45),
        c.textMuted.withValues(alpha: 0.45),
      ]);
    });

    testWidgets('a tie marks each; no votes marks none', (tester) async {
      await openPoll(tester, poll({'0': 4, '1': 4, '2': 1}));
      expect(find.byIcon(AppIcons.trophy), findsNWidgets(2));
      await openPoll(tester, poll({}));
      expect(find.byIcon(AppIcons.trophy), findsNothing);
      expect(rings(), findsNothing);
    });

    testWidgets('a choose-any poll drops its squares too, and keeps my '
        'checks', (tester) async {
      await openPoll(
        tester,
        poll({'0': 6, '1': 2, '2': 6}, allowMultiple: true),
        mine: {'0', '2'},
      );
      expect(rings(), findsNothing);
      expect(find.byIcon(AppIcons.check), findsNWidgets(2));
      expect(find.byIcon(AppIcons.trophy), findsNWidgets(2));
    });

    testWidgets('the count still shows who chose it, and a tap on the row '
        'votes nothing', (tester) async {
      final polls = FakePollRepository()..put(poll({'0': 2, '1': 1}));
      polls.votes['p1'] = {
        'sam': {'0'},
        'jo': {'0'},
        'alex': {'1'},
      };
      await scenes.pumpTeam(
        tester,
        scheme: TeamScheme.army,
        pollRepo: polls,
        messages: FakeMessageRepository([pollMessage('p1')]),
      );
      await tester.tap(find.text('Sunday'));
      await tester.pumpAndSettle();
      expect(polls.votes['p1']?['coach'], isNull);
      await tester.tap(find.text('2 votes · 67%'));
      await tester.pumpAndSettle();
      expect(find.text('Saturday · 2 votes'), findsOneWidget);
    });

    testWidgets('my own closed poll, in my bubble, reads the same', (
      tester,
    ) async {
      await openPoll(
        tester,
        poll({'0': 8, '1': 3}, createdBy: 'coach'),
        mine: {'0'},
      );
      expect(rings(), findsNothing);
      // The card's check, not "Sent"'s under the bubble.
      expect(
        find.descendant(
          of: find.byType(PollCard),
          matching: find.byIcon(AppIcons.check),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(AppIcons.trophy), findsOneWidget);
    });
  });

  group('a poll nobody can vote in yet', () {
    testWidgets('an archived team: no rings, my check, and no winner', (
      tester,
    ) async {
      await openPoll(
        tester,
        poll({'0': 5, '1': 3}, closed: false),
        mine: {'0'},
        group: scenes.sceneTeam.copyWith(archivedAt: DateTime(2026, 11)),
      );
      expect(rings(), findsNothing);
      expect(find.byIcon(AppIcons.check), findsOneWidget);
      expect(find.byIcon(AppIcons.trophy), findsNothing);
    });

    testWidgets('an open poll I can vote in is unchanged', (tester) async {
      final handle = tester.ensureSemantics();
      await openPoll(tester, poll({'0': 5, '1': 3}, closed: false));
      expect(rings(), findsNWidgets(3));
      expect(find.byIcon(AppIcons.trophy), findsNothing);
      final saturday = tester.widget<Semantics>(option('Saturday'));
      expect(saturday.properties.button, isTrue);
      expect(saturday.properties.label, 'Saturday, 5 votes');
      handle.dispose();
    });
  });

  group('a locked answer is one flat tag (SCHED-5)', () {
    final past = DateTime.now().subtract(const Duration(hours: 1));
    List<Event> deadlinePassed() => [
      for (final e in scenes.sceneEvents) e.copyWith(rsvpDeadline: past),
    ];
    const two = [
      GuardianLink(
        playerId: PlayerId('leo'),
        groupId: team,
        uid: UserId('sam'),
      ),
      GuardianLink(
        playerId: PlayerId('mia'),
        groupId: team,
        uid: UserId('sam'),
      ),
    ];

    Future<void> openEvent(
      WidgetTester tester, {
      String id = 'e1',
      bool admin = false,
      TeamScheme scheme = TeamScheme.army,
    }) async {
      await scenes.pumpTeam(
        tester,
        scheme: scheme,
        user: admin ? scenes.coach : scenes.sam,
        events: deadlinePassed(),
        links: admin ? null : two,
      );
      await scenes.goTo(tester, '/g/a/schedule');
      await scenes.pushTo(tester, '/g/a/schedule/e/$id');
    }

    testWidgets("a member past the deadline sees each player's answer as a "
        'tag, not buttons, with the note under it', (tester) async {
      final handle = tester.ensureSemantics();
      await openEvent(tester);
      expect(find.byType(SegmentedButton<RsvpStatus>), findsNothing);
      expect(
        find.text(
          'The RSVP deadline has passed. Only admins can change answers.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Going. RSVPs are closed.'), findsOneWidget);
      expect(find.bySemanticsLabel('Maybe. RSVPs are closed.'), findsOneWidget);
      // Under Mia's tag, and in Who's going.
      expect(find.text('"Bringing snacks"'), findsNWidgets(2));
      // No Add a note or Clear.
      expect(find.text('Add a note'), findsNothing);
      handle.dispose();
    });

    testWidgets('no answer is "No reply"', (tester) async {
      final handle = tester.ensureSemantics();
      await openEvent(tester, id: 'e2');
      expect(
        find.bySemanticsLabel('No reply. RSVPs are closed.'),
        findsNWidgets(2),
      );
      handle.dispose();
    });

    testWidgets('an admin past the deadline still has the buttons', (
      tester,
    ) async {
      await openEvent(tester, admin: true);
      final buttons = tester.widget<SegmentedButton<RsvpStatus>>(
        find.byType(SegmentedButton<RsvpStatus>),
      );
      expect(buttons.onSelectionChanged, isNotNull);
    });

    testWidgets("a started event's schedule rows show tags, with no coral "
        'dot on an unanswered one', (tester) async {
      final handle = tester.ensureSemantics();
      final now = DateTime.now();
      // Started, but today where the team is (Chicago), or Upcoming
      // leaves it out: just after midnight, half an hour ago is yesterday.
      final local = ZonedTime.wallClock('America/Chicago', now);
      final today = Duration(
        hours: local.hour,
        minutes: local.minute,
        seconds: local.second,
      );
      const ago = Duration(minutes: 30);
      final started = [
        for (final e in scenes.sceneEvents)
          if (e.id.value == 'e1' || e.id.value == 'e2')
            e.copyWith(
              startAt: now.subtract(today > ago ? ago : today ~/ 2),
              endAt: now.add(const Duration(hours: 1)),
            ),
      ];
      await scenes.pumpTeam(
        tester,
        scheme: TeamScheme.army,
        user: scenes.sam,
        events: started,
        links: two,
      );
      await scenes.goTo(tester, '/g/a/schedule');
      expect(find.byType(SegmentedButton<RsvpStatus>), findsNothing);
      expect(find.bySemanticsLabel('Going. RSVPs are closed.'), findsOneWidget);
      expect(
        find.bySemanticsLabel('No reply. RSVPs are closed.'),
        findsNWidgets(2),
      );
      final you = GumdropColors.of(tester.element(find.text('Practice').first))
          .you
          .face;
      final dots = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == you &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
            w.constraints == BoxConstraints.tight(const Size(8, 8)),
      );
      expect(dots, findsNothing);
      handle.dispose();
    });

    testWidgets('reads well: contrast in all five schemes, and 200% text', (
      tester,
    ) async {
      for (final scheme in TeamScheme.values) {
        await openEvent(tester, scheme: scheme);
        final handle = tester.ensureSemantics();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
        await openPoll(
          tester,
          poll({'0': 7, '1': 3, '2': 1}),
          mine: {'1'},
          scheme: scheme,
        );
        final again = tester.ensureSemantics();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        again.dispose();
      }
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await scenes.pumpTeam(
        tester,
        scheme: TeamScheme.light,
        size: const Size(320, 700),
        user: scenes.sam,
        events: deadlinePassed(),
        links: two,
      );
      await scenes.goTo(tester, '/g/a/schedule');
      await scenes.pushTo(tester, '/g/a/schedule/e/e1');
      expect(tester.takeException(), isNull);
      await openPoll(tester, poll({'0': 7, '1': 3, '2': 1}), mine: {'1'});
      expect(tester.takeException(), isNull);
    });
  });
}
