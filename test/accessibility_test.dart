// Accessibility of the main screens (SPEC §7.6) in each color scheme:
// Flutter's guideline checks for tap targets, labels, and text contrast.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/gumdrop_icon_button.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/auth/presentation/your_icon_screen.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/notifications/domain/notification_item.dart';
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/rendering.dart';
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
      await tester.tap(
        find.bySemanticsLabel(RegExp('Switch team: Thunder U14')),
      );
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
    // The top (SPEC §5.1), and a team's info (§5.2), from the chat's ⓘ.
    for (final (name, route) in [('teams', '/teams'), ('profile', '/profile')])
      name: (WidgetTester tester, {required TeamScheme scheme}) async {
        await pumpChat(tester, scheme: scheme);
        await goTo(tester, route);
      },
    'team info': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpChat(tester, scheme: scheme);
      await pushTo(tester, '/g/a/info');
    },
    'wide chat': (WidgetTester tester, {required TeamScheme scheme}) =>
        pumpTeam(tester, scheme: scheme, size: wideSize),
    // A super admin's Admin panel (SPEC §6.11 Access): in the team's and
    // Teams' headers on a phone, at the rail's foot on a wide screen.
    'super admin chat':
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpTeam(tester, scheme: scheme, user: boss);
          expect(find.byTooltip('Admin panel'), findsOneWidget);
        },
    'super admin teams':
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpTeam(tester, scheme: scheme, user: boss);
          await goTo(tester, '/teams');
          expect(find.byTooltip('Admin panel'), findsOneWidget);
        },
    'super admin wide chat':
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpTeam(tester, scheme: scheme, user: boss, size: wideSize);
          expect(find.text('Admin panel'), findsOneWidget);
        },
    // Pushed screens open as the app opens them, so the back row is
    // checked too (SPEC §5.4.1).
    'roster': (WidgetTester tester, {required TeamScheme scheme}) =>
        pumpFromTeamInfo(tester, scheme: scheme, path: '/g/a/roster'),
    // Start a new season (TEAM-16), from Team admin.
    'new season': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpFromTeamInfo(tester, scheme: scheme, path: '/g/a/settings');
      await pushTo(tester, '/g/a/season');
    },
    'settings': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpTeam(tester, scheme: scheme);
      await goTo(tester, '/profile');
      await pushTo(tester, '/settings');
    },
    // An unread item and a read one, so their text is checked too.
    'notifications': (WidgetTester tester, {required TeamScheme scheme}) async {
      NotificationItem item(String id, {required bool read}) =>
          NotificationItem(
            id: id,
            groupId: const GroupId('a'),
            kind: NotifyKind.reply,
            title: 'Thunder U14',
            body: 'Sam replied to you: Sounds good',
            route: '/g/a/chat',
            read: read,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          );
      await pumpTeam(
        tester,
        scheme: scheme,
        notifications: FakeNotificationRepository([
          item('n1', read: false),
          item('n2', read: true),
        ]),
      );
      await pushTo(tester, '/notifications');
      expect(find.text('Sam replied to you: Sounds good'), findsNWidgets(2));
    },
    // Color scheme: my default, and how I see a team (SET-2).
    'default color scheme':
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpTeam(tester, scheme: scheme);
          await goTo(tester, '/teams/scheme');
        },
    'color scheme': (WidgetTester tester, {required TeamScheme scheme}) =>
        pumpFromTeamInfo(tester, scheme: scheme, path: '/g/a/scheme'),
    // Team admin's team default color scheme (SET-2), its five rows.
    'team color scheme':
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpFromTeamInfo(tester, scheme: scheme, path: '/g/a/settings');
          final last = find.text('Light blue');
          await tester.scrollUntilVisible(
            last,
            200,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.pumpAndSettle();
          expect(find.text('Team color scheme'), findsOneWidget);
        },
    'group schedule':
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpGroupSchedule(tester, scheme: scheme);
          await clearOfAddButton(tester);
        },
    // Dues (DUES-1 to DUES-3): an admin's list with its totals, a due and
    // a share's sheet with its payments, Record a payment, Who owes what,
    // the forms, and what a guardian owes.
    'dues': (WidgetTester tester, {required TeamScheme scheme}) =>
        pumpFromTeamInfo(tester, scheme: scheme, path: '/g/a/dues'),
    'due': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpFromTeamInfo(tester, scheme: scheme, path: '/g/a/dues');
      await pushTo(tester, '/g/a/dues/d0');
    },
    'due status sheet':
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpFromTeamInfo(tester, scheme: scheme, path: '/g/a/dues');
          await pushTo(tester, '/g/a/dues/d0');
          // At large text Leo's row can start past what the list has built.
          await tester.scrollUntilVisible(
            find.text('Leo #9'),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Leo #9'));
          await tester.pumpAndSettle();
          expect(
            find.text('Mark paid in full'),
            findsOneWidget,
            reason: 'sheet',
          );
          expect(find.byTooltip(r'Undo the $20 payment'), findsOneWidget);
        },
    'record a payment':
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpFromTeamInfo(tester, scheme: scheme, path: '/g/a/dues');
          await pushTo(tester, '/g/a/dues/d0');
          // At large text Leo's row can start past what the list has built.
          await tester.scrollUntilVisible(
            find.text('Leo #9'),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Leo #9'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Record a payment'));
          await tester.pumpAndSettle();
          expect(find.text('Date paid'), findsOneWidget, reason: 'dialog');
        },
    'who owes what': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpFromTeamInfo(tester, scheme: scheme, path: '/g/a/dues');
      await tester.ensureVisible(find.text('Who owes what'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Who owes what'));
      await tester.pumpAndSettle();
      expect(find.text('Ava #12'), findsOneWidget);
    },
    'new due': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpFromTeamInfo(tester, scheme: scheme, path: '/g/a/dues');
      await pushTo(tester, '/g/a/dues/new');
    },
    'edit due': (WidgetTester tester, {required TeamScheme scheme}) async {
      await pumpFromTeamInfo(tester, scheme: scheme, path: '/g/a/dues');
      await pushTo(tester, '/g/a/dues/d0');
      await pushTo(tester, '/g/a/dues/d0/edit');
    },
    "a guardian's dues":
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpTeam(tester, scheme: scheme, user: _sam);
          await goTo(tester, '/g/a/info');
          await pushTo(tester, '/g/a/dues');
          expect(find.text('What you owe'), findsOneWidget);
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
    'schedule filter':
        (WidgetTester tester, {required TeamScheme scheme}) async {
          await pumpSchedule(tester, scheme: scheme);
          await tester.tap(find.byTooltip('Filter'));
          await tester.pumpAndSettle();
          expect(find.byType(FilterChip), findsWidgets, reason: 'sheet');
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
          .widgetList<Avatar>(find.byType(Avatar, skipOffstage: false))
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
      // The switcher's label replaces its contents but keeps its tap, and
      // says the eyebrow in plain case first (SPEC §5.4.2).
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Team chat. Switch team: Thunder U14'),
        ),
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

    testWidgets("the team header's Back is a 48 px button of its own, not "
        'the whole screen', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpChat(tester, scheme: TeamScheme.army);
      for (final tab in ['Chat', 'Schedule']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        final back = tester.getSemantics(find.bySemanticsLabel('Back'));
        expect(back, isSemantics(isButton: true, hasTapAction: true));
        expect(back.rect.height, lessThan(60), reason: tab);
        expect(back.rect.width, lessThan(100), reason: tab);
        expect(back.childrenCount, 0, reason: tab);
        // The switcher is beside it, not in it.
        var node = tester.getSemantics(
          find.bySemanticsLabel(RegExp('Switch team')),
        );
        while (node.parent != null) {
          expect(node.parent, isNot(same(back)), reason: tab);
          node = node.parent!;
        }
      }
      handle.dispose();
    });

    testWidgets("the Admin panel reads as a button: the header's on a "
        "phone, and the rail's on a wide screen, which isn't a tab", (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTeam(tester, scheme: TeamScheme.army, user: boss);
      expect(
        tester.getSemantics(find.byTooltip('Admin panel')),
        isSemantics(
          tooltip: 'Admin panel',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ),
      );
      await pumpTeam(
        tester,
        scheme: TeamScheme.army,
        user: boss,
        size: wideSize,
      );
      final link = tester.getSemantics(find.bySemanticsLabel('Admin panel'));
      expect(link, isSemantics(isButton: true, hasTapAction: true));
      expect(link.flagsCollection.isSelected.toBoolOrNull(), isNull);
      // The tabs still count four.
      expect(find.bySemanticsLabel('Plays, Tab 4 of 4'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('headings are their own nodes, a due is a button, and dues '
        'rows read as sentences', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpFromTeamInfo(
        tester,
        scheme: TeamScheme.army,
        path: '/g/a/dues',
      );
      // The heading, without the note under it.
      await tester.scrollUntilVisible(
        find.text('How to pay'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        tester.getSemantics(find.text('How to pay')),
        isSemantics(label: 'How to pay', isHeader: true),
      );
      // The due reads as one button, and New due stays its own.
      final due = tester.getSemantics(find.text('Uniform fee'));
      expect(due, isSemantics(isButton: true, hasTapAction: true));
      expect(due.label, startsWith('Uniform fee'));
      expect(due.label, isNot(contains('New due')));
      // What's owed in all reads as one sentence, and Who owes what is a
      // button of its own (DUES-2).
      expect(
        find.bySemanticsLabel(r'$270 owed in all, $150 paid, $120 left'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.text('Who owes what')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      // A share on a due reads as one sentence, and still taps.
      await pushTo(tester, '/g/a/dues/d0');
      expect(
        tester.getSemantics(find.text('Leo #9')),
        isSemantics(
          label: r'Leo #9, $25 left of $45, Due Oct 31',
          isButton: true,
          hasTapAction: true,
        ),
      );
      // And on Who owes what, with the due's name.
      await goTo(tester, '/g/a/dues/people');
      expect(
        find.bySemanticsLabel(r'Ava #12, Tournament fee, $20 left of $30'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(r'Ava #12, $65 left of $75')),
        isSemantics(isHeader: true),
      );

      // On Teams: the section label isn't the row's button, and a card
      // says its team's name once.
      await goTo(tester, '/teams');
      expect(
        tester.getSemantics(find.text('COLOR SCHEME')),
        isSemantics(label: 'Color scheme', isHeader: true, isButton: false),
      );
      final card = tester.getSemantics(find.text('Thunder U14'));
      expect(card, isSemantics(isButton: true));
      expect(card.flagsCollection.isImage, isFalse);
      expect('Thunder U14'.allMatches(card.label), hasLength(1));
      handle.dispose();
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

    testWidgets("a row's button goes under its text, which keeps the row's "
        'width; an icon stays at the end', (tester) async {
      Future<void> pumpRow(double scale) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PageRow(
                    title: 'Riverside Park',
                    subtitle: '100 River Rd',
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text('Directions'),
                    ),
                  ),
                  PageRow(
                    title: 'Archived',
                    onTap: () {},
                    trailing: const Icon(AppIcons.expand),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpRow(1);
      expect(
        tester.getTopLeft(find.text('Directions')).dy,
        lessThan(tester.getBottomLeft(find.text('Riverside Park')).dy),
      );
      await pumpRow(2);
      expect(
        tester.getTopLeft(find.text('Directions')).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.text('100 River Rd')).dy,
        ),
      );
      // The title keeps the row's width, so it isn't broken mid-word.
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('Riverside Park'))
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 14),
            )
            .map((b) => b.top)
            .toSet(),
        hasLength(1),
      );
      expect(
        tester.getCenter(find.byIcon(AppIcons.expand)).dy,
        moreOrLessEquals(
          tester.getCenter(find.text('Archived')).dy,
          epsilon: 2,
        ),
      );
    });

    testWidgets('unread counts grow with the text and are never cut off', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GumdropIconButton(
                icon: AppIcons.notifications,
                tooltip: 'Notifications',
                onPressed: () {},
                badgeLabel: '12',
              ),
            ),
          ),
        ),
      );
      final text = tester.renderObject<RenderParagraph>(find.text('12'));
      final pill = tester.getSize(
        find
            .ancestor(of: find.text('12'), matching: find.byType(Container))
            .first,
      );
      expect(text.size.height, lessThanOrEqualTo(pill.height));
      expect(text.size.height, greaterThan(19), reason: 'it grew');
      expect(text.didExceedMaxLines, isFalse);
    });
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
      const ringed = [
        'Back',
        'Switch team: Thunder U14',
        'Messages',
        'Notifications',
        'Team info',
        'Add photos or a poll',
        'Chat',
        'Schedule',
        'Documents',
        'Plays',
      ];
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
        if (name != null && !reached.contains(name)) {
          reached.add(name);
          // The header's and the tab bar's show the 3 px ring in the text
          // color (SPEC §7.6).
          if (ringed.any(name.endsWith)) expectFocusRing(tester, name);
        }
      }
      expect(
        FocusManager.instance.highlightMode,
        FocusHighlightMode.traditional,
      );
      // One lap of the Tab order, from the team switcher: the header, the
      // chat, the composer, then the tabs.
      final start = reached.indexWhere((l) => l.contains('Switch team'));
      expect(start, isNot(-1), reason: '$reached');
      final lap = [...reached.skip(start), ...reached.take(start)];
      expect(reached, contains('Back'));
      expect(
        lap,
        containsAllInOrder([
          'Team chat. Switch team: Thunder U14',
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

    testWidgets("Tab reaches a super admin's Admin panel, in the header on "
        'a phone and on the rail on a wide screen, with the ring', (
      tester,
    ) async {
      for (final size in [phoneSize, wideSize]) {
        await pumpTeam(tester, scheme: TeamScheme.navy, user: boss, size: size);
        var reached = false;
        for (var i = 0; i < 40 && !reached; i++) {
          await press(tester, LogicalKeyboardKey.tab);
          final context = FocusManager.instance.primaryFocus?.context;
          if (context == null) continue;
          final label =
              context.findAncestorWidgetOfExactType<Tooltip>()?.message ??
              context
                  .findAncestorWidgetOfExactType<Semantics>()
                  ?.properties
                  .label;
          if (label == 'Admin panel') {
            reached = true;
            expectFocusRing(tester, '$label ($size)');
          }
        }
        expect(reached, isTrue, reason: 'Admin panel ($size)');
      }
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
        if (label != null && !reached.contains(label)) {
          reached.add(label);
          expectFocusRing(tester, label);
        }
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

    /// Presses Tab until what has the focus is what [wanted] picks, and
    /// checks it shows the ring; [what] names it for a failure.
    Future<void> tabTo(
      WidgetTester tester,
      String what,
      bool Function(BuildContext focused) wanted,
    ) async {
      for (var i = 0; i < 60; i++) {
        await press(tester, LogicalKeyboardKey.tab);
        final context = FocusManager.instance.primaryFocus?.context;
        if (context != null && wanted(context)) {
          expectFocusRing(tester, what);
          return;
        }
      }
      fail('Tab never reached $what');
    }

    String? labelOf(BuildContext context) =>
        context.findAncestorWidgetOfExactType<Semantics>()?.properties.label;

    final l10n = lookupAppLocalizations(const Locale('en'));
    for (final (name, open) in [
      (
        'a team',
        (WidgetTester tester) => pumpFromTeamInfo(
          tester,
          scheme: TeamScheme.navy,
          path: '/g/a/scheme',
        ),
      ),
      (
        'my default',
        (WidgetTester tester) async {
          await pumpTeam(tester, scheme: TeamScheme.navy);
          await goTo(tester, '/teams');
          await pushTo(tester, '/teams/scheme');
        },
      ),
    ]) {
      testWidgets('Tab reaches each color scheme row for $name, with the '
          'ring', (tester) async {
        await open(tester);
        // A team's first row is its default (owner's request 2026-11-08).
        if (name == 'a team') {
          await tabTo(
            tester,
            'the default',
            (c) => labelOf(c)?.startsWith('Your default (') ?? false,
          );
        }
        for (final scheme in TeamScheme.values) {
          final title = scheme.label(l10n);
          await tabTo(
            tester,
            title,
            (c) => labelOf(c)?.startsWith('$title, ') ?? false,
          );
        }
      });
    }

    testWidgets('Tab reaches each icon color, with the ring', (tester) async {
      await pumpTeam(tester, scheme: TeamScheme.light);
      await goTo(tester, '/profile');
      await pushTo(tester, '/profile/icon');
      for (final color in AvatarColor.values) {
        final name = candyName(l10n, color);
        await tabTo(tester, name, (c) => labelOf(c) == name);
      }
    });

    testWidgets('Tab reaches the RSVP pills and the event cards, with the '
        'ring', (tester) async {
      await pumpSchedule(tester, scheme: TeamScheme.skyblue);
      for (final answer in ['Going', 'Maybe', 'Not going']) {
        await tabTo(
          tester,
          answer,
          (c) =>
              c.findAncestorWidgetOfExactType<SegmentedButton<RsvpStatus>>() !=
                  null &&
              _textIn(c) == answer,
        );
      }
      await tabTo(
        tester,
        'an event card',
        (c) =>
            c.findAncestorWidgetOfExactType<TapCard>() != null &&
            c.findAncestorWidgetOfExactType<SegmentedButton<RsvpStatus>>() ==
                null,
      );
    });

    testWidgets('a ring left on an RSVP pill or an event card goes away at '
        'the first touch', (tester) async {
      await pumpSchedule(tester, scheme: TeamScheme.skyblue);
      final rings = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.position == DecorationPosition.foreground &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border != null &&
            (w.decoration as BoxDecoration).border!.top.width == 3,
      );
      Future<void> touch() async {
        // A finger down and away again, so nothing is tapped and the
        // focus stays where it was.
        final finger = await tester.startGesture(const Offset(195, 400));
        await finger.cancel();
        await tester.pump();
      }

      await tabTo(
        tester,
        'Going',
        (c) =>
            c.findAncestorWidgetOfExactType<SegmentedButton<RsvpStatus>>() !=
                null &&
            _textIn(c) == 'Going',
      );
      final pill = FocusManager.instance.primaryFocus;
      await touch();
      expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
      expect(FocusManager.instance.primaryFocus, pill);
      expect(rings, findsNothing, reason: 'the pill keeps no ring');

      await tabTo(
        tester,
        'an event card',
        (c) =>
            c.findAncestorWidgetOfExactType<TapCard>() != null &&
            c.findAncestorWidgetOfExactType<SegmentedButton<RsvpStatus>>() ==
                null,
      );
      await touch();
      expect(rings, findsNothing, reason: 'the card keeps no ring');
    });
  });
}

/// Checks that what has the keyboard focus shows the 3 px ring in the text
/// color (SPEC §7.6): as its button's own border (icon and text buttons),
/// or drawn around it (FocusRing, an RSVP pill's face), and nowhere else.
void expectFocusRing(WidgetTester tester, String what) {
  final node = FocusManager.instance.primaryFocus!;
  final context = node.context!;
  final text = GumdropColors.of(context).textOnPage;
  bool ring(BorderSide side) => side.width == 3 && side.color == text;
  final button = context.findAncestorWidgetOfExactType<Material>()?.shape;
  if (button is OutlinedBorder && ring(button.side)) return;
  final rings = find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.position == DecorationPosition.foreground &&
        switch (w.decoration) {
          BoxDecoration(border: Border(:final top)) => ring(top),
          _ => false,
        },
  );
  expect(rings, findsOneWidget, reason: '$what shows one focus ring');
  final drawn = tester.getRect(rings);
  final focused = node.rect;
  expect(
    drawn.contains(focused.center) || focused.contains(drawn.center),
    isTrue,
    reason: '$what: the ring is around it ($drawn, focus $focused)',
  );
}

/// Leo's guardian, a member who isn't an admin.
const _sam = AuthUser(
  uid: 'sam',
  email: 'sam@example.com',
  displayName: 'Sam Rivera',
  emailVerified: true,
);

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
