import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/invite.dart';

/// Owns `invites`, which only Functions read and write (ARCH §5.2).
abstract interface class InviteRepository {
  /// The team's current link, created if needed. Members get it only when
  /// the team lets members invite.
  Future<TeamInvite> teamInvite(GroupId groupId);

  /// Replaces the link, turning the old one off at once (admins).
  Future<TeamInvite> resetTeamInvite(
    GroupId groupId, {
    InviteExpiry expiry = InviteExpiry.never,
    int? maxUses,
  });
}
