// Players domain service: owns players, playerGuardians ("player links"),
// and guardianRequests ("player claims"), on every team (TEAM-1, PLAYER).
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { findOrProvisionUser } from '../accounts/service.js';
import { joinedLine, postSystemMessage } from '../chat/service.js';
import { db } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { forEachPage } from '../shared/batch.js';
import { compositeId, groupMemberId } from '../shared/ids.js';
import { moveMemberRsvpsToPlayer, removeUpcomingRsvps, renameUpcomingRsvps } from '../schedule/service.js';
import {
  linkLimitProblem,
  playerLabelChanged,
  playerStatusOf,
  playerSummaryOf,
  relationOf,
  type PlayerInput,
  type Relation,
} from './roster.js';

/**
 * A deleted account stops being a player or guardian; its players stay
 * (AUTH-10). Players it proposed that no admin approved yet go with it.
 */
export async function removeAccountFromPlayers(uid: string): Promise<void> {
  for (const collection of [Collections.playerGuardians, Collections.guardianRequests]) {
    await forEachPage(db().collection(collection).where('uid', '==', uid), (b, d) => b.delete(d.ref));
  }
  await forEachPage(
    db().collection(Collections.players).where('proposedBy', '==', uid).where('status', '==', 'pending'),
    (b, d) => b.delete(d.ref),
  );
}

/**
 * Someone who leaves or is removed from a team stops being a player or
 * guardian there (TEAM-8, TEAM-3): their player links and claims on it go,
 * so coming back by link needs an admin's approval again (PLAYER-3, Q15)
 * and an old claim can't put them back on the team. Their players stay,
 * except pending ones they proposed, which no admin approved.
 */
export async function removeGuardianFromTeam(groupId: string, uid: string): Promise<void> {
  for (const collection of [Collections.playerGuardians, Collections.guardianRequests]) {
    await forEachPage(
      db().collection(collection).where('groupId', '==', groupId).where('uid', '==', uid),
      (b, d) => b.delete(d.ref),
    );
  }
  await forEachPage(
    db()
      .collection(Collections.players)
      .where('groupId', '==', groupId)
      .where('proposedBy', '==', uid)
      .where('status', '==', 'pending'),
    (b, d) => b.delete(d.ref),
  );
}

export interface AddPlayersResult {
  playersAdded: number;
  guardiansLinked: number;
  guardiansInvited: number;
  /** Players linked by their own email to an account they already had (PLAYER-1). */
  selfLinked: number;
  /** Players whose own email got a new added account (PLAYER-1); linked as the player once they set it up. */
  selfInvited: number;
  /** Emails of people (guardians or players) who got a new added account (for setup emails). */
  invitedEmails: string[];
  /**
   * Guardians given a name but no email, "Emma: Maria R." (PLAYER-1: both
   * are optional). Nobody can be linked without an email, so the results
   * say so instead of dropping them.
   */
  guardiansWithoutEmail: string[];
  /**
   * "Emma: maria@example.com", with the reason when there is one:
   * " (too-many-teams)" on 100 teams (TEAM-2), " (already-a-player)" for a
   * player's email that is already a player on the team, " (already-linked)"
   * for one email given as both the player's and a guardian's (PLAYER-3).
   */
  problems: string[];
}

/** Link refusals the results name (PLAYER-3). */
const LINK_PROBLEMS = new Set(['already-a-player', 'player-already-claimed', 'too-many-guardians', 'already-linked']);

/**
 * An admin adds players to a team (PLAYER-1), each with the player's own
 * email (optional) and up to 4 guardians. Admins' players are active at
 * once. People with accounts are linked now: the player's email as the
 * player ('self', within the PLAYER-3 limits), guardians' as guardians.
 * New emails get an added account (AUTH-6), linked the same way, which
 * they take over at setup. Everyone linked becomes a team member.
 */
