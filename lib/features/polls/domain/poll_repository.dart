import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/polls/domain/poll.dart';

/// Owns `polls`, `pollVotes`, and `pollPlayerVotes` (ARCH §5.3). Posting a
/// poll goes through the chat's MessageRepository.sendPoll, since the poll
/// and its message are written together.
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

  /// The votes of [playerIds] (my players) on a one-vote-per-player poll
  /// (#96), kept live, by player; a player with no vote is missing.
  Stream<Map<PlayerId, PlayerPollVote>> watchPlayerVotes(
    PollId pollId,
    List<PlayerId> playerIds,
  );

  /// Every player's vote on a one-vote-per-player poll that isn't
  /// anonymous (#96), for the results by player.
  Future<List<PlayerPollVote>> loadPlayerVotes(PollId pollId);

  /// Votes for my players on a one-vote-per-player poll (#96) through the
  /// `votePollForPlayers` callable: each player's choices, an empty set
  /// taking that player's vote back. Returns how many players' votes it
  /// replaced that another guardian had cast.
  Future<int> setPlayerVotes(Poll poll, Map<PlayerId, Set<String>> votes);
}
