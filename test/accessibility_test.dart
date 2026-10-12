// Accessibility of the main screens (SPEC §7.6) in light and dark: Flutter's
// guideline checks for tap targets, labels, and text contrast.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/scenes.dart';

void main() {
  final guidelines = {
    'Android tap targets': androidTapTargetGuideline,
    'iOS tap targets': iOSTapTargetGuideline,
    'labeled tap targets': labeledTapTargetGuideline,
    'text contrast': textContrastGuideline,
  };

  // The main screens, and the sheets and screens most used from them.
  final screens = {
    ...mainScreens,
    'team switcher': (WidgetTester tester, {required bool dark}) async {
      await pumpChat(tester, dark: dark);
      await tester.tap(find.bySemanticsLabel('Switch team: Thunder U14'));
      await tester.pumpAndSettle();
    },
    'message menu': (WidgetTester tester, {required bool dark}) async {
      await pumpChat(tester, dark: dark);
      await tester.scrollUntilVisible(
        find.text('Great hustle today'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.longPress(find.text('Great hustle today'));
      await tester.pumpAndSettle();
    },
    'roster': (WidgetTester tester, {required bool dark}) async {
      await pumpTeam(tester, dark: dark);
      await goTo(tester, '/g/a/roster');
    },
    'settings': (WidgetTester tester, {required bool dark}) async {
      await pumpTeam(tester, dark: dark);
      await goTo(tester, '/settings');
    },
    'notifications': (WidgetTester tester, {required bool dark}) async {
      await pumpTeam(tester, dark: dark);
      await goTo(tester, '/notifications');
    },
    'calendar': (WidgetTester tester, {required bool dark}) async {
      await pumpSchedule(tester, dark: dark);
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
    },
  };

  for (final MapEntry(key: name, value: pump) in screens.entries) {
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('$name ($theme) meets the guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, dark: dark);
        // Every guideline, so one failure doesn't hide the next.
        final failures = <String>[];
        for (final MapEntry(key: what, value: guideline)
            in guidelines.entries) {
          final result = await guideline.evaluate(tester);
          if (!result.passed) {
            failures.add('$what:\n${result.reason}');
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n\n'));
        handle.dispose();
      });
    }
  }

  group('screen reader labels (SPEC §7.6)', () {
    testWidgets('photos, reactions, and the team switcher', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpChat(tester, dark: false);
      // Photos read "Photo from Alex Kim" and open the viewer.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Photo from Alex Kim').first),
        isSemantics(
          label: 'Photo from Alex Kim',
          isButton: true,
          hasTapAction: true,
        ),
      );
      // Reaction chips read the reaction's name and count, not the emoji.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Like, 2')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      // The switcher's label replaces its contents but keeps its tap.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Switch team: Thunder U14')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('RSVP answers say their state in words with an icon, not '
        'color alone', (tester) async {
      await pumpEventDetails(tester, dark: false);
      for (final word in ['Going', 'Maybe', 'Not going']) {
        final button = find.ancestor(
          of: find.text(word).first,
          matching: find.byType(SegmentedButton<RsvpStatus>),
        );
        expect(button, findsOneWidget, reason: word);
      }
      expect(find.text('Going · 2'), findsOneWidget);
      expect(find.text('Maybe · 1'), findsOneWidget);
      expect(find.text('Not going · 1'), findsOneWidget);
      expect(find.byIcon(AppIcons.going), findsWidgets);
      expect(find.byIcon(AppIcons.maybe), findsWidgets);
      expect(find.byIcon(AppIcons.notGoing), findsWidgets);
    });
  });

  group('text at 200% (SPEC §7.6)', () {
    for (final MapEntry(key: name, value: pump) in screens.entries) {
      testWidgets('$name lays out without overflow', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester, dark: false);
        // An overflow is reported as an exception while laying out.
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('keyboard (SPEC §4.2, §7.6)', () {
    Future<void> press(
      WidgetTester tester,
      LogicalKeyboardKey key, {
      bool control = false,
      bool shift = false,
    }) async {
      if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(key);
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
    }

    testWidgets('Ctrl+K opens the team switcher sheet, and Esc closes it', (
      tester,
    ) async {
      await pumpChat(tester, dark: false);
      await press(tester, LogicalKeyboardKey.keyK, control: true);
      expect(find.text('Join a team'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.escape);
      expect(find.text('Join a team'), findsNothing);
    });

    testWidgets('⌘K works from the other tabs too', (tester) async {
      await pumpDocuments(tester, dark: false);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await press(tester, LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();
      expect(find.text('Join a team'), findsOneWidget);
    });

    testWidgets('Esc closes dialogs and menus', (tester) async {
      await pumpChat(tester, dark: false);
      await tester.scrollUntilVisible(
        find.text('Close poll'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Close poll'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close poll'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await press(tester, LogicalKeyboardKey.escape);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.byTooltip('Add photos or a poll'));
      await tester.pumpAndSettle();
      expect(find.text('Photo library'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.escape);
      expect(find.text('Photo library'), findsNothing);
    });

    testWidgets('Enter sends; Shift+Enter starts a new line', (tester) async {
      final messages = FakeMessageRepository(sceneMessages);
      await pumpTeam(tester, dark: false, messages: messages);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'On my way');
      await press(tester, LogicalKeyboardKey.enter, shift: true);
      expect(messages.sent, isEmpty);
      await press(tester, LogicalKeyboardKey.enter);
      expect(messages.sent, ['On my way']);
    });

    testWidgets('Tab reaches the header, the composer, and the tabs, with a '
        'visible focus', (tester) async {
      await pumpChat(tester, dark: false);
      final reached = <String>[];
      for (var i = 0; i < 40; i++) {
        await press(tester, LogicalKeyboardKey.tab);
        final focus = FocusManager.instance.primaryFocus;
        final context = focus?.context;
        if (context == null) continue;
        final label =
            context.findAncestorWidgetOfExactType<Tooltip>()?.message ??
            (context.findAncestorWidgetOfExactType<TextField>() != null
                ? 'message box'
                : null) ??
            context
                .findAncestorWidgetOfExactType<NavigationDestination>()
                ?.label ??
            context
                .findAncestorWidgetOfExactType<Semantics>()
                ?.properties
                .label;
        if (label != null && !reached.contains(label)) reached.add(label);
      }
      expect(
        FocusManager.instance.highlightMode,
        FocusHighlightMode.traditional,
      );
      // One lap of the Tab order, from the team switcher: the header, the
      // chat, the composer, then the tabs.
      final start = reached.indexWhere((l) => l.startsWith('Switch team'));
      expect(start, isNot(-1), reason: '$reached');
      final lap = [...reached.skip(start), ...reached.take(start)];
      expect(
        lap,
        containsAllInOrder([
          'Switch team: Thunder U14',
          'Notifications',
          'Team menu',
          'Account',
          'Add photos or a poll',
          'message box',
          'Chat',
          'Schedule',
          'Documents',
        ]),
      );
    });
  });
}
