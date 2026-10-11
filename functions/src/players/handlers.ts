// Thin entry points for the players domain (ARCH §6.4).
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { requireAuth } from '../shared/guards.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { requireTeamAdmin } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { sendSetupEmail } from '../accounts/service.js';
import { resendApiKey } from '../email/service.js';
import { addPlayers as add, removePlayer as remove } from './service.js';

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
  for (let i = 0; i < Math.max(guardianEmails, 1); i++) {
    await consumeRateLimit(input.groupId, 'addByEmail', Limits.addByEmailPerGroupPerDay);
  }
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
