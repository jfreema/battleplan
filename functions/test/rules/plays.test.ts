// Security rules for plays (SPEC §6.16 BOARD-4, ARCH §6.14): everyone on
// the team reads them; admins, and super admins, write them on open teams.
// Shared plays (BOARD-6) are read by anyone with the link and written only
// by sharePlay.
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

type Db = firebase.firestore.Firestore;

let env: RulesTestEnvironment;
const now = () => firebase.firestore.FieldValue.serverTimestamp();
const ts = (iso: string) => firebase.firestore.Timestamp.fromDate(new Date(iso));
const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const anon = (): Db => env.unauthenticatedContext().firestore();
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
    // pl2 is shared (BOARD-6).
    await db.doc('plays/pl2').set({
      ...play('alice'),
      shareId: 'Ab3_x-9Kq2Zw',
      createdAt: ts('2026-10-01T00:00:00Z'),
      updatedAt: ts('2026-10-01T00:00:00Z'),
    });
    await db.doc('sharedPlays/Ab3_x-9Kq2Zw').set({
      board: 'baseball',
      variant: 'full',
      title: 'Bunt defense',
      note: '',
      steps: [{ elements: [marker] }],
      hasImage: false,
    });
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

describe('shared plays (BOARD-6)', () => {
  it('anyone with the link reads one, signed in or not, but nobody lists them', async () => {
    await assertSucceeds(anon().doc('sharedPlays/Ab3_x-9Kq2Zw').get());
    await assertSucceeds(as('gina').doc('sharedPlays/Ab3_x-9Kq2Zw').get());
    await assertSucceeds(anon().doc('sharedPlays/Zz3_x-9Kq2Zw').get());
    await assertFails(anon().collection('sharedPlays').limit(10).get());
    await assertFails(as('alice').collection('sharedPlays').limit(10).get());
  });

  it('only sharePlay writes them', async () => {
    const copy = { board: 'blank', variant: 'full', title: 'Mine', note: '', steps: [{ elements: [] }] };
    await assertFails(anon().doc('sharedPlays/Yy3_x-9Kq2Zw').set(copy));
    await assertFails(as('alice').doc('sharedPlays/Yy3_x-9Kq2Zw').set(copy));
    await assertFails(root().doc('sharedPlays/Yy3_x-9Kq2Zw').set(copy));
    await assertFails(as('alice').doc('sharedPlays/Ab3_x-9Kq2Zw').update({ title: 'Mine' }));
    await assertFails(root().doc('sharedPlays/Ab3_x-9Kq2Zw').delete());
  });

  it("a play's link is sharePlay's to set; a shared play still changes", async () => {
    await assertFails(as('alice').collection('plays').add(play('alice', { shareId: 'Ab3_x-9Kq2Zw' })));
    await assertFails(as('alice').doc('plays/pl1').update({ shareId: 'Ab3_x-9Kq2Zw', updatedAt: now() }));
    await assertFails(as('alice').doc('plays/pl2').update({ shareId: 'Yy3_x-9Kq2Zw', updatedAt: now() }));
    await assertSucceeds(as('carol').doc('plays/pl2').update({ title: 'Squeeze', updatedAt: now() }));
    await assertSucceeds(as('bob').doc('plays/pl2').get());
    await assertSucceeds(as('carol').doc('plays/pl2').delete());
  });
});
