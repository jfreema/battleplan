// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State for the sign-in screen: idle, loading, or the last error.
/// Navigation after success is the router's job (it watches the auth user).

@ProviderFor(SignInController)
final signInControllerProvider = SignInControllerProvider._();

/// State for the sign-in screen: idle, loading, or the last error.
/// Navigation after success is the router's job (it watches the auth user).
final class SignInControllerProvider
    extends $NotifierProvider<SignInController, AsyncValue<void>> {
  /// State for the sign-in screen: idle, loading, or the last error.
  /// Navigation after success is the router's job (it watches the auth user).
  SignInControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInControllerHash();

  @$internal
  @override
  SignInController create() => SignInController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$signInControllerHash() => r'b4b4493d71f3f24dccd8e3a05991f2fcc6ec5d7f';

/// State for the sign-in screen: idle, loading, or the last error.
/// Navigation after success is the router's job (it watches the auth user).

abstract class _$SignInController extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The address a sign-in link was just sent to, shown as a confirmation.

@ProviderFor(SignInLinkSent)
final signInLinkSentProvider = SignInLinkSentProvider._();

/// The address a sign-in link was just sent to, shown as a confirmation.
final class SignInLinkSentProvider
    extends $NotifierProvider<SignInLinkSent, String?> {
  /// The address a sign-in link was just sent to, shown as a confirmation.
  SignInLinkSentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInLinkSentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInLinkSentHash();

  @$internal
  @override
  SignInLinkSent create() => SignInLinkSent();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$signInLinkSentHash() => r'89959aa915765431446d6f69f8ba52d36ffadaa1';

/// The address a sign-in link was just sent to, shown as a confirmation.

abstract class _$SignInLinkSent extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
