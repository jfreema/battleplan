// Thin entry points for the God admin panel (SPEC §6.11, ARCH §6.4). Every
// callable checks the superAdmin claim first, and every action (not the
// reads) writes an audit entry (ADMIN-8). Nobody's password is ever set or
// returned: admins send setup and reset emails only (AUTH-6).
import { HttpsError } from 'firebase-functions/v2/https';
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
import { updatePlayerProfile } from '../players/service.js';
import { closeReport, openReport, reopenReport } from '../safety/service.js';
import { auth, db, storage } from '../shared/admin.js';
import { onCall } from '../shared/callable.js';
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
  updateGroupProfile,
} from '../teams/service.js';
import {
  ArchiveInput,
  CreateUserInput,
  DeleteGroupInput,
  GroupInput,
  ListReportsInput,
  ListTeamsInput,
  ListUsersInput,
  type ReportAction,
  resolutionFor,
  ResolveReportInput,
  SetDisabledInput,
  SetSuperAdminInput,
  SetSuspendedInput,
  plain,
  UidInput,
  UpdateConfigInput,
  UpdateGroupInput,
  UpdatePlayerInput,
  UpdateUserInput,
} from './inputs.js';
import {
  dashboard,
  getTeam,
  getUser,
  listReports,
  listTeams,
  listUsers,
  requireCurrentSuperAdmin,
  updateConfig,
  withSuperAdminLock,
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

/**
 * Disables [uid]'s account (signing them out everywhere) unless that would
 * leave no super admin who can sign in (`last-super-admin`, ADMIN-4).
 * Returns their status before.
 */
async function disableAccount(actor: string, uid: string): Promise<string> {
  return withSuperAdminLock(actor, async () => {
    await requireCurrentSuperAdmin(actor);
    if (await wouldLeaveNoSuperAdmin(uid)) throw new HttpsError('failed-precondition', 'last-super-admin');
    return setAccountDisabled(uid, true);
  });
}

/** Throws `invalid-argument` unless each of [paths] is a file in Storage (an uploaded logo or background). */
async function requireFiles(...paths: (string | null | undefined)[]): Promise<void> {
  for (const path of paths) {
    if (path && !(await storage().bucket().file(path).exists())[0]) {
      throw new HttpsError('invalid-argument', 'no-such-file');
    }
  }
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
  const before = await setGroupArchived(input.groupId, input.archived);
  await audit({
    actorId: actor,
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
 * Changes the profile and settings of a team the super admin isn't on
 * (ADMIN-3): any of name, description, color, sport, timeZone, settings
 * (merged), chatTheme, photoPath, and backgroundPath (the chat look's
 * photo), validated as the rules validate its admins' writes. A new logo or
 * background is uploaded first; its path must name a file there
 * (`no-such-file`). An archived team is `archived`. Audited with each
 * changed field before and after.
 */
export const adminUpdateGroup = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const { groupId, ...edit } = parse(UpdateGroupInput, request.data);
  await requireFiles(edit.photoPath, edit.backgroundPath, edit.chatTheme?.backgroundPath);
  const { before, after } = await updateGroupProfile(groupId, edit);
  await audit({
    actorId: actor,
    action: 'updateGroup',
    groupId,
    targetType: 'group',
    targetId: groupId,
    before: plain(before) as Record<string, unknown>,
    after: plain(after) as Record<string, unknown>,
  });
  return { ok: true };
});

/**
 * Changes a player's name, number, or position on a team the super admin
 * isn't on (ADMIN-3, PLAYER-10). A blank number or position clears it.
 * Audited with each changed field before and after.
 */
export const adminUpdatePlayer = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const { playerId, ...edit } = parse(UpdatePlayerInput, request.data);
  const { groupId, before, after } = await updatePlayerProfile(playerId, edit);
  await audit({
    actorId: actor,
    action: 'updatePlayer',
    groupId,
    targetType: 'player',
    targetId: playerId,
    before,
    after,
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
 * (ADMIN-4). You can't disable yourself (`cannot-disable-self`), nor the
 * last super admin who can sign in (`last-super-admin`).
 */
export const adminSetUserDisabled = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(SetDisabledInput, request.data);
  if (input.disabled && input.uid === actor) throw new HttpsError('failed-precondition', 'cannot-disable-self');
  const before = input.disabled
    ? await disableAccount(actor, input.uid)
    : await setAccountDisabled(input.uid, false);
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
  // Their super admin goes first, under the lock, so the check and the
  // change happen together; the slow data deletion runs after.
  await withSuperAdminLock(actor, async () => {
    await requireCurrentSuperAdmin(actor);
    if (await wouldLeaveNoSuperAdmin(uid)) throw new HttpsError('failed-precondition', 'last-super-admin');
    const user = await auth().getUser(uid).catch(() => undefined);
    if (user?.customClaims?.superAdmin === true) await setSuperAdminClaim(uid, false);
  });
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
 * Grants or revokes super admin (ADMIN-4). The caller's claim is checked
 * in Auth too, as a revoked super admin's token keeps it for up to an hour
 * (`permission-denied`). The last super admin who can sign in can't be
 * removed (`last-super-admin`); changes happen one at a time, so two
 * super admins stepping down together can't both go. The app
 * force-refreshes the person's token when it's the caller's own.
 */
export const adminSetSuperAdmin = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(SetSuperAdminInput, request.data);
  const before = await withSuperAdminLock(actor, async () => {
    await requireCurrentSuperAdmin(actor);
    if (!input.superAdmin && (await wouldLeaveNoSuperAdmin(input.uid))) {
      throw new HttpsError('failed-precondition', 'last-super-admin');
    }
    return setSuperAdminClaim(input.uid, input.superAdmin);
  });
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
 * report is closed first, in a transaction, so a second resolve is refused
 * (`already-resolved`) before it can act; if the action then fails, the
 * report goes back to open. The action goes through its own domain; the
 * report records it. A refused or failed attempt is audited too
 * (resolveReportRefused, with why).
 */
export const adminResolveReport = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(ResolveReportInput, request.data);
  try {
    return await resolveReport(actor, input);
  } catch (e) {
    await audit({
      actorId: actor,
      action: 'resolveReportRefused',
      targetType: 'report',
      targetId: input.reportId,
      after: { action: input.action, note: input.note, refused: e instanceof HttpsError ? e.message : 'error' },
    });
    throw e;
  }
});

async function resolveReport(
  actor: string,
  input: { reportId: string; action: ReportAction; note: string },
): Promise<{ ok: true; resolution: string }> {
  // A quick refusal for a report that's gone or closed; closeReport makes
  // the same check in its transaction.
  const report = await openReport(input.reportId);
  const groupId = String(report.groupId ?? '');
  const subjectId = String(report.subjectId ?? '');
  const resolution = resolutionFor(input.action, String(report.targetType));
  if (!resolution) throw new HttpsError('failed-precondition', 'nothing-to-delete');
  if (input.action === 'disableUser') {
    if (!subjectId) throw new HttpsError('failed-precondition', 'no-subject');
    if (subjectId === actor) throw new HttpsError('failed-precondition', 'cannot-disable-self');
  }

  // Claim it: only one resolve gets past this.
  await closeReport(input.reportId, {
    status: input.action === 'dismiss' ? 'dismissed' : 'actioned',
    resolution,
    note: input.note,
    resolvedBy: actor,
  });
  try {
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
        await disableAccount(actor, subjectId);
        break;
      case 'suspendTeam':
        await setGroupSuspended(groupId, true);
        break;
      case 'dismiss':
        break;
    }
  } catch (e) {
    await reopenReport(input.reportId, actor);
    throw e;
  }

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
}

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
