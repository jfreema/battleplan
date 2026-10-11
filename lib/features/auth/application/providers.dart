import 'package:battleplan/features/auth/domain/auth_repository.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

@Riverpod(keepAlive: true)
Stream<AuthUser?> authUser(Ref ref) =>
    ref.watch(authRepositoryProvider).watchUser();
