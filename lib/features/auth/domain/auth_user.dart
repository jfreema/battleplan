import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// The signed-in identity. The Battleplan profile (`users/{uid}`) is
/// separate (ARCH §6.1, `UserProfile`).
@freezed
abstract class AuthUser with _$AuthUser {
  const factory({
    required String uid,
    required bool emailVerified,
    String? email,
    String? displayName,
    @Default(false) bool isSuperAdmin,

    /// Linked sign-in methods: `password`, `google.com`, `apple.com`. An
    /// emailed sign-in link also adds `password`, with no password behind
    /// it (AUTH-6).
    @Default(<String>[]) List<String> providerIds,

    /// How this session signed in, from the ID token: `password`,
    /// `emailLink`, `google.com`, or `apple.com`. `password` means the
    /// account really has a password (AUTH-7).
    String? signInProvider,

    /// When this device's session signed in (the ID token's auth_time).
    /// "Sign out of all devices" ends sessions older than that (AUTH-9),
    /// and method changes need it to be recent (AUTH-7).
    DateTime? authTime,
  }) = _AuthUser;
}
