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

/// The browser blocked a sign-in popup (AUTH-1 edge cases).
final class PopupBlocked extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'popupBlocked';
}

/// The email already has an account that signs in another way. Linking it
/// safely arrives with AUTH-7 (M1).
final class AccountExistsWithOtherMethod extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'accountExistsWithOtherMethod';
}

/// Creating an account with an email that already has one (AUTH-2).
final class EmailAlreadyInUse extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'emailAlreadyInUse';
}

/// A password that doesn't meet the policy (8+ characters, AUTH-2).
final class WeakPassword extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'weakPassword';
}

final class UnknownFailure extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'unknown';
}
