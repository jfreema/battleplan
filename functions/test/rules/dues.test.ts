// Security rules for dues (SPEC DUES-1..DUES-4): what a team's admins ask
// its players, or a basic group's members, to pay, and who paid. Admins, and
// super admins (§3), see every due and charge and record what each person
// paid, all at once or a part at a time, or waive it; everyone else sees
// only their own charge, or their player's. Dues and
// charges are created, edited, and deleted only by the saveDue and deleteDue
// callables (test/emulator/dues.test.ts). Everyone on the team reads how
// to pay (duesPayments); admins and the team's coaches write it. Archived
// teams are read-only (TEAM-9).
// Run against the emulator: npm --prefix functions run emulators:test
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { Limits } from '../../src/shared/constants.js';

type Db = firebase.firestore.Firestore;

let env: RulesTestEnvironment;
const now = () => firebase.firestore.FieldValue.serverTimestamp();
const ts = (iso: string) => firebase.firestore.Timestamp.fromDate(new Date(iso));
const OLD = ts('2026-10-01T00:00:00Z');
const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const root = (): Db => env.authenticatedContext('root', { superAdmin: true }).firestore();

/** A due as stored, for seeding. */
const storedDue = (extra: object = {}) => ({
  groupId: 'teamA',
  title: 'Uniforms',
  amountCents: 4500,
  dueOn: '2026-12-01',
  note: '',
  createdBy: 'alice',
  createdAt: OLD,
  updatedAt: OLD,
  ...extra,
});

/** A new due as the app writes it, every field there. */
const due = (uid: string, extra: object = {}): Record<string, unknown> => ({
  ...storedDue({ createdBy: uid, createdAt: now(), updatedAt: now() }),
  ...extra,
});

/** A charge as stored, for seeding. */
const storedCharge = (extra: object = {}) => ({
  groupId: 'teamA',
  dueId: 'd1',
  title: 'Uniforms',
  amountCents: 4500,
  dueOn: '2026-12-01',
  participantType: 'player',
  participantId: 'emma',
  participantName: 'Emma',
  status: 'owed',
  paidAt: null,
  updatedBy: 'alice',
  updatedAt: OLD,
  ...extra,
});

/** A new charge as the app writes it. */
const charge = (uid: string, extra: object = {}): Record<string, unknown> => ({
  ...storedCharge({ updatedBy: uid, updatedAt: now() }),
  ...extra,
});

/** How to pay, as the app writes it. */
const payments = (uid: string, extra: object = {}): Record<string, unknown> => ({
  groupId: 'teamA',
  venmo: '@coach-alice',
  cashApp: '',
  appleCash: '',
  note: 'Pay by the first game',
  updatedBy: uid,
  updatedAt: now(),
  ...extra,
});

const editDue = (db: Db, id: string, changes: object) => db.doc(`dues/${id}`).update({ updatedAt: now(), ...changes });
const editCharge = (db: Db, uid: string, id: string, changes: object) =>
  db.doc(`dueCharges/${id}`).update({ updatedBy: uid, updatedAt: now(), ...changes });

/** Everything on a team, as an admin's dues screen lists it. */
const listAll = (db: Db, collection: string, g = 'teamA') => db.collection(collection).where('groupId', '==', g).limit(100).get();
/** One person's charges, as the app lists them. */
const listOwn = (db: Db, type: string, id: string, g = 'teamA') =>
  db.collection('dueCharges')
    .where('groupId', '==', g)
    .where('participantType', '==', type)
    .where('participantId', '==', id)
    .limit(50)
    .get();

