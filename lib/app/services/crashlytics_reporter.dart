import 'package:battleplan/core/services/crash_reporter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Crashlytics, on iOS and Android only (ARCH §9).
class CrashlyticsReporter implements CrashReporter {
  new(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) => _crashlytics.recordError(error, stack, fatal: fatal);

  @override
  Future<void> setUserId(String? uid) =>
      _crashlytics.setUserIdentifier(uid ?? '');
}
