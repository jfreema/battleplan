// End to end on a real device, simulator, or emulator, against the Emulator
// Suite with the seed loaded (store checklist 1.13): the seeded coach opens
// a team's invite code; a new parent signs up with email, finishes setup,
// joins with the code, chats, posts a photo, and answers an RSVP, and the
// navigation suits the screen (store checklist 1.12). Any error fails it.
//
// Run (docs/DEVELOPMENT.md, "End-to-end test"):
//   flutter test integration_test/e2e_test.dart -d <device> --flavor dev \
//     --dart-define=USE_EMULATORS=true
//
// Google sign-up can't run here: it needs a real Google account, so it's a
// hands-on step. Neither can the system photo picker, so a stand-in hands
// the app one photo, which then uploads and posts like any other.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:battleplan/app/bootstrap.dart';
import 'package:battleplan/app/firebase_options_dev.dart';
import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:battleplan/features/chat/presentation/photo_grid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// A 240 × 160 JPEG: a white dot on the brand blue.
final Uint8List _photo = base64Decode(
  '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCACgAPADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDkqKKK/Wj5gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAorvPBHwx1jxNGLqc/wBm6ecbZp4yWkBXIMacbh93kkDnjOCK9h0H4WeFtIcSNZvfzKxZXvW8wAEYxsACEdTypOT16Y8jGZ3hcK3Bvml2X+ex1UsJUqK+yPmKivtCytLaxtktrK3htrdM7YoUCKuTk4A4HJJp88MdxBJDPGksMilHR1DKykYIIPUEV5X+tKv/AAtPX/gHT/Z3978P+CfFlFfUmvfDTwtrCHdpqWU20Kstl+5KgHP3R8hJ5GSpOPoMeUeNvhJqejJJd6I76pZhh+6RD9oQEnHyj74A25IweSdoAJr08JnuFxDUW+V+f+Zz1cFUp67o8yooor2TkCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAr2v4R/Dazu9Mh1zxFD9o8/D2to4ZVVQ3DuON27HA5UqcnOeOQ+D3hNPE3iQzXYzp+n7JpVwrCRs/JGQexwxPB4UjjINfTVfL5/mkqX+zUXZ9X+h6OCwyl+8nt0CiiivjT1gooooAKKKKAPL/il8NrPVbK81bRYfI1dN08kcYYi645G0Zw5xkEDkk5znI+ea+1q8A+PHhNNN1NNfsxi3v5Nk6AKoSbbkEY5O4BieOoJJ+YCvrMgzSTl9VrO/Z/p/l9x5mNwyt7SHzPKKKKK+uPLCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPp34MaO2keArMyh1mvWa8dWYEANgJjHYoqHB5yT9B3NQ2NrDY2VvaWqeXb28axRpknaqjAGTyeB3qavyzE1nXrSqvq2z6SnDkio9gooorAsKKKKACiiigArB8eaO2veD9V06MO00sJaJUYKWkUh0GTxgsoB9ieR1reoq6dR0pqcd07/AHClFSTT6nxTRWp4qtYbHxPrFpap5dvb3k0UaZJ2qrkAZPJ4Hesuv1WElOKkup801Z2CiiiqEFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQB9pwTR3EEc0EiSwyKHR0YMrKRkEEdQRT6434RawuseAtNOU860X7HIqKQFKYC9epKbCSOMk9Og7KvyvEUXQqypPo2j6WEueKkuoUUUViUFFFFABRRRQAUUVkeL9YXQPDOpamSga3hLR71LKZDwgIHOCxUfj1HWqhB1JKEd3oJtRV2fK/jGaO48Xa5NBIksMl9O6OjBlZTIxBBHUEVkUUV+rQjyRUex803d3CiiiqEFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQB6b8DfFa6Nrr6TeyOLPUWVYsAsEnyAvGeAwOCcHkJnABNfRNfFNfQ3wj+INtqumQ6Trd5s1eHCJLcOB9qBbC4PGXGQuDknrzk4+T4gyxt/WqSv3X6/5np4HEJfu5fI9Qooor5E9QKKKKACiiigArxH4/eK1kePw1ZSODGwmvcAqCcAomc8jB3EYIzswcgiu1+Jfjyy8MaXcW9rcJLrcimOKGNlZoGK5Ejg5wACCAR83HbJHzLPNJcTyTTyPLNIxd3dizMxOSST1JNfUZBljnNYqqtFt5vv6L8/Q87HYhJezjv1GUUUV9keSFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFAHq/gj4wXmmxi18SpNqNuMBLhCvnIAuMEHAfJA5JB5JJbgV7DoPjDw/rzhNK1W2mmZiqwsTHIxAycI2GIx3AxwfQ18j0V4eMyDDYhucPcflt93+VjspY2pBWeqPtaivj2y8Ra1Y2yW1lrGo21umdsUNy6KuTk4AOBySafP4n1+4gkhn1zVJYZFKOj3cjKykYIIJ5BFeU+F6l/4it6HV/aMf5T6o17xLougITq+pW1swUP5TNmQqTgEIMsRnPQdj6GvKPG3xlaRJLTwnG8RDD/TplGSATnZGQeCAOW5wSNoODXi9FelhOHsPRalUfO/Pb7v82c1XHVJ6R0HzzSXE8k08jyzSMXd3YszMTkkk9STTKKK99KxxBRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAf/9k=',
);

/// Hands the app [_photo] instead of opening the system picker.
class _OnePhoto implements PhotoPicker {
  const new();

  @override
  Future<List<PickedPhoto>> pickChatPhotos({int limit = 10}) async => [
    (bytes: Uint8List.fromList(_photo), contentType: 'image/jpeg'),
  ];

