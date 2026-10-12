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
