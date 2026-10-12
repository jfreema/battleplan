import 'package:battleplan/core/constants.g.dart';

/// The last `devices` doc this install wrote: for whom, with which token,
/// and when (NOTIF-10).
typedef DeviceRegistration = ({String uid, String token, DateTime at});

/// A sign-in method waiting to be linked to the account for `email`
/// (AUTH-7): `google.com` or `apple.com`.
typedef PendingLink = ({String providerId, String email});

/// Preferences kept on this device (SPEC SET-2, §5.2 "Memory"). The theme
/// also syncs to the profile once `users` exists (M1).
abstract interface class LocalPrefsRepository {
  ThemePreference get themePreference;

  Future<void> setThemePreference(ThemePreference value);

  /// The last team and tab used on this device, as a route like
  /// `/g/abc/schedule`.
  String? get lastTeamRoute;

  Future<void> setLastTeamRoute(String route);

  /// The email a sign-in link was just sent to, so opening the link on this
  /// device can finish without asking again. Cleared after use.
  String? get pendingSignInEmail;

  Future<void> setPendingSignInEmail(String? email);

  /// A sign-in method to link once the emailed link proves the email
  /// (AUTH-7): someone tried Google or Apple with an email that already has
  /// an account. Cleared once linked or declined.
  PendingLink? get pendingLink;

  Future<void> setPendingLink(PendingLink? value);

  /// A random ID for this app install, made on first use and kept: the
  /// install's `devices` doc ID (ARCH §6.5). Never tied to a person.
  String get installId;

  /// Whether the notification pre-prompt (or the iOS Safari tip) has been
  /// shown on this install. It's shown at most once (NOTIF-1).
  bool get pushPrePromptShown;

  Future<void> setPushPrePromptShown();

  /// Lets the app rewrite its device doc at most daily on start, and always
  /// for a new person or token. Cleared at sign-out.
  DeviceRegistration? get deviceRegistration;

  Future<void> setDeviceRegistration(DeviceRegistration? value);
}
