// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(duesRepository)
final duesRepositoryProvider = DuesRepositoryProvider._();

/// Overridden in app/providers.dart.

final class DuesRepositoryProvider
    extends $FunctionalProvider<DuesRepository, DuesRepository, DuesRepository>
    with $Provider<DuesRepository> {
  /// Overridden in app/providers.dart.
  DuesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'duesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$duesRepositoryHash();

  @$internal
  @override
  $ProviderElement<DuesRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DuesRepository create(Ref ref) {
    return duesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DuesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DuesRepository>(value),
    );
  }
}

String _$duesRepositoryHash() => r'd9472d1702e7d0d016169120aa779a83fa21d35b';

/// The team's dues (admins, DUES-1).

@ProviderFor(teamDues)
final teamDuesProvider = TeamDuesFamily._();

/// The team's dues (admins, DUES-1).

final class TeamDuesProvider
    extends
        $FunctionalProvider<AsyncValue<List<Due>>, List<Due>, Stream<List<Due>>>
    with $FutureModifier<List<Due>>, $StreamProvider<List<Due>> {
  /// The team's dues (admins, DUES-1).
  TeamDuesProvider._({
    required TeamDuesFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'teamDuesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamDuesHash();

  @override
  String toString() {
    return r'teamDuesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Due>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Due>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return teamDues(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamDuesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamDuesHash() => r'1ff661cbfce263ba75fbac3420da758b03e52a23';

/// The team's dues (admins, DUES-1).

final class TeamDuesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Due>>, GroupId> {
  TeamDuesFamily._()
    : super(
        retry: null,
        name: r'teamDuesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The team's dues (admins, DUES-1).

  TeamDuesProvider call(GroupId groupId) =>
      TeamDuesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'teamDuesProvider';
}

/// Everyone's share of one due (admins, DUES-2).

@ProviderFor(dueCharges)
final dueChargesProvider = DueChargesFamily._();

/// Everyone's share of one due (admins, DUES-2).

final class DueChargesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DueCharge>>,
          List<DueCharge>,
          Stream<List<DueCharge>>
        >
    with $FutureModifier<List<DueCharge>>, $StreamProvider<List<DueCharge>> {
  /// Everyone's share of one due (admins, DUES-2).
  DueChargesProvider._({
    required DueChargesFamily super.from,
    required (GroupId, String) super.argument,
  }) : super(
         retry: null,
         name: r'dueChargesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dueChargesHash();

  @override
  String toString() {
    return r'dueChargesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<DueCharge>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DueCharge>> create(Ref ref) {
    final argument = this.argument as (GroupId, String);
    return dueCharges(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is DueChargesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dueChargesHash() => r'fc0961c9e56990c770184092751cea00b8454b4c';

/// Everyone's share of one due (admins, DUES-2).

final class DueChargesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<DueCharge>>, (GroupId, String)> {
  DueChargesFamily._()
    : super(
        retry: null,
        name: r'dueChargesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everyone's share of one due (admins, DUES-2).

  DueChargesProvider call(GroupId groupId, String dueId) =>
      DueChargesProvider._(argument: (groupId, dueId), from: this);

  @override
  String toString() => r'dueChargesProvider';
}

/// Every share of every due on [groupId] (admins, DUES-5), for the totals
/// on Dues and Who owes what: each due's own shares ([dueCharges], the
/// same reads the due cards make), together. Loading until the dues and
/// every one's shares have loaded, and failing when any of them fails, so
/// a total is never shown short.

@ProviderFor(teamCharges)
final teamChargesProvider = TeamChargesFamily._();

/// Every share of every due on [groupId] (admins, DUES-5), for the totals
/// on Dues and Who owes what: each due's own shares ([dueCharges], the
/// same reads the due cards make), together. Loading until the dues and
/// every one's shares have loaded, and failing when any of them fails, so
/// a total is never shown short.

final class TeamChargesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DueCharge>>,
          AsyncValue<List<DueCharge>>,
          AsyncValue<List<DueCharge>>
        >
    with $Provider<AsyncValue<List<DueCharge>>> {
  /// Every share of every due on [groupId] (admins, DUES-5), for the totals
  /// on Dues and Who owes what: each due's own shares ([dueCharges], the
  /// same reads the due cards make), together. Loading until the dues and
  /// every one's shares have loaded, and failing when any of them fails, so
  /// a total is never shown short.
  TeamChargesProvider._({
    required TeamChargesFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'teamChargesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamChargesHash();

  @override
  String toString() {
    return r'teamChargesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<DueCharge>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<DueCharge>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return teamCharges(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<DueCharge>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<DueCharge>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeamChargesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamChargesHash() => r'71e58e03d4be74ab60f401ce9e910509476f2374';

/// Every share of every due on [groupId] (admins, DUES-5), for the totals
/// on Dues and Who owes what: each due's own shares ([dueCharges], the
/// same reads the due cards make), together. Loading until the dues and
/// every one's shares have loaded, and failing when any of them fails, so
/// a total is never shown short.

final class TeamChargesFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<DueCharge>>, GroupId> {
  TeamChargesFamily._()
    : super(
        retry: null,
        name: r'teamChargesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every share of every due on [groupId] (admins, DUES-5), for the totals
  /// on Dues and Who owes what: each due's own shares ([dueCharges], the
  /// same reads the due cards make), together. Loading until the dues and
  /// every one's shares have loaded, and failing when any of them fails, so
  /// a total is never shown short.

  TeamChargesProvider call(GroupId groupId) =>
      TeamChargesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'teamChargesProvider';
}

/// Who I pay for on [groupId] (DUES-2): my players on a team, myself in a
/// group, the same people I answer RSVPs for ([participantsFor]). On a team
/// I'm also there myself, last, for any shares of mine from before it was
/// a group made a team (TEAM-14); there are none on other teams. Loading
/// until my membership, the team, and on a team its players and player
/// links have loaded, and failing when any of them fails, so nobody is told
/// they owe nothing before it's known whom they pay for.

@ProviderFor(myPayers)
final myPayersProvider = MyPayersFamily._();

/// Who I pay for on [groupId] (DUES-2): my players on a team, myself in a
/// group, the same people I answer RSVPs for ([participantsFor]). On a team
/// I'm also there myself, last, for any shares of mine from before it was
/// a group made a team (TEAM-14); there are none on other teams. Loading
/// until my membership, the team, and on a team its players and player
/// links have loaded, and failing when any of them fails, so nobody is told
/// they owe nothing before it's known whom they pay for.

final class MyPayersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DuePayer>>,
          AsyncValue<List<DuePayer>>,
          AsyncValue<List<DuePayer>>
        >
    with $Provider<AsyncValue<List<DuePayer>>> {
  /// Who I pay for on [groupId] (DUES-2): my players on a team, myself in a
  /// group, the same people I answer RSVPs for ([participantsFor]). On a team
  /// I'm also there myself, last, for any shares of mine from before it was
  /// a group made a team (TEAM-14); there are none on other teams. Loading
  /// until my membership, the team, and on a team its players and player
  /// links have loaded, and failing when any of them fails, so nobody is told
  /// they owe nothing before it's known whom they pay for.
  MyPayersProvider._({
    required MyPayersFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'myPayersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myPayersHash();

  @override
  String toString() {
    return r'myPayersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<DuePayer>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<DuePayer>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return myPayers(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<DuePayer>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<DuePayer>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MyPayersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myPayersHash() => r'5e67f27342616c1ee2f415e71de2f769e6973d25';

/// Who I pay for on [groupId] (DUES-2): my players on a team, myself in a
/// group, the same people I answer RSVPs for ([participantsFor]). On a team
/// I'm also there myself, last, for any shares of mine from before it was
/// a group made a team (TEAM-14); there are none on other teams. Loading
/// until my membership, the team, and on a team its players and player
/// links have loaded, and failing when any of them fails, so nobody is told
/// they owe nothing before it's known whom they pay for.

final class MyPayersFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<DuePayer>>, GroupId> {
  MyPayersFamily._()
    : super(
        retry: null,
        name: r'myPayersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Who I pay for on [groupId] (DUES-2): my players on a team, myself in a
  /// group, the same people I answer RSVPs for ([participantsFor]). On a team
  /// I'm also there myself, last, for any shares of mine from before it was
  /// a group made a team (TEAM-14); there are none on other teams. Loading
  /// until my membership, the team, and on a team its players and player
  /// links have loaded, and failing when any of them fails, so nobody is told
  /// they owe nothing before it's known whom they pay for.

  MyPayersProvider call(GroupId groupId) =>
      MyPayersProvider._(argument: groupId, from: this);

  @override
  String toString() => r'myPayersProvider';
}

/// What I owe on [groupId] (DUES-2): my own share, or my players'. Loading
/// until [myPayers] knows whom I pay for, and failing when it fails.

@ProviderFor(myCharges)
final myChargesProvider = MyChargesFamily._();

/// What I owe on [groupId] (DUES-2): my own share, or my players'. Loading
/// until [myPayers] knows whom I pay for, and failing when it fails.

final class MyChargesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DueCharge>>,
          List<DueCharge>,
          Stream<List<DueCharge>>
        >
    with $FutureModifier<List<DueCharge>>, $StreamProvider<List<DueCharge>> {
  /// What I owe on [groupId] (DUES-2): my own share, or my players'. Loading
  /// until [myPayers] knows whom I pay for, and failing when it fails.
  MyChargesProvider._({
    required MyChargesFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'myChargesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myChargesHash();

  @override
  String toString() {
    return r'myChargesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<DueCharge>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DueCharge>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return myCharges(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyChargesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myChargesHash() => r'c95ac9bacabea0bdfce3600fbf8f74a3ff7b7dbd';

/// What I owe on [groupId] (DUES-2): my own share, or my players'. Loading
/// until [myPayers] knows whom I pay for, and failing when it fails.

final class MyChargesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<DueCharge>>, GroupId> {
  MyChargesFamily._()
    : super(
        retry: null,
        name: r'myChargesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What I owe on [groupId] (DUES-2): my own share, or my players'. Loading
  /// until [myPayers] knows whom I pay for, and failing when it fails.

  MyChargesProvider call(GroupId groupId) =>
      MyChargesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'myChargesProvider';
}

/// How to pay the team (DUES-3).

@ProviderFor(duesPayments)
final duesPaymentsProvider = DuesPaymentsFamily._();

/// How to pay the team (DUES-3).

final class DuesPaymentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DuesPayments>,
          DuesPayments,
          Stream<DuesPayments>
        >
    with $FutureModifier<DuesPayments>, $StreamProvider<DuesPayments> {
  /// How to pay the team (DUES-3).
  DuesPaymentsProvider._({
    required DuesPaymentsFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'duesPaymentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$duesPaymentsHash();

  @override
  String toString() {
    return r'duesPaymentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<DuesPayments> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DuesPayments> create(Ref ref) {
    final argument = this.argument as GroupId;
    return duesPayments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DuesPaymentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$duesPaymentsHash() => r'377839e9d302ccdad11184b7d8da732cff8a0ac6';

/// How to pay the team (DUES-3).

final class DuesPaymentsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<DuesPayments>, GroupId> {
  DuesPaymentsFamily._()
    : super(
        retry: null,
        name: r'duesPaymentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How to pay the team (DUES-3).

  DuesPaymentsProvider call(GroupId groupId) =>
      DuesPaymentsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'duesPaymentsProvider';
}
