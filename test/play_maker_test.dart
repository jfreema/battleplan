import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/widgets/info_tag.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/presentation/roster_screen.dart';
import 'package:battleplan/features/plays/domain/play_rules.dart';
import 'package:battleplan/features/plays/presentation/play_editor_screen.dart';
import 'package:battleplan/features/plays/presentation/plays_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// #63: a team's admins make someone a play maker from their card on the
/// Team tab; a play maker draws, saves, and changes the team's plays as
/// admins do (BOARD-4).
void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const maria = AuthUser(
    uid: 'maria',
    email: 'maria@example.com',
    emailVerified: true,
  );
  final thunder = testGroup('a', 'Thunder');

  group('canEditPlays', () {
    test('lets play makers edit, on an open team with players', () {
      final maker = testMembership('a', 'maria').copyWith(playMaker: true);
      final member = testMembership('a', 'sam');
      expect(canEditPlays(thunder, maker), isTrue);
      expect(canEditPlays(thunder, member), isFalse);
      expect(
        canEditPlays(
          thunder.copyWith(archivedAt: DateTime.utc(2026, 11)),
          maker,
        ),
        isFalse,
      );
      expect(
        canEditPlays(thunder.copyWith(kind: GroupKind.group), maker),
        isFalse,
      );
    });
  });

  Future<FakeMemberRepository> openCard(
    WidgetTester tester, {
    required String viewer,
    required MemberRole viewerRole,
    required String target,
    MemberRole targetRole = MemberRole.member,
    bool playMaker = false,
    Group? team,
  }) async {
    final members = FakeMemberRepository([
      testMembership('a', 'coach', role: MemberRole.owner, name: 'Jordan'),
      if (viewer != 'coach')
        testMembership('a', viewer, role: viewerRole, name: 'Viewer Vee'),
      testMembership(
        'a',
        target,
        role: targetRole,
        name: 'Maria Rodriguez',
      ).copyWith(playMaker: playMaker),
    ]);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(
        user: viewer == 'coach'
            ? coach
            : AuthUser(
                uid: viewer,
                email: '$viewer@example.com',
                emailVerified: true,
              ),
      ),
      groups: {'a': team ?? thunder},
      memberRepo: members,
    );
    await openTeamTab(
      tester,
      label: (team ?? thunder).hasPlayers ? 'Team' : 'People',
    );
    await tester.tap(find.text('Maria Rodriguez'));
    await tester.pumpAndSettle();
    return members;
  }

  final makerSwitch = find.widgetWithText(SwitchListTile, 'Play maker');

  testWidgets('an admin makes a member a play maker from their card, and '
      'the card says so', (tester) async {
    final members = await openCard(
      tester,
      viewer: 'coach',
      viewerRole: MemberRole.owner,
      target: 'maria',
    );
    await tester.ensureVisible(makerSwitch);
    expect(
      find.text("Can draw, save, and change the team's plays"),
      findsOneWidget,
    );
    expect(tester.widget<SwitchListTile>(makerSwitch).value, isFalse);
    await tester.tap(makerSwitch);
    await tester.pumpAndSettle();
    expect(members.calls, ['playMaker maria true']);
    expect(tester.widget<SwitchListTile>(makerSwitch).value, isTrue);
    // A tag under the name, beside Coach and Admin's.
    expect(
      find.descendant(
        of: find.byType(MemberCard),
        matching: find.widgetWithText(InfoTag, 'Play maker'),
      ),
      findsOneWidget,
    );
    await tester.tap(makerSwitch);
    await tester.pumpAndSettle();
    expect(members.calls.last, 'playMaker maria false');
    expect(find.widgetWithText(InfoTag, 'Play maker'), findsNothing);
  });

  testWidgets('admins make plays anyway: no switch on an admin', (
    tester,
  ) async {
    await openCard(
      tester,
      viewer: 'coach',
      viewerRole: MemberRole.owner,
      target: 'maria',
      targetRole: MemberRole.admin,
    );
    expect(makerSwitch, findsNothing);
  });

  testWidgets('members see the tag, not the switch', (tester) async {
    await openCard(
      tester,
      viewer: 'sam',
      viewerRole: MemberRole.member,
      target: 'maria',
      playMaker: true,
    );
    expect(makerSwitch, findsNothing);
    expect(find.widgetWithText(InfoTag, 'Play maker'), findsOneWidget);
  });

  testWidgets('a basic group has no plays, so no play makers', (tester) async {
    await openCard(
      tester,
      viewer: 'coach',
      viewerRole: MemberRole.owner,
      target: 'maria',
      playMaker: true,
      team: thunder.copyWith(kind: GroupKind.group),
    );
    expect(makerSwitch, findsNothing);
    expect(find.widgetWithText(InfoTag, 'Play maker'), findsNothing);
  });

  testWidgets("a play maker's Plays tab is the whiteboard; a member's is "
      'the saved plays', (tester) async {
    for (final maker in [true, false]) {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: maria),
        groups: {'a': thunder},
        memberships: [testMembership('a', 'maria').copyWith(playMaker: maker)],
      );
      await tester.tap(find.text('Plays'));
      await tester.pumpAndSettle();
      expect(
        find.byType(PlayEditorScreen),
        maker ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(SavedPlaysScreen),
        maker ? findsNothing : findsOneWidget,
      );
    }
  });
}
