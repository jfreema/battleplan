import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/polls/domain/poll_repository.dart';
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
