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

  /// Saves the default color scheme (SET-2): the top screens' and every
  /// team or group not picked for.
  Future<void> setColorScheme(String uid, TeamScheme scheme);

  /// Saves the candy color behind the icon's initials (SET-8).
  Future<void> setAvatarColor(String uid, AvatarColor color);

  /// Saves the time zone times show in (SET-7), on every device; null is
  /// Automatic, the device's zone.
  Future<void> setTimeZone(String uid, String? zone);

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

  /// Takes the profile photo away, so the icon shows initials (SET-8),
  /// and deletes the file.
  Future<void> removePhoto(String uid);

  /// A URL to show a stored photo, or null if it can't be loaded.
  Future<String?> photoUrl(String path);
}
