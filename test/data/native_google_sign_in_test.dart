// Data-layer tests (SPEC §8.1): Google sign-in in Android's own account
// sheet, which replaced the browser tab that lost its place on the way
// back from Google ("missing initial state", 2026-11-18; AUTH-1).
import 'package:battleplan/core/env.dart';
import 'package:battleplan/features/auth/data/native_google_sign_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

/// The plugin, answering each sheet with the next of [answers]: an ID
/// token, or a [GoogleSignInException] to throw.
class _Sheet extends GoogleSignInPlatform {
  new(this.answers, {this.initError});

  final List<Object> answers;
  final Error? initError;
  final inits = <InitParameters>[];

  @override
  Future<void> init(InitParameters params) async {
    inits.add(params);
    if (initError case final error?) throw error;
  }

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async => switch (answers.removeAt(0)) {
    final String token => AuthenticationResults(
      user: const GoogleSignInUserData(email: 'alex@gmail.com', id: '1'),
      authenticationTokens: AuthenticationTokenData(idToken: token),
    ),
    final GoogleSignInException error => throw error,
    _ => const AuthenticationResults(
      user: GoogleSignInUserData(email: 'alex@gmail.com', id: '1'),
      authenticationTokens: AuthenticationTokenData(idToken: null),
    ),
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoogleSignInException _e(GoogleSignInExceptionCode code) =>
    GoogleSignInException(code: code);

void main() {
  test('asks for an ID token for the project, setting up once', () async {
    final sheet = _Sheet(['token-1', 'token-2']);
    final google = AndroidGoogleSignIn('web-client', platform: sheet);
    expect(await google.idToken(), 'token-1');
    expect(await google.idToken(), 'token-2');
    expect(sheet.inits, hasLength(1));
    expect(sheet.inits.single.serverClientId, 'web-client');
  });

  test(
    'closing the sheet, or its going away, is no token and no error',
    () async {
      final google = AndroidGoogleSignIn(
        'web-client',
        platform: _Sheet([
          _e(GoogleSignInExceptionCode.canceled),
          _e(GoogleSignInExceptionCode.interrupted),
        ]),
      );
      expect(await google.idToken(), isNull);
      expect(await google.idToken(), isNull);
    },
  );

  test(
    "the sheet's failures, and an account with no token, are errors",
    () async {
      final google = AndroidGoogleSignIn(
        'web-client',
        platform: _Sheet([
          _e(GoogleSignInExceptionCode.providerConfigurationError),
          // No token.
          false,
        ]),
      );
      await expectLater(
        google.idToken(),
        throwsA(
          isA<GoogleSignInException>().having(
            (e) => e.code,
            'code',
            GoogleSignInExceptionCode.providerConfigurationError,
          ),
        ),
      );
      await expectLater(
        google.idToken(),
        throwsA(
          isA<GoogleSignInException>().having(
            (e) => e.code,
            'code',
            GoogleSignInExceptionCode.unknownError,
          ),
        ),
      );
    },
  );

  test('a failed setup is tried again on the next sign-in', () async {
    final broken = _Sheet(['token'], initError: StateError('no activity'));
    final google = AndroidGoogleSignIn('web-client', platform: broken);
    await expectLater(google.idToken(), throwsStateError);
    await expectLater(google.idToken(), throwsStateError);
    expect(broken.inits, hasLength(2));
  });

  test("each project's web client, and none on the emulators", () {
    String? id(AppFlavor flavor, {bool emulators = false}) =>
        AppEnv(flavor: flavor, useEmulators: emulators).googleServerClientId;
    expect(id(AppFlavor.dev), startsWith('814215990622-'));
    expect(id(AppFlavor.prod), startsWith('628123687470-'));
    for (final flavor in AppFlavor.values) {
      expect(id(flavor), endsWith('.apps.googleusercontent.com'));
      expect(id(flavor, emulators: true), isNull);
    }
  });
}
