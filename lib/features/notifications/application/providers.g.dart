// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(pushRepository)
final pushRepositoryProvider = PushRepositoryProvider._();

/// Overridden in app/providers.dart.

final class PushRepositoryProvider
    extends $FunctionalProvider<PushRepository, PushRepository, PushRepository>
    with $Provider<PushRepository> {
  /// Overridden in app/providers.dart.
  PushRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRepositoryHash();

  @$internal
  @override
  $ProviderElement<PushRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PushRepository create(Ref ref) {
    return pushRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushRepository>(value),
    );
  }
}

String _$pushRepositoryHash() => r'b02fa08cd4276efc92908678ab9f6e942ed0f0f1';

/// Overridden in app/providers.dart.

@ProviderFor(deviceRepository)
final deviceRepositoryProvider = DeviceRepositoryProvider._();

/// Overridden in app/providers.dart.

final class DeviceRepositoryProvider
    extends
        $FunctionalProvider<
          DeviceRepository,
          DeviceRepository,
          DeviceRepository
        >
    with $Provider<DeviceRepository> {
  /// Overridden in app/providers.dart.
  DeviceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceRepositoryHash();

  @$internal
  @override
  $ProviderElement<DeviceRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceRepository create(Ref ref) {
    return deviceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceRepository>(value),
    );
  }
}

String _$deviceRepositoryHash() => r'15b2b30b92d7c49b033522e98edcea989e7df9ca';

/// Overridden in app/providers.dart.

@ProviderFor(notificationRepository)
final notificationRepositoryProvider = NotificationRepositoryProvider._();

/// Overridden in app/providers.dart.

final class NotificationRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationRepository,
          NotificationRepository,
          NotificationRepository
        >
    with $Provider<NotificationRepository> {
  /// Overridden in app/providers.dart.
  NotificationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationRepository create(Ref ref) {
    return notificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationRepository>(value),
    );
  }
}

String _$notificationRepositoryHash() =>
    r'99b36fc3dcdf929239df5d3089f0dc5f633f8de9';

/// This build's version, stored on the `devices` doc. Overridden in
/// app/providers.dart, since features can't import app/ (ARCH §5.2).

@ProviderFor(deviceAppVersion)
final deviceAppVersionProvider = DeviceAppVersionProvider._();

/// This build's version, stored on the `devices` doc. Overridden in
/// app/providers.dart, since features can't import app/ (ARCH §5.2).

final class DeviceAppVersionProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// This build's version, stored on the `devices` doc. Overridden in
  /// app/providers.dart, since features can't import app/ (ARCH §5.2).
  DeviceAppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceAppVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceAppVersionHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return deviceAppVersion(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$deviceAppVersionHash() => r'2840cb6ca19c33b18410057cd5b927826c371d66';

/// Whether notifications are allowed on this device. Screens invalidate it
/// on resume, since the person can change it in system settings.

@ProviderFor(pushPermission)
final pushPermissionProvider = PushPermissionProvider._();

/// Whether notifications are allowed on this device. Screens invalidate it
/// on resume, since the person can change it in system settings.

final class PushPermissionProvider
    extends
        $FunctionalProvider<
          AsyncValue<PushPermission>,
          PushPermission,
          FutureOr<PushPermission>
        >
    with $FutureModifier<PushPermission>, $FutureProvider<PushPermission> {
  /// Whether notifications are allowed on this device. Screens invalidate it
  /// on resume, since the person can change it in system settings.
  PushPermissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushPermissionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushPermissionHash();

  @$internal
  @override
  $FutureProviderElement<PushPermission> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PushPermission> create(Ref ref) {
    return pushPermission(ref);
  }
}

String _$pushPermissionHash() => r'6734d58a922b053724d8b3b03266066bba1a79ec';

/// Unread notification-center items for the bell, up to 100 (NOTIF-11).
/// A one-time count, not a listener (ARCH §10.2): refreshed on resume, on
/// every foreground push, and after marking read.

@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = UnreadNotificationCountProvider._();

/// Unread notification-center items for the bell, up to 100 (NOTIF-11).
/// A one-time count, not a listener (ARCH §10.2): refreshed on resume, on
/// every foreground push, and after marking read.

final class UnreadNotificationCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Unread notification-center items for the bell, up to 100 (NOTIF-11).
  /// A one-time count, not a listener (ARCH §10.2): refreshed on resume, on
  /// every foreground push, and after marking read.
  UnreadNotificationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return unreadNotificationCount(ref);
  }
}

String _$unreadNotificationCountHash() =>
    r'f0282af204ba910219fb69a98d94469d15bf8031';

/// The in-app banner for a push that arrives while the app is open
/// (NOTIF-7): the message, or null when nothing is showing.

@ProviderFor(PushBanner)
final pushBannerProvider = PushBannerProvider._();

/// The in-app banner for a push that arrives while the app is open
/// (NOTIF-7): the message, or null when nothing is showing.
final class PushBannerProvider
    extends $NotifierProvider<PushBanner, PushMessage?> {
  /// The in-app banner for a push that arrives while the app is open
  /// (NOTIF-7): the message, or null when nothing is showing.
  PushBannerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushBannerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushBannerHash();

  @$internal
  @override
  PushBanner create() => PushBanner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushMessage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushMessage?>(value),
    );
  }
}

String _$pushBannerHash() => r'9edd0a9ec40b11dc641cc9ce26471954fc06dad2';

/// The in-app banner for a push that arrives while the app is open
/// (NOTIF-7): the message, or null when nothing is showing.

abstract class _$PushBanner extends $Notifier<PushMessage?> {
  PushMessage? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PushMessage?, PushMessage?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PushMessage?, PushMessage?>,
              PushMessage?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
