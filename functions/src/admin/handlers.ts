// Thin entry points for the God admin panel (SPEC §6.11, ARCH §6.4). Every
// callable checks the superAdmin claim first, and every action (not the
// reads) writes an audit entry (ADMIN-8). Nobody's password is ever set or
// returned: admins send setup and reset emails only (AUTH-6).
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { audit } from '../audit/service.js';
import {
  authEmailOf,
  deleteAccount,
  displayNameOf,
  findOrProvisionUser,
  requireAccount,
  sendAccountSetupEmail,
  sendPasswordReset,
  setAccountDisabled,
  setDisplayName,
  setSuperAdminClaim,
  signOutEverywhere,
  uidForEmail,
} from '../accounts/service.js';
import { eraseMessage } from '../chat/service.js';
import { deleteDocumentOf } from '../documents/service.js';
import { resendApiKey } from '../email/service.js';
import { closeReport, openReport } from '../safety/service.js';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { requireSuperAdmin } from '../shared/guards.js';
import { roleOf } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import {
  addMembersByEmail,
  deleteGroupNamed,
  removeFromTeam,
  setGroupArchived,
  setGroupSuspended,
  setMemberRole,
} from '../teams/service.js';
import {
  ArchiveInput,
  CreateUserInput,
  DeleteGroupInput,
  GroupInput,
  ListReportsInput,
  ListTeamsInput,
  ListUsersInput,
  resolutionFor,
  ResolveReportInput,
  SetDisabledInput,
  SetSuperAdminInput,
  SetSuspendedInput,
  UidInput,
  UpdateConfigInput,
  UpdateUserInput,
} from './inputs.js';
import {
  dashboard,
  getTeam,
  getUser,
  listReports,
  listTeams,
  listUsers,
  markSuperAdmin,
  updateConfig,
  wouldLeaveNoSuperAdmin,
} from './service.js';

/** The caller's name for emails they trigger ("Jordan added you to Thunder"). */
const actorName = (uid: string) => displayNameOf(uid, 'Battleplan support');

/** Throws unless the team exists. */
async function requireTeam(groupId: string): Promise<void> {
  if (!(await db().collection(Collections.groups).doc(groupId).get()).exists) {
    throw new HttpsError('not-found', 'No such team.');
  }
}

/** Adds an existing account to a team as [role] (ADMIN-4), through the team's own add-by-email flow. */
async function addToTeam(
  groupId: string,
  uid: string,
  email: string,
  role: 'admin' | 'member',
  actor: string,
): Promise<void> {
  await requireTeam(groupId);
  if (await roleOf(groupId, uid)) throw new HttpsError('failed-precondition', 'already-member');
  const result = await addMembersByEmail(groupId, { uid: actor, name: await actorName(actor) }, [{ email }]);
  if (result.problems.length) throw new HttpsError('internal', 'Could not add them to the team.');
  if (role === 'admin') await setMemberRole(groupId, uid, 'admin');
}

// ---- Dashboard and teams (ADMIN-1 to ADMIN-3) --------------------------------

/** The platform's totals (ADMIN-1). A read, so not audited. */
export const adminDashboard = onCall(async (request) => {
  requireSuperAdmin(request);
  return dashboard();
});

/**
 * A page of teams (ADMIN-2): { rows, nextCursor }. Pass nextCursor back as
 * `cursor` for the next page; null means the end.
 */
export const adminListTeams = onCall(async (request) => {
  requireSuperAdmin(request);
  return listTeams(parse(ListTeamsInput, request.data ?? {}));
});

/** One team's detail page (ADMIN-3): the team, people, players, invites, and counts. */
export const adminGetTeam = onCall(async (request) => {
  requireSuperAdmin(request);
  return getTeam(parse(GroupInput, request.data).groupId);
});

/**
 * Records a super admin opening a team's tabs with "View team" (ADMIN-3):
 * one audit entry each time. The rules let super admins read the team
 * without joining it.
 */
export const adminOpenGroup = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const { groupId } = parse(GroupInput, request.data);
  await requireTeam(groupId);
  await audit({ actorId: actor, action: 'viewGroup', groupId, targetType: 'group', targetId: groupId });
  return { ok: true };
});

/** Suspends or unsuspends a team (ADMIN-3, SAFE-4), with an optional note for the audit log. */
export const adminSetGroupSuspended = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(SetSuspendedInput, request.data);
  const before = await setGroupSuspended(input.groupId, input.suspended);
  await audit({
    actorId: actor,
    action: input.suspended ? 'suspendGroup' : 'unsuspendGroup',
    groupId: input.groupId,
    targetType: 'group',
    targetId: input.groupId,
    before: { suspended: before },
    after: { suspended: input.suspended, note: input.note || null },
  });
  return { ok: true };
});

/** Archives (read-only) or restores any team (ADMIN-3, TEAM-9). */
export const adminArchiveGroup = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(ArchiveInput, request.data);
  await setGroupArchived(input.groupId, input.archived);
  await audit({
    actorId: actor,
    action: input.archived ? 'archiveGroup' : 'restoreGroup',
    groupId: input.groupId,
    targetType: 'group',
    targetId: input.groupId,
  });
  return { ok: true };
});

