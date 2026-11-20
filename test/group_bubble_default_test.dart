// A group's chat bubbles default to light blue (Blue raspberry), a team's to
// the theme's coral (owner's request 2026-11-08, CHAT-18).
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/groups/domain/chat_colors.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  test('a group with nothing picked has light blue bubbles', () {
    final g = testGroup('a', 'Run club').copyWith(kind: GroupKind.group);
    expect(g.bubbleColorOrDefault, ChatCandy.blueRaspberry.stored);
  });

  test('a team with nothing picked keeps the theme color (null)', () {
    expect(testGroup('a', 'Thunder').bubbleColorOrDefault, isNull);
  });

  test("an admin's pick wins in a group", () {
    final g = testGroup('a', 'Run club').copyWith(
      kind: GroupKind.group,
      chatTheme: ChatTheme(bubbleColor: ChatCandy.mint.stored),
    );
    expect(g.bubbleColorOrDefault, ChatCandy.mint.stored);
  });

  // "Team color" follows the team's color (#34).
  group('Team color', () {
    const team = ChatTheme(bubbleColor: chatBubbleTeamColor);

    test('draws the team color as it is now', () {
      final g = testGroup(
        'a',
        'Thunder',
      ).copyWith(color: 0xFF1E3A5F, chatTheme: team);
      expect(g.bubbleColorOrDefault, chatBubbleTeamColor);
      expect(g.bubbleColorToDraw, 0xFF1E3A5F);
      expect(g.copyWith(color: 0xFFB91C1C).bubbleColorToDraw, 0xFFB91C1C);
    });

    test("is the theme's color (null) on a team with no color", () {
      final g = testGroup(
        'a',
        'Thunder',
      ).copyWith(color: null, chatTheme: team);
      expect(g.bubbleColorToDraw, isNull);
    });

    test('leaves a candy and a color saved before #34 as they are', () {
      final g = testGroup('a', 'Thunder').copyWith(color: 0xFF1E3A5F);
      expect(
        g
            .copyWith(chatTheme: ChatTheme(bubbleColor: ChatCandy.mint.stored))
            .bubbleColorToDraw,
        ChatCandy.mint.stored,
      );
      expect(
        g
            .copyWith(chatTheme: const ChatTheme(bubbleColor: 0xFF0F8A5F))
            .bubbleColorToDraw,
        0xFF0F8A5F,
      );
    });
  });
}
