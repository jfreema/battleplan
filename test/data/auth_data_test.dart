// Data-layer tests (SPEC §8.1): sign-in through Firebase Authentication.
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/links.dart';
import 'package:battleplan/features/auth/data/firebase_auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
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

  FirebaseAuthRepository repoFor(MockFirebaseAuth auth) =>
      FirebaseAuthRepository(auth, functions, links: _links);

  /// Runs [act] once per code on a fresh auth whose [method] throws it.
  Future<void> expectMapped(
    List<(String, Matcher)> cases,
    Object Function(MockFirebaseAuth auth) target,
    Symbol method,
    Future<void> Function(FirebaseAuthRepository repo) act, {
    MockUser Function()? user,
  }) async {
    for (final (code, type) in cases) {
      final mockUser = user?.call() ?? _user();
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      whenCalling(Invocation.method(method, null))
          .on(target(auth))
          .thenThrow(_e(code));
      await expectLater(act(repoFor(auth)), throwsA(type), reason: code);
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
