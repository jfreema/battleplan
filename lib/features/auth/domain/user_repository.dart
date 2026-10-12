import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/auth/domain/user_profile.dart';

/// Owns `users` (ARCH §5.2). Profiles are created and their protected
/// fields set only by the `ensureUserProfile` callable.
abstract interface class UserRepository {
  /// The profile, or null while it doesn't exist yet.
  Stream<UserProfile?> watchProfile(String uid);

  /// Creates the profile at first sign-in if needed. With [displayName] and
  /// the two confirmations, it also finishes first-run setup (AUTH-5). With
  /// [signInChosen], an added account has chosen how to sign in (AUTH-6).
  Future<void> ensureProfile({
    String? displayName,
    bool finishSetup = false,
    bool signInChosen = false,
  });

  /// Changes the display name shown on every team (SET-1).
  Future<void> updateDisplayName(String uid, String name);

  /// Saves the theme to the account so it follows the person (SET-2).
  Future<void> setThemeMode(String uid, ThemePreference mode);

  /// Turns one global notification switch on or off for every team
  /// (NOTIF-4). The server reads it before each push.
  Future<void> setNotificationPref(
    String uid,
    NotificationPref pref, {
    required bool enabled,
  });

  /// Uploads a new profile photo (JPEG, or PNG from the crop step) and
  /// points the profile at it (SET-1).
  Future<void> uploadPhoto(String uid, Uint8List jpegBytes);

  /// A URL to show a stored photo, or null if it can't be loaded.
  Future<String?> photoUrl(String path);
}