/** Permanently deletes any team once its name is typed (ADMIN-3, TEAM-9): `name-mismatch` otherwise. */
export const adminDeleteGroup = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(DeleteGroupInput, request.data);
  await deleteGroupNamed(input.groupId, input.confirmName, (before) =>
    audit({
      actorId: actor,
      action: 'deleteGroup',
      groupId: input.groupId,
      targetType: 'group',
      targetId: input.groupId,
      before,
    }),
  );
  return { ok: true };
});

// ---- Users (ADMIN-4) ---------------------------------------------------------

/** A page of people (ADMIN-4): { rows, nextCursor }; a search returns one page of matches. */
export const adminListUsers = onCall(async (request) => {
  requireSuperAdmin(request);
  return listUsers(parse(ListUsersInput, request.data ?? {}));
});

/** One person's details (ADMIN-4): profile, status, sign-in methods, teams and roles, dates. */
export const adminGetUser = onCall(async (request) => {
  requireSuperAdmin(request);
  return getUser(parse(UidInput, request.data).uid);
});

/**
 * Creates an added account (ADMIN-4, AUTH-6): a name and an email, no
 * password, and a setup email. With a team, they're added to it (as a
 * member or an admin) and the setup email names the team. An email that
 * already has an account is `already-exists` (add them to a team with
 * adminUpdateUser instead).
 */
export const adminCreateUser = onCall({ secrets: [resendApiKey] }, async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(CreateUserInput, request.data);
  if (await uidForEmail(input.email)) throw new HttpsError('already-exists', 'user-exists');
  let uid: string;
  if (input.groupId) {
    await requireTeam(input.groupId);
    // The team's flow creates the account, adds them, and sends the
    // setup email that names the team.
    const result = await addMembersByEmail(input.groupId, { uid: actor, name: await actorName(actor) }, [
      { name: input.displayName, email: input.email },
    ]);
    uid = (await uidForEmail(input.email)) ?? '';
    if (result.problems.length || !uid) throw new HttpsError('internal', 'Could not create the account.');
    if (input.role === 'admin') await setMemberRole(input.groupId, uid, 'admin');
  } else {
    uid = (await findOrProvisionUser(input.email, input.displayName)).uid;
    await sendAccountSetupEmail(input.email, await actorName(actor));
  }
  await audit({
    actorId: actor,
    action: 'createUser',
    groupId: input.groupId,
    targetType: 'user',
    targetId: uid,
    after: {
      email: input.email,
      displayName: input.displayName,
      groupId: input.groupId ?? null,
      role: input.groupId ? (input.role ?? 'member') : null,
    },
  });
  return { uid };
});

/** Renames someone and/or adds them to a team (ADMIN-4); `already-member` if they're on it. */
export const adminUpdateUser = onCall({ secrets: [resendApiKey] }, async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(UpdateUserInput, request.data);
  const before: Record<string, unknown> = {};
  const after: Record<string, unknown> = {};
  if (input.addToGroup) {
    // Checked first, so a refused add doesn't leave a half-made change.
    const email = await authEmailOf(input.uid);
    await addToTeam(input.addToGroup.groupId, input.uid, email, input.addToGroup.role, actor);
    after.addedTo = input.addToGroup;
  }
  if (input.displayName !== undefined) {
    before.displayName = await setDisplayName(input.uid, input.displayName);
    after.displayName = input.displayName;
  }
  await audit({
    actorId: actor,
    action: 'updateUser',
    groupId: input.addToGroup?.groupId,
    targetType: 'user',
    targetId: input.uid,
    before,
    after,
  });
  return { ok: true };
});

/**
 * Disables (signing them out everywhere) or re-enables an account
 * (ADMIN-4). You can't disable yourself (`cannot-disable-self`).
 */
export const adminSetUserDisabled = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(SetDisabledInput, request.data);
  if (input.disabled && input.uid === actor) throw new HttpsError('failed-precondition', 'cannot-disable-self');
  const before = await setAccountDisabled(input.uid, input.disabled);
  await audit({
    actorId: actor,
    action: input.disabled ? 'disableUser' : 'enableUser',
    targetType: 'user',
    targetId: input.uid,
    before: { status: before },
    after: { disabled: input.disabled },
  });
  return { ok: true };
});

/** Signs someone out on every device (ADMIN-4, AUTH-9). */
export const adminRevokeSessions = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const { uid } = parse(UidInput, request.data);
  await requireAccount(uid);
  await signOutEverywhere(uid);
  await audit({ actorId: actor, action: 'revokeSessions', targetType: 'user', targetId: uid });
  return { ok: true };
});

/** Emails someone a link to choose a new password (ADMIN-4, AUTH-6). The link is never returned. */
export const adminSendPasswordReset = onCall({ secrets: [resendApiKey] }, async (request) => {
  const actor = requireSuperAdmin(request);
  const { uid } = parse(UidInput, request.data);
  await sendPasswordReset(uid);
  await audit({ actorId: actor, action: 'sendPasswordReset', targetType: 'user', targetId: uid });
  return { ok: true };
});

