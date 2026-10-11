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

  /// A team's roster (TEAM-3). Readable by its members.
  Stream<List<Membership>> watchRoster(GroupId groupId);

  /// Makes someone an admin or a member, or sets their title (TEAM-4).
  /// Only the owner (or a super admin) can take admin away.
  Future<void> updateMember(
    GroupId groupId,
    UserId uid, {
    MemberRole? role,
    String? title,
    bool clearTitle = false,
  });

  /// Removes someone from the team (TEAM-3).
  Future<void> removeMember(GroupId groupId, UserId uid);
}
