// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_services.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Platform services and build info, overridden in app/providers.dart.
/// Which flavor this build is and whether it talks to the emulators.

@ProviderFor(appEnv)
final appEnvProvider = AppEnvProvider._();

/// Platform services and build info, overridden in app/providers.dart.
/// Which flavor this build is and whether it talks to the emulators.

final class AppEnvProvider extends $FunctionalProvider<AppEnv, AppEnv, AppEnv>
    with $Provider<AppEnv> {
  /// Platform services and build info, overridden in app/providers.dart.
  /// Which flavor this build is and whether it talks to the emulators.
  AppEnvProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appEnvProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appEnvHash();

  @$internal
  @override
  $ProviderElement<AppEnv> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppEnv create(Ref ref) {
    return appEnv(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppEnv value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppEnv>(value),
    );
  }
}

String _$appEnvHash() => r'8cabd7ff805917d2eb9ee00272a3a8d482d125be';

/// The app's version from the platform (pubspec `version`), for the
/// forced-update check.

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

/// The app's version from the platform (pubspec `version`), for the
/// forced-update check.

final class AppVersionProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The app's version from the platform (pubspec `version`), for the
  /// forced-update check.
  AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return appVersion(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$appVersionHash() => r'6751976461937ee18ad2436ed8daa4541b9c7442';

/// The version, build number, and commit, for Settings → About.

@ProviderFor(appBuild)
final appBuildProvider = AppBuildProvider._();

/// The version, build number, and commit, for Settings → About.

final class AppBuildProvider
    extends $FunctionalProvider<AppBuild, AppBuild, AppBuild>
    with $Provider<AppBuild> {
  /// The version, build number, and commit, for Settings → About.
  AppBuildProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appBuildProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appBuildHash();

  @$internal
  @override
  $ProviderElement<AppBuild> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppBuild create(Ref ref) {
    return appBuild(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppBuild value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppBuild>(value),
    );
  }
}

String _$appBuildHash() => r'3ac5982fc238a6c401783146496fc997f57d5045';

/// No-op until bootstrap supplies Firebase Analytics (never in emulator runs).

@ProviderFor(analytics)
final analyticsProvider = AnalyticsProvider._();

/// No-op until bootstrap supplies Firebase Analytics (never in emulator runs).

final class AnalyticsProvider
    extends $FunctionalProvider<Analytics, Analytics, Analytics>
    with $Provider<Analytics> {
  /// No-op until bootstrap supplies Firebase Analytics (never in emulator runs).
  AnalyticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsHash();

  @$internal
  @override
  $ProviderElement<Analytics> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Analytics create(Ref ref) {
    return analytics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Analytics value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Analytics>(value),
    );
  }
}

String _$analyticsHash() => r'5ab907505858d1021f29a8ae144c09c24d46ed6e';

/// Crashlytics on mobile, the logClientError callable on web.

@ProviderFor(crashReporter)
final crashReporterProvider = CrashReporterProvider._();

/// Crashlytics on mobile, the logClientError callable on web.

final class CrashReporterProvider
    extends $FunctionalProvider<CrashReporter, CrashReporter, CrashReporter>
    with $Provider<CrashReporter> {
  /// Crashlytics on mobile, the logClientError callable on web.
  CrashReporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crashReporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crashReporterHash();

  @$internal
  @override
  $ProviderElement<CrashReporter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CrashReporter create(Ref ref) {
    return crashReporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrashReporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrashReporter>(value),
    );
  }
}

String _$crashReporterHash() => r'a9056a74ef5e5d525646f2c563a6dd9a68748301';

/// Feature flags and `min_supported_version`; defaults until fetched.

@ProviderFor(remoteConfig)
final remoteConfigProvider = RemoteConfigProvider._();

/// Feature flags and `min_supported_version`; defaults until fetched.

final class RemoteConfigProvider
    extends $FunctionalProvider<RemoteConfig, RemoteConfig, RemoteConfig>
    with $Provider<RemoteConfig> {
  /// Feature flags and `min_supported_version`; defaults until fetched.
  RemoteConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteConfigHash();

  @$internal
  @override
  $ProviderElement<RemoteConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RemoteConfig create(Ref ref) {
    return remoteConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteConfig>(value),
    );
  }
}

String _$remoteConfigHash() => r'd7b4bf8bfa01cf05266c0e08e2b6a9f45dcf4121';