// teamA (a team): alice owner, carol admin, bob, dan, and erin members,
// and kim a member its admins marked Coach. Players emma (dan is her
// guardian), finn (erin is the player, 'self'), and gus (nobody's). Due d1
// with charges d1_emma, d1_finn, d1_gus, and dO with dO_bob, bob's own from
// before teamA was a group made a team (TEAM-14). clubC (a basic group):
// hana owner, ivan and jo members; due dC with charges dC_ivan and dC_jo.
// teamB: gina admin, player zed. teamA has a duesPayments doc. root is a
// super admin on no team.
async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const group = (g: string, kind: string) =>
      db.doc(`groups/${g}`).set({ name: g, nameLower: g.toLowerCase(), kind, settings: {}, storageBytes: 0, storageQuotaBytes: 1 });
    await group('teamA', 'team');
    await group('teamB', 'team');
    await group('clubC', 'group');
    await db.doc('groups/dm1').set({ name: '', nameLower: '', kind: 'direct', uids: ['alice', 'bob'], settings: {} });
    const member = (g: string, uid: string, role: string, extra: object = {}) =>
      db.doc(`groupMembers/${g}_${uid}`).set({ groupId: g, uid, role, displayName: uid, photoPath: null, ...extra });
    await member('teamA', 'alice', 'owner');
    await member('teamA', 'carol', 'admin');
    await member('teamA', 'bob', 'member');
    await member('teamA', 'dan', 'member');
    await member('teamA', 'erin', 'member');
    await member('teamA', 'kim', 'member', { coach: true });
    await member('teamB', 'gina', 'admin');
    await member('clubC', 'hana', 'owner');
    await member('clubC', 'ivan', 'member');
    await member('clubC', 'jo', 'member');
    await member('dm1', 'alice', 'member');
    await member('dm1', 'bob', 'member');
    const player = (id: string, g: string) =>
      db.doc(`players/${id}`).set({ groupId: g, displayName: id, displayNameLower: id, status: 'active' });
    await player('emma', 'teamA');
    await player('finn', 'teamA');
    await player('gus', 'teamA');
    await player('zed', 'teamB');
    await db.doc('playerGuardians/emma_dan').set({ groupId: 'teamA', playerId: 'emma', uid: 'dan', relation: 'guardian' });
    await db.doc('playerGuardians/finn_erin').set({ groupId: 'teamA', playerId: 'finn', uid: 'erin', relation: 'self' });
    await db.doc('dues/d1').set(storedDue());
    await db.doc('dues/dB').set(storedDue({ groupId: 'teamB', createdBy: 'gina' }));
    await db.doc('dues/dC').set(storedDue({ groupId: 'clubC', title: 'Lane fee', createdBy: 'hana' }));
    await db.doc('dueCharges/d1_emma').set(storedCharge());
    await db.doc('dueCharges/d1_finn').set(storedCharge({ participantId: 'finn', participantName: 'Finn', status: 'paid', paidAt: OLD }));
    await db.doc('dueCharges/d1_gus').set(storedCharge({ participantId: 'gus', participantName: 'Gus', status: 'waived' }));
    const memberCharge = (uid: string) =>
      db.doc(`dueCharges/dC_${uid}`).set(storedCharge({
        groupId: 'clubC', dueId: 'dC', title: 'Lane fee', participantType: 'member', participantId: uid,
        participantName: uid, updatedBy: 'hana',
      }));
    await memberCharge('ivan');
    await memberCharge('jo');
    await db.doc('dueCharges/dO_bob').set(storedCharge({
      dueId: 'dO', title: 'Snacks', participantType: 'member', participantId: 'bob', participantName: 'bob',
    }));
    await db.doc('duesPayments/teamA').set({ ...payments('alice'), updatedAt: OLD });
  });
}

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-battleplan',
    firestore: { rules: readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed();
});

afterAll(async () => {
  await env?.cleanup();
});

const setGroup = (g: string, fields: object) =>
  env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc(`groups/${g}`).update(fields));

describe('reading dues', () => {
  it('is for the team admins and super admins, a bounded list at a time', async () => {
    for (const uid of ['alice', 'carol']) {
      await assertSucceeds(as(uid).doc('dues/d1').get());
      await assertSucceeds(listAll(as(uid), 'dues'));
    }
    await assertSucceeds(as('hana').doc('dues/dC').get());
    await assertSucceeds(root().doc('dues/dB').get());
    await assertSucceeds(listAll(root(), 'dues'));
    await assertFails(as('alice').collection('dues').where('groupId', '==', 'teamA').get());
  });

  it("is closed to members, guardians, and other teams' admins, who read their charges instead", async () => {
    for (const uid of ['bob', 'dan', 'erin', 'gina']) {
      await assertFails(as(uid).doc('dues/d1').get());
      await assertFails(listAll(as(uid), 'dues'));
    }
    await assertFails(as('ivan').doc('dues/dC').get());
    await assertFails(listAll(as('ivan'), 'dues', 'clubC'));
  });
});

