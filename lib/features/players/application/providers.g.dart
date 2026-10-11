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

/// A youth team's players, by jersey number then name (TEAM-3).

@ProviderFor(players)
final playersProvider = PlayersFamily._();

/// A youth team's players, by jersey number then name (TEAM-3).

final class PlayersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Player>>,
          List<Player>,
          Stream<List<Player>>
        >
    with $FutureModifier<List<Player>>, $StreamProvider<List<Player>> {
  /// A youth team's players, by jersey number then name (TEAM-3).
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

String _$playersHash() => r'80c5fa2eeaf62d9718d6337f1107309247e48655';

/// A youth team's players, by jersey number then name (TEAM-3).

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

  /// A youth team's players, by jersey number then name (TEAM-3).

  PlayersProvider call(GroupId groupId) =>
      PlayersProvider._(argument: groupId, from: this);

  @override
  String toString() => r'playersProvider';
}

/// A youth team's guardian links.

@ProviderFor(guardianLinks)
final guardianLinksProvider = GuardianLinksFamily._();

/// A youth team's guardian links.

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
  /// A youth team's guardian links.
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

/// A youth team's guardian links.

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

  /// A youth team's guardian links.

  GuardianLinksProvider call(GroupId groupId) =>
      GuardianLinksProvider._(argument: groupId, from: this);

  @override
  String toString() => r'guardianLinksProvider';
}
