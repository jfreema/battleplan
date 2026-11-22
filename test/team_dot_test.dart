import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/team_dot.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// #36: a team's dot on Your schedule is its true color, ringed in muted
/// text where it would vanish into the card (under 3:1), in every scheme
/// alike (SPEC §7.4).
void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const navy = 0xFF1E3A5F;
  const yellow = 0xFFD4A017;
  const lightBlue = 0xFF7BAFD4;

  /// Your schedule (See all) with a navy, a yellow, and a light blue team.
  Future<void> open(WidgetTester tester, TeamScheme scheme) async {
    final now = DateTime.now();
    const teams = [
      ('a', 'Navy Knights', navy),
      ('b', 'Yellow Jackets', yellow),
      ('c', 'Sky Sharks', lightBlue),
    ];
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      prefs: FakeLocalPrefs()
        ..defaultSchemeValue = scheme
        ..pushPrePromptShown = true,
      users: FakeUserRepository()..colorScheme = scheme,
      groups: {
        for (final (id, name, color) in teams)
          id: testGroup(id, name).copyWith(color: color),
      },
      memberships: [
        for (final (id, _, _) in teams) testMembership(id, 'coach'),
      ],
      eventRepo: FakeEventRepository([
        for (final (i, (id, _, _)) in teams.indexed)
          Event(
            id: EventId('e$id'),
            groupId: GroupId(id),
            type: EventType.practice,
            title: 'Practice',
            startAt: DateTime(now.year, now.month, now.day + 1 + i, 18),
            endAt: DateTime(now.year, now.month, now.day + 1 + i, 19),
            timeZone: 'America/Chicago',
            createdBy: 'coach',
          ),
      ]),
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/teams');
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    unawaited(router.push('/teams/schedule'));
    await tester.pumpAndSettle();
  }

  /// The dot beside [team]'s name, and whether it has the ring.
  (Color, bool) dot(WidgetTester tester, String team) {
    final row = find.ancestor(of: find.text(team), matching: find.byType(Row));
    final box = tester.widget<Container>(
      find.descendant(
        of: find.descendant(of: row.first, matching: find.byType(TeamDot)),
        matching: find.byType(Container),
      ),
    );
    final d = box.decoration! as BoxDecoration;
    return (d.color!, d.border != null);
  }

  testWidgets('dark colors are ringed on a dark card, never lightened', (
    tester,
  ) async {
    await open(tester, TeamScheme.dark);
    final (navyColor, navyRing) = dot(tester, 'Navy Knights');
    expect(navyColor, const Color(navy));
    expect(navyRing, isTrue);
    expect(dot(tester, 'Yellow Jackets').$2, isFalse);
    // The ring is the card's muted text.
    final c = GumdropColors.of(tester.element(find.byType(TeamDot).first));
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(TeamDot).first,
        matching: find.byType(Container),
      ),
    );
    expect(
      ((box.decoration! as BoxDecoration).border! as Border).top.color,
      c.textMuted,
    );
  });

  testWidgets('one rule in every scheme: a light color on a light card is '
      'ringed too, and a dark one there is not', (tester) async {
    await open(tester, TeamScheme.light);
    expect(dot(tester, 'Sky Sharks').$2, isTrue);
    expect(dot(tester, 'Navy Knights').$2, isFalse);
  });

  testWidgets('every scheme rings exactly the colors under 3:1 on its card', (
    tester,
  ) async {
    for (final scheme in bootCampSchemes) {
      await open(tester, scheme);
      final surface = GumdropColors.of(
        tester.element(find.byType(TeamDot).first),
      ).surface;
      for (final (name, color) in [
        ('Navy Knights', navy),
        ('Yellow Jackets', yellow),
        ('Sky Sharks', lightBlue),
      ]) {
        expect(
          dot(tester, name).$2,
          ColorMath.contrast(Color(color), surface) < 3,
          reason: '$name in ${scheme.value}',
        );
      }
    }
  });

  testWidgets('the dot is decorative: screen readers hear the name', (
    tester,
  ) async {
    await open(tester, TeamScheme.dark);
    for (final element in find.byType(TeamDot).evaluate()) {
      expect(
        find.descendant(
          of: find.byWidget(element.widget),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    }
  });
}