  @override
  Future<Uint8List?> pickProfilePhoto() async => Uint8List.fromList(_photo);

  @override
  Future<PickedPhoto?> takeChatPhoto() async => null;

  @override
  bool get canUseCamera => false;
}

/// The seeded owner (tools/seed): every seeded password is `password`.
const _coach = 'coach@example.com';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps until [finder] finds something, for screens that wait on the
  /// emulators (pumpAndSettle never settles with spinners and live data).
  Future<void> until(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return;
    }
    // What was on screen instead, to see where it got stuck.
    final shown = {
      for (final e in find.byType(Text).evaluate()) ?(e.widget as Text).data,
    };
    throw TestFailure('Timed out waiting for $finder. On screen: $shown');
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await until(tester, finder);
    await tester.ensureVisible(finder.first);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(finder.first);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> type(WidgetTester tester, Finder field, String text) async {
    await until(tester, field);
    await tester.enterText(field.first, text);
    await tester.pump(const Duration(milliseconds: 250));
  }

  void go(WidgetTester tester, String route) =>
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(route);

  Future<void> signInWithEmail(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await tap(tester, find.text('Continue with email'));
    await type(tester, find.widgetWithText(TextFormField, 'Email'), email);
    await type(
      tester,
      find.widgetWithText(TextFormField, 'Password'),
      password,
    );
    await tap(tester, find.widgetWithText(FilledButton, 'Sign in'));
  }

  testWidgets('sign up, set up, join a team, chat, post a photo, and RSVP', (
    tester,
  ) async {
    final testOnError = FlutterError.onError;
    final testPlatformOnError = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = testOnError;
      PlatformDispatcher.instance.onError = testPlatformOnError;
    });

    await bootstrap(
      flavor: AppFlavor.dev,
      cloudOptions: () => DefaultFirebaseOptions.currentPlatform,
      photoPicker: const _OnePhoto(),
    );
    // The app's handlers report errors; the test's fail it as well.
    final appOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      appOnError?.call(details);
      testOnError?.call(details);
    };
    final uncaught = <Object>[];
    final appPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      uncaught.add(error);
      return appPlatformOnError?.call(error, stack) ?? false;
    };

    // A session from an earlier run stays in the keychain: start signed out.
    await tester.pump(const Duration(seconds: 2));
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }

    // The seeded coach opens their team's invite code.
    await signInWithEmail(tester, _coach, 'password');
    await tap(tester, find.byTooltip('Team info'));
    await tap(tester, find.text('Invite'));
    final codeText = find.byWidgetPredicate(
      (w) =>
          w is SelectableText &&
          RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(w.data ?? ''),
    );
    await until(tester, codeText);
    final code = tester.widget<SelectableText>(codeText.first).data!;
    go(tester, '/settings');
    await until(tester, find.byType(ListView));
    // Below the fold on a phone, so not built until scrolled to.
    await tester.dragUntilVisible(
      find.text('Sign out'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tap(tester, find.text('Sign out'));

    // A new parent signs up and finishes setup (AUTH-2, AUTH-5).
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await tap(tester, find.text('Continue with email'));
    await tap(tester, find.text('Create account').first);
    await type(
      tester,
      find.widgetWithText(TextFormField, 'Your name'),
      'Pat Parent',
    );
    await type(
      tester,
      find.widgetWithText(TextFormField, 'Email'),
      'e2e-$stamp@example.com',
    );
    await type(
      tester,
      find.widgetWithText(TextFormField, 'Password'),
      'longenough',
    );
    await tap(tester, find.widgetWithText(FilledButton, 'Create account'));
    await tap(tester, find.text("I'm 18 or older"));
    await tap(tester, find.textContaining('I agree to the Terms'));
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));

    // Joins with the code (INV-6), as a coach or another adult (PLAYER-3).
    await tap(tester, find.text('Join a Team or Group'));
    await type(tester, find.byType(TextField), code);
    await tap(tester, find.widgetWithText(FilledButton, 'Join team'));
    await tap(tester, find.widgetWithText(FilledButton, 'Join team'));
    await tap(tester, find.text("I'm a coach or another adult"));

    // Chats (CHAT-2).
    final message = 'Hello from the end-to-end test $stamp';
    await type(tester, find.byType(TextField).last, message);
    await tap(tester, find.byTooltip('Send'));
    await until(tester, find.text(message));
    await until(tester, find.text('Sent'));

    // Posts a photo (CHAT-3): it uploads to Storage and shows in the chat.
    await tap(tester, find.byTooltip('Add photos or a poll'));
    await tap(tester, find.text('Photo library'));
    await until(
      tester,
      find.byType(PhotoGrid),
      timeout: const Duration(minutes: 1),
    );

    // Answers an RSVP (SCHED-5) on the first upcoming event, found by its
    // time ("6:00 PM – 7:30 PM", with a narrow space before PM).
    await tap(tester, find.text('Schedule'));
    final event = find.byWidgetPredicate(
      (w) =>
          w is Text && RegExp(r'^\d{1,2}:\d{2}.[AP]M').hasMatch(w.data ?? ''),
    );
    await tap(tester, event);
    await tap(tester, find.text('Going'));
    await until(tester, find.text('Clear'));

    // The navigation suits the width (SPEC §5.5): the side rail from 840
    // points (an iPad in landscape), the bottom bar below. iPadOS doesn't
    // let an app that supports Split View turn itself, so the iPad
    // layouts at every orientation and in Split View are checked by
    // test/ipad_layout_test.dart.
    go(tester, '/');
    await until(tester, find.byTooltip('Team info'));
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    await until(
      tester,
      find.byType(width >= 840 ? NavigationRail : NavigationBar),
    );

    expect(uncaught, isEmpty);
  });
}
