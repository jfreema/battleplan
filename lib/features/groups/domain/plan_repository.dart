import 'package:battleplan/core/ids.dart';

/// A Plus license the signed-in person holds (PLAN-3).
typedef HeldLicense = ({String id, GroupId? groupId, DateTime endsAt});

/// Plus licenses through the plans callables (ARCH §6.11). Teams read their
/// plan from `Group.plan`; this is for holders and super admins.
abstract interface class PlanRepository {
  /// Licenses [uid] holds that haven't ended.
  Stream<List<HeldLicense>> watchMyLicenses(UserId uid);

  /// Moves a license to another team the holder admins (PLAN-3). Throws
  /// InvalidInput('moved-recently') within 30 days of the last move.
  Future<void> moveLicense(String licenseId, GroupId toGroupId);

  /// Super admins: grants Plus to a team admin for [months] (PLAN-2).
  Future<void> grantLicense(GroupId groupId, UserId holder, {int months = 12});

  /// Super admins: adds months to a license.
  Future<void> extendLicense(String licenseId, {int months = 12});

  /// Super admins: ends a license now.
  Future<void> revokeLicense(String licenseId);
}