describe('dues are written only by the saveDue and deleteDue callables', () => {
  it('nobody creates, edits, or deletes one in the app, admins and super admins included', async () => {
    for (const db of [as('alice'), as('carol'), root()]) {
      await assertFails(db.doc('dues/d2').set(due('carol')));
      await assertFails(editDue(db, 'd1', { title: 'Jerseys' }));
      await assertFails(db.doc('dues/d1').delete());
    }
    await assertFails(as('hana').doc('dues/dC2').set(due('hana', { groupId: 'clubC' })));
    for (const uid of ['bob', 'dan', 'erin', 'gina']) {
      await assertFails(as(uid).doc(`dues/n_${uid}`).set(due(uid)));
      await assertFails(editDue(as(uid), 'd1', { title: 'Mine' }));
      await assertFails(as(uid).doc('dues/d1').delete());
    }
  });
});

describe('charges', () => {
  it('nobody adds or deletes one in the app: the callables do, with the due', async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('dueCharges/d1_emma').delete());
    for (const [db, uid] of [[as('carol'), 'carol'], [as('alice'), 'alice'], [root(), 'root']] as const) {
      await assertFails(db.doc('dueCharges/d1_emma').set(charge(uid)));
      await assertFails(db.doc('dueCharges/d1_gus').delete());
    }
    await assertFails(as('hana').doc('dueCharges/dC_hana').set(charge('hana', {
      groupId: 'clubC', dueId: 'dC', participantType: 'member', participantId: 'hana', participantName: 'Hana',
    })));
    await assertFails(as('hana').doc('dueCharges/dC_jo').delete());
    await assertFails(as('dan').doc('dueCharges/d1_emma').set(charge('dan')));
    await assertFails(as('ivan').doc('dueCharges/dC_ivan').delete());
  });

  it('admins and super admins mark them paid, owed again, or waived', async () => {
    await assertSucceeds(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'paid', paidAt: now() }));
    await assertSucceeds(editCharge(as('alice'), 'alice', 'd1_finn', { status: 'owed', paidAt: null }));
    await assertSucceeds(editCharge(as('hana'), 'hana', 'dC_ivan', { status: 'waived' }));
    await assertSucceeds(editCharge(root(), 'root', 'd1_emma', { status: 'waived', paidAt: null }));
  });

  it("keep the due's note, up to 280 characters, when marked paid", async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('dueCharges/d1_emma').update({ note: 'n'.repeat(Limits.dueNoteMax) }));
    await assertSucceeds(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'paid', paidAt: now() }));
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('dueCharges/d1_gus').update({ note: 'n'.repeat(Limits.dueNoteMax + 1) }));
    await assertFails(editCharge(as('carol'), 'carol', 'd1_gus', { status: 'owed' }));
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('dueCharges/d1_finn').update({ note: 5 }));
    await assertFails(editCharge(as('carol'), 'carol', 'd1_finn', { status: 'owed', paidAt: null }));
  });

  it("never change a charge's terms, name, or person in the app", async () => {
    for (const changes of [
      { title: 'Jerseys' },
      { amountCents: 2000 },
      { dueOn: null },
      { note: 'Pay me instead' },
      { participantName: 'Gus B' },
      { participantId: 'gus' },
      { participantType: 'member' },
      { dueId: 'dB' },
      { groupId: 'teamB' },
    ]) {
      await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', changes));
      await assertFails(editCharge(root(), 'root', 'd1_emma', changes));
    }
  });

  it('never leave a paid time on an unpaid charge, or a bad status', async () => {
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { paidAt: now() }));
    await assertFails(editCharge(as('carol'), 'carol', 'd1_finn', { status: 'owed' }));
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'waived', paidAt: OLD }));
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'late' }));
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'paid', paidAt: 'today' }));
    await assertFails(as('carol').doc('dueCharges/d1_emma').update({ status: 'waived', updatedAt: now() }));
    await assertFails(editCharge(as('carol'), 'alice', 'd1_emma', { status: 'waived' }));
    await assertFails(as('carol').doc('dueCharges/d1_emma').update({ status: 'waived', updatedBy: 'carol', updatedAt: OLD }));
  });

  it('members, guardians, and other teams mark none, their own included', async () => {
    await assertFails(editCharge(as('dan'), 'dan', 'd1_emma', { status: 'paid', paidAt: now() }));
    await assertFails(editCharge(as('erin'), 'erin', 'd1_finn', { status: 'waived', paidAt: null }));
    await assertFails(editCharge(as('ivan'), 'ivan', 'dC_ivan', { status: 'paid', paidAt: now() }));
    await assertFails(editCharge(as('bob'), 'bob', 'd1_gus', { status: 'owed' }));
    await assertFails(editCharge(as('gina'), 'gina', 'd1_emma', { status: 'waived' }));
  });
});

