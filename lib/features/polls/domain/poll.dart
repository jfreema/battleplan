import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'poll.freezed.dart';

/// A poll in a team's chat (ARCH §6.2 `polls`). It shares its ID with the
/// chat message that shows it. The counts are kept by the server from
/// everyone's votes (POLL-2).
@freezed
abstract class Poll with _$Poll {
  const factory({
    required PollId id,
    required GroupId groupId,
    required String createdBy,
    required String question,
    required List<PollOption> options,
    @Default(false) bool allowMultiple,

    /// Only counts are shown; nobody in the app sees who chose what (POLL-3).
    @Default(false) bool anonymous,

    /// One vote per player on the roster (#96): parents, guardians, and
    /// adult players vote for their players, and the counts are players.
    @Default(false) bool perPlayer,

    /// When it closes by itself (POLL-4), if set.
    DateTime? closesAt,

    /// When it closed, early or on time. Closed polls never reopen.
    DateTime? closedAt,

    /// Votes per option ID.
    @Default(<String, int>{}) Map<String, int> voteCounts,

    /// How many people voted; on a one-vote-per-player poll, how many
    /// players have a vote.
    @Default(0) int voterCount,
  }) = _Poll;

  const new _();

  /// Closed, or past its close time while the server catches up (the rules
  /// already refuse votes then).
  bool isClosedAt(DateTime now) =>
      closedAt != null || (closesAt != null && !now.isBefore(closesAt!));

  int votesFor(String optionId) => voteCounts[optionId] ?? 0;

  /// The share of voters who chose [optionId], 0 to 1. On a multiple-answer
  /// poll the shares can add up to more than 1.
  double shareOf(String optionId) =>
      voterCount == 0 ? 0 : (votesFor(optionId) / voterCount).clamp(0, 1);

  /// The options with the most votes, once anyone has voted.
  Set<String> get leaders {
    final top = options.fold<int>(
      0,
      (m, o) => votesFor(o.id) > m ? votesFor(o.id) : m,
    );
    if (top == 0) return const {};
    return {
      for (final o in options)
        if (votesFor(o.id) == top) o.id,
    };
  }
}

/// One choice. IDs are '0' to '9' in the order the creator set them.
@freezed
abstract class PollOption with _$PollOption {
  const factory({required String id, required String text}) = _PollOption;
}

/// Someone's choices on a poll (`pollVotes/{pollId}_{uid}`).
@freezed
abstract class PollVote with _$PollVote {
  const factory({required String uid, required Set<String> optionIds}) =
      _PollVote;
}

/// A player's vote on a one-vote-per-player poll (#96,
/// `pollPlayerVotes/{pollId}_{playerId}`), and who cast it: a parent,
/// guardian, or the player themselves.
@freezed
abstract class PlayerPollVote with _$PlayerPollVote {
  const factory({
    required PlayerId playerId,
    required Set<String> optionIds,
    required String uid,
  }) = _PlayerPollVote;
}

/// A player's vote another guardian cast that mine would change (#96):
/// asked about before voting, and that guardian is told.
typedef ReplacedVote = ({
  PlayerId playerId,
  String uid,
  Set<String> before,
  Set<String> after,
});

/// A poll about to be posted (POLL-1).
@freezed
abstract class NewPoll with _$NewPoll {
  const factory({
    required String question,
    required List<String> options,
    @Default(false) bool allowMultiple,
    @Default(false) bool anonymous,

    /// One vote per player on the roster (#96); only on a team.
    @Default(false) bool perPlayer,
    DateTime? closesAt,
  }) = _NewPoll;

  const new _();

  /// The question and options trimmed, with empty options left out.
  NewPoll get tidy => copyWith(
    question: question.trim(),
    options: [
      for (final o in options)
        if (o.trim().isNotEmpty) o.trim(),
    ],
  );

  /// Whether it can be posted: a question, 2 to 10 options, everything
  /// within its length limit, and a close time still ahead of [now].
  bool isValidAt(DateTime now) {
    final t = tidy;
    return t.question.isNotEmpty &&
        !tooLong(t.question, Limits.pollQuestionMax) &&
        t.options.length >= Limits.pollOptionsMin &&
        t.options.length <= Limits.pollOptionsMax &&
        t.options.every((o) => !tooLong(o, Limits.pollOptionTextMax)) &&
        (closesAt == null || closesAt!.isAfter(now));
  }
}

/// Whether [text] is over [max] characters as the rules count them (code
/// points), which can be more than a text field counts for some emoji.
bool tooLong(String text, int max) => text.trim().runes.length > max;

/// What tapping [optionId] does to [mine] (POLL-2): on a one-answer poll it
/// picks that option, or removes the vote when it's already picked; on a
/// multiple-answer poll it toggles that option. An empty result removes
/// the vote.
Set<String> toggledVote(
  Set<String> mine,
  String optionId, {
  required bool allowMultiple,
}) {
  if (allowMultiple) {
    return mine.contains(optionId)
        ? ({...mine}..remove(optionId))
        : {...mine, optionId};
  }
  return mine.contains(optionId) ? const {} : {optionId};
}

/// What tapping [optionId] does to the votes of [mine], my players, on a
/// one-vote-per-player poll (#96): I vote for all of them at once. On a
/// one-answer poll it picks that option for each, or takes their votes
/// back when it's already every one's; on a multiple-answer poll it adds
/// that option to each one's, or takes it off when every one has it.
/// [current] holds their votes now, missing for a player with none. An
/// empty set takes a player's vote back.
Map<PlayerId, Set<String>> playerVotesAfterTap(
  Map<PlayerId, Set<String>> current,
  List<PlayerId> mine,
  String optionId, {
  required bool allowMultiple,
}) {
  Set<String> now(PlayerId p) => current[p] ?? const {};
  if (allowMultiple) {
    final everyone = mine.every((p) => now(p).contains(optionId));
    return {
      for (final p in mine)
        p: everyone ? ({...now(p)}..remove(optionId)) : {...now(p), optionId},
    };
  }
  final everyone = mine.every(
    (p) => now(p).length == 1 && now(p).contains(optionId),
  );
  return {
    for (final p in mine) p: everyone ? const <String>{} : {optionId},
  };
}

/// The votes [next] would change that someone else cast (#96): the
/// players' votes in [current] that aren't [me]'s, with an answer, and
/// different from what I'd vote. Asked about before voting.
List<ReplacedVote> replacedVotes(
  Map<PlayerId, PlayerPollVote> current,
  Map<PlayerId, Set<String>> next,
  String me,
) => [
  for (final MapEntry(key: player, value: after) in next.entries)
    if (current[player] case final vote?
        when vote.uid != me &&
            vote.optionIds.isNotEmpty &&
            !_sameChoices(vote.optionIds, after))
      (playerId: player, uid: vote.uid, before: vote.optionIds, after: after),
];

bool _sameChoices(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
