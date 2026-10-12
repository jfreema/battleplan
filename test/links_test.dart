import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/links.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/presentation/enter_code_screen.dart';
import 'package:battleplan/features/notifications/data/fcm_push_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

// The website is at the root and the web app under /app (D40, ARCH §6.6).
void main() {
  group('LinkService', () {
    const prod = LinkService(LinkService.prodHost);
    const dev = LinkService(LinkService.devHost);

    test('picks the host for the flavor', () {
      expect(LinkService.forEnv(isProd: true).host, 'getbattleplan.app');
      expect(
        LinkService.forEnv(isProd: false).host,
        'battleplan-dev-ecce4.web.app',
      );
    });

    test('puts app routes under /app', () {
      expect(
        prod.app('/g/a/schedule/e/e1').toString(),
        'https://getbattleplan.app/app/g/a/schedule/e/e1',
      );
      expect(
        dev.app('g/a/chat').toString(),
        'https://battleplan-dev-ecce4.web.app/app/g/a/chat',
      );
      expect(prod.appRoot.toString(), 'https://getbattleplan.app/app/');
      expect(
        prod.app('/sign-in?from=%2Fg%2Fa').toString(),
        'https://getbattleplan.app/app/sign-in?from=%2Fg%2Fa',
      );
    });

    test('keeps invite links short, at the root (WEB-4)', () {
      expect(
        prod.join('K7XPM2QR').toString(),
        'https://getbattleplan.app/join/K7XPM2QR',
      );
    });

    test('sends email sign-in to /app/activate', () {
      expect(
        prod.activate.toString(),
        'https://getbattleplan.app/app/activate',
      );
    });

    test('the iPhone app link goes through our domain (NOTIF-9)', () {
      expect(prod.iosApp.toString(), 'https://getbattleplan.app/ios');
    });

    test('website pages stay at the root', () {
      expect(
        prod.site('privacy').toString(),
        'https://getbattleplan.app/privacy',
      );
    });

    test('only a custom domain can be an email linkDomain', () {
      expect(prod.isCustomDomain, isTrue);
      expect(dev.isCustomDomain, isFalse);
      expect(
        const LinkService('battleplan-dev-ecce4.firebaseapp.com')
            .isCustomDomain,
        isFalse,
      );
    });
  });

  group('stripAppPrefix', () {
    String? strip(String s) => stripAppPrefix(Uri.parse(s))?.toString();

    test('drops a leading /app, keeping the query', () {
      expect(strip('/app/g/a/chat'), '/g/a/chat');
      expect(strip('/app/join/K7XPM2QR'), '/join/K7XPM2QR');
      expect(
        strip('/app/activate?mode=signIn&oobCode=x'),
        '/activate?mode=signIn&oobCode=x',
      );
      expect(strip('/app'), '/');
      expect(strip('/app/'), '/');
    });

    test('leaves other paths alone', () {
      expect(strip('/g/a/chat'), isNull);
      expect(strip('/join/K7XPM2QR'), isNull);
      expect(strip('/apple'), isNull);
      expect(strip('/application/x'), isNull);
      expect(strip('/'), isNull);
    });
  });

  test('the web push worker is registered under /app, not the root', () {
    // Relative to the base href, so /app/firebase-messaging-sw.js.
    expect(pushWorkerPath(isWeb: true), 'firebase-messaging-sw.js');
    expect(pushWorkerPath(isWeb: false), isNull);
  });

  test('invite codes come out of /app/join links too', () {
    expect(
      inviteCodeFrom('https://getbattleplan.app/app/join/K7XP-M2QR'),
      'K7XPM2QR',
    );
  });

  group('deep links with the /app prefix (Universal Links, App Links)', () {
    const coach = AuthUser(
      uid: 'coach',
      email: 'coach@example.com',
      emailVerified: true,
    );

    String location(WidgetTester tester) =>
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .routerDelegate
            .currentConfiguration
            .uri
            .toString();

    Future<void> openLink(WidgetTester tester, String path) async {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
      await tester.pumpAndSettle();
    }

    testWidgets('open the same screen as the link without it', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          'a': testGroup('a', 'Thunder'),
          'b': testGroup('b', 'Lightning'),
        },
        memberships: [
          testMembership('a', 'coach', role: MemberRole.owner),
          testMembership('b', 'coach'),
        ],
      );
      await tester.pumpAndSettle();

      await openLink(tester, '/app/g/b/schedule');
      expect(location(tester), '/g/b/schedule');

      await openLink(tester, '/app/g/a/chat');
      expect(location(tester), '/g/a/chat');
    });

    testWidgets('an /app/join link works signed out', (tester) async {
      await pumpApp(tester, auth: FakeAuthRepository());
      await tester.pumpAndSettle();

      await openLink(tester, '/app/join/K7XPM2QR');
      expect(location(tester), '/join/K7XPM2QR');
    });
  });
}
