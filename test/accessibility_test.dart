// Accessibility of the main screens (SPEC §7.6) in each color scheme:
// Flutter's guideline checks for tap targets, labels, and text contrast.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/scenes.dart';

void main() {
  // A tap or long press that misses what it aims at fails the test rather
  // than testing nothing.
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  final guidelines = {
    'Android tap targets': androidTapTargetGuideline,
    'iOS tap targets': iOSTapTargetGuideline,
    'labeled tap targets': labeledTapTargetGuideline,
    'text contrast': textContrastGuideline,
  };

  // The main screens, and the sheets and screens most used from them.
  final screens = {
    ...mainScreens,
    // The answer buttons on the schedule's cards (SCHED-4) scroll under the
    // + button, which the contrast check would read as their colors: the
    // list moves until none is under it, as a person would scroll.
    'schedule': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpSchedule(tester, scheme: scheme);
      await clearOfAddButton(tester);
    },
    'team switcher': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpChat(tester, scheme: scheme);
      await tester.tap(find.bySemanticsLabel('Switch team: Thunder U14'));
      await tester.pumpAndSettle();
    },
    'message menu': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpChat(tester, scheme: scheme);
      await tester.scrollUntilVisible(
        find.text('Great hustle today'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      // At large text sizes the scroll can leave it just off screen.
      await tester.ensureVisible(find.text('Great hustle today'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Great hustle today'));
      await tester.pumpAndSettle();
      expect(find.text('Copy text'), findsOneWidget, reason: 'menu open');
    },
    // Search in the chat (CHAT-20), with a result.
    'chat search': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpChat(tester, scheme: scheme);
      await tester.tap(find.byTooltip('Search the chat'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'hustle');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('hustle', findRichText: true),
        findsWidgets,
        reason: 'a result',
      );
    },
    // The top (SPEC §5.1), and a team's info (§5.2).
    for (final (name, route) in [
      ('teams', '/teams'),
      ('profile', '/profile'),
      ('team info', '/g/a/info'),
    ])
      name: (WidgetTester tester, {required TeamScheme scheme}) async {
        await pumpChat(tester, scheme: scheme);
        await goTo(tester, route);
      },
    'wide chat': (WidgetTester tester, {required TeamScheme scheme}) =>
        pumpTeam(tester, scheme: scheme, size: wideSize),
    'roster': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpTeam(tester, scheme: scheme);
      await goTo(tester, '/g/a/roster');
    },
    // Start a new season (TEAM-16), from Team admin.
    'new season': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpTeam(tester, scheme: scheme);
      await goTo(tester, '/g/a/season');
    },
    'settings': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpTeam(tester, scheme: scheme);
      await goTo(tester, '/settings');
    },
    'notifications': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpTeam(tester, scheme: scheme);
      await goTo(tester, '/notifications');
    },
    // Color scheme: my default, and how I see a team (SET-2).
    'default color scheme':
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpTeam(tester, scheme: scheme);
          await goTo(tester, '/teams/scheme');
        },
    'color scheme': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpTeam(tester, scheme: scheme);
      await goTo(tester, '/g/a/scheme');
    },
    'group schedule':
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpGroupSchedule(tester, scheme: scheme);
          await clearOfAddButton(tester);
        },
    'dues': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpTeam(tester, scheme: scheme);
      await goTo(tester, '/g/a/dues');
    },
    'your icon': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpTeam(tester, scheme: scheme);
      await goTo(tester, '/profile/icon');
    },
    'calendar': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpSchedule(tester, scheme: scheme);
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
    },
  };

  // Every screen in every color scheme: their colors all differ.
  for (final MapEntry(key: name, value: pump) in screens.entries) {
    for (final scheme in TeamScheme.values) {
      testWidgets('$name (${scheme.value}) meets the guidelines', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(tester, scheme: scheme);
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
    testWidgets("a message's icon is in the color its author picked (SET-8)", (
      tester,
    ) async {
      await pumpChat(tester, scheme: TeamScheme.army);
      final avatars = tester
          .widgetList<Avatar>(find.byType(Avatar))
          .where((a) => a.name == 'Sam Rivera');
      expect(avatars, isNotEmpty);
      expect(avatars.first.color, AvatarColor.mint);
    });

    testWidgets('photos, reactions, and the team switcher', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpChat(tester, scheme: TeamScheme.navy);
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
      // So does an author's photo, which opens their page (TEAM-15).
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp(r"^Open .*'s profile$")).first,
        ),
        isSemantics(isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('RSVP answers say their state in words with an icon, not '
        'color alone', (tester) async {
      await pumpEventDetails(tester, scheme: TeamScheme.navy);
      for (final word in ['Going', 'Maybe', 'Not going']) {
        final button = find.ancestor(
          of: find.text(word).first,
          matching: find.byType(SegmentedButton<RsvpStatus>),
        );
        expect(button, findsOneWidget, reason: word);
      }
      expect(find.text('GOING · 2'), findsOneWidget);
      expect(find.text('MAYBE · 1'), findsOneWidget);
      expect(find.text('NOT GOING · 1'), findsOneWidget);
      expect(find.byIcon(AppIcons.going), findsWidgets);
      expect(find.byIcon(AppIcons.maybe), findsWidgets);
      expect(find.byIcon(AppIcons.notGoing), findsWidgets);
    });
  });

  // In Army green (the default) and Light blue (a light one).
  group('text at 200% (SPEC §7.6)', () {
    for (final scheme in [TeamScheme.army, TeamScheme.skyblue]) {
      for (final MapEntry(key: name, value: pump) in screens.entries) {
        testWidgets('$name lays out without overflow (${scheme.value})', (
          tester,
        ) async {
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pump(tester, scheme: scheme);
          // An overflow is reported as an exception while laying out.
          expect(tester.takeException(), isNull);
        });
      }
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
      await pumpChat(tester, scheme: TeamScheme.navy);
      await press(tester, LogicalKeyboardKey.keyK, control: true);
      expect(find.text('Join a Team or Group'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.escape);
      expect(find.text('Join a Team or Group'), findsNothing);
    });

    testWidgets('Esc closes dialogs and menus', (tester) async {
      await pumpChat(tester, scheme: TeamScheme.navy);
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
      await pumpTeam(tester, scheme: TeamScheme.navy, messages: messages);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'On my way');
      await press(tester, LogicalKeyboardKey.enter, shift: true);
      expect(messages.sent, isEmpty);
      await press(tester, LogicalKeyboardKey.enter);
      expect(messages.sent, ['On my way']);
    });

    testWidgets('Enter picks the word an input method is composing, and '
        "doesn't send", (tester) async {
      final messages = FakeMessageRepository(sceneMessages);
      await pumpTeam(tester, scheme: TeamScheme.navy, messages: messages);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      // Typing Japanese: 'にほ' is still a candidate, not yet confirmed.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'にほ',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 2),
        ),
      );
      await tester.pump();
      await press(tester, LogicalKeyboardKey.enter);
      expect(messages.sent, isEmpty);
      // The word is confirmed; now Enter sends.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '日本',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();
      await press(tester, LogicalKeyboardKey.enter);
      expect(messages.sent, ['日本']);
    });

    testWidgets('Tab reaches the header, the composer, and the tabs, with a '
        'visible focus', (tester) async {
      await pumpChat(tester, scheme: TeamScheme.navy);
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
        // A tab reads "Chat, Tab 1 of 4".
        final name = label?.split(', Tab ').first;
        if (name != null && !reached.contains(name)) reached.add(name);
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
          'Team info',
          'Add photos or a poll',
          'message box',
          'Chat',
          'Schedule',
          'Documents',
        ]),
      );
    });

    testWidgets('Tab reaches the Teams cards, rows, the default scheme row '
        'and the tab bar', (tester) async {
      await pumpTeam(tester, scheme: TeamScheme.navy);
      await goTo(tester, '/teams');
      final reached = <String>[];
      for (var i = 0; i < 30; i++) {
        await press(tester, LogicalKeyboardKey.tab);
        final context = FocusManager.instance.primaryFocus?.context;
        if (context == null) continue;
        final label =
            context.findAncestorWidgetOfExactType<Tooltip>()?.message ??
            context
                .findAncestorWidgetOfExactType<Semantics>()
                ?.properties
                .label ??
            _textIn(context);
        if (label != null && !reached.contains(label)) reached.add(label);
      }
      for (final want in [
        'Thunder U14',
        'Join a Team or Group',
        'Default color scheme',
        'Profile',
      ]) {
        expect(
          reached.any((l) => l.contains(want)),
          isTrue,
          reason: '$want in $reached',
        );
      }
    });
  });
}

/// Scrolls the schedule until no answer button sits under its + button.
Future<void> clearOfAddButton(WidgetTester tester) async {
  final add = find.byType(FloatingActionButton);
  if (add.evaluate().isEmpty) return;
  final covered = tester.getRect(add).inflate(8);
  // Nor half scrolled out at the top, where the check would read the page
  // behind the cut-off card as their colors.
  final top = tester.getRect(find.byType(Scrollable).last).top;
  for (var i = 0; i < 20; i++) {
    final under = find.byType(SegmentedButton<RsvpStatus>).evaluate().any((e) {
      final r = tester.getRect(find.byWidget(e.widget));
      return r.overlaps(covered) || (r.top < top && r.bottom > top);
    });
    if (!under) return;
    await tester.drag(
      find.byType(Scrollable).last,
      const Offset(0, -40),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }
}

/// The texts under [context]'s widget, for a focused row or card whose
/// label is its text.
String? _textIn(BuildContext context) {
  final found = <String>[];
  void visit(Element e) {
    final w = e.widget;
    if (w is Text) {
      final t = w.data ?? w.textSpan?.toPlainText();
      if (t != null) found.add(t);
      return;
    }
    e.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
  return found.isEmpty ? null : found.join(' ');
}
