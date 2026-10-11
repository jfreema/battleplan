// Rules tests for the Plus plan (roadmap task 166, SPEC §6.14): every Plus
// feature is refused on Free teams, after a license ends, and to the wrong
// person, even when the database is called directly. Run with:
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

type Db = firebase.firestore.Firestore;
let env: RulesTestEnvironment;
const GB = 1024 ** 3;
const now = () => firebase.firestore.FieldValue.serverTimestamp();
const at = (ms: number) => firebase.firestore.Timestamp.fromMillis(Date.now() + ms);

// plusTeam is on Plus (alice owns it, bob is a member); freeTeam is on Free;
// lapsedTeam's plan says Plus but its end date has passed. Alice owns all.
beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-battleplan',
    firestore: { rules: readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8') },
    storage: { rules: readFileSync(resolve(process.cwd(), '../storage.rules'), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const team = (name: string, plan: object) => ({
      name,
      nameLower: name.toLowerCase(),
      sport: 'baseball',
      color: '#2F5BEA',
      photoPath: null,
      teamType: 'adult',
      settings: { membersCanUploadDocs: true, defaultReminderOffsets: [1440] },
      storageBytes: 0,
      storageQuotaBytes: 25 * GB,
      plan,
    });
    await db.doc('groups/plusTeam').set(team('Plus', { tier: 'plus', endsAt: at(86_400_000), licenseId: 'l1', holderId: 'alice' }));
    await db.doc('groups/freeTeam').set(team('Free', { tier: 'free', endsAt: null }));
    await db.doc('groups/lapsedTeam').set(team('Lapsed', { tier: 'plus', endsAt: at(-60_000), licenseId: 'l2', holderId: 'alice' }));
    for (const g of ['plusTeam', 'freeTeam', 'lapsedTeam']) {
      await db.doc(`groupMembers/${g}_alice`).set({ groupId: g, uid: 'alice', role: 'owner', displayName: 'Alice' });
      await db.doc(`groupMembers/${g}_bob`).set({ groupId: g, uid: 'bob', role: 'member', displayName: 'Bob' });
      await db.doc(`messages/${g}_m`).set({ groupId: g, authorId: 'alice', authorName: 'Alice', type: 'text', text: 'Hi', reactions: {} });
    }
    await db.doc('messages/plusTeam_gone').set({
      groupId: 'plusTeam', authorId: 'alice', authorName: 'Alice', type: 'text', text: '', reactions: {}, deletedAt: at(-1000),
    });
    await db.doc('licenses/l1').set({ holderId: 'alice', groupId: 'plusTeam', tier: 'plus', endsAt: at(86_400_000) });
  });
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const editAs = (uid: string, id: string, text = 'Edited') =>
  as(uid).doc(`messages/${id}`).update({ text, editedAt: now() });

describe('licenses and the plan cache (PLAN-1 to PLAN-3)', () => {
  it('lets the holder and super admins read a license, and nobody write one', async () => {
    await assertSucceeds(as('alice').doc('licenses/l1').get());
    await assertSucceeds(env.authenticatedContext('root', { superAdmin: true }).firestore().doc('licenses/l1').get());
    await assertFails(as('bob').doc('licenses/l1').get());
    await assertFails(as('alice').doc('licenses/l1').update({ endsAt: at(10 * 365 * 86_400_000) }));
    await assertFails(as('alice').doc('licenses/new').set({ holderId: 'alice', groupId: 'freeTeam' }));
  });

  it("never lets admins give their own team Plus or more storage", async () => {
    await assertFails(as('alice').doc('groups/freeTeam').update({ plan: { tier: 'plus', endsAt: at(86_400_000) } }));
    await assertFails(as('alice').doc('groups/freeTeam').update({ storageQuotaBytes: 100 * GB }));
  });
});

describe('editing messages (PLAN-6)', () => {
  it('lets the author edit on a Plus team', async () => {
    await assertSucceeds(editAs('alice', 'plusTeam_m'));
  });

  it('refuses edits on Free, after Plus ends, by others, and on deleted messages', async () => {
    await assertFails(editAs('alice', 'freeTeam_m'));
    await assertFails(editAs('alice', 'lapsedTeam_m'));
    await assertFails(editAs('bob', 'plusTeam_m'));
    await assertFails(editAs('alice', 'plusTeam_gone'));
    await assertFails(as('alice').doc('messages/plusTeam_m').update({ text: 'x', editedAt: at(-86_400_000) }));
    await assertFails(as('alice').doc('messages/plusTeam_m').update({ text: 'x', editedAt: now(), authorName: 'Boss' }));
  });
});

describe('more reactions (PLAN-7)', () => {
  const react = (uid: string, g: string, r: string) => as(uid).doc(`messages/${g}_m`).update({ [`reactions.${uid}`]: r });

  it('allows the free four everywhere and the 12 more only on Plus', async () => {
    await assertSucceeds(react('bob', 'freeTeam', 'love'));
    await assertSucceeds(react('bob', 'plusTeam', 'trophy'));
    await assertFails(react('bob', 'freeTeam', 'trophy'));
    await assertFails(react('bob', 'lapsedTeam', 'trophy'));
    await assertFails(react('bob', 'plusTeam', 'skull'));
  });
});

describe('chat look (PLAN-8)', () => {
  const look = (uid: string, g: string, theme: object) => as(uid).doc(`groups/${g}`).update({ chatTheme: theme });
  const good = { bubbleColor: '#0F8A5F', background: 'pattern', backgroundPath: null };

  it("lets a Plus team's admins set it", async () => {
    await assertSucceeds(look('alice', 'plusTeam', good));
    await assertSucceeds(look('alice', 'plusTeam', { bubbleColor: null, background: 'photo', backgroundPath: 'groups/plusTeam/theme/1.jpg' }));
  });

  it('refuses it on Free, after Plus ends, for members, and with bad values', async () => {
    await assertFails(look('alice', 'freeTeam', good));
    await assertFails(look('alice', 'lapsedTeam', good));
    await assertFails(look('bob', 'plusTeam', good));
    await assertFails(look('alice', 'plusTeam', { ...good, bubbleColor: '#FFFFFF' }));
    await assertFails(look('alice', 'plusTeam', { ...good, background: 'video' }));
    await assertFails(look('alice', 'plusTeam', { ...good, backgroundPath: 'groups/freeTeam/theme/1.jpg' }));
  });
});

describe('Plus files in Storage (PLAN-8, PLAN-11)', () => {
  const put = (uid: string, path: string, bytes: Uint8Array, type: string) =>
    env.authenticatedContext(uid).storage().ref(path).put(bytes, { contentType: type }).then(() => undefined);
  const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);

  it("takes chat backgrounds only from a Plus team's admins", async () => {
    await assertSucceeds(put('alice', 'groups/plusTeam/theme/1.jpg', jpeg, 'image/jpeg'));
    await assertFails(put('alice', 'groups/freeTeam/theme/1.jpg', jpeg, 'image/jpeg'));
    await assertFails(put('bob', 'groups/plusTeam/theme/1.jpg', jpeg, 'image/jpeg'));
  });

  it('allows documents over 25 MB only on Plus, up to 100 MB', async () => {
    const big = new Uint8Array(26 * 1024 * 1024);
    await assertSucceeds(put('bob', 'groups/plusTeam/documents/d1/big.pdf', big, 'application/pdf'));
    await assertFails(put('bob', 'groups/freeTeam/documents/d1/big.pdf', big, 'application/pdf'));
    await assertFails(put('bob', 'groups/lapsedTeam/documents/d1/big.pdf', big, 'application/pdf'));
  });
});
