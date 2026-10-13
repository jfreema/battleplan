// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionService)
final sessionServiceProvider = SessionServiceProvider._();

final class SessionServiceProvider
    extends $FunctionalProvider<SessionService, SessionService, SessionService>
    with $Provider<SessionService> {
  SessionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionServiceHash();

  @$internal
  @override
  $ProviderElement<SessionService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionService create(Ref ref) {
    return sessionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionService>(value),
    );
  }
}

String _$sessionServiceHash() => r'cbf261e3db1e818981761f8180762e0488ac8aa6';

/// AUTH-9: "Sign out of all devices" ends every session at once. Revoking
/// refresh tokens alone would leave other devices signed in until their
/// ID token expires (up to an hour), so the server also stamps
/// `users.sessionsRevokedAt`; this device signs out as soon as it sees a
/// stamp newer than its own sign-in. The app watches it while running.

@ProviderFor(sessionRevocationWatcher)
final sessionRevocationWatcherProvider = SessionRevocationWatcherProvider._();

/// AUTH-9: "Sign out of all devices" ends every session at once. Revoking
/// refresh tokens alone would leave other devices signed in until their
/// ID token expires (up to an hour), so the server also stamps
/// `users.sessionsRevokedAt`; this device signs out as soon as it sees a
/// stamp newer than its own sign-in. The app watches it while running.

final class SessionRevocationWatcherProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// AUTH-9: "Sign out of all devices" ends every session at once. Revoking
  /// refresh tokens alone would leave other devices signed in until their
  /// ID token expires (up to an hour), so the server also stamps
  /// `users.sessionsRevokedAt`; this device signs out as soon as it sees a
  /// stamp newer than its own sign-in. The app watches it while running.
  SessionRevocationWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionRevocationWatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionRevocationWatcherHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return sessionRevocationWatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$sessionRevocationWatcherHash() =>
    r'0d1c21c0780d6b96577ff98a472b308f389c5433';
