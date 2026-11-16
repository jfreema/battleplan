import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';

/// Someone on a team's roster (PLAYER-1). Every team has players. A member
/// can be a player themselves (a `self` link), and players others answer
/// for, such as kids, never have accounts. The record holds only a name
/// and number (PLAYER-10); older records may still carry a position, which
/// the app no longer shows.
@freezed
abstract class Player with _$Player {
  const factory({
    required PlayerId id,
    required GroupId groupId,
    required String displayName,
    String? jerseyNumber,

    /// The song played as they come up (PLAYER-2), "Thunderstruck, AC/DC":
    /// the whole team sees it, up to [Limits.walkUpSongMax] characters.
    String? walkUpSong,

    /// Pending until a team admin approves a member's new player
    /// (PLAYER-4). Players without a status are active.
    @Default(PlayerStatus.active) PlayerStatus status,

    /// Who added it, and how they said they're linked (PLAYER-4).
    String? proposedBy,
    PlayerRelation? proposedRelation,

    /// When it was added to the roster, so its RSVP history starts there
    /// (PLAYER-11). Null on records read without it.
    DateTime? addedAt,
  }) = _Player;

  const new _();

  bool get isPending => status == PlayerStatus.pending;

  /// "Emma" from "Emma Rodriguez".
  String get firstName => displayName.trim().split(RegExp(r'\s+')).first;

  /// "Emma #7", or "Emma" without a number (PLAYER-8).
  String get label => jerseyNumber == null || jerseyNumber!.isEmpty
      ? firstName
      : '$firstName #$jerseyNumber';
}

/// A member linked to a player (`playerGuardians`, "player links"): as the
/// player (`self`) or as a parent or guardian. Old links without a
/// relation are guardians.
@freezed
abstract class GuardianLink with _$GuardianLink {
  const factory({
    required PlayerId playerId,
    required GroupId groupId,
    required UserId uid,
    @Default(PlayerRelation.guardian) PlayerRelation relation,
  }) = _GuardianLink;

  const new _();

  /// The member is this player ("I am this player").
  bool get isSelf => relation == PlayerRelation.self;
}

/// [uid]'s links on a team, as the player or a guardian.
List<GuardianLink> linksOf(UserId uid, Iterable<GuardianLink> links) => [
  for (final l in links)
    if (l.uid == uid) l,
];

/// The member who is [playerId], if anyone claimed it (PLAYER-3: at most
/// one per player).
GuardianLink? selfLinkOf(PlayerId playerId, Iterable<GuardianLink> links) =>
    links.where((l) => l.playerId == playerId && l.isSelf).firstOrNull;

/// Whether [uid] may still say "I am this player" on a team (PLAYER-3).
/// A member is one player at most, so not when they're linked as a player
/// already, have a claim as the player waiting, or added themselves as a
/// player who is still waiting for approval: approving both would leave
/// one of the two players without them.
bool canStillBeAPlayer(
  UserId uid, {
  Iterable<GuardianLink> links = const [],
  Iterable<GuardianRequest> requests = const [],
  Iterable<Player> pendingPlayers = const [],
}) =>
    !links.any((l) => l.uid == uid && l.isSelf) &&
    !requests.any(
      (r) =>
          r.uid == uid &&
          r.relation == PlayerRelation.self &&
          r.status == GuardianRequestStatus.pending,
    ) &&
    !pendingPlayers.any(
      (p) =>
          p.isPending &&
          p.proposedBy == uid.value &&
          p.proposedRelation == PlayerRelation.self,
    );

/// How many guardians [playerId] has; the player's own link doesn't count
/// toward the 4 (PLAYER-3).
int guardianCountOf(PlayerId playerId, Iterable<GuardianLink> links) =>
    links.where((l) => l.playerId == playerId && !l.isSelf).length;

/// One player to add (PLAYER-1): a name, and optionally a number and a
/// date of birth. Who's linked to the player comes later, from claims
/// (PLAYER-3).
@freezed
abstract class NewPlayer with _$NewPlayer {
  const factory({
    required String name,
    String? jerseyNumber,

    /// 'YYYY-MM-DD' (optional): saved in the player's details, never on
    /// the roster (PLAYER-10, PLAYER-12).
    String? dateOfBirth,
  }) = _NewPlayer;
}

