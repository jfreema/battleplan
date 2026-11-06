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

/// My default color scheme (SET-2): this device's copy at once, then the
/// account's, which wins (another device may have changed it). The profile is
/// watched, not listened to, so a profile that loaded before this provider was
/// first read still counts.

@ProviderFor(DefaultSchemeController)
final defaultSchemeControllerProvider = DefaultSchemeControllerProvider._();

/// My default color scheme (SET-2): this device's copy at once, then the
/// account's, which wins (another device may have changed it). The profile is
/// watched, not listened to, so a profile that loaded before this provider was
/// first read still counts.
final class DefaultSchemeControllerProvider
    extends $NotifierProvider<DefaultSchemeController, TeamScheme> {
  /// My default color scheme (SET-2): this device's copy at once, then the
  /// account's, which wins (another device may have changed it). The profile is
  /// watched, not listened to, so a profile that loaded before this provider was
  /// first read still counts.
  DefaultSchemeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultSchemeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$defaultSchemeControllerHash();

  @$internal
  @override
  DefaultSchemeController create() => DefaultSchemeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamScheme value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamScheme>(value),
    );
  }
}

String _$defaultSchemeControllerHash() =>
    r'0377f6e13322fe62ce760b7a11668419619e1ab5';

/// My default color scheme (SET-2): this device's copy at once, then the
/// account's, which wins (another device may have changed it). The profile is
/// watched, not listened to, so a profile that loaded before this provider was
/// first read still counts.

abstract class _$DefaultSchemeController extends $Notifier<TeamScheme> {
  TeamScheme build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TeamScheme, TeamScheme>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TeamScheme, TeamScheme>,
              TeamScheme,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The scheme outside a team: Army green signed out, else my default.

@ProviderFor(appScheme)
final appSchemeProvider = AppSchemeProvider._();

/// The scheme outside a team: Army green signed out, else my default.

final class AppSchemeProvider
    extends $FunctionalProvider<TeamScheme, TeamScheme, TeamScheme>
    with $Provider<TeamScheme> {
  /// The scheme outside a team: Army green signed out, else my default.
  AppSchemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSchemeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSchemeHash();

  @$internal
  @override
  $ProviderElement<TeamScheme> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamScheme create(Ref ref) {
    return appScheme(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamScheme value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamScheme>(value),
    );
  }
}

String _$appSchemeHash() => r'bb3997be2386881a2761105ca5cdd3cd836b6eec';

/// The scheme I see [groupId] in: my pick on my membership, else my default.

@ProviderFor(teamScheme)
final teamSchemeProvider = TeamSchemeFamily._();

/// The scheme I see [groupId] in: my pick on my membership, else my default.

final class TeamSchemeProvider
    extends $FunctionalProvider<TeamScheme, TeamScheme, TeamScheme>
    with $Provider<TeamScheme> {
  /// The scheme I see [groupId] in: my pick on my membership, else my default.
  TeamSchemeProvider._({
    required TeamSchemeFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'teamSchemeProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamSchemeHash();

  @override
  String toString() {
    return r'teamSchemeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TeamScheme> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamScheme create(Ref ref) {
    final argument = this.argument as GroupId;
    return teamScheme(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamScheme value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamScheme>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeamSchemeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamSchemeHash() => r'7aec7d1037c2c871b778895c7a4ee9770111b765';

/// The scheme I see [groupId] in: my pick on my membership, else my default.

final class TeamSchemeFamily extends $Family
    with $FunctionalFamilyOverride<TeamScheme, GroupId> {
  TeamSchemeFamily._()
    : super(
        retry: null,
        name: r'teamSchemeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The scheme I see [groupId] in: my pick on my membership, else my default.

  TeamSchemeProvider call(GroupId groupId) =>
      TeamSchemeProvider._(argument: groupId, from: this);

  @override
  String toString() => r'teamSchemeProvider';
}

/// Keeps this device's copy of my team picks current (for [teamScheme] on
/// a cold start): watched at the app root.

@ProviderFor(teamSchemeCache)
final teamSchemeCacheProvider = TeamSchemeCacheProvider._();

/// Keeps this device's copy of my team picks current (for [teamScheme] on
/// a cold start): watched at the app root.

final class TeamSchemeCacheProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Keeps this device's copy of my team picks current (for [teamScheme] on
  /// a cold start): watched at the app root.
  TeamSchemeCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamSchemeCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamSchemeCacheHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return teamSchemeCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$teamSchemeCacheHash() => r'06e823181a687824339386e0dd41df32e7d7fe4e';
