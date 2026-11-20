// The frame for pages opened on top (SPEC §7.3, #14 step 2, owner's go
// 2026-11-16): a pinned back row, and a big title that scrolls away with
// the page, its name fading into the back row where it fits.
//
// The test font draws every letter 1 em square, so names are wide here;
// the phone is a wide one so the small title has room.

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/back_chevron.dart';
import 'package:battleplan/core/widgets/team_switcher_button.dart';
import 'package:battleplan/features/chat/presentation/messages_button.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/groups/presentation/teams_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  testWidgets("Settings' pages are on the frame and go back to Settings", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final (route, title) in [
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

  // Notification settings moved from Settings to Profile (#28).
  testWidgets('Notification settings is on the frame and goes back to '
      'Profile', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTeam(tester, scheme: TeamScheme.army);
    await goTo(tester, '/profile');
    await pushTo(tester, '/settings/notifications');
    expect(
      find.widgetWithText(PageTitle, 'Notification settings'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Back, Profile'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TopLevelBar, 'Profile'), findsOneWidget);
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
    // Notification settings lists every team's.
    await goTo(tester, '/profile');
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
    expect(
      find.bySemanticsLabel('Back, Notification settings'),
      findsOneWidget,
    );
    handle.dispose();
  });

  // Step 5: Invite's two email pages and the player card's RSVP history.
  testWidgets("Invite's email pages go back to Invite, and RSVP history to "
      'the player, by name', (tester) async {
    final handle = tester.ensureSemantics();
    for (final (route, title) in [
      ('/g/a/invite/email', 'Email invites'),
      ('/g/a/members/add', 'Add people by email'),
    ]) {
      await pumpTeam(tester, scheme: TeamScheme.army);
      await pushTo(tester, '/g/a/invite');
      await pushTo(tester, route);
      expect(find.widgetWithText(PageTitle, title), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back, Invite'));
      await tester.pumpAndSettle();
      // Its title names the team (#16); its pages' backs say "Invite".
      expect(
        find.widgetWithText(PageTitle, 'Invite to Thunder U14'),
        findsOneWidget,
      );
    }
    await pumpTeam(tester, scheme: TeamScheme.army);
    await pushTo(tester, '/g/a/team/players/mia');
    await pushTo(tester, '/g/a/team/players/mia/history');
    expect(find.widgetWithText(PageTitle, 'RSVP history'), findsOneWidget);
    expect(find.bySemanticsLabel('Back, Mia'), findsOneWidget);
    handle.dispose();
  });

  // Step 6: the rest of the pages opened on top.
  testWidgets('Messages goes back to the team that opened it, by name, or '
      'to Teams', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTeam(tester, scheme: TeamScheme.army);
    await tester.tap(find.byType(MessagesButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PageTitle, 'Messages'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back, Thunder U14'));
    await tester.pumpAndSettle();
    await goTo(tester, '/teams');
    await tester.tap(
      find.descendant(
        of: find.byType(TeamsScreen),
        matching: find.byType(MessagesButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PageTitle, 'Messages'), findsOneWidget);
    expect(find.bySemanticsLabel('Back, Teams'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Join and Create go back to Teams, or to the team whose '
      'switcher opened them', (tester) async {
    final handle = tester.ensureSemantics();
    for (final (row, title) in [
      ('Join a Team or Group', 'Join a Team or Group'),
      ('Create a Team', 'Create a Team'),
    ]) {
      await pumpTeam(tester, scheme: TeamScheme.army);
      await goTo(tester, '/teams');
      await scrollToTeamsRows(tester);
      await tester.tap(find.text(row).last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PageTitle, title), findsOneWidget);
      expect(find.bySemanticsLabel('Back, Teams'), findsOneWidget);

      await pumpTeam(tester, scheme: TeamScheme.army);
      await tester.tap(find.byType(TeamSwitcherButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(row).last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PageTitle, title), findsOneWidget);
      expect(find.bySemanticsLabel('Back, Thunder U14'), findsOneWidget);
    }
    handle.dispose();
  });

  testWidgets('Add players goes back to the Team tab, Team photos to '
      'Documents, and Assignments to its event, by name', (tester) async {
    final handle = tester.ensureSemantics();
    for (final (from, route, title, back) in [
      ('/g/a/team', '/g/a/players/add', 'Add players', 'Back, Team'),
      ('/g/a/documents', '/g/a/documents/photos', 'Photos', 'Back, Documents'),
      (
        '/g/a/schedule/e/e1',
        '/g/a/schedule/e/e1/assignments',
        'Assignments',
        'Back, vs. Eagles',
      ),
    ]) {
      await pumpTeam(tester, scheme: TeamScheme.army);
      await goTo(tester, from);
      await pushTo(tester, route);
      expect(find.widgetWithText(PageTitle, title), findsOneWidget);
      expect(find.bySemanticsLabel(back), findsOneWidget, reason: route);
    }
    // The back row names the event, so the page doesn't again.
    expect(find.text('vs. Eagles'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('vs. Eagles'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('Assignments opened from a link names its event on the page, '
      'with nothing under it to name', (tester) async {
    await pumpTeam(tester, scheme: TeamScheme.army);
    await goTo(tester, '/g/a/schedule/e/e1/assignments');
    expect(find.widgetWithText(PageTitle, 'Assignments'), findsOneWidget);
    expect(find.text('vs. Eagles'), findsOneWidget);
  });

  testWidgets("on wide screens Invite's pages, Media, Reports and Import "
      'open as side panels, like the other settings pages', (tester) async {
    for (final (from, route, title) in [
      ('/g/a/team', '/g/a/invite', 'Invite to Thunder U14'),
      ('/g/a/team', '/g/a/invite/email', 'Email invites'),
      ('/g/a/team', '/g/a/members/add', 'Add people by email'),
      ('/g/a/info', '/g/a/media', 'Media'),
      ('/g/a/info', '/g/a/reports', 'Reports'),
      ('/g/a/info', '/g/a/import', 'Import'),
    ]) {
      await pumpTeam(tester, scheme: TeamScheme.army, size: wideSize);
      await goTo(tester, from);
      await pushTo(tester, route);
      final page = find.widgetWithText(PageTitle, title);
      expect(page, findsOneWidget, reason: route);
      // A panel over the screen it came from, which shows around it.
      expect(ModalRoute.of(tester.element(page))!.opaque, isFalse);
    }
  });

  testWidgets("on a wide screen the big title lines up with the page's "
      "column, not the window's edge", (tester) async {
    await pumpTeam(tester, scheme: TeamScheme.army, size: wideSize);
    await goTo(tester, '/profile');
    await pushTo(tester, '/settings/notifications');
    final title = find.widgetWithText(PageTitle, 'Notification settings');
    final column = find.descendant(
      of: find.byType(PageList),
      matching: find.byType(ListView),
    );
    // Both have the 20 px margin inside, so their edges meet.
    expect(tester.getTopLeft(title).dx, tester.getTopLeft(column).dx);
    expect(tester.getSize(title).width, tester.getSize(column).width);
  });

  // #29 (owner's go 2026-11-20): on a computer the back row's chevron and
  // icons stood at the window's edges, far from the page's column, and
  // Messages and Notifications stretched across the window.
  testWidgets('on a wide screen the back row, the page and its button keep '
      "to the page's column", (tester) async {
    await pumpTeam(tester, scheme: TeamScheme.army, size: wideSize);
    await goTo(tester, '/teams');
    for (final (route, title) in [
      ('/notifications', 'Notifications'),
      ('/messages', 'Messages'),
    ]) {
      await pushTo(tester, route);
      final column = tester.getRect(find.widgetWithText(PageTitle, title));
      expect(column.width, 560);
      expect(column.center.dx, closeTo(wideSize.width / 2, 0.01));
      // The chevron at the column's left, the icons inside its right.
      final back = tester.getRect(find.byType(BackChevron));
      expect(back.left, greaterThanOrEqualTo(column.left));
      expect(back.left, lessThan(column.left + 20));
      for (final icon in [
        ...tester.widgetList(find.byType(IconButton)),
        ...tester.widgetList(find.byType(FloatingActionButton)),
      ]) {
        final rect = tester.getRect(find.byWidget(icon));
        expect(rect.left, greaterThanOrEqualTo(column.left), reason: title);
        expect(rect.right, lessThanOrEqualTo(column.right), reason: title);
      }
      tester.element(find.byType(PageTitle)).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets("on a wide screen Teams' and Profile's titles and icons keep "
      "to the page's column", (tester) async {
    await pumpTeam(tester, scheme: TeamScheme.army, size: wideSize);
    for (final route in ['/teams', '/profile']) {
      await goTo(tester, route);
      final bar = tester.getRect(
        find
            .descendant(
              of: find.byType(TopLevelBar),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      final page = tester.getRect(find.byType(ListView).first);
      expect(bar.width, 560, reason: route);
      expect(bar.left, page.left, reason: route);
      expect(bar.right, page.right, reason: route);
    }
  });

  testWidgets("on a wide screen a team's header keeps to the chat's column, "
      'everything in it still there', (tester) async {
    await pumpTeam(tester, scheme: TeamScheme.army, size: wideSize);
    final chat = tester.getRect(find.byType(StatefulNavigationShell));
    expect(chat.width, Breakpoints.contentMax);
    for (final part in [
      find.byType(BackChevron),
      find.byType(TeamSwitcherButton),
      find.byType(MessagesButton),
      find.byTooltip('Team settings'),
    ]) {
      final rect = tester.getRect(part.first);
      expect(rect.left, greaterThanOrEqualTo(chat.left));
      expect(rect.right, lessThanOrEqualTo(chat.right));
    }
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