export async function addPlayers(
  groupId: string,
  actorUid: string,
  players: PlayerInput[],
): Promise<{ result: AddPlayersResult; newMembers: string[] }> {
  const result: AddPlayersResult = {
    playersAdded: 0,
    guardiansLinked: 0,
    guardiansInvited: 0,
    selfLinked: 0,
    selfInvited: 0,
    invitedEmails: [],
    guardiansWithoutEmail: [],
    problems: [],
  };
  const touched = new Set<string>();
  // People who weren't on the team yet, to be told they were added (NOTIF-2).
  const newMembers = new Set<string>();
  for (const input of players) {
    const playerRef = db().collection(Collections.players).doc();
    const name = input.name.trim().slice(0, 60);
    await playerRef.set({
      groupId,
      displayName: name,
      displayNameLower: name.toLowerCase(),
      jerseyNumber: input.jerseyNumber?.trim() || null,
      position: input.position?.trim() || null,
      status: 'active',
      createdBy: actorUid,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    result.playersAdded++;
    // The player first, so their own email is never taken as a guardian's.
    const people: { email: string; name: string | null; relation: Relation }[] = [];
    if (input.email?.trim()) people.push({ email: input.email, name, relation: 'self' });
    for (const g of input.guardians) {
      if (!g.email) {
        // A name alone can't be linked; the results list it (PLAYER-1).
        if (g.name?.trim()) result.guardiansWithoutEmail.push(`${name}: ${g.name.trim()}`);
        continue;
      }
      people.push({ email: g.email, name: g.name ?? null, relation: 'guardian' });
    }
    for (const person of people) {
      try {
        const user = await findOrProvisionUser(person.email, person.name);
        // A person can be on up to 100 teams (TEAM-2).
        const member = await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, user.uid)).get();
        if (!member.exists) {
          const teams = await db().collection(Collections.groupMembers).where('uid', '==', user.uid).count().get();
          if (teams.data().count >= Limits.groupsPerUserMax) {
            result.problems.push(`${name}: ${person.email} (too-many-teams)`);
            continue;
          }
        }
        if (await linkGuardian(groupId, playerRef.id, user, actorUid, 'admin', person.relation)) newMembers.add(user.uid);
        touched.add(user.uid);
        const self = person.relation === 'self';
        if (user.provisioned) {
          if (self) result.selfInvited++;
          else result.guardiansInvited++;
          result.invitedEmails.push(person.email.trim().toLowerCase());
        } else if (self) {
          result.selfLinked++;
        } else {
          result.guardiansLinked++;
        }
      } catch (e) {
        const reason = e instanceof HttpsError && LINK_PROBLEMS.has(e.message) ? ` (${e.message})` : '';
        result.problems.push(`${name}: ${person.email}${reason}`);
      }
    }
  }
  for (const uid of touched) await refreshPlayerSummary(groupId, uid);
  await refreshPlayerCount(groupId);
  return { result, newMembers: [...newMembers] };
}

/**
 * How a link was made: an admin's roster ('admin'), an approved claim
 * ('request'), a co-parent added by a guardian ('guardian'), an admin's own
 * claim ('claim'), or an approved or admin's proposed player ('proposal').
 * Links from before claims may say 'self' (the old "add my player").
 */
export type LinkVia = 'admin' | 'request' | 'guardian' | 'claim' | 'proposal';

export interface LinkOptions {
  /**
   * Approval paths: when the person has left the team since asking, stop
   * ('left-team') instead of adding them back (TEAM-8). Default false: an
   * admin's roster and an added guardian make them a member.
   */
  requireMember?: boolean;
}

/**
 * Links a member to a player, as the player ('self') or a parent or
 * guardian (the default), and makes them a team member if needed. Returns
 * whether it made them a member, so callers can tell them they were added.
 *
 * The PLAYER-3 limits are checked in the transaction that writes the link
 * (linkLimitProblem), against the player's links and the person's 'self'
 * links on the team as they are at commit, so approvals that run at the
 * same time can't both get past them. Every link write also touches the
 * player (and, for 'self', the membership) with linksUpdatedAt, so two
 * such transactions always conflict and one retries and sees the other's
 * link. Throws `no-player` for a player that's gone or pending,
 * `already-linked` when they're linked another way, and the limit's code.
 * Linking someone the same way again changes nothing.
 *
 * A member (not an admin) who becomes the player answers on the player's
 * row from then on, so their own upcoming answers move to it
 * (moveMemberRsvpsToPlayer, PLAYER-6).
 */