/** A payment as the app records it. */
const pay = (by: string, amountCents: number, extra: object = {}) => ({
  id: `pay-${by}-${amountCents}-${Math.random().toString(36).slice(2, 8)}`,
  amountCents,
  paidOn: '2026-11-05',
  by,
  note: '',
  ...extra,
});

/** Sets a charge's payments as stored, for seeding. */
const storedPayments = (id: string, payments: object[], extra: object = {}) =>
  env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc(`dueCharges/${id}`).update({
    payments,
    paidCents: payments.reduce((sum, p) => sum + (p as { amountCents: number }).amountCents, 0),
    ...extra,
  }));

/** The charge's payments and total now, as the app reads them before writing. */
const current = async (id: string) => {
  let data: firebase.firestore.DocumentData = {};
  await env.withSecurityRulesDisabled(async (ctx) => {
    data = (await ctx.firestore().doc(`dueCharges/${id}`).get()).data()!;
  });
  return { payments: (data.payments ?? []) as Record<string, unknown>[], paidCents: (data.paidCents ?? 0) as number, amountCents: data.amountCents as number };
};

/** Records [p] on charge [id] as the app does: added at the end, the total and status with it. */
const record = async (db: Db, uid: string, id: string, p: { amountCents: number }, extra: object = {}) => {
  const c = await current(id);
  const paidCents = c.paidCents + p.amountCents;
  const full = paidCents === c.amountCents;
  return editCharge(db, uid, id, {
    payments: [...c.payments, p],
    paidCents,
    status: full ? 'paid' : 'owed',
    paidAt: full ? now() : null,
    ...extra,
  });
};

/** Takes payment [i] back, as the app does. */
const undo = async (db: Db, uid: string, id: string, i: number, extra: object = {}) => {
  const c = await current(id);
  const gone = c.payments[i] as { amountCents: number };
  return editCharge(db, uid, id, {
    payments: c.payments.filter((_, j) => j !== i),
    paidCents: c.paidCents - gone.amountCents,
    status: 'owed',
    paidAt: null,
    ...extra,
  });
};

