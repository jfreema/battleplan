// Thin entry points for the players domain (ARCH §6.4).
import { logger } from 'firebase-functions/v2';
import { HttpsError } from 'firebase-functions/v2/https';
import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { onCall } from '../shared/callable.js';
import { Collections, Limits } from '../shared/constants.js';
import { requireAuth, requireVerifiedEmail } from '../shared/guards.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { requireOpenTeam, requireRoomForAnotherTeam, requireTeamAdmin, roleOf } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { displayNameOf, findOrProvisionUser, sendSetupEmail } from '../accounts/service.js';
import { resendApiKey, sendEmail } from '../email/service.js';
import { addedToTeamEmail } from '../email/templates.js';
import { teamUrl } from '../links/service.js';
import { trySend } from '../notify/service.js';
import { notifyAddedToTeam } from '../teams/service.js';
import { groupMemberId } from '../shared/ids.js';
import { validDateOfBirth, type Relation } from './roster.js';
import {
  addPlayers as add,
  claimPlayer as claim,
  guardianCount,
  linkGuardian,
  linkOf,
  playersOnTeam,
  proposePlayer as propose,
  refreshPlayerSummary,
  removeGuardianLink,
  removePlayer as remove,
  resolvePendingPlayer as resolvePending,
  resolvePlayerClaim as resolveClaim,
} from './service.js';

const Guardian = z.object({
  name: z.string().trim().max(60).nullable().optional(),
  email: z.string().trim().email().max(200).nullable().optional(),
});

/** An optional date of birth (PLAYER-12), as the rules take it. */
const DateOfBirth = z
  .string()
  .trim()
  .refine((v) => validDateOfBirth(v, new Date(), Limits.playerAgeMaxYears), 'bad-date-of-birth')
  .nullable()
  .optional();

const Player = z.object({
  name: z.string().trim().min(1).max(60),
  dateOfBirth: DateOfBirth,
  jerseyNumber: z.string().trim().max(4).nullable().optional(),
  position: z.string().trim().max(30).nullable().optional(),
  // The player's own email (PLAYER-1, optional): linked as the player.
  email: z.string().trim().email().max(200).nullable().optional(),
  guardians: z.array(Guardian).max(Limits.guardiansPerPlayerMax).default([]),
});

/** Roster lines a list of players stands for: one per guardian, or one for a player with none (PLAYER-1). */
export function rosterLines(players: { guardians: unknown[] }[]): number {
  return players.reduce((n, p) => n + Math.max(1, p.guardians.length), 0);
}

const AddPlayersInput = z.object({
  groupId: z.string().min(1),
  players: z
    .array(Player)
    .min(1)
    .max(Limits.pastedRosterLinesMax)
    // Up to 200 lines, one per guardian (PLAYER-1), not 200 players.
    .refine((players) => rosterLines(players) <= Limits.pastedRosterLinesMax, 'too-many-lines'),
});

/**
 * Adds players to a team (PLAYER-1), active at once. Admins only. Input
 * { groupId, players: [{ name, jerseyNumber?, position?, email?,
 * guardians: [{ name?, email? }] }] }: `email` is the player's own, linked
 * as the player ('self'). Returns AddPlayersResult.
 */