/// Where a claim stands (PLAYER-4).
enum GuardianRequestStatus { pending, approved, declined }

/// A member claiming a player (`guardianRequests`, "player claims",
/// PLAYER-3): as the player or as a parent or guardian.
@freezed
abstract class GuardianRequest with _$GuardianRequest {
  const factory({
    required PlayerId playerId,
    required GroupId groupId,
    required UserId uid,
    required GuardianRequestStatus status,
    @Default(PlayerRelation.guardian) PlayerRelation relation,
  }) = _GuardianRequest;
}

/// What a claim did (PLAYER-3): linked at once (an admin's), or sent to
/// the admins.
enum ClaimOutcome { linked, requested }

/// Where a member stands on "Who are you here for?" on a team (PLAYER-3).
/// The prompts that lead there read it: the card at the top of the chat,
/// the line on the schedule's cards, the event page's RSVP area, the Team
/// tab's row, and Dues.
enum PlayerPickStage {
  /// Nothing to show: a team admin, someone linked to a player, an archived
  /// team, a group (no players), or not known yet.
  none,

  /// Not linked, nothing waiting, and they haven't said: the chat's card
  /// and the schedule's cards ask them to pick their player.
  ask,

  /// They closed the card with Not now ([HereFor.later]): the cards stop
  /// asking; the event page and the Team tab still offer it.
  later,

  /// A coach, or they said "I'm a coach or another adult"
  /// ([HereFor.nobody]): only quiet links stay, so they can still link.
  adult,

  /// A claim of theirs, or a player they added, waits for a team admin.
  waiting,
}

/// A member's [PlayerPickStage] on a team, with what its prompts show.
@freezed
abstract class PlayerPick with _$PlayerPick {
  const factory({
    @Default(PlayerPickStage.none) PlayerPickStage stage,

    /// While [PlayerPickStage.waiting]: the first names of the players
    /// waited on, for "Waiting for the coach to approve Max". Empty when
    /// none could be named.
    @Default(<String>[]) List<String> waitingFor,

    /// Whether the card at the top of the chat shows: asking, or waiting,
    /// until they close it (closing saves [HereFor.later]).
    @Default(false) bool card,
  }) = _PlayerPick;

  const new _();

  /// Whether a prompt still offers "Who are you here for?": not linked,
  /// and nothing waiting.
  bool get unlinked =>
      stage == PlayerPickStage.ask ||
      stage == PlayerPickStage.later ||
      stage == PlayerPickStage.adult;
}

/// Where [me] stands on a team with players (see [PlayerPickStage]), from
/// the team's player [links], [me]'s own claims ([requests]) and the
/// players they added that still wait ([pendingPlayers]), and the team's
/// active [players], which name the claimed ones.
PlayerPick playerPickOf({
  required Membership me,
  required bool archived,
  required Iterable<GuardianLink> links,
  required Iterable<GuardianRequest> requests,
  required Iterable<Player> pendingPlayers,
  required Iterable<Player> players,
}) {
  // Admins answer for anyone (SCHED-4) and link at once: nothing to ask.
  if (me.isAdmin || links.any((l) => l.uid == me.uid)) {
    return const PlayerPick();
  }
  final claimed = {
    for (final r in requests)
      if (r.uid == me.uid && r.status == GuardianRequestStatus.pending)
        r.playerId,
  };
  final added = [
    for (final p in pendingPlayers)
      if (p.isPending && p.proposedBy == me.uid.value) p,
  ];
  if (claimed.isNotEmpty || added.isNotEmpty) {
    return PlayerPick(
      stage: PlayerPickStage.waiting,
      waitingFor: [
        // In roster order, then the ones they added.
        for (final p in players)
          if (claimed.contains(p.id)) p.firstName,
        for (final p in added) p.firstName,
      ],
      card: me.hereFor == null,
    );
  }
  // An archived team takes no claims (TEAM-9).
  if (archived) return const PlayerPick();
  if (me.isCoach || me.hereFor == HereFor.nobody) {
    return const PlayerPick(stage: PlayerPickStage.adult);
  }
  if (me.hereFor == HereFor.later) {
    return const PlayerPick(stage: PlayerPickStage.later);
  }
  return const PlayerPick(stage: PlayerPickStage.ask, card: true);
}