export async function linkGuardian(
  groupId: string,
  playerId: string,
  user: { uid: string; displayName: string; photoPath: string | null; provisioned?: boolean },
  addedBy: string,
  via: LinkVia,
  relation: Relation = 'guardian',
  options: LinkOptions = {},
): Promise<boolean> {
  const now = FieldValue.serverTimestamp();
  const links = db().collection(Collections.playerGuardians);
  const playerRef = db().collection(Collections.players).doc(playerId);
  const memberRef = db().collection(Collections.groupMembers).doc(groupMemberId(groupId, user.uid));
  const linkRef = links.doc(compositeId(playerId, user.uid));
  const outcome = await db().runTransaction(async (tx) => {
    const [player, member, existing, playerLinks, selfLinks] = await Promise.all([
      tx.get(playerRef),
      tx.get(memberRef),
      tx.get(linkRef),
      tx.get(links.where('playerId', '==', playerId).limit(50)),
      relation === 'self'
        ? tx.get(links.where('groupId', '==', groupId).where('uid', '==', user.uid).where('relation', '==', 'self').limit(5))
        : null,
    ]);
    if (!player.exists || player.get('groupId') !== groupId || playerStatusOf(player.data()) !== 'active') {
      throw new HttpsError('not-found', 'no-player');
    }
    if (existing.exists) {
      if (relationOf(existing.data()) === relation) return { linked: false, created: false, role: null, playerName: '' };
      throw new HttpsError('failed-precondition', 'already-linked');
    }
    const problem = linkLimitProblem(
      user.uid,
      playerId,
      relation,
      playerLinks.docs.map((d) => ({ uid: String(d.get('uid')), relation: relationOf(d.data()) })),
      (selfLinks?.docs ?? []).map((d) => String(d.get('playerId'))),
      Limits.guardiansPerPlayerMax,
    );
    if (problem) throw new HttpsError('failed-precondition', problem);
    if (!member.exists && options.requireMember) throw new HttpsError('failed-precondition', 'left-team');
    tx.set(linkRef, {
      playerId,
      groupId,
      uid: user.uid,
      relation,
      addedBy,
      via,
      createdAt: now,
    });
    tx.update(playerRef, { linksUpdatedAt: now });
    if (member.exists) {
      if (relation === 'self') tx.update(memberRef, { linksUpdatedAt: now });
    } else {
      tx.set(memberRef, {
        groupId,
        uid: user.uid,
        role: 'member',
        title: null,
        displayName: user.displayName,
        photoPath: user.photoPath,
        playerSummary: null,
        notificationLevel: 'all',
        mutedUntil: null,
        lastReadAt: now,
        lastPostedAt: null,
        joinedAt: now,
        addedBy,
        pending: user.provisioned === true,
        linksUpdatedAt: now,
      });
    }
    return {
      linked: true,
      created: !member.exists,
      role: member.exists ? String(member.get('role')) : 'member',
      playerName: String(player.get('displayName') ?? ''),
    };
  });
  if (!outcome.linked) return false;
  if (outcome.created) {
    const count = await db().collection(Collections.groupMembers).where('groupId', '==', groupId).count().get();
    await db().collection(Collections.groups).doc(groupId).update({ memberCount: count.data().count });
  }
  // "Maria joined" (CHAT-10). An added account joins when it first signs
  // in (clearPendingMemberships).
  if (outcome.created && user.provisioned !== true) {
    await postSystemMessage(groupId, 'joined', joinedLine(user.displayName), user.uid);
  }
  // Anyone who is the player, admins included, answers on the player's row
  // from then on (PLAYER-6: the app shows no Me row to a member who is a
  // player), so their own upcoming answers move there.
  if (relation === 'self' && !outcome.created) {
    await moveMemberRsvpsToPlayer(groupId, user.uid, { id: playerId, name: outcome.playerName });
  }
  return outcome.created;
}