export const addPlayers = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(AddPlayersInput, request.data);
  await requireTeamAdmin(input.groupId, uid, request.auth?.token.superAdmin === true);
  const group = await db().collection(Collections.groups).doc(input.groupId).get();
  const players = await playersOnTeam(input.groupId);
  if (players + input.players.length > Limits.playersPerGroupMax) {
    throw new HttpsError('failed-precondition', 'too-many-players');
  }
  const emails = input.players.flatMap((p) => [p.email, ...p.guardians.map((g) => g.email)].filter((e) => e)).length;
  // Players' and guardians' emails add people by email: a verified email first (AUTH-3).
  if (emails > 0) requireVerifiedEmail(request);
  await consumeRateLimit(input.groupId, 'addByEmail', Limits.addByEmailPerGroupPerDay, 'day', Math.max(emails, 1));
  const { result, newMembers } = await add(input.groupId, uid, input.players);
  await audit({
    actorId: uid,
    action: 'addPlayers',
    groupId: input.groupId,
    targetType: 'group',
    targetId: input.groupId,
    after: { playersAdded: result.playersAdded, guardiansInvited: result.guardiansInvited },
  });
  const actor = await db().collection(Collections.users).doc(uid).get();
  const actorName = (actor.get('displayName') as string | undefined) ?? 'A team admin';
  // NOTIF-2: people who weren't on the team are told they were added.
  // First, since it never throws and a failed email below must not skip it.
  await notifyAddedToTeam(input.groupId, group.get('name') as string, { uid, name: actorName }, newMembers);
  // AUTH-6: new people get a setup email. One failure doesn't stop the
  // rest; the admin can resend from the roster.
  for (const email of result.invitedEmails) {
    await sendSetupEmail(email, group.get('name') as string, actorName).catch((e: unknown) =>
      logger.error('setup_email_failed', { groupId: input.groupId, error: String(e) }),
    );
  }
  return result;
});

/** Removes a player (PLAYER-2). Admins only. */
export const removePlayer = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(z.object({ groupId: z.string().min(1), playerId: z.string().min(1) }), request.data);
  await requireTeamAdmin(input.groupId, uid, request.auth?.token.superAdmin === true);
  const player = await db().collection(Collections.players).doc(input.playerId).get();
  if (!player.exists || player.get('groupId') !== input.groupId) return { ok: true };
  await remove(input.groupId, input.playerId);
  await audit({
    actorId: uid,
    action: 'removePlayer',
    groupId: input.groupId,
    targetType: 'player',
    targetId: input.playerId,
    before: { name: player.get('displayName') },
  });
  return { ok: true };
});

/**
 * Throws unless [groupId] is an open team (requireOpenTeam, which lets a
 * super admin act on a suspended one) the caller belongs to. A super admin
 * who isn't on it acts as an admin (role 'superAdmin', §3: adding a
 * guardian) unless [onTeam]: calls that link the caller themselves (claims,
 * adding yourself) need them on the team.
 */
async function requireTeamMember(
  groupId: string,
  uid: string,
  superAdmin = false,
  onTeam = false,
): Promise<{ role: string; teamName: string }> {
  const role = (await roleOf(groupId, uid)) ?? (superAdmin && !onTeam ? 'superAdmin' : null);
  if (!role) throw new HttpsError('permission-denied', 'Not a member.');
  const group = await requireOpenTeam(groupId, superAdmin);
  return { role, teamName: group.get('name') as string };
}

/** Team admins and owners, and super admins acting on the team (§3: claims and new players at once). */
const actsAsAdmin = (role: string, superAdmin: boolean) => superAdmin || role === 'owner' || role === 'admin';

const RelationInput = z.enum(['self', 'guardian']);

/** The team a player is on, checked against [groupId] when the caller passed one. */
async function teamOfPlayer(playerId: string, groupId?: string): Promise<string> {
  const player = await db().collection(Collections.players).doc(playerId).get();
  const team = player.exists ? String(player.get('groupId') ?? '') : '';
  if (!team || (groupId && groupId !== team)) throw new HttpsError('not-found', 'no-player');
  return team;
}

/** "Maria R. asked to be Emma's guardian" / "Jared F. asked to be linked as the player Jared" (NOTIF-2). */
export function claimBody(name: string, playerName: string, relation: Relation): string {
  return relation === 'self' ? `${name} asked to be linked as the player ${playerName}` : `${name} asked to be ${playerName}'s guardian`;
}

/** "Maria R. asked to add a player: Emma" / "Jared F. asked to join the roster as Jared" (NOTIF-2). */
export function pendingPlayerBody(name: string, playerName: string, relation: Relation): string {
  return relation === 'self' ? `${name} asked to join the roster as ${playerName}` : `${name} asked to add a player: ${playerName}`;
}

/** What an approved member hears (NOTIF-2): a claim, or a player they proposed. */
export function approvedBody(playerName: string, relation: Relation, proposal: boolean): string {
  if (relation === 'self') return `You're now on the roster as ${playerName}`;
  return proposal ? `${playerName} was added to the roster` : `You're now ${playerName}'s guardian`;
}

