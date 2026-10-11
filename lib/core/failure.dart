/// The one failure type repositories return (ARCH §5.2 rule 5).
///
/// Firebase exceptions are mapped to these inside `data/` and never leave it.
sealed class AppFailure implements Exception {
  const new([this.message]);

  /// Optional detail for logs. Never shown to users as-is.
  final String? message;

  /// A stable name for logs (runtimeType names are minified on web).
  String get code;

  @override
  String toString() => message == null ? code : '$code: $message';
}

final class NotFound extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'notFound';
}

final class PermissionDenied extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'permissionDenied';
}

final class Offline extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'offline';
}

final class RateLimited extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'rateLimited';
}

final class InvalidInput extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'invalidInput';
}

final class Unauthenticated extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'unauthenticated';
}

final class UnknownFailure extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'unknown';
}
