import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';

/// A kid on a youth team's roster (PLAYER-1). Players never have accounts,
/// and their record holds only a name, number, and position (PLAYER-10).
@freezed
abstract class Player with _$Player {
  const factory({
    required PlayerId id,
    required GroupId groupId,
    required String displayName,
    String? jerseyNumber,
    String? position,
  }) = _Player;

  const new _();

  /// "Emma #7", or "Emma" without a number (PLAYER-8).
  String get label {
    final first = displayName.trim().split(RegExp(r'\s+')).first;
    return jerseyNumber == null || jerseyNumber!.isEmpty
        ? first
        : '$first #$jerseyNumber';
  }
}

/// A guardian linked to a player (`playerGuardians`).
@freezed
abstract class GuardianLink with _$GuardianLink {
  const factory({
    required PlayerId playerId,
    required GroupId groupId,
    required UserId uid,
  }) = _GuardianLink;
}

/// One guardian when adding players.
@freezed
abstract class NewGuardian with _$NewGuardian {
  const factory({String? name, String? email}) = _NewGuardian;
}

/// One player to add (PLAYER-1).
@freezed
abstract class NewPlayer with _$NewPlayer {
  const factory({
    required String name,
    String? jerseyNumber,
    String? position,
    @Default(<NewGuardian>[]) List<NewGuardian> guardians,
  }) = _NewPlayer;
}

/// What happened when adding players (PLAYER-1 results screen).
@freezed
abstract class AddPlayersResult with _$AddPlayersResult {
  const factory({
    required int playersAdded,
    required int guardiansLinked,
    required int guardiansInvited,

    /// Guardians given a name and no email, "Emma: Maria R.": nobody can be
    /// linked without an email, so they're listed instead (PLAYER-1).
    @Default(<String>[]) List<String> guardiansWithoutEmail,

    /// "Emma: maria@example.com", with " (too-many-teams)" for someone on
    /// 100 teams already (TEAM-2).
    @Default(<String>[]) List<String> problems,
  }) = _AddPlayersResult;
}

/// Where a guardian request stands (PLAYER-4).
enum GuardianRequestStatus { pending, approved, declined }

/// A parent asking to be linked to a player (`guardianRequests`, PLAYER-3).
@freezed
abstract class GuardianRequest with _$GuardianRequest {
  const factory({
    required PlayerId playerId,
    required GroupId groupId,
    required UserId uid,
    required GuardianRequestStatus status,
  }) = _GuardianRequest;
}
