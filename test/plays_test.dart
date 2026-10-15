// Plays (SPEC §6.16, BOARD-1 to BOARD-4): the boards and their starting
// spots, drawing and undoing, steps, saving through the repository, and
// who may do what.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/plays/data/firestore_play_repository.dart';
import 'package:battleplan/features/plays/data/prefs_whiteboard_store.dart';
import 'package:battleplan/features/plays/domain/board_edit.dart';
import 'package:battleplan/features/plays/domain/board_layout.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/presentation/board_painter.dart';
import 'package:battleplan/features/plays/presentation/play_editor_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

const _marker = BoardElement.marker(
  id: 'm1',
  at: (x: 0.5, y: 0.5),
  side: MarkerSide.team,
  label: 'P',
);

void main() {
  group('boards and their starting spots (BOARD-1)', () {
    test('every formation stands on its board', () {
      for (final board in PlayBoard.values) {
        for (final v in boardVariants(board)) {
          for (final f in [
            ...teamFormations(board, v),
            ...opponentFormations(board, v),
          ]) {
            for (final s in f.spots) {
              expect(
                s.at.x,
                inInclusiveRange(0, 1),
                reason: '${f.id} ${s.label}',
              );
              expect(
                s.at.y,
                inInclusiveRange(0, 1),
                reason: '${f.id} ${s.label}',
              );
            }
          }
        }
      }
    });

    test("baseball's nine stand at their positions on the diamond", () {
      final field = teamFormations(
        PlayBoard.baseball,
        BoardVariant.full,
      ).single;
      expect(field.spots.map((s) => s.label), [
        'P', 'C', '1B', '2B', 'SS', '3B', 'LF', 'CF', 'RF', //
      ]);
      Spot at(String label) => field.spots.firstWhere((s) => s.label == label);
      // The pitcher on the mound, the catcher behind the plate, the
      // outfield deeper than second base.
      expect(at('P').at, BaseballField.mound);
      expect(at('C').at.y, greaterThan(BaseballField.home.y));
      expect(at('CF').at.y, lessThan(BaseballField.second.y));
      expect(at('1B').at.x, greaterThan(0.5));
      expect(at('3B').at.x, lessThan(0.5));
    });

    test('each sport starts on its board; softball on the diamond', () {
      expect(boardForSport(Sport.softball), PlayBoard.baseball);
      expect(boardForSport(Sport.basketball), PlayBoard.basketball);
      expect(boardForSport(Sport.soccer), PlayBoard.soccer);
      expect(boardForSport(Sport.football), PlayBoard.football);
      expect(boardForSport(Sport.volleyball), PlayBoard.blank);
      expect(boardVariants(PlayBoard.basketball), [
        BoardVariant.half,
        BoardVariant.full,
      ]);
      // Football's X's and O's: eleven on each side.
      final step = startingStep(
        teamFormations(PlayBoard.football, BoardVariant.full).first,
        opponentFormations(PlayBoard.football, BoardVariant.full).first,
      );
      final markers = step.elements.whereType<MarkerElement>();
      expect(markers.where((m) => m.side == MarkerSide.team), hasLength(11));
      expect(
        markers.where((m) => m.side == MarkerSide.opponent),
        hasLength(11),
      );
    });
  });

  group('drawing (BOARD-2, BOARD-3)', () {
    test('adds, moves while dragging, and undoes a drag in one go', () {
      var edit = const BoardEdit(steps: [PlayStep()]).add(_marker);
      final before = edit;
      for (var i = 1; i <= 5; i++) {
        edit = edit.moveLive(moveElement(edit.elements.single, 0.02, 0));
      }
      edit = edit.commitFrom(before);
      expect((edit.elements.single as MarkerElement).at.x, closeTo(0.6, 1e-9));
      edit = edit.undo();
      expect((edit.elements.single as MarkerElement).at.x, 0.5);
      edit = edit.redo();
      expect((edit.elements.single as MarkerElement).at.x, closeTo(0.6, 1e-9));
      // Two undos back to the empty board.
      expect(edit.undo().undo().elements, isEmpty);
    });

    test('a new step starts where everyone stands, without the arrows', () {
      final edit = const BoardEdit(steps: [PlayStep()])
          .add(_marker)
          .add(
            const BoardElement.arrow(
              id: 'a1',
              kind: ArrowKind.run,
              points: [(x: 0.5, y: 0.5), (x: 0.6, y: 0.4)],
            ),
          )
          .addStep();
      expect(edit.steps, hasLength(2));
      expect(edit.step, 1);
      expect(edit.elements, [_marker]);
      // Removing it goes back to the first, which keeps its arrow.
      final back = edit.removeStep();
      expect(back.steps, hasLength(1));
      expect(back.elements, hasLength(2));
    });

    test('a step holds so much, and a play so many steps', () {
      var edit = const BoardEdit(steps: [PlayStep()]);
      for (var i = 0; i < Limits.playElementsMax + 5; i++) {
        edit = edit.add(_marker.copyWith(id: '$i'));
      }
      expect(edit.elements, hasLength(Limits.playElementsMax));
      for (var i = 0; i < Limits.playStepsMax + 3; i++) {
        edit = edit.addStep();
      }
      expect(edit.steps, hasLength(Limits.playStepsMax));
    });

    test('a touch picks the nearest marker first, then lines', () {
      const arrow = BoardElement.arrow(
        id: 'a1',
        kind: ArrowKind.pass,
        points: [(x: 0.1, y: 0.1), (x: 0.9, y: 0.1)],
      );
      final elements = [arrow, _marker];
      expect(
        hitTest(elements, (x: 0.51, y: 0.51), 1, tolerance: 0.03)?.id,
        'm1',
      );
      expect(
        hitTest(elements, (x: 0.4, y: 0.11), 1, tolerance: 0.03)?.id,
        'a1',
      );
      expect(hitTest(elements, (x: 0.3, y: 0.8), 1, tolerance: 0.03), isNull);
    });

    test('a shaky hand draws a clean route', () {
      final wobbly = [
        for (var i = 0; i <= 100; i++)
          (x: i / 100, y: 0.5 + (i.isEven ? 0.001 : -0.001)),
      ];
      final clean = simplifyPath(wobbly, 1);
      expect(clean, hasLength(2));
      expect(clean.first, wobbly.first);
      expect(clean.last, wobbly.last);
      final zigzag = [
        for (var i = 0; i <= 200; i++) (x: i / 200, y: i.isEven ? 0.2 : 0.8),
      ];
      expect(
        simplifyPath(zigzag, 1).length,
        lessThanOrEqualTo(Limits.playPointsMax),
      );
    });

    test('playback glides markers halfway, then shows the next step', () {
      const moved = BoardElement.marker(
        id: 'm1',
        at: (x: 0.7, y: 0.3),
        side: MarkerSide.team,
        label: 'P',
      );
      const arrow = BoardElement.arrow(
        id: 'a1',
        kind: ArrowKind.run,
        points: [(x: 0.5, y: 0.5), (x: 0.7, y: 0.3)],
      );
      final mid = elementsBetween([_marker, arrow], [moved], 0.5);
      expect((mid.first as MarkerElement).at.x, closeTo(0.6, 1e-9));
      expect((mid.first as MarkerElement).at.y, closeTo(0.4, 1e-9));
      // The route stays on show while they run it.
      expect(mid.last, arrow);
      expect(elementsBetween([_marker, arrow], [moved], 1), [moved]);
    });

    test("a roster player's marker shows their number, or first name", () {
      expect(markerLabelFor('Emma Ortiz', '7'), '7');
      expect(markerLabelFor('Liam Brooks', null), 'Liam');
      expect(markerLabelFor('Maximilianopolis Smith', ''), 'Maximilianop');
    });
  });

  group('saving (BOARD-4, data)', () {
    test('a play goes to Firestore and back as drawn', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestorePlayRepository(db);
      final id = await repo.create(const GroupId('a'), const UserId('coach'), (
        board: PlayBoard.football,
        variant: BoardVariant.full,
        title: ' Slant ',
        note: 'On two',
        steps: const [
          PlayStep(
            elements: [
              _marker,
              BoardElement.arrow(
                id: 'a1',
                kind: ArrowKind.block,
                points: [(x: 0.123456, y: 0.5), (x: 0.2, y: 0.4)],
              ),
              BoardElement.line(id: 'l1', points: [(x: 0, y: 0), (x: 1, y: 1)]),
              BoardElement.note(id: 'n1', at: (x: 0.3, y: 0.3), text: 'Go'),
            ],
          ),
          PlayStep(),
        ],
      ));
      final raw = (await db.collection('plays').doc(id.value).get()).data()!;
      expect(raw['title'], 'Slant');
      expect(raw['createdBy'], 'coach');
      // Compact: points as one list of x, y pairs, rounded.
      final steps = (raw['steps'] as List).cast<Map<String, dynamic>>();
      final elements = (steps.first['elements'] as List)
          .cast<Map<String, dynamic>>();
      expect(elements[1]['pts'], [0.1235, 0.5, 0.2, 0.4]);
      final play = (await repo.watchPlay(id).first)!;
      expect(play.title, 'Slant');
      expect(play.board, PlayBoard.football);
      expect(play.steps, hasLength(2));
      expect(play.steps.first.elements[0], _marker);
      expect(play.steps.first.elements[3], isA<NoteElement>());
      expect(await repo.watchPlays(const GroupId('a')).first, hasLength(1));
      await repo.delete(id);
      expect(await repo.watchPlay(id).first, isNull);
    });
  });

  test("each team's whiteboard stays on the device across restarts", () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    Future<PrefsWhiteboardStore> open() async => PrefsWhiteboardStore(
      await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: {PrefsWhiteboardStore.key},
        ),
      ),
    );
    final store = await open();
    expect(store.load(const GroupId('a')), isNull);
    await store.save(const GroupId('a'), (
      board: PlayBoard.soccer,
      variant: BoardVariant.half,
      title: '',
      note: '',
      steps: const [
        PlayStep(elements: [_marker]),
      ],
    ));
    final again = (await open()).load(const GroupId('a'))!;
    expect(again.board, PlayBoard.soccer);
    expect(again.variant, BoardVariant.half);
    expect(again.steps.single.elements, [_marker]);
    expect((await open()).load(const GroupId('b')), isNull);
  });

  group('the Plays screens (BOARD-4)', () {
    const coach = AuthUser(
      uid: 'coach',
      email: 'coach@example.com',
      emailVerified: true,
    );
    // Thunder plays softball: its plays start on the diamond.
    final team = {
      'a': testGroup('a', 'Thunder').copyWith(sport: Sport.softball),
    };
    final saved = Play(
      id: const PlayId('p9'),
      groupId: const GroupId('a'),
      board: PlayBoard.baseball,
      variant: BoardVariant.full,
      title: 'Bunt defense',
      note: 'Corners crash.',
      steps: const [
        PlayStep(elements: [_marker]),
        PlayStep(),
      ],
      updatedAt: DateTime(2026, 10, 15),
    );

    Future<void> open(
      WidgetTester tester, {
      required MemberRole role,
      required FakePlayRepository plays,
      String path = '/g/a/plays',
    }) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('a', 'coach', role: role)],
        playRepo: plays,
        size: const Size(1024, 1366),
      );
      unawaited(
        GoRouter.of(tester.element(find.byType(Scaffold).first)).push(path),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('everyone finds Plays in the team menu', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('a', 'coach')],
      );
      await tester.tap(find.byTooltip('Team menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plays'));
      await tester.pumpAndSettle();
      expect(
        find.text("No plays yet. Your coaches' plays will show up here."),
        findsOneWidget,
      );
      // Members view; only admins start one.
      expect(find.text('New play'), findsNothing);
    });

    testWidgets('a member views a play step by step, without edit tools', (
      tester,
    ) async {
      final plays = FakePlayRepository([saved]);
      await open(tester, role: MemberRole.member, plays: plays);
      expect(find.text('Bunt defense'), findsOneWidget);
      await tester.tap(find.text('Bunt defense'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.text('Corners crash.'), findsOneWidget);
      expect(find.byTooltip('Edit'), findsNothing);
      await tester.tap(find.byTooltip('Next step'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 2'), findsOneWidget);
    });

    testWidgets("a coach's Plays is the whiteboard: the team's sport's "
        'board, ready to drag and draw, saved only when asked', (tester) async {
      final plays = FakePlayRepository();
      await open(tester, role: MemberRole.admin, plays: plays);
      expect(find.text('Whiteboard'), findsOneWidget);
      // Add a runner: the opponent tool, then a tap on the board.
      await tester.tap(find.byTooltip('Add an opponent'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('playBoard')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Redo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save to plays'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Pickoff at first');
      await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
      await tester.pumpAndSettle();
      expect(plays.calls, ['create Pickoff at first']);
      // Softball's diamond: the nine in the field, the ball, the runner.
      final play = plays.plays.single;
      expect(play.board, PlayBoard.baseball);
      final markers = play.steps.single.elements.whereType<MarkerElement>();
      expect(markers.where((m) => m.side == MarkerSide.team), hasLength(9));
      expect(markers.where((m) => m.side == MarkerSide.ball), hasLength(1));
      expect(markers.where((m) => m.side == MarkerSide.opponent), hasLength(1));
      // The whiteboard keeps its drawing, and the saved copy is listed.
      expect(find.text('Whiteboard'), findsOneWidget);
      await tester.tap(find.byTooltip('Saved plays'));
      await tester.pumpAndSettle();
      expect(find.text('Pickoff at first'), findsOneWidget);
    });

    testWidgets('the whiteboard keeps its drawing until it is cleared', (
      tester,
    ) async {
      await open(tester, role: MemberRole.owner, plays: FakePlayRepository());
      await tester.tap(find.byTooltip('Add an opponent'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('playBoard')));
      await tester.pumpAndSettle();
      // Away and back: still there, with no "unsaved" question on leaving.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Leave without saving?'), findsNothing);
      unawaited(
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .push('/g/a/plays'),
      );
      await tester.pumpAndSettle();
      final board = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('playBoard')),
          matching: find.byType(CustomPaint),
        ),
      );
      final shown = (board.painter! as PlayPainter).elements;
      expect(
        shown.whereType<MarkerElement>().where(
          (m) => m.side == MarkerSide.opponent,
        ),
        hasLength(1),
      );
      // A new board asks before erasing it.
      await tester.tap(find.byTooltip('New board'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start drawing'));
      await tester.pumpAndSettle();
      expect(find.text('Start a new board?'), findsOneWidget);
    });

    testWidgets('playing the steps glides everyone to the last one', (
      tester,
    ) async {
      final plays = FakePlayRepository([saved]);
      await open(
        tester,
        role: MemberRole.member,
        plays: plays,
        path: '/g/a/plays/p9',
      );
      expect(find.text('Step 1 of 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Play the steps'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byTooltip('Stop'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 2'), findsOneWidget);
    });

    testWidgets('leaving with changes asks first', (tester) async {
      final plays = FakePlayRepository([saved]);
      await open(
        tester,
        role: MemberRole.owner,
        plays: plays,
        path: '/g/a/plays/p9/edit',
      );
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear this step'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Leave without saving?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(plays.calls, isEmpty);
    });
  });
}
