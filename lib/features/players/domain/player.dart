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
    @Default(<String>[]) List<String> problems,
  }) = _AddPlayersResult;
}
