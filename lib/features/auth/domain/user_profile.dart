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
    @Default(ThemePreference.system) ThemePreference themeMode,
    @Default(<String>[]) List<String> signInMethods,
    DateTime? adultConfirmedAt,
    DateTime? acceptedTermsAt,
  }) = _UserProfile;

  const new _();

  /// First-run setup (18+ and Terms) is still to do (AUTH-5).
  bool get needsSetup => adultConfirmedAt == null || acceptedTermsAt == null;
}
