import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';

abstract interface class GroupRepository {
  /// A single team. Emits null if it's gone or the caller can't read it.
  Stream<Group?> watchGroup(GroupId id);

  /// Edits the team profile and settings (TEAM-5). Admins only.
  Future<void> updateGroup(
    GroupId id, {
    String? name,
    Sport? sport,
    String? color,
    String? description,
    String? timeZone,
    GroupSettings? settings,
  });

  /// Uploads a new team logo (TEAM-1, TEAM-5). Admins only.
  Future<void> uploadLogo(GroupId id, Uint8List jpegBytes);

  /// Saves the chat look (PLAN-8). Admins of Plus teams.
  Future<void> updateChatTheme(GroupId id, ChatTheme theme);

  /// Uploads a chat background photo and returns its path (PLAN-8).
  Future<String> uploadChatBackground(GroupId id, Uint8List jpegBytes);

  /// Hands the team to another member (TEAM-6). Owner only.
  Future<void> transferOwnership(GroupId id, UserId newOwner);

  /// Leaves the team (TEAM-8). Throws OwnerMustTransfer for the owner.
  Future<void> leave(GroupId id);

  /// Archives (read-only) or restores the team (TEAM-9). Owner only.
  Future<void> setArchived(GroupId id, {required bool archived});

  /// Permanently deletes the team; [confirmName] must match (TEAM-9).
  Future<void> deleteGroup(GroupId id, String confirmName);

  /// A URL to show a stored team photo, or null.
  Future<String?> photoUrl(String path);

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

  /// Adds people by email (TEAM-7): accounts are added and told; new emails
  /// get an account and a setup email. Admins with a verified email.
  Future<AddMembersResult> addByEmail(
    GroupId groupId,
    List<({String? name, String email})> entries,
  );

  /// Sends a fresh setup email to someone not joined yet (AUTH-6).
  Future<void> resendSetupEmail(GroupId groupId, UserId uid);

  /// Marks the team's chat read up to now (CHAT-9). Syncs to every device
  /// through the membership's `lastReadAt`.
  Future<void> markRead(GroupId groupId, UserId uid);
}

/// What happened when adding people by email (TEAM-7 results screen).
class AddMembersResult {
  const new({
    required this.added,
    required this.invited,
    required this.alreadyMembers,
    this.problems = const [],
  });

  final int added;
  final int invited;
  final int alreadyMembers;
  final List<String> problems;
}