describe('payments: a part at a time, or all of it (DUES-2)', () => {
  it('admins and super admins record parts until it is paid in full, then nothing more', async () => {
    await assertSucceeds(record(as('carol'), 'carol', 'd1_emma', pay('carol', 2000, { note: 'Cash at practice' })));
    await assertSucceeds(record(root(), 'root', 'd1_emma', pay('root', 500)));
    await assertSucceeds(record(as('alice'), 'alice', 'd1_emma', pay('alice', 2000)));
    const c = await current('d1_emma');
    expect(c.paidCents).toBe(4500);
    expect(c.payments.map((p) => p.amountCents)).toEqual([2000, 500, 2000]);
    // Paid in full: there's nothing left to record.
    await assertFails(record(as('carol'), 'carol', 'd1_emma', pay('carol', 1)));
    await assertSucceeds(record(as('hana'), 'hana', 'dC_ivan', pay('hana', 4500)));
  });

  it('never more than what is left, nothing, or a part of a cent', async () => {
    await storedPayments('d1_emma', [pay('alice', 2000)]);
    for (const amountCents of [2501, 0, -100, 12.5]) {
      await assertFails(record(as('carol'), 'carol', 'd1_emma', pay('carol', amountCents)));
    }
    await assertFails(record(as('carol'), 'carol', 'd1_emma', { ...pay('carol', 100), amountCents: '100' } as never));
    await assertSucceeds(record(as('carol'), 'carol', 'd1_emma', pay('carol', 2500)));
  });

  it('keeps the total and the status in step with the payments', async () => {
    const p = pay('carol', 2000);
    // A total that doesn't add up.
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { payments: [p], paidCents: 2500, status: 'owed', paidAt: null }));
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { payments: [p], paidCents: 1500, status: 'owed', paidAt: null }));
    // Paid while some is left, or owed with none left.
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { payments: [p], paidCents: 2000, status: 'paid', paidAt: now() }));
    const all = pay('carol', 4500);
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { payments: [all], paidCents: 4500, status: 'owed', paidAt: null }));
    // One without the other.
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { payments: [p] }));
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { paidCents: 2000 }));
    // Paid with nothing paid on a charge that records payments.
    await storedPayments('d1_emma', []);
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'paid', paidAt: now() }));
    await assertSucceeds(editCharge(as('carol'), 'carol', 'd1_emma', { payments: [p], paidCents: 2000, status: 'owed', paidAt: null }));
  });

  it('refuses a payment in someone else\'s name, a bad day, a long note, or extra fields', async () => {
    for (const p of [
      pay('alice', 1000),
      pay('carol', 1000, { paidOn: '11/05/2026' }),
      pay('carol', 1000, { paidOn: '2026-13-01' }),
      pay('carol', 1000, { note: 'n'.repeat(Limits.duePaymentNoteMax + 1) }),
      pay('carol', 1000, { note: null }),
      pay('carol', 1000, { id: 'short' }),
      pay('carol', 1000, { method: 'venmo' }),
      { amountCents: 1000, paidOn: '2026-11-05', by: 'carol', note: '' },
    ]) {
      await assertFails(record(as('carol'), 'carol', 'd1_emma', p));
    }
    await assertSucceeds(record(as('carol'), 'carol', 'd1_emma', pay('carol', 1000, { note: 'n'.repeat(Limits.duePaymentNoteMax) })));
  });

  it('adds one payment at a time, at the end, and never changes one already there', async () => {
    const first = pay('alice', 1000);
    await storedPayments('d1_emma', [first]);
    // Two at once.
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', {
      payments: [first, pay('carol', 500), pay('carol', 500)], paidCents: 2000, status: 'owed', paidAt: null,
    }));
    // In front of the earlier one.
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', {
      payments: [pay('carol', 500), first], paidCents: 1500, status: 'owed', paidAt: null,
    }));
    // Changing the earlier one.
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', {
      payments: [{ ...first, amountCents: 1500 }], paidCents: 1500, status: 'owed', paidAt: null,
    }));
    // The same one again.
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', {
      payments: [first, first], paidCents: 2000, status: 'owed', paidAt: null,
    }));
  });

  it('two admins recording at once: a write from an older list is refused, never lost over the other', async () => {
    // Carol and Alice both read the charge with nothing paid.
    const before = await current('d1_emma');
    await assertSucceeds(record(as('alice'), 'alice', 'd1_emma', pay('alice', 2000)));
    // Carol's write was made from the older list.
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', {
      payments: [...before.payments, pay('carol', 1000)], paidCents: before.paidCents + 1000, status: 'owed', paidAt: null,
    }));
    // Read again, it goes on after Alice's.
    await assertSucceeds(record(as('carol'), 'carol', 'd1_emma', pay('carol', 1000)));
    expect((await current('d1_emma')).paidCents).toBe(3000);
  });

  it(`holds at most ${Limits.duePaymentsMax} payments`, async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('dueCharges/d1_emma').update({ amountCents: 100000 }));
    await storedPayments('d1_emma', Array.from({ length: Limits.duePaymentsMax - 1 }, (_, i) => pay('alice', 100, { id: `seeded-${i}` })));
    await assertSucceeds(record(as('carol'), 'carol', 'd1_emma', pay('carol', 100)));
    await assertFails(record(as('carol'), 'carol', 'd1_emma', pay('carol', 100)));
  });

  it('a mistaken payment is taken back, from anywhere in the list, and nothing else with it', async () => {
    const [a, b, c] = [pay('alice', 1000), pay('carol', 2000), pay('alice', 1500)];
    await storedPayments('d1_emma', [a, b, c], { status: 'paid', paidAt: OLD });
    // Two at once, or the total wrong.
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { payments: [a], paidCents: 1000, status: 'owed', paidAt: null }));
    await assertFails(undo(as('carol'), 'carol', 'd1_emma', 1, { paidCents: 3000 }));
    // Still paid with some taken back.
    await assertFails(undo(as('carol'), 'carol', 'd1_emma', 1, { status: 'paid', paidAt: OLD }));
    await assertSucceeds(undo(as('carol'), 'carol', 'd1_emma', 1));
    expect((await current('d1_emma')).payments).toEqual([a, c]);
    expect((await current('d1_emma')).paidCents).toBe(2500);
    await assertSucceeds(undo(root(), 'root', 'd1_emma', 0));
    await assertSucceeds(undo(as('alice'), 'alice', 'd1_emma', 0));
    expect(await current('d1_emma')).toMatchObject({ payments: [], paidCents: 0 });
  });

  it('a waived share takes no payment, keeps what was paid, and goes back to paid or owed when waived no more', async () => {
    await storedPayments('d1_emma', [pay('alice', 2000)]);
    await assertSucceeds(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'waived' }));
    await assertFails(record(as('carol'), 'carol', 'd1_emma', pay('carol', 500), { status: 'waived' }));
    // Back to owed, with what was paid.
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'paid', paidAt: now() }));
    await assertSucceeds(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'owed' }));
    // A mistaken payment on a waived share can be taken back.
    await assertSucceeds(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'waived' }));
    await assertSucceeds(undo(as('carol'), 'carol', 'd1_emma', 0, { status: 'waived' }));
  });

  it('a share marked paid before payments were recorded stays paid, takes no payment, and can be marked not paid', async () => {
    // d1_finn: paid, with no payments recorded.
    await assertFails(record(as('carol'), 'carol', 'd1_finn', pay('carol', 4500)));
    await assertSucceeds(editCharge(as('carol'), 'carol', 'd1_finn', { status: 'owed', paidAt: null }));
    await assertSucceeds(record(as('carol'), 'carol', 'd1_finn', pay('carol', 4500)));
  });

  it('members, guardians, coaches, and other teams record none, their own included', async () => {
    for (const [uid, id] of [['dan', 'd1_emma'], ['erin', 'd1_finn'], ['bob', 'd1_emma'], ['kim', 'd1_emma'], ['gina', 'd1_emma'], ['ivan', 'dC_ivan'], ['bob', 'dO_bob']]) {
      await assertFails(record(as(uid), uid, id, pay(uid, 1000)));
    }
    await storedPayments('d1_emma', [pay('alice', 1000)]);
    await assertFails(undo(as('dan'), 'dan', 'd1_emma', 0));
  });

  it('a member reads their own share with what has been paid, and nobody else\'s', async () => {
    await storedPayments('d1_emma', [pay('alice', 1000)]);
    await assertSucceeds(as('dan').doc('dueCharges/d1_emma').get());
    await assertFails(as('erin').doc('dueCharges/d1_emma').get());
    await assertFails(as('bob').doc('dueCharges/d1_emma').get());
  });
});

