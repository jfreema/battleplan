import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// The signed-in identity. The Battleplan profile (`users/{uid}`) is separate
/// and arrives in M1 (ARCH §6.1).
@freezed
abstract class AuthUser with _$AuthUser {
  const factory({
    required String uid,
    required bool emailVerified,
    String? email,
    String? displayName,
    @Default(false) bool isSuperAdmin,
  }) = _AuthUser;
}
