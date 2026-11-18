// Data-layer tests (SPEC §8.1): sign-in through Firebase Authentication.
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/links.dart';
import 'package:battleplan/features/auth/data/firebase_auth_repository.dart';
import 'package:battleplan/features/auth/data/native_google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import '../helpers/fake_functions.dart';

const _links = LinkService(LinkService.devHost);

MockUser _user({
  List<String> providers = const ['password'],
  bool verified = true,
  Map<String, dynamic>? claims,
  DateTime? signedInAt,
  DateTime? issuedAt,
}) => MockUser(
  uid: 'u1',
  email: 'alex@example.com',
  displayName: 'Alex',
  isEmailVerified: verified,
  customClaim: claims,
  // AUTH-7: changing sign-in methods needs a sign-in in the last 5 minutes,
  // by the server's clock: auth_time against the fresh token's issue time.
  idTokenResult: _Token(
    signedInAt ?? DateTime.now(),
    claims,
    issuedAtTime: issuedAt ?? DateTime.now(),
  ),
  providerData: [for (final p in providers) _Info(p)],
);

class _Info implements UserInfo {
  new(this.providerId);

  @override
  final String providerId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Token implements IdTokenResult {
  new(this.authTime, this.claims, {required this.issuedAtTime});

  @override
  final DateTime authTime;

  @override
  final DateTime issuedAtTime;

  @override
  final Map<String, dynamic>? claims;

  @override
  String get signInProvider => 'password';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FirebaseAuthException _e(String code, {String? email}) =>
    FirebaseAuthException(code: code, email: email);

/// An account with Apple sign-in whose fresh Apple sign-in hands back
/// Apple's authorization code, or fails with [reauthError].
// ignore: must_be_immutable, MockUser's own name and photo fields change.
class _AppleUser extends MockUser {
  new({this.reauthError})
    : super(
        uid: 'u1',
        email: 'alex@example.com',
        idTokenResult: _Token(
          DateTime.now(),
          null,
          issuedAtTime: DateTime.now(),
        ),
        providerData: [_Info('apple.com')],
      );

  final FirebaseAuthException? reauthError;

  /// The providers each fresh sign-in used.
  final reauths = <String>[];

  @override
  Future<UserCredential> reauthenticateWithProvider(
    AuthProvider provider,
  ) async {
    reauths.add(provider.providerId);
    if (reauthError case final error?) throw error;
    return _AppleCredential(this);
  }
}

class _AppleCredential implements UserCredential {
  new(this.user);

  @override
  final User user;

  @override
  AdditionalUserInfo get additionalUserInfo => _AppleInfo();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AppleInfo implements AdditionalUserInfo {
  @override
  String get authorizationCode => 'apple-code';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Android's own Google account sheet: hands back [token] for the account
/// picked (null: closed), or fails with [error].
class _Sheet implements NativeGoogleSignIn {
  new({this.token = 'google-id-token', this.error});

  final String? token;
  final Exception? error;

  /// How many times it opened.
  int opened = 0;

  @override
  Future<String?> idToken() async {
    opened++;
    if (error case final error?) throw error;
    return token;
  }
}

/// Records the Apple authorization codes revoked, or fails with
/// [revokeError].
class _RevokingAuth extends MockFirebaseAuth {
  new(MockUser user, {this.revokeError})
    : super(signedIn: true, mockUser: user);

  final FirebaseAuthException? revokeError;
  final revoked = <String>[];

  @override
  Future<void> revokeTokenWithAuthorizationCode(String code) async {
    if (revokeError case final error?) throw error;
    revoked.add(code);
  }
}

void main() {
  late FakeFunctions functions;

  setUp(() => functions = FakeFunctions());

  FirebaseAuthRepository repoFor(
    MockFirebaseAuth auth, {
    NativeGoogleSignIn? google,
  }) => FirebaseAuthRepository(
    auth,
    functions,
    links: _links,
    googleNative: google,
  );

  /// Runs [act] once per code on a fresh auth whose [method] throws it.
  Future<void> expectMapped(
    List<(String, Matcher)> cases,
    Object Function(MockFirebaseAuth auth) target,
    Symbol method,
    Future<void> Function(FirebaseAuthRepository repo) act, {
    MockUser Function()? user,
    NativeGoogleSignIn? google,
  }) async {
    for (final (code, type) in cases) {
      final mockUser = user?.call() ?? _user();
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      whenCalling(Invocation.method(method, null))
          .on(target(auth))
          .thenThrow(_e(code));
      await expectLater(
        act(repoFor(auth, google: google)),
        throwsA(type),
        reason: code,
      );
    }
  }

  test('maps the signed-in user with the superAdmin claim', () async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: _user(claims: {'superAdmin': true}),
    );
    final repo = repoFor(auth);
    final next = repo.watchUser().first;
    await auth.signInWithEmailAndPassword(
      email: 'alex@example.com',
      password: 'pw',
    );
    final user = (await next)!;
    expect(user.uid, 'u1');
    expect(user.isSuperAdmin, isTrue);
    expect(user.providerIds, ['password']);
    expect(user.signInProvider, 'password');
    expect(repo.currentUser, user);
  });

  test('signs in with email, and never says which part was wrong', () async {
    final auth = MockFirebaseAuth(mockUser: _user());
    await repoFor(auth)
        .signInWithEmail(email: 'alex@example.com', password: 'pw');
    expect(auth.currentUser, isNotNull);
    await expectMapped(
      [
        ('wrong-password', isA<InvalidInput>()),
        ('user-not-found', isA<InvalidInput>()),
        ('user-disabled', isA<PermissionDenied>()),
        ('too-many-requests', isA<RateLimited>()),
        ('network-request-failed', isA<Offline>()),
        ('internal-error', isA<UnknownFailure>()),
      ],
      (a) => a,
      #signInWithEmailAndPassword,
      (r) => r.signInWithEmail(email: 'a@example.com', password: 'x'),
    );
  });

  test(
    'creates an account and sends the verification email (AUTH-3)',
    () async {
      final auth = MockFirebaseAuth(mockUser: _user(verified: false));
      await repoFor(auth).createAccount(
        name: 'Alex',
        email: 'alex@example.com',
        password: 'password1',
      );
      expect(auth.currentUser, isNotNull);
      await expectMapped(
        [
          ('email-already-in-use', isA<EmailAlreadyInUse>()),
          ('weak-password', isA<WeakPassword>()),
          ('invalid-email', isA<InvalidInput>()),
          ('too-many-requests', isA<RateLimited>()),
          ('network-request-failed', isA<Offline>()),
          ('internal-error', isA<UnknownFailure>()),
        ],
        (a) => a,
        #createUserWithEmailAndPassword,
        (r) =>
            r.createAccount(name: 'A', email: 'a@example.com', password: 'x'),
      );
    },
  );

  test('sends verification only to an unverified user', () async {
    await repoFor(MockFirebaseAuth()).sendEmailVerification();
    await repoFor(MockFirebaseAuth(signedIn: true, mockUser: _user()))
        .sendEmailVerification();
    await repoFor(
      MockFirebaseAuth(signedIn: true, mockUser: _user(verified: false)),
    ).sendEmailVerification();
    for (final (code, type) in [
      ('too-many-requests', isA<RateLimited>()),
      ('network-request-failed', isA<Offline>()),
      ('internal-error', isA<UnknownFailure>()),
    ]) {
      final user = _user(verified: false);
      whenCalling(Invocation.method(#sendEmailVerification, null))
          .on(user)
          .thenThrow(_e(code));
      await expectLater(
        repoFor(MockFirebaseAuth(signedIn: true, mockUser: user))
            .sendEmailVerification(),
        throwsA(type),
      );
    }
  });

  test('reloads the user, signing out a revoked session', () async {
    await repoFor(MockFirebaseAuth()).reloadUser();
    await repoFor(MockFirebaseAuth(signedIn: true, mockUser: _user()))
        .reloadUser();
    for (final (code, type) in [
      ('user-token-expired', isA<Unauthenticated>()),
      ('user-disabled', isA<Unauthenticated>()),
      ('network-request-failed', isA<Offline>()),
      ('internal-error', isA<UnknownFailure>()),
    ]) {
      final user = _user();
      whenCalling(Invocation.method(#reload, null))
          .on(user)
          .thenThrow(_e(code));
      await expectLater(
        repoFor(MockFirebaseAuth(signedIn: true, mockUser: user)).reloadUser(),
        throwsA(type),
      );
    }
  });

  test('sends a password reset, quiet about unknown emails (AUTH-4)', () async {
    await repoFor(MockFirebaseAuth()).sendPasswordReset('a@example.com');
    final quiet = MockFirebaseAuth();
    whenCalling(Invocation.method(#sendPasswordResetEmail, null))
        .on(quiet)
        .thenThrow(_e('user-not-found'));
    await repoFor(quiet).sendPasswordReset('nobody@example.com');
    await expectMapped(
      [
        ('invalid-email', isA<InvalidInput>()),
        ('too-many-requests', isA<RateLimited>()),
        ('network-request-failed', isA<Offline>()),
        ('internal-error', isA<UnknownFailure>()),
      ],
      (a) => a,
      #sendPasswordResetEmail,
      (r) => r.sendPasswordReset('a@example.com'),
    );
  });

  test('signs in with Google and Apple; closing the sheet is not an error (AUTH-1)', () async {
    final auth = MockFirebaseAuth(mockUser: _user(providers: ['google.com']));
    await repoFor(auth).signInWithGoogle();
    expect(auth.currentUser, isNotNull);
    await repoFor(MockFirebaseAuth(mockUser: _user())).signInWithApple();

    final closed = MockFirebaseAuth();
    whenCalling(Invocation.method(#signInWithProvider, null))
        .on(closed)
        .thenThrow(_e('canceled'));
    await repoFor(closed).signInWithGoogle();

    await expectMapped(
      [
        ('popup-blocked', isA<PopupBlocked>()),
        (
          'account-exists-with-different-credential',
          isA<AccountExistsWithOtherMethod>(),
        ),
        ('user-disabled', isA<PermissionDenied>()),
        ('network-request-failed', isA<Offline>()),
        ('internal-error', isA<UnknownFailure>()),
      ],
      (a) => a,
      #signInWithProvider,
      (r) => r.signInWithGoogle(),
    );
  });

  test('reports each Google or Apple failure shown as "Something went wrong", '
      'and nothing it explains (AUTH-1, ARCH §9)', () async {
    final reports = <ProviderSignInException>[];
    FirebaseAuthRepository reporting(MockFirebaseAuth auth) =>
        FirebaseAuthRepository(
          auth,
          functions,
          links: _links,
          onSignInError: (e, _) => reports.add(e),
        );

    // A check the app can't explain, such as Firebase not knowing the key
    // a Play install is signed with: reported with Firebase's code and
    // message, and still shown as "Something went wrong".
    final refused = MockFirebaseAuth();
    whenCalling(Invocation.method(#signInWithProvider, null))
        .on(refused)
        .thenThrow(
          FirebaseAuthException(
            code: 'internal-error',
            message: 'Invalid certificate hash',
          ),
        );
    await expectLater(
      reporting(refused).signInWithGoogle(),
      throwsA(isA<UnknownFailure>()),
    );
    final report = reports.single;
    expect(report.providerId, 'google.com');
    expect(report.action, 'sign in');
    expect(report.code, 'internal-error');
    expect(report.detail, 'Invalid certificate hash');
    expect(
      '$report',
      "Couldn't sign in with google.com: internal-error "
          '(Invalid certificate hash)',
    );

    // Closing the sheet, and the failures the screens explain, aren't.
    final closed = MockFirebaseAuth();
    whenCalling(Invocation.method(#signInWithProvider, null))
        .on(closed)
        .thenThrow(_e('canceled'));
    await reporting(closed).signInWithApple();
    for (final code in [
      'popup-blocked',
      'user-disabled',
      'network-request-failed',
      'account-exists-with-different-credential',
    ]) {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithProvider, null))
          .on(auth)
          .thenThrow(_e(code));
      await expectLater(
        reporting(auth).signInWithApple(),
        throwsA(isA<AppFailure>()),
        reason: code,
      );
    }
    expect(reports, hasLength(1));

    // The plugin failing on its own is reported too, and passed on.
    final broken = MockFirebaseAuth();
    whenCalling(Invocation.method(#signInWithProvider, null))
        .on(broken)
        .thenThrow(
          PlatformException(code: 'channel-error', message: 'No channel'),
        );
    await expectLater(
      reporting(broken).signInWithApple(),
      throwsA(isA<PlatformException>()),
    );
    expect(reports.last.providerId, 'apple.com');
    expect(reports.last.code, 'unexpected');
    expect(reports.last.detail, contains('No channel'));

    // Linking Google from Sign-in methods: reported the same way, but not
    // a method already on another account, which the screen explains.
    final linking = _user();
    whenCalling(Invocation.method(#linkWithProvider, null))
        .on(linking)
        .thenThrow(_e('internal-error'));
    await expectLater(
      reporting(MockFirebaseAuth(signedIn: true, mockUser: linking))
          .linkGoogle(),
      throwsA(isA<UnknownFailure>()),
    );
    expect(reports.last.action, 'link');
    expect(reports.last.providerId, 'google.com');
    final taken = _user();
    whenCalling(Invocation.method(#linkWithProvider, null))
        .on(taken)
        .thenThrow(_e('credential-already-in-use'));
    await expectLater(
      reporting(MockFirebaseAuth(signedIn: true, mockUser: taken)).linkGoogle(),
      throwsA(isA<CredentialInUse>()),
    );
    expect(reports, hasLength(3));

    // Confirming it's you with Apple before a change.
    await expectLater(
      reporting(
        MockFirebaseAuth(
          signedIn: true,
          mockUser: _AppleUser(reauthError: _e('internal-error')),
        ),
      ).reauthenticateWithProvider('apple.com'),
      throwsA(isA<UnknownFailure>()),
    );
    expect(reports.last.action, 'confirm');
    expect(reports.last.providerId, 'apple.com');

    // With nobody listening, the failure is the same.
    await expectLater(
      repoFor(refused).signInWithGoogle(),
      throwsA(isA<UnknownFailure>()),
    );
    expect(reports, hasLength(4));
  });

  test('emails a sign-in link instead of merging accounts (AUTH-7)', () async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(#signInWithProvider, null))
        .on(auth)
        .thenThrow(
          _e(
            'account-exists-with-different-credential',
            email: 'alex@example.com',
          ),
        );
    await expectLater(
      repoFor(auth).signInWithGoogle(),
      throwsA(
        isA<AccountExistsWithOtherMethod>().having(
          (f) => f.message,
          'email',
          'alex@example.com',
        ),
      ),
    );
    await repoFor(MockFirebaseAuth()).sendSignInLink('alex@example.com');
    await expectMapped(
      [
        ('invalid-email', isA<InvalidInput>()),
        ('too-many-requests', isA<RateLimited>()),
        ('network-request-failed', isA<Offline>()),
        ('internal-error', isA<UnknownFailure>()),
      ],
      (a) => a,
      #sendSignInLinkToEmail,
      (r) => r.sendSignInLink('a@example.com'),
    );
  });

  group("Google in Android's own account sheet, not a browser tab that "
      'can lose its place ("missing initial state", 2026-11-18; AUTH-1)', () {
    test(
      'signs in with the account picked, never through the browser',
      () async {
        final auth = MockFirebaseAuth(
          mockUser: _user(providers: ['google.com']),
        );
        // Firebase's browser flow would fail; it isn't used.
        whenCalling(Invocation.method(#signInWithProvider, null))
            .on(auth)
            .thenThrow(_e('web-internal-error'));
        final sheet = _Sheet();
        await repoFor(auth, google: sheet).signInWithGoogle();
        expect(sheet.opened, 1);
        expect(auth.currentUser, isNotNull);

        // Closing the sheet signs nobody in, and isn't an error.
        final closed = MockFirebaseAuth(mockUser: _user());
        await repoFor(closed, google: _Sheet(token: null)).signInWithGoogle();
        expect(closed.currentUser, isNull);
      },
    );

    test("Apple keeps Firebase's flow", () async {
      final sheet = _Sheet();
      final auth = MockFirebaseAuth(mockUser: _user(providers: ['apple.com']));
      await repoFor(auth, google: sheet).signInWithApple();
      expect(sheet.opened, 0);
      expect(auth.currentUser, isNotNull);
    });

    test("Firebase's answers mean what they did, and the sheet's own "
        'failures are reported as "Something went wrong"', () async {
      await expectMapped(
        [
          (
            'account-exists-with-different-credential',
            isA<AccountExistsWithOtherMethod>(),
          ),
          ('user-disabled', isA<PermissionDenied>()),
          ('network-request-failed', isA<Offline>()),
          ('invalid-credential', isA<UnknownFailure>()),
        ],
        (a) => a,
        #signInWithCredential,
        (r) => r.signInWithGoogle(),
        google: _Sheet(),
      );

      final reports = <ProviderSignInException>[];
      final broken = FirebaseAuthRepository(
        MockFirebaseAuth(
          signedIn: true,
          mockUser: _user(providers: ['google.com']),
        ),
        functions,
        links: _links,
        googleNative: _Sheet(
          error: const GoogleSignInException(
            code: GoogleSignInExceptionCode.providerConfigurationError,
            description: 'Developer console is not set up correctly.',
          ),
        ),
        onSignInError: (e, _) => reports.add(e),
      );
      for (final act in [
        broken.signInWithGoogle,
        () => broken.reauthenticateWithProvider('google.com'),
      ]) {
        await expectLater(act(), throwsA(isA<UnknownFailure>()));
      }
      expect(reports.map((r) => r.action), ['sign in', 'confirm']);
      expect(reports.first.providerId, 'google.com');
      expect(reports.first.code, 'google-providerConfigurationError');
      expect(
        reports.first.detail,
        'Developer console is not set up correctly.',
      );
    });

    test(
      'emails a sign-in link instead of merging accounts (AUTH-7)',
      () async {
        final auth = MockFirebaseAuth();
        whenCalling(Invocation.method(#signInWithCredential, null))
            .on(auth)
            .thenThrow(
              _e(
                'account-exists-with-different-credential',
                email: 'alex@example.com',
              ),
            );
        await expectLater(
          repoFor(auth, google: _Sheet()).signInWithGoogle(),
          throwsA(
            isA<AccountExistsWithOtherMethod>().having(
              (f) => f.message,
              'email',
              'alex@example.com',
            ),
          ),
        );
      },
    );

    test(
      'links Google from Sign-in methods; closing the sheet links nothing',
      () async {
        final user = _user();
        whenCalling(Invocation.method(#linkWithProvider, null))
            .on(user)
            .thenThrow(_e('web-internal-error'));
        final auth = MockFirebaseAuth(signedIn: true, mockUser: user);
        expect(await repoFor(auth, google: _Sheet()).linkGoogle(), isTrue);
        expect(
          functions.calls.where((c) => c.$1 == 'recordSignInMethodChange'),
          hasLength(1),
        );
        expect(
          await repoFor(auth, google: _Sheet(token: null)).linkGoogle(),
          isFalse,
        );
        expect(functions.calls, hasLength(1));

        // A Google account already on someone else's: the screen explains it.
        final taken = _user();
        whenCalling(Invocation.method(#linkWithCredential, null))
            .on(taken)
            .thenThrow(_e('credential-already-in-use'));
        await expectLater(
          repoFor(
            MockFirebaseAuth(signedIn: true, mockUser: taken),
            google: _Sheet(),
          ).linkGoogle(),
          throwsA(isA<CredentialInUse>()),
        );
      },
    );

    test("confirms it's you with Google before a change; closing the sheet "
        'leaves the change waiting, unreported', () async {
      final reports = <ProviderSignInException>[];
      FirebaseAuthRepository confirming(MockUser user, _Sheet sheet) =>
          FirebaseAuthRepository(
            MockFirebaseAuth(signedIn: true, mockUser: user),
            functions,
            links: _links,
            googleNative: sheet,
            onSignInError: (e, _) => reports.add(e),
          );
      final user = _user(providers: ['google.com']);
      whenCalling(Invocation.method(#reauthenticateWithProvider, null))
          .on(user)
          .thenThrow(_e('web-internal-error'));
      final sheet = _Sheet();
      await confirming(user, sheet).reauthenticateWithProvider('google.com');
      expect(sheet.opened, 1);
      await expectLater(
        confirming(
          _user(providers: ['google.com']),
          _Sheet(token: null),
        ).reauthenticateWithProvider('google.com'),
        throwsA(isA<RequiresRecentLogin>()),
      );
      // Another Google account than this one's.
      final other = _user(providers: ['google.com']);
      whenCalling(Invocation.method(#reauthenticateWithCredential, null))
          .on(other)
          .thenThrow(_e('user-mismatch'));
      await expectLater(
        confirming(other, _Sheet()).reauthenticateWithProvider('google.com'),
        throwsA(isA<UnknownFailure>()),
      );
      expect(reports.map((r) => r.code), ['user-mismatch']);
    });
  });

  test('links and unlinks sign-in methods, keeping the last one', () async {
    final user = _user();
    final repo = repoFor(MockFirebaseAuth(signedIn: true, mockUser: user));
    await repo.linkGoogle();
    expect(user.providerData.map((p) => p.providerId), contains('google.com'));
    await repo.unlink('google.com');
    expect(user.providerData.map((p) => p.providerId), ['password']);
    await expectLater(repo.unlink('password'), throwsA(isA<InvalidInput>()));
    expect(
      functions.calls.where((c) => c.$1 == 'recordSignInMethodChange').length,
      2,
    );

    final closedUser = _user();
    whenCalling(Invocation.method(#linkWithProvider, null))
        .on(closedUser)
        .thenThrow(_e('user-cancelled'));
    await repoFor(MockFirebaseAuth(signedIn: true, mockUser: closedUser))
        .linkGoogle();

    functions.fail('recordSignInMethodChange', 'internal');
    await expectLater(
      repoFor(MockFirebaseAuth(signedIn: true, mockUser: _user())).linkGoogle(),
      throwsA(isA<UnknownFailure>()),
    );
    await expectLater(
      repoFor(MockFirebaseAuth()).linkGoogle(),
      throwsA(isA<Unauthenticated>()),
    );
  });

  test('asks for a fresh sign-in before changing methods (AUTH-7)', () async {
    final stale = repoFor(
      MockFirebaseAuth(
        signedIn: true,
        mockUser: _user(
          signedInAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ),
    );
    await expectLater(stale.linkGoogle(), throwsA(isA<RequiresRecentLogin>()));
    await expectLater(
      stale.setPassword('newpassword'),
      throwsA(isA<RequiresRecentLogin>()),
    );
    await expectLater(
      stale.changeEmail('new@example.com'),
      throwsA(isA<RequiresRecentLogin>()),
    );
    expect(functions.calls, isEmpty);

    // An added account choosing how to sign in skips the app's own check
    // (AUTH-6); Firebase still asks where it must.
    await stale.linkGoogle(checkRecent: false);
    await stale.setPassword('newpassword', checkRecent: false);
    expect(functions.calls, hasLength(2));
  });

  test('the recent sign-in check uses the server clock, not the device '
      'clock (AUTH-7)', () async {
    // Signed in a minute before the server issued a fresh token; this
    // device's clock runs 9 minutes fast, so by it the sign-in is 10
    // minutes old.
    final now = DateTime.now();
    final repo = repoFor(
      MockFirebaseAuth(
        signedIn: true,
        mockUser: _user(
          signedInAt: now.subtract(const Duration(minutes: 10)),
          issuedAt: now.subtract(const Duration(minutes: 9)),
        ),
      ),
    );
    expect(await repo.linkGoogle(), isTrue);
    await repo.changeEmail('new@example.com');
  });

  test('maps sign-in method errors', () async {
    await expectMapped(
      [
        ('requires-recent-login', isA<RequiresRecentLogin>()),
        ('credential-already-in-use', isA<CredentialInUse>()),
        ('weak-password', isA<WeakPassword>()),
        ('wrong-password', isA<InvalidInput>()),
        ('invalid-email', isA<InvalidInput>()),
        ('network-request-failed', isA<Offline>()),
        ('too-many-requests', isA<RateLimited>()),
        ('internal-error', isA<UnknownFailure>()),
      ],
      (a) => a.currentUser!,
      #updatePassword,
      (r) => r.setPassword('newpassword'),
    );
  });

  test(
    'sets or adds a password, changes the email, and reauthenticates',
    () async {
      await repoFor(MockFirebaseAuth(signedIn: true, mockUser: _user()))
          .setPassword('newpassword');
      await repoFor(
        MockFirebaseAuth(
          signedIn: true,
          mockUser: _user(providers: ['google.com']),
        ),
      ).setPassword('newpassword');
      final repo = repoFor(MockFirebaseAuth(signedIn: true, mockUser: _user()));
      await repo.changeEmail('new@example.com');
      await repo.reauthenticateWithPassword('password1');
      final noEmail = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u2'),
      );
      await expectLater(
        repoFor(noEmail).reauthenticateWithPassword('x'),
        throwsA(isA<InvalidInput>()),
      );
      await expectMapped(
        [('requires-recent-login', isA<RequiresRecentLogin>())],
        (a) => a.currentUser!,
        #verifyBeforeUpdateEmail,
        (r) => r.changeEmail('new@example.com'),
      );
      await expectMapped(
        [('wrong-password', isA<InvalidInput>())],
        (a) => a.currentUser!,
        #reauthenticateWithCredential,
        (r) => r.reauthenticateWithPassword('nope'),
      );
    },
  );

  test(
    'deletes the account and signs out everywhere through callables',
    () async {
      final auth = MockFirebaseAuth(signedIn: true, mockUser: _user());
      await repoFor(auth).deleteAccount();
      expect(auth.currentUser, isNull);
      final again = MockFirebaseAuth(signedIn: true, mockUser: _user());
      await repoFor(again).signOutEverywhere();
      expect(again.currentUser, isNull);
      final plain = MockFirebaseAuth(signedIn: true, mockUser: _user());
      await repoFor(plain).signOut();
      expect(plain.currentUser, isNull);

      for (final (code, type) in [
        ('failed-precondition', isA<RequiresRecentLogin>()),
        ('unavailable', isA<Offline>()),
        ('internal', isA<UnknownFailure>()),
      ]) {
        functions.fail('deleteAccount', code);
        await expectLater(
          repoFor(MockFirebaseAuth(signedIn: true, mockUser: _user()))
              .deleteAccount(),
          throwsA(type),
        );
      }
      for (final (code, type) in [
        ('deadline-exceeded', isA<Offline>()),
        ('internal', isA<UnknownFailure>()),
      ]) {
        functions.fail('signOutEverywhere', code);
        await expectLater(
          repoFor(MockFirebaseAuth(signedIn: true, mockUser: _user()))
              .signOutEverywhere(),
          throwsA(type),
        );
      }
    },
  );
  test('links Apple the way it links Google (task 109)', () async {
    final user = _user();
    final repo = repoFor(MockFirebaseAuth(signedIn: true, mockUser: user));
    expect(await repo.linkApple(), isTrue);
    expect(user.providerData.map((p) => p.providerId), contains('apple.com'));
    expect(functions.calls.single.$1, 'recordSignInMethodChange');
  });

  group('deleting an account with Apple sign-in in the iPhone and iPad app '
      '(App Review 5.1.1(v))', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test("signs in with Apple again, revokes Apple's tokens, then "
        'deletes', () async {
      final user = _AppleUser();
      final auth = _RevokingAuth(user);
      await repoFor(auth).deleteAccount();
      expect(user.reauths, ['apple.com']);
      expect(auth.revoked, ['apple-code']);
      expect(functions.calls.single.$1, 'deleteAccount');
      expect(auth.currentUser, isNull);
    });

    test("closing Apple's sheet deletes nothing", () async {
      final auth = _RevokingAuth(_AppleUser(reauthError: _e('canceled')));
      await expectLater(
        repoFor(auth).deleteAccount(),
        throwsA(isA<SignInCanceled>()),
      );
      expect(auth.revoked, isEmpty);
      expect(functions.calls, isEmpty);
    });

    test('a refused Apple sign-in deletes nothing', () async {
      final auth = _RevokingAuth(_AppleUser(reauthError: _e('user-mismatch')));
      await expectLater(
        repoFor(auth).deleteAccount(),
        throwsA(isA<UnknownFailure>()),
      );
      expect(functions.calls, isEmpty);
    });

    test('a failed revoke still deletes the account', () async {
      final auth = _RevokingAuth(
        _AppleUser(),
        revokeError: _e('invalid-credential'),
      );
      await repoFor(auth).deleteAccount();
      expect(functions.calls.single.$1, 'deleteAccount');
      expect(auth.currentUser, isNull);
    });

    test('accounts without Apple, and Android, skip it', () async {
      final google = _RevokingAuth(_user(providers: ['google.com']));
      await repoFor(google).deleteAccount();
      expect(google.revoked, isEmpty);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final user = _AppleUser();
      final android = _RevokingAuth(user);
      await repoFor(android).deleteAccount();
      expect(user.reauths, isEmpty);
      expect(android.revoked, isEmpty);
      expect(functions.calls.map((c) => c.$1), [
        'deleteAccount',
        'deleteAccount',
      ]);
    });
  });
}
