import 'dart:developer' as developer;

/// The one logger (ARCH §5.2 rule 9). Never log message content or personal
/// data (SPEC §8.1).
abstract final class Log {
  static void debug(String message) => developer.log(message, name: 'bp');

  static void warn(String message, [Object? error, StackTrace? stack]) =>
      developer.log(
        message,
        name: 'bp',
        level: 900,
        error: error,
        stackTrace: stack,
      );

  static void error(String message, Object error, [StackTrace? stack]) =>
      developer.log(
        message,
        name: 'bp',
        level: 1000,
        error: error,
        stackTrace: stack,
      );
}
