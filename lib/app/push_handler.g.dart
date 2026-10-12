// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pushes the person taps, and pushes that arrive while the app is open
/// (NOTIF-6, NOTIF-7, ARCH §6.5 "In the app"). In app/ because it drives
/// the router. Started from app.dart.

@ProviderFor(PushHandler)
final pushHandlerProvider = PushHandlerProvider._();

/// Pushes the person taps, and pushes that arrive while the app is open
/// (NOTIF-6, NOTIF-7, ARCH §6.5 "In the app"). In app/ because it drives
/// the router. Started from app.dart.
final class PushHandlerProvider extends $NotifierProvider<PushHandler, void> {
  /// Pushes the person taps, and pushes that arrive while the app is open
  /// (NOTIF-6, NOTIF-7, ARCH §6.5 "In the app"). In app/ because it drives
  /// the router. Started from app.dart.
  PushHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushHandlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushHandlerHash();

  @$internal
  @override
  PushHandler create() => PushHandler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pushHandlerHash() => r'caf9ab5e6de47225a6e127b2975351b7deea0bfe';

/// Pushes the person taps, and pushes that arrive while the app is open
/// (NOTIF-6, NOTIF-7, ARCH §6.5 "In the app"). In app/ because it drives
/// the router. Started from app.dart.

abstract class _$PushHandler extends $Notifier<void> {
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
