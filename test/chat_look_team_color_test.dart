import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// #34 (owner's go 2026-11-20): "Team color" message bubbles follow the
/// team color. Chat look saves the choice itself, not a copy of today's
/// color; a palette color saved before that stays as it was, shown as a
/// swatch of its own (CHAT-18).
void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );

  /// Admin settings for the owner of Thunder (navy) with [theme] as its
  /// chat look.
  Future<FakeGroupRepository> open(
    WidgetTester tester,
    ChatTheme? theme,
  ) async {
    final groups = FakeGroupRepository({
      'a': testGroup(
        'a',
        'Thunder',
      ).copyWith(color: 0xFF1E3A5F, chatTheme: theme),
    });
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groups,
      memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
      size: const Size(400, 5000),
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/g/a/info');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin settings'));
    await tester.pumpAndSettle();
    return groups;
  }

  Future<void> openChatLook(WidgetTester tester) async {
    await tester.tap(find.text('Chat look'));
    await tester.pumpAndSettle();
  }

  bool selected(WidgetTester tester, String label) => tester
      .getSemantics(find.bySemanticsLabel(label))
      .flagsCollection
      .isSelected
      .toBoolOrNull()!;

  testWidgets('picking Team color saves the choice, not the color', (
    tester,
  ) async {
    final groups = await open(tester, null);
    final handle = tester.ensureSemantics();
    await openChatLook(tester);
    expect(selected(tester, 'Team color'), isFalse);
    await tester.tap(find.bySemanticsLabel('Team color'));
    await tester.pumpAndSettle();
    expect(groups.savedTheme?.bubbleColor, chatBubbleTeamColor);
    handle.dispose();
  });

  testWidgets('Team color shows as picked, by name on Admin settings', (
    tester,
  ) async {
    await open(tester, const ChatTheme(bubbleColor: chatBubbleTeamColor));
    expect(find.text('Team color, plain background'), findsOneWidget);
    final handle = tester.ensureSemantics();
    await openChatLook(tester);
    expect(selected(tester, 'Team color'), isTrue);
    // No swatch for an earlier color.
    expect(find.text('Green'), findsNothing);
    handle.dispose();
  });

  testWidgets('a palette color saved before #34 keeps a swatch of its own, '
      'picked, and Team color is not', (tester) async {
    final groups = await open(tester, const ChatTheme(bubbleColor: 0xFF0F8A5F));
    expect(find.text('Green, plain background'), findsOneWidget);
    final handle = tester.ensureSemantics();
    await openChatLook(tester);
    expect(selected(tester, 'Green'), isTrue);
    expect(selected(tester, 'Team color'), isFalse);
    // Choosing Team color moves to following it.
    await tester.tap(find.bySemanticsLabel('Team color'));
    await tester.pumpAndSettle();
    expect(groups.savedTheme?.bubbleColor, chatBubbleTeamColor);
    handle.dispose();
  });
}
