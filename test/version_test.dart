// Versions and build numbers (ARCH §9): the forced-update comparison, and
// what Settings → About shows.
import 'package:battleplan/core/version.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  test('versions compare by number, ignoring the build', () {
    expect(compareVersions('1.2.10', '1.2.9'), greaterThan(0));
    expect(compareVersions('1.2', '1.2.0'), 0);
    expect(compareVersions('0.1.0+312', '0.1.0'), 0);
    expect(compareVersions('0.9.9', '1.0.0'), lessThan(0));
  });

  test('the full build reads as semantic versioning build metadata', () {
    expect(
      const AppBuild(version: '0.1.0', number: '312', commit: '806de75').full,
      '0.1.0+312.806de75',
    );
    expect(
      const AppBuild(version: '0.1.0', number: '1', commit: '').full,
      '0.1.0+1',
    );
    expect(
      const AppBuild(version: '0.1.0', number: '', commit: '').full,
      '0.1.0',
    );
  });

  Future<void> openSettings(WidgetTester tester, AppBuild build) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(
        user: const AuthUser(
          uid: 'coach',
          email: 'coach@example.com',
          emailVerified: true,
        ),
      ),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach')],
      build: build,
      size: const Size(400, 2400),
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/settings');
    await tester.pumpAndSettle();
  }

  testWidgets('Settings shows the version, build, and commit', (tester) async {
    await openSettings(
      tester,
      const AppBuild(version: '0.1.0', number: '312', commit: '806de75'),
    );
    final about = find.text('Version 0.1.0 (build 312)');
    await tester.ensureVisible(about);
    expect(about, findsOneWidget);
    expect(find.text('806de75'), findsOneWidget);
  });

  testWidgets('a build without a number shows just the version', (
    tester,
  ) async {
    await openSettings(
      tester,
      const AppBuild(version: '0.1.0', number: '', commit: ''),
    );
    final about = find.text('Version 0.1.0');
    await tester.ensureVisible(about);
    expect(about, findsOneWidget);
  });
}
