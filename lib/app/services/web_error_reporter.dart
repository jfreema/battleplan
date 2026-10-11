import 'dart:math';

import 'package:battleplan/core/logging.dart';
import 'package:battleplan/core/services/crash_reporter.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Crashlytics doesn't support web, so web errors go to the `logClientError`
/// callable, sampled, which writes them to Cloud Logging (ARCH §9).
class WebErrorReporter implements CrashReporter {
  new(this._functions, {this.appVersion = '', this.sampleRate = 0.2});

  final FirebaseFunctions _functions;
  final String appVersion;
  final double sampleRate;
  final _random = Random();
  int _sentThisSession = 0;

  static const _maxPerSession = 20;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    if (!fatal && _random.nextDouble() > sampleRate) return;
    if (_sentThisSession >= _maxPerSession) return;
    _sentThisSession++;
    try {
      await _functions.httpsCallable('logClientError').call<void>({
        'message': error.toString().truncate(500),
        'stack': (stack?.toString() ?? '').truncate(4000),
        'fatal': fatal,
        'appVersion': appVersion,
      });
    } on Object catch (e) {
      Log.warn('logClientError failed', e);
    }
  }

  @override
  Future<void> setUserId(String? uid) async {}
}

extension on String {
  String truncate(int max) => length <= max ? this : substring(0, max);
}
