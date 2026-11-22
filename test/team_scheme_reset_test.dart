// A team's color scheme, by its admins (SET-2, #73, owner's request
// 2026-11-20: "make it so that a person can set their own theme for a team
// but also a team admin can reset it for everyone"): System default (no
// team default, so everyone sees their own default), and Reset for
// everyone, which asks first and takes back every member's own pick.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const boss = AuthUser(
    uid: 'boss',
    email: 'boss@example.com',
    emailVerified: true,
    isSuperAdmin: true,
  );

  /// Thunder, its default [teamDefault] (none: System default).
  FakeGroupRepository thunder({TeamScheme? teamDefault}) =>
      FakeGroupRepository({
        'a': testGroup('a', 'Thunder').copyWith(colorScheme: teamDefault),
        'b': testGroup('b', 'Comets'),
      });

  /// Opens Admin settings → Team color scheme, my default Light.
  Future<void> open(
    WidgetTester tester, {
    required FakeGroupRepository groups,
    required FakeMemberRepository members,
    AuthUser user = coach,
    FakeAdminRepository? admin,
  }) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: user),
      prefs: FakeLocalPrefs()..defaultSchemeValue = TeamScheme.light,
      users: FakeUserRepository()..colorScheme = TeamScheme.light,
      groupRepo: groups,
      memberRepo: members,
      admin: admin,
      size: const Size(400, 1800),
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .go('/g/a/settings/color-scheme');
    await tester.pumpAndSettle();
  }

  /// Whether [row] is the checked one.
  void expectPicked(WidgetTester tester, String row, {required bool picked}) =>
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^$row, '))),
        isSemantics(isSelected: picked, isButton: true, hasTapAction: true),
      );

  /// The scheme the page is drawn in.
  TeamScheme drawnIn(WidgetTester tester) =>
      GumdropColors.of(tester.element(find.text('Reset for everyone'))).scheme;

  Future<void> tapReset(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Reset for everyone'));
    await tester.tap(find.text('Reset for everyone'));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();
  }

  testWidgets('System default takes the team default away, and is checked '
      'while none is set', (tester) async {
    final groups = thunder(teamDefault: TeamScheme.dark);
    await open(
      tester,
      groups: groups,
      members: FakeMemberRepository([
        testMembership('a', 'coach', role: MemberRole.owner),
      ]),
    );
    expectPicked(tester, 'Black', picked: true);
    expectPicked(tester, 'System default', picked: false);
    expect(find.text('Everyone sees their own default'), findsOneWidget);
    // With no pick of mine, I see the team's default.
    expect(drawnIn(tester), TeamScheme.dark);

    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();
    expect(groups.updates, contains('colorScheme none'));
    expect(groups.groups['a']!.colorScheme, isNull);
    expectPicked(tester, 'System default', picked: true);
    expectPicked(tester, 'Black', picked: false);
    // Now my own default.
    expect(drawnIn(tester), TeamScheme.light);

    // The checked row writes nothing.
    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();
    expect(groups.updates.where((u) => u.startsWith('colorScheme')), [
      'colorScheme none',
    ]);
  });

  testWidgets('Reset for everyone asks first, then takes back every pick on '
      'the team, mine too, and says how many', (tester) async {
    final members = FakeMemberRepository([
      testMembership(
        'a',
        'coach',
        role: MemberRole.owner,
      ).copyWith(colorScheme: TeamScheme.army),
      testMembership('a', 'sam').copyWith(colorScheme: TeamScheme.dark),
      testMembership('a', 'jo'),
      // Another team's pick stays, even of a scheme the app no longer
      // offers (#85).
      testMembership('b', 'coach').copyWith(colorScheme: TeamScheme.skyblue),
    ]);
    await open(
      tester,
      groups: thunder(teamDefault: TeamScheme.dark),
      members: members,
    );
    expect(drawnIn(tester), TeamScheme.army);
    expect(
      find.text(
        'Anyone on Thunder can still pick their own with Color scheme in '
        'Team settings. Reset for everyone takes back every pick, so '
        'everyone sees the choice above.',
      ),
      findsOneWidget,
    );

    await tapReset(tester);
    expect(find.text("Reset everyone's color scheme?"), findsOneWidget);
    expect(
      find.text(
        'Everyone will see Thunder in Black. They can still pick their own '
        'afterward.',
      ),
      findsOneWidget,
    );
    // Cancel does nothing.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(members.calls, isNot(contains('schemes a reset')));
    expect(drawnIn(tester), TeamScheme.army);

    await tapReset(tester);
    await confirm(tester);
    expect(members.calls, contains('schemes a reset'));
    expect(find.text('Reset for 2 people.'), findsOneWidget);
    expect(
      [
        for (final m in members.memberships)
          '${m.groupId.value} ${m.uid.value} ${m.colorScheme?.value}',
      ],
      ['a coach null', 'a sam null', 'a jo null', 'b coach skyblue'],
    );
    // I see the team's default now, and can still pick my own.
    expect(drawnIn(tester), TeamScheme.dark);
  });

  testWidgets('with System default, everyone goes back to their own '
      'default', (tester) async {
    final members = FakeMemberRepository([
      testMembership(
        'a',
        'coach',
        role: MemberRole.owner,
      ).copyWith(colorScheme: TeamScheme.army),
    ]);
    await open(tester, groups: thunder(), members: members);
    await tapReset(tester);
    expect(
      find.text(
        'Everyone will see Thunder in their own default color scheme. They '
        'can still pick their own afterward.',
      ),
      findsOneWidget,
    );
    await confirm(tester);
    expect(find.text('Reset for 1 person.'), findsOneWidget);
    expect(drawnIn(tester), TeamScheme.light);

    // Nothing left to take back.
    await tapReset(tester);
    await confirm(tester);
    expect(find.text('Nobody had picked their own.'), findsOneWidget);
  });

  testWidgets('a refused reset says so, and changes nothing', (tester) async {
    final members = FakeMemberRepository([
      testMembership(
        'a',
        'coach',
        role: MemberRole.owner,
      ).copyWith(colorScheme: TeamScheme.army),
    ])..resetSchemesFails = const PermissionDenied('permission-denied');
    await open(tester, groups: thunder(), members: members);
    await tapReset(tester);
    await confirm(tester);
    expect(find.text("You can't do that on this team."), findsOneWidget);
    expect(members.memberships.single.colorScheme, TeamScheme.army);
  });

  testWidgets("a super admin's System default goes through the audited "
      "callable, and they can reset a team they aren't on", (tester) async {
    final admin = FakeAdminRepository();
    final members = FakeMemberRepository([
      testMembership(
        'a',
        'coach',
        role: MemberRole.owner,
      ).copyWith(colorScheme: TeamScheme.army),
    ]);
    await open(
      tester,
      user: boss,
      admin: admin,
      groups: thunder(teamDefault: TeamScheme.dark),
      members: members,
    );
    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();
    expect(admin.calls.last, 'team a colorScheme=none');

    await tapReset(tester);
    await confirm(tester);
    expect(members.calls, contains('schemes a reset'));
    expect(find.text('Reset for 1 person.'), findsOneWidget);
  });
}
