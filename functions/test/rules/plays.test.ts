// Security rules for plays (SPEC §6.16 BOARD-4, ARCH §6.14): everyone on
// the team reads them; admins, the play makers they pick (#63), and super
// admins write them on open teams.
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
import { playBoardValues } from '../../src/shared/constants.js';

type Db = firebase.firestore.Firestore;

let env: RulesTestEnvironment;
const now = () => firebase.firestore.FieldValue.serverTimestamp();
const ts = (iso: string) => firebase.firestore.Timestamp.fromDate(new Date(iso));
const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const root = (): Db => env.authenticatedContext('root', { superAdmin: true }).firestore();

const marker = { k: 'm', id: 'a', x: 0.5, y: 0.5, s: 'team', l: 'P' };

/** A new play as the app writes it. */
const play = (uid: string, extra: object = {}, g = 'teamA') => ({
  groupId: g,
  board: 'baseball',
  variant: 'full',
  title: 'Bunt defense',
  note: '',
  steps: [{ elements: [marker] }],
  createdBy: uid,
  createdAt: now(),
  updatedAt: now(),
  ...extra,
});

// teamA: alice owner, carol admin, bob member. teamB: gina admin. A play,
// pl1, on teamA by alice.
async function seed(group: object = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const g of ['teamA', 'teamB']) {
      await db.doc(`groups/${g}`).set({ name: g, nameLower: g, settings: {}, storageBytes: 0, storageQuotaBytes: 1, ...(g === 'teamA' ? group : {}) });
    }
    const member = (g: string, uid: string, role: string) =>
      db.doc(`groupMembers/${g}_${uid}`).set({ groupId: g, uid, role, displayName: uid, photoPath: null });
    await member('teamA', 'alice', 'owner');
    await member('teamA', 'carol', 'admin');
    await member('teamA', 'bob', 'member');
    await member('teamB', 'gina', 'admin');
    await db.doc('plays/pl1').set({ ...play('alice'), createdAt: ts('2026-10-01T00:00:00Z'), updatedAt: ts('2026-10-01T00:00:00Z') });
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

describe('reading plays (BOARD-4)', () => {
  it('is for the team, and super admins', async () => {
    for (const uid of ['alice', 'carol', 'bob']) {
      await assertSucceeds(as(uid).doc('plays/pl1').get());
      await assertSucceeds(as(uid).collection('plays').where('groupId', '==', 'teamA').orderBy('updatedAt', 'desc').limit(100).get());
    }
    await assertSucceeds(root().doc('plays/pl1').get());
    await assertFails(as('gina').doc('plays/pl1').get());
    // Lists must be bounded.
    await assertFails(as('bob').collection('plays').where('groupId', '==', 'teamA').get());
  });
});

describe('drawing plays (BOARD-2, BOARD-4)', () => {
  it('is for admins and super admins, as themselves', async () => {
    await assertSucceeds(as('carol').collection('plays').add(play('carol')));
    await assertSucceeds(root().collection('plays').add(play('root')));
    await assertFails(as('bob').collection('plays').add(play('bob')));
    await assertFails(as('gina').collection('plays').add(play('gina')));
    await assertFails(as('carol').collection('plays').add(play('alice')));
  });

  it('checks what a play holds', async () => {
    const add = (extra: object) => as('alice').collection('plays').add(play('alice', extra));
    // Every board the app draws (shared/constants.json), volleyball's court
    // too (#87), and no others.
    for (const board of playBoardValues) {
      await assertSucceeds(add({ board }));
    }
    await assertFails(add({ board: 'hockey' }));
    await assertFails(add({ variant: 'third' }));
    await assertFails(add({ title: '  ' }));
    await assertFails(add({ title: 'x'.repeat(81) }));
    await assertFails(add({ note: 'x'.repeat(1001) }));
    await assertFails(add({ steps: [] }));
    await assertFails(add({ steps: Array.from({ length: 11 }, () => ({ elements: [] })) }));
    await assertFails(add({ steps: [{ elements: Array.from({ length: 151 }, () => marker) }] }));
    await assertFails(add({ steps: [{ elements: [], extra: true }] }));
    await assertFails(add({ public: true }));
    await assertSucceeds(add({ steps: Array.from({ length: 10 }, () => ({ elements: Array.from({ length: 150 }, () => marker) })) }));
  });

  it('changes and deletes are for admins too, and never move a play', async () => {
    await assertSucceeds(as('carol').doc('plays/pl1').update({ title: 'Squeeze', steps: [{ elements: [] }, { elements: [marker] }], updatedAt: now() }));
    await assertFails(as('carol').doc('plays/pl1').update({ groupId: 'teamB', updatedAt: now() }));
    await assertFails(as('carol').doc('plays/pl1').update({ createdBy: 'carol', updatedAt: now() }));
    await assertFails(as('bob').doc('plays/pl1').update({ title: 'Mine', updatedAt: now() }));
    await assertFails(as('bob').doc('plays/pl1').delete());
    await assertSucceeds(as('carol').doc('plays/pl1').delete());
  });

  it('stops on an archived team, for super admins too (TEAM-9)', async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ archivedAt: ts('2026-10-02T00:00:00Z') }));
    await assertFails(as('alice').collection('plays').add(play('alice')));
    await assertFails(root().doc('plays/pl1').update({ title: 'Late', updatedAt: now() }));
    await assertFails(as('alice').doc('plays/pl1').delete());
    await assertSucceeds(as('bob').doc('plays/pl1').get());
  });
});

describe('play makers (BOARD-4, #63)', () => {
  // dee is a member the admins made a play maker.
  beforeEach(async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('groupMembers/teamA_dee').set({ groupId: 'teamA', uid: 'dee', role: 'member', displayName: 'dee', photoPath: null, playMaker: true }),
    );
  });

  it('draw, change, and delete the team\'s plays, as themselves', async () => {
    await assertSucceeds(as('dee').collection('plays').add(play('dee')));
    await assertFails(as('dee').collection('plays').add(play('alice')));
    await assertSucceeds(as('dee').doc('plays/pl1').update({ title: 'Squeeze', updatedAt: now() }));
    await assertSucceeds(as('dee').doc('plays/pl1').delete());
  });

  it('only on their own team, and not once it is archived or a basic group', async () => {
    await assertFails(as('dee').collection('plays').add(play('dee', {}, 'teamB')));
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ archivedAt: ts('2026-10-02T00:00:00Z') }));
    await assertFails(as('dee').collection('plays').add(play('dee')));
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ archivedAt: null, kind: 'group' }));
    await assertFails(as('dee').collection('plays').add(play('dee')));
  });

  it('are made by admins only: nobody makes themselves one', async () => {
    await assertFails(as('bob').doc('groupMembers/teamA_bob').update({ playMaker: true }));
    await assertFails(as('dee').doc('groupMembers/teamA_dee').update({ playMaker: false }));
    await assertFails(as('bob').collection('plays').add(play('bob')));
  });
});

describe('basic groups (TEAM-14)', () => {
  it('have no plays, for admins and super admins too', async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ kind: 'group' }));
    await assertFails(as('alice').collection('plays').add(play('alice')));
    await assertFails(root().collection('plays').add(play('root')));
    await assertFails(as('carol').doc('plays/pl1').update({ title: 'Squeeze', updatedAt: now() }));
    await assertFails(as('carol').doc('plays/pl1').delete());
  });
});