/**
 * Rewrites a member's "Who's who" label on their membership (PLAYER-8): a
 * guardian's "Emma #7, Liam #23", a player's own "#12".
 */
export async function refreshPlayerSummary(groupId: string, uid: string): Promise<void> {
  const links = await db()
    .collection(Collections.playerGuardians)
    .where('groupId', '==', groupId)
    .where('uid', '==', uid)
    .limit(20)
    .get();
  const labels: Parameters<typeof playerSummaryOf>[0] = [];
  for (const link of links.docs) {
    const player = await db().collection(Collections.players).doc(link.get('playerId') as string).get();
    if (!player.exists || playerStatusOf(player.data()) !== 'active') continue;
    labels.push({
      relation: relationOf(link.data()),
      name: player.get('displayName') as string,
      jerseyNumber: (player.get('jerseyNumber') as string | null | undefined) ?? null,
    });
  }
  await db()
    .collection(Collections.groupMembers)
    .doc(groupMemberId(groupId, uid))
    .update({ playerSummary: playerSummaryOf(labels) })
    .catch(() => undefined);
}

/**
 * players updated → the labels that copy a player's name and number (ARCH
 * §6.4 trigger map): each linked member's "Who's who" (PLAYER-8, "Emma #7"
 * or "#12") and, after a rename, participantName on upcoming RSVPs. Exits
 * early unless an active player's name or number changed (playerLabelChanged),
 * so link writes (linksUpdatedAt) and approvals cost nothing.
 */
export async function followUpPlayerUpdate(
  playerId: string,
  before: FirebaseFirestore.DocumentData | undefined,
  after: FirebaseFirestore.DocumentData | undefined,
): Promise<void> {
  if (!after || !playerLabelChanged(before, after)) return;
  const groupId = String(after.groupId ?? '');
  if (!groupId) return;
  const links = await db().collection(Collections.playerGuardians).where('playerId', '==', playerId).limit(50).get();
  for (const uid of new Set(links.docs.map((d) => String(d.get('uid'))))) await refreshPlayerSummary(groupId, uid);
  if (before?.displayName !== after.displayName && typeof after.displayName === 'string') {
    await renameUpcomingRsvps(playerId, after.displayName);
  }
}

/** Recomputes groups.playerCount (D12): the roster's active players. */
export async function refreshPlayerCount(groupId: string): Promise<void> {
  const players = await db()
    .collection(Collections.players)
    .where('groupId', '==', groupId)
    .select('status')
    .get();
  const active = players.docs.filter((d) => playerStatusOf(d.data()) === 'active').length;
  await db().collection(Collections.groups).doc(groupId).update({ playerCount: active });
}

/**
 * Every player on the team, pending ones included, for the 200-player
 * limit (PLAYER-1): proposals count, so members can't pile them up.
 */
export async function playersOnTeam(groupId: string): Promise<number> {
  const count = await db().collection(Collections.players).where('groupId', '==', groupId).count().get();
  return count.data().count;
}

/**
 * Removes a player, their links and claims, and their answers to upcoming
 * events, so those events' counts drop (PLAYER-2, PLAYER-6).
 */
export async function removePlayer(groupId: string, playerId: string): Promise<void> {
  const links = await db().collection(Collections.playerGuardians).where('playerId', '==', playerId).limit(20).get();
  const guardians = links.docs.map((d) => d.get('uid') as string);
  for (const collection of [Collections.playerGuardians, Collections.guardianRequests]) {
    await forEachPage(db().collection(collection).where('playerId', '==', playerId), (b, d) => b.delete(d.ref));
  }
  await db().collection(Collections.players).doc(playerId).delete();
  await removeUpcomingRsvps(playerId);
  for (const uid of guardians) await refreshPlayerSummary(groupId, uid);
  await refreshPlayerCount(groupId);
}

/** How [uid] is linked to [playerId], or null when they aren't. */
export async function linkOf(playerId: string, uid: string): Promise<Relation | null> {
  const link = await db().collection(Collections.playerGuardians).doc(compositeId(playerId, uid)).get();
  return link.exists ? relationOf(link.data()) : null;
}

