// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_center.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The center across all my teams: the live newest 30 plus older pages
/// loaded by scrolling, merged by ID (ARCH §5.3). The listener runs only
/// while the screen is open (ARCH §10.2).

@ProviderFor(NotificationCenter)
final notificationCenterProvider = NotificationCenterProvider._();

/// The center across all my teams: the live newest 30 plus older pages
/// loaded by scrolling, merged by ID (ARCH §5.3). The listener runs only
/// while the screen is open (ARCH §10.2).
final class NotificationCenterProvider
    extends $NotifierProvider<NotificationCenter, NotificationCenterState> {
  /// The center across all my teams: the live newest 30 plus older pages
  /// loaded by scrolling, merged by ID (ARCH §5.3). The listener runs only
  /// while the screen is open (ARCH §10.2).
  NotificationCenterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationCenterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationCenterHash();

  @$internal
  @override
  NotificationCenter create() => NotificationCenter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationCenterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationCenterState>(value),
    );
  }
}

String _$notificationCenterHash() =>
    r'12139e96f2cc9b57f3e2c68a8b7467c5fb0a83d8';

/// The center across all my teams: the live newest 30 plus older pages
/// loaded by scrolling, merged by ID (ARCH §5.3). The listener runs only
/// while the screen is open (ARCH §10.2).

abstract class _$NotificationCenter extends $Notifier<NotificationCenterState> {
  NotificationCenterState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<NotificationCenterState, NotificationCenterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NotificationCenterState, NotificationCenterState>,
              NotificationCenterState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
