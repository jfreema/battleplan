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

/// My direct conversations that have messages, newest first (CHAT-19):
/// my memberships of them, one query. Enough for the Messages badge; the
/// list reads each conversation too.

@ProviderFor(myDirectMemberships)
final myDirectMembershipsProvider = MyDirectMembershipsProvider._();

/// My direct conversations that have messages, newest first (CHAT-19):
/// my memberships of them, one query. Enough for the Messages badge; the
/// list reads each conversation too.

final class MyDirectMembershipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Membership>>,
          List<Membership>,
          Stream<List<Membership>>
        >
    with $FutureModifier<List<Membership>>, $StreamProvider<List<Membership>> {
  /// My direct conversations that have messages, newest first (CHAT-19):
  /// my memberships of them, one query. Enough for the Messages badge; the
  /// list reads each conversation too.
  MyDirectMembershipsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myDirectMembershipsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myDirectMembershipsHash();

  @$internal
  @override
  $StreamProviderElement<List<Membership>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Membership>> create(Ref ref) {
    return myDirectMemberships(ref);
  }
}

String _$myDirectMembershipsHash() =>
    r'6dff2163aa1c18a727054b0a4fb12326bf0d8b2c';

/// Someone's membership of a team I'm on, live, or null when they aren't
/// on it (the person page, TEAM-15); or mine of a direct conversation.

@ProviderFor(member)
final memberProvider = MemberFamily._();

/// Someone's membership of a team I'm on, live, or null when they aren't
/// on it (the person page, TEAM-15); or mine of a direct conversation.