/** How many guardians a player has; the player's own 'self' link doesn't count (PLAYER-3: up to 4). */
export async function guardianCount(playerId: string): Promise<number> {
  const links = await db().collection(Collections.playerGuardians).where('playerId', '==', playerId).limit(20).get();
  return links.docs.filter((d) => relationOf(d.data()) === 'guardian').length;
}

/** Whether a member is linked as the player to [playerId]. */
async function selfLinkOf(playerId: string): Promise<string | null> {
  const links = await db()
    .collection(Collections.playerGuardians)
    .where('playerId', '==', playerId)
    .where('relation', '==', 'self')
    .limit(1)
    .get();
  return links.empty ? null : String(links.docs[0].get('uid'));
}

/** Whether [uid] is already a player on [groupId] (PLAYER-3: one per member per team). */
async function isPlayerOnTeam(groupId: string, uid: string): Promise<boolean> {
  const links = await db()
    .collection(Collections.playerGuardians)
    .where('groupId', '==', groupId)
    .where('uid', '==', uid)
    .where('relation', '==', 'self')
    .limit(1)
    .get();
  return !links.empty;
}

/**
 * Throws unless [uid] may be linked to [playerId] as [relation] now
 * (PLAYER-3): a player has at most one 'self' link, a member is 'self'
 * for at most one player per team, and a player has up to 4 guardians.
 */
export async function requireLinkAllowed(
  groupId: string,
  playerId: string,
  uid: string,
  relation: Relation,
): Promise<void> {
  if (relation === 'self') {
    const self = await selfLinkOf(playerId);
    if (self && self !== uid) throw new HttpsError('failed-precondition', 'player-already-claimed');
    if (await isPlayerOnTeam(groupId, uid)) throw new HttpsError('failed-precondition', 'already-a-player');
  } else if ((await guardianCount(playerId)) >= Limits.guardiansPerPlayerMax) {
    throw new HttpsError('failed-precondition', 'too-many-guardians');
  }
}

async function profileOf(uid: string, fallback: string): Promise<{ uid: string; displayName: string; photoPath: string | null }> {
  const profile = await db().collection(Collections.users).doc(uid).get();
  return {
    uid,
    displayName: (profile.get('displayName') as string | undefined) ?? fallback,
    photoPath: (profile.get('photoPath') as string | null | undefined) ?? null,
  };
}

export interface ClaimResult {
  /** 'linked' when an admin claimed (approved at once), else 'requested'. */
  status: 'linked' | 'requested';
  playerName: string;
}

/**
 * A member claims a player (PLAYER-3, Q15): "I am this player" ('self') or
 * "I'm their parent or guardian". A claim waits for an admin's approval
 * (PLAYER-4); an admin's own claim is approved at once. Only active players
 * on the team can be claimed. A declined claim can be sent again.
 */
