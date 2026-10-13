// Teams domain service: owns groups and groupMembers (ARCH §6.4).
import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { HttpsError } from 'firebase-functions/v2/https';
import { randomUUID } from 'node:crypto';
import { findOrProvisionUser, sendSetupEmail } from '../accounts/service.js';
import { joinedLine, postSystemMessage } from '../chat/service.js';
import { sendEmail } from '../email/service.js';
import { addedToTeamEmail } from '../email/templates.js';
import { teamUrl } from '../links/service.js';
import { removeTeamNotifications, trySend } from '../notify/service.js';
import { removeGuardianFromTeam } from '../players/service.js';
import { db, storage } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections, Limits } from '../shared/constants.js';
import { groupMemberId } from '../shared/ids.js';
import type { Role } from '../shared/roles.js';

interface MemberRow {
  uid: string;
  role: string;
  joinedAt?: FirebaseFirestore.Timestamp;
}

/**
 * Picks who takes over a team when its owner leaves (AUTH-10): the
 * member the owner picked if they're still on the team, else the
 * longest-serving admin, else the longest-serving member, else nobody.
 */
export function nextOwner(members: MemberRow[], leavingUid: string, picked?: string): string | null {
  const others = members.filter((m) => m.uid !== leavingUid);
  if (picked && others.some((m) => m.uid === picked)) return picked;
  const byTenure = (a: MemberRow, b: MemberRow) =>
    (a.joinedAt?.toMillis() ?? 0) - (b.joinedAt?.toMillis() ?? 0);
  const admins = others.filter((m) => m.role === 'admin').sort(byTenure);
  if (admins.length) return admins[0].uid;
  const rest = others.sort(byTenure);
  return rest.length ? rest[0].uid : null;
}

/**
 * Removes a deleted account from every team: owned teams pass to the next
 * owner (or are archived when nobody is left), then all memberships go.
 * [newOwners] maps a team ID to the member its owner picked (AUTH-10).
 */
