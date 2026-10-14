// Accounts, sign-in, setup, and settings (SPEC §6.1, SET-1): the gaps the
// MVP audit found, end to end on fake repositories.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
import 'package:battleplan/features/auth/data/firebase_auth_repository.dart';
import 'package:battleplan/features/auth/data/firestore_user_repository.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/auth/presentation/crop_photo_screen.dart';
import 'package:battleplan/features/auth/presentation/sign_in_screen.dart';
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

  group('sign-in screen (AUTH-1, edge cases)', () {
    testWidgets('the footer links to the Terms and Privacy Policy', (
      tester,
    ) async {
      final links = FakeLinkOpener();
      await pumpApp(tester, auth: FakeAuthRepository(), linkOpener: links);
      await tester.tap(find.text('Terms of Use'));
      await tester.tap(find.text('Privacy Policy'));
      expect(links.opened.map((u) => u.path), ['/terms', '/privacy']);
    });

    testWidgets("the Apple button follows Apple's style once it's on, and "
        'is hidden until then (task 187)', (tester) async {
      await pumpApp(tester, auth: FakeAuthRepository());
      expect(find.byType(AppleSignInButton), findsNothing);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppleSignInButton(
              label: 'Continue with Apple',
              onPressed: () {},
            ),
          ),
        ),
      );
      final apple = find.byType(AppleSignInButton);
      expect(apple, findsOneWidget);
      expect(
        find.descendant(of: apple, matching: find.byIcon(Icons.apple)),
        findsOneWidget,
      );
    });

    testWidgets('offline shows an inline error with Retry', (tester) async {
      final auth = OfflineOnceAuth();
      await pumpApp(tester, auth: auth);
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.textContaining("You're offline"), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(auth.googleAttempts, 2);
      expect(find.text('Continue with Google'), findsNothing);
    });

    testWidgets('a disabled account sees only the disabled message', (
      tester,
    ) async {
      await pumpApp(tester, auth: DisabledAuth());
      await tester.tap(find.text('Continue with email'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'coach@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.textContaining('has been disabled'), findsOneWidget);
      expect(find.textContaining('@'), findsOneWidget);
      expect(find.text('Continue with Google'), findsNothing);
      await tester.tap(find.text('Back to sign-in'));
      await tester.pumpAndSettle();
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.textContaining('has been disabled'), findsNothing);
    });

    testWidgets('an email in use points added people to their setup email', (
      tester,
    ) async {
      await pumpApp(tester, auth: FakeAuthRepository());
      await tester.tap(find.text('Continue with email'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Jordan');
      await tester.enterText(find.byType(TextField).at(1), 'coach@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'longenough');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Use the link in your setup email'),
        findsOneWidget,
      );
    });
  });

  group('safe account linking (AUTH-7)', () {
    testWidgets('Google for an existing email links after the emailed link', (
      tester,
    ) async {
      final auth = ExistingAccountAuth();
      final prefs = await pumpApp(tester, auth: auth);
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.textContaining('We emailed you a link'), findsOneWidget);
      expect(prefs.pendingSignInEmail, 'coach@example.com');
      expect(prefs.pendingLink, (
        providerId: 'google.com',
        email: 'coach@example.com',
      ));

      // Opening the link signs them in; then the app offers to add Google.
      await auth.signInWithLink(
        email: 'coach@example.com',
        link: Uri.parse('/activate?mode=signIn'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Google sign-in?'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Continue with Google'),
      );
      await tester.pumpAndSettle();
      expect(auth.currentUser!.providerIds, contains('google.com'));
      expect(prefs.pendingLink, isNull);
      expect(find.text('Welcome to Battleplan'), findsOneWidget);
    });

    testWidgets('Not now skips linking and forgets it', (tester) async {
      final prefs = FakeLocalPrefs()
        ..pendingLink = (providerId: 'google.com', email: 'coach@example.com');
      final auth = FakeAuthRepository(user: coach);
      await pumpApp(tester, auth: auth, prefs: prefs);
      expect(find.text('Add Google sign-in?'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(prefs.pendingLink, isNull);
      expect(auth.currentUser!.providerIds, isNot(contains('google.com')));
      expect(find.text('Welcome to Battleplan'), findsOneWidget);
    });

    test('changes need a sign-in within the last 5 minutes, by the time the '
        'server issued a fresh token', () {
      final issued = DateTime.utc(2026, 10, 12, 12);
      expect(
        isRecentSignIn(issued.subtract(const Duration(minutes: 4)), issued),
        isTrue,
      );
      expect(
        isRecentSignIn(issued.subtract(const Duration(minutes: 6)), issued),
        isFalse,
      );
      expect(isRecentSignIn(null, issued), isFalse);
      expect(isRecentSignIn(issued, null), isFalse);
    });
  });

  group('added accounts choose how to sign in (AUTH-6)', () {
    testWidgets('after the setup link, they create a password', (tester) async {
      final users = FakeUserRepository()..chooseSignIn = true;
      final auth = FakeAuthRepository(
        user: coach.copyWith(providerIds: ['password']),
      );
      final prefs = await pumpApp(tester, auth: auth, users: users);
      expect(
        find.text('How do you want to sign in from now on?'),
        findsOneWidget,
      );
      // Not offered until Sign in with Apple is on (task 187).
      expect(find.byType(AppleSignInButton), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Create a password'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'longenough');
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(users.chooseSignIn, isFalse);
      expect(auth.uncheckedChanges, ['password']);
      // A fresh sign-in on this device may ask for it from now on.
      expect(prefs.passwordSetUids, {'coach'});
      expect(find.text('Welcome to Battleplan'), findsOneWidget);
    });

    testWidgets('long after the setup link, Google still links without '
        'asking for a password they never had (AUTH-7)', (tester) async {
      final users = FakeUserRepository()..chooseSignIn = true;
      final auth = FakeAuthRepository(
        user: coach.copyWith(
          providerIds: ['password'],
          signInProvider: 'emailLink',
        ),
      )..needsRecentLogin = true;
      await pumpApp(tester, auth: auth, users: users);
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text("Confirm it's you"), findsNothing);
      expect(auth.uncheckedChanges, ['google.com']);
      expect(users.chooseSignIn, isFalse);
      expect(find.text('Welcome to Battleplan'), findsOneWidget);
    });

    testWidgets('they can sign out instead of choosing', (tester) async {
      final users = FakeUserRepository()..chooseSignIn = true;
      final auth = FakeAuthRepository(
        user: coach.copyWith(providerIds: ['password']),
      );
      await pumpApp(tester, auth: auth, users: users);
      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNull);
      expect(
        find.text('How do you want to sign in from now on?'),
        findsNothing,
      );
    });

    testWidgets('closing the Google sheet keeps asking', (tester) async {
      final users = FakeUserRepository()..chooseSignIn = true;
      final auth = FakeAuthRepository(
        user: coach.copyWith(providerIds: ['password']),
      )..linkCancels = true;
      await pumpApp(tester, auth: auth, users: users);
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(users.chooseSignIn, isTrue);
      expect(
        find.text('How do you want to sign in from now on?'),
        findsOneWidget,
      );

      auth.linkCancels = false;
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(users.chooseSignIn, isFalse);
      expect(find.text('Welcome to Battleplan'), findsOneWidget);
    });
  });

  group('sign out of all devices (AUTH-9)', () {
    test('ends sessions that signed in before it, to the second', () {
      final at = DateTime.utc(2026, 10, 12, 12);
      expect(sessionRevoked(at, at.add(const Duration(seconds: 2))), isTrue);
      expect(
        sessionRevoked(at, at.add(const Duration(milliseconds: 400))),
        isFalse,
      );
      expect(sessionRevoked(at.add(const Duration(seconds: 5)), at), isFalse);
      expect(sessionRevoked(null, at), isFalse);
      expect(sessionRevoked(at, null), isFalse);
    });

    testWidgets('another device signing out everywhere signs this one out '
        'at once', (tester) async {
      final signedInAt = DateTime.utc(2026, 10, 12, 9);
      final users = FakeUserRepository();
      final auth = FakeAuthRepository(
        user: coach.copyWith(authTime: signedInAt),
      );
      await pumpApp(tester, auth: auth, users: users);
      expect(find.text('Welcome to Battleplan'), findsOneWidget);

      users
        ..sessionsRevokedAt = signedInAt.subtract(const Duration(days: 1))
        ..changed();
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNotNull);

      users
        ..sessionsRevokedAt = signedInAt.add(const Duration(minutes: 1))
        ..changed();
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNull);
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });

  group('deleting the account (AUTH-10)', () {
    testWidgets('owners pick the new owner of each team they own', (
      tester,
    ) async {
      final auth = FakeAuthRepository(
        user: coach.copyWith(providerIds: ['google.com']),
      );
      await pumpApp(
        tester,
        auth: auth,
        groups: {'a': testGroup('a', 'Thunder'), 'b': testGroup('b', 'Hawks')},
        memberRepo: FakeMemberRepository([
          testMembership('a', 'coach', role: MemberRole.owner, name: 'Jordan'),
          testMembership('a', 'max', name: 'Max Lee'),
          testMembership('a', 'ana', role: MemberRole.admin, name: 'Ana Ruiz'),
          testMembership('b', 'coach', role: MemberRole.owner, name: 'Jordan'),
          testMembership('b', 'kim', name: 'Kim Park'),
        ]),
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/settings');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Delete account'), 100);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
      await tester.pumpAndSettle();

      expect(find.text('Choose new owners'), findsOneWidget);
      expect(find.text('Thunder'), findsOneWidget);
      expect(find.text('Hawks'), findsOneWidget);
      await tester.tap(find.text('Automatic').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Max Lee').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(auth.deleted, isTrue);
      // Hawks stays on Automatic: the longest-serving admin or member.
      expect(auth.deletedNewOwners, {'a': 'max'});
    });

    testWidgets('cancelling the pick deletes nothing', (tester) async {
      final auth = FakeAuthRepository(user: coach);
      await pumpApp(
        tester,
        auth: auth,
        groups: {'a': testGroup('a', 'Thunder')},
        memberRepo: FakeMemberRepository([
          testMembership('a', 'coach', role: MemberRole.owner, name: 'Jordan'),
        ]),
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/settings');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Delete account'), 100);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
      await tester.pumpAndSettle();
      expect(find.textContaining('it will be archived'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(auth.deleted, isFalse);
    });
  });

  group('profile photo (SET-1, AUTH-5)', () {
    test('the crop keeps the image covering the circle', () {
      const image = Size(200, 100);
      // Covering a 100 px square: the 100 px side fits exactly.
      expect(coverScale(image, 100), 1);
      expect(
        cropSourceRect(image, 100, const Offset(-50, 0), 1),
        const Rect.fromLTWH(50, 0, 100, 100),
      );
      // Zoomed 2x, the circle shows half as much.
      expect(
        cropSourceRect(image, 100, const Offset(-100, -50), 2),
        const Rect.fromLTWH(50, 25, 50, 50),
      );
      // No dragging past an edge.
      expect(
        clampCropOffset(image, 100, const Offset(30, -20), 1),
        Offset.zero,
      );
      expect(
        clampCropOffset(image, 100, const Offset(-500, 0), 1),
        const Offset(-100, 0),
      );
    });

    test('renders the crop as a square PNG', () async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 40, 20),
        Paint()..color = const Color(0xFF2F5BEA),
      );
      final image = await recorder.endRecording().toImage(40, 20);
      final png = await renderCrop(
        image,
        const Rect.fromLTWH(10, 0, 20, 20),
        64,
      );
      expect(isPng(png), isTrue);
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      expect((frame.image.width, frame.image.height), (64, 64));
    });

    testWidgets('setup offers a photo, cropped before it uploads, and links '
        'the Terms', (tester) async {
      final users = FakeUserRepository(needsSetup: true);
      final picker = FakePhotoPicker()
        ..profilePhoto = await tester.runAsync(_photo);
      final links = FakeLinkOpener();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        users: users,
        photoPicker: picker,
        linkOpener: links,
      );
      await tester.tap(find.text('Terms of Use'));
      expect(links.opened.single.path, '/terms');

      await tester.tap(find.text('Add photo'));
      await _openCrop(tester);
      expect(find.text('Crop photo'), findsOneWidget);
      await tester.tap(find.text('Use photo'));
      await _realWork(tester);
      await tester.pumpAndSettle();
      expect(users.photosUploaded, 1);
      expect(find.text('Crop photo'), findsNothing);
    });

    testWidgets('cancelling the crop uploads nothing', (tester) async {
      final users = FakeUserRepository();
      final picker = FakePhotoPicker()
        ..profilePhoto = await tester.runAsync(_photo);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        users: users,
        photoPicker: picker,
      );
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jordan Coach'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change photo'));
      await _openCrop(tester);
      expect(find.text('Crop photo'), findsOneWidget);
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(users.photosUploaded, 0);
    });
  });
}

/// A real 40x20 PNG, like a picked photo.
Future<Uint8List> _photo() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 40, 20),
    Paint()..color = const Color(0xFF2F5BEA),
  );
  final image = await recorder.endRecording().toImage(40, 20);
  return await renderCrop(image, const Rect.fromLTWH(0, 0, 40, 20), 40);
}

/// Long enough for a real image decode or encode in a test.
const _decodeTime = Duration(milliseconds: 300);

/// Lets the crop screen open and decode the picked photo for real.
Future<void> _openCrop(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await _realWork(tester);
  await tester.pumpAndSettle();
}

/// Image decoding and encoding run in the engine: give each step real time,
/// then a frame to carry on in the test's zone.
Future<void> _realWork(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(_decodeTime));
    await tester.pump();
  }
}
