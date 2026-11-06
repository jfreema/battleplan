// The app shell, design system, and web parity (SPEC §4.2, §5.2, §5.3,
// §5.5, §7.3, §7.5, §7.6, §7.7).
import 'package:battleplan/app/services/share_plus_sharer.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/haptics.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/core/widgets/team_switcher_button.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/presentation/shell_parts.dart';
import 'package:battleplan/features/groups/presentation/team_switcher.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/presentation/event_details_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// A team whose logo has a download URL.
class _LogoGroups extends FakeGroupRepository {
  new(super.groups);

  @override
  Future<String?> photoUrl(String path) async => 'https://example.com/$path';
}

/// Deletes fail, as offline.
class _FailingDeletes extends FakeMessageRepository {
  new(super.messages);

  @override
  Future<void> deleteMessage(String messageId) async =>
      throw const Offline('delete');
}

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    displayName: 'Coach Lee',
    emailVerified: true,
  );
  const zone = 'America/Chicago';
  const wide = Size(1200, 900);

  /// An event [days] from now, 90 minutes long.
  Event event(
    String id, {
    required int days,
    String title = 'Practice',
    bool rsvpEnabled = true,
    DateTime? canceledAt,
  }) {
    final start = DateTime.now().add(Duration(days: days, hours: 1));
    return Event(
      id: EventId(id),
      groupId: const GroupId('a'),
      type: EventType.practice,
      title: title,
      startAt: start,
      endAt: start.add(const Duration(minutes: 90)),
      timeZone: zone,
      createdBy: 'coach',
      rsvpEnabled: rsvpEnabled,
      canceledAt: canceledAt,
    );
  }

  group('team switcher (SPEC §5.2)', () {
    testWidgets('shows the eyebrow over the name, no logo in the header, '
        'and logos, translated sports and muted labels in the list', (
      tester,
    ) async {
      final groups = {
        'a': testGroup(
          'a',
          'Thunder',
          lastMessageAt: DateTime(2026, 10),
        ).copyWith(photoPath: 'groups/a/avatar/logo.jpg'),
        'b': testGroup('b', 'Lightning', lastMessageAt: DateTime(2026, 9)),
      };
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groupRepo: _LogoGroups(groups),
        memberships: [
          testMembership('a', 'coach'),
          testMembership(
            'b',
            'coach',
          ).copyWith(notificationLevel: NotificationLevel.none),
        ],
      );
      // The header names the tab over the team, in one row, with no logo.
      expect(
        find.descendant(
          of: find.byType(TeamSwitcherButton),
          matching: find.byType(TeamBadge),
        ),
        findsNothing,
      );
      expect(find.text('TEAM CHAT'), findsOneWidget);
      expect(
        tester.getCenter(find.text('TEAM CHAT')).dy,
        lessThan(tester.getCenter(find.text('Thunder')).dy),
      );

      await tester.tap(find.byType(TeamSwitcherButton));
      await tester.pumpAndSettle();
      final list = find.byType(TeamSwitcherList);
      final badges = tester
          .widgetList<TeamBadge>(
            find.descendant(of: list, matching: find.byType(TeamBadge)),
          )
          .toList();
      expect(badges.first.imageUrl, isNotNull);
      expect(badges.last.imageUrl, isNull);
      expect(find.bySemanticsLabel(RegExp('Soccer')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Muted')), findsOneWidget);
    });

    testWidgets('wide screens get a dropdown panel under the switcher, '
        'for a click and for Ctrl+K', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach')],
        size: wide,
      );
      final button = find.widgetWithText(TeamSwitcherButton, 'Thunder');
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Your teams'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        tester.getTopLeft(find.byType(TeamSwitcherList)).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(button).dy),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Your teams'), findsNothing);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
      expect(find.text('Your teams'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      // A click outside closes it.
      await tester.tapAt(const Offset(1150, 850));
      await tester.pumpAndSettle();
      expect(find.text('Your teams'), findsNothing);
    });
  });

  testWidgets('the Schedule tab shows no count, even with events waiting '
      'for an answer (SPEC §5.3)', (tester) async {
    final events = FakeEventRepository([
      event('e1', days: 1),
      event('e2', days: 3, title: 'vs. Eagles'),
    ]);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach', name: 'Coach Lee')],
      rsvpRepo: FakeRsvpRepository(events),
    );
    expect(
      find.descendant(
        of: find.byType(OpenFieldTabBar),
        matching: find.byType(Badge),
      ),
      findsNothing,
    );
  });

  testWidgets('a long team name steps down and fits a 360 px phone', (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder Parents Association')},
      memberships: [testMembership('a', 'coach')],
      size: const Size(360, 780),
    );
    expect(tester.takeException(), isNull);
    final name = tester.widget<Text>(find.text('Thunder Parents Association'));
    expect(name.style!.fontSize, lessThan(27));
    expect(name.style!.fontSize, greaterThanOrEqualTo(19));
    // One row: the back, the eyebrow over the name, and the three icons.
    final back = tester.getCenter(find.byTooltip('Back'));
    final info = tester.getCenter(find.byTooltip('Team info'));
    expect((back.dy - info.dy).abs(), lessThan(2));
  });

  group('wide screens (SPEC §5.5)', () {
    testWidgets('whiteboard opens below Documents and keeps the rail visible', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach')],
        size: wide,
      );
      final rail = tester.widget<OpenFieldRail>(find.byType(OpenFieldRail));
      expect(rail.tabs[2].label, 'Documents');
      expect(rail.tabs[3].label, 'Plays');
      await tester.tap(find.text('Plays'));
      await tester.pumpAndSettle();
      expect(find.byType(OpenFieldRail), findsOneWidget);
      expect(
        tester.widget<OpenFieldRail>(find.byType(OpenFieldRail)).selectedIndex,
        3,
      );
      expect(
        find.text("No plays yet. Your coaches' plays will show up here."),
        findsOneWidget,
      );
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<OpenFieldRail>(find.byType(OpenFieldRail)).selectedIndex,
        2,
      );
    });

    testWidgets('event details open as a dialog over the tabs, and a tap '
        'outside closes it', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach', name: 'Coach Lee')],
        eventRepo: FakeEventRepository([event('e1', days: 2)]),
        size: wide,
      );
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Practice').first);
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailsScreen), findsOneWidget);
      // The rail is still there under the dialog.
      expect(find.byType(OpenFieldRail), findsOneWidget);
      final panel = tester.getRect(find.byType(Scaffold).last);
      expect(panel.width, lessThanOrEqualTo(720));
      await tester.tapAt(const Offset(1190, 10));
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailsScreen), findsNothing);
    });

    testWidgets('Settings opens as a dialog too', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach')],
        size: wide,
      );
      await openProfile(tester);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(OpenFieldRail), findsOneWidget);
      expect(
        tester.getRect(find.byType(Scaffold).last).width,
        lessThanOrEqualTo(720),
      );
    });
  });

  group('color schemes (SET-2)', () {
    Color page(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(Scaffold).last))
            .scaffoldBackgroundColor;

    testWidgets('Teams shows my default and the picker changes it', (
      tester,
    ) async {
      final users = FakeUserRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach')],
        users: users,
      );
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/teams');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Default color scheme'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // A new account starts on Army green.
      expect(find.text('Army green · new teams start here'), findsOneWidget);
      await tester.tap(find.text('Default color scheme'));
      await tester.pumpAndSettle();
      expect(page(tester), SchemeRoles.army.page);
      // The checked row writes nothing.
      await tester.tap(find.text('Army green'));
      await tester.pumpAndSettle();
      expect(users.colorScheme, isNull);
      await tester.tap(find.text('Navy'));
      await tester.pumpAndSettle();
      expect(users.colorScheme, TeamScheme.navy);
      expect(page(tester), SchemeRoles.navy.page);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Navy, '))),
        isSemantics(isSelected: true, isButton: true, hasTapAction: true),
      );
      // Teams follows the new default.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(page(tester), SchemeRoles.navy.page);
      expect(find.text('Navy · new teams start here'), findsOneWidget);
    });

    testWidgets('Team info → Color scheme saves my pick for the team', (
      tester,
    ) async {
      final members = FakeMemberRepository([testMembership('a', 'coach')]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberRepo: members,
      );
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/g/a/info');
      await tester.pumpAndSettle();
      expect(find.text('Color scheme'), findsOneWidget);
      await tester.tap(find.text('Color scheme'));
      await tester.pumpAndSettle();
      expect(find.textContaining('How Thunder looks for you.'), findsOneWidget);
      await tester.tap(find.text('Army green'));
      await tester.pumpAndSettle();
      expect(members.calls.where((c) => c.startsWith('scheme')), isEmpty);
      await tester.tap(find.text('Light blue'));
      await tester.pumpAndSettle();
      expect(members.calls, contains('scheme a skyblue'));
      // The team's screens re-theme at once.
      expect(page(tester), SchemeRoles.skyblue.page);
    });
  });

  group('web parity (SPEC §4.2)', () {
    testWidgets('pasted or dropped photos send to the chat, with a hint '
        'while dragging', (tester) async {
      final repo = FakeMessageRepository();
      final drops = FakePhotoDrops();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
        messageRepo: repo,
        photoDrops: drops,
      );
      drops.drag(on: true);
      await tester.pump();
      await tester.pump();
      expect(find.text('Drop photos to send them to the team'), findsOneWidget);
      drops
        ..drag(on: false)
        ..drop([
          (bytes: tinyPng, contentType: 'image/png'),
          (bytes: tinyPng, contentType: 'image/png'),
        ]);
      await tester.pumpAndSettle();
      expect(find.text('Drop photos to send them to the team'), findsNothing);
      expect(repo.photoBatches, [2]);

      // Not while another tab is showing.
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();
      drops.drop([(bytes: tinyPng, contentType: 'image/png')]);
      await tester.pumpAndSettle();
      expect(repo.photoBatches, [2]);
    });

    test('links copy where the browser has no Web Share', () async {
      const noWebShare = SharePlusSharer(web: true, canWebShareLink: _never);
      expect(
        await noWebShare.shareLink(Uri.parse('https://example.com')),
        isFalse,
      );
    });

    testWidgets('haptics on sends, long-presses, reactions, and RSVPs', (
      tester,
    ) async {
      final felt = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            felt.add('${call.arguments}'.split('.').last);
          }
          return null;
        },
      );
      Haptics.enabled = true;
      addTearDown(() => Haptics.enabled = !kIsWeb);
      final events = FakeEventRepository([event('e1', days: 2)]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          'a': testGroup('a', 'Thunder').copyWith(kind: GroupKind.group),
        },
        memberships: [testMembership('a', 'coach')],
        messageRepo: FakeMessageRepository([
          Message(
            id: 'm1',
            groupId: const GroupId('a'),
            authorId: 'sam',
            authorName: 'Sam',
            type: MessageType.text,
            text: 'Field 3 is open',
            createdAt: DateTime(2026, 10, 2),
          ),
        ]),
        eventRepo: events,
      );
      await tester.enterText(find.byType(TextField), 'On my way');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(felt, ['lightImpact']);

      await tester.longPress(find.text('Field 3 is open'));
      await tester.pumpAndSettle();
      expect(felt.last, 'mediumImpact');
      await tester.tap(find.text('👍').first);
      await tester.pumpAndSettle();
      expect(felt.last, 'lightImpact');

      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Practice').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Going').first);
      await tester.pumpAndSettle();
      expect(felt.last, 'selectionClick');
    });
  });

  group('keyboard (SPEC §7.6)', () {
    testWidgets('a focused message opens its menu with Enter or the menu '
        'key', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach')],
        messageRepo: FakeMessageRepository([
          Message(
            id: 'm1',
            groupId: const GroupId('a'),
            authorId: 'sam',
            authorName: 'Sam',
            type: MessageType.text,
            text: 'Field 3 is open',
            createdAt: DateTime(2026, 10, 2),
          ),
        ]),
      );
      Future<void> focusMessage() async {
        Focus.of(tester.element(find.text('Field 3 is open'))).requestFocus();
        await tester.pump();
      }

      await focusMessage();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Copy text'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Copy text'), findsNothing);

      await focusMessage();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pumpAndSettle();
      expect(find.text('Copy text'), findsOneWidget);
    });
  });

  group('design tokens (SPEC §7.3)', () {
    testWidgets('motion is 150 to 250 ms with standard easing, and none when '
        'the system reduces motion', (tester) async {
      late Duration normal;
      late Duration reduced;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            normal = Motion.of(context, Motion.slow);
            return MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (inner) {
                  reduced = Motion.of(inner, Motion.slow);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      );
      expect(normal, const Duration(milliseconds: 250));
      expect(reduced, Duration.zero);
      expect(Motion.curve, Easing.standard);
      expect(Motion.fast.inMilliseconds, 150);
    });

    testWidgets("Gumdrop Pop's fonts are bundled, with their licenses", (
      tester,
    ) async {
      final manifest = await rootBundle.loadString('FontManifest.json');
      for (final file in [
        'assets/fonts/lilita_one/LilitaOne-Regular.ttf',
        'assets/fonts/fredoka/Fredoka-SemiBold.ttf',
        'assets/fonts/nunito/Nunito-Bold.ttf',
        'assets/fonts/nunito/Nunito-ExtraBold.ttf',
      ]) {
        expect(manifest, contains(file));
      }
      // Inter is gone.
      expect(manifest, isNot(contains('Inter')));
      registerFontLicenses();
      final entries = await LicenseRegistry.licenses.toList();
      for (final family in [AppFonts.display, AppFonts.label, AppFonts.body]) {
        expect(
          entries.where((e) => e.packages.contains(family)),
          hasLength(1),
          reason: family,
        );
      }
    });

    test('every eyebrow is in the letters Black Ops One is cut to', () {
      // tools/cut_fonts.sh keeps A–Z, the space and "·"; any other letter
      // would draw in another font.
      final l10n = lookupAppLocalizations(const Locale('en'));
      for (final group in [false, true]) {
        for (var tab = 0; tab < 4; tab++) {
          for (var month = 1; month <= 12; month++) {
            final label = HeaderEyebrow.labelFor(
              l10n,
              tab,
              DateTime(2026, month),
              group: group,
            );
            expect(
              label.toUpperCase(),
              matches(RegExp(r'^[A-Z ·]+$')),
              reason: label,
            );
          }
        }
      }
    });
  });

  group('writing (SPEC §7.5, §7.7)', () {
    testWidgets('deleting a message says "Delete message", and a failure '
        'says what failed', (tester) async {
      final repo = _FailingDeletes([
        Message(
          id: 'm1',
          groupId: const GroupId('a'),
          authorId: 'coach',
          authorName: 'Coach Lee',
          type: MessageType.text,
          text: 'Wrong field',
          createdAt: DateTime(2026, 10, 2),
        ),
      ]);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach')],
        messageRepo: repo,
      );
      await tester.longPress(find.text('Wrong field'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete message'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "Couldn't delete the message. Check your connection and try again.",
        ),
        findsOneWidget,
      );
    });
  });

  group('chat event cards (SPEC §5.4, §7.5)', () {
    testWidgets('answer from the card, which shows the counts', (tester) async {
      final events = FakeEventRepository([
        event('e1', days: 2).copyWith(
          rsvpCounts: const RsvpCounts(going: 12, maybe: 3, notGoing: 2),
        ),
      ]);
      final rsvps = FakeRsvpRepository(events);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        // A basic group, where each member answers for themselves (TEAM-14).
        groups: {
          'a': testGroup('a', 'Thunder').copyWith(kind: GroupKind.group),
        },
        memberships: [testMembership('a', 'coach', name: 'Coach Lee')],
        messageRepo: FakeMessageRepository([
          Message(
            id: 'm1',
            groupId: const GroupId('a'),
            authorId: 'coach',
            authorName: 'Coach Lee',
            type: MessageType.event,
            text: 'Practice',
            eventId: 'e1',
            createdAt: DateTime(2026, 10, 2),
          ),
        ]),
        rsvpRepo: rsvps,
      );
      expect(
        find.textContaining(RegExp(r'^12/\d+ going'), findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.text('Going'));
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.status, RsvpStatus.going);
      expect(rsvps.rsvps.single.participantId, 'coach');
    });
  });
}

bool _never(Uri _) => false;