/** Asks the team's admins to decide on a claim or pending player (NOTIF-2, kind guardianRequest). */
async function askAdmins(input: {
  groupId: string;
  uid: string;
  teamName: string;
  playerId: string;
  playerName: string;
  relation: Relation;
  request: 'claim' | 'player';
}): Promise<void> {
  // The team's admins are asked, even at Important only.
  await trySend(async () => {
    const name = await displayNameOf(input.uid, 'Someone');
    return {
      kind: 'guardianRequest',
      groupId: input.groupId,
      recipients: { admins: true },
      actor: { uid: input.uid, name },
      target: { type: 'player', id: input.playerId },
      route: `/g/${input.groupId}/roster`,
      params: {
        actorName: name,
        playerId: input.playerId,
        playerNames: input.playerName,
        relation: input.relation,
        request: input.request,
      },
      body:
        input.request === 'claim'
          ? claimBody(name, input.playerName, input.relation)
          : pendingPlayerBody(name, input.playerName, input.relation),
      // Claim IDs are reused when someone asks again, so each ask gets its own key.
      dedupeKey: randomUUID(),
      teamName: input.teamName,
    };
  });
}

/** Tells a member an admin approved their claim or player (NOTIF-2). A decline isn't announced. */
async function tellApproved(input: {
  groupId: string;
  uid: string;
  actor: string;
  playerId: string;
  playerName: string;
  relation: Relation;
  proposal: boolean;
}): Promise<void> {
  await trySend(async () => {
    const actorName = await displayNameOf(input.actor, 'A team admin');
    return {
      kind: 'guardianApproved',
      groupId: input.groupId,
      recipients: { uids: [input.uid] },
      actor: { uid: input.actor, name: actorName },
      target: { type: 'player', id: input.playerId },
      route: `/g/${input.groupId}/roster/players/${input.playerId}`,
      params: { playerId: input.playerId, playerName: input.playerName, relation: input.relation },
      body: approvedBody(input.playerName, input.relation, input.proposal),
      dedupeKey: randomUUID(),
    };
  });
}

/**
 * Claim a player (PLAYER-3): "I am this player" ('self') or "I'm their
 * parent or guardian". Claims by admins, and by super admins on the team,
 * are approved at once; others wait for an admin (PLAYER-4). Input { playerId, relation, groupId? }; returns
 * { status: 'linked' | 'requested' }.
 */
export const claimPlayer = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(
    z.object({ groupId: z.string().min(1).optional(), playerId: z.string().min(1), relation: RelationInput }),
    request.data,
  );
  const groupId = await teamOfPlayer(input.playerId, input.groupId);
  const superAdmin = request.auth?.token.superAdmin === true;
  const { role, teamName } = await requireTeamMember(groupId, uid, superAdmin, true);
  const admin = actsAsAdmin(role, superAdmin);
  if (!admin) await consumeRateLimit(uid, 'guardianRequest', Limits.guardianRequestsPerUserPerDay);
  const result = await claim(groupId, uid, input.playerId, input.relation, admin);
  await audit({
    actorId: uid,
    action: 'claimPlayer',
    groupId,
    targetType: 'player',
    targetId: input.playerId,
    after: { relation: input.relation, status: result.status },
  });
  if (result.status === 'requested') {
    await askAdmins({
      groupId,
      uid,
      teamName,
      playerId: input.playerId,
      playerName: result.playerName,
      relation: input.relation,
      request: 'claim',
    });
  }
  return { status: result.status };
});

/**
 * Admins approve or decline a claim (PLAYER-4). Input { playerId, uid,
 * approve, groupId? }; returns { ok }.
 */
