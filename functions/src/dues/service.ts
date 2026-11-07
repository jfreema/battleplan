// Dues domain service: creates, edits, and deletes dues with their charges
// (SPEC DUES-1, DUES-2, ARCH §6.2). A due and its charges change together,
// in one batch or transaction, so nobody sees a due without its charges, or
// charges with another due's terms. Recording what each person paid, a part
// at a time or all at once, and how to pay the team, stay in the app under
// the rules; an edit keeps every payment, and refuses an amount below what
// someone already paid. The names on charges follow renames, and a deleted
// account's own charges read "Deleted user" (AUTH-10).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { createHash } from 'node:crypto';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { DELETED_USER_NAME } from '../chat/service.js';
import { db } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections, ID_SEPARATOR, Limits } from '../shared/constants.js';
import { dueChargeId, groupMemberId } from '../shared/ids.js';
import { requireTeamAdmin } from '../shared/roles.js';

/** Who's asking: their uid, and whether they're a super admin (§3). */
export interface Actor {
  uid: string;
  superAdmin: boolean;
}

/** A calendar day, 'YYYY-MM-DD', as the rules check it. */
const DAY = /^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/;

/** A document ID that can go in a composite ID (ARCH §6.2). */
const docId = z
  .string()
  .min(1)
  .max(128)
  .refine((s) => !s.includes('/') && !s.includes(ID_SEPARATOR));

/**
 * saveDue's input: a new due when there's no dueId, with who owes it, or
 * an edit of one, with anyone to add to it. Titles and notes longer than
 * their limits are clipped.
 */
export const SaveDueInput = z.object({
  groupId: docId,
  dueId: docId.optional(),
  title: z.string().max(1000),
  amountCents: z.number().int().min(1).max(Limits.dueAmountMaxCents),
  dueOn: z.string().regex(DAY).nullable(),
  note: z.string().max(5000).default(''),
  participantIds: z.array(docId).max(Limits.duesChargesMax * 2).optional(),
  // The app's ID for one new due, the same on every retry of it, so a
  // retry after a lost reply gets back that due, not a second one.
  requestId: z.string().regex(/^[A-Za-z0-9_-]{8,64}$/).optional(),
});
export type SaveDueInput = z.infer<typeof SaveDueInput>;

export const DeleteDueInput = z.object({ dueId: docId });

/** A due's terms, as stored on it and copied to its charges. */
export interface DueTerms {
  title: string;
  amountCents: number;
  dueOn: string | null;
  note: string;
}

function clip(s: string, max: number): string {
  const t = s.trim();
  return t.length <= max ? t : t.slice(0, max).trimEnd();
}

/** [input]'s terms, trimmed and clipped; a blank title is `invalid-argument`. */
export function dueTerms(input: Pick<SaveDueInput, 'title' | 'amountCents' | 'dueOn' | 'note'>): DueTerms {
  const title = clip(input.title, Limits.dueTitleMax);
  if (!title) throw new HttpsError('invalid-argument', 'due-title-required');
  return { title, amountCents: input.amountCents, dueOn: input.dueOn, note: clip(input.note ?? '', Limits.dueNoteMax) };
}

/** "Emma #7", or "Emma" without a number (PLAYER-8), as the app labels a player. */
export function playerLabel(displayName: unknown, jerseyNumber: unknown): string {
  const first = String(displayName ?? '').trim().split(/\s+/)[0] ?? '';
  const number = typeof jerseyNumber === 'string' ? jerseyNumber.trim() : '';
  return clip(number ? `${first} #${number}` : first, 80);
}

/** Who a new due is for, read from the server: names come from the roster, never the caller. */
interface Payer {
  type: 'player' | 'member';
  id: string;
  name: string;
}

/**
 * The payers among [ids]: on a team, its active players; in a basic group
 * (TEAM-14), its members who have joined. Anyone else is
 * `invalid-argument`, and so is no one or more than duesChargesMax.
 */