export async function removeAccountFromTeams(uid: string, newOwners: Record<string, string> = {}): Promise<void> {
  const memberships = await db()
    .collection(Collections.groupMembers)
    .where('uid', '==', uid)
    .get();

  for (const m of memberships.docs) {
    const groupId = m.get('groupId') as string;
    const groupRef = db().collection(Collections.groups).doc(groupId);
    if (m.get('role') === 'owner') {
      const members = await db()
        .collection(Collections.groupMembers)
        .where('groupId', '==', groupId)
        .limit(500)
        .get();
      const heir = nextOwner(
        members.docs.map((d) => d.data() as MemberRow),
        uid,
        newOwners[groupId],
      );
      if (heir) {
        await db().batch()
          .update(groupRef, { ownerId: heir, updatedAt: FieldValue.serverTimestamp() })
          .update(db().collection(Collections.groupMembers).doc(groupMemberId(groupId, heir)), { role: 'owner' })
          .commit();
      } else {
        await groupRef.update({ archivedAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
      }
    }
    await m.ref.delete();
    // Counts are recomputed, never incremented (D12).
    const count = await db().collection(Collections.groupMembers).where('groupId', '==', groupId).count().get();
    await groupRef.update({ memberCount: count.data().count }).catch(() => undefined);
  }
}


/**
 * Copies a person's name and photo onto their memberships, the cache the
 * roster and message author snapshots read (ARCH §6.2 `groupMembers`).
 */
export async function updateMemberSnapshots(
  uid: string,
  displayName: string,
  photoPath: string | null,
): Promise<void> {
  const memberships = await db()
    .collection(Collections.groupMembers)
    .where('uid', '==', uid)
    .limit(100)
    .get();
  if (memberships.empty) return;
  const batch = db().batch();
  memberships.docs.forEach((d) => batch.update(d.ref, { displayName, photoPath }));
  await batch.commit();
}

export interface NewGroup {
  name: string;
  sport: string;
  teamType: 'adult' | 'youth';
  color?: string;
  timeZone: string;
  description?: string;
}

/** Defaults for a new team's settings (TEAM-5). */
export const DEFAULT_SETTINGS = {
  membersCanCreateEvents: false,
  membersCanCreatePolls: true,
  membersCanUploadDocs: true,
  membersCanInvite: true,
  allowMaybe: true,
  defaultReminderOffsets: [1440],
};

/**
 * Creates a team with its creator as owner (TEAM-1). Callers check who may
 * create teams; this only writes the group and the owner's membership.
 */
export async function createGroup(
  uid: string,
  owner: { displayName: string; photoPath: string | null },
  input: NewGroup,
  quotaMb: number,
): Promise<string> {
  const ref = db().collection(Collections.groups).doc();
  const now = FieldValue.serverTimestamp();
  const name = input.name.trim();
  await db()
    .batch()
    .set(ref, {
      name,
      nameLower: name.toLowerCase(),
      description: input.description?.trim() ?? '',
      photoPath: null,
      color: input.color ?? null,
      sport: input.sport,
      teamType: input.teamType,
      ownerId: uid,
      createdBy: uid,
      timeZone: input.timeZone,
      settings: DEFAULT_SETTINGS,
      memberCount: 1,
      playerCount: 0,
      lastMessageAt: null,
      lastMessagePreview: null,
      // Every team gets the same limit (STORE-1); only adminSetGroupQuota
      // changes it (STORE-6).
      storageBytes: 0,
      storageQuotaBytes: quotaMb * 1024 * 1024,
      storageAlert: 'none',
      archivedAt: null,
      suspendedAt: null,
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    })
    .set(db().collection(Collections.groupMembers).doc(groupMemberId(ref.id, uid)), {
      groupId: ref.id,
      uid,
      role: 'owner',
      title: null,
      displayName: owner.displayName,
      photoPath: owner.photoPath,
      playerSummary: null,
      notificationLevel: 'all',
      mutedUntil: null,
      lastReadAt: now,
      lastPostedAt: null,
      joinedAt: now,
      addedBy: uid,
    })
    .commit();
  return ref.id;
}

/** Who may change whom (SPEC §3): admins promote; only the owner or a super admin demotes. */
export function canChangeRole(
  actor: 'owner' | 'admin' | 'superAdmin',
  targetRole: 'owner' | 'admin' | 'member',
  newRole: 'admin' | 'member',
): boolean {
  if (targetRole === 'owner') return false; // ownership moves only by transfer
  if (newRole === 'admin') return true;
  return actor === 'owner' || actor === 'superAdmin';
}

/** Who may remove whom (SPEC §3): admins remove non-admins; the owner and super admins remove anyone but the owner. */
export function canRemove(
  actor: 'owner' | 'admin' | 'superAdmin',
  targetRole: 'owner' | 'admin' | 'member',
): boolean {
  if (targetRole === 'owner') return false;
  if (targetRole === 'admin') return actor === 'owner' || actor === 'superAdmin';
  return true;
}

/** Recomputes a team's member count (D12: recompute, never increment). */
export async function refreshMemberCount(groupId: string): Promise<void> {
  const count = await db().collection(Collections.groupMembers).where('groupId', '==', groupId).count().get();
  await db().collection(Collections.groups).doc(groupId).update({ memberCount: count.data().count });
}

/** Clears a former member's notification-center items for the team; a failure only logs. */
export async function clearTeamNotifications(groupId: string, uid: string): Promise<void> {
  await removeTeamNotifications(groupId, uid).catch((e) =>
    logger.warn('team_notifications_cleanup_failed', { groupId, uid, error: String(e) }),
  );
}

/**
 * Takes someone off a team (TEAM-3, SAFE-4): the membership, their
 * guardian links and requests there, the member count, "Sam was removed" in chat, and their center items for the team.
 * Callers check who may remove whom (canRemove). Returns the role they had,
 * or null when they weren't on the team.
 */
export async function removeFromTeam(groupId: string, uid: string, actorUid: string): Promise<Role | null> {
  const ref = db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid));
  const target = await ref.get();
  if (!target.exists) return null;
  await ref.delete();
  await removeGuardianFromTeam(groupId, uid);
  await refreshMemberCount(groupId);
  const name = (target.get('displayName') as string) || 'Someone';
  await postSystemMessage(groupId, 'removed', `${name} was removed`, actorUid, uid);
  await clearTeamNotifications(groupId, uid);
  return target.get('role') as Role;
}

/**
 * Changes a member's role (TEAM-4) for a caller that already checked it may
 * (an admin panel add, ADMIN-4). Ownership moves only by transfer.
 */
export async function setMemberRole(groupId: string, uid: string, role: 'admin' | 'member'): Promise<void> {
  const ref = db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid));
  await db().runTransaction(async (tx) => {
    const member = await tx.get(ref);
    if (!member.exists) throw new HttpsError('not-found', 'Not a member.');
    if (member.get('role') === 'owner') throw new HttpsError('failed-precondition', 'owner');
    tx.update(ref, { role });
  });
}

/** The team's document, or `not-found`. */
async function groupOrThrow(groupId: string): Promise<FirebaseFirestore.DocumentSnapshot> {
  const group = await db().collection(Collections.groups).doc(groupId).get();
  if (!group.exists) throw new HttpsError('not-found', 'No such team.');
  return group;
}