export async function claimPlayer(
  groupId: string,
  uid: string,
  playerId: string,
  relation: Relation,
  admin: boolean,
): Promise<ClaimResult> {
  const player = await db().collection(Collections.players).doc(playerId).get();
  if (!player.exists || player.get('groupId') !== groupId || playerStatusOf(player.data()) !== 'active') {
    throw new HttpsError('not-found', 'no-player');
  }
  const playerName = (player.get('displayName') as string | undefined) || 'a player';
  if (await linkOf(playerId, uid)) throw new HttpsError('failed-precondition', 'already-linked');
  await requireLinkAllowed(groupId, playerId, uid, relation);
  const requestRef = db().collection(Collections.guardianRequests).doc(compositeId(playerId, uid));
  if (admin) {
    await linkGuardian(groupId, playerId, await profileOf(uid, 'Member'), uid, 'claim', relation, { requireMember: true });
    await requestRef.delete();
    await refreshPlayerSummary(groupId, uid);
    return { status: 'linked', playerName };
  }
  await requestRef.set({
    playerId,
    groupId,
    uid,
    relation,
    status: 'pending',
    decidedBy: null,
    decidedAt: null,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { status: 'requested', playerName };
}

/**
 * An admin approves or declines a claim (PLAYER-4). Approving links the
 * member as the claim says, if the limits still allow it (else it throws
 * and the claim stays for a decline); either way the claim records who
 * decided. Returns the claim's relation, or null when there was nothing to
 * decide.
 */
export async function resolvePlayerClaim(
  groupId: string,
  playerId: string,
  uid: string,
  approve: boolean,
  actorUid: string,
): Promise<Relation | null> {
  const ref = db().collection(Collections.guardianRequests).doc(compositeId(playerId, uid));
  const request = await ref.get();
  if (!request.exists || request.get('groupId') !== groupId || request.get('status') !== 'pending') return null;
  const relation = relationOf(request.data());
  // Someone who has left the team since asking isn't put back on it (TEAM-8).
  const member = await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid)).get();
  if (!member.exists) {
    await ref.delete();
    return null;
  }
  if (approve) {
    const player = await db().collection(Collections.players).doc(playerId).get();
    if (!player.exists || playerStatusOf(player.data()) !== 'active') {
      await ref.delete();
      return null;
    }
    if (!(await linkOf(playerId, uid))) {
      await requireLinkAllowed(groupId, playerId, uid, relation);
      try {
        await linkGuardian(groupId, playerId, await profileOf(uid, 'Member'), actorUid, 'request', relation, {
          requireMember: true,
        });
      } catch (e) {
        // They left, or the player went, while this ran: nothing to decide.
        if (!(e instanceof HttpsError) || !['left-team', 'no-player'].includes(e.message)) throw e;
        await ref.delete();
        return null;
      }
    }
    await refreshPlayerSummary(groupId, uid);
  }
  await ref.update({
    status: approve ? 'approved' : 'declined',
    decidedBy: actorUid,
    decidedAt: FieldValue.serverTimestamp(),
  });
  return relation;
}

export interface NewPlayerInput {
  displayName: string;
  jerseyNumber?: string | null;
  position?: string | null;
  relation: Relation;
}

/**
 * A member adds a player who isn't on the roster (PLAYER-3), saying how
 * they're linked: themselves ('self') or their child ('guardian'). A
 * member's player is pending until an admin approves it (PLAYER-4); its
 * link is made then, from proposedRelation. An admin's is active at once,
 * linked now. Returns the player's ID and status.
 */
export async function proposePlayer(
  groupId: string,
  uid: string,
  input: NewPlayerInput,
  admin: boolean,
): Promise<{ playerId: string; status: 'active' | 'pending' }> {
  if (input.relation === 'self') {
    const pendingSelf = await db()
      .collection(Collections.players)
      .where('groupId', '==', groupId)
      .where('proposedBy', '==', uid)
      .where('status', '==', 'pending')
      .where('proposedRelation', '==', 'self')
      .limit(1)
      .get();
    if (!pendingSelf.empty || (await isPlayerOnTeam(groupId, uid))) {
      throw new HttpsError('failed-precondition', 'already-a-player');
    }
  }
  const ref = db().collection(Collections.players).doc();
  const name = input.displayName.trim().slice(0, 60);
  const status = admin ? 'active' : 'pending';
  const now = FieldValue.serverTimestamp();
  await ref.set({
    groupId,
    displayName: name,
    displayNameLower: name.toLowerCase(),
    jerseyNumber: input.jerseyNumber?.trim() || null,
    position: input.position?.trim() || null,
    status,
    proposedBy: uid,
    proposedRelation: input.relation,
    decidedBy: admin ? uid : null,
    decidedAt: admin ? now : null,
    createdBy: uid,
    createdAt: now,
    updatedAt: now,
  });
  if (admin) {
    try {
      await linkGuardian(groupId, ref.id, await profileOf(uid, 'Member'), uid, 'proposal', input.relation, {
        requireMember: true,
      });
    } catch (e) {
      // Became a player meanwhile (PLAYER-3): no unlinked duplicate is left.
      await ref.delete();
      throw e;
    }
    await refreshPlayerSummary(groupId, uid);
    await refreshPlayerCount(groupId);
  }
  return { playerId: ref.id, status };
}

