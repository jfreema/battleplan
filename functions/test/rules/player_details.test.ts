// Rules tests for player details (PLAYER-12): who reads, lists, writes,
// and deletes them, their fields and sizes (kept in step with Limits in
// shared/constants.json), the date of birth, and no health data. Run
// with:
//   npm --prefix functions run emulators:test
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
const del = () => firebase.firestore.FieldValue.delete();
const ts = (iso: string) => firebase.firestore.Timestamp.fromDate(new Date(iso));
const SAVED = ts('2026-09-01T00:00:00Z');

const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const anon = (): Db => env.unauthenticatedContext().firestore();
const root = (): Db => env.authenticatedContext('root', { superAdmin: true }).firestore();

/** A date [days] from now, as 'YYYY-MM-DD' in UTC. */
const dayFromNow = (days: number) => new Date(Date.now() + days * 86_400_000).toISOString().slice(0, 10);

// teamA: alice owns it, carol is an admin, bob a member with no link, dan
// is emma's guardian, and sam is the player sam-p ('self'). emma (an old
// player with no status) has details; sam-p has none yet. zoe is a pending
// player bob proposed. teamB: gina is its admin. nina is on no team; root
// is a super admin on no team.
async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const g of ['teamA', 'teamB']) {
      await db.doc(`groups/${g}`).set({ name: g, nameLower: g.toLowerCase(), kind: 'team', archivedAt: null, suspendedAt: null });
    }
    const member = (g: string, uid: string, role: string) =>
      db.doc(`groupMembers/${g}_${uid}`).set({ groupId: g, uid, role, displayName: uid });
    await member('teamA', 'alice', 'owner');
    await member('teamA', 'carol', 'admin');
    await member('teamA', 'bob', 'member');
    await member('teamA', 'dan', 'member');
    await member('teamA', 'sam', 'member');
    await member('teamB', 'gina', 'admin');
    await db.doc('players/emma').set({ groupId: 'teamA', displayName: 'Emma', displayNameLower: 'emma' });
    await db.doc('players/sam-p').set({ groupId: 'teamA', displayName: 'Sam', displayNameLower: 'sam', status: 'active' });
    await db.doc('players/zoe').set({
      groupId: 'teamA', displayName: 'Zoe', displayNameLower: 'zoe', status: 'pending', proposedBy: 'bob', proposedRelation: 'guardian',
    });
    await db.doc('players/gus').set({ groupId: 'teamB', displayName: 'Gus', displayNameLower: 'gus', status: 'active' });
    await db.doc('playerGuardians/emma_dan').set({ playerId: 'emma', groupId: 'teamA', uid: 'dan', relation: 'guardian' });
    await db.doc('playerGuardians/sam-p_sam').set({ playerId: 'sam-p', groupId: 'teamA', uid: 'sam', relation: 'self' });
    await db.doc('playerDetails/emma').set({
      groupId: 'teamA',
      dateOfBirth: '2016-04-01',
      emergencyContacts: [{ name: 'Dan Lee', phone: '555-0100', relationship: 'Dad' }],
      notes: 'Wears glasses',
      updatedBy: 'dan',
      updatedAt: SAVED,
    });
    await db.doc('playerDetails/gus').set({ groupId: 'teamB', emergencyContacts: [], updatedBy: 'gina', updatedAt: SAVED });
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

const setTeam = (fields: object) =>
  env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update(fields));

/** The medical keys the app once wrote, which it now deletes on save. */
const MEDICAL = ['medicalNotes', 'medicalConsentAt', 'medicalConsentBy'];
/** What the app writes on save (PLAYER-12): no health data, and any left
 * from before deleted. */
const details = (uid: string, extra: object = {}) => ({
  groupId: 'teamA',
  dateOfBirth: '2016-04-01',
  emergencyContacts: [{ name: 'Dan Lee', phone: '555-0100', relationship: 'Dad' }],
  medicalNotes: del(),
  medicalConsentAt: del(),
  medicalConsentBy: del(),
  notes: 'Wears glasses',
  updatedBy: uid,
  updatedAt: now(),
  ...extra,
});
/** [data] without [key]. */
const without = (data: Record<string, unknown>, key: string) => Object.fromEntries(Object.entries(data).filter(([k]) => k !== key));
/** The app's save: one set with merge. */
const save = (uid: string, playerId: string, data: object) =>
  as(uid).doc(`playerDetails/${playerId}`).set(data, { merge: true });
const list = (db: Db, groupId = 'teamA') => db.collection('playerDetails').where('groupId', '==', groupId).limit(100).get();

