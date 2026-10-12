import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/polls/domain/poll.dart';

/// Owns `polls` and `pollVotes` (ARCH §5.3). Posting a poll goes through
/// the chat's MessageRepository.sendPoll, since the poll and its message are
/// written together.
abstract interface class PollRepository {
  /// The poll, kept live; null once it's deleted with its message (POLL-5).
  Stream<Poll?> watchPoll(PollId pollId);

  /// My choices on the poll, kept live, including a vote still on its way.
  Stream<Set<String>> watchMyVote(PollId pollId, UserId uid);

  /// Replaces my choices (POLL-2); an empty set removes my vote. Shows at
  /// once and goes out when the connection allows.
  Future<void> setVote(Poll poll, UserId uid, Set<String> optionIds);

  /// Everyone's votes on a poll that isn't anonymous (POLL-3).
  Future<List<PollVote>> loadVotes(PollId pollId);

  /// Closes the poll early through the `closePoll` callable (POLL-4).
  Future<void> closePoll(PollId pollId);
}
