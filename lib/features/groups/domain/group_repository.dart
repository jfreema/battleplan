import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';

abstract interface class GroupRepository {
  /// A single team. Emits null if it's gone or the caller can't read it.
  Stream<Group?> watchGroup(GroupId id);
}

abstract interface class MemberRepository {
  /// The caller's own memberships, one per team (at most 100, TEAM-2).
  Stream<List<Membership>> watchMyMemberships(UserId uid);
}
