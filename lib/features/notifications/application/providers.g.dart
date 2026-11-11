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

/// Unread notification-center items for the bell, up to 100 (NOTIF-11):
/// every team's on Teams, or only [groupId]'s on that team's bell. A
/// one-time count, not a listener (ARCH §10.2): refreshed on resume, on
/// every foreground push, and after marking read, which invalidate the
/// whole family.

@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = UnreadNotificationCountFamily._();

/// Unread notification-center items for the bell, up to 100 (NOTIF-11):
/// every team's on Teams, or only [groupId]'s on that team's bell. A
/// one-time count, not a listener (ARCH §10.2): refreshed on resume, on
/// every foreground push, and after marking read, which invalidate the
/// whole family.

final class UnreadNotificationCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Unread notification-center items for the bell, up to 100 (NOTIF-11):
  /// every team's on Teams, or only [groupId]'s on that team's bell. A
  /// one-time count, not a listener (ARCH §10.2): refreshed on resume, on
  /// every foreground push, and after marking read, which invalidate the
  /// whole family.
  UnreadNotificationCountProvider._({
    required UnreadNotificationCountFamily super.from,
    required GroupId? super.argument,
  }) : super(
         retry: null,
         name: r'unreadNotificationCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationCountHash();

  @override
  String toString() {
    return r'unreadNotificationCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as GroupId?;
    return unreadNotificationCount(ref, groupId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UnreadNotificationCountProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unreadNotificationCountHash() =>
    r'63570aeb2757ba2a57fdb21ade2cddf952e52bd8';

/// Unread notification-center items for the bell, up to 100 (NOTIF-11):
/// every team's on Teams, or only [groupId]'s on that team's bell. A
/// one-time count, not a listener (ARCH §10.2): refreshed on resume, on
/// every foreground push, and after marking read, which invalidate the
/// whole family.

final class UnreadNotificationCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, GroupId?> {
  UnreadNotificationCountFamily._()
    : super(
        retry: null,
        name: r'unreadNotificationCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Unread notification-center items for the bell, up to 100 (NOTIF-11):
  /// every team's on Teams, or only [groupId]'s on that team's bell. A
  /// one-time count, not a listener (ARCH §10.2): refreshed on resume, on
  /// every foreground push, and after marking read, which invalidate the
  /// whole family.

  UnreadNotificationCountProvider call({GroupId? groupId}) =>
      UnreadNotificationCountProvider._(argument: groupId, from: this);

  @override
  String toString() => r'unreadNotificationCountProvider';
}

/// Whether the bell on Teams has unread items that [groupId]'s bell
/// doesn't, for the dot on the team header's back arrow (NOTIF-11): every
/// unread item, counted, against that team's. Both counts stop at 100, so
/// with 100 or more unread on this team it says no.

@ProviderFor(unreadNotificationsElsewhere)
final unreadNotificationsElsewhereProvider =
    UnreadNotificationsElsewhereFamily._();

/// Whether the bell on Teams has unread items that [groupId]'s bell
/// doesn't, for the dot on the team header's back arrow (NOTIF-11): every
/// unread item, counted, against that team's. Both counts stop at 100, so
/// with 100 or more unread on this team it says no.

final class UnreadNotificationsElsewhereProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the bell on Teams has unread items that [groupId]'s bell
  /// doesn't, for the dot on the team header's back arrow (NOTIF-11): every
  /// unread item, counted, against that team's. Both counts stop at 100, so
  /// with 100 or more unread on this team it says no.
  UnreadNotificationsElsewhereProvider._({
    required UnreadNotificationsElsewhereFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'unreadNotificationsElsewhereProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationsElsewhereHash();

  @override
  String toString() {
    return r'unreadNotificationsElsewhereProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as GroupId;
    return unreadNotificationsElsewhere(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UnreadNotificationsElsewhereProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unreadNotificationsElsewhereHash() =>
    r'01426fd652fb3189ac9af2d6c0b66bd55162fe86';

/// Whether the bell on Teams has unread items that [groupId]'s bell
/// doesn't, for the dot on the team header's back arrow (NOTIF-11): every
/// unread item, counted, against that team's. Both counts stop at 100, so
/// with 100 or more unread on this team it says no.

final class UnreadNotificationsElsewhereFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, GroupId> {
  UnreadNotificationsElsewhereFamily._()
    : super(
        retry: null,
        name: r'unreadNotificationsElsewhereProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the bell on Teams has unread items that [groupId]'s bell
  /// doesn't, for the dot on the team header's back arrow (NOTIF-11): every
  /// unread item, counted, against that team's. Both counts stop at 100, so
  /// with 100 or more unread on this team it says no.

  UnreadNotificationsElsewhereProvider call(GroupId groupId) =>
      UnreadNotificationsElsewhereProvider._(argument: groupId, from: this);

  @override
  String toString() => r'unreadNotificationsElsewhereProvider';
}

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
