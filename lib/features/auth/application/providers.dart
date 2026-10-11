import 'package:battleplan/features/auth/domain/auth_repository.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/auth/domain/user_profile.dart';
import 'package:battleplan/features/auth/domain/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// The signed-in user, or null. The router and most screens watch this.
@Riverpod(keepAlive: true)
Stream<AuthUser?> authUser(Ref ref) =>
    ref.watch(authRepositoryProvider).watchUser();

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// The signed-in person's Battleplan profile. Creating it at first sign-in
/// is idempotent, so it's requested whenever the signed-in user changes.
@Riverpod(keepAlive: true)
Stream<UserProfile?> myProfile(Ref ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return Stream.value(null);
  final repo = ref.watch(userRepositoryProvider);
  // Fire and forget: the stream below emits once the profile exists.
  repo.ensureProfile().ignore();
  return repo.watchProfile(user.uid);
}

/// A URL for the signed-in person's profile photo, or null.
@riverpod
Future<String?> myPhotoUrl(Ref ref) async {
  final path = ref.watch(myProfileProvider).value?.photoPath;
  if (path == null) return null;
  return await ref.watch(userRepositoryProvider).photoUrl(path);
}
