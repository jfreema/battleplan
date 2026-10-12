// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_registration.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps this install's `devices` doc current while someone is signed in
/// and notifications are allowed (NOTIF-10, ARCH §6.5): written after
/// sign-in, again whenever FCM rotates the token, and at least daily on
/// start so the 60-day device prune never removes a device in use. Started
/// from app.dart; SessionService removes the doc at sign-out.

@ProviderFor(PushRegistration)
final pushRegistrationProvider = PushRegistrationProvider._();

/// Keeps this install's `devices` doc current while someone is signed in
/// and notifications are allowed (NOTIF-10, ARCH §6.5): written after
/// sign-in, again whenever FCM rotates the token, and at least daily on
/// start so the 60-day device prune never removes a device in use. Started
/// from app.dart; SessionService removes the doc at sign-out.
final class PushRegistrationProvider
    extends $NotifierProvider<PushRegistration, void> {
  /// Keeps this install's `devices` doc current while someone is signed in
  /// and notifications are allowed (NOTIF-10, ARCH §6.5): written after
  /// sign-in, again whenever FCM rotates the token, and at least daily on
  /// start so the 60-day device prune never removes a device in use. Started
  /// from app.dart; SessionService removes the doc at sign-out.
  PushRegistrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRegistrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRegistrationHash();

  @$internal
  @override
  PushRegistration create() => PushRegistration();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pushRegistrationHash() => r'8d8f522ec301a7979617458fee43f92d92da04f9';

/// Keeps this install's `devices` doc current while someone is signed in
/// and notifications are allowed (NOTIF-10, ARCH §6.5): written after
/// sign-in, again whenever FCM rotates the token, and at least daily on
/// start so the 60-day device prune never removes a device in use. Started
/// from app.dart; SessionService removes the doc at sign-out.

abstract class _$PushRegistration extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
