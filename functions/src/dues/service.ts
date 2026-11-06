// Dues domain service: creates, edits, and deletes dues with their charges
// (SPEC DUES-1, DUES-2, ARCH §6.2). A due and its charges change together,
// in one batch, so nobody sees a due without its charges, or charges with
// another due's terms. Marking a charge paid, and how to pay the team, stay
// in the app under the rules.
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
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
 * an edit of one. Titles and notes longer than their limits are clipped.
 */
export const SaveDueInput = z.object({
  groupId: docId,
  dueId: docId.optional(),
  title: z.string().max(1000),
  amountCents: z.number().int().min(1).max(Limits.dueAmountMaxCents),
  dueOn: z.string().regex(DAY).nullable(),
  note: z.string().max(5000).default(''),
  participantIds: z.array(docId).max(Limits.duesChargesMax * 2).optional(),
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
 * Adds a due and a charge, owed, for each of [participantIds], in one
 * batch (up to 101 writes). Team admins and super admins, on a team that
 * isn't archived; never in a direct conversation. Returns the due's ID.
 */
export async function createDue(
  groupId: string,
  terms: DueTerms,
  participantIds: string[],
  actor: Actor,
): Promise<string> {
  await requireTeamAdmin(groupId, actor.uid, actor.superAdmin);
  const group = await db().collection(Collections.groups).doc(groupId).get();
  const payers = await payersOf(groupId, group.get('kind') === 'group', participantIds);
  const due = db().collection(Collections.dues).doc();
  const now = FieldValue.serverTimestamp();
  const batch = db().batch();
  batch.create(due, { groupId, ...terms, createdBy: actor.uid, createdAt: now, updatedAt: now });
  for (const p of payers) {
    batch.create(db().collection(Collections.dueCharges).doc(dueChargeId(due.id, p.id)), {
      groupId,
      dueId: due.id,
      title: terms.title,
      amountCents: terms.amountCents,
      dueOn: terms.dueOn,
      participantType: p.type,
      participantId: p.id,
      participantName: p.name,
      status: 'owed',
      paidAt: null,
      updatedBy: actor.uid,
      updatedAt: now,
    });
  }
  await batch.commit();
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

/**
 * Changes a due's terms and copies its title, amount, and date to every
 * one of its charges, in one batch. Whether each is paid stays.
 */
export async function editDue(groupId: string, dueId: string, terms: DueTerms, actor: Actor): Promise<void> {
  await requireTeamAdmin(groupId, actor.uid, actor.superAdmin);
  const due = await dueOn(groupId, dueId);
  const charges = await chargesOf(groupId, dueId).get();
  const now = FieldValue.serverTimestamp();
  const batch = db().batch();
  batch.update(due.ref, { ...terms, updatedAt: now });
  for (const c of charges.docs) {
    batch.update(c.ref, {
      title: terms.title,
      amountCents: terms.amountCents,
      dueOn: terms.dueOn,
      updatedBy: actor.uid,
      updatedAt: now,
    });
  }
  await batch.commit();
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
