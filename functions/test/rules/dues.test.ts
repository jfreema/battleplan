// Security rules for dues (SPEC DUES-1..DUES-4): what a team's admins ask
// its players, or a basic group's members, to pay, and who paid. Admins, and
// super admins (§3), see every due and charge and mark charges paid;
// everyone else sees only their own charge, or their player's. Dues and
// charges are created, edited, and deleted only by the saveDue and deleteDue
// callables (test/emulator/dues.test.ts). Everyone on the team reads how
// to pay (duesPayments); only admins write it. Archived teams are read-only
// (TEAM-9).
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
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
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

// teamA (a team): alice owner, carol admin, bob, dan, and erin members.
// Players emma (dan is her guardian), finn (erin is the player, 'self'),
// and gus (nobody's). Due d1 with charges d1_emma, d1_finn, d1_gus.
// clubC (a basic group): hana owner, ivan and jo members; due dC with
// charges dC_ivan and dC_jo. teamB: gina admin, player zed. teamA has a
// duesPayments doc. root is a super admin on no team.
async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const group = (g: string, kind: string) =>
      db.doc(`groups/${g}`).set({ name: g, nameLower: g.toLowerCase(), kind, settings: {}, storageBytes: 0, storageQuotaBytes: 1 });
    await group('teamA', 'team');
    await group('teamB', 'team');
    await group('clubC', 'group');
    await db.doc('groups/dm1').set({ name: '', nameLower: '', kind: 'direct', uids: ['alice', 'bob'], settings: {} });
    const member = (g: string, uid: string, role: string) =>
      db.doc(`groupMembers/${g}_${uid}`).set({ groupId: g, uid, role, displayName: uid, photoPath: null });
    await member('teamA', 'alice', 'owner');
    await member('teamA', 'carol', 'admin');
    await member('teamA', 'bob', 'member');
    await member('teamA', 'dan', 'member');
    await member('teamA', 'erin', 'member');
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

  it("never change a charge's terms, name, or person in the app", async () => {
    for (const changes of [
      { title: 'Jerseys' },
      { amountCents: 2000 },
      { dueOn: null },
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
    await assertSucceeds(editCharge(as('carol'), 'carol', 'd1_emma', { status: 'paid', paidAt: now() }));
    await assertSucceeds(as('alice').doc('duesPayments/teamA').set(payments('alice')));
  });
});
