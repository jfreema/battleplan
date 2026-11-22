import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/groups/presentation/invite_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart' as scenes;

/// #16 (owner's go 2026-11-17): Invite says what to do, with one main
/// button. A title and a line, Share as the one coral button (Copy link
/// where the browser can't share), the QR code that opens full screen,
/// email rows that each say what they do, and the link's settings behind
/// Link settings, which Admin settings opens too (INV-1, INV-2, TEAM-5).
void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const link = 'https://battleplan-dev-ecce4.web.app/join/K7XPM2QR';

  GoRouter router(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Scaffold).first));

  String path(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Scaffold).last)).state.uri.path;

  /// The app on Thunder, as its owner unless [role] says otherwise.
  Future<({FakeInviteRepository invites, FakeSharer sharer})> pump(
    WidgetTester tester, {
    MemberRole role = MemberRole.owner,
    Group? team,
    bool canShare = true,
  }) async {
    final invites = FakeInviteRepository();
    final sharer = FakeSharer()..linksShare = canShare;
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': team ?? testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach', role: role)],
      invites: invites,
      sharer: sharer,
    );
    return (invites: invites, sharer: sharer);
  }

  /// Invite from the Team tab's card (People in a group).
  Future<void> openFromTeamTab(WidgetTester tester, {String tab = 'Team'}) =>
      openTeamTab(tester, label: tab).then((_) async {
        await tester.tap(find.text('Invite'));
        await tester.pumpAndSettle();
      });

  /// Invite as Create opens it: nothing under it, and [InviteAfterCreate].
  Future<void> openAfterCreate(WidgetTester tester) async {
    router(tester).go('/g/a/invite', extra: const InviteAfterCreate());
    await tester.pumpAndSettle();
  }

  /// Scrolls the page's own list until [finder] is built and on screen.
  Future<void> reach(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -200));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  /// Opens Link settings from the Invite screen.
  Future<void> openLinkSettings(WidgetTester tester) async {
    await reach(tester, find.text('Link settings'));
    await tester.tap(find.text('Link settings'));
    await tester.pumpAndSettle();
  }

  /// Copying in tests: what was put on the clipboard.
  List<String> mockClipboard(WidgetTester tester) {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    return copied;
  }

  group('the title and the line (TEAM-1, INV-1)', () {
    testWidgets('right after Create: "Thunder is ready!", what to do, and '
        'Continue as the third button, under Share and Copy link, into the '
        'chat (#69)', (tester) async {
      await pump(tester);
      await openAfterCreate(tester);
      expect(
        find.widgetWithText(PageTitle, 'Thunder is ready!'),
        findsOneWidget,
      );
      expect(
        find.text('Send this link to your families so they can join.'),
        findsOneWidget,
      );
      final go = find.widgetWithText(OutlinedButton, 'Continue to Thunder');
      expect(go, findsOneWidget);
      // Not a second coral button.
      expect(
        find.widgetWithText(FilledButton, 'Continue to Thunder'),
        findsNothing,
      );
      expect(tester.getSize(go).height, greaterThanOrEqualTo(48));
      // Right under Copy link, as wide.
      final copy = find.widgetWithText(OutlinedButton, 'Copy link');
      expect(
        tester.getTopLeft(go).dy,
        greaterThan(tester.getBottomLeft(copy).dy),
      );
      expect(
        tester.getTopLeft(go).dy - tester.getBottomLeft(copy).dy,
        lessThan(24),
      );
      expect(tester.getSize(go).width, tester.getSize(copy).width);
      // No second way at the foot of the page.
      expect(find.text('Continue to Thunder'), findsOneWidget);
      await tester.ensureVisible(go);
      await tester.pumpAndSettle();
      await tester.tap(go);
      await tester.pumpAndSettle();
      expect(path(tester), '/g/a/chat');
    });

    testWidgets('with no link to show, the way into the team stays at the '
        'foot of the page (#69)', (tester) async {
      final fakes = await pump(tester);
      fakes.invites.linkOff = true;
      await openAfterCreate(tester);
      final go = find.widgetWithText(TextButton, 'Continue to Thunder');
      expect(go, findsOneWidget);
      await tester.tap(go);
      await tester.pumpAndSettle();
      expect(path(tester), '/g/a/chat');
    });

    testWidgets('opened from the Team tab: "Invite to Thunder", anyone can '
        'join, and no Continue', (tester) async {
      await pump(tester);
      await openFromTeamTab(tester);
      expect(
        find.widgetWithText(PageTitle, 'Invite to Thunder'),
        findsOneWidget,
      );
      expect(
        find.text('Anyone with this link or code can join.'),
        findsOneWidget,
      );
      expect(find.textContaining('Continue to'), findsNothing);
    });

    testWidgets('a reload has nothing under it either, but it says Invite '
        'to, with Continue', (tester) async {
      await pump(tester);
      router(tester).go('/g/a/invite');
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(PageTitle, 'Invite to Thunder'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Continue to Thunder'),
        findsOneWidget,
      );
    });

    testWidgets('a group says so in group words', (tester) async {
      await pump(
        tester,
        team: testGroup('a', 'Book Club').copyWith(kind: GroupKind.group),
      );
      await openAfterCreate(tester);
      expect(
        find.widgetWithText(PageTitle, 'Book Club is ready!'),
        findsOneWidget,
      );
      expect(
        find.text('Send this link to the people you want in the group.'),
        findsOneWidget,
      );
      await reach(tester, find.text('Add people by email'));
      expect(
        find.text(
          'Put people on the group now. New people get an email to set up '
          'their account.',
        ),
        findsOneWidget,
      );
    });
  });

  group('one main button (INV-1)', () {
    testWidgets('Share is the one coral button, and shares the link', (
      tester,
    ) async {
      final r = await pump(tester);
      await openFromTeamTab(tester);
      final share = find.widgetWithText(FilledButton, 'Share');
      expect(share, findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Copy link'), findsOneWidget);
      expect(tester.getSize(share).height, greaterThanOrEqualTo(48));
      await tester.tap(share);
      await tester.pumpAndSettle();
      expect(r.sharer.shared, ['link $link']);
    });

    testWidgets("where the browser can't share, Copy link is the coral "
        'button and Share is gone', (tester) async {
      await pump(tester, canShare: false);
      await openFromTeamTab(tester);
      expect(find.text('Share'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Copy link'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('Copy link shows no check until tapped, then says Copied '
        'for 2 seconds, and screen readers hear it', (tester) async {
      final copied = mockClipboard(tester);
      await pump(tester);
      await openFromTeamTab(tester);
      final copy = find.widgetWithText(OutlinedButton, 'Copy link');
      expect(
        find.descendant(of: copy, matching: find.byIcon(AppIcons.check)),
        findsNothing,
      );
      await tester.ensureVisible(copy);
      await tester.tap(copy);
      await tester.pump();
      await tester.pump();
      expect(copied, [link]);
      final done = find.widgetWithText(OutlinedButton, 'Copied');
      expect(done, findsOneWidget);
      expect(
        find.descendant(of: done, matching: find.byIcon(AppIcons.check)),
        findsOneWidget,
      );
      expect(
        tester.takeAnnouncements(),
        contains(isAccessibilityAnnouncement('Link copied.')),
      );
      // The button says it: no snackbar.
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(find.widgetWithText(OutlinedButton, 'Copy link'), findsOneWidget);
      expect(find.text('Copied'), findsNothing);
    });

    testWidgets('a share that fails copies instead, and says so', (
      tester,
    ) async {
      final copied = mockClipboard(tester);
      final r = await pump(tester);
      r.sharer.linksFail = true;
      await openFromTeamTab(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Share'));
      await tester.pumpAndSettle();
      expect(copied, [link]);
      expect(find.text('Link copied.'), findsOneWidget);
    });
  });

  testWidgets('the QR code opens full screen; there is no Show QR code '
      'button', (tester) async {
    await pump(tester);
    await openFromTeamTab(tester);
    expect(find.text('Show QR code'), findsNothing);
    // Its tooltip stays out of the semantics: the card says it (below).
    expect(
      find.byWidgetPredicate(
        (w) => w is Tooltip && w.message == 'Show full screen',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(AppIcons.enlarge), findsOneWidget);
    await tester.tap(find.byType(QrImageView));
    await tester.pumpAndSettle();
    // Black on white, filling the screen, with the code.
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.getSize(find.byType(QrImageView)).width, greaterThan(250));
    expect(find.text('K7XP-M2QR'), findsOneWidget);
  });

  group('the email rows (INV-4, TEAM-7)', () {
    testWidgets('each says what it does, and neither is bold', (tester) async {
      await pump(tester);
      await openFromTeamTab(tester);
      await reach(tester, find.text('Add people by email'));
      expect(
        find.text(
          "Email each person their own link. They join when they're ready.",
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Put people on the team now. New people get an email to set up '
          'their account.',
        ),
        findsOneWidget,
      );
      for (final title in ['Email invites', 'Add people by email']) {
        expect(
          tester.widget<Text>(find.text(title)).style?.fontWeight,
          FontWeight.w700,
        );
      }
      // Their pages still go back to "‹ Invite".
      final handle = tester.ensureSemantics();
      await tester.tap(find.text('Email invites'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Back, Invite'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a member who may invite sees the link, Email invites, and '
        'nothing an admin does', (tester) async {
      await pump(tester, role: MemberRole.member);
      await openFromTeamTab(tester);
      expect(find.widgetWithText(FilledButton, 'Share'), findsOneWidget);
      await reach(tester, find.text('Email invites'));
      expect(find.text('Add people by email'), findsNothing);
      expect(find.text('Link settings'), findsNothing);
    });
  });

  group('Link settings (INV-2, TEAM-5)', () {
    testWidgets('an admin opens it from Invite: a heading, the summary, and '
        'three rows', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await openFromTeamTab(tester);
      await reach(tester, find.text('Link settings'));
      expect(find.text('Never expires · Used 0 times'), findsOneWidget);
      await openLinkSettings(tester);
      final heading = find.widgetWithText(CardHeading, 'Link settings');
      expect(heading, findsOneWidget);
      expect(
        tester.getSemantics(find.text('Link settings').last),
        matchesSemantics(isHeader: true, label: 'Link settings'),
      );
      expect(find.text('Never expires · Used 0 times'), findsNWidgets(2));
      for (final line in [
        'How long the link works, and how many people can use it',
        'A new link and QR code. The old ones stop working.',
        'Nobody can join with it until an admin turns on a new one.',
      ]) {
        expect(find.text(line), findsOneWidget);
      }
      handle.dispose();
    });

    testWidgets('Expiry and uses changes the link people have', (tester) async {
      final r = await pump(tester);
      await openFromTeamTab(tester);
      await openLinkSettings(tester);
      await tester.tap(find.text('Expiry and uses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Never'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('After 7 days').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '20');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(r.invites.expiry, InviteExpiry.sevenDays);
      expect(r.invites.maxUses, 20);
      expect(r.invites.resets, 0);
      // The sheet closed first; the row says the new limits.
      expect(find.widgetWithText(CardHeading, 'Link settings'), findsNothing);
      expect(find.text('Never expires · Used 0 of 20 times'), findsOneWidget);
    });

    testWidgets('Reset link makes a new link', (tester) async {
      final r = await pump(tester);
      await openFromTeamTab(tester);
      await openLinkSettings(tester);
      await tester.tap(find.text('Reset link'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reset link'));
      await tester.pumpAndSettle();
      expect(r.invites.resets, 1);
      expect(find.text('NEWC-QDE2'), findsOneWidget);
    });

    testWidgets('Turn off link is in the warning red, and turns it off; a '
        'new one turns on', (tester) async {
      final r = await pump(tester);
      await openFromTeamTab(tester);
      await openLinkSettings(tester);
      final off = find.text('Turn off link');
      final c = GumdropColors.of(tester.element(off));
      expect(tester.widget<Text>(off).style?.color, c.cherry.text);
      await tester.tap(off);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Turn off link'));
      await tester.pumpAndSettle();
      expect(r.invites.linkOff, isTrue);
      expect(
        find.text("The team's invite link is turned off."),
        findsOneWidget,
      );
      // The email rows stay, as neither needs the link.
      await reach(tester, find.text('Add people by email'));
      expect(find.text('Email invites'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Turn on a new link'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Turn on a new link').last,
      );
      await tester.pumpAndSettle();
      expect(r.invites.linkOff, isFalse);
      expect(find.text('NEWC-QDE2'), findsOneWidget);
    });

    testWidgets("Admin settings' Manage invite link opens the same sheet over "
        'it, and turns a new link on while it is off', (tester) async {
      final r = await pump(tester);
      Future<void> manage() async {
        router(tester).go('/g/a/settings');
        await tester.pumpAndSettle();
        final row = find.text('Manage invite link');
        await tester.scrollUntilVisible(
          row,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(row);
        await tester.pumpAndSettle();
      }

      await manage();
      expect(find.widgetWithText(CardHeading, 'Link settings'), findsOneWidget);
      expect(path(tester), '/g/a/settings');
      await tester.tap(find.text('Turn off link'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Turn off link'));
      await tester.pumpAndSettle();
      expect(r.invites.linkOff, isTrue);
      expect(find.text('Invite link turned off.'), findsOneWidget);

      await manage();
      expect(
        find.text("The team's invite link is turned off."),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Turn on a new link'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Turn on a new link').last,
      );
      await tester.pumpAndSettle();
      expect(r.invites.linkOff, isFalse);
      expect(r.invites.resets, 1);
    });
  });

  testWidgets('reads well: a heading, 48 px targets, contrast in all five '
      'schemes, and 200% text', (tester) async {
    for (final scheme in bootCampSchemes) {
      await scenes.pumpTeam(tester, scheme: scheme);
      router(tester).go('/g/a/invite', extra: const InviteAfterCreate());
      await tester.pumpAndSettle();
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.text('Thunder U14 is ready!')),
        matchesSemantics(
          isHeader: true,
          namesRoute: true,
          label: 'Thunder U14 is ready!',
        ),
      );
      // The QR card is one button that says what it does.
      expect(
        tester.getSemantics(find.byType(QrImageView)),
        matchesSemantics(
          isButton: true,
          hasTapAction: true,
          label: "QR code for the team's invite link",
          hint: 'Show full screen',
        ),
      );
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
      router(tester).go('/g/a/invite', extra: const InviteAfterCreate());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await reach(tester, find.text('Link settings'));
      await tester.tap(find.text('Link settings'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    }
  });
}
