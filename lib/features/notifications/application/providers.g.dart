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
