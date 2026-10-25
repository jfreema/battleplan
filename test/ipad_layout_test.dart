// The iPad pass (store checklist 1.12, ROADMAP task 210, SPEC §5.5): App
// Review runs on iPads, so every screen has to lay out at iPad sizes, in
// portrait and landscape, and in Split View and Slide Over, which give the
// app a narrow slice of the screen. A layout that overflows fails here.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/env.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart';

/// iPad sizes in points: whole screens, then Split View and Slide Over.
const ipadSizes = {
  'iPad mini, portrait': Size(744, 1133),
  'iPad mini, landscape': Size(1133, 744),
  'iPad Air 11-inch, portrait': Size(820, 1180),
  'iPad Air 11-inch, landscape': Size(1180, 820),
  'iPad Pro 13-inch, portrait': Size(1032, 1376),
  'iPad Pro 13-inch, landscape': Size(1376, 1032),
  'Slide Over, or a third in portrait': Size(320, 1180),
  'a third in landscape': Size(375, 820),
  'two thirds in portrait (11-inch)': Size(504, 1180),
  'half in landscape (11-inch)': Size(592, 820),
  'half in landscape (13-inch)': Size(678, 1024),
  'two thirds in portrait (13-inch)': Size(694, 1366),
  'two thirds in landscape (11-inch)': Size(809, 820),
  'two thirds in landscape (13-inch)': Size(981, 1024),
};

/// Every screen a team member reaches, by route.
const teamRoutes = [
  '/g/a/chat',
  '/g/a/schedule',
  '/g/a/schedule/e/e1',
  '/g/a/schedule/new',
  '/g/a/documents',
  '/g/a/plays',
  '/g/a/plays/saved',
  '/g/a/roster',
  '/g/a/invite',
  '/g/a/invite/email',
  '/g/a/notifications',
  '/g/a/settings',
  '/g/a/media',
  '/g/a/reports',
  '/g/a/import',
  '/g/a/members/add',
  '/g/a/players/add',
  '/g/a/who',
  '/notifications',
  '/settings',
  '/settings/profile',
  '/settings/sign-in-methods',
  '/settings/blocked',
  '/settings/notifications',
  '/g/new',
  '/join',
];

/// The super-admin panel (ADMIN-1 to ADMIN-8).
const adminRoutes = [
  '/admin',
  '/admin/teams',
  '/admin/users',
  '/admin/reports',
  '/admin/audit',
  '/admin/settings',
];

Future<void> visit(WidgetTester tester, String route, String size) async {
  GoRouter.of(tester.element(find.byType(Navigator).first)).go(route);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: '$route on $size');
}

void main() {
  testWidgets("the team header stays below an iPad's status bar, in the "
      'wide layout too', (tester) async {
    tester.view
      ..padding = const FakeViewPadding(top: 24)
      ..viewPadding = const FakeViewPadding(top: 24);
    await pumpTeam(
      tester,
      theme: ThemePreference.dark,
      size: ipadSizes['iPad Pro 13-inch, portrait']!,
    );
    expect(
      tester.getTopLeft(find.byTooltip('Team menu')).dy,
      greaterThanOrEqualTo(24),
    );
  });

  for (final MapEntry(key: name, value: size) in ipadSizes.entries) {
    group(name, () {
      testWidgets('sign-in, sign-up, and email sign-in', (tester) async {
        await pumpApp(
          tester,
          auth: FakeAuthRepository(),
          env: const AppEnv(flavor: AppFlavor.prod, useEmulators: false),
          size: size,
        );
        expect(tester.takeException(), isNull);
        for (final route in ['/sign-up', '/emaillogin', '/reset-password']) {
          await visit(tester, route, name);
        }
      });

      testWidgets("every team member's screen", (tester) async {
        await pumpTeam(tester, theme: ThemePreference.dark, size: size);
        expect(tester.takeException(), isNull);
        for (final route in teamRoutes) {
          await visit(tester, route, name);
        }
      });

      testWidgets("the super admin's panel", (tester) async {
        await pumpTeam(
          tester,
          theme: ThemePreference.dark,
          size: size,
          user: boss,
        );
        for (final route in adminRoutes) {
          await visit(tester, route, name);
        }
      });
    });
  }
}