export interface PendingDecision {
  playerName: string;
  proposedBy: string | null;
  relation: Relation;
  /** Whether the proposer was linked on approval (false if they left, or the limits no longer allow it). */
  linked: boolean;
}

/**
 * An admin approves or declines a pending player (PLAYER-4). Approving
 * makes it active and links its proposer as they said, if they're still on
 * the team and the limits allow it; declining deletes it. Returns null
 * when there's no pending player to decide.
 */
export async function resolvePendingPlayer(
  groupId: string,
  playerId: string,
  approve: boolean,
  actorUid: string,
): Promise<PendingDecision | null> {
  const ref = db().collection(Collections.players).doc(playerId);
  const player = await ref.get();
  if (!player.exists || player.get('groupId') !== groupId || playerStatusOf(player.data()) !== 'pending') return null;
  const proposedBy = (player.get('proposedBy') as string | null | undefined) ?? null;
  const relation = relationOf({ relation: player.get('proposedRelation') });
  const playerName = (player.get('displayName') as string | undefined) || 'a player';
  if (!approve) {
    for (const collection of [Collections.playerGuardians, Collections.guardianRequests]) {
      await forEachPage(db().collection(collection).where('playerId', '==', playerId), (b, d) => b.delete(d.ref));
    }
    await ref.delete();
    return { playerName, proposedBy, relation, linked: false };
  }
  await ref.update({ status: 'active', decidedBy: actorUid, decidedAt: FieldValue.serverTimestamp() });
  let linked = false;
  if (proposedBy) {
    const member = await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, proposedBy)).get();
    if (member.exists) {
      try {
        await requireLinkAllowed(groupId, playerId, proposedBy, relation);
        await linkGuardian(groupId, playerId, await profileOf(proposedBy, 'Member'), actorUid, 'proposal', relation, {
          requireMember: true,
        });
        linked = true;
      } catch (e) {
        if (!(e instanceof HttpsError)) throw e;
      }
      await refreshPlayerSummary(groupId, proposedBy);
    }
  }
  await refreshPlayerCount(groupId);
  return { playerName, proposedBy, relation, linked };
}

/**
 * Removes one link from a player, a guardian's or the player's own
 * (PLAYER-2). They stay on the team; only the link and its label go.
 */
export async function removeGuardianLink(groupId: string, playerId: string, uid: string): Promise<void> {
  await db().collection(Collections.playerGuardians).doc(compositeId(playerId, uid)).delete();
  await db().collection(Collections.guardianRequests).doc(compositeId(playerId, uid)).delete();
  await refreshPlayerSummary(groupId, uid);
}

/** What a super admin may change on a player (ADMIN-3): the same fields the rules' validPlayer allows (PLAYER-10). */
export interface PlayerEdit {
  displayName?: string;
  jerseyNumber?: string | null;
  position?: string | null;
}

/**
 * Changes a player's name, number, or position for a super admin who isn't
 * on the team (ADMIN-3); its admins and guardians write them directly.
 * Callers validate [edit] as validPlayer does. Returns the player's team
 * and each changed field before and after, for the audit log.
 */
export async function updatePlayerProfile(
  playerId: string,
  edit: PlayerEdit,
): Promise<{ groupId: string; before: Record<string, unknown>; after: Record<string, unknown> }> {
  const ref = db().collection(Collections.players).doc(playerId);
  return db().runTransaction(async (tx) => {
    const player = await tx.get(ref);
    if (!player.exists) throw new HttpsError('not-found', 'No such player.');
    const after: Record<string, unknown> = {};
    for (const key of ['displayName', 'jerseyNumber', 'position'] as const) {
      if (edit[key] !== undefined) after[key] = edit[key];
    }
    const before = Object.fromEntries(Object.keys(after).map((k) => [k, player.get(k) ?? null]));
    tx.update(ref, {
      ...after,
      ...(edit.displayName !== undefined ? { displayNameLower: edit.displayName.toLowerCase() } : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { groupId: String(player.get('groupId') ?? ''), before, after };
  });
}
