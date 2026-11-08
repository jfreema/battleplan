import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/settings/domain/local_prefs_repository.dart';
import 'package:flutter/foundation.dart';
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

/// The scheme a member sees a team in (SET-2, owner's request 2026-11-08):
/// their own explicit [pick], else the team's [teamDefault] its admins set,
/// else their own default [mine].
TeamScheme resolveTeamScheme({
  required TeamScheme? pick,
  required TeamScheme? teamDefault,
  required TeamScheme mine,
}) => pick ?? teamDefault ?? mine;

/// The scheme I see [groupId] in ([resolveTeamScheme]): my pick on my
/// membership, else the team's default, else my default. The team is read
/// only while I'm on it, through the read my teams already keep
/// (myTeams), so this provider (kept for the session) keeps no reads of a
/// team I've left or only viewed: a super admin viewing a team they
/// aren't on sees it in their default.
@Riverpod(keepAlive: true)
TeamScheme teamScheme(Ref ref, GroupId groupId) {
  final (loaded, member, pick) = ref.watch(
    myMembershipsProvider.select((a) {
      final list = a.value;
      if (list == null) return (false, false, null);
      final mine = list.where((m) => m.groupId == groupId).firstOrNull;
      return (true, mine != null, mine?.colorScheme);
    }),
  );
  final fallback = ref.watch(defaultSchemeControllerProvider);
  if (loaded && !member) return fallback;
  if (loaded && pick != null) return pick;
  if (loaded) {
    final (teamLoaded, teamDefault) = ref.watch(
      groupProvider(groupId).select((a) => (a.hasValue, a.value?.colorScheme)),
    );
    if (teamLoaded) {
      return resolveTeamScheme(
        pick: null,
        teamDefault: teamDefault,
        mine: fallback,
      );
    }
  }
  // Still loading: this device's last copy, so a cold start into a team
  // paints in the right scheme on its first frame.
  final uid = ref.watch(authUserProvider.select((a) => a.value?.uid));
  return ref
          .watch(localPrefsRepositoryProvider)
          .teamScheme(groupId.value, uid: uid) ??
      fallback;
}

/// Keeps this device's copy of how I see my teams current (for
/// [teamScheme] on a cold start): my pick, else the team's default, for
/// each team that has one. Watched at the app root.
@Riverpod(keepAlive: true)
void teamSchemeCache(Ref ref) {
  // Written only when it changes: my teams change with every new message.
  Map<String, TeamScheme>? last;
  ref.listen(myTeamsProvider, (_, next) {
    final uid = ref.read(authUserProvider).value?.uid;
    final list = next.value;
    if (uid == null || list == null) return;
    final schemes = {
      for (final t in list)
        t.group.id.value: ?(t.membership.colorScheme ?? t.group.colorScheme),
    };
    if (last != null && mapEquals(last, schemes)) return;
    last = schemes;
    unawaited(
      ref.read(localPrefsRepositoryProvider).setTeamSchemes(uid, schemes),
    );
  }, fireImmediately: true);
}
