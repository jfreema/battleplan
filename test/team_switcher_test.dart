import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/team_switcher_button.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/presentation/team_switcher.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// Plays that never finish loading.
class _SlowPlays extends FakePlayRepository {
  @override
  Stream<List<Play>> watchPlays(GroupId groupId) =>
      StreamController<List<Play>>().stream;
}

/// Team photos that never finish loading.
class _SlowPhotos extends FakeMessageRepository {
  new() : super(const []);

  @override
  Future<MessagePage> photoMessages(
    GroupId groupId, {
    PageCursor? before,
    int limit = 30,
  }) => Completer<MessagePage>().future;
}

/// #25: the team switcher in the app's own rows: a coral check for the
/// team I'm on and its name in the text color, never the groups' blue, the
/// coral count Teams shows, archived teams under a row that opens them;
/// and Saved plays and Team photos load with placeholders, not a spinner
/// (SPEC §5.2, §7.5).
void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  final read = DateTime(2030, 10);
  final last = DateTime(2030, 10, 8, 9);
  Message msg(String g, int i) => Message(
    id: '$g$i',
    groupId: GroupId(g),
    authorId: 'sam',
    authorName: 'Sam Rivera',
    type: MessageType.text,
    text: 'Hi $i',
    createdAt: DateTime(2030, 10, 2, 9, i),
  );

  GoRouter router(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Scaffold).first));

  /// Thunder (I'm on it, 3 unread), Lightning (12 unread), Book club
  /// (muted, 2 unread), and Hornets, archived; opened on Thunder's chat.
  Future<void> pump(
    WidgetTester tester, {
    TeamScheme scheme = TeamScheme.army,
    Size size = const Size(400, 900),
    FakePlayRepository? plays,
    FakeMessageRepository? messages,
  }) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      prefs: FakeLocalPrefs()
        ..defaultSchemeValue = scheme
        ..pushPrePromptShown = true,
      users: FakeUserRepository()..colorScheme = scheme,
      groups: {
        'a': testGroup('a', 'Thunder', lastMessageAt: last),
        'b': testGroup('b', 'Lightning', lastMessageAt: last),
        'c': testGroup(
          'c',
          'Book club',
          lastMessageAt: last,
        ).copyWith(kind: GroupKind.group),
        'e': testGroup(
          'e',
          'Hornets',
          lastMessageAt: DateTime(2025),
        ).copyWith(archivedAt: DateTime(2026)),
      },
      memberships: [
        testMembership(
          'a',
          'coach',
          role: MemberRole.owner,
        ).copyWith(lastReadAt: read, colorScheme: scheme),
        testMembership('b', 'coach').copyWith(lastReadAt: read),
        testMembership(
          'c',
          'coach',
        ).copyWith(lastReadAt: read, notificationLevel: NotificationLevel.none),
        testMembership('e', 'coach').copyWith(lastReadAt: last),
      ],
      messageRepo:
          messages ??
          FakeMessageRepository([
            for (var i = 0; i < 3; i++) msg('a', i),
            for (var i = 0; i < 12; i++) msg('b', i),
            for (var i = 0; i < 2; i++) msg('c', i),
          ]),
      playRepo: plays,
      size: size,
    );
    router(tester).go('/g/a/chat');
    await tester.pumpAndSettle();
  }

  Future<void> openSwitcher(WidgetTester tester) async {
    await tester.tap(find.byType(TeamSwitcherButton));
    await tester.pumpAndSettle();
  }

  Finder inList(Finder f) =>
      find.descendant(of: find.byType(TeamSwitcherList), matching: f);

  testWidgets("the team I'm on: a coral check, its name in the text color, "
      'and "current team" to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await openSwitcher(tester);
    final c = GumdropColors.of(tester.element(inList(find.text('Thunder'))));
    final check = tester.widget<Icon>(inList(find.byIcon(AppIcons.check)));
    expect(check.color, c.you.face);
    // Never the groups' blue, the theme's primary.
    final name = tester.widget<Text>(inList(find.text('Thunder')));
    expect(name.style?.color, c.textPrimary);
    expect(name.style?.fontWeight, FontWeight.w800);
    expect(
      tester.widget<Text>(inList(find.text('Lightning'))).style?.fontWeight,
      FontWeight.w600,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Thunder, \w+, current team, 3 unread messages$'),
      ),
      findsOneWidget,
    );
    // Only the team I'm on is checked.
    expect(inList(find.byIcon(AppIcons.check)), findsOneWidget);
    handle.dispose();
  });

  testWidgets("unread is Teams' coral count; a muted team's is gray", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await openSwitcher(tester);
    final c = GumdropColors.of(tester.element(inList(find.text('Lightning'))));
    BoxDecoration pill(String count) =>
        tester
                .widget<Container>(
                  find
                      .ancestor(
                        of: inList(find.text(count)),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;
    expect(pill('12').color, c.you.face);
    expect(pill('2').color, isNull);
    expect(pill('2').border, isNotNull);
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Book club, Group, Muted, 2 unread messages$'),
      ),
      findsOneWidget,
    );
    // No Material badge, the red one.
    expect(inList(find.byType(Badge)), findsNothing);
    handle.dispose();
  });

  testWidgets('archived teams wait under Archived, closed, and open on a '
      'tap', (tester) async {
    await pump(tester);
    await openSwitcher(tester);
    expect(inList(find.text('Hornets')), findsNothing);
    await tester.tap(inList(find.text('Archived')));
    await tester.pumpAndSettle();
    expect(inList(find.text('Hornets')), findsOneWidget);
    await tester.tap(inList(find.text('Archived')));
    await tester.pumpAndSettle();
    expect(inList(find.text('Hornets')), findsNothing);
  });

  testWidgets('a row opens that team; Join and Create still open theirs', (
    tester,
  ) async {
    await pump(tester);
    await openSwitcher(tester);
    await tester.tap(inList(find.text('Lightning')));
    await tester.pumpAndSettle();
    expect(router(tester).state.uri.path, startsWith('/g/b/'));
    await openSwitcher(tester);
    await tester.tap(inList(find.text('Join a Team or Group')));
    await tester.pumpAndSettle();
    expect(find.byType(TeamSwitcherList), findsNothing);
    expect(
      GoRouter.of(tester.element(find.byType(Scaffold).last)).state.uri.path,
      '/join',
    );
  });

  testWidgets('Saved plays and Team photos load with placeholders, not a '
      'spinner', (tester) async {
    await pump(tester, plays: _SlowPlays());
    router(tester).go('/g/a/plays/saved');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SkeletonGrid), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await pump(tester, messages: _SlowPhotos());
    router(tester).go('/g/a/documents');
    await tester.pumpAndSettle();
    unawaited(router(tester).push('/g/a/documents/photos'));
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonGrid), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('reads well: a heading, 48 px targets, contrast in all five '
      'schemes, and 200% text', (tester) async {
    for (final scheme in bootCampSchemes) {
      await pump(tester, scheme: scheme);
      await openSwitcher(tester);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(inList(find.text('Your teams'))),
        matchesSemantics(isHeader: true, label: 'Your teams'),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }
    for (final width in [320.0, 360.0]) {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await pump(tester, size: Size(width, 700));
      await openSwitcher(tester);
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    }
  });
}
