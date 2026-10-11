// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(localPrefsRepository)
final localPrefsRepositoryProvider = LocalPrefsRepositoryProvider._();

/// Overridden in app/providers.dart.

final class LocalPrefsRepositoryProvider
    extends
        $FunctionalProvider<
          LocalPrefsRepository,
          LocalPrefsRepository,
          LocalPrefsRepository
        >
    with $Provider<LocalPrefsRepository> {
  /// Overridden in app/providers.dart.
  LocalPrefsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localPrefsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localPrefsRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocalPrefsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalPrefsRepository create(Ref ref) {
    return localPrefsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalPrefsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalPrefsRepository>(value),
    );
  }
}

String _$localPrefsRepositoryHash() =>
    r'4bd3d9bebc93b9482537a6972a87c46ccf5a2e65';

/// System, light, or dark (SPEC SET-2). Applies instantly and is remembered.

@ProviderFor(ThemePreferenceController)
final themePreferenceControllerProvider = ThemePreferenceControllerProvider._();

/// System, light, or dark (SPEC SET-2). Applies instantly and is remembered.
final class ThemePreferenceControllerProvider
    extends $NotifierProvider<ThemePreferenceController, ThemePreference> {
  /// System, light, or dark (SPEC SET-2). Applies instantly and is remembered.
  ThemePreferenceControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themePreferenceControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themePreferenceControllerHash();

  @$internal
  @override
  ThemePreferenceController create() => ThemePreferenceController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemePreference value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemePreference>(value),
    );
  }
}

String _$themePreferenceControllerHash() =>
    r'cf344abfdb50e65648d1de154dec5e06000102d6';

/// System, light, or dark (SPEC SET-2). Applies instantly and is remembered.

abstract class _$ThemePreferenceController extends $Notifier<ThemePreference> {
  ThemePreference build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemePreference, ThemePreference>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemePreference, ThemePreference>,
              ThemePreference,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
