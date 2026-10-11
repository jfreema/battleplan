import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'membership.freezed.dart';

/// One person on one team (ARCH §6.2 `groupMembers`).
@freezed
abstract class Membership with _$Membership {
  const factory({
    required GroupId groupId,
    required UserId uid,
    required MemberRole role,
    required String displayName,
    @Default(NotificationLevel.all) NotificationLevel notificationLevel,
    DateTime? mutedUntil,
    DateTime? lastReadAt,
    String? title,

    /// Youth teams: "Emma #7, Liam #23" for a guardian (PLAYER-8).
    String? playerSummary,

    /// Added by email and hasn't signed in yet: "Not joined yet" (AUTH-6).
    @Default(false) bool pending,
  }) = _Membership;

  const new _();

  /// "Maria R." from "Maria Rodriguez": first name and last initial.
  String get shortName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2 || parts.last.isEmpty) return displayName.trim();
    return '${parts.first} ${String.fromCharCode(parts.last.runes.first).toUpperCase()}.';
  }

  /// Who's who on youth teams (PLAYER-8): "Maria R. · Emma #7", or just the
  /// name when they guard no players. Used in chat and anywhere space is
  /// tight; the roster shows the full name with "Parent of …".
  String get nameWithPlayers => (playerSummary?.isNotEmpty ?? false)
      ? '$shortName · $playerSummary'
      : displayName;

  /// Owners and admins manage the team (SPEC §3).
  bool get isAdmin => role == MemberRole.owner || role == MemberRole.admin;

  /// True when pushes from this team are off or snoozed (NOTIF-3).
  bool isMutedAt(DateTime now) =>
      notificationLevel == NotificationLevel.none ||
      (mutedUntil != null && mutedUntil!.isAfter(now));
}
