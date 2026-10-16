// Direct conversations (CHAT-19): two people who share a team, talking one
// to one. Each is a group of kind 'direct' (ARCH §6.2) with a membership
// for each of the two (role 'participant'), so the team chat's messages,
// rules, photos, read markers, and unread counts carry over unchanged.
// Its ID comes from the pair, so both people always land in the same one.
// Nothing that lists teams shows it: team lists ask for team roles.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { createHash } from 'node:crypto';
import { DELETED_USER_NAME } from '../chat/service.js';
import { db } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections, Limits } from '../shared/constants.js';
import { groupMemberId } from '../shared/ids.js';
import { TEAM_ROLES } from '../shared/roles.js';

/** A direct conversation's people: never a team's owner, admin, or member. */
export const PARTICIPANT = 'participant';

/**
 * The pair's conversation ID: the same whoever opens it, 34 characters
 * that no auto ID matches, and never an underscore, so composite IDs built
 * on it stay unambiguous (ARCH §6.2 rule 4).
 */
export function directChatId(a: string, b: string): string {
  const [x, y] = [a, b].sort();
  return `dm${createHash('sha256').update(`${x}\n${y}`).digest('hex').slice(0, 32)}`;
}

/** Whether a groups document is a direct conversation rather than a team. */
export function isDirect(group: FirebaseFirestore.DocumentData | undefined): boolean {
  return group?.kind === 'direct';
}

/**
 * Its settings: nothing a team turns on. No polls, events, or documents,
 * and the language filter on, as every team starts (SAFE-7).
 */
export const DIRECT_SETTINGS = {
  membersCanCreateEvents: false,
  membersCanCreatePolls: false,
  membersCanUploadDocs: false,
  membersCanInvite: false,
  allowMaybe: false,
  membersCanSeePeople: true,
  filterLanguage: true,
  defaultReminderOffsets: [],
};

/** What a conversation shows of each of its people (cache ← users). */
export interface DirectPerson {
  name: string;
  photoPath: string | null;
}

function personOf(profile: FirebaseFirestore.DocumentSnapshot): DirectPerson {
  return {
    name: String(profile.get('displayName') ?? '').trim(),
    photoPath: (profile.get('photoPath') as string | null | undefined) ?? null,
  };
}

/** The two people's team IDs in common, open ones only (not suspended). */
export async function sharedTeams(a: string, b: string): Promise<string[]> {
  const mine = await db()
    .collection(Collections.groupMembers)
    .where('uid', '==', a)
    .where('role', 'in', [...TEAM_ROLES])
    .limit(Limits.groupsPerUserMax)
    .select('groupId')
    .get();
  const ids = mine.docs.map((d) => String(d.get('groupId')));
  if (!ids.length) return [];
  const theirs = await db().getAll(
    ...ids.map((g) => db().collection(Collections.groupMembers).doc(groupMemberId(g, b))),
    { fieldMask: ['role'] },
  );
  const both = ids.filter((_, i) => theirs[i].exists && TEAM_ROLES.includes(theirs[i].get('role')));
  if (!both.length) return [];
  const teams = await db().getAll(
    ...both.map((g) => db().collection(Collections.groups).doc(g)),
    { fieldMask: ['suspendedAt', 'kind'] },
  );
  return both.filter((_, i) => teams[i].exists && teams[i].get('suspendedAt') == null && !isDirect(teams[i].data()));
}

export interface OpenedChat {
  groupId: string;
  /** True when this call made it; the caller counts it toward the day's limit. */
  created: boolean;
}

/**
 * Opens the conversation between [uid] and [otherUid] (CHAT-19), making it
 * the first time. Someone new needs a team in common that isn't suspended,
 * an account that's joined (not one an admin added who hasn't signed in
 * yet), and not to be someone the caller blocked. Being blocked by them
 * isn't refused, since nobody is told they're blocked (SAFE-2): their
 * messages just never reach the person who blocked them. A conversation
 * that's already there opens whatever the teams are now; one whose other
 * person deleted their account is read-only and isn't reopened.
 * [beforeCreate] runs just before a new one is written, for the rate limit.
 */
export async function openDirectChat(
  uid: string,
  otherUid: string,
  beforeCreate: () => Promise<void> = async () => undefined,
): Promise<OpenedChat> {
  if (uid === otherUid) throw new HttpsError('invalid-argument', 'self');
  const groupId = directChatId(uid, otherUid);
  const groupRef = db().collection(Collections.groups).doc(groupId);
  const [me, them, existing] = await Promise.all([
    db().collection(Collections.users).doc(uid).get(),
    db().collection(Collections.users).doc(otherUid).get(),
    groupRef.get(),
  ]);
  if (!me.exists) throw new HttpsError('failed-precondition', 'no-profile');
  if (!them.exists || them.get('status') !== 'active') {
    throw new HttpsError('failed-precondition', 'not-available');
  }
  const blocked = await db().collection(Collections.userBlocks).doc(`${uid}_${otherUid}`).get();
  if (existing.exists) {
    if (existing.get('archivedAt') != null) throw new HttpsError('failed-precondition', 'not-available');
    // A membership lost to an earlier failure comes back.
    await ensureParticipants(groupId, uid, otherUid, me, them);
    return { groupId, created: false };
  }
  if (blocked.exists) throw new HttpsError('failed-precondition', 'blocked');
  if (!(await sharedTeams(uid, otherUid)).length) {
    throw new HttpsError('permission-denied', 'no-shared-team');
  }
  await beforeCreate();
  const now = FieldValue.serverTimestamp();
  const created = await db().runTransaction(async (tx) => {
    // Both people opening it at once: the second finds the first's.
    if ((await tx.get(groupRef)).exists) return false;
    tx.create(groupRef, {
      kind: 'direct',
      uids: [uid, otherUid].sort(),
      people: { [uid]: personOf(me), [otherUid]: personOf(them) },
      name: '',
      nameLower: '',
      description: '',
      photoPath: null,
      color: null,
      sport: 'other',
      ownerId: null,
      createdBy: uid,
      timeZone: 'UTC',
      settings: DIRECT_SETTINGS,
      memberCount: 2,
      playerCount: 0,
      lastMessageAt: null,
      lastMessagePreview: null,
      // Its own limit, which the platform default never changes (STORE-6).
      storageBytes: 0,
      storageQuotaBytes: Limits.directChatStorageQuotaMb * 1024 * 1024,
      storageQuotaCustom: true,
      storageAlert: 'none',
      archivedAt: null,
      suspendedAt: null,
      status: 'active',
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    });
    tx.create(participantRef(groupId, uid), participantDoc(groupId, uid, otherUid, me, uid));
    tx.create(participantRef(groupId, otherUid), participantDoc(groupId, otherUid, uid, them, uid));
    return true;
  });
  return { groupId, created };
}

