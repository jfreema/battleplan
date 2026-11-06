import 'package:battleplan/core/constants.g.dart';

/// The last `devices` doc this install wrote: for whom, with which token,
/// and when (NOTIF-10).
typedef DeviceRegistration = ({String uid, String token, DateTime at});

/// A sign-in method waiting to be linked to the account for `email`
/// (AUTH-7): `google.com` or `apple.com`.
typedef PendingLink = ({String providerId, String email});

/// Preferences kept on this device (SPEC SET-2, §5.2 "Memory"). The color
/// schemes are a start-up copy of the account's (users.colorScheme and each
/// membership's pick), so the first frame paints in the right scheme.
abstract interface class LocalPrefsRepository {
  /// Account [uid]'s default color scheme on this device, or this device's
  /// last one while [uid] is null (auth still restoring). Otherwise the old
  /// theme setting's scheme (a one-time carry-over), else Army green.
  TeamScheme defaultScheme({String? uid});

  Future<void> setDefaultScheme(String uid, TeamScheme scheme);

  /// Account [uid]'s pick for [groupId] on this device, or null.
  TeamScheme? teamScheme(String groupId, {String? uid});

  /// Replaces account [uid]'s picks on this device.
  Future<void> setTeamSchemes(String uid, Map<String, TeamScheme> schemes);

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

  /// Whether account [uid] set a password on this device (AUTH-7). Its
  /// `password` method may otherwise be only an emailed sign-in link, so
  /// a fresh sign-in can't simply ask for a password.
  bool passwordSet(String uid);

  Future<void> setPasswordSet(String uid, {required bool value});

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
