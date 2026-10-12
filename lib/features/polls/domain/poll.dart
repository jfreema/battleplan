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

    /// When it closes by itself (POLL-4), if set.
    DateTime? closesAt,

    /// When it closed, early or on time. Closed polls never reopen.
    DateTime? closedAt,

    /// Votes per option ID.
    @Default(<String, int>{}) Map<String, int> voteCounts,

    /// How many people voted.
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

/// A poll about to be posted (POLL-1).
@freezed
abstract class NewPoll with _$NewPoll {
  const factory({
    required String question,
    required List<String> options,
    @Default(false) bool allowMultiple,
    @Default(false) bool anonymous,
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
        t.question.length <= Limits.pollQuestionMax &&
        t.options.length >= Limits.pollOptionsMin &&
        t.options.length <= Limits.pollOptionsMax &&
        t.options.every((o) => o.length <= Limits.pollOptionTextMax) &&
        (closesAt == null || closesAt!.isAfter(now));
  }
}

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
