// Thin entry points for the teams domain (ARCH §6.4).
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { auth, db } from '../shared/admin.js';
import { onCall } from '../shared/callable.js';
import { Collections, Limits, sportValues } from '../shared/constants.js';
import { teamColor } from '../shared/team_color.js';
import { requireAuth, requireSuperAdmin } from '../shared/guards.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { parse } from '../shared/validate.js';
import { audit } from '../audit/service.js';
import { tryDeleteCalendarLinksOf } from '../calendar/service.js';
import { alertTeamCreated, alertTeamDeleted } from '../admin/alerts.js';
import { groupCreationConfig } from '../admin/service.js';
import { postSystemMessage } from '../chat/service.js';
import { groupMemberId } from '../shared/ids.js';
import {
  requireOpenTeam,
  requireRoomForAnotherTeam,
  requireTeamAdmin,
  requireTeamOwner,
  roleOf,
} from '../shared/roles.js';
import { displayNameOf, sendSetupEmail } from '../accounts/service.js';
import { resendApiKey } from '../email/service.js';
import { trySend } from '../notify/service.js';
import { hideReportsAbout } from '../safety/service.js';
import { tryClearAssignmentsOf } from '../schedule/assignments.js';
import {
  addMembersByEmail,
  canChangeRole,
  canRemove,
  clearTeamNotifications,
  createGroup as create,
  deleteGroupNamed,
  teamIdFor,
  refreshMemberCount,
  removeFromTeam,
  setGroupArchived,
} from './service.js';
import { deleteMedia, listMedia } from './media.js';
import { removeGuardianFromTeam } from '../players/service.js';
import { setGroupQuota, updateStorageAlert } from './storage.js';

const CreateGroupInput = z.object({
  name: z.string().trim().min(1).max(Limits.groupNameMax),
  // A team (the default, and all older apps send) or a basic group (TEAM-14).
  kind: z.enum(['team', 'group']).optional(),
  sport: z.enum(sportValues),
  color: teamColor.optional(),
  timeZone: z.string().min(1).max(64),
  description: z.string().max(500).optional(),
  // The app's ID for this attempt, the same on every retry of it (TEAM-1).
  requestId: z.string().regex(/^[A-Za-z0-9_-]{8,64}$/).optional(),
});

/**
 * Creates a team with the caller as owner (TEAM-1). With a requestId, the
 * team's ID comes from it, so a retry of an attempt whose first request
 * arrived late (a phone can hold a request for minutes before sending it)
 * gets back the team that request made, not a second one.
 */
export const createGroup = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(CreateGroupInput, request.data);
  const madeId = input.requestId ? teamIdFor(uid, input.requestId) : undefined;
  const alreadyMade = async () =>
    madeId !== undefined && (await db().collection(Collections.groups).doc(madeId).get()).get('createdBy') === uid;
  if (await alreadyMade()) return { groupId: madeId };

  // Verified email required (AUTH-3, SAFE-5); super admins can turn
  // team creation off for everyone else (Q3, ADMIN-7).
  const user = await auth().getUser(uid);
  if (!user.emailVerified) {
    throw new HttpsError('failed-precondition', 'email-not-verified');
  }
  const config = await groupCreationConfig();
  const superAdmin = request.auth?.token.superAdmin === true;
  if (!config.allowUserGroupCreation && !superAdmin) {
    throw new HttpsError('permission-denied', 'group-creation-off');
  }
  if (!superAdmin) {
    await consumeRateLimit(uid, 'createGroup', config.maxGroupsCreatedPerUserPerDay);
  }

  // A person can be on up to 100 teams (TEAM-2).
  await requireRoomForAnotherTeam(uid, Limits.groupsPerUserMax);

  const profile = (await db().collection(Collections.users).doc(uid).get()).data();
  let groupId: string;
  try {
    groupId = await create(
      uid,
      {
        displayName: (profile?.displayName as string | undefined) ?? user.displayName ?? 'Team owner',
        photoPath: (profile?.photoPath as string | null | undefined) ?? null,
      },
      input,
      // New teams start at the platform's default limit (STORE-1, ADMIN-7).
      config.defaultStorageQuotaMb,
      madeId,
    );
  } catch (e) {
    // Two copies of one attempt at the same moment: the other made it.
    if ((e as { code?: number }).code === 6 && (await alreadyMade())) return { groupId: madeId };
    throw e;
  }
  // ADMIN-9: super admins hear about every new team.
  await alertTeamCreated({
    groupId,
    name: input.name,
    kind: input.kind ?? 'team',
    sport: input.sport,
    ownerName: (profile?.displayName as string | undefined) ?? user.displayName ?? 'Someone',
    ownerEmail: user.email ?? '',
  });
  return { groupId };
});

