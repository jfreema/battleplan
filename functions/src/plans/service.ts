// Plans domain service (ARCH §6.11): owns licenses and the groups.plan
// cache. Every change to a license ends in applyPlan(), the one function
// that turns licenses into a team's plan.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { db } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';

const GB = 1024 ** 3;

/** [from] plus [months] calendar months (Jan 31 + 1 month = Feb 28/29). */
export function addMonths(from: Date, months: number): Date {
  const d = new Date(from.getTime());
  const day = d.getUTCDate();
  d.setUTCDate(1);
  d.setUTCMonth(d.getUTCMonth() + months);
  const lastDay = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate();
  d.setUTCDate(Math.min(day, lastDay));
  return d;
}

export interface LicenseDoc {
  holderId: string;
  groupId: string | null;
  tier: 'plus';
  startsAt: Timestamp;
  endsAt: Timestamp;
  source: string;
  revokedAt?: Timestamp | null;
  lastMovedAt?: Timestamp | null;
}

/** Whether a license counts right now. */
export function isActive(l: Pick<LicenseDoc, 'endsAt' | 'revokedAt'>, now = Date.now()): boolean {
  return !l.revokedAt && l.endsAt.toMillis() > now;
}

/** The team's active license, if any (one at a time, PLAN-3). */
export async function activeLicenseFor(
  groupId: string,
): Promise<{ id: string; data: LicenseDoc } | null> {
  const snap = await db().collection(Collections.licenses).where('groupId', '==', groupId).limit(20).get();
  const active = snap.docs
    .map((d) => ({ id: d.id, data: d.data() as LicenseDoc }))
    .filter((l) => isActive(l.data))
    .sort((a, b) => b.data.endsAt.toMillis() - a.data.endsAt.toMillis());
  return active[0] ?? null;
}

/**
 * Rewrites a team's plan cache and storage quota from its licenses
 * (ARCH §6.11). Called after every grant, extension, move, revoke, renewal,
 * and expiry, so the cache can't drift.
 */
export async function applyPlan(groupId: string): Promise<'free' | 'plus'> {
  const ref = db().collection(Collections.groups).doc(groupId);
  const group = await ref.get();
  if (!group.exists) return 'free';
  const license = await activeLicenseFor(groupId);
  const plus = license !== null;
  await ref.update({
    plan: plus
      ? { tier: 'plus', endsAt: license.data.endsAt, licenseId: license.id, holderId: license.data.holderId }
      : { tier: 'free', endsAt: null, licenseId: null, holderId: null },
    storageQuotaBytes: (plus ? Limits.plusStorageQuotaGb : Limits.defaultStorageQuotaGb) * GB,
  });
  return plus ? 'plus' : 'free';
}

/** Throws unless [uid] is an owner or admin of [groupId]. */
async function requireAdminOf(groupId: string, uid: string, message: string): Promise<void> {
  const member = await db().collection(Collections.groupMembers).doc(`${groupId}_${uid}`).get();
  const role = member.get('role') as string | undefined;
  if (role !== 'owner' && role !== 'admin') throw new HttpsError('failed-precondition', message);
}

/**
 * A super admin grants Plus to a person for a team (PLAN-2). The holder
 * must be an owner or admin of the team, and the team must not already
 * have an active license (extend that one instead).
 */
export async function grantLicense(input: {
  holderId: string;
  groupId: string;
  months: number;
  grantedBy: string;
}): Promise<string> {
  await requireAdminOf(input.groupId, input.holderId, 'holder-not-admin');
  if (await activeLicenseFor(input.groupId)) throw new HttpsError('failed-precondition', 'team-has-license');
  const now = new Date();
  const ref = await db()
    .collection(Collections.licenses)
    .add({
      holderId: input.holderId,
      groupId: input.groupId,
      tier: 'plus',
      startsAt: Timestamp.fromDate(now),
      endsAt: Timestamp.fromDate(addMonths(now, input.months)),
      source: 'grant',
      grantedBy: input.grantedBy,
      externalId: null,
      lastMovedAt: null,
      revokedAt: null,
      remindedAt: {},
      createdAt: FieldValue.serverTimestamp(),
    });
  await applyPlan(input.groupId);
  return ref.id;
}

/** Adds months to a license, from its end date or today if it ended. */
export async function extendLicense(licenseId: string, months: number): Promise<void> {
  const ref = db().collection(Collections.licenses).doc(licenseId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'no-license');
  const l = snap.data() as LicenseDoc;
  const base = Math.max(l.endsAt.toMillis(), Date.now());
  await ref.update({
    endsAt: Timestamp.fromDate(addMonths(new Date(base), months)),
    revokedAt: null,
    remindedAt: {},
  });
  if (l.groupId) await applyPlan(l.groupId);
}

/** Ends a license now (PLAN-2). The team returns to Free. */
export async function revokeLicense(licenseId: string): Promise<void> {
  const ref = db().collection(Collections.licenses).doc(licenseId);
  const snap = await ref.get();
  if (!snap.exists) return;
  await ref.update({ revokedAt: FieldValue.serverTimestamp() });
  const groupId = snap.get('groupId') as string | null;
  if (groupId) await applyPlan(groupId);
}

/**
 * Moves a license to another team (PLAN-3). The holder must own or admin
 * the target, the target must have no active license, and the license can
 * move once every 30 days unless a super admin moves it. The remaining
 * time moves with it.
 */
export async function moveLicense(
  licenseId: string,
  toGroupId: string,
  actorUid: string,
  bySuperAdmin: boolean,
): Promise<void> {
  const ref = db().collection(Collections.licenses).doc(licenseId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'no-license');
  const l = snap.data() as LicenseDoc;
  if (!bySuperAdmin && l.holderId !== actorUid) throw new HttpsError('permission-denied', 'not-holder');
  if (!isActive(l)) throw new HttpsError('failed-precondition', 'license-ended');
  if (l.groupId === toGroupId) return;
  await requireAdminOf(toGroupId, l.holderId, 'holder-not-admin');
  const cooldown = Limits.licenseMoveCooldownDays * 86_400_000;
  if (!bySuperAdmin && l.lastMovedAt && Date.now() - l.lastMovedAt.toMillis() < cooldown) {
    throw new HttpsError('failed-precondition', 'moved-recently');
  }
  const target = await activeLicenseFor(toGroupId);
  if (target && target.id !== licenseId) throw new HttpsError('failed-precondition', 'team-has-license');
  const from = l.groupId;
  await ref.update({ groupId: toGroupId, lastMovedAt: FieldValue.serverTimestamp() });
  if (from) await applyPlan(from);
  await applyPlan(toGroupId);
}
