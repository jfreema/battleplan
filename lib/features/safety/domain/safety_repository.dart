import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/safety/domain/safety.dart';

/// Owns `userBlocks` and `reports` (ARCH §5.2).
abstract interface class SafetyRepository {
  /// The people [uid] blocked (SET-5).
  Stream<List<BlockedPerson>> watchBlocked(UserId uid);

  /// Blocks [blocked] in every team (SAFE-2). They aren't told.
  Future<void> block(UserId uid, UserId blocked, {required String name});

  Future<void> unblock(UserId uid, UserId blocked);

  /// Reports something to the team's admins (SAFE-1). Throws RateLimited.
  Future<void> report(
    GroupId groupId, {
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? details,
  });

  /// A team's open reports, newest first (SAFE-4). Admins only.
  Stream<List<Report>> watchOpenReports(GroupId groupId);

  /// Closes a report after acting on it, or dismisses it.
  Future<void> resolveReport(
    String reportId, {
    required bool actioned,
    ReportResolution resolution = ReportResolution.none,
  });
}