export const resolvePlayerClaim = onCall(async (request) => {
  const actor = requireAuth(request);
  const input = parse(
    z.object({
      groupId: z.string().min(1).optional(),
      playerId: z.string().min(1),
      uid: z.string().min(1),
      approve: z.boolean(),
    }),
    request.data,
  );
  const groupId = await teamOfPlayer(input.playerId, input.groupId);
  await requireTeamAdmin(groupId, actor, request.auth?.token.superAdmin === true);
  const relation = await resolveClaim(groupId, input.playerId, input.uid, input.approve, actor);
  if (relation) {
    await audit({
      actorId: actor,
      action: input.approve ? 'approveClaim' : 'declineClaim',
      groupId,
      targetType: 'player',
      targetId: input.playerId,
      after: { uid: input.uid, relation },
    });
  }
  if (relation && input.approve) {
    const player = await db().collection(Collections.players).doc(input.playerId).get();
    await tellApproved({
      groupId,
      uid: input.uid,
      actor,
      playerId: input.playerId,
      playerName: (player.get('displayName') as string | undefined) || 'a player',
      relation,
      proposal: false,
    });
  }
  return { ok: relation != null };
});

/**
 * Add a player who isn't on the roster (PLAYER-3), saying how you're
 * linked. A member's player is pending until an admin approves it; an
 * admin's (or a super admin's on the team) is active at once. Input { groupId, displayName, jerseyNumber?,
 * position?, relation }; returns { playerId, status: 'active' | 'pending' }.
 */
export const proposePlayer = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(
    z.object({
      groupId: z.string().min(1),
      displayName: z.string().trim().min(1).max(60),
      jerseyNumber: z.string().trim().max(4).nullable().optional(),
      position: z.string().trim().max(30).nullable().optional(),
      dateOfBirth: DateOfBirth,
      relation: RelationInput,
    }),
    request.data,
  );
  const superAdmin = request.auth?.token.superAdmin === true;
  const { role, teamName } = await requireTeamMember(input.groupId, uid, superAdmin, true);
  const admin = actsAsAdmin(role, superAdmin);
  if (!admin) await consumeRateLimit(uid, 'guardianRequest', Limits.guardianRequestsPerUserPerDay);
  if ((await playersOnTeam(input.groupId)) >= Limits.playersPerGroupMax) {
    throw new HttpsError('failed-precondition', 'too-many-players');
  }
  const result = await propose(input.groupId, uid, input, admin);
  await audit({
    actorId: uid,
    action: 'proposePlayer',
    groupId: input.groupId,
    targetType: 'player',
    targetId: result.playerId,
    after: { name: input.displayName, relation: input.relation, status: result.status },
  });
  if (result.status === 'pending') {
    await askAdmins({
      groupId: input.groupId,
      uid,
      teamName,
      playerId: result.playerId,
      playerName: input.displayName,
      relation: input.relation,
      request: 'player',
    });
  }
  return result;
});

/**
 * Admins approve or decline a pending player (PLAYER-4). Declining deletes
 * it. Input { playerId, approve, groupId? }; returns { ok, linked }.
 */
export const resolvePendingPlayer = onCall(async (request) => {
  const actor = requireAuth(request);
  const input = parse(
    z.object({ groupId: z.string().min(1).optional(), playerId: z.string().min(1), approve: z.boolean() }),
    request.data,
  );
  const groupId = await teamOfPlayer(input.playerId, input.groupId);
  await requireTeamAdmin(groupId, actor, request.auth?.token.superAdmin === true);
  const decision = await resolvePending(groupId, input.playerId, input.approve, actor);
  if (!decision) return { ok: false, linked: false };
  await audit({
    actorId: actor,
    action: input.approve ? 'approvePlayer' : 'declinePlayer',
    groupId,
    targetType: 'player',
    targetId: input.playerId,
    after: { name: decision.playerName, proposedBy: decision.proposedBy, relation: decision.relation },
  });
  if (input.approve && decision.proposedBy && decision.linked) {
    await tellApproved({
      groupId,
      uid: decision.proposedBy,
      actor,
      playerId: input.playerId,
      playerName: decision.playerName,
      relation: decision.relation,
      proposal: true,
    });
  }
  return { ok: true, linked: decision.linked };
});

/**
 * A linked member (the player or a guardian) or an admin adds a guardian
 * by email (PLAYER-5). The existing link vouches for them, so no approval
 * is needed. New emails get an
 * added account and a setup email; people already on Battleplan get an
 * "added to the team" email if they weren't on it.
 */
