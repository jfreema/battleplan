// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playRepository)
final playRepositoryProvider = PlayRepositoryProvider._();

final class PlayRepositoryProvider
    extends $FunctionalProvider<PlayRepository, PlayRepository, PlayRepository>
    with $Provider<PlayRepository> {
  PlayRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlayRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlayRepository create(Ref ref) {
    return playRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayRepository>(value),
    );
  }
}

String _$playRepositoryHash() => r'9932989ae579c5c34059b9097b5c0324882e68f3';

/// The team's plays, most recently changed first (BOARD-4).

@ProviderFor(teamPlays)
final teamPlaysProvider = TeamPlaysFamily._();

/// The team's plays, most recently changed first (BOARD-4).

final class TeamPlaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Play>>,
          List<Play>,
          Stream<List<Play>>
        >
    with $FutureModifier<List<Play>>, $StreamProvider<List<Play>> {
  /// The team's plays, most recently changed first (BOARD-4).
  TeamPlaysProvider._({
    required TeamPlaysFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'teamPlaysProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamPlaysHash();

  @override
  String toString() {
    return r'teamPlaysProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Play>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Play>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return teamPlays(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamPlaysProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamPlaysHash() => r'f27b5c7a4f1a97c87d951b053a961fadd80d9a8b';

/// The team's plays, most recently changed first (BOARD-4).

final class TeamPlaysFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Play>>, GroupId> {
  TeamPlaysFamily._()
    : super(
        retry: null,
        name: r'teamPlaysProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The team's plays, most recently changed first (BOARD-4).

  TeamPlaysProvider call(GroupId groupId) =>
      TeamPlaysProvider._(argument: groupId, from: this);

  @override
  String toString() => r'teamPlaysProvider';
}

/// One play, live; null once it's deleted.

@ProviderFor(play)
final playProvider = PlayFamily._();

/// One play, live; null once it's deleted.

final class PlayProvider
    extends $FunctionalProvider<AsyncValue<Play?>, Play?, Stream<Play?>>
    with $FutureModifier<Play?>, $StreamProvider<Play?> {
  /// One play, live; null once it's deleted.
  PlayProvider._({
    required PlayFamily super.from,
    required PlayId super.argument,
  }) : super(
         retry: null,
         name: r'playProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playHash();

  @override
  String toString() {
    return r'playProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Play?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Play?> create(Ref ref) {
    final argument = this.argument as PlayId;
    return play(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playHash() => r'4fb6ced50c0307abaae93bf9a41b7eb0c046e92e';

/// One play, live; null once it's deleted.

final class PlayFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Play?>, PlayId> {
  PlayFamily._()
    : super(
        retry: null,
        name: r'playProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One play, live; null once it's deleted.

  PlayProvider call(PlayId id) => PlayProvider._(argument: id, from: this);

  @override
  String toString() => r'playProvider';
}

/// The whiteboard on this device (BOARD-2): kept until it's cleared.

@ProviderFor(whiteboardStore)
final whiteboardStoreProvider = WhiteboardStoreProvider._();

/// The whiteboard on this device (BOARD-2): kept until it's cleared.

final class WhiteboardStoreProvider
    extends
        $FunctionalProvider<WhiteboardStore, WhiteboardStore, WhiteboardStore>
    with $Provider<WhiteboardStore> {
  /// The whiteboard on this device (BOARD-2): kept until it's cleared.
  WhiteboardStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'whiteboardStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$whiteboardStoreHash();

  @$internal
  @override
  $ProviderElement<WhiteboardStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WhiteboardStore create(Ref ref) {
    return whiteboardStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WhiteboardStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WhiteboardStore>(value),
    );
  }
}

String _$whiteboardStoreHash() => r'8f424a4533a426562656799e362b0d41e2cbb874';

/// Counts the plays put on the whiteboard from elsewhere, so an open
/// whiteboard starts over with what's now kept.

@ProviderFor(WhiteboardRevision)
final whiteboardRevisionProvider = WhiteboardRevisionProvider._();

/// Counts the plays put on the whiteboard from elsewhere, so an open
/// whiteboard starts over with what's now kept.
final class WhiteboardRevisionProvider
    extends $NotifierProvider<WhiteboardRevision, int> {
  /// Counts the plays put on the whiteboard from elsewhere, so an open
  /// whiteboard starts over with what's now kept.
  WhiteboardRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'whiteboardRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$whiteboardRevisionHash();

  @$internal
  @override
  WhiteboardRevision create() => WhiteboardRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$whiteboardRevisionHash() =>
    r'5e144a3e543018666ed241c2afa548828438e43f';

/// Counts the plays put on the whiteboard from elsewhere, so an open
/// whiteboard starts over with what's now kept.

abstract class _$WhiteboardRevision extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
