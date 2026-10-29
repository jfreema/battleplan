// Invites domain service: owns invites (ARCH §6.4, §6.6).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db, storage } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
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

/**
 * Turns off every link for the team at once (INV-2 "Reset link", §3
 * "revoke"). [turnedOff] marks a revoke that isn't followed by a new link:
 * the team then has no link until an admin turns one on (teamLinkIsOff).
 */
export async function revokeTeamLinks(groupId: string, turnedOff = false): Promise<void> {
  const snap = await db()
    .collection(Collections.invites)
    .where('groupId', '==', groupId)
    .where('type', '==', 'link')
    .where('revokedAt', '==', null)
    .limit(50)
    .get();
  const batch = db().batch();
  snap.docs.forEach((d) =>
    batch.update(d.ref, { revokedAt: FieldValue.serverTimestamp(), ...(turnedOff ? { turnedOff: true } : {}) }),
  );
  await batch.commit();
}

/**
 * Whether an admin turned the team's link off (§3 "revoke"): its newest
 * link was revoked without a new one. getTeamInvite then makes no new link
 * until an admin turns one on with resetGroupInvite.
 */
export async function teamLinkIsOff(groupId: string): Promise<boolean> {
  const snap = await db()
    .collection(Collections.invites)
    .where('groupId', '==', groupId)
    .where('type', '==', 'link')
    .orderBy('createdAt', 'desc')
    .limit(1)
    .get();
  return snap.docs[0]?.get('turnedOff') === true;
}

/**
 * Changes the current link's expiry and use limit without changing its
 * code, so the link and QR already shared keep working (INV-2). An expiry
 * counts from now; null clears it, as null maxUses does. Returns the link,
 * or null when the team has no usable one.
 */
export async function updateTeamLink(
  groupId: string,
  options: { expiresInDays: 1 | 7 | 30 | null; maxUses: number | null },
  now = Date.now(),
): Promise<TeamLink | null> {
  const link = await activeTeamLink(groupId);
  if (!link) return null;
  const ref = db().collection(Collections.invites).doc(link.code);
  const expiresAt = options.expiresInDays ? Timestamp.fromMillis(now + options.expiresInDays * 86_400_000) : null;
  await ref.update({ expiresAt, maxUses: options.maxUses });
  return toTeamLink(link.code, (await ref.get()).data() ?? {});
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
  /** 'team' or a basic 'group' (TEAM-14); older apps ignore it. */
  kind: string;
  sport: string;
  memberCount: number;
  color: string | null;
  /** A link to the team's logo, readable signed out (INV-5), or null. */
  logoUrl: string | null;
  invitedBy: string | null;
}

/**
 * A download link for the team's logo, which visitors who aren't on the
 * team can't read through the Storage rules (INV-5 "logo"). Logos uploaded
 * from the app carry a download token, which the link is built from; null
 * without one, or on any error.
 */
export async function logoUrlOf(photoPath: string | null | undefined): Promise<string | null> {
  if (!photoPath) return null;
  try {
    const file = storage().bucket().file(photoPath);
    const [meta] = await file.getMetadata();
    const token = String(meta.metadata?.firebaseStorageDownloadTokens ?? '').split(',')[0];
    if (!token) return null;
    const emulator = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
    const origin = emulator ? `http://${emulator.replace(/^https?:\/\//, '')}` : 'https://firebasestorage.googleapis.com';
    return `${origin}/v0/b/${file.bucket.name}/o/${encodeURIComponent(photoPath)}?alt=media&token=${encodeURIComponent(token)}`;
  } catch {
    return null;
  }
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
    kind: (group.get('kind') as string | undefined) ?? 'team',
    sport: group.get('sport') as string,
    memberCount: (group.get('memberCount') as number) ?? 0,
    color: (group.get('color') as string | null) ?? null,
    logoUrl: await logoUrlOf(group.get('photoPath') as string | null | undefined),
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
): Promise<{ groupId: string; alreadyMember: boolean } | InviteProblem> {
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
      if (existing.exists) return { groupId, alreadyMember: true };
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
    return { groupId, alreadyMember: false };
  });
}

export interface EmailInviteRow {
  code: string;
  email: string;
  status: 'pending' | 'joined' | 'expired' | 'revoked';
  createdAt: string | null;
}

/** Creates a single-use email invite that expires in 14 days (INV-4). */
export async function createEmailInvite(groupId: string, email: string, createdBy: string): Promise<string> {
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = newInviteCode();
    try {
      await db().collection(Collections.invites).doc(code).create({
        groupId,
        type: 'email',
        email: email.toLowerCase(),
        role: 'member',
        createdBy,
        expiresAt: Timestamp.fromMillis(Date.now() + Limits.emailInviteExpiryDays * 86_400_000),
        maxUses: 1,
        useCount: 0,
        revokedAt: null,
        createdAt: FieldValue.serverTimestamp(),
      });
      return code;
    } catch (e) {
      if ((e as { code?: number }).code !== 6) throw e;
    }
  }
  throw new Error('Could not find a free invite code.');
}

/** The team's email invites, newest first, with their state (INV-4). */
export async function listEmailInvites(groupId: string): Promise<EmailInviteRow[]> {
  const snap = await db()
    .collection(Collections.invites)
    .where('groupId', '==', groupId)
    .where('type', '==', 'email')
    .orderBy('createdAt', 'desc')
    .limit(100)
    .get();
  const now = Date.now();
  return snap.docs.map((d) => {
    const x = d.data();
    const status: EmailInviteRow['status'] =
      (x.useCount ?? 0) >= 1
        ? 'joined'
        : x.revokedAt
          ? 'revoked'
          : ((x.expiresAt as Timestamp | null)?.toMillis() ?? Infinity) <= now
            ? 'expired'
            : 'pending';
    return {
      code: d.id,
      email: x.email as string,
      status,
      createdAt: (x.createdAt as Timestamp | null)?.toDate().toISOString() ?? null,
    };
  });
}
