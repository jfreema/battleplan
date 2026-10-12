import 'package:battleplan/core/constants.g.dart';

/// Owns `devices` (ARCH §6.5): one doc per app install, keyed by the
/// install's random ID, so the server can push to every signed-in device
/// (NOTIF-10).
abstract interface class DeviceRepository {
  /// Writes this install's doc. It's a blind set, never read first: rules
  /// refuse reading a doc you don't own, and a doc left by an earlier failed
  /// sign-out on this install may belong to someone else.
  Future<void> register(
    String installId, {
    required String uid,
    required String token,
    required DevicePlatform platform,
    required String appVersion,
  });

  /// Deletes this install's doc. Call while still signed in.
  Future<void> remove(String installId);
}
