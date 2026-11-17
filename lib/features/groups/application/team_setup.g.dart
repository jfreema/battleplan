// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_setup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The setup card at the top of a new team's chat (TEAM-1, #3), with what's
/// done of its steps, or null where it doesn't show. Only the team's admins
/// see it (the owner and admins, not members, and not a super admin
/// viewing the team), only on a team made since the card shipped and in
/// its first 30 days ([Group.inSetupWindow]), and only until they put it
/// away ([Membership.setupClosed]).
///
/// Its own file, so groups' providers don't import the schedule's, which
/// import them.

@ProviderFor(teamSetup)
final teamSetupProvider = TeamSetupFamily._();

/// The setup card at the top of a new team's chat (TEAM-1, #3), with what's
/// done of its steps, or null where it doesn't show. Only the team's admins
/// see it (the owner and admins, not members, and not a super admin
/// viewing the team), only on a team made since the card shipped and in
/// its first 30 days ([Group.inSetupWindow]), and only until they put it
/// away ([Membership.setupClosed]).
///
/// Its own file, so groups' providers don't import the schedule's, which
/// import them.

final class TeamSetupProvider
    extends $FunctionalProvider<TeamSetup?, TeamSetup?, TeamSetup?>
    with $Provider<TeamSetup?> {
  /// The setup card at the top of a new team's chat (TEAM-1, #3), with what's
  /// done of its steps, or null where it doesn't show. Only the team's admins
  /// see it (the owner and admins, not members, and not a super admin
  /// viewing the team), only on a team made since the card shipped and in
  /// its first 30 days ([Group.inSetupWindow]), and only until they put it
  /// away ([Membership.setupClosed]).
  ///
  /// Its own file, so groups' providers don't import the schedule's, which
  /// import them.
  TeamSetupProvider._({
    required TeamSetupFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'teamSetupProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamSetupHash();

  @override
  String toString() {
    return r'teamSetupProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TeamSetup?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamSetup? create(Ref ref) {
    final argument = this.argument as GroupId;
    return teamSetup(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamSetup? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamSetup?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeamSetupProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamSetupHash() => r'fae3928b2429cad544c1e7abf0d25318e601d1c8';

/// The setup card at the top of a new team's chat (TEAM-1, #3), with what's
/// done of its steps, or null where it doesn't show. Only the team's admins
/// see it (the owner and admins, not members, and not a super admin
/// viewing the team), only on a team made since the card shipped and in
/// its first 30 days ([Group.inSetupWindow]), and only until they put it
/// away ([Membership.setupClosed]).
///
/// Its own file, so groups' providers don't import the schedule's, which
/// import them.

final class TeamSetupFamily extends $Family
    with $FunctionalFamilyOverride<TeamSetup?, GroupId> {
  TeamSetupFamily._()
    : super(
        retry: null,
        name: r'teamSetupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The setup card at the top of a new team's chat (TEAM-1, #3), with what's
  /// done of its steps, or null where it doesn't show. Only the team's admins
  /// see it (the owner and admins, not members, and not a super admin
  /// viewing the team), only on a team made since the card shipped and in
  /// its first 30 days ([Group.inSetupWindow]), and only until they put it
  /// away ([Membership.setupClosed]).
  ///
  /// Its own file, so groups' providers don't import the schedule's, which
  /// import them.

  TeamSetupProvider call(GroupId groupId) =>
      TeamSetupProvider._(argument: groupId, from: this);

  @override
  String toString() => r'teamSetupProvider';
}
