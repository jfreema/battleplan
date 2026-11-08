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
}
