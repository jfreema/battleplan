import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:battleplan/features/players/domain/player_repository.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/rsvp_history.dart';
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

/// The signed-in person's own claims on a team (PLAYER-3).
@riverpod
Stream<List<GuardianRequest>> myGuardianRequests(Ref ref, GroupId groupId) {
  final uid = ref.watch(authUserProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref
      .watch(playerRepositoryProvider)
      .watchMyRequests(groupId, UserId(uid));
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
