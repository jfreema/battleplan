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

/// The action needs a fresh sign-in first (AUTH-7): linking, unlinking,
/// changing the email or password, and deleting the account.
final class RequiresRecentLogin extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'requiresRecentLogin';
}

/// The sign-in method is already linked to another Battleplan account.
/// Two accounts are never merged automatically (AUTH-7).
final class CredentialInUse extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'credentialInUse';
}

/// The action needs a verified email first (AUTH-3): creating teams,
/// sending email invites, adding people by email.
final class EmailNotVerified extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'emailNotVerified';
}

/// A person can be on up to 100 teams (TEAM-2).
final class TooManyTeams extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'tooManyTeams';
}

/// The owner must hand the team to someone else before leaving (TEAM-8).
final class OwnerMustTransfer extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'ownerMustTransfer';
}

/// An invite code that can't be used; [reason] is one of the INV-8 cases
/// (unknown, expired, revoked, used-up, wrong-email).
final class InviteUnusable extends AppFailure {
  const new(this.reason, [super.message]);

  final String reason;

  @override
  String get code => 'inviteUnusable';
}

final class UnknownFailure extends AppFailure {
  const new([super.message]);

  @override
  String get code => 'unknown';
}
