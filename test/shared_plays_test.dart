// Shared plays (SPEC BOARD-6): a play's public link, which shows only the
// play, signed in or not.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/plays/data/firestore_play_repository.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/domain/shared_play.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

const _shareId = 'Ab3_x-9Kq2Zw';

const _marker = BoardElement.marker(
  id: 'm1',
  at: (x: 0.5, y: 0.5),
  side: MarkerSide.team,
  label: 'SS',
);

const PlayDraft _shared = (
  board: PlayBoard.basketball,
  variant: BoardVariant.half,
  title: 'Box out',
  note: 'Hit first, then go get it.',
  steps: [
    PlayStep(elements: [_marker]),
    PlayStep(),
  ],
);

void main() {
  group('links (BOARD-6)', () {
    test("the link's picture is drawn without roster players' names", () {
      const play = Play(
        id: PlayId('p1'),
        groupId: GroupId('a'),
        board: PlayBoard.baseball,
        variant: BoardVariant.full,
        title: 'Bunt defense',
        steps: [
          PlayStep(
            elements: [
              _marker,
              BoardElement.marker(
                id: 'm2',
                at: (x: 0.2, y: 0.2),
                side: MarkerSide.team,
                label: 'Emma',
                playerId: PlayerId('emma'),
              ),
              BoardElement.note(id: 'n1', at: (x: 0.3, y: 0.3), text: 'Go'),
            ],
          ),
        ],
      );
      expect(publicPlay(play).steps.single.elements, [
        _marker,
        const BoardElement.marker(
          id: 'm2',
          at: (x: 0.2, y: 0.2),
          side: MarkerSide.team,
        ),
        const BoardElement.note(id: 'n1', at: (x: 0.3, y: 0.3), text: 'Go'),
      ]);
    });

    test('anyone reads a shared play in the play format; a missing or '
        'malformed ID is no play', () async {
      final db = FakeFirebaseFirestore();
      await db.collection(Collections.sharedPlays).doc(_shareId).set({
        'board': 'basketball',
        'variant': 'half',
        'title': 'Box out',
        'note': 'Hit first.',
        'steps': [
          {
            'elements': [
              {'k': 'm', 'id': 'm1', 'x': 0.5, 'y': 0.5, 's': 'team'},
              {
                'k': 'a',
                'id': 'a1',
                't': 'pass',
                'pts': [0.5, 0.5, 0.2, 0.2],
              },
              // A kind this version doesn't know is left out.
              {'k': 'zone', 'id': 'z1'},
            ],
          },
        ],
        'hasImage': true,
      });
      final repo = FirestorePlayRepository(db);
      final play = (await repo.sharedPlay(_shareId))!;
      expect(play.board, PlayBoard.basketball);
      expect(play.variant, BoardVariant.half);
      expect(play.title, 'Box out');
      expect(play.steps.single.elements, [
        const BoardElement.marker(
          id: 'm1',
          at: (x: 0.5, y: 0.5),
          side: MarkerSide.team,
        ),
        const BoardElement.arrow(
          id: 'a1',
          kind: ArrowKind.pass,
          points: [(x: 0.5, y: 0.5), (x: 0.2, y: 0.2)],
        ),
      ]);
      expect(await repo.sharedPlay('Zz3_x-9Kq2Zw'), isNull);
      expect(await repo.sharedPlay('../plays/p1'), isNull);
    });

    test("a play's link ID comes with it", () {
      final play = playFromFirestore('p1', {
        'groupId': 'a',
        'board': 'soccer',
        'variant': 'full',
        'title': 'Corner',
        'steps': <Object?>[],
        'shareId': _shareId,
      });
      expect(play.shareId, _shareId);
    });
  });

  group('sharing and importing (BOARD-6)', () {
    const coach = AuthUser(
      uid: 'coach',
      email: 'coach@example.com',
      emailVerified: true,
    );
    final teams = {
      'a': testGroup('a', 'Thunder'),
      'b': testGroup('b', 'Cyclone'),
    };
    final saved = Play(
      id: const PlayId('p9'),
      groupId: const GroupId('a'),
      board: PlayBoard.baseball,
      variant: BoardVariant.full,
      title: 'Bunt defense',
      steps: const [
        PlayStep(elements: [_marker]),
      ],
      updatedAt: DateTime(2026, 10, 15),
    );

    Future<void> go(
      WidgetTester tester,
      String path, {
      bool push = false,
    }) async {
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      if (push) {
        unawaited(router.push(path));
      } else {
        router.go(path);
      }
      await tester.pumpAndSettle();
    }

    testWidgets("a team's admin shares a play's link, with a picture of it, "
        'and can stop sharing it', (tester) async {
      final plays = FakePlayRepository([saved]);
      final sharer = FakeSharer();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: [testMembership('a', 'coach', role: MemberRole.admin)],
        playRepo: plays,
        sharer: sharer,
        size: const Size(1024, 1366),
      );
      await go(tester, '/g/a/plays/p9', push: true);
      expect(find.text('Stop sharing'), findsNothing);

      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(OutlinedButton, 'Share link'));
        for (var i = 0; i < 20 && sharer.shared.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();
      final shareId = plays.plays.single.shareId!;
      expect(sharer.shared, ['link https://getbattleplan.app/p/$shareId']);
      // A PNG of the play, for the link's preview.
      expect(plays.shareImages.single!.sublist(1, 4), 'PNG'.codeUnits);
      expect(plays.shared[shareId]!.title, 'Bunt defense');

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop sharing'));
      await tester.pumpAndSettle();
      expect(find.text('Stop sharing Bunt defense?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Stop sharing'));
      await tester.pumpAndSettle();
      expect(plays.calls, contains('stop sharing p9'));
      expect(plays.shared, isEmpty);
      expect(find.text("The play's link is off."), findsOneWidget);
    });

    testWidgets("where links can't be shared, the link shows, to copy", (
      tester,
    ) async {
      final plays = FakePlayRepository([saved]);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: [testMembership('a', 'coach', role: MemberRole.admin)],
        playRepo: plays,
        sharer: FakeSharer()..linksShare = false,
        size: const Size(1024, 1366),
      );
      await go(tester, '/g/a/plays/p9', push: true);
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(OutlinedButton, 'Share link'));
        for (
          var i = 0;
          i < 20 && find.byType(AlertDialog).evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();
      final link = 'https://getbattleplan.app/p/${plays.plays.single.shareId}';
      expect(find.text(link), findsOneWidget);
      expect(
        find.text(
          'Anyone with this link sees the play, but not your team or its '
          'players.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();
      expect(
        copied,
        'https://getbattleplan.app/p/${plays.plays.single.shareId}',
      );
      expect(find.text('Link copied.'), findsOneWidget);
    });

    testWidgets("a member doesn't share the team's plays", (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: teams,
        memberships: [testMembership('a', 'coach')],
        playRepo: FakePlayRepository([saved]),
        size: const Size(1024, 1366),
      );
      await go(tester, '/g/a/plays/p9', push: true);
      expect(find.text('Save as GIF'), findsOneWidget);
      expect(find.text('Share link'), findsNothing);
    });

    testWidgets('signed out, the link shows only the play, step by step', (
      tester,
    ) async {
      final plays = FakePlayRepository()..shared[_shareId] = _shared;
      await pumpApp(tester, auth: FakeAuthRepository(), playRepo: plays);
      await go(tester, '/p/$_shareId');
      expect(find.widgetWithText(AppBar, 'Box out'), findsOneWidget);
      expect(find.text('Hit first, then go get it.'), findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Next step'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 2'), findsOneWidget);
    });

    testWidgets("a link that's no longer shared says so; one that can't "
        'load says to try again', (tester) async {
      final plays = FakePlayRepository();
      await pumpApp(tester, auth: FakeAuthRepository(), playRepo: plays);
      await go(tester, '/p/$_shareId');
      expect(find.text("This play isn't shared anymore."), findsOneWidget);
      plays.sharedFailure = const Offline('offline');
      await go(tester, '/p/Zz3_x-9Kq2Zw');
      expect(
        find.text(
          "Couldn't open the play. Check your connection and try again.",
        ),
        findsOneWidget,
      );
    });
  });
}
