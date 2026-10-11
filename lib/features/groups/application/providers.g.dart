// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(groupRepository)
final groupRepositoryProvider = GroupRepositoryProvider._();

/// Overridden in app/providers.dart.

final class GroupRepositoryProvider
    extends
        $FunctionalProvider<GroupRepository, GroupRepository, GroupRepository>
    with $Provider<GroupRepository> {
  /// Overridden in app/providers.dart.
  GroupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupRepositoryHash();

  @$internal
  @override
  $ProviderElement<GroupRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GroupRepository create(Ref ref) {
    return groupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupRepository>(value),
    );
  }
}

String _$groupRepositoryHash() => r'1cf5e97dbc58f8465340fa5c0a7b93e415cf4fc6';

/// Overridden in app/providers.dart.

@ProviderFor(memberRepository)
final memberRepositoryProvider = MemberRepositoryProvider._();

/// Overridden in app/providers.dart.

final class MemberRepositoryProvider
    extends
        $FunctionalProvider<
          MemberRepository,
          MemberRepository,
          MemberRepository
        >
    with $Provider<MemberRepository> {
  /// Overridden in app/providers.dart.
  MemberRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberRepositoryHash();

  @$internal
  @override
  $ProviderElement<MemberRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MemberRepository create(Ref ref) {
    return memberRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemberRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemberRepository>(value),
    );
  }
}

String _$memberRepositoryHash() => r'b19ee46c27e04be343cbe4aa020cfa3e902e1ac0';

@ProviderFor(myMemberships)
final myMembershipsProvider = MyMembershipsProvider._();

final class MyMembershipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Membership>>,
          List<Membership>,
          Stream<List<Membership>>
        >
    with $FutureModifier<List<Membership>>, $StreamProvider<List<Membership>> {
  MyMembershipsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myMembershipsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myMembershipsHash();

  @$internal
  @override
  $StreamProviderElement<List<Membership>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Membership>> create(Ref ref) {
    return myMemberships(ref);
  }
}

String _$myMembershipsHash() => r'3c7f5221b372f48e0de076a2a0b4941b6e9a3500';

@ProviderFor(group)
final groupProvider = GroupFamily._();

