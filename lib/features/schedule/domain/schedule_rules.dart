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

/// Whether [me] may answer on [event] at [now]: RSVPs on, not canceled,
/// an active team, and before the deadline unless an admin (SCHED-5).
bool canAnswerNow(Event event, Group group, Membership? me, DateTime now) =>
    me != null &&
    !group.isArchived &&
    event.takesRsvps &&
    (!event.deadlinePassedAt(now) || me.isAdmin);

/// The people the signed-in person answers for on [group] (PLAYER-6, Q14):
/// themselves on adult teams; on youth teams their players, plus
/// themselves when they're an admin (counted apart, D34).
List<Participant> participantsFor({
  required Group group,
  required Membership me,
  List<Player> players = const [],
  List<GuardianLink> links = const [],
}) {
  final self = Participant(
    type: ParticipantType.member,
    id: me.uid.value,
    name: me.displayName,
  );
  if (group.teamType != TeamType.youth) return [self];
  final mine = {
    for (final l in links)
      if (l.uid == me.uid) l.playerId,
  };
  return [
    if (me.isAdmin) self,
    for (final p in players)
      if (mine.contains(p.id)) playerParticipant(p),
  ];
}

/// A player as someone to answer for (PLAYER-6).
Participant playerParticipant(Player p) => Participant(
  type: ParticipantType.player,
  id: p.id.value,
  name: p.displayName,
  label: p.label,
);

/// Everyone who can be answered for on [event]: on youth events the
/// players and, apart, the admins (Q14); otherwise every member. "No
/// response" lists those without an answer (SCHED-4).
({List<Participant> main, List<Participant> staff}) eventParticipants(
  Event event,
  List<Membership> roster,
  List<Player> players,
) {
  Participant member(Membership m) => Participant(
    type: ParticipantType.member,
    id: m.uid.value,
    name: m.displayName,
  );
  if (!event.forPlayers) {
    return (main: [for (final m in roster) member(m)], staff: const []);
  }
  return (
    main: [for (final p in players) playerParticipant(p)],
    staff: [
      for (final m in roster)
        if (m.isAdmin) member(m),
    ],
  );
}

/// Whether an admin ([me]) may set [p]'s answer on [event] (SCHED-4), as
/// the rules allow it: anyone on adult events; on youth events any
/// player, but of the coaches only themselves, since each admin answers
/// for themselves (Q14).
bool canSetRsvpFor(Event event, Participant p, UserId me) =>
    !event.forPlayers || p.type == ParticipantType.player || isSelf(p, me);

/// The answer [participantId] gave, if any.
Rsvp? answerOf(Iterable<Rsvp> rsvps, String participantId) =>
    rsvps.where((r) => r.participantId == participantId).firstOrNull;

/// Whether an admin's answer for [uid] is about themselves or someone
/// else, for "Set RSVP for a member or player" (SCHED-4).
bool isSelf(Participant p, UserId uid) =>
    p.type == ParticipantType.member && p.id == uid.value;

/// How far ahead the Schedule tab's badge looks (SPEC §5.3).
const awaitingRsvpWindow = Duration(days: 14);

/// The Schedule tab's badge (SPEC §5.3): how many of [events] in the next
/// 14 days from [now] still wait for an answer from someone I answer for
/// ([participants]: me, or my players on youth teams). Only events I
/// can still answer count: taking answers, not started, and before the
/// deadline unless I'm an admin (SCHED-5). [answers] are mine by event ID,
/// then participant ID.
int countAwaitingRsvp({
  required List<Event> events,
  required Group group,
  required Membership me,
  required List<Participant> participants,
  required Map<String, Map<String, Rsvp>> answers,
  required DateTime now,
}) {
  final until = now.add(awaitingRsvpWindow);
  var count = 0;
  for (final e in events) {
    if (e.startedBefore(now) || !e.startAt.isBefore(until)) continue;
    if (!canAnswerNow(e, group, me, now)) continue;
    // Everyone I answer for, as event details shows them (PLAYER-6).
    final mine = answers[e.id.value] ?? const {};
    if (participants.any((p) => !mine.containsKey(p.id))) count++;
  }
  return count;
}
