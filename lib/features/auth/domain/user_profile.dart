import 'package:battleplan/core/constants.g.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// The Battleplan profile (`users/{uid}`), separate from the sign-in
/// identities in Firebase Auth (AUTH-12, ARCH §6.1).
@freezed
abstract class UserProfile with _$UserProfile {
  const factory({
    required String uid,
    required String displayName,
    required UserStatus status,
    String? email,
    String? photoPath,
    @Default(ThemePreference.dark) ThemePreference themeMode,
    @Default(<String>[]) List<String> signInMethods,
    DateTime? adultConfirmedAt,
    DateTime? acceptedTermsAt,

    /// An admin-added account that signed in by its setup link still has to
    /// choose how to sign in from now on (AUTH-6).
    @Default(false) bool chooseSignIn,

    /// Set by "Sign out of all devices": every session that signed in
    /// before it ends at once (AUTH-9).
    DateTime? sessionsRevokedAt,

    /// The global notification switches that are set (NOTIF-4). A missing
    /// switch is on; use [notifies].
    @Default(<NotificationPref, bool>{})
    Map<NotificationPref, bool> notificationPrefs,
  }) = _UserProfile;

  const new _();

  /// First-run setup (18+ and Terms) is still to do (AUTH-5).
  bool get needsSetup => adultConfirmedAt == null || acceptedTermsAt == null;

  /// Whether the global switch [pref] is on (NOTIF-4). Unset means on.
  bool notifies(NotificationPref pref) => notificationPrefs[pref] ?? true;
}
