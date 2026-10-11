import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'safety.freezed.dart';

/// Someone the signed-in person blocked (SAFE-2, SET-5).
@freezed
abstract class BlockedPerson with _$BlockedPerson {
  const factory({required UserId uid, @Default('') String name}) =
      _BlockedPerson;
}

/// What a report is about.
enum ReportTargetType { message, user, document }

/// A report waiting for the team's admins (SAFE-1, SAFE-4). The reporter
/// isn't included: admins don't see who reported.
@freezed
abstract class Report with _$Report {
  const factory({
    required String id,
    required GroupId groupId,
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,

    /// The person the report is about, and a copy of what was reported.
    required String subjectId,
    required String subjectName,
    @Default('') String excerpt,
    String? details,
    DateTime? createdAt,
  }) = _Report;
}

/// How an admin closed a report.
enum ReportResolution { deletedMessage, removedMember, none }
