// Thin entry points for the players domain (ARCH §6.4).
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { requireAuth } from '../shared/guards.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { requireTeamAdmin, roleOf } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { findOrProvisionUser, sendSetupEmail } from '../accounts/service.js';
import { resendApiKey, sendEmail } from '../email/service.js';
import { addedToTeamEmail } from '../email/templates.js';
import { teamUrl } from '../links/service.js';
import { groupMemberId } from '../shared/ids.js';
import {
  addPlayers as add,
  addMyPlayer as addMine,
  guardianCount,
  isGuardian,
  linkGuardian,
  refreshPlayerSummary,
  removeGuardianLink,
  removePlayer as remove,
  requestGuardianLinks,
  resolveGuardianRequest,
} from './service.js';

const Guardian = z.object({
  name: z.string().trim().max(60).nullable().optional(),
  email: z.string().trim().email().max(200).nullable().optional(),
});

const Player = z.object({
  name: z.string().trim().min(1).max(60),
  jerseyNumber: z.string().trim().max(4).nullable().optional(),
  position: z.string().trim().max(30).nullable().optional(),
  guardians: z.array(Guardian).max(Limits.guardiansPerPlayerMax).default([]),
});

const AddPlayersInput = z.object({
  groupId: z.string().min(1),
  players: z.array(Player).min(1).max(Limits.pastedRosterLinesMax),
});

/** Adds players with their guardians to a youth team (PLAYER-1). Admins only. */
export const addPlayers = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(AddPlayersInput, request.data);
  await requireTeamAdmin(input.groupId, uid, request.auth?.token.superAdmin === true);
  const group = await db().collection(Collections.groups).doc(input.groupId).get();
  if (group.get('teamType') !== 'youth') throw new HttpsError('failed-precondition', 'not-youth-team');
  const players = (group.get('playerCount') as number | undefined) ?? 0;
  if (players + input.players.length > Limits.playersPerGroupMax) {
    throw new HttpsError('failed-precondition', 'too-many-players');
  }
  const guardianEmails = input.players.flatMap((p) => p.guardians.filter((g) => g.email)).length;
  await consumeRateLimit(
    input.groupId,
    'addByEmail',
    Limits.addByEmailPerGroupPerDay,
    'day',
    Math.max(guardianEmails, 1),
  );
  const result = await add(input.groupId, uid, input.players);
  await audit({
    actorId: uid,
    action: 'addPlayers',
    groupId: input.groupId,
    targetType: 'group',
    targetId: input.groupId,
    after: { playersAdded: result.playersAdded, guardiansInvited: result.guardiansInvited },
  });
  // AUTH-6: new guardians get a setup email.
  const actor = await db().collection(Collections.users).doc(uid).get();
  const actorName = (actor.get('displayName') as string | undefined) ?? 'A team admin';
  for (const email of result.invitedEmails) {
    await sendSetupEmail(email, group.get('name') as string, actorName);
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

/** Throws unless [groupId] is a youth team the caller belongs to. */
async function requireYouthMember(groupId: string, uid: string): Promise<{ role: string; teamName: string }> {
  const role = await roleOf(groupId, uid);
  if (!role) throw new HttpsError('permission-denied', 'Not a member.');
  const group = await db().collection(Collections.groups).doc(groupId).get();
  if (group.get('teamType') !== 'youth') throw new HttpsError('failed-precondition', 'not-youth-team');
  if (group.get('archivedAt')) throw new HttpsError('failed-precondition', 'team-archived');
  return { role, teamName: group.get('name') as string };
}

/** "Who are you here for?": ask admins to link you to players (PLAYER-3). */
export const requestGuardianLink = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(
    z.object({ groupId: z.string().min(1), playerIds: z.array(z.string().min(1)).min(1).max(10) }),
    request.data,
  );
  await requireYouthMember(input.groupId, uid);
  await consumeRateLimit(uid, 'guardianRequest', Limits.guardianRequestsPerUserPerDay);
  return { requested: await requestGuardianLinks(input.groupId, uid, input.playerIds) };
});

