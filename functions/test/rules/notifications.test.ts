// Rules tests for notifications (M4, SPEC §6.9): push devices, the
// notification center, per-team level and mute, and the global switches.
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
const now = () => firebase.firestore.FieldValue.serverTimestamp();
const at = (ms: number) => firebase.firestore.Timestamp.fromMillis(Date.now() + ms);
const INSTALL = 'abcdefghijklmnop1234';

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
    await db.doc('groups/teamA').set({ name: 'Thunder', teamType: 'adult' });
    await db.doc('groupMembers/teamA_alice').set({ groupId: 'teamA', uid: 'alice', role: 'owner', displayName: 'Alice', notificationLevel: 'all' });
    await db.doc('groupMembers/teamA_bob').set({ groupId: 'teamA', uid: 'bob', role: 'member', displayName: 'Bob', notificationLevel: 'all' });
    await db.doc(`devices/${INSTALL}`).set({ uid: 'alice', token: 't1', platform: 'web', appVersion: '1.0.0', updatedAt: at(0) });
    await db.doc('notifications/n1_alice').set({ uid: 'alice', groupId: 'teamA', type: 'reply', read: false, createdAt: at(0) });
    await db.doc('users/alice').set({
      displayName: 'Alice', displayNameLower: 'alice', themeMode: 'system', photoPath: null,
      notificationPrefs: { messages: true, replies: true, events: true },
    });
  });
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const device = (uid: string, extra: object = {}) => ({
  uid, token: 'tok', platform: 'ios', appVersion: '1.2.3', updatedAt: now(), ...extra,
});

describe('push devices (NOTIF-10)', () => {
  it('lets people register, refresh, and remove their own device', async () => {
    await assertSucceeds(as('bob').doc('devices/zyxwvutsrqponmlk9876').set(device('bob')));
    await assertSucceeds(as('bob').doc('devices/zyxwvutsrqponmlk9876').set(device('bob', { token: 'tok2' })));
    await assertSucceeds(as('bob').doc('devices/zyxwvutsrqponmlk9876').delete());
  });

  it("keeps other people's devices private", async () => {
    await assertFails(as('bob').doc(`devices/${INSTALL}`).get());
    await assertFails(as('bob').doc(`devices/${INSTALL}`).delete());
    await assertFails(as('bob').collection('devices').where('uid', '==', 'alice').limit(10).get());
  });

  it('refuses bad devices', async () => {
    await assertFails(as('bob').doc('devices/zyxwvutsrqponmlk9876').set(device('alice')));
    await assertFails(as('bob').doc('devices/zyxwvutsrqponmlk9876').set(device('bob', { platform: 'tv' })));
    await assertFails(as('bob').doc('devices/zyxwvutsrqponmlk9876').set(device('bob', { extra: 1 })));
    await assertFails(as('bob').doc('devices/zyxwvutsrqponmlk9876').set(device('bob', { updatedAt: at(-86_400_000) })));
    await assertFails(as('bob').doc('devices/short').set(device('bob')));
  });
});

describe('notification center (NOTIF-11)', () => {
  it('shows people only their own items, in bounded queries', async () => {
    await assertSucceeds(as('alice').doc('notifications/n1_alice').get());
    await assertSucceeds(
      as('alice').collection('notifications').where('uid', '==', 'alice').orderBy('createdAt', 'desc').limit(30).get(),
    );
    await assertFails(as('alice').collection('notifications').where('uid', '==', 'alice').get());
    await assertFails(as('bob').doc('notifications/n1_alice').get());
  });

  it('lets people only mark their items read', async () => {
    await assertSucceeds(as('alice').doc('notifications/n1_alice').update({ read: true }));
    await assertFails(as('alice').doc('notifications/n1_alice').update({ read: false }));
    await assertFails(as('alice').doc('notifications/n1_alice').update({ body: 'x' }));
    await assertFails(as('bob').doc('notifications/n1_alice').update({ read: true }));
    await assertFails(as('alice').doc('notifications/new').set({ uid: 'alice', read: false }));
    await assertFails(as('alice').doc('notifications/n1_alice').delete());
  });
});

describe('per-team level and mute (NOTIF-3)', () => {
  const member = (uid: string) => as(uid).doc(`groupMembers/teamA_${uid}`);

  it('lets people set their own level and mute', async () => {
    await assertSucceeds(member('bob').update({ notificationLevel: 'important' }));
    await assertSucceeds(member('bob').update({ notificationLevel: 'none' }));
    await assertSucceeds(member('bob').update({ mutedUntil: at(3_600_000) }));
    await assertSucceeds(member('bob').update({ mutedUntil: firebase.firestore.Timestamp.fromMillis(253402214400000) }));
    await assertSucceeds(member('bob').update({ mutedUntil: null }));
    await assertSucceeds(member('bob').update({ lastReadAt: now() }));
    // Read partway up the chat (CHAT-9): the newest message on screen.
    await assertSucceeds(member('bob').update({ lastReadAt: at(-60_000) }));
  });

  it('refuses bad values and other people', async () => {
    await assertFails(member('bob').update({ notificationLevel: 'loud' }));
    await assertFails(member('bob').update({ mutedUntil: at(-60_000) }));
    await assertFails(member('bob').update({ mutedUntil: 'tomorrow' }));
    await assertFails(member('bob').update({ lastReadAt: at(86_400_000) }));
    await assertFails(member('bob').update({ lastReadAt: 'now' }));
    await assertFails(as('bob').doc('groupMembers/teamA_alice').update({ notificationLevel: 'none' }));
  });
});

describe('global switches (NOTIF-4)', () => {
  it('lets people flip their own switches, including the old events key', async () => {
    await assertSucceeds(as('alice').doc('users/alice').update({ 'notificationPrefs.messages': false }));
    await assertSucceeds(as('alice').doc('users/alice').update({ 'notificationPrefs.eventsNew': false }));
    await assertSucceeds(as('alice').doc('users/alice').update({ themeMode: 'dark' }));
  });

  it('refuses unknown switches and non-true/false values', async () => {
    await assertFails(as('alice').doc('users/alice').update({ 'notificationPrefs.marketing': true }));
    await assertFails(as('alice').doc('users/alice').update({ 'notificationPrefs.replies': 'yes' }));
  });
});
