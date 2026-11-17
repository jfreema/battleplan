import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:battleplan/features/players/domain/player_repository.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/rsvp_history.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
PlayerRepository playerRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// Players by jersey number, then name (TEAM-3).
List<Player> sortPlayers(Iterable<Player> list) {
  int number(Player p) => int.tryParse(p.jerseyNumber ?? '') ?? 1 << 20;
  return [...list]..sort((a, b) {
    final byNumber = number(a).compareTo(number(b));
    return byNumber != 0
        ? byNumber
        : a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
}

/// A team's active players, by jersey number then name (TEAM-3). Every
/// team has them.
@riverpod
Stream<List<Player>> players(Ref ref, GroupId groupId) =>
    ref.watch(playerRepositoryProvider).watchPlayers(groupId).map(sortPlayers);

/// A team's pending players (PLAYER-4). Only admins can read them all.
@riverpod
Stream<List<Player>> pendingPlayers(Ref ref, GroupId groupId) => ref
    .watch(playerRepositoryProvider)
    .watchPendingPlayers(groupId)
    .map(sortPlayers);

/// The pending players the signed-in person added (PLAYER-4).
@riverpod
Stream<List<Player>> myPendingPlayers(Ref ref, GroupId groupId) {
  final uid = ref.watch(authUserProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref
      .watch(playerRepositoryProvider)
      .watchMyPendingPlayers(groupId, UserId(uid))
      .map(sortPlayers);
}

/// A team's player links, as the player or a guardian.
@riverpod
Stream<List<GuardianLink>> guardianLinks(Ref ref, GroupId groupId) =>
    ref.watch(playerRepositoryProvider).watchGuardianLinks(groupId);

/// A team's pending claims (PLAYER-4). Only admins can read them.
@riverpod
Stream<List<GuardianRequest>> pendingGuardianRequests(
  Ref ref,
  GroupId groupId,
) => ref.watch(playerRepositoryProvider).watchPendingRequests(groupId);

/// How many requests wait for [groupId]'s admins (PLAYER-4, #23): its
/// pending players and claims, for the Team tab's count and the Teams
/// card's line. Zero for everyone else, a super admin viewing the team
/// included, and on a group, which has no players (TEAM-14), so nobody
/// else's app listens.
@riverpod
int pendingRequestCount(Ref ref, GroupId groupId) {
  final admin = ref.watch(
    myMembershipProvider(groupId).select((m) => m?.isAdmin ?? false),
  );
  if (!admin) return 0;
  final hasPlayers = ref.watch(
    groupProvider(groupId).select((g) => g.value?.hasPlayers ?? false),
  );
  if (!hasPlayers) return 0;
  final players = ref.watch(pendingPlayersProvider(groupId)).value;
  final claims = ref.watch(pendingGuardianRequestsProvider(groupId)).value;
  return (players?.length ?? 0) + (claims?.length ?? 0);
}

/// The signed-in person's own claims on a team (PLAYER-3).
@riverpod
Stream<List<GuardianRequest>> myGuardianRequests(Ref ref, GroupId groupId) {
  final uid = ref.watch(authUserProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref
      .watch(playerRepositoryProvider)
      .watchMyRequests(groupId, UserId(uid));
}

/// Whether the signed-in person is someone the "Who are you here for?"
/// prompts could be for on [groupId] (PLAYER-3): a member of a team with
/// players who doesn't manage it. Null until the team is known. Team
/// admins link at once and answer for anyone, as super admins do on any
/// team (SCHED-4), and a group has no players (TEAM-14).
bool? _mayPickAPlayer(Ref ref, GroupId groupId) {
  // Only what this needs of the team, whose document changes with every
  // message.
  final hasPlayers = ref.watch(
    groupProvider(groupId).select((g) => g.value?.hasPlayers),
  );
  if (hasPlayers == null) return null;
  final me = ref.watch(myMembershipProvider(groupId));
  final superAdmin = ref.watch(
    authUserProvider.select((a) => a.value?.isSuperAdmin ?? false),
  );
  return hasPlayers && me != null && !me.isAdmin && !superAdmin;
}

/// Where the signed-in person stands on "Who are you here for?" on
/// [groupId] (PLAYER-3), for every prompt that leads there, so they agree:
/// the chat's card, the schedule's cards, the event page, the Team tab,
/// and Dues. Nothing ([PlayerPickStage.none]) until the team's links,
/// their own claims, and the roster have loaded, so a prompt never shows
/// and then goes or changes its words. Their claims and the players they
/// added are read only while they're not linked to anyone.
@riverpod
PlayerPick myPlayerPick(Ref ref, GroupId groupId) {
  if (!(_mayPickAPlayer(ref, groupId) ?? false)) return const PlayerPick();
  final me = ref.watch(myMembershipProvider(groupId));
  if (me == null) return const PlayerPick();
  // Without the team's links there's no telling whether they're linked.
  final links = ref.watch(guardianLinksProvider(groupId));
  if (!links.hasValue) return const PlayerPick();
  if (links.requireValue.any((l) => l.uid == me.uid)) {
    return const PlayerPick();
  }
  // Their claims, the players they added, and the roster, which names who
  // a claim is for. All three first, so the wording never changes under
  // them; one that fails counts as empty, and the prompts still offer the
  // screen.
  final requests = ref.watch(myGuardianRequestsProvider(groupId));
  final pending = ref.watch(myPendingPlayersProvider(groupId));
  final players = ref.watch(playersProvider(groupId));
  if (_firstLoad(requests) || _firstLoad(pending) || _firstLoad(players)) {
    return const PlayerPick();
  }
  return playerPickOf(
    me: me,
    archived: ref.watch(
      groupProvider(groupId).select((g) => g.value?.isArchived ?? false),
    ),
    links: links.requireValue,
    requests: requests.value ?? const [],
    pendingPlayers: pending.value ?? const [],
    players: players.value ?? const [],
  );
}

/// Whether [value] is still on its first load: nothing to show yet, and
/// nothing has failed.
bool _firstLoad(AsyncValue<Object?> value) =>
    value.isLoading && !value.hasValue;

/// Whether [myPlayerPick] is final for [groupId]: what it reads has
/// arrived (or failed). Lets a card wait for its line rather than grow it
/// a moment later, as with [myParticipantsReadyProvider].
@riverpod
bool myPlayerPickReady(Ref ref, GroupId groupId) {
  final may = _mayPickAPlayer(ref, groupId);
  if (may == null) return false;
  if (!may) return true;
  final me = ref.watch(myMembershipProvider(groupId));
  final links = ref.watch(guardianLinksProvider(groupId));
  if (links.isLoading) return false;
  if (links.value?.any((l) => l.uid == me?.uid) ?? true) return true;
  return !ref.watch(myGuardianRequestsProvider(groupId)).isLoading &&
      !ref.watch(myPendingPlayersProvider(groupId)).isLoading &&
      !ref.watch(playersProvider(groupId)).isLoading;
}

/// A player's answers on the team's events from yesterday on, by event ID,
/// for the player card's upcoming RSVPs (PLAYER-2).
@riverpod
Stream<Map<String, Rsvp>> playerRsvps(
  Ref ref,
  GroupId groupId,
  PlayerId playerId,
) => ref
    .watch(rsvpRepositoryProvider)
    .watchMine(groupId, [
      playerId.value,
    ], from: DateTime.now().subtract(const Duration(days: 1)))
    .map((list) => {for (final r in list) r.eventId.value: r});

/// A player's RSVP history (PLAYER-11): the team's events that took RSVPs
/// and started in [from, until), since the player was added, newest first,
/// with the player's answers (live), for the player's linked members and
/// the team's admins.
@riverpod
AsyncValue<RsvpHistory> playerRsvpHistory(
  Ref ref,
  GroupId groupId,
  PlayerId playerId,
  DateTime from,
  DateTime until,
) {
  final events = ref.watch(eventsBetweenProvider(groupId, from, until));
  final answers = ref.watch(
    _playerAnswersProvider(groupId, playerId, from, until),
  );
  if (events.hasError) {
    return AsyncError(events.error!, events.stackTrace ?? StackTrace.current);
  }
  if (!events.hasValue || !answers.hasValue) return const AsyncLoading();
  final player = ref
      .watch(playersProvider(groupId))
      .value
      ?.where((p) => p.id == playerId)
      .firstOrNull;
  return AsyncData(
    rsvpHistoryOf(
      events: events.requireValue,
      answers: answers.requireValue,
      now: until,
      since: player?.addedAt,
    ),
  );
}

/// A player's answers on events starting in [from, until), by event ID.
@riverpod
Stream<Map<String, Rsvp>> _playerAnswers(
  Ref ref,
  GroupId groupId,
  PlayerId playerId,
  DateTime from,
  DateTime until,
) => ref
    .watch(rsvpRepositoryProvider)
    .watchMine(groupId, [playerId.value], from: from, until: until)
    .map((list) => {for (final r in list) r.eventId.value: r});

/// A player's details (PLAYER-12). Watched only for the team's admins and
/// the members linked to the player ([seesPlayerDetails]): nobody else's
/// app asks for them.
@riverpod
Stream<PlayerDetails?> playerDetails(Ref ref, PlayerId playerId) =>
    ref.watch(playerRepositoryProvider).watchPlayerDetails(playerId);

/// A team's player details by player ID, for ages on the roster
/// (PLAYER-12). One list for the whole team, watched only for its admins.
@riverpod
Stream<Map<PlayerId, PlayerDetails>> teamPlayerDetails(
  Ref ref,
  GroupId groupId,
) => ref
    .watch(playerRepositoryProvider)
    .watchTeamPlayerDetails(groupId)
    .map((list) => {for (final d in list) d.playerId: d});
