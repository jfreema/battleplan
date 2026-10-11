/// Crash and error reporting (ARCH §9): Crashlytics on iOS and Android, the
/// `logClientError` callable on web.
abstract interface class CrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  });

  Future<void> setUserId(String? uid);
}

class NoopCrashReporter implements CrashReporter {
  const new();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {}

  @override
  Future<void> setUserId(String? uid) async {}
}
