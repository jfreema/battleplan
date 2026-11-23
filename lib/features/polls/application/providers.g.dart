// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(pollRepository)
final pollRepositoryProvider = PollRepositoryProvider._();

/// Overridden in app/providers.dart.

final class PollRepositoryProvider
    extends $FunctionalProvider<PollRepository, PollRepository, PollRepository>
    with $Provider<PollRepository> {
  /// Overridden in app/providers.dart.
  PollRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pollRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pollRepositoryHash();

  @$internal
  @override
  $ProviderElement<PollRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PollRepository create(Ref ref) {
    return pollRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PollRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PollRepository>(value),
    );
  }
}

String _$pollRepositoryHash() => r'8f370dc78e2eb22857fdf22354f94003e349e82e';

/// A poll, live (POLL-2). Null once it's deleted.

@ProviderFor(poll)
final pollProvider = PollFamily._();

/// A poll, live (POLL-2). Null once it's deleted.

final class PollProvider
    extends $FunctionalProvider<AsyncValue<Poll?>, Poll?, Stream<Poll?>>
    with $FutureModifier<Poll?>, $StreamProvider<Poll?> {
  /// A poll, live (POLL-2). Null once it's deleted.
  PollProvider._({
    required PollFamily super.from,
    required PollId super.argument,
  }) : super(
         retry: null,
         name: r'pollProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pollHash();

  @override
  String toString() {
    return r'pollProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Poll?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Poll?> create(Ref ref) {
    final argument = this.argument as PollId;
    return poll(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PollProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pollHash() => r'39f6826d821970e2dbb8956d21afd938432c4ef3';

/// A poll, live (POLL-2). Null once it's deleted.

final class PollFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Poll?>, PollId> {
  PollFamily._()
    : super(
        retry: null,
        name: r'pollProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A poll, live (POLL-2). Null once it's deleted.

  PollProvider call(PollId pollId) =>
      PollProvider._(argument: pollId, from: this);

  @override
  String toString() => r'pollProvider';
}

/// My choices on a poll, live, including a vote still on its way.

@ProviderFor(myPollVote)
final myPollVoteProvider = MyPollVoteFamily._();

/// My choices on a poll, live, including a vote still on its way.

final class MyPollVoteProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  /// My choices on a poll, live, including a vote still on its way.
  MyPollVoteProvider._({
    required MyPollVoteFamily super.from,
    required PollId super.argument,
  }) : super(
         retry: null,
         name: r'myPollVoteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myPollVoteHash();

  @override
  String toString() {
    return r'myPollVoteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    final argument = this.argument as PollId;
    return myPollVote(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyPollVoteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myPollVoteHash() => r'169c28e145f2d6309b7eefa446330318814fa5c2';

/// My choices on a poll, live, including a vote still on its way.

final class MyPollVoteFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Set<String>>, PollId> {
  MyPollVoteFamily._()
    : super(
        retry: null,
        name: r'myPollVoteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// My choices on a poll, live, including a vote still on its way.

  MyPollVoteProvider call(PollId pollId) =>
      MyPollVoteProvider._(argument: pollId, from: this);

  @override
  String toString() => r'myPollVoteProvider';
}

/// Everyone's votes on a regular poll, for "who voted" (POLL-3). Read when
/// the sheet opens, not kept live.

@ProviderFor(pollVotes)
final pollVotesProvider = PollVotesFamily._();

/// Everyone's votes on a regular poll, for "who voted" (POLL-3). Read when
/// the sheet opens, not kept live.

final class PollVotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PollVote>>,
          List<PollVote>,
          FutureOr<List<PollVote>>
        >
    with $FutureModifier<List<PollVote>>, $FutureProvider<List<PollVote>> {
  /// Everyone's votes on a regular poll, for "who voted" (POLL-3). Read when
  /// the sheet opens, not kept live.
  PollVotesProvider._({
    required PollVotesFamily super.from,
    required PollId super.argument,
  }) : super(
         retry: null,
         name: r'pollVotesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pollVotesHash();

  @override
  String toString() {
    return r'pollVotesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PollVote>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PollVote>> create(Ref ref) {
    final argument = this.argument as PollId;
    return pollVotes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PollVotesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pollVotesHash() => r'5db86f831f504a5e180340d22290be8d3a3d29c2';

/// Everyone's votes on a regular poll, for "who voted" (POLL-3). Read when
/// the sheet opens, not kept live.

final class PollVotesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PollVote>>, PollId> {
  PollVotesFamily._()
    : super(
        retry: null,
        name: r'pollVotesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everyone's votes on a regular poll, for "who voted" (POLL-3). Read when
  /// the sheet opens, not kept live.

  PollVotesProvider call(PollId pollId) =>
      PollVotesProvider._(argument: pollId, from: this);

  @override
  String toString() => r'pollVotesProvider';
}

/// The players I vote for on a team's one-vote-per-player polls (#96):
/// those I'm linked to, as a parent, guardian, or the player, in roster
/// order. Empty while the roster loads, and for anyone linked to nobody,
/// such as a coach.

@ProviderFor(myVotingPlayers)
final myVotingPlayersProvider = MyVotingPlayersFamily._();

/// The players I vote for on a team's one-vote-per-player polls (#96):
/// those I'm linked to, as a parent, guardian, or the player, in roster
/// order. Empty while the roster loads, and for anyone linked to nobody,
/// such as a coach.

final class MyVotingPlayersProvider
    extends $FunctionalProvider<List<Player>, List<Player>, List<Player>>
    with $Provider<List<Player>> {
  /// The players I vote for on a team's one-vote-per-player polls (#96):
  /// those I'm linked to, as a parent, guardian, or the player, in roster
  /// order. Empty while the roster loads, and for anyone linked to nobody,
  /// such as a coach.
  MyVotingPlayersProvider._({
    required MyVotingPlayersFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'myVotingPlayersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myVotingPlayersHash();

  @override
  String toString() {
    return r'myVotingPlayersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Player>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Player> create(Ref ref) {
    final argument = this.argument as GroupId;
    return myVotingPlayers(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Player> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Player>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MyVotingPlayersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myVotingPlayersHash() => r'c2fde2f71733e6c1625240e692af885972f9c467';

/// The players I vote for on a team's one-vote-per-player polls (#96):
/// those I'm linked to, as a parent, guardian, or the player, in roster
/// order. Empty while the roster loads, and for anyone linked to nobody,
/// such as a coach.

final class MyVotingPlayersFamily extends $Family
    with $FunctionalFamilyOverride<List<Player>, GroupId> {
  MyVotingPlayersFamily._()
    : super(
        retry: null,
        name: r'myVotingPlayersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The players I vote for on a team's one-vote-per-player polls (#96):
  /// those I'm linked to, as a parent, guardian, or the player, in roster
  /// order. Empty while the roster loads, and for anyone linked to nobody,
  /// such as a coach.

  MyVotingPlayersProvider call(GroupId groupId) =>
      MyVotingPlayersProvider._(argument: groupId, from: this);

  @override
  String toString() => r'myVotingPlayersProvider';
}

/// My players' votes on a one-vote-per-player poll (#96), live, by player;
/// a player with no vote is missing. Listens again only when my players
/// change, not on every roster update.

@ProviderFor(myPlayersPollVotes)
final myPlayersPollVotesProvider = MyPlayersPollVotesFamily._();

/// My players' votes on a one-vote-per-player poll (#96), live, by player;
/// a player with no vote is missing. Listens again only when my players
/// change, not on every roster update.

final class MyPlayersPollVotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<PlayerId, PlayerPollVote>>,
          Map<PlayerId, PlayerPollVote>,
          Stream<Map<PlayerId, PlayerPollVote>>
        >
    with
        $FutureModifier<Map<PlayerId, PlayerPollVote>>,
        $StreamProvider<Map<PlayerId, PlayerPollVote>> {
  /// My players' votes on a one-vote-per-player poll (#96), live, by player;
  /// a player with no vote is missing. Listens again only when my players
  /// change, not on every roster update.
  MyPlayersPollVotesProvider._({
    required MyPlayersPollVotesFamily super.from,
    required (PollId, GroupId) super.argument,
  }) : super(
         retry: null,
         name: r'myPlayersPollVotesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myPlayersPollVotesHash();

  @override
  String toString() {
    return r'myPlayersPollVotesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Map<PlayerId, PlayerPollVote>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<PlayerId, PlayerPollVote>> create(Ref ref) {
    final argument = this.argument as (PollId, GroupId);
    return myPlayersPollVotes(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is MyPlayersPollVotesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myPlayersPollVotesHash() =>
    r'3ba49fbd50caa6dbca611a31d8edb06edb26a581';

/// My players' votes on a one-vote-per-player poll (#96), live, by player;
/// a player with no vote is missing. Listens again only when my players
/// change, not on every roster update.

final class MyPlayersPollVotesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Map<PlayerId, PlayerPollVote>>,
          (PollId, GroupId)
        > {
  MyPlayersPollVotesFamily._()
    : super(
        retry: null,
        name: r'myPlayersPollVotesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// My players' votes on a one-vote-per-player poll (#96), live, by player;
  /// a player with no vote is missing. Listens again only when my players
  /// change, not on every roster update.

  MyPlayersPollVotesProvider call(PollId pollId, GroupId groupId) =>
      MyPlayersPollVotesProvider._(argument: (pollId, groupId), from: this);

  @override
  String toString() => r'myPlayersPollVotesProvider';
}

/// Every player's vote on a one-vote-per-player poll that isn't anonymous
/// (#96), for the results by player. Read when the sheet opens, not kept
/// live.

@ProviderFor(pollPlayerVotes)
final pollPlayerVotesProvider = PollPlayerVotesFamily._();

/// Every player's vote on a one-vote-per-player poll that isn't anonymous
/// (#96), for the results by player. Read when the sheet opens, not kept
/// live.

final class PollPlayerVotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlayerPollVote>>,
          List<PlayerPollVote>,
          FutureOr<List<PlayerPollVote>>
        >
    with
        $FutureModifier<List<PlayerPollVote>>,
        $FutureProvider<List<PlayerPollVote>> {
  /// Every player's vote on a one-vote-per-player poll that isn't anonymous
  /// (#96), for the results by player. Read when the sheet opens, not kept
  /// live.
  PollPlayerVotesProvider._({
    required PollPlayerVotesFamily super.from,
    required PollId super.argument,
  }) : super(
         retry: null,
         name: r'pollPlayerVotesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pollPlayerVotesHash();

  @override
  String toString() {
    return r'pollPlayerVotesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlayerPollVote>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlayerPollVote>> create(Ref ref) {
    final argument = this.argument as PollId;
    return pollPlayerVotes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PollPlayerVotesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pollPlayerVotesHash() => r'75e551158a5bd85d8cc2a07c83a4011ba5f8bb69';

/// Every player's vote on a one-vote-per-player poll that isn't anonymous
/// (#96), for the results by player. Read when the sheet opens, not kept
/// live.

final class PollPlayerVotesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlayerPollVote>>, PollId> {
  PollPlayerVotesFamily._()
    : super(
        retry: null,
        name: r'pollPlayerVotesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every player's vote on a one-vote-per-player poll that isn't anonymous
  /// (#96), for the results by player. Read when the sheet opens, not kept
  /// live.

  PollPlayerVotesProvider call(PollId pollId) =>
      PollPlayerVotesProvider._(argument: pollId, from: this);

  @override
  String toString() => r'pollPlayerVotesProvider';
}
