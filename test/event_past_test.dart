// Past events, and Delete in the event menu (owner's go 2026-11-16, "once
// #30 is done, do #35"; SPEC SCHED-4): a past event's page says Ended,
// titles its list "Who said they'd go" and drops the reminder line; the
// menu sets Cancel event and Delete apart, in the warning red.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
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

  Event event(String id, Duration fromNow) {
    final start = DateTime.now().toUtc().add(fromNow);
    return Event(
      id: EventId(id),
      groupId: const GroupId('a'),
      type: EventType.practice,
      title: 'Practice',
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      timeZone: 'America/Chicago',
      createdBy: 'coach',
      reminderOffsets: const [60],
    );
  }

  Future<void> open(WidgetTester tester, Event e) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
      eventRepo: FakeEventRepository([e]),
      // A player, so the event lists who's coming.
      playerRepo: FakePlayerRepository(const [
        Player(
          id: PlayerId('emma'),
          groupId: GroupId('a'),
          displayName: 'Emma',
        ),
      ]),
    );
    GoRouter.of(tester.element(find.byType(Navigator).first))
        .go('/g/a/schedule/e/${e.id.value}');
    await tester.pumpAndSettle();
  }

  testWidgets('a past event says Ended and what people said, with no '
      'reminders', (tester) async {
    await open(tester, event('old', const Duration(days: -2)));
    expect(find.text('Ended'), findsOneWidget);
    expect(find.text("Who said they'd go"), findsOneWidget);
    expect(find.text("Who's going"), findsNothing);
    expect(find.textContaining('Reminders'), findsNothing);
  });

  testWidgets('an upcoming one stays as it was', (tester) async {
    await open(tester, event('next', const Duration(days: 2)));
    expect(find.text('Ended'), findsNothing);
    expect(find.text("Who's going"), findsOneWidget);
    expect(find.textContaining('Reminders'), findsOneWidget);
  });

  testWidgets('the menu sets Cancel event and Delete apart, in red', (
    tester,
  ) async {
    await open(tester, event('next', const Duration(days: 2)));
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuDivider), findsOneWidget);
    final line = tester.getTopLeft(find.byType(PopupMenuDivider)).dy;
    expect(tester.getTopLeft(find.text('Edit')).dy, lessThan(line));
    for (final risky in ['Cancel event', 'Delete']) {
      expect(tester.getTopLeft(find.text(risky)).dy, greaterThan(line));
      final text = tester.widget<Text>(find.text(risky));
      final red = GumdropColors.of(tester.element(find.text(risky))).cherry;
      expect(text.style?.color, red.text, reason: risky);
    }
  });
}