describe('who reads them', () => {
  it("lets the team's admins, the player's linked members, and super admins read them", async () => {
    for (const uid of ['alice', 'carol', 'dan']) await assertSucceeds(as(uid).doc('playerDetails/emma').get());
    await assertSucceeds(root().doc('playerDetails/emma').get());
    await assertSucceeds(as('sam').doc('playerDetails/sam-p').get());
  });

  it('shows nothing to other members, other teams, people on no team, or signed-out visitors', async () => {
    await assertFails(as('bob').doc('playerDetails/emma').get());
    await assertFails(as('sam').doc('playerDetails/emma').get());
    await assertFails(as('dan').doc('playerDetails/sam-p').get());
    await assertFails(as('gina').doc('playerDetails/emma').get());
    await assertFails(as('carol').doc('playerDetails/gus').get());
    await assertFails(as('nina').doc('playerDetails/emma').get());
    await assertFails(anon().doc('playerDetails/emma').get());
  });

  it('reads as not found, not refused, for a player with no details yet, and for a pending player', async () => {
    await assertSucceeds(as('sam').doc('playerDetails/sam-p').get());
    await assertSucceeds(as('carol').doc('playerDetails/sam-p').get());
    await assertSucceeds(as('carol').doc('playerDetails/zoe').get());
    await assertFails(as('bob').doc('playerDetails/sam-p').get());
    // Proposing a player links nobody until it's approved.
    await assertFails(as('bob').doc('playerDetails/zoe').get());
    await assertFails(as('carol').doc('playerDetails/nobody').get());
  });

  it("lists a team's details for its admins and super admins only, by groupId and bounded", async () => {
    await assertSucceeds(list(as('carol')));
    await assertSucceeds(list(as('alice')));
    await assertSucceeds(list(root()));
    await assertSucceeds(
      as('carol').collection('playerDetails').where('groupId', '==', 'teamA')
        .orderBy(firebase.firestore.FieldPath.documentId()).limit(100).get(),
    );
    await assertFails(list(as('dan')));
    await assertFails(list(as('sam')));
    await assertFails(list(as('bob')));
    await assertFails(list(as('gina')));
    await assertFails(list(as('carol'), 'teamB'));
    await assertFails(list(anon()));
    await assertFails(as('carol').collection('playerDetails').where('groupId', '==', 'teamA').get());
    await assertFails(as('carol').collection('playerDetails').where('groupId', '==', 'teamA').limit(101).get());
    await assertFails(as('carol').collection('playerDetails').limit(100).get());
    await assertFails(root().collection('playerDetails').limit(100).get());
  });

  it("keeps them readable on an archived team, and closed to a suspended team's members", async () => {
    await setTeam({ archivedAt: ts('2026-10-01T00:00:00Z') });
    await assertSucceeds(as('dan').doc('playerDetails/emma').get());
    await assertSucceeds(list(as('carol')));
    await setTeam({ archivedAt: null, suspendedAt: ts('2026-10-01T00:00:00Z') });
    for (const uid of ['alice', 'carol', 'dan']) await assertFails(as(uid).doc('playerDetails/emma').get());
    await assertFails(list(as('carol')));
    await assertSucceeds(root().doc('playerDetails/emma').get());
  });
});

