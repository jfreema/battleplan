// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(safetyRepository)
final safetyRepositoryProvider = SafetyRepositoryProvider._();

/// Overridden in app/providers.dart.

final class SafetyRepositoryProvider
    extends
        $FunctionalProvider<
          SafetyRepository,
          SafetyRepository,
          SafetyRepository
        >
    with $Provider<SafetyRepository> {
  /// Overridden in app/providers.dart.
  SafetyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'safetyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$safetyRepositoryHash();

  @$internal
  @override
  $ProviderElement<SafetyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SafetyRepository create(Ref ref) {
    return safetyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SafetyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SafetyRepository>(value),
    );
  }
}

String _$safetyRepositoryHash() => r'505a6492c8822b9d54cb2bdc67d3b4e7acb77e43';

/// The people I blocked (SET-5).

@ProviderFor(blockedPeople)
final blockedPeopleProvider = BlockedPeopleProvider._();

/// The people I blocked (SET-5).

final class BlockedPeopleProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BlockedPerson>>,
          List<BlockedPerson>,
          Stream<List<BlockedPerson>>
        >
    with
        $FutureModifier<List<BlockedPerson>>,
        $StreamProvider<List<BlockedPerson>> {
  /// The people I blocked (SET-5).
  BlockedPeopleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockedPeopleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockedPeopleHash();

  @$internal
  @override
  $StreamProviderElement<List<BlockedPerson>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BlockedPerson>> create(Ref ref) {
    return blockedPeople(ref);
  }
}

String _$blockedPeopleHash() => r'24d5245782867e0fcf56deebfc4ad3d5fff9d8b3';

/// Just their IDs, for collapsing their messages (CHAT-12).

@ProviderFor(blockedIds)
final blockedIdsProvider = BlockedIdsProvider._();

/// Just their IDs, for collapsing their messages (CHAT-12).

final class BlockedIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// Just their IDs, for collapsing their messages (CHAT-12).
  BlockedIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockedIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockedIdsHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return blockedIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$blockedIdsHash() => r'6732ad31d3253982ca0ab4cf4e9dd8ccaf353065';

/// A team's open reports (SAFE-4). Only admins can read them.

@ProviderFor(openReports)
final openReportsProvider = OpenReportsFamily._();

/// A team's open reports (SAFE-4). Only admins can read them.

final class OpenReportsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Report>>,
          List<Report>,
          Stream<List<Report>>
        >
    with $FutureModifier<List<Report>>, $StreamProvider<List<Report>> {
  /// A team's open reports (SAFE-4). Only admins can read them.
  OpenReportsProvider._({
    required OpenReportsFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'openReportsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$openReportsHash();

  @override
  String toString() {
    return r'openReportsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Report>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Report>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return openReports(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OpenReportsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$openReportsHash() => r'dcc08646c09d2792d7b9912c5b4047c5547e8218';

/// A team's open reports (SAFE-4). Only admins can read them.

final class OpenReportsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Report>>, GroupId> {
  OpenReportsFamily._()
    : super(
        retry: null,
        name: r'openReportsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's open reports (SAFE-4). Only admins can read them.

  OpenReportsProvider call(GroupId groupId) =>
      OpenReportsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'openReportsProvider';
}
