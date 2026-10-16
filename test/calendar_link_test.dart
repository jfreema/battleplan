// Calendar links (SPEC SCHED-11): from the team menu, a private link for
// this team or all my teams, added to Google, Apple, or Outlook Calendar or
// copied, with Reset and Turn off after asking.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/schedule/domain/calendar_link.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

const _coach = AuthUser(
  uid: 'coach',
  email: 'coach@example.com',
  emailVerified: true,
);

void main() {
  /// The coach on Thunder ([alsoCyclone]: and Cyclone), on Calendar link.
  Future<({FakeCalendarLinkRepository links, FakeLinkOpener opener})> open(
    WidgetTester tester, {
    FakeCalendarLinkRepository? links,
    bool alsoCyclone = false,
  }) async {
    final repo = links ?? FakeCalendarLinkRepository();
    final opener = FakeLinkOpener();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: _coach),
      groups: {
        'a': testGroup('a', 'Thunder'),
        if (alsoCyclone) 'b': testGroup('b', 'Cyclone'),
      },
      memberships: [
        testMembership('a', 'coach', role: MemberRole.owner),
        if (alsoCyclone) testMembership('b', 'coach'),
      ],
      calendarLinks: repo,
      linkOpener: opener,
    );
    await tester.tap(find.byTooltip('Team menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar link'));
    await tester.pumpAndSettle();
    return (links: repo, opener: opener);
  }

  testWidgets('the team menu opens it; a link is made when asked, and '
      'adds to Google Calendar or Outlook', (tester) async {
    final r = await open(tester);
    expect(
      find.textContaining("Keep Thunder's schedule in your calendar"),
      findsOneWidget,
    );
    // Nothing until asked: a link is a secret worth having on purpose.
    expect(r.links.calls, isEmpty);
    await tester.tap(find.text('Make my calendar link'));
    await tester.pumpAndSettle();
    expect(r.links.calls, ['make a']);
    final token = r.links.links.single.token;

    await tester.tap(find.text('Add to Google Calendar'));
    await tester.pumpAndSettle();
    expect(
      r.opener.opened.last.toString(),
      'https://calendar.google.com/calendar/r'
      '?cid=webcal%3A%2F%2Fgetbattleplan.app%2Fcal%2F$token.ics',
    );
    await tester.tap(find.text('Add to Outlook'));
    await tester.pumpAndSettle();
    expect(r.opener.opened.last.queryParameters, {
      'url': 'https://getbattleplan.app/cal/$token.ics',
      'name': 'Thunder',
    });
    // webcal:// opens nothing on Android.
    expect(find.text('Add to Apple Calendar'), findsNothing);
    expect(find.text('No calendar has checked this link yet.'), findsOneWidget);
    expect(
      find.textContaining('Anyone with this link can see this schedule'),
      findsOneWidget,
    );
  });

  testWidgets('Apple Calendar on an iPhone, iPad, or Mac', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      const token = 'Xk3v9QmZp0aB1cD2eF3gH4iJ5kL6mN7oP8qR9sT0uVw';
      final r = await open(
        tester,
        links: FakeCalendarLinkRepository(
          links: [const CalendarLink(token: token, groupId: GroupId('a'))],
        ),
      );
      await tester.tap(find.text('Add to Apple Calendar'));
      await tester.pumpAndSettle();
      expect(
        r.opener.opened.single.toString(),
        'webcal://getbattleplan.app/cal/$token.ics',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Copy link copies the https link, and says when a calendar '
      'last checked', (tester) async {
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
    const token = 'Xk3v9QmZp0aB1cD2eF3gH4iJ5kL6mN7oP8qR9sT0uVw';
    await open(
      tester,
      links: FakeCalendarLinkRepository(
        links: [
          CalendarLink(
            token: token,
            groupId: const GroupId('a'),
            fetchedAt: DateTime(2026, 10, 16, 15, 40),
          ),
        ],
      ),
    );
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();
    expect(copied, 'https://getbattleplan.app/cal/$token.ics');
    expect(find.text('Link copied.'), findsOneWidget);
    expect(
      find.textContaining(
        'A calendar last checked this link on October 16 at 3:40',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Reset and Turn off ask first', (tester) async {
    final r = await open(tester);
    await tester.tap(find.text('Make my calendar link'));
    await tester.pumpAndSettle();
    final first = r.links.links.single.token;

    await tester.ensureVisible(find.text('Reset link'));
    await tester.tap(find.text('Reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your calendar link?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(r.links.links.single.token, first);

    await tester.tap(find.text('Reset link'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(r.links.links.single.token, isNot(first));

    await tester.ensureVisible(find.text('Turn off'));
    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();
    expect(find.text('Turn off your calendar link?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Turn off'));
    await tester.pumpAndSettle();
    expect(r.links.links, isEmpty);
    expect(find.text('Make my calendar link'), findsOneWidget);
    expect(r.links.calls, ['make a', 'reset a', 'off a']);
  });

  testWidgets('All my teams has a link of its own', (tester) async {
    final r = await open(tester, alsoCyclone: true);
    await tester.tap(find.text('All my teams'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('including teams you join later'),
      findsOneWidget,
    );
    await tester.tap(find.text('Make my calendar link'));
    await tester.pumpAndSettle();
    expect(r.links.calls, ['make all']);
    expect(r.links.links.single.groupId, isNull);
    await tester.tap(find.text('Add to Outlook'));
    await tester.pumpAndSettle();
    expect(r.opener.opened.last.queryParameters['name'], 'Battleplan');
    // Thunder's own link is still to make.
    await tester.tap(find.text('Thunder').last);
    await tester.pumpAndSettle();
    expect(find.text('Make my calendar link'), findsOneWidget);
  });

  testWidgets("says so when the link can't be made", (tester) async {
    final links = FakeCalendarLinkRepository()
      ..failWith = const Offline('offline');
    await open(tester, links: links);
    await tester.tap(find.text('Make my calendar link'));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't change your calendar link. Try again."),
      findsOneWidget,
    );
    expect(find.text('Make my calendar link'), findsOneWidget);
  });
}