/**
 * Deletes an account and its data as AUTH-10 does (ADMIN-4). Not your own
 * (`cannot-delete-self`; use Settings), and never the last super admin
 * (`last-super-admin`).
 */
export const adminDeleteUser = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const { uid } = parse(UidInput, request.data);
  if (uid === actor) throw new HttpsError('failed-precondition', 'cannot-delete-self');
  if (await wouldLeaveNoSuperAdmin(uid, actor)) throw new HttpsError('failed-precondition', 'last-super-admin');
  const profile = await db().collection(Collections.users).doc(uid).get();
  await audit({
    actorId: actor,
    action: 'deleteUser',
    targetType: 'user',
    targetId: uid,
    before: {
      displayName: (profile.get('displayName') as string | undefined) ?? null,
      email: (profile.get('email') as string | undefined) ?? null,
    },
  });
  await deleteAccount(uid);
  return { ok: true };
});

/**
 * Grants or revokes super admin (ADMIN-4). The last super admin can't be
 * removed (`last-super-admin`). The app force-refreshes the person's token
 * when it's the caller's own.
 */
export const adminSetSuperAdmin = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(SetSuperAdminInput, request.data);
  // The caller holds the claim, so make sure their profile says so too.
  await markSuperAdmin(actor);
  if (!input.superAdmin && (await wouldLeaveNoSuperAdmin(input.uid, actor))) {
    throw new HttpsError('failed-precondition', 'last-super-admin');
  }
  const before = await setSuperAdminClaim(input.uid, input.superAdmin);
  await audit({
    actorId: actor,
    action: input.superAdmin ? 'grantSuperAdmin' : 'revokeSuperAdmin',
    targetType: 'user',
    targetId: input.uid,
    before: { superAdmin: before },
    after: { superAdmin: input.superAdmin },
  });
  return { ok: true };
});

// ---- Reports (ADMIN-5) -------------------------------------------------------

/** A page of reports from every team with one status, newest first (ADMIN-5): { rows, nextCursor }. */
export const adminListReports = onCall(async (request) => {
  requireSuperAdmin(request);
  return listReports(parse(ListReportsInput, request.data ?? {}));
});

/**
 * Acts on a report from any team and closes it with a note (ADMIN-5,
 * SAFE-4): delete the reported message or document, remove the person from
 * the team, disable their account, suspend the team, or dismiss. The
 * action goes through its own domain; the report records it.
 */
export const adminResolveReport = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(ResolveReportInput, request.data);
  const report = await openReport(input.reportId);
  const groupId = String(report.groupId ?? '');
  const subjectId = String(report.subjectId ?? '');
  const resolution = resolutionFor(input.action, String(report.targetType));
  if (!resolution) throw new HttpsError('failed-precondition', 'nothing-to-delete');

  switch (input.action) {
    case 'deleteContent':
      if (report.targetType === 'message') {
        const message = await db().collection(Collections.messages).doc(String(report.targetId)).get();
        if (message.exists && message.get('groupId') === groupId && message.get('type') !== 'system') {
          await eraseMessage(message.id, actor, 'admin');
        }
      } else {
        await deleteDocumentOf(groupId, String(report.targetId));
      }
      break;
    case 'removeMember': {
      const role = await roleOf(groupId, subjectId);
      if (role === 'owner') throw new HttpsError('failed-precondition', 'owner');
      if (role) await removeFromTeam(groupId, subjectId, actor);
      break;
    }
    case 'disableUser':
      if (!subjectId) throw new HttpsError('failed-precondition', 'no-subject');
      if (subjectId === actor) throw new HttpsError('failed-precondition', 'cannot-disable-self');
      await setAccountDisabled(subjectId, true);
      break;
    case 'suspendTeam':
      await setGroupSuspended(groupId, true);
      break;
    case 'dismiss':
      break;
  }

  await closeReport(input.reportId, {
    status: input.action === 'dismiss' ? 'dismissed' : 'actioned',
    resolution,
    note: input.note,
    resolvedBy: actor,
  });
  await audit({
    actorId: actor,
    action: input.action === 'dismiss' ? 'dismissReport' : 'actionReport',
    groupId,
    targetType: 'report',
    targetId: input.reportId,
    before: { status: 'open', targetType: report.targetType, targetId: report.targetId, subjectId },
    after: { action: input.action, resolution, note: input.note },
  });
  return { ok: true, resolution };
});

// ---- Platform settings (ADMIN-7) ---------------------------------------------

/**
 * Saves the platform settings to config/app (ADMIN-7): who may create
 * teams and how many a day, the default storage limit, the largest upload,
 * the support email, and the announcement banner (null removes it).
 */
export const adminUpdateConfig = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(UpdateConfigInput, request.data);
  const { before, after } = await updateConfig(input);
  await audit({ actorId: actor, action: 'updateConfig', targetType: 'config', targetId: 'app', before, after });
  return { ok: true };
});
