import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'season.freezed.dart';

/// Who and what comes along to a new season (TEAM-16). Everyone comes to
/// start; the documents and saved plays are the owner's to add.
@freezed
abstract class SeasonChoices with _$SeasonChoices {
  const factory({
    /// The players, with their parents' links, and so the members linked
    /// to them: parents keep answering for their kids.
    @Default(true) bool players,

    /// The coaches and admins, keeping their roles and titles.
    @Default(true) bool staff,

    /// Everyone else.
    @Default(true) bool members,
    @Default(false) bool documents,
    @Default(false) bool plays,
  }) = _SeasonChoices;
}

/// A new season's team, and how many people it couldn't bring because
/// they're on 100 teams already (TEAM-2).
typedef NewSeason = ({GroupId groupId, int leftOut});

/// Where a member stands when a team starts a new season (TEAM-16), for
/// the counts on Start a new season.
enum SeasonGroup {
  /// The owner, who always comes.
  owner,

  /// Admins and coaches.
  staff,

  /// Here for a player: a parent, or the player.
  players,

  /// Everyone else.
  others,
}

/// [member]'s group: the owner, then admins and coaches, then members
/// [linked] to a player, then everyone else. The server's seasonPlaceOf
/// sorts people the same way.
SeasonGroup seasonGroupOf(Membership member, {required bool linked}) {
  if (member.role == MemberRole.owner) return SeasonGroup.owner;
  if (member.role == MemberRole.admin || member.coach == true) {
    return SeasonGroup.staff;
  }
  return linked ? SeasonGroup.players : SeasonGroup.others;
}
