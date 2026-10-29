import 'package:battleplan/core/constants.g.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite.freezed.dart';

/// A team's reusable invite link (INV-1, INV-2).
@freezed
abstract class TeamInvite with _$TeamInvite {
  const factory({
    /// Stored without the dash, e.g. K7XPM2QR.
    required String code,

    /// For display, e.g. K7XP-M2QR.
    required String display,
    required Uri url,
    required int useCount,
    DateTime? expiresAt,
    int? maxUses,
  }) = _TeamInvite;
}

/// Link expiry choices (INV-2).
enum InviteExpiry {
  never(null),
  oneDay(1),
  sevenDays(7),
  thirtyDays(30);

  new(this.days);

  final int? days;
}

/// The team behind an invite, shown before joining (INV-5, INV-7).
@freezed
abstract class InvitePreview with _$InvitePreview {
  const factory({
    required String groupId,
    required String name,
    required Sport sport,
    required int memberCount,

    /// A team, or a basic group without players (TEAM-14).
    @Default(GroupKind.team) GroupKind kind,
    int? color,

    /// The team's logo, readable signed out (INV-5), or null.
    String? logoUrl,
    String? invitedBy,
  }) = _InvitePreview;
}

/// The result of joining (INV-5).
@freezed
abstract class JoinResult with _$JoinResult {
  const factory({required String groupId, required bool alreadyMember}) =
      _JoinResult;
}

/// Where an email invite stands (INV-4).
enum EmailInviteStatus { pending, joined, expired, revoked }

/// One single-use invite sent to an address (INV-4).
@freezed
abstract class EmailInvite with _$EmailInvite {
  const factory({
    required String code,
    required String email,
    required EmailInviteStatus status,
    DateTime? createdAt,
  }) = _EmailInvite;
}
