import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_repository.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/schedule.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart' as scenes;

/// Unlinking takes the link away, as the server does, and says so.
class _Unlinking extends FakePlayerRepository {
  new(super.players);

  final _links = StreamController<List<GuardianLink>>.broadcast();

  @override
  Stream<List<GuardianLink>> watchGuardianLinks(GroupId groupId) async* {
    yield links.where((l) => l.groupId == groupId).toList();
    yield* _links.stream;
  }

  @override
  Future<void> removeGuardian(
    GroupId groupId,
    PlayerId playerId,
    UserId uid,
  ) async {
    await super.removeGuardian(groupId, playerId, uid);
    links.removeWhere((l) => l.playerId == playerId && l.uid == uid);
    _links.add(links.where((l) => l.groupId == groupId).toList());
  }
}

/// Events that never finish loading.
class _SlowEvents extends FakeEventRepository {
  @override
  Stream<EventPage> watchUpcoming(
    GroupId groupId,
    DateTime from, {
    int limit = 50,
  }) => StreamController<EventPage>().stream;
}

/// #37: the player card's upcoming answers in color, as the RSVP history
/// page shows them, and a worded Unlink that says what it means in place
/// of a bare X (PLAYER-2, PLAYER-5).
void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const team = GroupId('a');
  const noah = Player(
    id: PlayerId('noah'),
    groupId: team,
    displayName: 'Noah Lee',
    jerseyNumber: '4',
  );

  /// Noah's card, with me ([role]) and Pam Beesly as his guardians.
  Future<FakePlayerRepository> open(
    WidgetTester tester, {
    MemberRole role = MemberRole.member,
    FakeEventRepository? events,
  }) async {
    final players = _Unlinking([noah])
      ..links.addAll(const [
        GuardianLink(
          playerId: PlayerId('noah'),
          groupId: team,
          uid: UserId('coach'),
        ),
        GuardianLink(
          playerId: PlayerId('noah'),
          groupId: team,
          uid: UserId('pam'),
        ),
      ]);
    final now = DateTime.now();
    final eventRepo =
        events ??
        FakeEventRepository([
          for (final (i, title) in ['Practice', 'vs. Eagles'].indexed)
            Event(
              id: EventId('e$i'),
              groupId: team,
              type: i == 0 ? EventType.practice : EventType.game,
              title: title,
              startAt: DateTime(now.year, now.month, now.day + 2 + i, 16),
              endAt: DateTime(now.year, now.month, now.day + 2 + i, 17),
              timeZone: 'America/Chicago',
              createdBy: 'coach',
            ),
        ]);
    final rsvps = FakeRsvpRepository(eventRepo)
      ..rsvps.add(
        const Rsvp(
          eventId: EventId('e0'),
          groupId: team,
          participantType: ParticipantType.player,
          participantId: 'noah',
          participantName: 'Noah Lee',
          status: RsvpStatus.going,
        ),
      );
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [
        testMembership('a', 'coach', role: role, name: 'Coach Lee'),
        testMembership('a', 'pam', name: 'Pam Beesly'),
      ],
      playerRepo: players,
      eventRepo: eventRepo,
      rsvpRepo: rsvps,
      size: const Size(400, 1400),
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .go('/g/a/team/players/noah');
    await tester.pumpAndSettle();
    return players;
  }

  group('upcoming answers in color (PLAYER-2)', () {
    testWidgets('an answer is its icon and word in its color; no answer is '
        'muted, with no icon', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      final going = tester.widget<Text>(find.text('Going'));
      expect(
        going.style?.color,
        statusColor(tester.element(find.text('Going')), RsvpStatus.going),
      );
      expect(going.style?.fontWeight, FontWeight.w700);
      expect(find.byIcon(statusIcon(RsvpStatus.going)), findsOneWidget);
      final none = tester.widget<Text>(find.text('No answer'));
      expect(none.style?.color, isNot(going.style?.color));
      // One line to screen readers, the answer last.
      expect(
        find.bySemanticsLabel(RegExp(r'^Practice, .+, Going$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^vs\. Eagles, .+, No answer$')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('they load with placeholder rows, not a spinner', (
      tester,
    ) async {
      await open(tester, events: _SlowEvents());
      expect(find.byType(SkeletonList), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('a worded Unlink (PLAYER-5)', () {
    testWidgets("a guardian's own: Stop answering for Noah, said plainly, "
        'and they can claim him again', (tester) async {
      final handle = tester.ensureSemantics();
      final players = await open(tester);
      expect(find.byTooltip('Remove guardian'), findsNothing);
      // Only on my own row, as a member.
      expect(find.widgetWithText(TextButton, 'Unlink'), findsOneWidget);
      expect(find.bySemanticsLabel('Unlink Coach Lee'), findsOneWidget);
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Unlink')).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.widgetWithText(TextButton, 'Unlink'));
      await tester.pumpAndSettle();
      expect(find.text('Stop answering for Noah?'), findsOneWidget);
      expect(
        find.text(
          "You won't answer Noah's RSVPs or see their details any more. "
          "You'll stay on the team, and you can claim Noah again later.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Unlink'));
      await tester.pumpAndSettle();
      expect(players.calls, ['removeGuardian noah coach']);
      expect(find.text("You're no longer linked to Noah."), findsOneWidget);
      // Claiming again works (PLAYER-3, PLAYER-4).
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final claim = find.text('Claim this player');
      await tester.ensureVisible(claim);
      await tester.tap(claim);
      await tester.pumpAndSettle();
      await tester.tap(find.text("I'm their parent or guardian"));
      await tester.pumpAndSettle();
      expect(players.calls.last, 'claim noah guardian');
      handle.dispose();
    });

    testWidgets("an admin's, on someone else: Unlink Pam Beesly from Noah", (
      tester,
    ) async {
      final players = await open(tester, role: MemberRole.admin);
      // Every row, for an admin.
      expect(find.widgetWithText(TextButton, 'Unlink'), findsNWidgets(2));
      final pamRow = find.ancestor(
        of: find.text('Pam Beesly'),
        matching: find.byType(ListTile),
      );
      await tester.tap(
        find.descendant(
          of: pamRow,
          matching: find.widgetWithText(TextButton, 'Unlink'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unlink Pam Beesly from Noah?'), findsOneWidget);
      expect(
        find.text(
          "Pam won't answer Noah's RSVPs or see their details any more. "
          "They'll stay on the team.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Unlink'));
      await tester.pumpAndSettle();
      expect(players.calls, ['removeGuardian noah pam']);
      expect(find.text('Pam is no longer linked to Noah.'), findsOneWidget);
    });
  });

  testWidgets('reads well: answers keep their contrast in all five schemes, '
      'and 200% text', (tester) async {
    for (final scheme in TeamScheme.values) {
      await scenes.pumpTeam(
        tester,
        scheme: scheme,
        size: const Size(390, 1600),
      );
      await scenes.pushTo(tester, '/g/a/team/players/leo');
      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    }
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await scenes.pumpTeam(
      tester,
      scheme: TeamScheme.army,
      size: const Size(320, 2400),
    );
    await scenes.pushTo(tester, '/g/a/team/players/leo');
    expect(tester.takeException(), isNull);
    // Unlink goes under the name, so "Guardian" keeps the row's width...
    final unlink = find.widgetWithText(TextButton, 'Unlink');
    expect(
      tester.getRect(unlink).top,
      greaterThanOrEqualTo(tester.getRect(find.text('Guardian')).bottom - 1),
    );
    // ...and an event's day and time wrap rather than end in "…".
    final rows = tester.renderObjectList<RenderParagraph>(
      find.descendant(
        of: find.byType(PageRow),
        matching: find.byType(RichText),
      ),
    );
    expect(rows, isNotEmpty);
    for (final text in rows) {
      expect(text.didExceedMaxLines, isFalse, reason: text.text.toPlainText());
    }
  });
}