const UpdateMemberInput = z.object({
  groupId: z.string().min(1),
  uid: z.string().min(1),
  role: z.enum(['admin', 'member']).optional(),
  title: z.string().trim().max(40).nullable().optional(),
  // A coach of the team (TEAM-3); unset, the owner counts as one.
  coach: z.boolean().optional(),
});

/** Changes a member's role, title, or whether they coach (TEAM-3, TEAM-4). */
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
  // Nobody coaches a basic group (TEAM-14); an older app may still ask.
  if (input.coach !== undefined) {
    const group = await db().collection(Collections.groups).doc(input.groupId).get();
    if (group.get('kind') !== 'group') update.coach = input.coach;
  }
  if (Object.keys(update).length === 0) return { ok: true };
  await ref.update(update);
  await audit({
    actorId: actorUid,
    action: 'updateGroupMember',
    groupId: input.groupId,
    targetType: 'user',
    targetId: input.uid,
    before: { role: targetRole, title: target.get('title') ?? null, coach: target.get('coach') ?? null },
    after: update,
  });
  if (update.role === 'admin') {
    await hideReportsAbout(input.groupId, input.uid);
    const name = (target.get('displayName') as string) || 'Someone';
    await postSystemMessage(input.groupId, 'madeAdmin', `${name} is now an admin`, actorUid, input.uid);
    // NOTIF-2: the new admin is told, even at Important only.
    await trySend(async () => {
      const actorName = await displayNameOf(actorUid, 'A team admin');
      return {
        kind: 'madeAdmin',
        groupId: input.groupId,
        recipients: { uids: [input.uid] },
        actor: { uid: actorUid, name: actorName },
        target: { type: 'user', id: input.uid },
        route: `/g/${input.groupId}/chat`,
        params: { actorName },
        body: `${actorName} made you an admin`,
        dedupeKey: randomUUID(),
      };
    });
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
  const targetRole = await roleOf(input.groupId, input.uid);
  if (!targetRole) return { ok: true };
  if (!canRemove(actor, targetRole)) {
    throw new HttpsError('permission-denied', 'Only the owner can remove an admin.');
  }
  await removeFromTeam(input.groupId, input.uid, actorUid);
  await audit({
    actorId: actorUid,
    action: 'removeMember',
    groupId: input.groupId,
    targetType: 'user',
    targetId: input.uid,
    before: { role: targetRole },
  });
  return { ok: true };
});

const GroupOnly = z.object({ groupId: z.string().min(1) });

/** Hands the team to another member; the old owner becomes an admin (TEAM-6). */
export const transferOwnership = onCall(async (request) => {
  const actorUid = requireAuth(request);
  const input = parse(GroupOnly.extend({ uid: z.string().min(1) }), request.data);
  await requireTeamOwner(input.groupId, actorUid, request.auth?.token.superAdmin === true);
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
  await hideReportsAbout(input.groupId, input.uid);
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

/**
 * Leaves a team (TEAM-8). The owner transfers ownership first. Their tasks
 * on the team's events open again (SCHED-15).
 */
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
  // They stop being a guardian here too (TEAM-8, PLAYER-3).
  await removeGuardianFromTeam(input.groupId, uid);
  await refreshMemberCount(input.groupId);
  const name = (me.get('displayName') as string) || 'Someone';
  await postSystemMessage(input.groupId, 'left', `${name} left`, uid);
  await clearTeamNotifications(input.groupId, uid);
  await tryDeleteCalendarLinksOf(uid, input.groupId);
  await tryClearAssignmentsOf(uid, input.groupId);
  return { ok: true };
});

/**
 * Archives (read-only) or restores a team (TEAM-9). Not while it's
 * suspended, except by a super admin (§3).
 */
export const archiveGroup = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(GroupOnly.extend({ archived: z.boolean() }), request.data);
  await requireTeamOwner(input.groupId, uid, request.auth?.token.superAdmin === true, { allowArchived: true });
  const before = await setGroupArchived(input.groupId, input.archived);
  await audit({
    actorId: uid,
    action: input.archived ? 'archiveGroup' : 'restoreGroup',
    groupId: input.groupId,
    targetType: 'group',
    targetId: input.groupId,
    before,
    after: { archived: input.archived },
  });
  return { ok: true };
});