async function payersOf(groupId: string, isGroup: boolean, ids: string[]): Promise<Payer[]> {
  const unique = [...new Set(ids)];
  if (unique.length < 1 || unique.length > Limits.duesChargesMax) {
    throw new HttpsError('invalid-argument', 'due-payers');
  }
  const refs = unique.map((id) =>
    isGroup
      ? db().collection(Collections.groupMembers).doc(groupMemberId(groupId, id))
      : db().collection(Collections.players).doc(id),
  );
  const docs = await db().getAll(...refs);
  return docs.map((d, i) => {
    const ok = isGroup
      ? d.exists && d.get('groupId') === groupId && d.get('pending') !== true
      : d.exists && d.get('groupId') === groupId && d.get('status') !== 'pending';
    if (!ok) throw new HttpsError('invalid-argument', 'due-payer-not-on-team');
    return isGroup
      ? { type: 'member', id: unique[i], name: clip(String(d.get('displayName') ?? ''), 80) }
      : { type: 'player', id: unique[i], name: playerLabel(d.get('displayName'), d.get('jerseyNumber')) };
  });
}

/**
 * The due ID for one create attempt: the same for every retry of it by the
 * same person, and unguessable without their requestId. Twenty hex
 * characters, like Firestore's own IDs in length.
 */
export function dueIdFor(uid: string, requestId: string): string {
  return createHash('sha256').update(`due:${uid}:${requestId}`).digest('hex').slice(0, 20);
}