/** Admins approve or decline a guardian request (PLAYER-4). */
export const resolveGuardianLink = onCall(async (request) => {
  const actor = requireAuth(request);
  const input = parse(
    z.object({
      groupId: z.string().min(1),
      playerId: z.string().min(1),
      uid: z.string().min(1),
      approve: z.boolean(),
    }),
    request.data,
  );
  await requireTeamAdmin(input.groupId, actor, request.auth?.token.superAdmin === true);
  const done = await resolveGuardianRequest(input.groupId, input.playerId, input.uid, input.approve, actor);
  if (done) {
    await audit({
      actorId: actor,
      action: input.approve ? 'approveGuardian' : 'declineGuardian',
      groupId: input.groupId,
      targetType: 'player',
      targetId: input.playerId,
      after: { uid: input.uid },
    });
  }
  return { ok: done };
});

/** A parent adds their player who isn't listed (PLAYER-3). */
export const addMyPlayer = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(
    z.object({
      groupId: z.string().min(1),
      name: z.string().trim().min(1).max(60),
      jerseyNumber: z.string().trim().max(4).nullable().optional(),
    }),
    request.data,
  );
  await requireYouthMember(input.groupId, uid);
  await consumeRateLimit(uid, 'guardianRequest', Limits.guardianRequestsPerUserPerDay);
  const group = await db().collection(Collections.groups).doc(input.groupId).get();
  if (((group.get('playerCount') as number | undefined) ?? 0) >= Limits.playersPerGroupMax) {
    throw new HttpsError('failed-precondition', 'too-many-players');
  }
  const playerId = await addMine(input.groupId, uid, input);
  await audit({
    actorId: uid,
    action: 'addMyPlayer',
    groupId: input.groupId,
    targetType: 'player',
    targetId: playerId,
    after: { name: input.name },
  });
  return { playerId };
});

/**
 * A guardian (or an admin) adds a co-parent by email (PLAYER-5). The
 * guardian vouches for them, so no approval is needed. New emails get an
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
  const { role, teamName } = await requireYouthMember(input.groupId, actor);
  const player = await db().collection(Collections.players).doc(input.playerId).get();
  if (!player.exists || player.get('groupId') !== input.groupId) throw new HttpsError('not-found', 'no-player');
  if (role === 'member' && !(await isGuardian(input.playerId, actor))) {
    throw new HttpsError('permission-denied', 'Only guardians and admins can add guardians.');
  }
  if ((await guardianCount(input.playerId)) >= Limits.guardiansPerPlayerMax) {
    throw new HttpsError('failed-precondition', 'too-many-guardians');
  }
  await consumeRateLimit(input.groupId, 'addByEmail', Limits.addByEmailPerGroupPerDay);
  const user = await findOrProvisionUser(input.email, input.name ?? null);
  const wasMember = (
    await db().collection(Collections.groupMembers).doc(groupMemberId(input.groupId, user.uid)).get()
  ).exists;
  await linkGuardian(input.groupId, input.playerId, user, actor, 'guardian');
  await refreshPlayerSummary(input.groupId, user.uid);
  const actorProfile = await db().collection(Collections.users).doc(actor).get();
  const actorName = (actorProfile.get('displayName') as string | undefined) ?? 'A teammate';
  if (user.provisioned) {
    await sendSetupEmail(input.email, teamName, actorName);
  } else if (!wasMember) {
    await sendEmail(addedToTeamEmail(input.email.trim().toLowerCase(), teamName, actorName, teamUrl(input.groupId)));
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

/** Removes a guardian from a player (PLAYER-2): admins, or the guardian. */
export const removeGuardian = onCall(async (request) => {
  const actor = requireAuth(request);
  const input = parse(
    z.object({ groupId: z.string().min(1), playerId: z.string().min(1), uid: z.string().min(1) }),
    request.data,
  );
  if (input.uid !== actor) {
    await requireTeamAdmin(input.groupId, actor, request.auth?.token.superAdmin === true);
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