describe('reading charges: nobody sees what someone else owes', () => {
  it('admins and super admins read and list them all', async () => {
    for (const uid of ['alice', 'carol']) {
      await assertSucceeds(as(uid).doc('dueCharges/d1_gus').get());
      await assertSucceeds(listAll(as(uid), 'dueCharges'));
    }
    await assertSucceeds(listAll(as('hana'), 'dueCharges', 'clubC'));
    await assertSucceeds(root().doc('dueCharges/dC_jo').get());
    await assertSucceeds(listAll(root(), 'dueCharges'));
    await assertFails(as('alice').collection('dueCharges').where('groupId', '==', 'teamA').get());
  });

  it("a member of a basic group reads only their own", async () => {
    await assertSucceeds(as('ivan').doc('dueCharges/dC_ivan').get());
    await assertSucceeds(listOwn(as('ivan'), 'member', 'ivan', 'clubC'));
    await assertFails(as('ivan').doc('dueCharges/dC_jo').get());
    await assertFails(listOwn(as('ivan'), 'member', 'jo', 'clubC'));
    await assertFails(listAll(as('ivan'), 'dueCharges', 'clubC'));
  });

  it('on a team that was a group, a member still reads their own from then', async () => {
    await assertSucceeds(as('bob').doc('dueCharges/dO_bob').get());
    await assertSucceeds(listOwn(as('bob'), 'member', 'bob'));
    await assertFails(as('dan').doc('dueCharges/dO_bob').get());
    await assertFails(listOwn(as('dan'), 'member', 'bob'));
    // With nothing to show, the list still works: it can show only mine.
    await assertSucceeds(listOwn(as('dan'), 'member', 'dan'));
  });

  it("a guardian reads only their player's, and so does a player linked as themselves", async () => {
    await assertSucceeds(as('dan').doc('dueCharges/d1_emma').get());
    await assertSucceeds(listOwn(as('dan'), 'player', 'emma'));
    await assertSucceeds(as('erin').doc('dueCharges/d1_finn').get());
    await assertSucceeds(listOwn(as('erin'), 'player', 'finn'));
    await assertFails(as('dan').doc('dueCharges/d1_finn').get());
    await assertFails(as('dan').doc('dueCharges/d1_gus').get());
    await assertFails(listOwn(as('dan'), 'player', 'gus'));
    await assertFails(as('erin').doc('dueCharges/d1_emma').get());
    await assertFails(listAll(as('dan'), 'dueCharges'));
  });

  it("others on the team, and other teams' admins, read none", async () => {
    for (const id of ['d1_emma', 'd1_finn', 'd1_gus']) {
      await assertFails(as('bob').doc(`dueCharges/${id}`).get());
      await assertFails(as('gina').doc(`dueCharges/${id}`).get());
    }
    await assertFails(listOwn(as('bob'), 'player', 'emma'));
    await assertFails(listOwn(as('gina'), 'player', 'emma'));
    await assertFails(listAll(as('bob'), 'dueCharges'));
    await assertFails(listAll(as('gina'), 'dueCharges'));
    // A guardian who leaves the team loses their player's charges.
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groupMembers/teamA_dan').delete());
    await assertFails(as('dan').doc('dueCharges/d1_emma').get());
  });

  it('a suspended team closes them to everyone on it, and super admins still read', async () => {
    await setGroup('teamA', { suspendedAt: OLD });
    await assertFails(as('alice').doc('dueCharges/d1_emma').get());
    await assertFails(listAll(as('alice'), 'dueCharges'));
    await assertFails(as('dan').doc('dueCharges/d1_emma').get());
    await assertFails(as('alice').doc('dues/d1').get());
    await assertFails(editCharge(as('alice'), 'alice', 'd1_emma', { status: 'waived' }));
    await assertSucceeds(listAll(root(), 'dueCharges'));
  });
});

