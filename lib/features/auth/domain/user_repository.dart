import 'package:battleplan/features/auth/domain/user_profile.dart';

/// Owns `users` (ARCH §5.2). Profiles are created and their protected
/// fields set only by the `ensureUserProfile` callable.
abstract interface class UserRepository {
  /// The profile, or null while it doesn't exist yet.
  Stream<UserProfile?> watchProfile(String uid);

  /// Creates the profile at first sign-in if needed. With [displayName] and
  /// the two confirmations, it also finishes first-run setup (AUTH-5).
  Future<void> ensureProfile({String? displayName, bool finishSetup = false});
}
