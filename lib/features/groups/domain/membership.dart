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

    /// Their profile photo's Storage path, copied onto the membership, for
    /// the roster (TEAM-3).
    String? photoPath,

    /// Who's who from their player links (PLAYER-8): "Emma #7, Liam #23"
    /// for a guardian, "#12" for a member who is a player (number first
    /// when both), or null.
    String? playerSummary,

    /// Added by email and hasn't signed in yet: "Not joined yet" (AUTH-6).
    @Default(false) bool pending,

    /// A phone number and email they chose to share with this team, shown
    /// on their card with call, text, and email buttons (TEAM-10).
    String? contactPhone,
    String? contactEmail,

    /// A coach of the team (TEAM-3), set by its admins: on the roster's
    /// Coaches, and answering for themselves on events (PLAYER-6). Unset,
    /// the owner counts as one ([isCoach]).
    bool? coach,
  }) = _Membership;

  const new _();

  /// "Maria R." from "Maria Rodriguez": first name and last initial.
  String get shortName => shortNameOf(displayName);

  /// Who's who (PLAYER-8): "Maria R. · Emma #7" for a guardian, "Jared F.
  /// #12" for a member who is a player, or just the name. The roster shows
  /// the full name with "Parent of …" instead.
  String get nameWithPlayers => nameWithPlayersOf(displayName, playerSummary);

  /// Owners and admins manage the team (SPEC §3).
  bool get isAdmin => role == MemberRole.owner || role == MemberRole.admin;

  /// A coach (TEAM-3): as the admins set it, else the owner, who usually
  /// started the team to coach it.
  bool get isCoach => coach ?? role == MemberRole.owner;

  /// Whether they share a phone number or email with the team (TEAM-10).
  bool get sharesContact => contactPhone != null || contactEmail != null;

  /// True when pushes from this team are off or snoozed (NOTIF-3).
  bool isMutedAt(DateTime now) =>
      notificationLevel == NotificationLevel.none || isSnoozedAt(now);

  /// Muted for a while or until unmuted, whatever the level (NOTIF-3).
  bool isSnoozedAt(DateTime now) =>
      mutedUntil != null && mutedUntil!.isAfter(now);

  /// Muted "until unmuted": the far-future sentinel, not a real time.
  bool get isMutedForever =>
      mutedUntil != null &&
      mutedUntil!.millisecondsSinceEpoch >= Limits.mutedForeverMs;
}

/// Whether [email] could be an address to share (TEAM-10): something, an
/// @, and a domain with a dot, as the rules check it.
bool looksLikeEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

/// "Maria R." from "Maria Rodriguez": first name and last initial.
String shortNameOf(String displayName) {
  final parts = displayName.trim().split(RegExp(r'\s+'));
  if (parts.length < 2 || parts.last.isEmpty) return displayName.trim();
  return '${parts.first} ${String.fromCharCode(parts.last.runes.first).toUpperCase()}.';
}

/// "Maria R. · Emma #7" for a guardian, "Jared F. #12" for a member who is
/// a player, and "Jared F. #12 · Emma #7" for both (PLAYER-8); otherwise
/// the name. [playerSummary] lists the member's own number first ("#12,
/// Emma #7"). Chat uses it with the author snapshot on each message.
String nameWithPlayersOf(String displayName, String? playerSummary) {
  final summary = playerSummary?.trim() ?? '';
  if (summary.isEmpty) return displayName;
  final short = shortNameOf(displayName);
  if (!summary.startsWith('#')) return '$short · $summary';
  final comma = summary.indexOf(', ');
  if (comma < 0) return '$short $summary';
  return '$short ${summary.substring(0, comma)} · '
      '${summary.substring(comma + 2)}';
}
