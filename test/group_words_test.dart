// Groups say group, not team (owner's go 2026-11-16, "do #30"; SPEC
// TEAM-14): a group's settings, Admin settings, notifications, Media,
// new season, and leaving use group words; a team's keep team words.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
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

  Future<void> open(
    WidgetTester tester,
    String path, {
    GroupKind kind = GroupKind.group,
    MemberRole role = MemberRole.owner,
  }) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Book club').copyWith(kind: kind)},
      memberships: [testMembership('a', 'coach', role: role)],
      size: const Size(400, 6000),
    );
    final router = GoRouter.of(tester.element(find.byType(Navigator).first))
      ..go('/g/a/chat');
    await tester.pumpAndSettle();
    for (final p in path.split(',')) {
      unawaited(router.push(p));
      await tester.pumpAndSettle();
    }
  }

  testWidgets("a group's settings say group", (tester) async {
    await open(tester, '/g/a/info');
    expect(find.text('Notifications for this group'), findsOneWidget);
    expect(find.textContaining('team'), findsNothing);
  });

  testWidgets("a group's Admin settings say group, with a friend's message "
      'in the chat look', (tester) async {
    await open(tester, '/g/a/info,/g/a/settings');
    const chatIntro =
        'How the group chat looks for everyone in Book club. Only admins can '
        'change it.';
    for (final words in [
      'GROUP NAME',
      'Color',
      "The color is on the group's badge and in the switcher.",
      "Everyone can see who's in the group",
      'Off: only admins see everyone in the group. Members see only themselves.',
      chatIntro,
      'Sam',
      'Moved to 7 tonight, same place.',
      'Group color',
      'A new group for the next season, with the people you choose.',
      'Archive group',
      'Delete group',
    ]) {
      expect(find.text(words), findsWidgets, reason: words);
    }
    for (final words in [
      'TEAM NAME',
      'Team color',
      'Coach',
      'Archive team',
      'Delete team',
    ]) {
      expect(find.text(words), findsNothing, reason: words);
    }

    await tester.tap(find.text('Archive group'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The group becomes read-only'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete group'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Type the group name'), findsOneWidget);
  });

  testWidgets("a team's Admin settings keep team words", (tester) async {
    await open(tester, '/g/a/info,/g/a/settings', kind: GroupKind.team);
    for (final words in [
      'TEAM NAME',
      'Team color',
      "Everyone can see who's on the team",
      'Coach',
      'Archive team',
      'Delete team',
    ]) {
      expect(find.text(words), findsWidgets, reason: words);
    }
    expect(find.text('GROUP NAME'), findsNothing);
  });

  testWidgets("a group's notifications, Media and new season say group", (
    tester,
  ) async {
    await open(tester, '/g/a/info,/g/a/notifications');
    expect(find.text('Notifications for this group'), findsOneWidget);
    expect(
      find.text('Every message and update from this group.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'No pushes from this group. The bell still lists its activity.',
      ),
      findsOneWidget,
    );

    await open(tester, '/g/a/info,/g/a/media');
    expect(find.textContaining('the group logo'), findsOneWidget);

    await open(tester, '/g/a/info,/g/a/settings,/g/a/season');
    expect(find.text('NEW GROUP NAME'), findsOneWidget);
    expect(find.textContaining("this group's logo"), findsOneWidget);
    expect(find.textContaining('in the new group at once'), findsOneWidget);
  });

  testWidgets('a member leaves a group, not a team', (tester) async {
    await open(tester, '/g/a/team', role: MemberRole.member);
    await tester.tap(find.text('coach').first);
    await tester.pumpAndSettle();
    expect(find.text('Leave group'), findsOneWidget);
    expect(find.text('Leave team'), findsNothing);
  });
}
