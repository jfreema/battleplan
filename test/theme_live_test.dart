// A theme editor change reaches what's already on screen (#83, owner's
// report 2026-11-21: "changing the bubbles/my text color doesn't change
// existing messages and polls that are in the chat"): my messages and my
// polls already in the chat take a theme's new "you" color at once, and
// others' polls its new card color. A team whose Chat look picks its own
// bubble color (CHAT-18), as every sample team in dev does, keeps that
// color for its messages: the team's pick wins over the theme.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/scenes.dart';

void main() {
  const tall = Size(390, 2400);
  const blue = Color(0xFF79BBFF);

  /// The fill of the bubble or card [text] is in.
  Color? fillOf(WidgetTester tester, Finder text) {
    for (final box in tester.widgetList<DecoratedBox>(
      find.ancestor(of: text, matching: find.byType(DecoratedBox)),
    )) {
      final color = switch (box.decoration) {
        BoxDecoration(:final color) => color,
        ShapeDecoration(:final color) => color,
        _ => null,
      };
      if (color != null && color.a > 0) return color;
    }
    return null;
  }

  /// Saves [config] as the server would, live.
  Future<void> saveConfig(WidgetTester tester, AppConfig config) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    (container.read(adminRepositoryProvider) as FakeAdminRepository).config =
        config;
    await tester.pumpAndSettle();
  }

  final mine = find.text('See everyone Monday!');
  // My poll's question, in its bubble (its quote in Alex's reply comes
  // first).
  final myPoll = find.text('Team dinner after the game?').last;

  testWidgets('my messages and polls already in the chat take a new "you" '
      'color at once', (tester) async {
    await pumpTeam(tester, scheme: TeamScheme.army, size: tall);
    expect(fillOf(tester, mine), CandyFaces.coral);
    expect(fillOf(tester, myPoll), CandyFaces.coral);
    await saveConfig(
      tester,
      const AppConfig(
        themes: {TeamScheme.army: ThemeOverride(accent: 0xFF79BBFF)},
      ),
    );
    expect(fillOf(tester, mine), blue);
    expect(fillOf(tester, myPoll), blue);
    // And back, when it's put back as it ships.
    await saveConfig(tester, const AppConfig());
    expect(fillOf(tester, mine), CandyFaces.coral);
  });

  testWidgets('cards already in the chat take a new card color', (
    tester,
  ) async {
    await pumpTeam(tester, scheme: TeamScheme.army, size: tall);
    // The event's card, drawn in the card color where it sits.
    Color card() =>
        GumdropColors.of(tester.element(find.text('vs. Eagles'))).surface;
    expect(card(), SchemeRoles.army.card);
    await saveConfig(
      tester,
      const AppConfig(
        themes: {TeamScheme.army: ThemeOverride(card: 0xFF3B3F22)},
      ),
    );
    expect(card(), const Color(0xFF3B3F22));
  });

  testWidgets("a team's own Chat look bubble color stays its messages' color", (
    tester,
  ) async {
    await pumpTeam(
      tester,
      scheme: TeamScheme.army,
      size: tall,
      team: sceneTeam.copyWith(
        chatTheme: const ChatTheme(bubbleColor: 0xFFC2410C),
      ),
    );
    expect(fillOf(tester, mine), const Color(0xFFC2410C));
    await saveConfig(
      tester,
      const AppConfig(
        themes: {TeamScheme.army: ThemeOverride(accent: 0xFF79BBFF)},
      ),
    );
    expect(fillOf(tester, mine), const Color(0xFFC2410C));
    expect(fillOf(tester, myPoll), const Color(0xFFC2410C));
  });
}
