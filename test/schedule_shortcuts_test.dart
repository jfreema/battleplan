// Calendar sync and Import where you'd look for them (owner's go
// 2026-11-16, "do #22"; SPEC SCHED-1, SCHED-2, SCHED-11): "Sync to my
// calendar" at the top of Upcoming, a team's and Your schedule's, and
// "Import a schedule" beside the + for a team's admins.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/group.dart';
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
  const sync = 'Sync to my calendar';
  const import = 'Import a schedule';

  Event practice(String id, {int days = 2}) {
    final start = DateTime.now().toUtc().add(Duration(days: days));
    return Event(
      id: EventId(id),
      groupId: const GroupId('a'),
      type: EventType.practice,
      title: 'Practice',
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      timeZone: 'America/Chicago',
      createdBy: 'coach',
    );
  }

  Future<void> open(
    WidgetTester tester, {
    MemberRole role = MemberRole.owner,
    AuthUser user = coach,
    List<Event>? events,
    Group? group,
    bool member = true,
  }) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: user),
      groups: {'a': group ?? testGroup('a', 'Thunder')},
      memberships: [if (member) testMembership('a', user.uid, role: role)],
      eventRepo: FakeEventRepository(events ?? [practice('e1')]),
    );
  }

  Future<void> go(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
    await tester.pumpAndSettle();
  }

  String location(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Navigator).first)).state.uri
          .toString();

  testWidgets("a team's Upcoming starts with Sync to my calendar, which "
      'opens its calendar link and comes back to Schedule', (tester) async {
    await open(tester, role: MemberRole.member);
    await go(tester, '/g/a/schedule');
    expect(find.text(sync), findsOneWidget);
    // Above the first event.
    expect(
      tester.getTopLeft(find.text(sync)).dy,
      lessThan(tester.getTopLeft(find.text('Practice')).dy),
    );
    await tester.tap(find.text(sync));
    await tester.pumpAndSettle();
    expect(location(tester), '/g/a/calendar');
    expect(
      find.textContaining("Keep Thunder's schedule in your calendar"),
      findsOneWidget,
    );
    expect(find.text('Schedule'), findsWidgets);

    // Not on Past.
    await go(tester, '/g/a/schedule');
    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();
    expect(find.text(sync), findsNothing);
  });

  testWidgets('the empty Upcoming has it too, above its message', (
    tester,
  ) async {
    await open(tester, role: MemberRole.member, events: const []);
    await go(tester, '/g/a/schedule');
    expect(find.text(sync), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(sync)).dy,
      lessThan(
        tester
            .getTopLeft(
              find.text('No upcoming events. Your coaches will add them here.'),
            )
            .dy,
      ),
    );
  });

  testWidgets("Your schedule's See all opens every team's calendar link", (
    tester,
  ) async {
    await open(tester);
    await go(tester, '/teams');
    unawaited(
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push('/teams/schedule'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(sync));
    await tester.pumpAndSettle();
    expect(location(tester), '/teams/calendar');
    expect(
      find.textContaining("Keep every team's schedule in your calendar"),
      findsOneWidget,
    );
    // Every team's alone: no choosing a team.
    expect(find.text('All my teams'), findsNothing);
    expect(find.text('Your schedule'), findsWidgets);
  });

  testWidgets('not for a super admin viewing a team', (tester) async {
    await open(
      tester,
      user: const AuthUser(
        uid: 'boss',
        email: 'boss@example.com',
        emailVerified: true,
        isSuperAdmin: true,
      ),
      member: false,
    );
    await go(tester, '/g/a/schedule');
    expect(find.text(sync), findsNothing);
  });

  testWidgets('an admin gets Import a schedule beside the +, which opens '
      'Import', (tester) async {
    await open(tester);
    await go(tester, '/g/a/schedule');
    final button = find.widgetWithText(OutlinedButton, import);
    expect(button, findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
    // Beside the +, to its left.
    final plus = find.byTooltip('New event');
    expect(tester.getCenter(button).dx, lessThan(tester.getCenter(plus).dx));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(location(tester), '/g/a/import');
    expect(find.text('Schedule'), findsWidgets);
  });

  testWidgets('a member who can add events gets only the +; an empty '
      'Upcoming offers Import once, in its message', (tester) async {
    await open(
      tester,
      role: MemberRole.member,
      group: testGroup(
        'a',
        'Thunder',
      ).copyWith(settings: const GroupSettings(membersCanCreateEvents: true)),
    );
    await go(tester, '/g/a/schedule');
    expect(find.byTooltip('New event'), findsOneWidget);
    expect(find.text(import), findsNothing);

    await open(tester, events: const []);
    await go(tester, '/g/a/schedule');
    expect(find.text(import), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, import), findsNothing);
  });

  testWidgets('reads well: 48 px targets and 200% text', (tester) async {
    await open(tester);
    await go(tester, '/g/a/schedule');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Import is its icon alone then, named by its tooltip.
    expect(find.byTooltip(import), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, import), findsNothing);
  });
}
