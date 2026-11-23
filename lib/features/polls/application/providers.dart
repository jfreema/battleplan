import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/polls/domain/poll_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
PollRepository pollRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// A poll, live (POLL-2). Null once it's deleted.
@riverpod
Stream<Poll?> poll(Ref ref, PollId pollId) =>
    ref.watch(pollRepositoryProvider).watchPoll(pollId);

/// My choices on a poll, live, including a vote still on its way.
@riverpod
Stream<Set<String>> myPollVote(Ref ref, PollId pollId) {
  final uid = ref.watch(authUserProvider).value?.uid;
  if (uid == null) return Stream.value(const {});
  return ref.watch(pollRepositoryProvider).watchMyVote(pollId, UserId(uid));
}

/// Everyone's votes on a regular poll, for "who voted" (POLL-3). Read when
/// the sheet opens, not kept live.
@riverpod
Future<List<PollVote>> pollVotes(Ref ref, PollId pollId) =>
    ref.watch(pollRepositoryProvider).loadVotes(pollId);

/// The players I vote for on a team's one-vote-per-player polls (#96):
/// those I'm linked to, as a parent, guardian, or the player, in roster
/// order. Empty while the roster loads, and for anyone linked to nobody,
/// such as a coach.
@riverpod
List<Player> myVotingPlayers(Ref ref, GroupId groupId) {
  final me = ref.watch(authUserProvider.select((u) => u.value?.uid));
  if (me == null) return const [];
  final mine = {
    for (final l
        in ref.watch(guardianLinksProvider(groupId)).value ??
            const <GuardianLink>[])
      if (l.uid.value == me) l.playerId,
  };
  return [
    for (final p
        in ref.watch(playersProvider(groupId)).value ?? const <Player>[])
      if (mine.contains(p.id)) p,
  ];
}

/// My players' votes on a one-vote-per-player poll (#96), live, by player;
/// a player with no vote is missing. Listens again only when my players
/// change, not on every roster update.
@riverpod
Stream<Map<PlayerId, PlayerPollVote>> myPlayersPollVotes(
  Ref ref,
  PollId pollId,
  GroupId groupId,
) {
  final ids = ref.watch(
    myVotingPlayersProvider(groupId)
        .select((players) => [for (final p in players) p.id.value].join(',')),
  );
  return ref.watch(pollRepositoryProvider).watchPlayerVotes(pollId, [
    for (final id in ids.split(','))
      if (id.isNotEmpty) PlayerId(id),
  ]);
}

/// Every player's vote on a one-vote-per-player poll that isn't anonymous
/// (#96), for the results by player. Read when the sheet opens, not kept
/// live.
@riverpod
Future<List<PlayerPollVote>> pollPlayerVotes(Ref ref, PollId pollId) =>
    ref.watch(pollRepositoryProvider).loadPlayerVotes(pollId);
