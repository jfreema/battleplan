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

    /// Linked sign-in methods: `password`, `google.com`, `apple.com`.
    @Default(<String>[]) List<String> providerIds,
  }) = _AuthUser;
}
