// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(playerRepository)
final playerRepositoryProvider = PlayerRepositoryProvider._();

/// Overridden in app/providers.dart.

final class PlayerRepositoryProvider
    extends
        $FunctionalProvider<
          PlayerRepository,
          PlayerRepository,
          PlayerRepository
        >
    with $Provider<PlayerRepository> {
  /// Overridden in app/providers.dart.
  PlayerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlayerRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlayerRepository create(Ref ref) {
    return playerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerRepository>(value),
    );
  }
}

String _$playerRepositoryHash() => r'f94248185382f6ab3608ad1ba482ab3ad9f94149';

/// A team's active players, by jersey number then name (TEAM-3). Every
/// team has them.

@ProviderFor(players)
final playersProvider = PlayersFamily._();

/// A team's active players, by jersey number then name (TEAM-3). Every
/// team has them.

final class PlayersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Player>>,
          List<Player>,
          Stream<List<Player>>
        >
    with $FutureModifier<List<Player>>, $StreamProvider<List<Player>> {
  /// A team's active players, by jersey number then name (TEAM-3). Every
  /// team has them.
  PlayersProvider._({
    required PlayersFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'playersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playersHash();

  @override
  String toString() {
    return r'playersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Player>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Player>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return players(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playersHash() => r'7c75892f9d335c0be7aaf398b5d084888a994701';

/// A team's active players, by jersey number then name (TEAM-3). Every
/// team has them.

final class PlayersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Player>>, GroupId> {
  PlayersFamily._()
    : super(
        retry: null,
        name: r'playersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's active players, by jersey number then name (TEAM-3). Every
  /// team has them.

  PlayersProvider call(GroupId groupId) =>
      PlayersProvider._(argument: groupId, from: this);

  @override
  String toString() => r'playersProvider';
}

/// A team's pending players (PLAYER-4). Only admins can read them all.

@ProviderFor(pendingPlayers)
final pendingPlayersProvider = PendingPlayersFamily._();

/// A team's pending players (PLAYER-4). Only admins can read them all.

final class PendingPlayersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Player>>,
          List<Player>,
          Stream<List<Player>>
        >
    with $FutureModifier<List<Player>>, $StreamProvider<List<Player>> {
  /// A team's pending players (PLAYER-4). Only admins can read them all.
  PendingPlayersProvider._({
    required PendingPlayersFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'pendingPlayersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingPlayersHash();

  @override
  String toString() {
    return r'pendingPlayersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Player>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Player>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return pendingPlayers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingPlayersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingPlayersHash() => r'1cf0c616ee70cdab53aa6f6e49f074498dc32e84';

/// A team's pending players (PLAYER-4). Only admins can read them all.

final class PendingPlayersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Player>>, GroupId> {
  PendingPlayersFamily._()
    : super(
        retry: null,
        name: r'pendingPlayersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's pending players (PLAYER-4). Only admins can read them all.

  PendingPlayersProvider call(GroupId groupId) =>
      PendingPlayersProvider._(argument: groupId, from: this);

  @override
  String toString() => r'pendingPlayersProvider';
}

/// The pending players the signed-in person added (PLAYER-4).

@ProviderFor(myPendingPlayers)
final myPendingPlayersProvider = MyPendingPlayersFamily._();

/// The pending players the signed-in person added (PLAYER-4).

final class MyPendingPlayersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Player>>,
          List<Player>,
          Stream<List<Player>>
        >
    with $FutureModifier<List<Player>>, $StreamProvider<List<Player>> {
  /// The pending players the signed-in person added (PLAYER-4).
  MyPendingPlayersProvider._({
    required MyPendingPlayersFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'myPendingPlayersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myPendingPlayersHash();

  @override
  String toString() {
    return r'myPendingPlayersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Player>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Player>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return myPendingPlayers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyPendingPlayersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myPendingPlayersHash() => r'cb1e44fa435eac0ffbb9a107cec60b16bcfa71aa';

/// The pending players the signed-in person added (PLAYER-4).

final class MyPendingPlayersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Player>>, GroupId> {
  MyPendingPlayersFamily._()
    : super(
        retry: null,
        name: r'myPendingPlayersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The pending players the signed-in person added (PLAYER-4).

  MyPendingPlayersProvider call(GroupId groupId) =>
      MyPendingPlayersProvider._(argument: groupId, from: this);

  @override
  String toString() => r'myPendingPlayersProvider';
}

/// A team's player links, as the player or a guardian.

@ProviderFor(guardianLinks)
final guardianLinksProvider = GuardianLinksFamily._();

/// A team's player links, as the player or a guardian.

final class GuardianLinksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GuardianLink>>,
          List<GuardianLink>,
          Stream<List<GuardianLink>>
        >
    with
        $FutureModifier<List<GuardianLink>>,
        $StreamProvider<List<GuardianLink>> {
  /// A team's player links, as the player or a guardian.
  GuardianLinksProvider._({
    required GuardianLinksFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'guardianLinksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$guardianLinksHash();

  @override
  String toString() {
    return r'guardianLinksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GuardianLink>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GuardianLink>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return guardianLinks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GuardianLinksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$guardianLinksHash() => r'55719c25bfd58d226b0e2dbe58b120b48987f6ba';

/// A team's player links, as the player or a guardian.

final class GuardianLinksFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GuardianLink>>, GroupId> {
  GuardianLinksFamily._()
    : super(
        retry: null,
        name: r'guardianLinksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's player links, as the player or a guardian.

  GuardianLinksProvider call(GroupId groupId) =>
      GuardianLinksProvider._(argument: groupId, from: this);

  @override
  String toString() => r'guardianLinksProvider';
}

/// A team's pending claims (PLAYER-4). Only admins can read them.

@ProviderFor(pendingGuardianRequests)
final pendingGuardianRequestsProvider = PendingGuardianRequestsFamily._();

/// A team's pending claims (PLAYER-4). Only admins can read them.

final class PendingGuardianRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GuardianRequest>>,
          List<GuardianRequest>,
          Stream<List<GuardianRequest>>
        >
    with
        $FutureModifier<List<GuardianRequest>>,
        $StreamProvider<List<GuardianRequest>> {
  /// A team's pending claims (PLAYER-4). Only admins can read them.
  PendingGuardianRequestsProvider._({
    required PendingGuardianRequestsFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'pendingGuardianRequestsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingGuardianRequestsHash();

  @override
  String toString() {
    return r'pendingGuardianRequestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GuardianRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GuardianRequest>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return pendingGuardianRequests(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingGuardianRequestsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingGuardianRequestsHash() =>
    r'3931c360053f5235a9f50117822d4bf6641652d9';

/// A team's pending claims (PLAYER-4). Only admins can read them.

final class PendingGuardianRequestsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GuardianRequest>>, GroupId> {
  PendingGuardianRequestsFamily._()
    : super(
        retry: null,
        name: r'pendingGuardianRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's pending claims (PLAYER-4). Only admins can read them.

  PendingGuardianRequestsProvider call(GroupId groupId) =>
      PendingGuardianRequestsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'pendingGuardianRequestsProvider';
}

/// The signed-in person's own claims on a team (PLAYER-3).

@ProviderFor(myGuardianRequests)
final myGuardianRequestsProvider = MyGuardianRequestsFamily._();

/// The signed-in person's own claims on a team (PLAYER-3).

final class MyGuardianRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GuardianRequest>>,
          List<GuardianRequest>,
          Stream<List<GuardianRequest>>
        >
    with
        $FutureModifier<List<GuardianRequest>>,
        $StreamProvider<List<GuardianRequest>> {
  /// The signed-in person's own claims on a team (PLAYER-3).
  MyGuardianRequestsProvider._({
    required MyGuardianRequestsFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'myGuardianRequestsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myGuardianRequestsHash();

  @override
  String toString() {
    return r'myGuardianRequestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GuardianRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GuardianRequest>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return myGuardianRequests(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyGuardianRequestsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myGuardianRequestsHash() =>
    r'21d0ecaf2e5edc869ea69a74578b4c8de9ee14c2';

/// The signed-in person's own claims on a team (PLAYER-3).

final class MyGuardianRequestsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GuardianRequest>>, GroupId> {
  MyGuardianRequestsFamily._()
    : super(
        retry: null,
        name: r'myGuardianRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The signed-in person's own claims on a team (PLAYER-3).

  MyGuardianRequestsProvider call(GroupId groupId) =>
      MyGuardianRequestsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'myGuardianRequestsProvider';
}

/// A player's answers on the team's events from yesterday on, by event ID,
/// for the player card's upcoming RSVPs (PLAYER-2).

@ProviderFor(playerRsvps)
final playerRsvpsProvider = PlayerRsvpsFamily._();

/// A player's answers on the team's events from yesterday on, by event ID,
/// for the player card's upcoming RSVPs (PLAYER-2).

final class PlayerRsvpsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Rsvp>>,
          Map<String, Rsvp>,
          Stream<Map<String, Rsvp>>
        >
    with
        $FutureModifier<Map<String, Rsvp>>,
        $StreamProvider<Map<String, Rsvp>> {
  /// A player's answers on the team's events from yesterday on, by event ID,
  /// for the player card's upcoming RSVPs (PLAYER-2).
  PlayerRsvpsProvider._({
    required PlayerRsvpsFamily super.from,
    required (GroupId, PlayerId) super.argument,
  }) : super(
         retry: null,
         name: r'playerRsvpsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerRsvpsHash();

  @override
  String toString() {
    return r'playerRsvpsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, Rsvp>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, Rsvp>> create(Ref ref) {
    final argument = this.argument as (GroupId, PlayerId);
    return playerRsvps(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerRsvpsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerRsvpsHash() => r'd889be7bb5e0c425aed44c2be159b3bc5baecf38';

/// A player's answers on the team's events from yesterday on, by event ID,
/// for the player card's upcoming RSVPs (PLAYER-2).

final class PlayerRsvpsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Map<String, Rsvp>>,
          (GroupId, PlayerId)
        > {
  PlayerRsvpsFamily._()
    : super(
        retry: null,
        name: r'playerRsvpsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A player's answers on the team's events from yesterday on, by event ID,
  /// for the player card's upcoming RSVPs (PLAYER-2).

  PlayerRsvpsProvider call(GroupId groupId, PlayerId playerId) =>
      PlayerRsvpsProvider._(argument: (groupId, playerId), from: this);

  @override
  String toString() => r'playerRsvpsProvider';
}

/// A player's RSVP history (PLAYER-11): the team's events that took RSVPs
/// and started in [from, until), since the player was added, newest first,
/// with the player's answers (live), for the player's linked members and
/// the team's admins.

@ProviderFor(playerRsvpHistory)
final playerRsvpHistoryProvider = PlayerRsvpHistoryFamily._();

/// A player's RSVP history (PLAYER-11): the team's events that took RSVPs
/// and started in [from, until), since the player was added, newest first,
/// with the player's answers (live), for the player's linked members and
/// the team's admins.

final class PlayerRsvpHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<RsvpHistory>,
          AsyncValue<RsvpHistory>,
          AsyncValue<RsvpHistory>
        >
    with $Provider<AsyncValue<RsvpHistory>> {
  /// A player's RSVP history (PLAYER-11): the team's events that took RSVPs
  /// and started in [from, until), since the player was added, newest first,
  /// with the player's answers (live), for the player's linked members and
  /// the team's admins.
  PlayerRsvpHistoryProvider._({
    required PlayerRsvpHistoryFamily super.from,
    required (GroupId, PlayerId, DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'playerRsvpHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerRsvpHistoryHash();

  @override
  String toString() {
    return r'playerRsvpHistoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<RsvpHistory>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<RsvpHistory> create(Ref ref) {
    final argument = this.argument as (GroupId, PlayerId, DateTime, DateTime);
    return playerRsvpHistory(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
      argument.$4,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<RsvpHistory> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<RsvpHistory>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerRsvpHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerRsvpHistoryHash() => r'44fdd933b5cb62216d616c03a9111bd1de9b7401';

/// A player's RSVP history (PLAYER-11): the team's events that took RSVPs
/// and started in [from, until), since the player was added, newest first,
/// with the player's answers (live), for the player's linked members and
/// the team's admins.

final class PlayerRsvpHistoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<RsvpHistory>,
          (GroupId, PlayerId, DateTime, DateTime)
        > {
  PlayerRsvpHistoryFamily._()
    : super(
        retry: null,
        name: r'playerRsvpHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A player's RSVP history (PLAYER-11): the team's events that took RSVPs
  /// and started in [from, until), since the player was added, newest first,
  /// with the player's answers (live), for the player's linked members and
  /// the team's admins.

  PlayerRsvpHistoryProvider call(
    GroupId groupId,
    PlayerId playerId,
    DateTime from,
    DateTime until,
  ) => PlayerRsvpHistoryProvider._(
    argument: (groupId, playerId, from, until),
    from: this,
  );

  @override
  String toString() => r'playerRsvpHistoryProvider';
}

/// A player's answers on events starting in [from, until), by event ID.

@ProviderFor(_playerAnswers)
final _playerAnswersProvider = _PlayerAnswersFamily._();

/// A player's answers on events starting in [from, until), by event ID.

final class _PlayerAnswersProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Rsvp>>,
          Map<String, Rsvp>,
          Stream<Map<String, Rsvp>>
        >
    with
        $FutureModifier<Map<String, Rsvp>>,
        $StreamProvider<Map<String, Rsvp>> {
  /// A player's answers on events starting in [from, until), by event ID.
  _PlayerAnswersProvider._({
    required _PlayerAnswersFamily super.from,
    required (GroupId, PlayerId, DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'_playerAnswersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_playerAnswersHash();

  @override
  String toString() {
    return r'_playerAnswersProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, Rsvp>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, Rsvp>> create(Ref ref) {
    final argument = this.argument as (GroupId, PlayerId, DateTime, DateTime);
    return _playerAnswers(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
      argument.$4,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _PlayerAnswersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_playerAnswersHash() => r'8b3fba309e2ab74444a69318a1ab5f297cf0dbf0';

/// A player's answers on events starting in [from, until), by event ID.

final class _PlayerAnswersFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Map<String, Rsvp>>,
          (GroupId, PlayerId, DateTime, DateTime)
        > {
  _PlayerAnswersFamily._()
    : super(
        retry: null,
        name: r'_playerAnswersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A player's answers on events starting in [from, until), by event ID.

  _PlayerAnswersProvider call(
    GroupId groupId,
    PlayerId playerId,
    DateTime from,
    DateTime until,
  ) => _PlayerAnswersProvider._(
    argument: (groupId, playerId, from, until),
    from: this,
  );

  @override
  String toString() => r'_playerAnswersProvider';
}

/// A player's details (PLAYER-12). Watched only for the team's admins and
/// the members linked to the player ([seesPlayerDetails]): nobody else's
/// app asks for them.

@ProviderFor(playerDetails)
final playerDetailsProvider = PlayerDetailsFamily._();

/// A player's details (PLAYER-12). Watched only for the team's admins and
/// the members linked to the player ([seesPlayerDetails]): nobody else's
/// app asks for them.

final class PlayerDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlayerDetails?>,
          PlayerDetails?,
          Stream<PlayerDetails?>
        >
    with $FutureModifier<PlayerDetails?>, $StreamProvider<PlayerDetails?> {
  /// A player's details (PLAYER-12). Watched only for the team's admins and
  /// the members linked to the player ([seesPlayerDetails]): nobody else's
  /// app asks for them.
  PlayerDetailsProvider._({
    required PlayerDetailsFamily super.from,
    required PlayerId super.argument,
  }) : super(
         retry: null,
         name: r'playerDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerDetailsHash();

  @override
  String toString() {
    return r'playerDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<PlayerDetails?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<PlayerDetails?> create(Ref ref) {
    final argument = this.argument as PlayerId;
    return playerDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerDetailsHash() => r'4a388b6863417c0ff896a76dc7c6e68cb45429b6';

/// A player's details (PLAYER-12). Watched only for the team's admins and
/// the members linked to the player ([seesPlayerDetails]): nobody else's
/// app asks for them.

final class PlayerDetailsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<PlayerDetails?>, PlayerId> {
  PlayerDetailsFamily._()
    : super(
        retry: null,
        name: r'playerDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A player's details (PLAYER-12). Watched only for the team's admins and
  /// the members linked to the player ([seesPlayerDetails]): nobody else's
  /// app asks for them.

  PlayerDetailsProvider call(PlayerId playerId) =>
      PlayerDetailsProvider._(argument: playerId, from: this);

  @override
  String toString() => r'playerDetailsProvider';
}

/// A team's player details by player ID, for ages on the roster
/// (PLAYER-12). One list for the whole team, watched only for its admins.

@ProviderFor(teamPlayerDetails)
final teamPlayerDetailsProvider = TeamPlayerDetailsFamily._();

/// A team's player details by player ID, for ages on the roster
/// (PLAYER-12). One list for the whole team, watched only for its admins.

final class TeamPlayerDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<PlayerId, PlayerDetails>>,
          Map<PlayerId, PlayerDetails>,
          Stream<Map<PlayerId, PlayerDetails>>
        >
    with
        $FutureModifier<Map<PlayerId, PlayerDetails>>,
        $StreamProvider<Map<PlayerId, PlayerDetails>> {
  /// A team's player details by player ID, for ages on the roster
  /// (PLAYER-12). One list for the whole team, watched only for its admins.
  TeamPlayerDetailsProvider._({
    required TeamPlayerDetailsFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'teamPlayerDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamPlayerDetailsHash();

  @override
  String toString() {
    return r'teamPlayerDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<PlayerId, PlayerDetails>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<PlayerId, PlayerDetails>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return teamPlayerDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamPlayerDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamPlayerDetailsHash() => r'b82bd559b737f58d85157cc851b65967490d6d66';

/// A team's player details by player ID, for ages on the roster
/// (PLAYER-12). One list for the whole team, watched only for its admins.

final class TeamPlayerDetailsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Map<PlayerId, PlayerDetails>>,
          GroupId
        > {
  TeamPlayerDetailsFamily._()
    : super(
        retry: null,
        name: r'teamPlayerDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's player details by player ID, for ages on the roster
  /// (PLAYER-12). One list for the whole team, watched only for its admins.

  TeamPlayerDetailsProvider call(GroupId groupId) =>
      TeamPlayerDetailsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'teamPlayerDetailsProvider';
}
