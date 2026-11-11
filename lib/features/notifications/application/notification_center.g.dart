// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_center.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The center across all my teams, or only [groupId]'s from that team's
/// bell: the live newest 30 plus older pages loaded by scrolling, merged
/// by ID (ARCH §5.3). The listener runs only while the screen is open
/// (ARCH §10.2).

@ProviderFor(NotificationCenter)
final notificationCenterProvider = NotificationCenterFamily._();

/// The center across all my teams, or only [groupId]'s from that team's
/// bell: the live newest 30 plus older pages loaded by scrolling, merged
/// by ID (ARCH §5.3). The listener runs only while the screen is open
/// (ARCH §10.2).
final class NotificationCenterProvider
    extends $NotifierProvider<NotificationCenter, NotificationCenterState> {
  /// The center across all my teams, or only [groupId]'s from that team's
  /// bell: the live newest 30 plus older pages loaded by scrolling, merged
  /// by ID (ARCH §5.3). The listener runs only while the screen is open
  /// (ARCH §10.2).
  NotificationCenterProvider._({
    required NotificationCenterFamily super.from,
    required GroupId? super.argument,
  }) : super(
         retry: null,
         name: r'notificationCenterProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$notificationCenterHash();

  @override
  String toString() {
    return r'notificationCenterProvider'
        ''
        '($argument)';
  }

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

  @override
  bool operator ==(Object other) {
    return other is NotificationCenterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$notificationCenterHash() =>
    r'b05c71fdd10424796439ec197af35901d110b1c9';

/// The center across all my teams, or only [groupId]'s from that team's
/// bell: the live newest 30 plus older pages loaded by scrolling, merged
/// by ID (ARCH §5.3). The listener runs only while the screen is open
/// (ARCH §10.2).

final class NotificationCenterFamily extends $Family
    with
        $ClassFamilyOverride<
          NotificationCenter,
          NotificationCenterState,
          NotificationCenterState,
          NotificationCenterState,
          GroupId?
        > {
  NotificationCenterFamily._()
    : super(
        retry: null,
        name: r'notificationCenterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The center across all my teams, or only [groupId]'s from that team's
  /// bell: the live newest 30 plus older pages loaded by scrolling, merged
  /// by ID (ARCH §5.3). The listener runs only while the screen is open
  /// (ARCH §10.2).

  NotificationCenterProvider call({GroupId? groupId}) =>
      NotificationCenterProvider._(argument: groupId, from: this);

  @override
  String toString() => r'notificationCenterProvider';
}

/// The center across all my teams, or only [groupId]'s from that team's
/// bell: the live newest 30 plus older pages loaded by scrolling, merged
/// by ID (ARCH §5.3). The listener runs only while the screen is open
/// (ARCH §10.2).

abstract class _$NotificationCenter extends $Notifier<NotificationCenterState> {
  late final _$args = ref.$arg as GroupId?;
  GroupId? get groupId => _$args;

  NotificationCenterState build({GroupId? groupId});
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
    return element.handleCreate(ref, () => build(groupId: _$args));
  }
}
