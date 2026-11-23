// Roster requests that coaches notice (owner's go 2026-11-16, "do #20, then
// #23"; SPEC PLAYER-4, §5.3, §5.1): the Team tab's count and the Teams
// card's line for admins, each request as one plain sentence, the sheet to
// review it and fix a new player's name and number, and what a decision
// did. The one-decision and failure tests are in app_flow_test.dart.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/presentation/roster_requests.dart';
import 'package:battleplan/features/groups/presentation/shell_parts.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/contrast.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const pat = AuthUser(
    uid: 'pat',
    email: 'pat@example.com',
    emailVerified: true,
  );

  final team = testGroup('y', 'Lightning U10');

  const emma = Player(
    id: PlayerId('emma'),
    groupId: GroupId('y'),
    displayName: 'Emma Rodriguez',
    jerseyNumber: '7',
  );

  /// Pat Lee's new player Noah Park, waiting, with no number.
  Player noah({String? number}) => Player(
    id: const PlayerId('noah'),
    groupId: const GroupId('y'),
    displayName: 'Noah Park',
    jerseyNumber: number,
    status: PlayerStatus.pending,
    proposedBy: 'pat',
    proposedRelation: PlayerRelation.guardian,
    addedAt: DateTime.utc(2026, 11, 15),
  );

  /// Pat Lee's claim to be Emma's parent or guardian.
  final patClaim = GuardianRequest(
    playerId: const PlayerId('emma'),
    groupId: const GroupId('y'),
    uid: const UserId('pat'),
    status: GuardianRequestStatus.pending,
    createdAt: DateTime.utc(2026, 11, 16),
  );

  final people = [
    testMembership('y', 'coach', role: MemberRole.owner, name: 'Coach Kim'),
    testMembership('y', 'pat', name: 'Pat Lee'),
    testMembership('y', 'claire', name: 'Claire Dunphy'),
  ];

  /// The app as [user], with [players] (Emma, and Noah waiting) and
  /// [requests] (Pat's claim).
  Future<FakePlayerRepository> open(
    WidgetTester tester, {
    AuthUser user = coach,
    List<Player>? players,
    List<GuardianRequest>? requests,
    List<GuardianLink> links = const [],
    List<Membership>? memberships,
    Size size = const Size(400, 1600),
  }) async {
    final repo =
        FakePlayerRepository([
            ...(players ?? [emma, noah()]),
          ])
          ..requests.addAll(requests ?? [patClaim])
          ..links.addAll(links);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: user),
      groups: {'y': team},
      memberships: memberships ?? people,
      playerRepo: repo,
      size: size,
    );
    return repo;
  }

  String location(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Navigator).first)).state.uri
          .toString();

  const claimSentence = "Pat Lee says they're a guardian of Emma #7.";
  const noahSentence =
      "Pat Lee wants to add Noah Park to the roster, as Noah's guardian.";

  group('a count where coaches look', () {
    testWidgets('the Team tab counts new players and claims for admins', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      final tabs = find.byWidgetPredicate((w) => w is OpenFieldTabBar);
      expect(
        find.descendant(of: tabs, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Team, 2 waiting for approval')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('not for a member, or a super admin viewing the team', (
      tester,
    ) async {
      await open(tester, user: pat);
      final tabs = find.byWidgetPredicate((w) => w is OpenFieldTabBar);
      expect(find.descendant(of: tabs, matching: find.text('2')), findsNothing);
      expect(find.descendant(of: tabs, matching: find.text('1')), findsNothing);

      await open(
        tester,
        user: const AuthUser(
          uid: 'boss',
          email: 'boss@example.com',
          emailVerified: true,
          isSuperAdmin: true,
        ),
      );
      GoRouter.of(tester.element(find.byType(Navigator).first)).go('/g/y/chat');
      await tester.pumpAndSettle();
      expect(find.textContaining('Viewing as super admin'), findsWidgets);
      expect(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is OpenFieldTabBar),
          matching: find.text('2'),
        ),
        findsNothing,
      );
    });

    testWidgets('the Teams card says how many wait, and opens the Team tab', (
      tester,
    ) async {
      await open(tester);
      GoRouter.of(tester.element(find.byType(Navigator).first)).go('/teams');
      await tester.pumpAndSettle();
      final waiting = find.widgetWithText(TextButton, '2 requests waiting');
      expect(waiting, findsOneWidget);
      expect(tester.getSize(waiting).height, greaterThanOrEqualTo(48));
      await tester.tap(waiting);
      await tester.pumpAndSettle();
      expect(location(tester), '/g/y/team');
      expect(find.text('Waiting for approval'), findsOneWidget);

      // One waiting: singular. A member's card has none.
      await open(tester, requests: const []);
      GoRouter.of(tester.element(find.byType(Navigator).first)).go('/teams');
      await tester.pumpAndSettle();
      expect(find.text('1 request waiting'), findsOneWidget);

      await open(tester, user: pat);
      GoRouter.of(tester.element(find.byType(Navigator).first)).go('/teams');
      await tester.pumpAndSettle();
      expect(find.textContaining('waiting'), findsNothing);
    });
  });

  group('one plain sentence per request', () {
    testWidgets('each kind reads as a parent would say it, oldest first, '
        'with Decline and Approve under it', (tester) async {
      await open(
        tester,
        players: [
          emma,
          noah(number: '4'),
          Player(
            id: const PlayerId('claire'),
            groupId: const GroupId('y'),
            displayName: 'Claire Dunphy',
            jerseyNumber: '12',
            status: PlayerStatus.pending,
            proposedBy: 'claire',
            proposedRelation: PlayerRelation.self,
            addedAt: DateTime.utc(2026, 11, 17),
          ),
        ],
        requests: [
          patClaim,
          GuardianRequest(
            playerId: const PlayerId('emma'),
            groupId: const GroupId('y'),
            uid: const UserId('claire'),
            status: GuardianRequestStatus.pending,
            relation: PlayerRelation.self,
            createdAt: DateTime.utc(2026, 11, 14),
          ),
        ],
      );
      await openTeamTab(tester);
      const self = "Claire Dunphy says they're Emma #7 on the roster.";
      const noah4 =
          "Pat Lee wants to add Noah Park #4 to the roster, as Noah's "
          'guardian.';
      const claireNew = 'Claire Dunphy wants to join the roster as player #12.';
      final order = [self, noah4, claimSentence, claireNew];
      for (final s in order) {
        expect(find.text(s), findsOneWidget);
      }
      // Oldest first.
      final ys = [for (final s in order) tester.getTopLeft(find.text(s)).dy];
      expect(ys, [...ys]..sort());
      // The buttons sit on their own line, under the words.
      final row = find.ancestor(
        of: find.text(claimSentence),
        matching: find.byType(RequestTile),
      );
      final approve = find.descendant(
        of: row,
        matching: find.widgetWithText(FilledButton, 'Approve'),
      );
      expect(
        tester.getTopLeft(approve).dy,
        greaterThan(tester.getBottomLeft(find.text(claimSentence)).dy),
      );
      expect(tester.getSize(approve).height, greaterThanOrEqualTo(48));
      expect(
        find.descendant(
          of: row,
          matching: find.widgetWithText(OutlinedButton, 'Decline'),
        ),
        findsOneWidget,
      );
    });

    testWidgets("a parent's say parent, as they picked (#95)", (tester) async {
      await open(
        tester,
        players: [
          emma,
          noah().copyWith(proposedTitle: GuardianTitle.parent),
        ],
        requests: [patClaim.copyWith(title: GuardianTitle.parent)],
        links: const [
          GuardianLink(
            playerId: PlayerId('emma'),
            groupId: GroupId('y'),
            uid: UserId('claire'),
            title: GuardianTitle.parent,
          ),
        ],
      );
      await openTeamTab(tester);
      const parentClaim = "Pat Lee says they're a parent of Emma #7.";
      expect(find.text(parentClaim), findsOneWidget);
      expect(
        find.text(
          "Pat Lee wants to add Noah Park to the roster, as Noah's parent.",
        ),
        findsOneWidget,
      );
      // Who's linked already says it too.
      await tester.tap(find.text(parentClaim));
      await tester.pumpAndSettle();
      expect(find.text('Claire Dunphy, parent'), findsOneWidget);
    });

    testWidgets('a self request with no number', (tester) async {
      await open(
        tester,
        players: [
          emma,
          const Player(
            id: PlayerId('claire'),
            groupId: GroupId('y'),
            displayName: 'Claire Dunphy',
            status: PlayerStatus.pending,
            proposedBy: 'claire',
            proposedRelation: PlayerRelation.self,
          ),
        ],
        requests: const [],
      );
      await openTeamTab(tester);
      expect(
        find.text('Claire Dunphy wants to join the roster as a player.'),
        findsOneWidget,
      );
    });
  });

  group('what a decision did', () {
    Finder inRow(String sentence, Finder f) => find.descendant(
      of: find.ancestor(
        of: find.text(sentence),
        matching: find.byType(RequestTile),
      ),
      matching: f,
    );

    testWidgets('approving a claim says who can answer whose RSVPs', (
      tester,
    ) async {
      final repo = await open(tester);
      await openTeamTab(tester);
      await tester.tap(
        inRow(claimSentence, find.widgetWithText(FilledButton, 'Approve')),
      );
      await tester.pumpAndSettle();
      expect(repo.calls, ['approve emma pat']);
      expect(find.text("Pat can answer Emma's RSVPs now."), findsOneWidget);
    });

    testWidgets('declining says they can ask again', (tester) async {
      final repo = await open(tester);
      await openTeamTab(tester);
      await tester.tap(
        inRow(claimSentence, find.widgetWithText(OutlinedButton, 'Decline')),
      );
      await tester.pumpAndSettle();
      expect(repo.calls, ['decline emma pat']);
      expect(find.text('Declined. Pat can ask again.'), findsOneWidget);
    });

    testWidgets('approving a new player with no number offers Add number, '
        'which opens the player', (tester) async {
      final repo = await open(tester);
      await openTeamTab(tester);
      await tester.tap(
        inRow(noahSentence, find.widgetWithText(FilledButton, 'Approve')),
      );
      await tester.pumpAndSettle();
      expect(repo.calls, ['approvePlayer noah']);
      expect(
        find.text("Noah is on the roster. Pat can answer Noah's RSVPs now."),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(SnackBarAction, 'Add number'));
      await tester.pumpAndSettle();
      expect(location(tester), '/g/y/team/players/noah');
    });
  });

  group('the request sheet', () {
    testWidgets("a new player's name and number are fixed, saved, then "
        'approved', (tester) async {
      final handle = tester.ensureSemantics();
      final repo = await open(tester);
      await openTeamTab(tester);
      await tester.tap(find.text(noahSentence));
      await tester.pumpAndSettle();
      expect(find.text('Add this player?'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.text('Add this player?'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      final sheet = find.byType(RequestSheet);
      final fields = find.descendant(
        of: sheet,
        matching: find.byType(TextField),
      );
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.first, 'Noah Parker');
      await tester.enterText(fields.last, '9');
      await tester.tap(
        find.descendant(
          of: sheet,
          matching: find.widgetWithText(FilledButton, 'Approve'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.calls, ['update noah Noah Parker', 'approvePlayer noah']);
      expect(repo.jerseyNumbers['noah'], '9');
      expect(find.byType(RequestSheet), findsNothing);
      // Numbered now: no Add number.
      expect(
        find.text("Noah is on the roster. Pat can answer Noah's RSVPs now."),
        findsOneWidget,
      );
      expect(find.text('Add number'), findsNothing);
      handle.dispose();
    });

    testWidgets("a failed save doesn't approve, and says so", (tester) async {
      final repo = await open(tester);
      repo.updateFailure = const UnknownFailure('unavailable');
      await openTeamTab(tester);
      await tester.tap(find.text(noahSentence));
      await tester.pumpAndSettle();
      final sheet = find.byType(RequestSheet);
      await tester.enterText(
        find.descendant(of: sheet, matching: find.byType(TextField)).first,
        'Noah Parker',
      );
      await tester.tap(
        find.descendant(
          of: sheet,
          matching: find.widgetWithText(FilledButton, 'Approve'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      expect(
        find.text(
          "Couldn't save the name and number, so it wasn't approved. Try "
          'again.',
        ),
        findsOneWidget,
      );
      expect(find.byType(RequestSheet), findsOneWidget);
    });

    testWidgets("a claim shows who's already linked to the player", (
      tester,
    ) async {
      final repo = await open(
        tester,
        links: const [
          GuardianLink(
            playerId: PlayerId('emma'),
            groupId: GroupId('y'),
            uid: UserId('claire'),
          ),
        ],
      );
      await openTeamTab(tester);
      await tester.tap(find.text(claimSentence));
      await tester.pumpAndSettle();
      expect(find.text('Approve this link?'), findsOneWidget);
      expect(find.text('Claire Dunphy, guardian'), findsOneWidget);
      // Closing it changes nothing.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
    });

    testWidgets('reads well: 48 px targets, contrast, and 200% text', (
      tester,
    ) async {
      await open(tester, size: const Size(390, 844));
      await openTeamTab(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      await tester.tap(find.text(claimSentence));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
