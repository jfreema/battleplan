// Invites domain service: owns invites (ARCH §6.4, §6.6).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { joinUrl } from '../links/service.js';
import { groupMemberId } from '../shared/ids.js';
import { formatCode, newInviteCode } from './codes.js';

export interface LinkOptions {
  expiresInDays?: 1 | 7 | 30 | null;
  maxUses?: number | null;
}

export interface TeamLink {
  code: string;
  display: string;
  url: string;
  expiresAt: string | null;
  maxUses: number | null;
  useCount: number;
}

function toTeamLink(code: string, d: FirebaseFirestore.DocumentData): TeamLink {
  return {
    code,
    display: formatCode(code),
    url: joinUrl(code),
    expiresAt: (d.expiresAt as Timestamp | null)?.toDate().toISOString() ?? null,
    maxUses: (d.maxUses as number | null) ?? null,
    useCount: (d.useCount as number | undefined) ?? 0,
  };
}

/** True if a link invite can still be used. */
export function isUsable(d: FirebaseFirestore.DocumentData, now = Date.now()): boolean {
  if (d.revokedAt) return false;
  const expires = d.expiresAt as Timestamp | null | undefined;
  if (expires && expires.toMillis() <= now) return false;
  if (d.maxUses != null && (d.useCount ?? 0) >= d.maxUses) return false;
  return true;
}

/** The team's current reusable link, or null (INV-2). */
export async function activeTeamLink(groupId: string): Promise<TeamLink | null> {
  const snap = await db()
    .collection(Collections.invites)
    .where('groupId', '==', groupId)
    .where('type', '==', 'link')
    .where('revokedAt', '==', null)
    .limit(5)
    .get();
  const doc = snap.docs.find((d) => isUsable(d.data()));
  return doc ? toTeamLink(doc.id, doc.data()) : null;
}

/** Creates a new reusable link for the team, with a code no other invite uses. */
export async function createTeamLink(groupId: string, createdBy: string, options: LinkOptions = {}): Promise<TeamLink> {
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = newInviteCode();
    const ref = db().collection(Collections.invites).doc(code);
    const data = {
      groupId,
      type: 'link',
      email: null,
      role: 'member',
      createdBy,
      expiresAt: options.expiresInDays ? Timestamp.fromMillis(Date.now() + options.expiresInDays * 86_400_000) : null,
      maxUses: options.maxUses ?? null,
      useCount: 0,
      revokedAt: null,
      createdAt: FieldValue.serverTimestamp(),
    };
    try {
      await ref.create(data);
      return toTeamLink(code, { ...data, createdAt: null });
    } catch (e) {
      if ((e as { code?: number }).code !== 6) throw e; // 6 = ALREADY_EXISTS: try another code
    }
  }
  throw new Error('Could not find a free invite code.');
}

/** Turns off every link for the team at once (INV-2 "Reset link"). */
export async function revokeTeamLinks(groupId: string): Promise<void> {
  const snap = await db()
    .collection(Collections.invites)
    .where('groupId', '==', groupId)
    .where('type', '==', 'link')
    .where('revokedAt', '==', null)
    .limit(50)
    .get();
  const batch = db().batch();
  snap.docs.forEach((d) => batch.update(d.ref, { revokedAt: FieldValue.serverTimestamp() }));
  await batch.commit();
}

export type InviteProblem = 'unknown' | 'expired' | 'revoked' | 'used-up' | 'wrong-email';

/** Why an invite can't be used, or null if it can (INV-8). */
export function problemWith(
  d: FirebaseFirestore.DocumentData | undefined,
  email: string | null,
  now = Date.now(),
): InviteProblem | null {
  if (!d) return 'unknown';
  if (d.revokedAt) return 'revoked';
  const expires = d.expiresAt as Timestamp | null | undefined;
  if (expires && expires.toMillis() <= now) return 'expired';
  if (d.maxUses != null && (d.useCount ?? 0) >= d.maxUses) return 'used-up';
  if (d.type === 'email' && email != null && d.email && d.email.toLowerCase() !== email.toLowerCase()) {
    return 'wrong-email';
  }
  return null;
}

export interface InvitePreview {
  groupId: string;
  name: string;
  sport: string;
  teamType: string;
  memberCount: number;
  color: string | null;
  invitedBy: string | null;
}

/** What the /join page shows before sign-in (INV-5, INV-7). */
export async function previewInvite(code: string): Promise<InvitePreview | InviteProblem> {
  const invite = await db().collection(Collections.invites).doc(code).get();
  const problem = problemWith(invite.data(), null);
  if (problem) return problem;
  const groupId = invite.get('groupId') as string;
  const group = await db().collection(Collections.groups).doc(groupId).get();
  if (!group.exists || group.get('archivedAt') || group.get('suspendedAt')) return 'unknown';
  const creator = await db().collection(Collections.users).doc(invite.get('createdBy') as string).get();
  return {
    groupId,
    name: group.get('name') as string,
    sport: group.get('sport') as string,
    teamType: group.get('teamType') as string,
    memberCount: (group.get('memberCount') as number) ?? 0,
    color: (group.get('color') as string | null) ?? null,
    invitedBy: (creator.get('displayName') as string | undefined) ?? null,
  };
}

/**
 * Uses an invite: adds the person to the team, counts the use, and returns
 * the team (INV-5). People already on the team just get the team back.
 */
export async function redeem(
  code: string,
  uid: string,
  email: string | null,
  member: { displayName: string; photoPath: string | null },
): Promise<{ groupId: string; teamType: string; alreadyMember: boolean } | InviteProblem> {
  const inviteRef = db().collection(Collections.invites).doc(code);
  return db().runTransaction(async (tx) => {
    const invite = await tx.get(inviteRef);
    const data = invite.data();
    const groupId = data?.groupId as string | undefined;
    const memberRef = groupId
      ? db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid))
      : null;
    if (memberRef && groupId) {
      const existing = await tx.get(memberRef);
      if (existing.exists) {
        const group = await tx.get(db().collection(Collections.groups).doc(groupId));
        return { groupId, teamType: group.get('teamType') as string, alreadyMember: true };
      }
    }
    const problem = problemWith(data, email);
    if (problem || !groupId || !memberRef) return problem ?? 'unknown';
    const group = await tx.get(db().collection(Collections.groups).doc(groupId));
    if (!group.exists || group.get('archivedAt') || group.get('suspendedAt')) return 'unknown';
    const now = FieldValue.serverTimestamp();
    tx.set(memberRef, {
      groupId,
      uid,
      role: data?.role ?? 'member',
      title: null,
      displayName: member.displayName,
      photoPath: member.photoPath,
      playerSummary: null,
      notificationLevel: 'all',
      mutedUntil: null,
      lastReadAt: now,
      lastPostedAt: null,
      joinedAt: now,
      addedBy: data?.createdBy ?? null,
      inviteCode: code,
    });
    tx.update(inviteRef, { useCount: FieldValue.increment(1) });
    return { groupId, teamType: group.get('teamType') as string, alreadyMember: false };
  });
}
