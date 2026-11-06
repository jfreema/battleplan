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

/// Who I pay for on [groupId] (DUES-2): my players on a team, myself in a
/// group, the same people I answer RSVPs for.

@ProviderFor(myPayers)
final myPayersProvider = MyPayersFamily._();

/// Who I pay for on [groupId] (DUES-2): my players on a team, myself in a
/// group, the same people I answer RSVPs for.

final class MyPayersProvider
    extends $FunctionalProvider<List<DuePayer>, List<DuePayer>, List<DuePayer>>
    with $Provider<List<DuePayer>> {
  /// Who I pay for on [groupId] (DUES-2): my players on a team, myself in a
  /// group, the same people I answer RSVPs for.
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
  $ProviderElement<List<DuePayer>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<DuePayer> create(Ref ref) {
    final argument = this.argument as GroupId;
    return myPayers(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DuePayer> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DuePayer>>(value),
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

String _$myPayersHash() => r'def1a61ecde0632dc4df23720b1340b4f2c90512';

/// Who I pay for on [groupId] (DUES-2): my players on a team, myself in a
/// group, the same people I answer RSVPs for.

final class MyPayersFamily extends $Family
    with $FunctionalFamilyOverride<List<DuePayer>, GroupId> {
  MyPayersFamily._()
    : super(
        retry: null,
        name: r'myPayersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Who I pay for on [groupId] (DUES-2): my players on a team, myself in a
  /// group, the same people I answer RSVPs for.

  MyPayersProvider call(GroupId groupId) =>
      MyPayersProvider._(argument: groupId, from: this);

  @override
  String toString() => r'myPayersProvider';
}

/// What I owe on [groupId] (DUES-2): my own share, or my players'.

@ProviderFor(myCharges)
final myChargesProvider = MyChargesFamily._();

/// What I owe on [groupId] (DUES-2): my own share, or my players'.

final class MyChargesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DueCharge>>,
          List<DueCharge>,
          Stream<List<DueCharge>>
        >
    with $FutureModifier<List<DueCharge>>, $StreamProvider<List<DueCharge>> {
  /// What I owe on [groupId] (DUES-2): my own share, or my players'.
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

String _$myChargesHash() => r'69b619db6a29abb0a318e4747ef68bb971240bc2';

/// What I owe on [groupId] (DUES-2): my own share, or my players'.

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

  /// What I owe on [groupId] (DUES-2): my own share, or my players'.

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
