// Teams domain service: owns groups and groupMembers (ARCH §6.4).
import { FieldValue } from 'firebase-admin/firestore';
import { findOrProvisionUser, sendSetupEmail } from '../accounts/service.js';
import { sendEmail } from '../email/service.js';
import { addedToTeamEmail } from '../email/templates.js';
import { teamUrl } from '../links/service.js';
import { db, storage } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections } from '../shared/constants.js';

import { groupMemberId } from '../shared/ids.js';

interface MemberRow {
  uid: string;
  role: string;
  joinedAt?: FirebaseFirestore.Timestamp;
}

/**
 * Picks who takes over a team when its owner leaves (AUTH-10): the
 * longest-serving admin, else the longest-serving member, else nobody.
 */
export function nextOwner(members: MemberRow[], leavingUid: string): string | null {
  const others = members.filter((m) => m.uid !== leavingUid);
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
 */
export async function removeAccountFromTeams(uid: string): Promise<void> {
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
  quotaGb: number,
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
      storageBytes: 0,
      storageQuotaBytes: quotaGb * 1024 ** 3,
      // Every team starts on Free (PLAN-1); licenses move it to Plus.
      plan: { tier: 'free', endsAt: null, licenseId: null, holderId: null },
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

export interface AddMembersResult {
  added: number;
  invited: number;
  alreadyMembers: number;
  problems: string[];
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
  const result: AddMembersResult = { added: 0, invited: 0, alreadyMembers: 0, problems: [] };
  const group = await db().collection(Collections.groups).doc(groupId).get();
  const teamName = group.get('name') as string;
  for (const entry of entries) {
    try {
      const user = await findOrProvisionUser(entry.email, entry.name ?? null);
      const ref = db().collection(Collections.groupMembers).doc(groupMemberId(groupId, user.uid));
      if ((await ref.get()).exists) {
        result.alreadyMembers++;
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
      if (user.provisioned) {
        await sendSetupEmail(entry.email, teamName, actor.name);
        result.invited++;
      } else {
        await sendEmail(addedToTeamEmail(entry.email, teamName, actor.name, teamUrl(groupId)));
        result.added++;
      }
    } catch {
      result.problems.push(entry.email);
    }
  }
  await refreshMemberCount(groupId);
  return result;
}