describe('how to pay (duesPayments)', () => {
  it('everyone on the team reads it, and super admins', async () => {
    for (const uid of ['alice', 'carol', 'bob', 'dan', 'erin']) {
      await assertSucceeds(as(uid).doc('duesPayments/teamA').get());
    }
    await assertSucceeds(as('bob').collection('duesPayments').where('groupId', '==', 'teamA').limit(10).get());
    await assertSucceeds(root().doc('duesPayments/teamA').get());
    await assertSucceeds(as('ivan').doc('duesPayments/clubC').get());
    await assertFails(as('gina').doc('duesPayments/teamA').get());
    await assertFails(as('gina').collection('duesPayments').where('groupId', '==', 'teamA').limit(10).get());
  });

  it("a team's coaches write it too, on an open team, and nothing else of the dues", async () => {
    await assertSucceeds(as('kim').doc('duesPayments/teamA').set(payments('kim', { venmo: '@coach-kim' })));
    await assertSucceeds(as('kim').doc('duesPayments/teamA').update({ cashApp: '$KimsTeam', updatedBy: 'kim', updatedAt: now() }));
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('duesPayments/teamA').delete());
    await assertSucceeds(as('kim').doc('duesPayments/teamA').set(payments('kim')));
    // Only admins delete it, read the dues, or mark who paid.
    await assertFails(as('kim').doc('duesPayments/teamA').delete());
    await assertFails(as('kim').doc('dues/d1').get());
    await assertFails(as('kim').doc('dueCharges/d1_emma').get());
    await assertFails(editCharge(as('kim'), 'kim', 'd1_emma', { status: 'paid', paidAt: now() }));
    // Still in their own name, with good values.
    await assertFails(as('kim').doc('duesPayments/teamA').set(payments('alice')));
    await assertFails(as('kim').doc('duesPayments/teamA').set(payments('kim', { venmo: 'x'.repeat(Limits.duePayHandleMax + 1) })));
    // Not once the admins unmark them, or on an archived team.
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groupMembers/teamA_kim').update({ coach: false }));
    await assertFails(as('kim').doc('duesPayments/teamA').set(payments('kim')));
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groupMembers/teamA_kim').update({ coach: true }));
    await setGroup('teamA', { archivedAt: OLD });
    await assertFails(as('kim').doc('duesPayments/teamA').set(payments('kim')));
  });

  it('a basic group has no coaches: a coach flag there writes nothing', async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groupMembers/clubC_ivan').update({ coach: true }));
    await assertFails(as('ivan').doc('duesPayments/clubC').set(payments('ivan', { groupId: 'clubC' })));
  });

  it('admins and super admins write it, and members never do', async () => {
    await assertSucceeds(as('carol').doc('duesPayments/teamA').set(payments('carol', { cashApp: '$teamA', note: '' })));
    await assertSucceeds(as('hana').doc('duesPayments/clubC').set(payments('hana', { groupId: 'clubC', venmo: '', appleCash: '555-0100' })));
    await assertSucceeds(root().doc('duesPayments/teamB').set(payments('root', { groupId: 'teamB' })));
    for (const uid of ['bob', 'dan', 'gina']) {
      await assertFails(as(uid).doc('duesPayments/teamA').set(payments(uid)));
      await assertFails(as(uid).doc('duesPayments/teamA').update({ venmo: '@mine', updatedBy: uid, updatedAt: now() }));
      await assertFails(as(uid).doc('duesPayments/teamA').delete());
    }
    await assertFails(as('ivan').doc('duesPayments/clubC').set(payments('ivan', { groupId: 'clubC' })));
    await assertSucceeds(as('alice').doc('duesPayments/teamA').delete());
  });

  it('refuses bad values, another team, and a direct conversation', async () => {
    for (const extra of [
      { venmo: 'x'.repeat(Limits.duePayHandleMax + 1) },
      { cashApp: 'x'.repeat(Limits.duePayHandleMax + 1) },
      { appleCash: 'x'.repeat(Limits.duePayHandleMax + 1) },
      { note: 'x'.repeat(Limits.dueNoteMax + 1) },
      { venmo: null },
      { groupId: 'teamB' },
      { updatedBy: 'alice' },
      { updatedAt: OLD },
      { extra: true },
    ]) {
      await assertFails(as('carol').doc('duesPayments/teamA').set(payments('carol', extra)));
    }
    await assertFails(as('alice').doc('duesPayments/dm1').set(payments('alice', { groupId: 'dm1' })));
  });
});

