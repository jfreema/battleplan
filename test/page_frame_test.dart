// The frame for pages opened on top (SPEC §7.3, #14 step 2, owner's go
// 2026-11-16): a pinned back row, and a big title that scrolls away with
// the page, its name fading into the back row where it fits.
//
// The test font draws every letter 1 em square, so names are wide here;
// the phone is a wide one so the small title has room.

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/scenes.dart';

/// [title] in the back row, as the small title.
Finder _small(String title) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(title));

Future<void> _scroll(WidgetTester tester, double by) async {
  await tester.drag(find.byType(Scrollable).last, Offset(0, -by));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("the big title scrolls away with the page, and the page's name "
      'fades into the back row, with a hairline under it', (tester) async {
    await pumpTeam(tester, scheme: TeamScheme.army, size: const Size(800, 900));
    await goTo(tester, '/profile');
    await pushTo(tester, '/settings');
    expect(find.widgetWithText(PageTitle, 'Settings'), findsOneWidget);
    expect(_small('Settings'), findsNothing);
    AppBar bar() => tester.widget<AppBar>(find.byType(AppBar).last);
    expect(bar().shape, isNull);

    await _scroll(tester, 400);
    // Out of sight, and the back row says where you are instead.
    expect(find.widgetWithText(PageTitle, 'Settings'), findsNothing);
    expect(_small('Settings'), findsOneWidget);
    expect(bar().shape, isA<Border>());
    // Still one heading for screen readers: the small title is only its
    // echo.
    expect(
      find.descendant(
        of: find.byType(ExcludeSemantics),
        matching: find.text('Settings'),
      ),
      findsOneWidget,
    );

    await _scroll(tester, -800);
    expect(find.widgetWithText(PageTitle, 'Settings'), findsOneWidget);
    expect(_small('Settings'), findsNothing);
  });

  // Step 3: they had a plain bar, a smaller title and narrower margins.
  testWidgets("Settings' three pages are on the frame and go back to "
      'Settings', (tester) async {
    final handle = tester.ensureSemantics();
    for (final (route, title) in [
      ('/settings/notifications', 'Notifications'),
      ('/settings/sign-in-methods', 'Sign-in methods'),
      ('/settings/blocked', 'Blocked people'),
    ]) {
      await pumpTeam(tester, scheme: TeamScheme.army);
      await goTo(tester, '/profile');
      await pushTo(tester, '/settings');
      await pushTo(tester, route);
      expect(find.widgetWithText(PageTitle, title), findsOneWidget);
      expect(find.bySemanticsLabel('Back, Settings'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back, Settings'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PageTitle, 'Settings'), findsOneWidget);
    }
    handle.dispose();
  });

  // Step 4: Team settings had the chevron alone, and its pages plain bars.
  testWidgets('Team settings goes back into the team, by name, and its five '
      'pages go back to Team settings', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTeam(tester, scheme: TeamScheme.army);
    await pushTo(tester, '/g/a/info');
    expect(find.widgetWithText(PageTitle, 'Team settings'), findsOneWidget);
    expect(find.bySemanticsLabel('Back, Thunder U14'), findsOneWidget);
    for (final (route, title) in [
      ('/g/a/notifications', 'Notifications for this team'),
      ('/g/a/calendar', 'Calendar link'),
      ('/g/a/media', 'Media'),
      ('/g/a/reports', 'Reports'),
      ('/g/a/import', 'Import'),
    ]) {
      await pushTo(tester, route);
      expect(find.widgetWithText(PageTitle, title), findsOneWidget);
      expect(find.bySemanticsLabel('Back, Team settings'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back, Team settings'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PageTitle, 'Team settings'), findsOneWidget);
    }
    handle.dispose();
  });

  testWidgets('opened from elsewhere, those pages name where they go back '
      'to', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTeam(tester, scheme: TeamScheme.army);
    // Settings' Notifications lists every team's.
    await goTo(tester, '/profile');
    await pushTo(tester, '/settings');
    await pushTo(tester, '/settings/notifications');
    await tester.scrollUntilVisible(
      find.text('Thunder U14'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Thunder U14'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(PageTitle, 'Notifications for this team'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Back, Notifications'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the small title stays out where it would crowd the back '
      'label: the back label matters more', (tester) async {
    await pumpTeam(tester, scheme: TeamScheme.army, size: const Size(320, 700));
    await pushTo(tester, '/g/a/info');
    await pushTo(tester, '/g/a/settings');
    await _scroll(tester, 400);
    expect(find.text('Team settings'), findsOneWidget);
    expect(_small('Admin settings'), findsNothing);
  });
}
