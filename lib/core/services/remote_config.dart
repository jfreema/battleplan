/// Feature flags and the forced-update floor (ARCH §9).
abstract interface class RemoteConfig {
  /// Fetches and activates the latest values. Failures keep the defaults.
  Future<void> refresh();

  /// The oldest app version still allowed to run, e.g. "1.0.0".
  String get minSupportedVersion;
}

class DefaultRemoteConfig implements RemoteConfig {
  const new();

  @override
  Future<void> refresh() async {}

  @override
  String get minSupportedVersion => '0.0.0';
}
