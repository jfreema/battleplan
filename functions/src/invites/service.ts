// Invites domain service: owns invites (ARCH §6.4, §6.6).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { joinUrl } from '../links/service.js';
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
