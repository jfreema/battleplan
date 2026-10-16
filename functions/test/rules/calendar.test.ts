// Rules tests for calendar links (SPEC SCHED-11, ARCH §6.15): a link's ID
// is its secret, so only its owner reads it; only Functions write links,
// and teams' cached calendars are for the feed alone.
// Run with: npm --prefix functions run emulators:test
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
const TOKEN = 'Xk3v9QmZp0aB1cD2eF3gH4iJ5kL6mN7oP8qR9sT0uVw';

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-battleplan',
    firestore: { rules: readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc('groups/teamA').set({ name: 'Thunder', kind: 'team' });
    await db.doc('groupMembers/teamA_alice').set({ groupId: 'teamA', uid: 'alice', role: 'owner' });
    await db.doc('groupMembers/teamA_bob').set({ groupId: 'teamA', uid: 'bob', role: 'member' });
    await db.doc(`calendarLinks/${TOKEN}`).set({ uid: 'alice', groupId: 'teamA', createdAt: new Date() });
    await db.doc('teamCalendars/teamA').set({ groupId: 'teamA', events: [], builtAt: new Date() });
  });
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const anon = (): Db => env.unauthenticatedContext().firestore();

describe('calendar links (SCHED-11)', () => {
  it('lets the owner read and list their own links', async () => {
    await assertSucceeds(as('alice').doc(`calendarLinks/${TOKEN}`).get());
    await assertSucceeds(as('alice').collection('calendarLinks').where('uid', '==', 'alice').limit(100).get());
  });

  it("keeps a link from anyone else, teammates included", async () => {
    await assertFails(as('bob').doc(`calendarLinks/${TOKEN}`).get());
    await assertFails(as('bob').collection('calendarLinks').where('uid', '==', 'alice').limit(100).get());
    await assertFails(as('bob').collection('calendarLinks').where('groupId', '==', 'teamA').limit(100).get());
    await assertFails(anon().doc(`calendarLinks/${TOKEN}`).get());
  });

  it('refuses an unbounded list, even of your own', async () => {
    await assertFails(as('alice').collection('calendarLinks').where('uid', '==', 'alice').get());
  });

  it('leaves making, resetting, and turning off links to setCalendarLink', async () => {
    const mine = { uid: 'alice', groupId: 'teamA', createdAt: new Date() };
    await assertFails(as('alice').doc('calendarLinks/aWeakTokenOfMyOwnChoosing0123456789abcdefg').set(mine));
    await assertFails(as('alice').doc(`calendarLinks/${TOKEN}`).update({ groupId: null }));
    await assertFails(as('alice').doc(`calendarLinks/${TOKEN}`).delete());
  });

  it("keeps teams' cached calendars to the feed", async () => {
    await assertFails(as('alice').doc('teamCalendars/teamA').get());
    await assertFails(as('alice').doc('teamCalendars/teamA').set({ events: [] }));
    await assertFails(anon().doc('teamCalendars/teamA').get());
  });
});