/**
 * Permanently deletes a team after the owner types its name (TEAM-9). An
 * archived team can be deleted; a suspended one only by a super admin, so
 * its owner can't erase what it was suspended for (§3).
 */
export const deleteGroup = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(GroupOnly.extend({ confirmName: z.string() }), request.data);
  const superAdmin = request.auth?.token.superAdmin === true;
  const owner = (await roleOf(input.groupId, uid)) === 'owner';
  if (!superAdmin && !owner) {
    throw new HttpsError('permission-denied', 'Only the team owner can do that.');
  }
  // A team that's already gone is left alone (deleteGroupNamed).
  const group = await db().collection(Collections.groups).doc(input.groupId).get();
  if (group.exists) await requireOpenTeam(input.groupId, superAdmin, { allowArchived: true });
  const deleted: { before?: { name: string; memberCount: number } } = {};
  await deleteGroupNamed(input.groupId, input.confirmName, (before) => {
    deleted.before = before;
    return audit({
      actorId: uid,
      action: 'deleteGroup',
      groupId: input.groupId,
      targetType: 'group',
      targetId: input.groupId,
      before,
    });
  });
  // ADMIN-9: super admins hear about every deleted team.
  if (deleted.before) {
    await alertTeamDeleted({ groupId: input.groupId, ...deleted.before, actorUid: uid, bySuperAdmin: !owner });
  }
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
  await consumeRateLimit(input.groupId, 'addByEmail', Limits.addByEmailPerGroupPerDay, 'day', input.entries.length);
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

// ---- Team storage (STORE-5, STORE-6, ARCH §6.11) ----------------------------

/** A team ID as it appears in a Storage path: no slashes. */
const GroupId = z.string().min(1).max(128).regex(/^[^/]+$/);

const SetQuotaInput = z.object({
  groupId: GroupId,
  // Null puts the team back on the default (ADMIN-7).
  quotaMb: z.number().int().min(1).max(Limits.storageQuotaMaxMb).nullable(),
});

/**
 * Gives one team its own storage limit, higher or lower, or puts it back
 * on the default (STORE-6). Super admins only, and the option isn't shown
 * to anyone else. Audited, and the team's warning follows the new limit
 * right away.
 */
export const adminSetGroupQuota = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(SetQuotaInput, request.data);
  // Teams only: a direct conversation keeps its own limit (CHAT-19).
  await requireOpenTeam(input.groupId, true, { allowArchived: true });
  const { before, after, custom } = await setGroupQuota(input.groupId, input.quotaMb);
  await audit({
    actorId: actor,
    action: 'setGroupQuota',
    groupId: input.groupId,
    targetType: 'group',
    targetId: input.groupId,
    before: { storageQuotaBytes: before },
    after: { storageQuotaBytes: after, storageQuotaCustom: custom },
  });
  await updateStorageAlert(input.groupId);
  return { storageQuotaBytes: after };
});

/** Every file the team stores, largest first, with what uses it (STORE-5). Team admins. */
export const listTeamMedia = onCall(async (request) => {
  const uid = requireAuth(request);
  const { groupId } = parse(z.object({ groupId: GroupId }), request.data);
  // Reading is fine on an archived team; deleting isn't (TEAM-9).
  await requireTeamAdmin(groupId, uid, request.auth?.token.superAdmin === true, { allowArchived: true });
  return listMedia(groupId);
});

const DeleteMediaInput = z.object({ groupId: GroupId, path: z.string().min(1).max(1024) });

/**
 * Deletes one team file to free space (STORE-5): a chat photo leaves its
 * message, the logo or background in use is reset, and a document's file
 * takes its document with it (the response's `fixed` is 'deletedDocument').
 * Team admins; audited.
 */
export const deleteTeamMedia = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(DeleteMediaInput, request.data);
  await requireTeamAdmin(input.groupId, uid, request.auth?.token.superAdmin === true);
  const deleted = await deleteMedia(input.groupId, input.path, uid);
  await audit({
    actorId: uid,
    action: 'deleteTeamMedia',
    groupId: input.groupId,
    targetType: 'file',
    targetId: input.path,
    before: {
      kind: deleted.kind,
      size: deleted.size,
      messageId: deleted.messageId ?? null,
      documentId: deleted.documentId ?? null,
    },
    after: { fixed: deleted.fixed },
  });
  return { ok: true, kind: deleted.kind, fixed: deleted.fixed };
});