function participantRef(groupId: string, uid: string) {
  return db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid));
}

/** One person's membership of a conversation: their read marker, mute, and send limit. */
function participantDoc(
  groupId: string,
  uid: string,
  otherUid: string,
  profile: FirebaseFirestore.DocumentSnapshot,
  addedBy: string,
): Record<string, unknown> {
  const person = personOf(profile);
  return {
    groupId,
    uid,
    otherUid,
    role: PARTICIPANT,
    title: null,
    // The author snapshot each message must match (ARCH §6.3).
    displayName: person.name,
    photoPath: person.photoPath,
    playerSummary: null,
    notificationLevel: 'all',
    mutedUntil: null,
    lastReadAt: null,
    lastPostedAt: null,
    joinedAt: FieldValue.serverTimestamp(),
    addedBy,
  };
}

async function ensureParticipants(
  groupId: string,
  uid: string,
  otherUid: string,
  me: FirebaseFirestore.DocumentSnapshot,
  them: FirebaseFirestore.DocumentSnapshot,
): Promise<void> {
  const [mine, theirs] = await db().getAll(participantRef(groupId, uid), participantRef(groupId, otherUid));
  if (mine.exists && theirs.exists) return;
  const batch = db().batch();
  if (!mine.exists) batch.set(mine.ref, participantDoc(groupId, uid, otherUid, me, uid));
  if (!theirs.exists) batch.set(theirs.ref, participantDoc(groupId, otherUid, uid, them, uid));
  await batch.commit();
}

/**
 * After a message in a conversation: each person's copy of when it last
 * had one, which orders their Messages list (ARCH §6.2 `groupMembers`),
 * and the author's read marker, since sending marks a chat read (CHAT-9),
 * so their own message never counts as unread, even when they leave
 * before the app marks it. Never moves backward, since triggers can
 * arrive late or twice.
 */
export async function touchParticipants(groupId: string, at: Timestamp, authorId: string): Promise<void> {
  const people = await db()
    .collection(Collections.groupMembers)
    .where('groupId', '==', groupId)
    .limit(2)
    .get();
  const batch = db().batch();
  let writes = 0;
  const behind = (field: string, p: FirebaseFirestore.QueryDocumentSnapshot) => {
    const current = p.get(field) as Timestamp | undefined | null;
    return !current || current.toMillis() < at.toMillis();
  };
  for (const p of people.docs) {
    const update: Record<string, Timestamp> = {};
    if (behind('lastMessageAt', p)) update.lastMessageAt = at;
    if (p.get('uid') === authorId && behind('lastReadAt', p)) update.lastReadAt = at;
    if (!Object.keys(update).length) continue;
    batch.update(p.ref, update);
    writes++;
  }
  if (writes) await batch.commit();
}

/**
 * A renamed person, or a new photo, on the conversations they're in: what
 * the other person's Messages list and header show (`groups.people`).
 */
export async function updateDirectPeople(uid: string, person: DirectPerson): Promise<void> {
  await forEachPage(
    db().collection(Collections.groupMembers).where('uid', '==', uid).where('role', '==', PARTICIPANT),
    (batch, m) => batch.update(db().collection(Collections.groups).doc(String(m.get('groupId'))), {
      [`people.${uid}`]: person,
    }),
  );
}

/**
 * A deleted account leaves its conversations (AUTH-10). The other person
 * keeps theirs, read-only, with the messages from "Deleted user"; a
 * conversation nobody is left in is deleted with everything in it.
 * [deleteConversation] deletes one (deleteGroupData, which owns that).
 */
export async function leaveDirectChats(
  uid: string,
  deleteConversation: (groupId: string) => Promise<void>,
): Promise<void> {
  const mine = await db()
    .collection(Collections.groupMembers)
    .where('uid', '==', uid)
    .where('role', '==', PARTICIPANT)
    .get();
  for (const m of mine.docs) {
    const groupId = String(m.get('groupId'));
    await m.ref.delete();
    const left = await db().collection(Collections.groupMembers).where('groupId', '==', groupId).count().get();
    if (left.data().count === 0) {
      await deleteConversation(groupId);
      continue;
    }
    await db()
      .collection(Collections.groups)
      .doc(groupId)
      .update({
        [`people.${uid}`]: { name: DELETED_USER_NAME, photoPath: null },
        memberCount: left.data().count,
        archivedAt: FieldValue.serverTimestamp(),
        status: 'archived',
        updatedAt: FieldValue.serverTimestamp(),
      })
      .catch(() => undefined);
  }
}
