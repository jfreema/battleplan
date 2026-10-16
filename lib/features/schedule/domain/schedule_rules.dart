import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';

/// Who may do what on the schedule, as the rules decide it (ARCH §6.3).
/// The screens show only what these allow; the server checks again.

/// Making events (SCHED-3, Q12): admins, and members when the team turns
/// on `membersCanCreateEvents`; super admins on any team, as the rules and
/// saveEventSeries let them (§3). Never on an archived team (TEAM-9). Full
/// storage blocks it too, but the + button stays to say why (STORE-4).
bool canCreateEvents(Group group, Membership? me, {bool superAdmin = false}) =>
    !group.isArchived &&
    (superAdmin ||
        (me != null && (me.isAdmin || group.settings.membersCanCreateEvents)));

/// Editing, canceling, and deleting [event]: admins and super admins, or
/// its creator, even after the team stops letting members make events
/// (§3 "own only", as the rules and saveEventSeries decide it).
bool canManageEvent(
  Event event,
  Group group,
  Membership? me, {
  bool superAdmin = false,
}) =>
    !group.isArchived &&
    (superAdmin ||
        (me != null && (me.isAdmin || event.createdBy == me.uid.value)));

/// Posting [event] in the chat again as a reminder (SCHED-8): whoever
/// manages it ([canManageEvent]), while it's on and not over, as
/// repostEvent checks too.
bool canRepost(
  Event event,
  Group group,
  Membership? me, {
  bool superAdmin = false,
  DateTime? now,
}) =>
    me != null &&
    canManageEvent(event, group, me, superAdmin: superAdmin) &&
    !event.isCanceled &&
    event.endAt.isAfter(now ?? DateTime.now());

/// "Email people who haven't RSVP'd" (SCHED-14): whoever may post a
/// reminder ([canRepost]), on an event that takes RSVPs, hasn't started,
/// and is before its deadline, as emailRsvpReminder checks too.
bool canEmailRsvpReminder(
  Event event,
  Group group,
  Membership? me, {
  bool superAdmin = false,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  return canRepost(event, group, me, superAdmin: superAdmin, now: at) &&
      event.takesRsvps &&
      event.startAt.isAfter(at) &&
      !event.deadlinePassedAt(at);
}

/// Whether [me] may answer on [event] at [now]: RSVPs on, not canceled,
/// an active team, and before the deadline unless an admin (SCHED-5).
bool canAnswerNow(Event event, Group group, Membership? me, DateTime now) =>
    me != null &&
    !group.isArchived &&
    event.takesRsvps &&
    (!event.deadlinePassedAt(now) || me.isAdmin);

/// The people the signed-in person answers for on a team (PLAYER-6, Q14):
/// the active players they're linked to, as the player or a guardian,
/// first, then themselves ("Me", [hasMeRow]) when they're a coach or
/// aren't linked to any player. A member who is a player, coaches
/// included, answers on their player's row only, so they never have two
/// answers of their own.
List<Participant> participantsFor({
  required Membership me,
  List<Player> players = const [],
  List<GuardianLink> links = const [],
}) {
  final self = Participant(
    type: ParticipantType.member,
    id: me.uid.value,
    name: me.displayName,
  );
  final mine = linksOf(me.uid, links);
  final myPlayers = [
    // The member's own player first, then the players they're here for.
    for (final p in players)
      if (mine.any((l) => l.playerId == p.id && l.isSelf)) p,
    for (final p in players)
      if (mine.any((l) => l.playerId == p.id && !l.isSelf)) p,
  ];
  final mySelf = {
    for (final l in mine)
      if (l.isSelf) l.playerId,
  };
  return [
    for (final p in myPlayers)
      if (!p.isPending)
        playerParticipant(p).copyWith(isMe: mySelf.contains(p.id)),
    if (hasMeRow(me, links)) self,
  ];
}

/// Whether [me] answers for themselves as a member ("Me", Q14): a coach
/// ([Membership.isCoach]) or someone not linked to any player, but never a
/// member who is a player (PLAYER-6). A parent who isn't a coach answers
/// only for their players, admin or not.
bool hasMeRow(Membership me, Iterable<GuardianLink> links) {
  final mine = linksOf(me.uid, links);
  return !mine.any((l) => l.isSelf) && (me.isCoach || mine.isEmpty);
}

/// A player as someone to answer for (PLAYER-6).
Participant playerParticipant(Player p) => Participant(
  type: ParticipantType.player,
  id: p.id.value,
  name: p.displayName,
  label: p.label,
);

/// Everyone who can be answered for on an event (SCHED-4, PLAYER-6): the
/// active players, and apart, the members who answer for themselves
/// ("coaches and others", Q14): those with a Me row ([hasMeRow]), and
/// anyone who already answered for themselves, as on events made before
/// one team type ([withOwnAnswer] lets them change it). "No response"
/// lists those without an answer.
({List<Participant> main, List<Participant> staff}) eventParticipants(
  List<Membership> roster,
  List<Player> players, {
  List<GuardianLink> links = const [],
  List<Rsvp> rsvps = const [],
}) {
  final answeredForSelf = {
    for (final r in rsvps)
      if (r.participantType == ParticipantType.member) r.participantId,
  };
  return (
    main: [
      for (final p in players)
        if (!p.isPending) playerParticipant(p),
    ],
    staff: [
      for (final m in roster)
        if (hasMeRow(m, links) || answeredForSelf.contains(m.uid.value))
          Participant(
            type: ParticipantType.member,
            id: m.uid.value,
            name: m.displayName,
          ),
    ],
  );
}

/// [mine] ([participantsFor]) with "Me" added, after the players, when
/// [me] has no Me row but already answered for themselves on this event,
/// as before they were linked to a player: an answer listed under "coaches
/// and others" can always be changed or cleared (PLAYER-6).
List<Participant> withOwnAnswer(
  List<Participant> mine,
  Membership me,
  Iterable<Rsvp> rsvps,
) {
  final answered = rsvps.any(
    (r) =>
        r.participantType == ParticipantType.member &&
        r.participantId == me.uid.value,
  );
  if (!answered || mine.any((p) => isSelf(p, me.uid))) return mine;
  return [
    ...mine,
    Participant(
      type: ParticipantType.member,
      id: me.uid.value,
      name: me.displayName,
    ),
  ];
}

/// The answer [participantId] gave, if any.
Rsvp? answerOf(Iterable<Rsvp> rsvps, String participantId) =>
    rsvps.where((r) => r.participantId == participantId).firstOrNull;

/// Whether an admin's answer for [uid] is about themselves or someone
/// else, for "Set RSVP for a member or player" (SCHED-4).
bool isSelf(Participant p, UserId uid) =>
    p.type == ParticipantType.member && p.id == uid.value;
