// Rules tests for answer links (SPEC SCHED-14, ARCH §6.15): they're for the
// answer page alone, so nobody reads or writes them from the app, not even
// the person a link is for.
// Run with: npm --prefix functions run emulators:test
import { assertFails, initializeTestEnvironment, type RulesTestEnvironment } from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

type Db = firebase.firestore.Firestore;
let env: RulesTestEnvironment;
const LINK = 'a'.repeat(64);

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-battleplan',
    firestore: { rules: readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`answerLinks/${LINK}`).set({ uid: 'maria', groupId: 'teamA', eventId: 'e1', participants: [] });
  });
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid: string): Db => env.authenticatedContext(uid).firestore();

describe('answer links (SCHED-14)', () => {
  it('are closed to everyone, the person they are for included', async () => {
    await assertFails(as('maria').doc(`answerLinks/${LINK}`).get());
    await assertFails(as('maria').collection('answerLinks').where('uid', '==', 'maria').limit(10).get());
    await assertFails(as('maria').doc(`answerLinks/${'b'.repeat(64)}`).set({ uid: 'maria', groupId: 'teamA', eventId: 'e1' }));
    await assertFails(env.unauthenticatedContext().firestore().doc(`answerLinks/${LINK}`).get());
  });
});