export const inviteGuardian = onCall({ secrets: [resendApiKey] }, async (request) => {
  const actor = requireAuth(request);
  const input = parse(
    z.object({
      groupId: z.string().min(1),
      playerId: z.string().min(1),
      name: z.string().trim().max(60).nullable().optional(),
      email: z.string().trim().email().max(200),
    }),
    request.data,
  );
  // Adding someone by email needs a verified email (AUTH-3).
  requireVerifiedEmail(request);
  const superAdmin = request.auth?.token.superAdmin === true;
  const { role, teamName } = await requireTeamMember(input.groupId, actor, superAdmin);
  const player = await db().collection(Collections.players).doc(input.playerId).get();
  if (!player.exists || player.get('groupId') !== input.groupId || player.get('status') === 'pending') {
    throw new HttpsError('not-found', 'no-player');
  }
  // Any link vouches, the player's own included (PLAYER-5).
  if (role === 'member' && !superAdmin && !(await linkOf(input.playerId, actor))) {
    throw new HttpsError('permission-denied', 'Only linked members and admins can add guardians.');
  }
  if ((await guardianCount(input.playerId)) >= Limits.guardiansPerPlayerMax) {
    throw new HttpsError('failed-precondition', 'too-many-guardians');
  }
  await consumeRateLimit(input.groupId, 'addByEmail', Limits.addByEmailPerGroupPerDay);
  const user = await findOrProvisionUser(input.email, input.name ?? null);
  const wasMember = (
    await db().collection(Collections.groupMembers).doc(groupMemberId(input.groupId, user.uid)).get()
  ).exists;
  // A person can be on up to 100 teams (TEAM-2).
  if (!wasMember) await requireRoomForAnotherTeam(user.uid, Limits.groupsPerUserMax);
  // The player themselves can't also be their own guardian.
  if ((await linkOf(input.playerId, user.uid)) === 'self') throw new HttpsError('failed-precondition', 'already-linked');
  await linkGuardian(input.groupId, input.playerId, user, actor, 'guardian');
  await refreshPlayerSummary(input.groupId, user.uid);
  const actorProfile = await db().collection(Collections.users).doc(actor).get();
  const actorName = (actorProfile.get('displayName') as string | undefined) ?? 'A teammate';
  // The notification first: it never throws, and a failed email must not
  // skip it or the audit entry.
  if (!wasMember) await notifyAddedToTeam(input.groupId, teamName, { uid: actor, name: actorName }, [user.uid]);
  try {
    if (user.provisioned) {
      await sendSetupEmail(input.email, teamName, actorName);
    } else if (!wasMember) {
      await sendEmail(addedToTeamEmail(input.email.trim().toLowerCase(), teamName, actorName, teamUrl(input.groupId)));
    }
  } catch (e) {
    logger.error('guardian_email_failed', { groupId: input.groupId, error: String(e) });
  }
  await audit({
    actorId: actor,
    action: 'inviteGuardian',
    groupId: input.groupId,
    targetType: 'player',
    targetId: input.playerId,
    after: { uid: user.uid },
  });
  return { uid: user.uid, invited: user.provisioned };
});

/** Removes a link from a player (PLAYER-2): admins, or the linked member themselves. */
export const removeGuardian = onCall(async (request) => {
  const actor = requireAuth(request);
  const input = parse(
    z.object({ groupId: z.string().min(1), playerId: z.string().min(1), uid: z.string().min(1) }),
    request.data,
  );
  if (input.uid !== actor) {
    await requireTeamAdmin(input.groupId, actor, request.auth?.token.superAdmin === true);
  } else {
    await requireOpenTeam(input.groupId, request.auth?.token.superAdmin === true);
  }
  const player = await db().collection(Collections.players).doc(input.playerId).get();
  if (!player.exists || player.get('groupId') !== input.groupId) return { ok: true };
  await removeGuardianLink(input.groupId, input.playerId, input.uid);
  await audit({
    actorId: actor,
    action: 'removeGuardian',
    groupId: input.groupId,
    targetType: 'player',
    targetId: input.playerId,
    before: { uid: input.uid },
  });
  return { ok: true };
});