describe('an archived team (TEAM-9)', () => {
  beforeEach(() => setGroup('teamA', { archivedAt: OLD }));

  it('takes no dues changes from anyone, super admins included, and still shows them', async () => {
    await assertFails(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'paid', paidAt: now() }));
    await assertFails(record(as('carol'), 'carol', 'd1_emma', pay('carol', 1000)));
    await assertFails(record(root(), 'root', 'd1_emma', pay('root', 1000)));
    await assertFails(editCharge(root(), 'root', 'd1_emma', { status: 'waived' }));
    await assertFails(as('alice').doc('duesPayments/teamA').set(payments('alice')));
    await assertFails(as('alice').doc('duesPayments/teamA').delete());
    await assertSucceeds(as('carol').doc('dues/d1').get());
    await assertSucceeds(listAll(as('alice'), 'dueCharges'));
    await assertSucceeds(as('dan').doc('dueCharges/d1_emma').get());
    await assertSucceeds(as('bob').doc('duesPayments/teamA').get());
  });

  it('takes them again once restored', async () => {
    await setGroup('teamA', { archivedAt: null });
    await assertSucceeds(record(as('carol'), 'carol', 'd1_emma', pay('carol', 1000)));
    await assertSucceeds(editCharge(as('carol'), 'carol', 'd1_finn', { status: 'owed', paidAt: null }));
    await assertSucceeds(as('alice').doc('duesPayments/teamA').set(payments('alice')));
  });
});
