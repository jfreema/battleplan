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
