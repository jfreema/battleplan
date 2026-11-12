// Tap targets with the app's real fonts (SPEC §7.6), at a 390 px phone and
// a 360 px one (many Android phones). The test font draws every letter
// 1 em wide, so a tap area sized by its word or squeezed by a narrow
// screen (the icon colors) only shows up here. Fonts stay loaded for the
// whole file, which is why this is a file of its own.
//
// The schedule isn't here yet: its Upcoming/Past toggle sizes each tab by
// its word, and "Past" is narrower than 44 px. The schedule's own fix
// widens those tabs and adds the schedule to this list.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/groups/presentation/shell_parts.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/golden.dart';
import 'helpers/scenes.dart';

void main() {
  setUpAll(loadAppFonts);

  final guidelines = {
    'Android tap targets': androidTapTargetGuideline,
    'iOS tap targets': iOSTapTargetGuideline,
  };

  Future<void> top(WidgetTester tester, Size size, String path) async {
    await pumpTeam(tester, scheme: TeamScheme.army, size: size);
    await goTo(tester, path);
  }

  final screens = {
    'chat': (WidgetTester tester, Size size) =>
        pumpTeam(tester, scheme: TeamScheme.army, size: size),
    'teams': (WidgetTester tester, Size size) => top(tester, size, '/teams'),
    // Teams' rows under Your schedule (SCHED-2): Join, Create, and the
    // default color scheme, below the fold once the cards show.
    'teams, its rows': (WidgetTester tester, Size size) async {
      await top(tester, size, '/teams');
      await scrollToTeamsRows(tester);
      expect(find.text('Join a Team or Group'), findsOneWidget);
    },
    // Your schedule's page, from See all on Teams.
    'your schedule': (WidgetTester tester, Size size) async {
      await top(tester, size, '/teams');
      await pushTo(tester, '/teams/schedule');
      expect(find.text('vs. Eagles'), findsOneWidget);
    },
    'profile': (WidgetTester tester, Size size) =>
        top(tester, size, '/profile'),
    'your icon': (WidgetTester tester, Size size) async {
      await top(tester, size, '/profile');
      await pushTo(tester, '/profile/icon');
    },
    // The Team tab: the team's card with Invite and Dues side by side,
    // the search and sort, the roster, and the + (SPEC §5.3).
    'team tab': (WidgetTester tester, Size size) =>
        top(tester, size, '/g/a/team'),
    'team settings': (WidgetTester tester, Size size) async {
      await pumpTeam(tester, scheme: TeamScheme.army, size: size);
      await pushTo(tester, '/g/a/info');
    },
    'color scheme': (WidgetTester tester, Size size) async {
      await top(tester, size, '/g/a/info');
      await pushTo(tester, '/g/a/scheme');
    },
    'dues': (WidgetTester tester, Size size) async {
      await top(tester, size, '/g/a/team');
      await pushTo(tester, '/g/a/dues');
    },
    'due': (WidgetTester tester, Size size) async {
      await top(tester, size, '/g/a/team');
      await pushTo(tester, '/g/a/dues');
      await pushTo(tester, '/g/a/dues/d0');
    },
    'new due': (WidgetTester tester, Size size) async {
      await top(tester, size, '/g/a/team');
      await pushTo(tester, '/g/a/dues');
      await pushTo(tester, '/g/a/dues/new');
    },
    'who owes what': (WidgetTester tester, Size size) async {
      await top(tester, size, '/g/a/team');
      await pushTo(tester, '/g/a/dues');
      await pushTo(tester, '/g/a/dues/people');
    },
    'a share': (WidgetTester tester, Size size) async {
      await top(tester, size, '/g/a/team');
      await pushTo(tester, '/g/a/dues');
      await pushTo(tester, '/g/a/dues/d0');
      await tester.ensureVisible(find.text('Leo #9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leo #9'));
      await tester.pumpAndSettle();
    },
  };

  for (final size in [phoneSize, const Size(360, 780)]) {
    for (final MapEntry(key: name, value: pump) in screens.entries) {
      testWidgets('$name meets the tap target guidelines at '
          '${size.width.round()} px with real fonts', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, size);
        final failures = <String>[];
        for (final MapEntry(key: what, value: guideline)
            in guidelines.entries) {
          final result = await guideline.evaluate(tester);
          if (!result.passed) failures.add('$what:\n${result.reason}');
        }
        expect(failures, isEmpty, reason: failures.join('\n\n'));
        handle.dispose();
      });
    }
  }

  // Five tabs share a 360-point phone (SPEC §5.3). "Documents" fills its
  // tab at the default text size; with larger text, a label too long for
  // its tab shrinks to fit rather than ending in "…".
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('every tab label is whole and inside its tab at 360 px, '
        'with text at ${(scale * 100).round()}%', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await top(tester, const Size(360, 780), '/g/a/chat');
      for (final label in ['Chat', 'Schedule', 'Documents', 'Plays', 'Team']) {
        final text = find.descendant(
          of: find.byType(OpenFieldTabBar),
          matching: find.text(label),
        );
        final tab = find
            .ancestor(of: text, matching: find.byType(Expanded))
            .first;
        expect(
          tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
          isFalse,
          reason: label,
        );
        final (drawn, room) = (tester.getRect(text), tester.getRect(tab));
        expect(drawn.left, greaterThanOrEqualTo(room.left), reason: label);
        expect(drawn.right, lessThanOrEqualTo(room.right), reason: label);
      }
    });
  }

  // A phone on its side is wide enough for the rail (840 px and up) but
  // short: with large text, five tabs are taller than the screen, and the
  // rail scrolls rather than overflows.
  testWidgets('the rail scrolls down to the Team tab on a phone on its side '
      'with text at 200%', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await top(tester, const Size(852, 393), '/g/a/chat');
    final team = find.descendant(
      of: find.byType(OpenFieldRail),
      matching: find.text('Team'),
    );
    await tester.ensureVisible(team);
    await tester.pumpAndSettle();
    await tester.tap(team);
    await tester.pumpAndSettle();
    expect(find.text('TEAM ROSTER'), findsOneWidget);
  });
}
