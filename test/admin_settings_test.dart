import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/theme_override.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart' as scenes;

/// #32 (owner's go 2026-11-17): a shorter Admin settings. The name and
/// description save together with one Save, leaving with them unsaved asks
/// first, and the three colors sit together under Look, with Chat look and
/// the team color scheme on pages of their own (TEAM-5, CHAT-18, SET-2).
void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );

  GoRouter router(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Scaffold).first));

  String path(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Scaffold).last)).state.uri.path;

  /// Admin settings, opened from Team settings as admins do, for the owner
  /// of Thunder (or [group]); [admin] makes them an admin who isn't.
  Future<FakeGroupRepository> open(
    WidgetTester tester, {
    Group? group,
    bool admin = false,
  }) async {
    final groups = FakeGroupRepository({
      'a': group ?? testGroup('a', 'Thunder').copyWith(description: 'U14'),
    });
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groupRepo: groups,
      memberships: [
        testMembership(
          'a',
          'coach',
          role: admin ? MemberRole.admin : MemberRole.owner,
        ),
      ],
      size: const Size(400, 5000),
    );
    router(tester).go('/g/a/info');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin settings'));
    await tester.pumpAndSettle();
    return groups;
  }

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(LabeledField, label),
    matching: find.byType(TextField),
  );

  FilledButton save(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));

  /// Types into a field, and lets Save catch up.
  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.enterText(field(label), text);
    await tester.pump();
  }

  group('one Save for the name and description', () {
    testWidgets('Save is off until either changes, saves both, and turns off '
        'again', (tester) async {
      final groups = await open(tester);
      expect(save(tester).onPressed, isNull);
      await type(tester, 'DESCRIPTION (OPTIONAL)', 'U14 travel');
      expect(save(tester).onPressed, isNotNull);
      // Back to what's saved: nothing to save.
      await type(tester, 'DESCRIPTION (OPTIONAL)', 'U14');
      expect(save(tester).onPressed, isNull);
      await type(tester, 'TEAM NAME', 'Storm');
      await type(tester, 'DESCRIPTION (OPTIONAL)', 'U14 travel');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(groups.updates, ['name Storm description U14 travel']);
      expect(find.text('Profile saved.'), findsOneWidget);
      expect(save(tester).onPressed, isNull);
    });

    testWidgets('an empty name keeps Save off', (tester) async {
      await open(tester);
      await type(tester, 'TEAM NAME', '  ');
      expect(save(tester).onPressed, isNull);
    });

    testWidgets('Enter in the name does what Save does', (tester) async {
      final groups = await open(tester);
      await type(tester, 'DESCRIPTION (OPTIONAL)', 'Spring');
      await type(tester, 'TEAM NAME', 'Storm');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(groups.updates, ['name Storm description Spring']);
    });

    testWidgets('another admin renaming the team moves the fields along, '
        "unless I've typed", (tester) async {
      final groups = await open(tester);
      groups.setGroup(
        groups.groups['a']!.copyWith(name: 'Thunder Blue', description: ''),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field('TEAM NAME')).controller!.text,
        'Thunder Blue',
      );
      expect(save(tester).onPressed, isNull);
      await type(tester, 'TEAM NAME', 'Storm');
      groups.setGroup(groups.groups['a']!.copyWith(name: 'Lightning'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field('TEAM NAME')).controller!.text,
        'Storm',
      );
      expect(save(tester).onPressed, isNotNull);
    });
  });

  group('leaving with changes unsaved asks first', () {
    Finder dialog() => find.text('Save your changes?');

    testWidgets('with nothing changed, Back leaves at once', (tester) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel(RegExp('^Back')).last);
      await tester.pumpAndSettle();
      expect(dialog(), findsNothing);
      expect(path(tester), '/g/a/info');
    });

    testWidgets('Discard leaves without saving', (tester) async {
      final groups = await open(tester);
      await type(tester, 'DESCRIPTION (OPTIONAL)', 'U14 travel');
      await tester.tap(find.bySemanticsLabel(RegExp('^Back')).last);
      await tester.pumpAndSettle();
      expect(dialog(), findsOneWidget);
      expect(
        find.text(
          "Your changes to the team's name and description aren't saved yet.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Discard'));
      await tester.pumpAndSettle();
      expect(path(tester), '/g/a/info');
      expect(groups.updates, isEmpty);
    });

    testWidgets('Save saves, then leaves', (tester) async {
      final groups = await open(tester);
      await type(tester, 'DESCRIPTION (OPTIONAL)', 'U14 travel');
      await tester.tap(find.bySemanticsLabel(RegExp('^Back')).last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Save'),
        ),
      );
      await tester.pumpAndSettle();
      expect(groups.updates, ['name Thunder description U14 travel']);
      expect(path(tester), '/g/a/info');
    });

    testWidgets('closing the dialog stays, with the text as typed', (
      tester,
    ) async {
      await open(tester);
      await type(tester, 'DESCRIPTION (OPTIONAL)', 'U14 travel');
      await tester.tap(find.bySemanticsLabel(RegExp('^Back')).last);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(dialog(), findsNothing);
      expect(path(tester), '/g/a/settings');
      expect(
        tester
            .widget<TextField>(field('DESCRIPTION (OPTIONAL)'))
            .controller!
            .text,
        'U14 travel',
      );
    });

    testWidgets("Android's Back asks too", (tester) async {
      await open(tester);
      await type(tester, 'DESCRIPTION (OPTIONAL)', 'U14 travel');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(dialog(), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Discard'));
      await tester.pumpAndSettle();
      expect(path(tester), '/g/a/info');
    });

    testWidgets('a go elsewhere asks too, as the rail or the header would', (
      tester,
    ) async {
      await open(tester);
      await type(tester, 'TEAM NAME', 'Storm');
      router(tester).go('/g/a/chat');
      await tester.pumpAndSettle();
      expect(dialog(), findsOneWidget);
      // Staying keeps the page.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(path(tester), '/g/a/settings');
      router(tester).go('/g/a/chat');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Discard'));
      await tester.pumpAndSettle();
      expect(path(tester), '/g/a/chat');
    });

    testWidgets("a group's question says group", (tester) async {
      await open(
        tester,
        group: testGroup('a', 'Book club').copyWith(kind: GroupKind.group),
      );
      await type(tester, 'DESCRIPTION (OPTIONAL)', 'Monthly');
      await tester.tap(find.bySemanticsLabel(RegExp('^Back')).last);
      await tester.pumpAndSettle();
      expect(
        find.text(
          "Your changes to the group's name and description aren't saved yet.",
        ),
        findsOneWidget,
      );
    });
  });

  group('Look (TEAM-5, CHAT-18, SET-2)', () {
    testWidgets('the sections, in order: the team, its basics, Look, then '
        'the rest, and About last', (tester) async {
      await open(tester);
      double top(String text) => tester.getTopLeft(find.text(text).first).dy;
      final order = [
        'TEAM NAME',
        'Time zone',
        'Manage invite link',
        'Look',
        'TEAM COLOR',
        'Chat look',
        'Team color scheme',
        'Member permissions',
        'Language',
        'Default event reminders',
        'Notifications for new members',
        'Storage',
        'Owner actions',
        'About',
      ];
      for (final (i, text) in order.indexed.skip(1)) {
        expect(
          top(text),
          greaterThan(top(order[i - 1])),
          reason: '$text after ${order[i - 1]}',
        );
      }
      // Look is a heading.
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.text('Look')),
        matchesSemantics(isHeader: true, label: 'Look'),
      );
      handle.dispose();
    });

    testWidgets('Chat look opens its page, going back to Admin settings, '
        'and a pick there saves', (tester) async {
      final groups = await open(tester);
      expect(find.text('Cherry, plain background'), findsOneWidget);
      final handle = tester.ensureSemantics();
      await tester.tap(find.text('Chat look'));
      await tester.pumpAndSettle();
      expect(path(tester), '/g/a/settings/chat-look');
      expect(find.widgetWithText(PageTitle, 'Chat look'), findsOneWidget);
      expect(find.bySemanticsLabel('Back, Admin settings'), findsOneWidget);
      await tester.tap(find.text('Sprinkles'));
      await tester.pumpAndSettle();
      expect(groups.savedTheme?.background, ChatBackground.pattern);
      handle.dispose();
    });

    testWidgets('Team color scheme opens its page, and its row says the '
        'default, or System default when none is set', (tester) async {
      final groups = await open(tester);
      expect(
        find.descendant(
          of: find.widgetWithText(SettingsRow, 'Team color scheme'),
          matching: find.text('System default'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Team color scheme'));
      await tester.pumpAndSettle();
      expect(path(tester), '/g/a/settings/color-scheme');
      await tester.tap(find.text('Navy'));
      await tester.pumpAndSettle();
      expect(groups.updates, contains('colorScheme navy'));
      Navigator.of(tester.element(find.text('Navy'))).pop();
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(SettingsRow, 'Team color scheme'),
          matching: find.text('Navy'),
        ),
        findsOneWidget,
      );
    });

    testWidgets("a group's Look says Color and Group color scheme", (
      tester,
    ) async {
      await open(
        tester,
        group: testGroup('a', 'Book club').copyWith(kind: GroupKind.group),
      );
      expect(find.text('COLOR'), findsOneWidget);
      expect(find.text('Group color scheme'), findsOneWidget);
      expect(find.text('Team color scheme'), findsNothing);
      await tester.tap(find.text('Group color scheme'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(PageTitle, 'Group color scheme'),
        findsOneWidget,
      );
    });

    testWidgets('an admin who is not the owner has no Owner actions', (
      tester,
    ) async {
      await open(tester, admin: true);
      expect(find.text('Owner actions'), findsNothing);
      expect(find.text('About'), findsOneWidget);
    });
  });

  testWidgets('reads well: 48 px targets, contrast in all five schemes, and '
      '200% text', (tester) async {
    for (final scheme in builtInSchemes) {
      await scenes.pumpTeam(
        tester,
        scheme: scheme,
        size: const Size(390, 3600),
      );
      await scenes.goTo(tester, '/g/a/info');
      await scenes.pushTo(tester, '/g/a/settings');
      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }
    for (final width in [320.0, 360.0]) {
      await scenes.pumpTeam(
        tester,
        scheme: TeamScheme.army,
        size: Size(width, 700),
      );
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await scenes.goTo(tester, '/g/a/info');
      await scenes.pushTo(tester, '/g/a/settings');
      expect(tester.takeException(), isNull);
      await scenes.pushTo(tester, '/g/a/settings/chat-look');
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    }
  });
}
