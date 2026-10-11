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
  }) = _Membership;

  const new _();

  /// Owners and admins manage the team (SPEC §3).
  bool get isAdmin => role == MemberRole.owner || role == MemberRole.admin;

  /// True when pushes from this team are off or snoozed (NOTIF-3).
  bool isMutedAt(DateTime now) =>
      notificationLevel == NotificationLevel.none ||
      (mutedUntil != null && mutedUntil!.isAfter(now));
}
