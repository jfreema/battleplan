// Teams domain service: owns groups and groupMembers (ARCH §6.4).
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../shared/admin.js';
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
