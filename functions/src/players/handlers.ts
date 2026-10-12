// Thin entry points for the players domain (ARCH §6.4).
import { logger } from 'firebase-functions/v2';
import { HttpsError } from 'firebase-functions/v2/https';
import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { onCall } from '../shared/callable.js';
import { Collections, Limits } from '../shared/constants.js';
import { requireAuth } from '../shared/guards.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { requireTeamAdmin, roleOf } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { displayNameOf, findOrProvisionUser, sendSetupEmail } from '../accounts/service.js';
import { resendApiKey, sendEmail } from '../email/service.js';
import { addedToTeamEmail } from '../email/templates.js';
import { teamUrl } from '../links/service.js';
import { trySend } from '../notify/service.js';
import { notifyAddedToTeam } from '../teams/service.js';
import { groupMemberId } from '../shared/ids.js';
import { joinNames } from './roster.js';
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
  // NOTIF-2: guardians who weren't on the team are told they were added.
  // First, since it never throws and a failed email below must not skip it.
  await notifyAddedToTeam(input.groupId, group.get('name') as string, { uid, name: actorName }, newMembers);
  // AUTH-6: new guardians get a setup email. One failure doesn't stop the
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
  const { teamName } = await requireYouthMember(input.groupId, uid);
  await consumeRateLimit(uid, 'guardianRequest', Limits.guardianRequestsPerUserPerDay);
  const players = await requestGuardianLinks(input.groupId, uid, input.playerIds);
  if (players.length) {
    // NOTIF-2: the team's admins are asked, even at Important only.
    await trySend(async () => {
      const name = await displayNameOf(uid, 'Someone');
      const playerNames = joinNames(players);
      return {
        kind: 'guardianRequest',
        groupId: input.groupId,
        recipients: { admins: true },
        actor: { uid, name },
        target: { type: 'user', id: uid },
        route: `/g/${input.groupId}/roster`,
        params: { actorName: name, playerNames },
        body: `${name} asked to be ${playerNames}'s guardian`,
        // Request IDs are reused when someone asks again, so each ask gets its own key.
        dedupeKey: randomUUID(),
        teamName,
      };
    });
  }
  return { requested: players.length };
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
  if (done && input.approve) {
    // NOTIF-2: the parent hears they're approved. A decline isn't announced.
    await trySend(async () => {
      const [player, actorName] = await Promise.all([
        db().collection(Collections.players).doc(input.playerId).get(),
        displayNameOf(actor, 'A team admin'),
      ]);
      if (!player.exists) return null;
      const playerName = (player.get('displayName') as string | undefined) || 'a player';
      return {
        kind: 'guardianApproved',
        groupId: input.groupId,
        recipients: { uids: [input.uid] },
        actor: { uid: actor, name: actorName },
        target: { type: 'player', id: input.playerId },
        route: `/g/${input.groupId}/roster/players/${input.playerId}`,
        params: { playerId: input.playerId, playerName },
        body: `You're now ${playerName}'s guardian`,
        dedupeKey: randomUUID(),
      };
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
  // PLAYER-3: admins hear about a player a parent added, to check it.
  await trySend(async () => {
    const name = await displayNameOf(uid, 'A parent');
    return {
      kind: 'playerAdded',
      groupId: input.groupId,
      recipients: { admins: true },
      actor: { uid, name },
      target: { type: 'player', id: playerId },
      route: `/g/${input.groupId}/roster/players/${playerId}`,
      params: { actorName: name, playerId, playerName: input.name },
      body: `${name} added a player: ${input.name}`,
      dedupeKey: randomUUID(),
      teamName: group.get('name') as string,
    };
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