/**
 * Archives (read-only) or restores a team (TEAM-9). Archiving a team that's
 * already archived keeps the date it was first archived. Returns whether it
 * was archived before, and since when (ISO 8601), for the audit log
 * (ADMIN-6).
 */
export async function setGroupArchived(
  groupId: string,
  archived: boolean,
): Promise<{ archived: boolean; archivedAt: string | null }> {
  const ref = db().collection(Collections.groups).doc(groupId);
  return db().runTransaction(async (tx) => {
    const group = await tx.get(ref);
    if (!group.exists) throw new HttpsError('not-found', 'No such team.');
    const was = group.get('archivedAt') as FirebaseFirestore.Timestamp | null | undefined;
    tx.update(ref, {
      archivedAt: archived ? (was ?? FieldValue.serverTimestamp()) : null,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { archived: was != null, archivedAt: was ? was.toDate().toISOString() : null };
  });
}

/** What a super admin may change on a team's profile and settings (ADMIN-3); the same fields team admins write (TEAM-5, CHAT-18). */
export interface GroupEdit {
  name?: string;
  description?: string;
  color?: string | null;
  sport?: string;
  timeZone?: string;
  settings?: Record<string, unknown>;
  chatTheme?: { bubbleColor?: string | null; background?: string; backgroundPath?: string | null };
  photoPath?: string | null;
  backgroundPath?: string | null;
}

/**
 * Changes a team's profile and settings for a super admin who isn't on it
 * (ADMIN-3); its admins write the same fields directly under the rules'
 * validGroup. Callers validate [edit] the same way. Settings merge into the
 * team's; a background path replaces the chat look's. An archived team is
 * read-only (`archived`, TEAM-9). Returns each changed field before and
 * after, for the audit log.
 */
export async function updateGroupProfile(
  groupId: string,
  edit: GroupEdit,
): Promise<{ before: Record<string, unknown>; after: Record<string, unknown> }> {
  const ref = db().collection(Collections.groups).doc(groupId);
  return db().runTransaction(async (tx) => {
    const group = await tx.get(ref);
    if (!group.exists) throw new HttpsError('not-found', 'No such team.');
    if (group.get('archivedAt') != null) throw new HttpsError('failed-precondition', 'archived');
    const after: Record<string, unknown> = {};
    for (const key of ['name', 'description', 'color', 'sport', 'timeZone', 'photoPath'] as const) {
      if (edit[key] !== undefined) after[key] = edit[key];
    }
    if (edit.settings) {
      after.settings = { ...((group.get('settings') as Record<string, unknown> | undefined) ?? {}), ...edit.settings };
    }
    if (edit.chatTheme || edit.backgroundPath !== undefined) {
      const theme: Record<string, unknown> = {
        ...(edit.chatTheme ?? (group.get('chatTheme') as Record<string, unknown> | undefined) ?? {}),
      };
      if (edit.backgroundPath !== undefined) theme.backgroundPath = edit.backgroundPath;
      after.chatTheme = theme;
    }
    const before = Object.fromEntries(Object.keys(after).map((k) => [k, group.get(k) ?? null]));
    tx.update(ref, {
      ...after,
      ...(edit.name !== undefined ? { nameLower: edit.name.toLowerCase() } : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { before, after };
  });
}

/**
 * Suspends or unsuspends a team (ADMIN-3, SAFE-4). While suspendedAt is set
 * the rules' isMember fails for everyone on it, so members can't read or
 * write anything and the app shows "This team has been suspended"; only
 * super admins still see it. Returns whether it was suspended before.
 */
export async function setGroupSuspended(groupId: string, suspended: boolean): Promise<boolean> {
  const before = (await groupOrThrow(groupId)).get('suspendedAt') != null;
  await db()
    .collection(Collections.groups)
    .doc(groupId)
    .update({
      suspendedAt: suspended ? FieldValue.serverTimestamp() : null,
      updatedAt: FieldValue.serverTimestamp(),
    });
  return before;
}

/**
 * Deletes a team once [confirmName] matches its name (TEAM-9, ADMIN-3), or
 * throws `name-mismatch`. [beforeDelete] runs first with what the audit log
 * keeps, so the entry is written even if the delete is cut short and
 * retried. A team that's already gone is left alone.
 */
export async function deleteGroupNamed(
  groupId: string,
  confirmName: string,
  beforeDelete: (before: { name: string; memberCount: number }) => Promise<void>,
): Promise<void> {
  const group = await db().collection(Collections.groups).doc(groupId).get();
  if (!group.exists) return;
  const name = (group.get('name') as string | undefined) ?? '';
  if (confirmName.trim() !== name.trim()) {
    throw new HttpsError('invalid-argument', 'name-mismatch');
  }
  await beforeDelete({ name, memberCount: (group.get('memberCount') as number | undefined) ?? 0 });
  await deleteGroupData(groupId);
}

/** Every team-owned collection, for deleting a team (TEAM-9). */
const TEAM_COLLECTIONS = [
  Collections.messages,
  Collections.polls,
  Collections.pollVotes,
  Collections.rsvps,
  Collections.events,
  Collections.eventSeries,
  Collections.groupDocuments,
  Collections.playerGuardians,
  Collections.guardianRequests,
  Collections.players,
  Collections.invites,
  Collections.notifications,
  Collections.reports,
  Collections.groupMembers,
];

/**
 * Permanently deletes a team: every document that carries its groupId, its
 * files in Storage, and the team itself (TEAM-9). Safe to retry.
 */
export async function deleteGroupData(groupId: string): Promise<void> {
  for (const collection of TEAM_COLLECTIONS) {
    await forEachPage(db().collection(collection).where('groupId', '==', groupId), (b, d) => b.delete(d.ref));
  }
  await storage().bucket().deleteFiles({ prefix: `groups/${groupId}/` }).catch(() => undefined);
  await db().collection(Collections.groups).doc(groupId).delete();
}

export interface AddedPerson {
  name: string;
  email: string;
}

export interface AddMembersResult {
  added: number;
  invited: number;
  alreadyMembers: number;
  /** Who was added (had an account) and who was invited (got one), for the results screen (TEAM-7). */
  addedPeople: AddedPerson[];
  invitedPeople: AddedPerson[];
  /** Emails that couldn't be added; "email (too-many-teams)" when the person is on 100 teams (TEAM-2). */
  problems: string[];
}

/**
 * Tells people they were added to a team (NOTIF-2): "Alex added you to
 * Thunder". People who haven't signed in yet get the center item and see it
 * once they do; they have no devices to push to.
 */
export async function notifyAddedToTeam(
  groupId: string,
  teamName: string,
  actor: { uid: string; name: string },
  uids: string[],
): Promise<void> {
  if (!uids.length) return;
  await trySend({
    kind: 'addedToTeam',
    groupId,
    recipients: { uids },
    actor,
    target: { type: 'group', id: groupId },
    route: `/g/${groupId}/chat`,
    params: { actorName: actor.name },
    body: `${actor.name} added you to ${teamName}`,
    // Callables aren't retried; someone removed and added again is told again.
    dedupeKey: randomUUID(),
    teamName,
  });
}

/**
 * Adds people to a team by email (TEAM-7): people with accounts are added
 * and told; new emails get an added account and a setup email (AUTH-6).
 */
export async function addMembersByEmail(
  groupId: string,
  actor: { uid: string; name: string },
  entries: { name?: string | null; email: string }[],
): Promise<AddMembersResult> {
  const result: AddMembersResult = {
    added: 0,
    invited: 0,
    alreadyMembers: 0,
    addedPeople: [],
    invitedPeople: [],
    problems: [],
  };
  const group = await db().collection(Collections.groups).doc(groupId).get();
  const teamName = group.get('name') as string;
  const addedUids: string[] = [];
  for (const entry of entries) {
    try {
      const user = await findOrProvisionUser(entry.email, entry.name ?? null);
      const ref = db().collection(Collections.groupMembers).doc(groupMemberId(groupId, user.uid));
      if ((await ref.get()).exists) {
        result.alreadyMembers++;
        continue;
      }
      // A person can be on up to 100 teams (TEAM-2).
      const teams = await db().collection(Collections.groupMembers).where('uid', '==', user.uid).count().get();
      if (teams.data().count >= Limits.groupsPerUserMax) {
        result.problems.push(`${entry.email} (too-many-teams)`);
        continue;
      }
      const now = FieldValue.serverTimestamp();
      await ref.set({
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
        addedBy: actor.uid,
        pending: user.provisioned,
      });
      addedUids.push(user.uid);
      const person = { name: user.displayName, email: entry.email.trim().toLowerCase() };
      if (user.provisioned) {
        await sendSetupEmail(entry.email, teamName, actor.name);
        result.invited++;
        result.invitedPeople.push(person);
      } else {
        // An added account joins when it first signs in (clearPendingMemberships).
        await postSystemMessage(groupId, 'joined', joinedLine(user.displayName), user.uid);
        await sendEmail(addedToTeamEmail(entry.email, teamName, actor.name, teamUrl(groupId)));
        result.added++;
        result.addedPeople.push(person);
      }
    } catch {
      result.problems.push(entry.email);
    }
  }
  await refreshMemberCount(groupId);
  await notifyAddedToTeam(groupId, teamName, actor, addedUids);
  return result;
}