final class MemberProvider
    extends
        $FunctionalProvider<
          AsyncValue<Membership?>,
          Membership?,
          Stream<Membership?>
        >
    with $FutureModifier<Membership?>, $StreamProvider<Membership?> {
  /// Someone's membership of a team I'm on, live, or null when they aren't
  /// on it (the person page, TEAM-15); or mine of a direct conversation.
  MemberProvider._({
    required MemberFamily super.from,
    required (GroupId, UserId) super.argument,
  }) : super(
         retry: null,
         name: r'memberProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberHash();

  @override
  String toString() {
    return r'memberProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Membership?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Membership?> create(Ref ref) {
    final argument = this.argument as (GroupId, UserId);
    return member(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberHash() => r'da2a66c34aa58bf7f4232679de23065a2bebd20a';

/// Someone's membership of a team I'm on, live, or null when they aren't
/// on it (the person page, TEAM-15); or mine of a direct conversation.

final class MemberFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Membership?>, (GroupId, UserId)> {
  MemberFamily._()
    : super(
        retry: null,
        name: r'memberProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Someone's membership of a team I'm on, live, or null when they aren't
  /// on it (the person page, TEAM-15); or mine of a direct conversation.

  MemberProvider call(GroupId groupId, UserId uid) =>
      MemberProvider._(argument: (groupId, uid), from: this);

  @override
  String toString() => r'memberProvider';
}

/// A team, live. One you can't read (removed, deleted, or suspended)
/// reads as null, and its read ends there. A suspension can be lifted with
/// nothing to tell its members, so while it's null the read starts over:
/// after [groupRetryFirst], doubling to [groupRetryMax], and whenever the
/// app comes back to the foreground (ADMIN-3).

@ProviderFor(group)
final groupProvider = GroupFamily._();

/// A team, live. One you can't read (removed, deleted, or suspended)
/// reads as null, and its read ends there. A suspension can be lifted with
/// nothing to tell its members, so while it's null the read starts over:
/// after [groupRetryFirst], doubling to [groupRetryMax], and whenever the
/// app comes back to the foreground (ADMIN-3).

final class GroupProvider
    extends $FunctionalProvider<AsyncValue<Group?>, Group?, Stream<Group?>>
    with $FutureModifier<Group?>, $StreamProvider<Group?> {
  /// A team, live. One you can't read (removed, deleted, or suspended)
  /// reads as null, and its read ends there. A suspension can be lifted with
  /// nothing to tell its members, so while it's null the read starts over:
  /// after [groupRetryFirst], doubling to [groupRetryMax], and whenever the
  /// app comes back to the foreground (ADMIN-3).
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

String _$groupHash() => r'e6fc99d8c38a4c2f44b26775508166e9339e9d75';

/// A team, live. One you can't read (removed, deleted, or suspended)
/// reads as null, and its read ends there. A suspension can be lifted with
/// nothing to tell its members, so while it's null the read starts over:
/// after [groupRetryFirst], doubling to [groupRetryMax], and whenever the
/// app comes back to the foreground (ADMIN-3).

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

  /// A team, live. One you can't read (removed, deleted, or suspended)
  /// reads as null, and its read ends there. A suspension can be lifted with
  /// nothing to tell its members, so while it's null the read starts over:
  /// after [groupRetryFirst], doubling to [groupRetryMax], and whenever the
  /// app comes back to the foreground (ADMIN-3).

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

/// The roster's order (TEAM-10), kept while the app runs.

@ProviderFor(RosterView)
final rosterViewProvider = RosterViewProvider._();

/// The roster's order (TEAM-10), kept while the app runs.
final class RosterViewProvider
    extends $NotifierProvider<RosterView, RosterOrder> {
  /// The roster's order (TEAM-10), kept while the app runs.
  RosterViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rosterViewProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rosterViewHash();

  @$internal
  @override
  RosterView create() => RosterView();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RosterOrder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RosterOrder>(value),
    );
  }
}

String _$rosterViewHash() => r'c433d3cc61a94551dfd261fd6173988d77a7a305';

/// The roster's order (TEAM-10), kept while the app runs.

abstract class _$RosterView extends $Notifier<RosterOrder> {
  RosterOrder build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RosterOrder, RosterOrder>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RosterOrder, RosterOrder>,
              RosterOrder,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

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

/// The signed-in person's membership on [groupId], if any: of a team, or
/// of a direct conversation (CHAT-19), which isn't among my teams and is
/// read on its own, only once the conversation shows it's one.

@ProviderFor(myMembership)
final myMembershipProvider = MyMembershipFamily._();

/// The signed-in person's membership on [groupId], if any: of a team, or
/// of a direct conversation (CHAT-19), which isn't among my teams and is
/// read on its own, only once the conversation shows it's one.

final class MyMembershipProvider
    extends $FunctionalProvider<Membership?, Membership?, Membership?>
    with $Provider<Membership?> {
  /// The signed-in person's membership on [groupId], if any: of a team, or
  /// of a direct conversation (CHAT-19), which isn't among my teams and is
  /// read on its own, only once the conversation shows it's one.
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

String _$myMembershipHash() => r'6db40062e5ba9ae9d8511799b59bd07c0d97bde7';

/// The signed-in person's membership on [groupId], if any: of a team, or
/// of a direct conversation (CHAT-19), which isn't among my teams and is
/// read on its own, only once the conversation shows it's one.

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

  /// The signed-in person's membership on [groupId], if any: of a team, or
  /// of a direct conversation (CHAT-19), which isn't among my teams and is
  /// read on its own, only once the conversation shows it's one.

  MyMembershipProvider call(GroupId groupId) =>
      MyMembershipProvider._(argument: groupId, from: this);

  @override
  String toString() => r'myMembershipProvider';
}

/// True while a super admin looks at a team they aren't on (ADMIN-3 View
/// team): its tabs, read-only, with the "Viewing as super admin" banner and
/// moderation. False until their memberships have loaded.

@ProviderFor(viewingAsSuperAdmin)
final viewingAsSuperAdminProvider = ViewingAsSuperAdminFamily._();

/// True while a super admin looks at a team they aren't on (ADMIN-3 View
/// team): its tabs, read-only, with the "Viewing as super admin" banner and
/// moderation. False until their memberships have loaded.

final class ViewingAsSuperAdminProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// True while a super admin looks at a team they aren't on (ADMIN-3 View
  /// team): its tabs, read-only, with the "Viewing as super admin" banner and
  /// moderation. False until their memberships have loaded.
  ViewingAsSuperAdminProvider._({
    required ViewingAsSuperAdminFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'viewingAsSuperAdminProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$viewingAsSuperAdminHash();

  @override
  String toString() {
    return r'viewingAsSuperAdminProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as GroupId;
    return viewingAsSuperAdmin(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ViewingAsSuperAdminProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$viewingAsSuperAdminHash() =>
    r'452fef99ee1b3c818872f0d790a4f19d04e60e1b';

/// True while a super admin looks at a team they aren't on (ADMIN-3 View
/// team): its tabs, read-only, with the "Viewing as super admin" banner and
/// moderation. False until their memberships have loaded.

final class ViewingAsSuperAdminFamily extends $Family
    with $FunctionalFamilyOverride<bool, GroupId> {
  ViewingAsSuperAdminFamily._()
    : super(
        retry: null,
        name: r'viewingAsSuperAdminProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// True while a super admin looks at a team they aren't on (ADMIN-3 View
  /// team): its tabs, read-only, with the "Viewing as super admin" banner and
  /// moderation. False until their memberships have loaded.

  ViewingAsSuperAdminProvider call(GroupId groupId) =>
      ViewingAsSuperAdminProvider._(argument: groupId, from: this);

  @override
  String toString() => r'viewingAsSuperAdminProvider';
}

/// Saves edits to [groupId] (TEAM-5, CHAT-18): directly for its admins,
/// through the audited admin callable for a super admin who isn't one
/// (ADMIN-3).

@ProviderFor(teamEditor)
final teamEditorProvider = TeamEditorFamily._();

/// Saves edits to [groupId] (TEAM-5, CHAT-18): directly for its admins,
/// through the audited admin callable for a super admin who isn't one
/// (ADMIN-3).

final class TeamEditorProvider
    extends $FunctionalProvider<TeamEditor, TeamEditor, TeamEditor>
    with $Provider<TeamEditor> {
  /// Saves edits to [groupId] (TEAM-5, CHAT-18): directly for its admins,
  /// through the audited admin callable for a super admin who isn't one
  /// (ADMIN-3).
  TeamEditorProvider._({
    required TeamEditorFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'teamEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamEditorHash();

  @override
  String toString() {
    return r'teamEditorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TeamEditor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamEditor create(Ref ref) {
    final argument = this.argument as GroupId;
    return teamEditor(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamEditor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamEditor>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeamEditorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamEditorHash() => r'7ee0f62407a06ba8cb292df9a3d11b23fe5a1ee2';

/// Saves edits to [groupId] (TEAM-5, CHAT-18): directly for its admins,
/// through the audited admin callable for a super admin who isn't one
/// (ADMIN-3).

final class TeamEditorFamily extends $Family
    with $FunctionalFamilyOverride<TeamEditor, GroupId> {
  TeamEditorFamily._()
    : super(
        retry: null,
        name: r'teamEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Saves edits to [groupId] (TEAM-5, CHAT-18): directly for its admins,
  /// through the audited admin callable for a super admin who isn't one
  /// (ADMIN-3).

  TeamEditorProvider call(GroupId groupId) =>
      TeamEditorProvider._(argument: groupId, from: this);

  @override
  String toString() => r'teamEditorProvider';
}

/// A URL for a stored team file (the logo, the chat background, or a Media
/// preview), or null.

@ProviderFor(teamPhotoUrl)
final teamPhotoUrlProvider = TeamPhotoUrlFamily._();

/// A URL for a stored team file (the logo, the chat background, or a Media
/// preview), or null.

final class TeamPhotoUrlProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// A URL for a stored team file (the logo, the chat background, or a Media
  /// preview), or null.
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

/// A URL for a stored team file (the logo, the chat background, or a Media
/// preview), or null.

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

  /// A URL for a stored team file (the logo, the chat background, or a Media
  /// preview), or null.

  TeamPhotoUrlProvider call(String path) =>
      TeamPhotoUrlProvider._(argument: path, from: this);

  @override
  String toString() => r'teamPhotoUrlProvider';
}

/// Overridden in app/providers.dart.

@ProviderFor(mediaRepository)
final mediaRepositoryProvider = MediaRepositoryProvider._();

/// Overridden in app/providers.dart.

final class MediaRepositoryProvider
    extends
        $FunctionalProvider<MediaRepository, MediaRepository, MediaRepository>
    with $Provider<MediaRepository> {
  /// Overridden in app/providers.dart.
  MediaRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaRepositoryHash();

  @$internal
  @override
  $ProviderElement<MediaRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaRepository create(Ref ref) {
    return mediaRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaRepository>(value),
    );
  }
}

String _$mediaRepositoryHash() => r'365ae5bb296846cf714f71c6b13adffc61bd2587';

/// The team's files, largest first, for Media (STORE-5). Read once per
/// visit (it lists the bucket); invalidate to refresh after a delete.

@ProviderFor(teamMedia)
final teamMediaProvider = TeamMediaFamily._();

/// The team's files, largest first, for Media (STORE-5). Read once per
/// visit (it lists the bucket); invalidate to refresh after a delete.

final class TeamMediaProvider
    extends
        $FunctionalProvider<
          AsyncValue<TeamMedia>,
          TeamMedia,
          FutureOr<TeamMedia>
        >
    with $FutureModifier<TeamMedia>, $FutureProvider<TeamMedia> {
  /// The team's files, largest first, for Media (STORE-5). Read once per
  /// visit (it lists the bucket); invalidate to refresh after a delete.
  TeamMediaProvider._({
    required TeamMediaFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'teamMediaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamMediaHash();

  @override
  String toString() {
    return r'teamMediaProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TeamMedia> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TeamMedia> create(Ref ref) {
    final argument = this.argument as GroupId;
    return teamMedia(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamMediaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamMediaHash() => r'738964d53460208666f1a4048eb1cd9a5d9fce0a';

/// The team's files, largest first, for Media (STORE-5). Read once per
/// visit (it lists the bucket); invalidate to refresh after a delete.

final class TeamMediaFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TeamMedia>, GroupId> {
  TeamMediaFamily._()
    : super(
        retry: null,
        name: r'teamMediaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The team's files, largest first, for Media (STORE-5). Read once per
  /// visit (it lists the bucket); invalidate to refresh after a delete.

  TeamMediaProvider call(GroupId groupId) =>
      TeamMediaProvider._(argument: groupId, from: this);

  @override
  String toString() => r'teamMediaProvider';
}

/// Storage banners dismissed this session, by team and level (STORE-3,
/// STORE-4). Each level is its own, so filling up after dismissing the 90%
/// warning still shows the full banner. A new sign-in starts over.

@ProviderFor(DismissedStorageBanners)
final dismissedStorageBannersProvider = DismissedStorageBannersProvider._();

/// Storage banners dismissed this session, by team and level (STORE-3,
/// STORE-4). Each level is its own, so filling up after dismissing the 90%
/// warning still shows the full banner. A new sign-in starts over.
final class DismissedStorageBannersProvider
    extends
        $NotifierProvider<
          DismissedStorageBanners,
          Set<(GroupId, StorageLevel)>
        > {
  /// Storage banners dismissed this session, by team and level (STORE-3,
  /// STORE-4). Each level is its own, so filling up after dismissing the 90%
  /// warning still shows the full banner. A new sign-in starts over.
  DismissedStorageBannersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dismissedStorageBannersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dismissedStorageBannersHash();

  @$internal
  @override
  DismissedStorageBanners create() => DismissedStorageBanners();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<(GroupId, StorageLevel)> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<(GroupId, StorageLevel)>>(value),
    );
  }
}

String _$dismissedStorageBannersHash() =>
    r'4e7692471bb8bd63fdc5cb7cfcb6043cde8287f0';

/// Storage banners dismissed this session, by team and level (STORE-3,
/// STORE-4). Each level is its own, so filling up after dismissing the 90%
/// warning still shows the full banner. A new sign-in starts over.

abstract class _$DismissedStorageBanners
    extends $Notifier<Set<(GroupId, StorageLevel)>> {
  Set<(GroupId, StorageLevel)> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<Set<(GroupId, StorageLevel)>, Set<(GroupId, StorageLevel)>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Set<(GroupId, StorageLevel)>,
                Set<(GroupId, StorageLevel)>
              >,
              Set<(GroupId, StorageLevel)>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
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

/// The team's email invites with their state (INV-4).

@ProviderFor(emailInvites)
final emailInvitesProvider = EmailInvitesFamily._();

/// The team's email invites with their state (INV-4).

final class EmailInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EmailInvite>>,
          List<EmailInvite>,
          FutureOr<List<EmailInvite>>
        >
    with
        $FutureModifier<List<EmailInvite>>,
        $FutureProvider<List<EmailInvite>> {
  /// The team's email invites with their state (INV-4).
  EmailInvitesProvider._({
    required EmailInvitesFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'emailInvitesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$emailInvitesHash();

  @override
  String toString() {
    return r'emailInvitesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<EmailInvite>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EmailInvite>> create(Ref ref) {
    final argument = this.argument as GroupId;
    return emailInvites(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EmailInvitesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$emailInvitesHash() => r'd67d0ed6b55d83c8e6d2a96284fd00caef8212bd';

/// The team's email invites with their state (INV-4).

final class EmailInvitesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<EmailInvite>>, GroupId> {
  EmailInvitesFamily._()
    : super(
        retry: null,
        name: r'emailInvitesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The team's email invites with their state (INV-4).

  EmailInvitesProvider call(GroupId groupId) =>
      EmailInvitesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'emailInvitesProvider';
}
