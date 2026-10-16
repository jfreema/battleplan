// The app shell, design system, and web parity (SPEC §4.2, §5.2, §5.3,
// §5.5, §7.3, §7.5, §7.6, §7.7).
import 'package:battleplan/app/services/share_plus_sharer.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/haptics.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/core/widgets/team_switcher_button.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/presentation/team_switcher.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/schedule_rules.dart';
import 'package:battleplan/features/schedule/presentation/event_details_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Rsvp answer(String eventId, String who, {RsvpStatus s = RsvpStatus.going}) =>
      Rsvp(
        eventId: EventId(eventId),
        groupId: const GroupId('a'),
        participantType: ParticipantType.member,
        participantId: who,
        participantName: who,
        status: s,
      );

  group('team switcher (SPEC §5.2)', () {
    testWidgets('shows the team logo in the header and the list, with '
        'translated sport and muted labels', (tester) async {
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
      final header = tester.widget<TeamBadge>(
        find.descendant(
          of: find.byType(TeamSwitcherButton),
          matching: find.byType(TeamBadge),
        ),
      );
      expect(header.imageUrl, 'https://example.com/groups/a/avatar/logo.jpg');

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

  group('Schedule tab badge (SPEC §5.3)', () {
    test('counts upcoming events in 14 days still waiting for an answer', () {
      final now = DateTime.now();
      final group = testGroup('a', 'Thunder');
      final me = testMembership('a', 'coach');
      const self = Participant(
        type: ParticipantType.member,
        id: 'coach',
        name: 'Coach Lee',
      );
      final events = [
        event('answered', days: 1),
        event('open', days: 2),
        event('later', days: 20),
        event('off', days: 3, rsvpEnabled: false),
        event('canceled', days: 3, canceledAt: now),
        event('past', days: -1),
        event(
          'closed',
          days: 4,
        ).copyWith(rsvpDeadline: now.subtract(const Duration(hours: 1))),
      ];
      int count(Membership m) => countAwaitingRsvp(
        events: events,
        group: group,
        me: m,
        participants: const [self],
        answers: {
          'answered': {'coach': answer('answered', 'coach')},
        },
        now: now,
      );
      expect(count(me), 1);
      // Admins can still answer after the deadline (SCHED-5).
      expect(count(me.copyWith(role: MemberRole.admin)), 2);
    });

    testWidgets('shows on the tab and goes down as I answer', (tester) async {
      final events = FakeEventRepository([
        event('e1', days: 1),
        event('e2', days: 3, title: 'vs. Eagles'),
        event('e3', days: 30, title: 'Far off'),
      ]);
      final rsvps = FakeRsvpRepository(events);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach', name: 'Coach Lee')],
        rsvpRepo: rsvps,
      );
      Finder badge(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.widgetWithText(Badge, label),
      );
      expect(badge('2'), findsOneWidget);
      rsvps.put(answer('e1', 'coach'));
      await tester.pumpAndSettle();
      expect(badge('2'), findsNothing);
      expect(badge('1'), findsOneWidget);
      rsvps.put(answer('e2', 'coach', s: RsvpStatus.notGoing));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(Badge),
        ),
        findsNothing,
      );
    });
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
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations[2].label, isA<Text>());
      expect((rail.destinations[2].label as Text).data, 'Documents');
      expect((rail.destinations[3].label as Text).data, 'Plays');
      await tester.tap(find.text('Plays'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        3,
      );
      expect(
        find.text("No plays yet. Your coaches' plays will show up here."),
        findsOneWidget,
      );
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
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
      expect(find.byType(NavigationRail), findsOneWidget);
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
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(
        tester.getRect(find.byType(Scaffold).last).width,
        lessThanOrEqualTo(720),
      );
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

    testWidgets('Inter is bundled, and its license is listed', (tester) async {
      final manifest = await rootBundle.loadString('FontManifest.json');
      expect(manifest, contains('assets/fonts/inter/Inter-Regular.ttf'));
      registerFontLicenses();
      final entries = await LicenseRegistry.licenses.toList();
      expect(entries.any((e) => e.packages.contains('Inter')), isTrue);
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
        groups: {'a': testGroup('a', 'Thunder')},
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
      expect(find.text('12 going · 3 maybe · 2 no'), findsOneWidget);
      await tester.tap(find.text('Going'));
      await tester.pumpAndSettle();
      expect(rsvps.rsvps.single.status, RsvpStatus.going);
      expect(rsvps.rsvps.single.participantId, 'coach');
    });
  });
}

bool _never(Uri _) => false;