describe('who writes them', () => {
  it('lets admins, guardians, and the member who is the player save them', async () => {
    await assertSucceeds(save('carol', 'emma', details('carol')));
    await assertSucceeds(save('alice', 'emma', details('alice', { notes: null })));
    await assertSucceeds(save('dan', 'emma', details('dan')));
    await assertSucceeds(save('sam', 'sam-p', details('sam')));
    await assertSucceeds(save('carol', 'sam-p', details('carol', { dateOfBirth: null, emergencyContacts: [] })));
  });

  it('takes the fullest save the app makes: two contacts and notes', async () => {
    await assertSucceeds(save('dan', 'emma', details('dan', {
      emergencyContacts: [
        { name: 'Dan Lee', phone: '555-0100', relationship: 'Dad' },
        { name: 'Erin Lee', phone: '555-0101' },
      ],
    })));
  });

  it('refuses other members, other teams, people on no team, and signed-out visitors', async () => {
    await assertFails(save('bob', 'emma', details('bob')));
    await assertFails(save('sam', 'emma', details('sam')));
    await assertFails(save('dan', 'sam-p', details('dan')));
    await assertFails(save('gina', 'emma', details('gina')));
    await assertFails(save('nina', 'sam-p', details('nina')));
    await assertFails(anon().doc('playerDetails/sam-p').set(details('anon'), { merge: true }));
  });

  it('lets super admins read but never write', async () => {
    await assertFails(root().doc('playerDetails/sam-p').set(details('root'), { merge: true }));
    await assertFails(root().doc('playerDetails/emma').set(details('root'), { merge: true }));
    await assertFails(root().doc('playerDetails/emma').delete());
  });

  it('refuses details for a pending player, a missing player, or a player on another team', async () => {
    await assertFails(save('carol', 'zoe', details('carol')));
    await assertFails(save('bob', 'zoe', details('bob')));
    await assertFails(save('carol', 'nobody', details('carol')));
    await assertFails(save('carol', 'gus', details('carol')));
    await assertFails(save('gina', 'gus', details('gina')));
    // gina's own team, where the rules allow her.
    await assertSucceeds(save('gina', 'gus', details('gina', { groupId: 'teamB' })));
  });

  it('keeps groupId the player’s, and never changes it', async () => {
    await assertFails(save('carol', 'sam-p', details('carol', { groupId: 'teamB' })));
    await assertFails(save('gina', 'sam-p', details('gina', { groupId: 'teamB' })));
    await assertFails(save('carol', 'sam-p', without(details('carol'), 'groupId')));
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('playerDetails/gus').update({ groupId: 'teamA' }));
    // A stray doc claiming another team can't be taken over or kept.
    await assertFails(save('gina', 'gus', details('gina', { groupId: 'teamB' })));
  });

  it("freezes them on an archived team, and on a suspended one", async () => {
    await setTeam({ archivedAt: ts('2026-10-01T00:00:00Z') });
    await assertFails(save('carol', 'sam-p', details('carol')));
    await assertFails(save('dan', 'emma', details('dan')));
    await assertFails(as('carol').doc('playerDetails/emma').delete());
    await setTeam({ archivedAt: null, suspendedAt: ts('2026-10-01T00:00:00Z') });
    await assertFails(save('carol', 'sam-p', details('carol')));
    await assertFails(as('dan').doc('playerDetails/emma').delete());
    await setTeam({ suspendedAt: null });
    await assertSucceeds(save('carol', 'sam-p', details('carol')));
  });

  it('stamps who saved and when', async () => {
    await assertFails(save('carol', 'sam-p', details('carol', { updatedBy: 'dan' })));
    await assertFails(save('carol', 'sam-p', details('carol', { updatedAt: ts('2026-01-01T00:00:00Z') })));
    await assertFails(save('carol', 'sam-p', without(details('carol'), 'updatedBy')));
    await assertFails(save('carol', 'sam-p', without(details('carol'), 'updatedAt')));
  });

  it('lets the same people delete them, and deleting none is no error', async () => {
    await assertFails(as('bob').doc('playerDetails/emma').delete());
    await assertFails(as('gina').doc('playerDetails/emma').delete());
    await assertFails(as('sam').doc('playerDetails/emma').delete());
    await assertSucceeds(as('dan').doc('playerDetails/emma').delete());
    await assertSucceeds(as('sam').doc('playerDetails/sam-p').delete());
    await assertSucceeds(as('carol').doc('playerDetails/sam-p').delete());
    await assertFails(as('carol').doc('playerDetails/zoe').delete());
  });
});

