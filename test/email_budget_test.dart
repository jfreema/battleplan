// The one daily email budget in the app (#47, SPEC ADMIN-1, ADMIN-7,
// INV-4, TEAM-7): email invites send what fits and keep the rest for
// tomorrow, a resend past the limit says so, Add people by email names the
// setup emails the day had no room for, the Dashboard counts today's
// emails, and Platform settings sets the budget.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/candy_box.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const boss = AuthUser(
    uid: 'boss',
    email: 'boss@example.com',
    displayName: 'Bea Boss',
    emailVerified: true,
    isSuperAdmin: true,
  );

  Future<void> go(WidgetTester tester, String path, {bool push = false}) async {
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    if (push) {
      unawaited(router.push(path));
    } else {
      router.go(path);
    }
    await tester.pumpAndSettle();
  }

  Future<void> openTeam(
    WidgetTester tester, {
    FakeInviteRepository? invites,
    FakeMemberRepository? members,
  }) => pumpApp(
    tester,
    auth: FakeAuthRepository(user: coach),
    groups: {'a': testGroup('a', 'Thunder')},
    memberships: members == null
        ? [testMembership('a', 'coach', role: MemberRole.owner)]
        : const [],
    memberRepo: members,
    invites: invites,
  );

  group('email invites (INV-4)', () {
    Future<void> send(WidgetTester tester, String emails) async {
      await tester.enterText(find.byType(TextField).first, emails);
      await tester.pump();
      await tester.tap(find.textContaining(RegExp(r'^Send \d+ invites?$')));
      await tester.pumpAndSettle();
    }

    testWidgets('send what fits and keep the rest in the box for tomorrow', (
      tester,
    ) async {
      final invites = FakeInviteRepository()..emailRoom = 1;
      await openTeam(tester, invites: invites);
      await go(tester, '/g/a/invite/email', push: true);
      await send(tester, 'a@example.com b@example.com c@example.com');
      expect(
        find.text(
          "Sent 1. Today's email limit is reached, so the other 2 weren't "
          'sent. Try again tomorrow.',
        ),
        findsOneWidget,
      );
      expect(invites.sent.map((i) => i.email), ['a@example.com']);
      // The two left over wait in the box.
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'b@example.com\nc@example.com',
      );
    });

    testWidgets('with no room at all, nothing is sent', (tester) async {
      final invites = FakeInviteRepository()..emailRoom = 0;
      await openTeam(tester, invites: invites);
      await go(tester, '/g/a/invite/email', push: true);
      await send(tester, 'a@example.com');
      expect(
        find.text("Today's email limit is reached. Try again tomorrow."),
        findsOneWidget,
      );
      expect(invites.sent, isEmpty);
    });

    testWidgets('a resend past the limit says so', (tester) async {
      final invites = FakeInviteRepository()
        ..sent.add(
          const EmailInvite(
            code: 'EMAIL001',
            email: 'a@example.com',
            status: EmailInviteStatus.pending,
          ),
        )
        ..resendFails = const RateLimited('email-limit');
      await openTeam(tester, invites: invites);
      await go(tester, '/g/a/invite/email', push: true);
      await tester.ensureVisible(find.text('Resend'));
      await tester.tap(find.text('Resend'));
      await tester.pumpAndSettle();
      expect(
        find.text("Today's email limit is reached. Try again tomorrow."),
        findsOneWidget,
      );
    });
  });

  testWidgets('Add people by email names the setup emails the day had no '
      'room for (TEAM-7)', (tester) async {
    final members =
        FakeMemberRepository([
            testMembership('a', 'coach', role: MemberRole.owner),
          ])
          ..emailFails.addAll(['lee@example.com', 'bo@example.com'])
          ..emailLimitReached = true;
    await openTeam(tester, members: members);
    await go(tester, '/g/a/members/add', push: true);
    await tester.enterText(
      find.byType(TextField),
      'Nia Park, nia@example.com\nLee Chen, lee@example.com\n'
      'Bo Diaz, bo@example.com',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Add 3 people'));
    await tester.pumpAndSettle();
    expect(
      find.text("Added, but the setup email didn't send (2)"),
      findsOneWidget,
    );
    expect(
      find.text(
        "2 setup emails couldn't be sent today because of the daily email "
        'limit. Use Resend setup email on each tomorrow.',
      ),
      findsOneWidget,
    );
  });

  group('the Super Admin Panel', () {
    Future<FakeAdminRepository> openAdmin(
      WidgetTester tester,
      String path, {
      AdminTotals totals = const AdminTotals(),
      AppConfig config = const AppConfig(supportEmail: 'help@example.com'),
    }) async {
      final admin = FakeAdminRepository(totalsValue: totals)..config = config;
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: boss),
        admin: admin,
        size: const Size(390, 1600),
      );
      await go(tester, path);
      return admin;
    }

    AdminTotals emails(int sent) =>
        AdminTotals(emailsToday: sent, emailBudget: 90, emailBulkLimit: 63);

    /// The Emails today card's badge color: a candy drop's face (#98).
    Color badge(WidgetTester tester) {
      final card = find.ancestor(
        of: find.text('Emails today'),
        matching: find.byType(Material),
      );
      return tester
          .widget<CandyBox>(
            find.descendant(of: card.first, matching: find.byType(CandyBox)),
          )
          .color;
    }

    testWidgets("the Dashboard counts today's emails, and where invites "
        'stop (ADMIN-1)', (tester) async {
      final handle = tester.ensureSemantics();
      await openAdmin(tester, '/admin', totals: emails(38));
      expect(find.text('Emails today'), findsOneWidget);
      expect(find.text('38 of 90'), findsOneWidget);
      expect(
        find.text(
          'Invites and RSVP emails stop at 63. Setup emails can use the rest.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Emails today: 38 of 90\. Invites')),
        findsOneWidget,
      );
      final c = GumdropColors.of(tester.element(find.text('Emails today')));
      expect(badge(tester), c.mint.face);
      handle.dispose();
    });

    testWidgets('its badge warns once invites stop, and turns red when the day '
        'is full', (tester) async {
      await openAdmin(tester, '/admin', totals: emails(63));
      var c = GumdropColors.of(tester.element(find.text('Emails today')));
      expect(badge(tester), c.lemon.face);
      await openAdmin(tester, '/admin', totals: emails(90));
      c = GumdropColors.of(tester.element(find.text('Emails today')));
      expect(badge(tester), c.cherry.face);
    });

    testWidgets('Platform settings sets Emails a day, from the default '
        '(ADMIN-7)', (tester) async {
      final admin = await openAdmin(tester, '/admin/settings');
      final field = find.widgetWithText(TextField, 'Emails a day');
      expect(field, findsOneWidget);
      // This project's default until one is set: the test app's links are
      // prod's.
      expect(
        tester.widget<TextField>(field).controller!.text,
        '${Limits.emailsPerDayProd}',
      );
      expect(
        find.text(
          "Your email plan's daily limit for this project. Dev and prod "
          "share Resend's 100.",
        ),
        findsOneWidget,
      );
      await tester.enterText(field, '0');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a whole number from 1 to 10000.'),
        findsOneWidget,
      );
      expect(admin.savedConfigs, isEmpty);
      await tester.enterText(field, '250');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(admin.savedConfigs.single.emailsPerDay, 250);
    });
  });
}
