// Plays (SPEC §6.16, BOARD-1 to BOARD-5): the boards and their starting
// spots, drawing and undoing, steps, saving through the repository, who
// may do what, and posting a play to the chat or saving it as a GIF.
import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/plays_icon.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/presentation/composer.dart';
import 'package:battleplan/features/plays/data/firestore_play_repository.dart';
import 'package:battleplan/features/plays/data/prefs_whiteboard_store.dart';
import 'package:battleplan/features/plays/domain/board_edit.dart';
import 'package:battleplan/features/plays/domain/board_layout.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/domain/play_gif.dart';
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
    test('every formation stands on its board, in the part it shows', () {
      for (final board in PlayBoard.values) {
        final frame = boardFrame(board);
        for (final v in boardVariants(board)) {
          for (final f in [
            ...teamFormations(board, v),
            ...opponentFormations(board, v),
          ]) {
            for (final s in f.spots) {
              expect(
                s.at.x,
                inInclusiveRange(frame.left, frame.left + frame.width),
                reason: '${f.id} ${s.label}',
              );
              expect(
                s.at.y,
                inInclusiveRange(frame.top, frame.top + frame.height),
                reason: '${f.id} ${s.label}',
              );
            }
          }
        }
      }
    });

    test("baseball's board is cut to the fence, so the field fills it", () {
      const frame = BaseballField.frame;
      // The center-field fence runs to the top edge, a few feet short of
      // it; the foul poles' corners run off the sides.
      expect(
        (BaseballField.center.y - frame.top) * BaseballField.widthFeet,
        inInclusiveRange(1, 6),
      );
      expect(BaseballField.leftPole.x, lessThan(frame.left));
      expect(BaseballField.rightPole.x, greaterThan(frame.left + frame.width));
      // Behind home there's room for the pitcher backing up the plate.
      expect(
        (frame.top + frame.height - BaseballField.home.y) *
            BaseballField.widthFeet,
        greaterThanOrEqualTo(45),
      );
      // A little taller than wide, for a phone held upright; the other
      // boards show all of their fields.
      expect(
        boardAspect(PlayBoard.baseball, BoardVariant.full),
        inInclusiveRange(0.9, 1),
      );
      expect(
        boardAspect(PlayBoard.soccer, BoardVariant.full),
        fieldAspect(PlayBoard.soccer, BoardVariant.full),
      );
      // A point kept on the board stays in what it shows.
      expect(onBoard((x: 0, y: 1), frame), (
        x: frame.left,
        y: frame.top + frame.height,
      ));
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

  group("a play's GIF (BOARD-5)", () {
    test('the first step shows 1.5 seconds, each next one glides in over '
        '1.5 seconds, and the last holds 3 seconds', () {
      final frames = playGifFrames(3);
      expect(frames.first, (step: 0, t: 0.0, delay: 150));
      // 20 frames a second while gliding, arriving on the step itself.
      expect(frames[1], (step: 0, t: 1 / 30, delay: 5));
      expect(frames[29], (step: 0, t: 29 / 30, delay: 5));
      expect(frames[30], (step: 1, t: 0.0, delay: 5));
      expect(frames[31], (step: 1, t: 1 / 30, delay: 5));
      expect(frames.last, (step: 2, t: 0.0, delay: 300));
      expect(frames, hasLength(61));
      // Each step's 1.5 seconds, then the 3-second hold (which takes the
      // last frame's own twentieth of a second).
      expect(frames.fold(0, (sum, f) => sum + f.delay), 450 + 300 - 5);
      // One step: a still picture.
      expect(playGifFrames(1), [(step: 0, t: 0.0, delay: 300)]);
    });

    test("it's saved under the play's name", () {
      expect(playGifName('Bunt defense'), 'Bunt defense');
      expect(playGifName(' 4-3 / "Zone"?  press '), '4-3 Zone press');
      expect(playGifName(r'a\b:c*d<e>f|g'), 'a b c d e f g');
      expect(playGifName(' ?? '), 'Play');
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
      Size size = const Size(1024, 1366),
    }) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('a', 'coach', role: role)],
        playRepo: plays,
        size: size,
      );
      unawaited(
        GoRouter.of(tester.element(find.byType(Scaffold).first)).push(path),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('everyone finds the Whiteboard after Documents in navigation', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('a', 'coach')],
      );
      final navigation = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(
        navigation.destinations.cast<NavigationDestination>().map(
          (d) => d.label,
        ),
        ['Chat', 'Schedule', 'Documents', 'Plays'],
      );
      // The drawn chalkboard, outlined, also while its tab is showing: the
      // gumdrop indicator marks the tab (Gumdrop Pop design §3.2).
      expect(tester.widget<PlaysIcon>(find.byType(PlaysIcon)).filled, isFalse);
      await tester.tap(find.text('Plays'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlaysIcon>(
              find.descendant(
                of: find.byType(NavigationBar),
                matching: find.byType(PlaysIcon),
              ),
            )
            .filled,
        isFalse,
      );
      expect(
        find.text("No plays yet. Your coaches' plays will show up here."),
        findsOneWidget,
      );
      // The empty screen's art is the play in color: a lemon O and a
      // cherry X on their lips (the Play Call app icon); the tab's is one
      // color, like the icons beside it.
      final art = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is PlaysIcon && w.colorful),
          matching: find.byType(CustomPaint),
        ),
      );
      final candies = (art.painter! as PlaysIconPainter).candies!;
      final colors = GumdropColors.of(tester.element(find.byWidget(art)));
      expect(candies.o, colors.lemon);
      expect(candies.x, colors.cherry);
      final tab = tester.widget<CustomPaint>(
        find.descendant(
          of: find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byType(PlaysIcon),
          ),
          matching: find.byType(CustomPaint),
        ),
      );
      expect((tab.painter! as PlaysIconPainter).candies, isNull);
      // Members view; only admins start one.
      expect(find.text('New play'), findsNothing);
    });

    testWidgets('anyone on the team posts a saved play to the chat: a '
        'picture of its last step, which opens the play (BOARD-5)', (
      tester,
    ) async {
      final messages = FakeMessageRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('a', 'coach')],
        playRepo: FakePlayRepository([saved]),
        messageRepo: messages,
        // The team's chat hasn't been opened yet.
        prefs: FakeLocalPrefs()..lastTeamRoute = '/g/a/documents',
        size: const Size(1024, 1366),
      );
      expect(find.byType(Composer), findsNothing);
      unawaited(
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .push('/g/a/plays/${saved.id.value}'),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Post to chat'));
        for (var i = 0; i < 20 && messages.photoBatches.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();
      // One picture, with the play's name, naming the play.
      expect(messages.photoBatches, [1]);
      final posted = messages.messages.first;
      expect(posted.text, 'Bunt defense');
      expect(posted.playId, 'p9');
      expect(find.byType(Composer), findsOneWidget);
      // In the chat it says it opens the play, and a tap does.
      expect(find.text('Open play'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      await tester.pump();
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp('Open the play Bunt defense')),
        ),
        isSemantics(isButton: true, hasTapAction: true),
      );
      semantics.dispose();
      await tester.tap(find.text('Open play'));
      // Past the wait for a double tap (CHAT-6).
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Bunt defense'), findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.byTooltip('Play the steps'), findsOneWidget);
    });

    // A runner who crosses the board between its two steps.
    final crossing = saved.copyWith(
      steps: const [
        PlayStep(
          elements: [
            BoardElement.marker(
              id: 'm1',
              at: (x: 0.2, y: 0.8),
              side: MarkerSide.team,
              label: 'P',
            ),
          ],
        ),
        PlayStep(
          elements: [
            BoardElement.marker(
              id: 'm1',
              at: (x: 0.8, y: 0.2),
              side: MarkerSide.team,
              label: 'P',
            ),
          ],
        ),
      ],
    );

    /// Taps Save as GIF on the crossing play, and waits until [done].
    Future<void> saveGif(WidgetTester tester, bool Function() done) async {
      unawaited(
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .push('/g/a/plays/${crossing.id.value}'),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(OutlinedButton, 'Save as GIF'));
        await tester.pump();
        expect(find.text('Making the GIF…'), findsOneWidget);
        for (var i = 0; i < 300 && !done(); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();
    }

    testWidgets('anyone saves a saved play to their phone as a GIF that '
        'plays it (BOARD-5)', (tester) async {
      final saver = FakePhotoSaver();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('a', 'coach')],
        playRepo: FakePlayRepository([crossing]),
        size: const Size(1024, 1366),
        overrides: [photoSaverProvider.overrideWithValue(saver)],
      );
      await saveGif(tester, () => saver.saved.isNotEmpty);
      expect(saver.saved, ['Bunt defense']);
      final gif = saver.bytes.single;
      expect(String.fromCharCodes(gif.sublist(0, 6)), 'GIF89a');
      // The first step for 1.5 seconds, 29 frames as the runner crosses
      // and the second step, held 3 seconds.
      final delays = _gifDelays(gif);
      expect(delays, hasLength(31));
      expect(delays.first, 150);
      expect(delays.sublist(1, 30), everyElement(5));
      expect(delays.last, 300);
      expect(find.text('GIF saved to your photos.'), findsOneWidget);
      expect(find.text('Save as GIF'), findsOneWidget);
    });

    testWidgets('in a browser, the GIF is shared or downloaded (BOARD-5)', (
      tester,
    ) async {
      final sharer = FakeSharer();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('a', 'coach')],
        playRepo: FakePlayRepository([crossing]),
        sharer: sharer,
        size: const Size(1024, 1366),
      );
      await saveGif(tester, () => sharer.shared.isNotEmpty);
      expect(sharer.shared, ['file Bunt defense.gif image/gif']);
      expect(String.fromCharCodes(sharer.files.single.sublist(0, 6)), 'GIF89a');
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
      expect(find.widgetWithText(AppBar, 'Plays'), findsOneWidget);
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
      expect(find.widgetWithText(AppBar, 'Plays'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Saved plays'));
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

    testWidgets('a saved play goes up on the whiteboard underneath', (
      tester,
    ) async {
      final plays = FakePlayRepository([saved]);
      await open(tester, role: MemberRole.admin, plays: plays);
      expect(find.text('Step 1 of 1'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Saved plays'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bunt defense'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Put on the whiteboard'));
      await tester.pumpAndSettle();
      // Back on the whiteboard, now with the play's two steps, and still
      // with the way back to the team.
      expect(find.widgetWithText(AppBar, 'Plays'), findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets("a phone's whiteboard runs the screen's width under one "
        'bar, with the rest in More', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(
        tester,
        role: MemberRole.admin,
        plays: FakePlayRepository([saved]),
        size: const Size(390, 844),
      );
      // The board, edge to edge; the bar over it, and the tools under it.
      final board = tester.getRect(find.byKey(const ValueKey('playBoard')));
      expect(board.width, 390);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byTooltip('Undo'), findsOneWidget);
      expect(find.byTooltip('Redo'), findsOneWidget);
      // The saved plays by name, so they're found; Add step makes room as
      // a plus.
      expect(find.byTooltip('Add step'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Saved'), findsOneWidget);
      expect(find.byTooltip('Save to plays'), findsNothing);
      // A tap in the board's corner lands at the corner of the field it
      // shows: baseball's is cut to the fence.
      await tester.tap(find.byTooltip('Add an opponent'));
      await tester.pumpAndSettle();
      await tester.tapAt(board.topLeft + const Offset(1, 1));
      await tester.pumpAndSettle();
      final painted = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('playBoard')),
          matching: find.byType(CustomPaint),
        ),
      );
      final added = (painted.painter! as PlayPainter).elements
          .whereType<MarkerElement>()
          .firstWhere((m) => m.side == MarkerSide.opponent);
      expect(added.at.x, closeTo(BaseballField.frame.left, 0.01));
      expect(added.at.y, closeTo(BaseballField.frame.top, 0.01));
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      expect(find.text('Save to plays'), findsOneWidget);
      expect(find.text('New board'), findsOneWidget);
      await tester.tapAt(const Offset(200, 600));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Saved'));
      await tester.pumpAndSettle();
      // A play's steps fit a phone too: where they are, and adding one, in
      // the bar; playing them, if there's no room, in More.
      await tester.tap(find.text('Bunt defense'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Put on the whiteboard'));
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);
      expect(find.bySemanticsLabel('Step 1 of 2'), findsOneWidget);
      expect(find.byTooltip('Add step'), findsOneWidget);
      if (find.byTooltip('Play the steps').evaluate().isEmpty) {
        await tester.tap(find.byTooltip('More'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Play the steps').hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('on a phone, a drag moves a player; a tap picks one, and the '
        'bar shows what to do with it', (tester) async {
      await open(
        tester,
        role: MemberRole.admin,
        plays: FakePlayRepository(),
        size: const Size(390, 844),
      );
      final board = tester.getRect(find.byKey(const ValueKey('playBoard')));
      List<MarkerElement> markers() =>
          (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byKey(const ValueKey('playBoard')),
                          matching: find.byType(CustomPaint),
                        ),
                      )
                      .painter!
                  as PlayPainter)
              .elements
              .whereType<MarkerElement>()
              .toList();
      // Where the center fielder stands on screen.
      final center = markers().firstWhere((m) => m.label == 'CF').at;
      const frame = BaseballField.frame;
      final onScreen = Offset(
        board.left + (center.x - frame.left) / frame.width * board.width,
        board.top + (center.y - frame.top) / frame.height * board.height,
      );
      await tester.dragFrom(onScreen, const Offset(0, 40));
      await tester.pumpAndSettle();
      final moved = markers().firstWhere((m) => m.label == 'CF');
      expect(moved.at.y, greaterThan(center.y));
      // Still the step's controls, not the center fielder's.
      expect(find.byTooltip('Add step'), findsOneWidget);
      expect(find.byTooltip('Label'), findsNothing);
      await tester.tapAt(onScreen + const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Label'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(markers().where((m) => m.label == 'CF'), isEmpty);
      expect(find.byTooltip('Add step'), findsOneWidget);
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

/// How long each of [gif]'s frames shows, in hundredths of a second, from
/// the graphic control block before each image.
List<int> _gifDelays(Uint8List gif) {
  // The header, the screen, and the global table of 256 colors.
  var at = 13 + 256 * 3;
  final delays = <int>[];
  void skipBlocks() {
    while (gif[at] != 0) {
      at += gif[at] + 1;
    }
    at++;
  }

  while (gif[at] != 0x3B) {
    if (gif[at] == 0x21) {
      if (gif[at + 1] == 0xF9) delays.add(gif[at + 4] | gif[at + 5] << 8);
      at += 2;
      skipBlocks();
    } else {
      // An image: its descriptor, the code size, then its data.
      at += 11;
      skipBlocks();
    }
  }
  return delays;
}
