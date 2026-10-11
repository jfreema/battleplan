// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// Overridden in app/providers.dart.

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Overridden in app/providers.dart.
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'916c16ea1b05261e6453c56554da2d5a2f00ae47';

/// The signed-in user, or null. The router and most screens watch this.

@ProviderFor(authUser)
final authUserProvider = AuthUserProvider._();

/// The signed-in user, or null. The router and most screens watch this.

final class AuthUserProvider
    extends
        $FunctionalProvider<AsyncValue<AuthUser?>, AuthUser?, Stream<AuthUser?>>
    with $FutureModifier<AuthUser?>, $StreamProvider<AuthUser?> {
  /// The signed-in user, or null. The router and most screens watch this.
  AuthUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authUserHash();

  @$internal
  @override
  $StreamProviderElement<AuthUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthUser?> create(Ref ref) {
    return authUser(ref);
  }
}

String _$authUserHash() => r'eb5861fccca8a24b7df59fc0415964608897267f';

/// Overridden in app/providers.dart.

@ProviderFor(userRepository)
final userRepositoryProvider = UserRepositoryProvider._();

/// Overridden in app/providers.dart.

final class UserRepositoryProvider
    extends $FunctionalProvider<UserRepository, UserRepository, UserRepository>
    with $Provider<UserRepository> {
  /// Overridden in app/providers.dart.
  UserRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserRepository create(Ref ref) {
    return userRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserRepository>(value),
    );
  }
}

String _$userRepositoryHash() => r'2514308090efaa25862553395f53a6e0804f4ac7';

/// The signed-in person's Battleplan profile. Creating it at first sign-in
/// is idempotent, so it's requested whenever the signed-in user changes.

@ProviderFor(myProfile)
final myProfileProvider = MyProfileProvider._();

/// The signed-in person's Battleplan profile. Creating it at first sign-in
/// is idempotent, so it's requested whenever the signed-in user changes.

final class MyProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          Stream<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $StreamProvider<UserProfile?> {
  /// The signed-in person's Battleplan profile. Creating it at first sign-in
  /// is idempotent, so it's requested whenever the signed-in user changes.
  MyProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProfileHash();

  @$internal
  @override
  $StreamProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserProfile?> create(Ref ref) {
    return myProfile(ref);
  }
}

String _$myProfileHash() => r'928a546b913ec5c33498da8f335b8224c3debe88';

/// A URL for the signed-in person's profile photo, or null.

@ProviderFor(myPhotoUrl)
final myPhotoUrlProvider = MyPhotoUrlProvider._();

/// A URL for the signed-in person's profile photo, or null.

final class MyPhotoUrlProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// A URL for the signed-in person's profile photo, or null.
  MyPhotoUrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPhotoUrlProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPhotoUrlHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return myPhotoUrl(ref);
  }
}

String _$myPhotoUrlHash() => r'ff0f15cb1087c8e2df4954abac92127ba392cc54';
