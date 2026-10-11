import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';

abstract interface class GroupRepository {
  /// A single team. Emits null if it's gone or the caller can't read it.
  Stream<Group?> watchGroup(GroupId id);

  /// Creates a team with the caller as owner (TEAM-1) and returns its ID.
  /// [color] is one of the 12 team colors as `#RRGGBB`.
  Future<GroupId> createGroup({
    required String name,
    required Sport sport,
    required TeamType teamType,
    required String timeZone,
    String? color,
    String? description,
  });
}

abstract interface class MemberRepository {
  /// The caller's own memberships, one per team (at most 100, TEAM-2).
  Stream<List<Membership>> watchMyMemberships(UserId uid);
}