final class GroupProvider
    extends $FunctionalProvider<AsyncValue<Group?>, Group?, Stream<Group?>>
    with $FutureModifier<Group?>, $StreamProvider<Group?> {
  GroupProvider._({
    required GroupFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'groupProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupHash();

  @override
  String toString() {
    return r'groupProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Group?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Group?> create(Ref ref) {
    final argument = this.argument as GroupId;
    return group(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupHash() => r'8f0d95c22926eb09c879e9739fcdd3cb9822833c';

final class GroupFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Group?>, GroupId> {
  GroupFamily._()
    : super(
        retry: null,
        name: r'groupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GroupProvider call(GroupId id) => GroupProvider._(argument: id, from: this);

  @override
  String toString() => r'groupProvider';
}

/// The switcher's list: one group read per membership (ARCH §6.2 query
/// table), most recent activity first, archived teams last.

@ProviderFor(myTeams)
final myTeamsProvider = MyTeamsProvider._();

/// The switcher's list: one group read per membership (ARCH §6.2 query
/// table), most recent activity first, archived teams last.

final class MyTeamsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MyTeam>>,
          AsyncValue<List<MyTeam>>,
          AsyncValue<List<MyTeam>>
        >
    with $Provider<AsyncValue<List<MyTeam>>> {
  /// The switcher's list: one group read per membership (ARCH §6.2 query
  /// table), most recent activity first, archived teams last.
  MyTeamsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myTeamsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myTeamsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<MyTeam>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<MyTeam>> create(Ref ref) {
    return myTeams(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<MyTeam>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<MyTeam>>>(value),
    );
  }
}

String _$myTeamsHash() => r'cc5acf94ad9d18a01c61592c8c94979afd05bdc4';

/// A team's roster, sorted by name (TEAM-3).

@ProviderFor(roster)
final rosterProvider = RosterFamily._();

/// A team's roster, sorted by name (TEAM-3).

final class RosterProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Membership>>,
          List<Membership>,
          Stream<List<Membership>>
        >
    with $FutureModifier<List<Membership>>, $StreamProvider<List<Membership>> {
  /// A team's roster, sorted by name (TEAM-3).
  RosterProvider._({
    required RosterFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'rosterProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rosterHash();

  @override
  String toString() {
    return r'rosterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Membership>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Membership>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return roster(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RosterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rosterHash() => r'71eba9f25085ba9d46d57910e3fe7c79023c573e';

/// A team's roster, sorted by name (TEAM-3).

final class RosterFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Membership>>, GroupId> {
  RosterFamily._()
    : super(
        retry: null,
        name: r'rosterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's roster, sorted by name (TEAM-3).

  RosterProvider call(GroupId groupId) =>
      RosterProvider._(argument: groupId, from: this);

  @override
  String toString() => r'rosterProvider';
}

/// The signed-in person's membership on [groupId], if any.

@ProviderFor(myMembership)
final myMembershipProvider = MyMembershipFamily._();

/// The signed-in person's membership on [groupId], if any.

final class MyMembershipProvider
    extends $FunctionalProvider<Membership?, Membership?, Membership?>
    with $Provider<Membership?> {
  /// The signed-in person's membership on [groupId], if any.
  MyMembershipProvider._({
    required MyMembershipFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'myMembershipProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myMembershipHash();

  @override
  String toString() {
    return r'myMembershipProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Membership?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Membership? create(Ref ref) {
    final argument = this.argument as GroupId;
    return myMembership(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Membership? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Membership?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MyMembershipProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myMembershipHash() => r'5eca66810f071d3c929e0ad39d9f8c4e8f18f865';

/// The signed-in person's membership on [groupId], if any.

final class MyMembershipFamily extends $Family
    with $FunctionalFamilyOverride<Membership?, GroupId> {
  MyMembershipFamily._()
    : super(
        retry: null,
        name: r'myMembershipProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The signed-in person's membership on [groupId], if any.

  MyMembershipProvider call(GroupId groupId) =>
      MyMembershipProvider._(argument: groupId, from: this);

  @override
  String toString() => r'myMembershipProvider';
}

/// A URL for a team logo path, or null.

@ProviderFor(teamPhotoUrl)
final teamPhotoUrlProvider = TeamPhotoUrlFamily._();

/// A URL for a team logo path, or null.

final class TeamPhotoUrlProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// A URL for a team logo path, or null.
  TeamPhotoUrlProvider._({
    required TeamPhotoUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamPhotoUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamPhotoUrlHash();

  @override
  String toString() {
    return r'teamPhotoUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return teamPhotoUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamPhotoUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamPhotoUrlHash() => r'6d8e54677d8b41b22c87a6bf8c79309c213a2659';

/// A URL for a team logo path, or null.

final class TeamPhotoUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  TeamPhotoUrlFamily._()
    : super(
        retry: null,
        name: r'teamPhotoUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A URL for a team logo path, or null.

  TeamPhotoUrlProvider call(String path) =>
      TeamPhotoUrlProvider._(argument: path, from: this);

  @override
  String toString() => r'teamPhotoUrlProvider';
}

/// Overridden in app/providers.dart.

@ProviderFor(inviteRepository)
final inviteRepositoryProvider = InviteRepositoryProvider._();

/// Overridden in app/providers.dart.

final class InviteRepositoryProvider
    extends
        $FunctionalProvider<
          InviteRepository,
          InviteRepository,
          InviteRepository
        >
    with $Provider<InviteRepository> {
  /// Overridden in app/providers.dart.
  InviteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inviteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inviteRepositoryHash();

  @$internal
  @override
  $ProviderElement<InviteRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InviteRepository create(Ref ref) {
    return inviteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InviteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InviteRepository>(value),
    );
  }
}

String _$inviteRepositoryHash() => r'406850cc6cb375431bcbb131385c5700c2300c50';

/// The team's invite link (INV-1).

@ProviderFor(teamInvite)
final teamInviteProvider = TeamInviteFamily._();

/// The team's invite link (INV-1).

final class TeamInviteProvider
    extends
        $FunctionalProvider<
          AsyncValue<TeamInvite>,
          TeamInvite,
          FutureOr<TeamInvite>
        >
    with $FutureModifier<TeamInvite>, $FutureProvider<TeamInvite> {
  /// The team's invite link (INV-1).
  TeamInviteProvider._({
    required TeamInviteFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'teamInviteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamInviteHash();

  @override
  String toString() {
    return r'teamInviteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TeamInvite> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TeamInvite> create(Ref ref) {
    final argument = this.argument as GroupId;
    return teamInvite(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamInviteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamInviteHash() => r'c377d0242450f2f2e352314eb0b2a3d2f45e5976';

/// The team's invite link (INV-1).

final class TeamInviteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TeamInvite>, GroupId> {
  TeamInviteFamily._()
    : super(
        retry: null,
        name: r'teamInviteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The team's invite link (INV-1).

  TeamInviteProvider call(GroupId groupId) =>
      TeamInviteProvider._(argument: groupId, from: this);

  @override
  String toString() => r'teamInviteProvider';
}
