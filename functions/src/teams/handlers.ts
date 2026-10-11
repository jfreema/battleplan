// Thin entry points for the teams domain (ARCH §6.4).
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { auth, db } from '../shared/admin.js';
import { Collections, Limits, sportValues, TEAM_COLORS, teamTypeValues } from '../shared/constants.js';
import { requireAuth } from '../shared/guards.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { parse } from '../shared/validate.js';
import { audit } from '../audit/service.js';
import { postSystemMessage } from '../chat/service.js';
import { groupMemberId } from '../shared/ids.js';
import { requireTeamAdmin } from '../shared/roles.js';
import { canChangeRole, canRemove, createGroup as create, refreshMemberCount } from './service.js';

const CreateGroupInput = z.object({
  name: z.string().trim().min(1).max(Limits.groupNameMax),
  sport: z.enum(sportValues),
  teamType: z.enum(teamTypeValues),
  color: z.enum(TEAM_COLORS).optional(),
  timeZone: z.string().min(1).max(64),
  description: z.string().max(500).optional(),
});

/** Creates a team with the caller as owner (TEAM-1). */
export const createGroup = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(CreateGroupInput, request.data);

  // Verified email required (AUTH-3, SAFE-5); super admins can turn
  // team creation off for everyone else (Q3, ADMIN-7).
  const user = await auth().getUser(uid);
  if (!user.emailVerified) {
    throw new HttpsError('failed-precondition', 'email-not-verified');
  }
  const config = (await db().collection(Collections.config).doc('app').get()).data() ?? {};
  const superAdmin = request.auth?.token.superAdmin === true;
  if (config.allowUserGroupCreation === false && !superAdmin) {
    throw new HttpsError('permission-denied', 'group-creation-off');
  }
  if (!superAdmin) {
    await consumeRateLimit(
      uid,
      'createGroup',
      (config.maxGroupsCreatedPerUserPerDay as number | undefined) ?? Limits.groupsCreatedPerUserPerDay,
    );
  }

  // A person can be on up to 100 teams (TEAM-2).
  const teams = await db()
    .collection(Collections.groupMembers)
    .where('uid', '==', uid)
    .count()
    .get();
  if (teams.data().count >= Limits.groupsPerUserMax) {
    throw new HttpsError('failed-precondition', 'too-many-teams');
  }

  const profile = (await db().collection(Collections.users).doc(uid).get()).data();
  const groupId = await create(
    uid,
    {
      displayName: (profile?.displayName as string | undefined) ?? user.displayName ?? 'Team owner',
      photoPath: (profile?.photoPath as string | null | undefined) ?? null,
    },
    input,
    (config.defaultStorageQuotaGb as number | undefined) ?? Limits.defaultStorageQuotaGb,
  );
  return { groupId };
});

const UpdateMemberInput = z.object({
  groupId: z.string().min(1),
  uid: z.string().min(1),
  role: z.enum(['admin', 'member']).optional(),
  title: z.string().trim().max(40).nullable().optional(),
});

/** Changes a member's role or title (TEAM-3, TEAM-4). */
export const updateGroupMember = onCall(async (request) => {
  const actorUid = requireAuth(request);
  const input = parse(UpdateMemberInput, request.data);
  const actor = await requireTeamAdmin(input.groupId, actorUid, request.auth?.token.superAdmin === true);
  const ref = db().collection(Collections.groupMembers).doc(groupMemberId(input.groupId, input.uid));
  const target = await ref.get();
  if (!target.exists) throw new HttpsError('not-found', 'Not a member.');
  const targetRole = target.get('role') as 'owner' | 'admin' | 'member';
  const update: Record<string, unknown> = {};
  if (input.role && input.role !== targetRole) {
    if (!canChangeRole(actor, targetRole, input.role)) {
      throw new HttpsError('permission-denied', 'Only the owner can remove an admin.');
    }
    update.role = input.role;
  }
  if (input.title !== undefined) update.title = input.title || null;
  if (Object.keys(update).length === 0) return { ok: true };
  await ref.update(update);
  await audit({
    actorId: actorUid,
    action: 'updateGroupMember',
    groupId: input.groupId,
    targetType: 'user',
    targetId: input.uid,
    before: { role: targetRole, title: target.get('title') ?? null },
    after: update,
  });
  if (update.role === 'admin') {
    const name = (target.get('displayName') as string) || 'Someone';
    await postSystemMessage(input.groupId, 'madeAdmin', `${name} is now an admin`, actorUid, input.uid);
  }
  return { ok: true };
});

const RemoveMemberInput = z.object({ groupId: z.string().min(1), uid: z.string().min(1) });

/** Removes someone from a team (TEAM-3). Leaving yourself is leaveGroup. */
export const removeMember = onCall(async (request) => {
  const actorUid = requireAuth(request);
  const input = parse(RemoveMemberInput, request.data);
  if (input.uid === actorUid) throw new HttpsError('invalid-argument', 'Use leave team instead.');
  const actor = await requireTeamAdmin(input.groupId, actorUid, request.auth?.token.superAdmin === true);
  const ref = db().collection(Collections.groupMembers).doc(groupMemberId(input.groupId, input.uid));
  const target = await ref.get();
  if (!target.exists) return { ok: true };
  const targetRole = target.get('role') as 'owner' | 'admin' | 'member';
  if (!canRemove(actor, targetRole)) {
    throw new HttpsError('permission-denied', 'Only the owner can remove an admin.');
  }
  await ref.delete();
  await refreshMemberCount(input.groupId);
  await audit({
    actorId: actorUid,
    action: 'removeMember',
    groupId: input.groupId,
    targetType: 'user',
    targetId: input.uid,
    before: { role: targetRole },
  });
  const name = (target.get('displayName') as string) || 'Someone';
  await postSystemMessage(input.groupId, 'removed', `${name} was removed`, actorUid, input.uid);
  return { ok: true };
});