describe('their fields and sizes (Limits)', () => {
  const contact = (extra: object = {}) => ({ name: 'Dan Lee', phone: '555-0100', ...extra });
  const withContacts = (contacts: unknown) => details('carol', { emergencyContacts: contacts });

  it('takes only the known keys', async () => {
    await assertFails(save('carol', 'sam-p', details('carol', { birthdate: '2016-04-01' })));
    await assertFails(save('carol', 'sam-p', details('carol', { age: 10 })));
    await assertFails(save('carol', 'sam-p', details('carol', { allergies: 'Peanuts' })));
  });

  it('allows notes up to their limits', async () => {
    await assertSucceeds(save('carol', 'sam-p', details('carol', { notes: 'x'.repeat(Limits.playerNotesMax) })));
    await assertFails(save('carol', 'sam-p', details('carol', { notes: 'x'.repeat(Limits.playerNotesMax + 1) })));
    await assertFails(save('carol', 'sam-p', details('carol', { notes: 42 })));
  });

  it(`allows up to ${Limits.emergencyContactsMax} emergency contacts, each a name and a phone number`, async () => {
    const most = Array.from({ length: Limits.emergencyContactsMax }, () => contact());
    await assertSucceeds(save('carol', 'sam-p', withContacts(most)));
    await assertFails(save('carol', 'sam-p', withContacts([...most, contact()])));
    await assertSucceeds(save('carol', 'sam-p', withContacts([contact({ relationship: null })])));
    await assertFails(save('carol', 'sam-p', withContacts([{ name: 'Dan Lee' }])));
    await assertFails(save('carol', 'sam-p', withContacts([{ phone: '555-0100' }])));
    await assertFails(save('carol', 'sam-p', withContacts([contact({ name: '' })])));
    await assertFails(save('carol', 'sam-p', withContacts([contact({ phone: '   ' })])));
    await assertFails(save('carol', 'sam-p', withContacts([contact({ email: 'dan@example.com' })])));
    await assertFails(save('carol', 'sam-p', withContacts([contact(), 'Erin 555-0101'])));
    await assertFails(save('carol', 'sam-p', withContacts(contact())));
    await assertFails(save('carol', 'sam-p', withContacts([contact({ phone: 5550100 })])));
  });

  it('keeps each contact field to its limit', async () => {
    const cases: [string, number][] = [
      ['name', Limits.emergencyContactNameMax],
      ['phone', Limits.emergencyContactPhoneMax],
      ['relationship', Limits.emergencyContactRelationshipMax],
    ];
    for (const [field, max] of cases) {
      await assertSucceeds(save('carol', 'sam-p', withContacts([contact({ [field]: 'x'.repeat(max) })])));
      await assertFails(save('carol', 'sam-p', withContacts([contact({ [field]: 'x'.repeat(max + 1) })])));
    }
  });
});

describe('date of birth', () => {
  const dob = (value: unknown) => save('carol', 'sam-p', details('carol', { dateOfBirth: value }));

  it("takes a past date as 'YYYY-MM-DD', or none", async () => {
    await assertSucceeds(dob('2016-04-01'));
    await assertSucceeds(dob('2008-02-29'));
    await assertSucceeds(dob(dayFromNow(-2)));
    await assertSucceeds(dob(null));
  });

  it('refuses other formats and dates that don’t exist', async () => {
    for (const bad of ['2016-4-1', '2016/04/01', '04/01/2016', '2016-04-01T00:00:00Z', '2016-13-01', '2016-00-10',
      '2016-04-32', '2016-02-30', '2015-02-29', 'soon', '']) {
      await assertFails(dob(bad));
    }
    await assertFails(dob(ts('2016-04-01T00:00:00Z')));
    await assertFails(dob(20160401));
  });

  it('refuses a date in the future', async () => {
    await assertFails(dob(dayFromNow(2)));
    await assertFails(dob('2999-01-01'));
  });
});

describe('no health data', () => {
  /** A record saved before medical notes were removed. */
  const legacy = () =>
    env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('playerDetails/emma').update({
      medicalNotes: 'Peanut allergy', medicalConsentAt: SAVED, medicalConsentBy: 'dan',
    }));
  /** [data] without the medical keys' deletes: a save that leaves them be. */
  const keeping = (data: Record<string, unknown>) => MEDICAL.reduce((d, k) => without(d, k), data);

  it('refuses medical notes and their consent, with any value', async () => {
    for (const key of MEDICAL) {
      for (const value of ['Peanut allergy', '', null, now(), 'sam']) {
        await assertFails(save('sam', 'sam-p', details('sam', { [key]: value })));
        await assertFails(save('carol', 'emma', details('carol', { [key]: value })));
      }
    }
    await assertFails(save('sam', 'sam-p', details('sam', {
      medicalNotes: 'Asthma', medicalConsentAt: now(), medicalConsentBy: 'sam',
    })));
  });

  it('takes a save without the deletes on a record with none', async () => {
    await assertSucceeds(save('carol', 'emma', keeping(details('carol'))));
    await assertSucceeds(save('sam', 'sam-p', keeping(details('sam'))));
  });

  it("refuses a save that keeps an old record's medical notes, and takes the app's, which deletes them", async () => {
    await legacy();
    await assertFails(save('dan', 'emma', keeping(details('dan'))));
    await assertSucceeds(save('dan', 'emma', details('dan')));
    await env.withSecurityRulesDisabled(async (ctx) => {
      const data = (await ctx.firestore().doc('playerDetails/emma').get()).data() ?? {};
      for (const key of MEDICAL) if (key in data) throw new Error(`${key} is still there`);
    });
  });

  it('still lets the same people delete an old record with medical notes', async () => {
    await legacy();
    await assertSucceeds(as('dan').doc('playerDetails/emma').delete());
  });
});
