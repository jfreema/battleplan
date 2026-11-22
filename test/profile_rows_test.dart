import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// #28: Notification settings and the default color scheme sit on Profile,
/// where people look for them; the bell and a team's notifications page
/// lead to Notification settings too, and Settings keeps only account
/// things, with one Sign out (Profile's).
void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  final teams = {
    'a': testGroup('a', 'Thunder', lastMessageAt: DateTime(2026, 10)),
  };
  final mine = [testMembership('a', 'coach', role: MemberRole.owner)];

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    auth: FakeAuthRepository(user: coach),
    groups: teams,
    memberships: mine,
  );

  GoRouter router(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Scaffold).last));

  String path(WidgetTester tester) => router(tester).state.uri.path;

  testWidgets('Profile has Notifications and Color scheme rows, each going '
      'back to Profile', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await openProfile(tester);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(path(tester), '/settings/notifications');
    expect(
      find.widgetWithText(PageTitle, 'Notification settings'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Back, Profile'));
    await tester.pumpAndSettle();
    expect(path(tester), '/profile');

    // The row says which scheme new teams get: the test app's is Black.
    final row = find.widgetWithText(PageRow, 'Color scheme');
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text('Black')),
      findsOneWidget,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(path(tester), '/teams/scheme');
    expect(
      find.widgetWithText(PageTitle, 'Default color scheme'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Back, Profile'));
    await tester.pumpAndSettle();
    expect(path(tester), '/profile');
    handle.dispose();
  });

  testWidgets("the bell's gear opens Notification settings, going back to "
      'Notifications', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notification settings'));
    await tester.pumpAndSettle();
    expect(path(tester), '/settings/notifications');
    await tester.tap(find.bySemanticsLabel('Back, Notifications'));
    await tester.pumpAndSettle();
    expect(path(tester), '/g/a/activity');
    handle.dispose();
  });

  testWidgets("a team's notifications page ends with a link to every "
      "team's, going back to it", (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    unawaited(router(tester).push('/g/a/notifications'));
    await tester.pumpAndSettle();
    final link = find.text('Notification settings for all teams');
    await tester.scrollUntilVisible(
      link,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(path(tester), '/settings/notifications');
    expect(
      find.bySemanticsLabel('Back, Notifications for this team'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('Settings keeps account things: no Notifications, and no '
      'second Sign out', (tester) async {
    await pump(tester);
    await openProfile(tester);
    expect(find.text('Sign out'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(path(tester), '/settings');
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Sign out'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Sign out of all devices'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Sign out of all devices'), findsOneWidget);
  });
}
