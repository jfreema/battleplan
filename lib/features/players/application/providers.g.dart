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
