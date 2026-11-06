import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/settings/domain/local_prefs_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
LocalPrefsRepository localPrefsRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// My default color scheme (SET-2): this device's copy at once, then the
/// account's, which wins (another device may have changed it). The profile is
/// watched, not listened to, so a profile that loaded before this provider was
/// first read still counts.
@Riverpod(keepAlive: true)
class DefaultSchemeController extends _$DefaultSchemeController {
  @override
  TeamScheme build() {
    final uid = ref.watch(authUserProvider.select((a) => a.value?.uid));
    final prefs = ref.watch(localPrefsRepositoryProvider);
    final local = prefs.defaultScheme(uid: uid);
    // Only the signed-in account's profile: right after a switch, the
    // previous one may still be the last value.
    final synced = ref.watch(
      myProfileProvider.select(
        (p) => p.value?.uid == uid ? p.value?.defaultScheme : null,
      ),
    );
    if (uid != null && synced != null && synced != local) {
      unawaited(prefs.setDefaultScheme(uid, synced));
    }
    return synced ?? local;
  }

  /// Applies at once, is remembered on this device, and syncs to
  /// users.colorScheme. The profile stream then carries the same value; if
  /// the write fails, the old value comes back and the error is rethrown.
  Future<void> set(TeamScheme value) async {
    final old = state;
    if (value == old) return;
    state = value;
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final prefs = ref.read(localPrefsRepositoryProvider);
    await prefs.setDefaultScheme(uid, value);
    try {
      await ref.read(userRepositoryProvider).setColorScheme(uid, value);
    } on Object catch (e) {
      Log.warn('Color scheme sync failed', e);
      if (ref.mounted) state = old;
      await prefs.setDefaultScheme(uid, old);
      rethrow;
    }
  }
}

/// The scheme outside a team: Army green signed out, else my default.
@Riverpod(keepAlive: true)
TeamScheme appScheme(Ref ref) {
  // Watched always and first, so the controller exists from the first frame.
  final mine = ref.watch(defaultSchemeControllerProvider);
  final auth = ref.watch(authUserProvider);
  // Army green only once auth has loaded with nobody signed in. While it
  // restores, `mine` is the cached default, so a cold start doesn't flash.
  return auth.hasValue && auth.value == null ? TeamScheme.army : mine;
}

/// The scheme I see [groupId] in: my pick on my membership, else my default.
/// Read from my memberships alone, never the team itself, so this provider
/// (kept for the session) keeps no reads of a team I've left or only
/// viewed.
@Riverpod(keepAlive: true)
TeamScheme teamScheme(Ref ref, GroupId groupId) {
  final (loaded, pick) = ref.watch(
    myMembershipsProvider.select((a) {
      final list = a.value;
      if (list == null) return (false, null);
      final mine = list.where((m) => m.groupId == groupId).firstOrNull;
      return (true, mine?.colorScheme);
    }),
  );
  final fallback = ref.watch(defaultSchemeControllerProvider);
  if (loaded) return pick ?? fallback;
  // Memberships still loading: this device's last copy, so a cold start into
  // a team paints in the right scheme on its first frame.
  final uid = ref.watch(authUserProvider.select((a) => a.value?.uid));
  return ref
          .watch(localPrefsRepositoryProvider)
          .teamScheme(groupId.value, uid: uid) ??
      fallback;
}

/// Keeps this device's copy of my team picks current (for [teamScheme] on
/// a cold start): watched at the app root.
@Riverpod(keepAlive: true)
void teamSchemeCache(Ref ref) {
  ref.listen(myMembershipsProvider, (_, next) {
    final uid = ref.read(authUserProvider).value?.uid;
    final list = next.value;
    if (uid == null || list == null) return;
    unawaited(
      ref.read(localPrefsRepositoryProvider).setTeamSchemes(uid, {
        for (final m in list) m.groupId.value: ?m.colorScheme,
      }),
    );
  }, fireImmediately: true);
}