/** A new owed charge of [dueId] for [p], with the due's terms (the note too, DUES-2). */
function newCharge(groupId: string, dueId: string, terms: DueTerms, p: Payer, uid: string) {
  return {
    groupId,
    dueId,
    title: terms.title,
    amountCents: terms.amountCents,
    dueOn: terms.dueOn,
    note: terms.note,
    participantType: p.type,
    participantId: p.id,
    participantName: p.name,
    status: 'owed',
    paidAt: null,
    updatedBy: uid,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

/**
 * Adds a due and a charge, owed, for each of [participantIds], in one
 * batch (up to 101 writes). Team admins and super admins, on a team that
 * isn't archived; never in a direct conversation. Returns the due's ID.
 * With a [requestId], the due's ID comes from it, so a retry of an attempt
 * whose reply was lost gets back the due it made, not a second one.
 */
export async function createDue(
  groupId: string,
  terms: DueTerms,
  participantIds: string[],
  actor: Actor,
  requestId?: string,
): Promise<string> {
  await requireTeamAdmin(groupId, actor.uid, actor.superAdmin);
  const dues = db().collection(Collections.dues);
  const due = requestId ? dues.doc(dueIdFor(actor.uid, requestId)) : dues.doc();
  const alreadyMade = async () => {
    if (!requestId) return false;
    const d = await due.get();
    return d.exists && d.get('groupId') === groupId && d.get('createdBy') === actor.uid;
  };
  if (await alreadyMade()) return due.id;
  const group = await db().collection(Collections.groups).doc(groupId).get();
  const payers = await payersOf(groupId, group.get('kind') === 'group', participantIds);
  const now = FieldValue.serverTimestamp();
  const batch = db().batch();
  batch.create(due, { groupId, ...terms, createdBy: actor.uid, createdAt: now, updatedAt: now });
  for (const p of payers) {
    batch.create(db().collection(Collections.dueCharges).doc(dueChargeId(due.id, p.id)), newCharge(groupId, due.id, terms, p, actor.uid));
  }
  try {
    await batch.commit();
  } catch (e) {
    // Two copies of one attempt at the same moment: the other made it.
    if ((e as { code?: number }).code === 6 && (await alreadyMade())) return due.id;
    throw e;
  }
  return due.id;
}

/** The due [dueId] on [groupId], or `not-found`. */
async function dueOn(groupId: string | undefined, dueId: string): Promise<FirebaseFirestore.DocumentSnapshot> {
  const due = await db().collection(Collections.dues).doc(dueId).get();
  if (!due.exists || (groupId !== undefined && due.get('groupId') !== groupId)) {
    throw new HttpsError('not-found', 'due-not-found');
  }
  return due;
}

/** Every charge of [dueId], however many the app has loaded. */
function chargesOf(groupId: string, dueId: string): FirebaseFirestore.Query {
  return db().collection(Collections.dueCharges).where('groupId', '==', groupId).where('dueId', '==', dueId);
}

/** One payment on a charge, as the app records it (DUES-2, ARCH §6.2). */
export interface DuePayment {
  id: string;
  amountCents: number;
  paidOn: string;
  by: string;
  note: string;
}

/** A charge's status and payments, as stored. */
export interface ShareState {
  status: string;
  amountCents: number;
  payments?: DuePayment[];
  paidCents?: number;
  paidAt?: unknown;
}

/** The ID of the payment a share marked paid before payments were recorded becomes. */
export const MARKED_PAID_ID = 'marked-paid';

/** [at] (a Timestamp or Date) as a UTC day, 'YYYY-MM-DD', or [fallback]. */
function dayOf(at: unknown, fallback: string): string {
  const d = at instanceof Timestamp ? at.toDate() : at instanceof Date ? at : null;
  return d ? d.toISOString().slice(0, 10) : fallback;
}

/**
 * What a share becomes when its due's amount changes to [amountCents]
 * (DUES-1, DUES-2): its payments stay, and it's paid when they cover the new
 * amount, or owed (partly paid) when they don't; a waived one stays waived.
 * A share marked paid before payments were recorded paid its amount in
 * full, so it becomes one payment of that amount, on the day it was marked
 * paid, by nobody named. A share with no payments is left as it is (null).
 * Paid more than the new amount is `failed-precondition`: someone's payment
 * would be more than they owe, so the admin takes a payment back first.
 */
export function reamountShare(
  share: ShareState,
  amountCents: number,
  today: string,
): { payments: DuePayment[]; paidCents: number; status: string; paidAt: unknown } | null {
  let payments = share.payments;
  if (!payments) {
    if (share.status !== 'paid') return null;
    payments = [{ id: MARKED_PAID_ID, amountCents: share.amountCents, paidOn: dayOf(share.paidAt, today), by: '', note: '' }];
  }
  const paidCents = payments.reduce((sum, p) => sum + p.amountCents, 0);
  if (paidCents > amountCents) throw new HttpsError('failed-precondition', 'due-amount-below-paid');
  const status = share.status === 'waived' ? 'waived' : paidCents === amountCents ? 'paid' : 'owed';
  const paidAt = status !== 'paid' ? null : share.status === 'paid' ? (share.paidAt ?? FieldValue.serverTimestamp()) : FieldValue.serverTimestamp();
  return { payments, paidCents, status, paidAt };
}

/**
 * Changes a due's terms and copies its title, amount, date, and note to
 * every one of its charges, in one transaction, so a payment recorded at
 * the same moment is never lost or left over the amount. Every payment
 * stays: on a new amount, a share is paid when what was paid covers it, or
 * owed the rest (reamountShare), and an amount below what someone already
 * paid is `failed-precondition`. [addIds] are people to add to it (a player
 * who joined after it was made), each with a new owed charge, checked as a
 * new due's are; anyone already on it is skipped, nobody is taken off, and
 * the due still charges at most duesChargesMax people.
 */
export async function editDue(
  groupId: string,
  dueId: string,
  terms: DueTerms,
  actor: Actor,
  addIds: string[] = [],
): Promise<void> {
  await requireTeamAdmin(groupId, actor.uid, actor.superAdmin);
  const group = await db().collection(Collections.groups).doc(groupId).get();
  const isGroup = group.get('kind') === 'group';
  const today = new Date().toISOString().slice(0, 10);
  await db().runTransaction(async (tx) => {
    const due = await tx.get(db().collection(Collections.dues).doc(dueId));
    if (!due.exists || due.get('groupId') !== groupId) throw new HttpsError('not-found', 'due-not-found');
    const charges = await tx.get(chargesOf(groupId, dueId));
    const onIt = new Set(charges.docs.map((c) => String(c.get('participantId'))));
    const newIds = [...new Set(addIds)].filter((id) => !onIt.has(id));
    let added: Payer[] = [];
    if (newIds.length) {
      if (onIt.size + newIds.length > Limits.duesChargesMax) {
        throw new HttpsError('invalid-argument', 'due-payers');
      }
      added = await payersOf(groupId, isGroup, newIds);
    }
    const now = FieldValue.serverTimestamp();
    const reamounted = new Map<string, ReturnType<typeof reamountShare>>();
    for (const c of charges.docs) {
      if (c.get('amountCents') === terms.amountCents) continue;
      reamounted.set(c.id, reamountShare(c.data() as ShareState, terms.amountCents, today));
    }
    tx.update(due.ref, { ...terms, updatedAt: now });
    for (const c of charges.docs) {
      tx.update(c.ref, {
        title: terms.title,
        amountCents: terms.amountCents,
        dueOn: terms.dueOn,
        note: terms.note,
        ...(reamounted.get(c.id) ?? {}),
        updatedBy: actor.uid,
        updatedAt: now,
      });
    }
    for (const p of added) {
      tx.create(db().collection(Collections.dueCharges).doc(dueChargeId(dueId, p.id)), newCharge(groupId, dueId, terms, p, actor.uid));
    }
  });
}

/**
 * Deletes a due and every one of its charges, in one batch. Deleting
 * someone else's goes in the audit log (§6.4), with its title only: never
 * what anyone owed or paid.
 */
export async function deleteDueAndCharges(dueId: string, actor: Actor): Promise<void> {
  const due = await dueOn(undefined, dueId);
  const groupId = String(due.get('groupId'));
  await requireTeamAdmin(groupId, actor.uid, actor.superAdmin);
  const charges = await chargesOf(groupId, dueId).get();
  const batch = db().batch();
  batch.delete(due.ref);
  for (const c of charges.docs) batch.delete(c.ref);
  await batch.commit();
  const createdBy = String(due.get('createdBy') ?? '');
  if (createdBy !== actor.uid) {
    await audit({
      actorId: actor.uid,
      action: 'deleteDue',
      groupId,
      targetType: 'due',
      targetId: dueId,
      before: { title: due.get('title') ?? null, createdBy: createdBy || null },
    });
  }
}

/**
 * Keeps the name on [type] [id]'s charges (dueCharges.participantName,
 * cache ← players or the member's profile) in step after a rename or a new
 * jersey number, on every due, paid ones too, so admins and families see
 * who it is now ("Emma #12", not "Emma #7").
 */
export async function renameDueCharges(type: 'player' | 'member', id: string, name: string): Promise<number> {
  const clipped = clip(name, 80);
  if (!clipped) return 0;
  return forEachPage(
    db().collection(Collections.dueCharges).where('participantType', '==', type).where('participantId', '==', id),
    (b, d) => {
      if (d.get('participantName') !== clipped) b.update(d.ref, { participantName: clipped });
    },
  );
}

/**
 * A deleted account's dues (AUTH-10). Their own charges in a group stay
 * with its admins as part of its record, what was owed and paid, but read
 * "Deleted user"; a player's charges keep the player's name, as the player
 * stays on the roster. How to pay that they saved last is removed, so
 * nobody is pointed at the payment handles of someone who's gone; the
 * team's admins can add it again.
 */
export async function removeAccountFromDues(uid: string): Promise<void> {
  await renameDueCharges('member', uid, DELETED_USER_NAME);
  await forEachPage(db().collection(Collections.duesPayments).where('updatedBy', '==', uid), (b, d) => b.delete(d.ref));
}
