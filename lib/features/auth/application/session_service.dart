import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/domain/auth_repository.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_service.g.dart';

/// Signing out (AUTH-9) touches two repositories: this device stops getting
/// pushes, then the session ends. Screens call this, never the repositories
/// directly, so the order is always right.
class SessionService {
  const new(this._auth, this._push);

  final AuthRepository _auth;
  final PushRepository _push;

  /// Signs out on this device and stops its push notifications.
  Future<void> signOut() async {
    await _push.unregister();
    await _auth.signOut();
  }

  /// Ends every session for this account (other devices within an hour),
  /// then signs out here.
  Future<void> signOutEverywhere() async {
    await _push.unregister();
    await _auth.signOutEverywhere();
  }
}

@Riverpod(keepAlive: true)
SessionService sessionService(Ref ref) => SessionService(
  ref.watch(authRepositoryProvider),
  ref.watch(pushRepositoryProvider),
);
