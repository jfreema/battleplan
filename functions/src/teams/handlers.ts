// Thin entry points for the teams domain (ARCH §6.4).
import { FieldValue } from 'firebase-admin/firestore';
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
import { requireTeamAdmin, roleOf } from '../shared/roles.js';
import { sendSetupEmail } from '../accounts/service.js';
import { resendApiKey } from '../email/service.js';
import {
  addMembersByEmail,
  canChangeRole,
  canRemove,
  createGroup as create,
  deleteGroupData,
  refreshMemberCount,
} from './service.js';

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

const GroupOnly = z.object({ groupId: z.string().min(1) });

/** Throws unless the caller owns the team or is a super admin. */
async function requireOwner(groupId: string, uid: string, superAdmin: boolean): Promise<void> {
  if (superAdmin) return;
  if ((await roleOf(groupId, uid)) !== 'owner') {
    throw new HttpsError('permission-denied', 'Only the team owner can do that.');
  }
}

/** Hands the team to another member; the old owner becomes an admin (TEAM-6). */
export const transferOwnership = onCall(async (request) => {
  const actorUid = requireAuth(request);
  const input = parse(GroupOnly.extend({ uid: z.string().min(1) }), request.data);
  await requireOwner(input.groupId, actorUid, request.auth?.token.superAdmin === true);
  const groupRef = db().collection(Collections.groups).doc(input.groupId);
  const ownerId = (await groupRef.get()).get('ownerId') as string;
  if (input.uid === ownerId) return { ok: true };
  const newRef = db().collection(Collections.groupMembers).doc(groupMemberId(input.groupId, input.uid));
  if (!(await newRef.get()).exists) throw new HttpsError('not-found', 'Not a member.');
  await db()
    .batch()
    .update(newRef, { role: 'owner' })
    .update(db().collection(Collections.groupMembers).doc(groupMemberId(input.groupId, ownerId)), { role: 'admin' })
    .update(groupRef, { ownerId: input.uid, updatedAt: FieldValue.serverTimestamp() })
    .commit();
  await audit({
    actorId: actorUid,
    action: 'transferOwnership',
    groupId: input.groupId,
    targetType: 'group',
    targetId: input.groupId,
    before: { ownerId },
    after: { ownerId: input.uid },
  });
  return { ok: true };
});

/** Leaves a team (TEAM-8). The owner transfers ownership first. */
export const leaveGroup = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(GroupOnly, request.data);
  const ref = db().collection(Collections.groupMembers).doc(groupMemberId(input.groupId, uid));
  const me = await ref.get();
  if (!me.exists) return { ok: true };
  if (me.get('role') === 'owner') {
    throw new HttpsError('failed-precondition', 'owner-must-transfer');
  }
  await ref.delete();
  await refreshMemberCount(input.groupId);
  const name = (me.get('displayName') as string) || 'Someone';
  await postSystemMessage(input.groupId, 'left', `${name} left`, uid);
  return { ok: true };
});

/** Archives (read-only) or restores a team (TEAM-9). */
export const archiveGroup = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(GroupOnly.extend({ archived: z.boolean() }), request.data);
  await requireOwner(input.groupId, uid, request.auth?.token.superAdmin === true);
  await db()
    .collection(Collections.groups)
    .doc(input.groupId)
    .update({
      archivedAt: input.archived ? FieldValue.serverTimestamp() : null,
      updatedAt: FieldValue.serverTimestamp(),
    });
  await audit({
    actorId: uid,
    action: input.archived ? 'archiveGroup' : 'restoreGroup',
    groupId: input.groupId,
    targetType: 'group',
    targetId: input.groupId,
  });
  return { ok: true };
});

/** Permanently deletes a team after the owner types its name (TEAM-9). */
export const deleteGroup = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(GroupOnly.extend({ confirmName: z.string() }), request.data);
  await requireOwner(input.groupId, uid, request.auth?.token.superAdmin === true);
  const group = await db().collection(Collections.groups).doc(input.groupId).get();
  if (!group.exists) return { ok: true };
  if (input.confirmName.trim() !== (group.get('name') as string).trim()) {
    throw new HttpsError('invalid-argument', 'name-mismatch');
  }
  await audit({
    actorId: uid,
    action: 'deleteGroup',
    groupId: input.groupId,
    targetType: 'group',
    targetId: input.groupId,
    before: { name: group.get('name'), memberCount: group.get('memberCount') },
  });
  await deleteGroupData(input.groupId);
  return { ok: true };
});

const AddByEmailInput = z.object({
  groupId: z.string().min(1),
  entries: z
    .array(z.object({ name: z.string().trim().max(60).nullable().optional(), email: z.string().trim().email().max(200) }))
    .min(1)
    .max(Limits.pastedMembersMax),
});

/** Adds people by email, one or a pasted list (TEAM-7). Admins with a verified email. */
export const addMemberByEmail = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(AddByEmailInput, request.data);
  await requireTeamAdmin(input.groupId, uid, request.auth?.token.superAdmin === true);
  if (request.auth?.token.email_verified !== true) {
    throw new HttpsError('failed-precondition', 'email-not-verified');
  }
  for (let i = 0; i < input.entries.length; i++) {
    await consumeRateLimit(input.groupId, 'addByEmail', Limits.addByEmailPerGroupPerDay);
  }
  const profile = (await db().collection(Collections.users).doc(uid).get()).data();
  const result = await addMembersByEmail(
    input.groupId,
    { uid, name: (profile?.displayName as string | undefined) ?? 'A team admin' },
    input.entries,
  );
  await audit({
    actorId: uid,
    action: 'addMemberByEmail',
    groupId: input.groupId,
    targetType: 'group',
    targetId: input.groupId,
    after: { added: result.added, invited: result.invited },
  });
  return result;
});

/** Sends a fresh setup email to someone who hasn't joined yet (AUTH-6). Admins only. */
export const resendSetupEmail = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(z.object({ groupId: z.string().min(1), uid: z.string().min(1) }), request.data);
  await requireTeamAdmin(input.groupId, uid, request.auth?.token.superAdmin === true);
  const member = await db().collection(Collections.groupMembers).doc(groupMemberId(input.groupId, input.uid)).get();
  const target = await db().collection(Collections.users).doc(input.uid).get();
  if (!member.exists || target.get('status') !== 'provisioned') {
    throw new HttpsError('failed-precondition', 'already-joined');
  }
  await consumeRateLimit(input.groupId, 'addByEmail', Limits.addByEmailPerGroupPerDay);
  const group = await db().collection(Collections.groups).doc(input.groupId).get();
  const actor = await db().collection(Collections.users).doc(uid).get();
  await sendSetupEmail(
    target.get('email') as string,
    group.get('name') as string,
    (actor.get('displayName') as string | undefined) ?? 'A team admin',
  );
  return { ok: true };
});
