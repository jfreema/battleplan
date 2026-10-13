// Rules tests for team storage limits (SPEC §6.14, STORE-1 and STORE-4;
// roadmap task 173): a full team can't upload or attach, even by calling
// Storage directly, yet still chats; no file is over 10 MB; only Media
// deletes team files; and no team can raise its own limit or silence its
// warning. Run with:
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
const MB = 1024 * 1024;
const QUOTA = 500 * MB;
const now = () => firebase.firestore.FieldValue.serverTimestamp();

// roomy has space and full has used its limit. Alice owns both; bob is a
// member of both.
beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-battleplan',
    firestore: { rules: readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8') },
    storage: { rules: readFileSync(resolve(process.cwd(), '../storage.rules'), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const team = (name: string, storageBytes: number) => ({
      name,
      nameLower: name.toLowerCase(),
      sport: 'baseball',
      color: '#2F5BEA',
      photoPath: null,
      teamType: 'adult',
      settings: { membersCanUploadDocs: true, defaultReminderOffsets: [1440] },
      storageBytes,
      storageQuotaBytes: QUOTA,
      storageAlert: storageBytes >= QUOTA ? 'full' : 'none',
    });
    await db.doc('groups/roomy').set(team('Roomy', 10 * MB));
    await db.doc('groups/full').set(team('Full', QUOTA));
    for (const g of ['roomy', 'full']) {
      await db.doc(`groupMembers/${g}_alice`).set({ groupId: g, uid: 'alice', role: 'owner', displayName: 'Alice', photoPath: null });
      await db.doc(`groupMembers/${g}_bob`).set({ groupId: g, uid: 'bob', role: 'member', displayName: 'Bob', photoPath: null });
      await db.doc(`messages/${g}_m`).set({ groupId: g, authorId: 'alice', authorName: 'Alice', type: 'text', text: 'Hi', reactions: {} });
    }
  });
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const put = (uid: string, path: string, bytes: Uint8Array, contentType = 'image/jpeg') =>
  env.authenticatedContext(uid).storage().ref(path).put(bytes, { contentType }).then(() => undefined);
const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);

describe('storage fields are server-only (STORE-1, STORE-3, STORE-6)', () => {
  it('never lets admins raise the limit, change usage, or clear the warning', async () => {
    await assertFails(as('alice').doc('groups/full').update({ storageQuotaBytes: 2 * QUOTA }));
    await assertFails(as('alice').doc('groups/full').update({ storageBytes: 0 }));
    await assertFails(as('alice').doc('groups/full').update({ storageAlert: 'none' }));
    await assertFails(as('alice').doc('groups/full').update({ name: 'Full', nameLower: 'full', storageBytes: 0 }));
    await assertFails(as('bob').doc('groups/roomy').update({ storageQuotaBytes: 2 * QUOTA }));
    // Super admins change the limit through adminSetGroupQuota, not directly.
    const root = env.authenticatedContext('root', { superAdmin: true }).firestore();
    await assertFails(root.doc('groups/roomy').update({ storageQuotaBytes: 2 * QUOTA }));
  });

  it('still lets admins edit the team profile', async () => {
    await assertSucceeds(as('alice').doc('groups/full').update({ name: 'Full Team', nameLower: 'full team' }));
  });
});

describe('a full team (STORE-4)', () => {
  it("can't add chat photos, a logo, a background, or documents", async () => {
    await assertFails(put('bob', 'groups/full/messages/m1/0.jpg', jpeg));
    await assertFails(put('alice', 'groups/full/messages/m1/0.jpg', jpeg));
    await assertFails(put('alice', 'groups/full/avatar/1.jpg', jpeg));
    await assertFails(put('alice', 'groups/full/theme/1.jpg', jpeg));
    await assertFails(put('alice', 'groups/full/documents/d1/a.pdf', jpeg, 'application/pdf'));
  });

  it('still sends text messages and reacts', async () => {
    const db = as('bob');
    const batch = db.batch();
    batch.set(db.doc('messages/new1'), {
      groupId: 'full', authorId: 'bob', authorName: 'Bob', authorPhotoPath: null,
      type: 'text', text: 'Still here', createdAt: now(),
    });
    batch.update(db.doc('groupMembers/full_bob'), { lastPostedAt: now(), lastPostedMessageId: 'new1' });
    await assertSucceeds(batch.commit());
    await assertSucceeds(db.doc('messages/full_m').update({ 'reactions.bob': 'fire' }));
  });

  it('still edits messages and answers RSVPs: nothing else turns off', async () => {
    await assertSucceeds(as('alice').doc('messages/full_m').update({ text: 'Edited', editedAt: now() }));
    const startAt = firebase.firestore.Timestamp.fromDate(new Date('2030-05-01T17:00:00Z'));
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('events/e1').set({ groupId: 'full', rsvpEnabled: true, rsvpFor: 'members', startAt }),
    );
    await assertSucceeds(as('bob').doc('rsvps/e1_bob').set({
      eventId: 'e1', groupId: 'full', participantType: 'member', participantId: 'bob', participantName: 'Bob',
      eventStartAt: startAt, status: 'going', respondedBy: 'bob', updatedAt: now(),
    }));
  });

  it('uploads again once space is freed', async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/full').update({ storageBytes: QUOTA - MB }));
    await assertSucceeds(put('bob', 'groups/full/messages/m1/0.jpg', jpeg));
  });
});

describe('deleting and reading team files (STORE-5)', () => {
  const ref = (uid: string, path: string) => env.authenticatedContext(uid).storage().ref(path);
  const paths = ['messages/m1/0.jpg', 'avatar/1.jpg', 'theme/1.jpg', 'documents/d1/a.pdf'].map((p) => `groups/roomy/${p}`);

  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      for (const p of paths) await ctx.storage().ref(p).put(jpeg, { contentType: 'image/jpeg' });
    });
  });

  it('leaves deleting to Media: nobody deletes a team file directly, admins included', async () => {
    for (const p of paths) {
      await assertFails(ref('bob', p).delete());
      await assertFails(ref('alice', p).delete());
    }
  });

  it("keeps a team's files, its chat background included, to its members", async () => {
    for (const p of paths) {
      await assertSucceeds(ref('bob', p).getMetadata());
      await assertFails(ref('eve', p).getMetadata());
    }
  });
});

describe('uploads with room (STORE-1)', () => {
  it('takes chat photos from members, and the logo and background from admins', async () => {
    await assertSucceeds(put('bob', 'groups/roomy/messages/m1/0.jpg', jpeg));
    await assertSucceeds(put('alice', 'groups/roomy/avatar/1.jpg', jpeg));
    await assertSucceeds(put('alice', 'groups/roomy/theme/1.jpg', jpeg));
    await assertFails(put('bob', 'groups/roomy/avatar/1.jpg', jpeg));
    await assertFails(put('bob', 'groups/roomy/theme/1.jpg', jpeg));
    await assertFails(put('alice', 'groups/roomy/theme/1.pdf', jpeg, 'application/pdf'));
  });

  it('tags the logo and background with their uploader only (STORE-5)', async () => {
    const tagged = (uid: string, path: string, uploadedBy: string) =>
      env
        .authenticatedContext(uid)
        .storage()
        .ref(path)
        .put(jpeg, { contentType: 'image/jpeg', customMetadata: { uploadedBy } })
        .then(() => undefined);
    await assertSucceeds(tagged('alice', 'groups/roomy/avatar/2.jpg', 'alice'));
    await assertSucceeds(tagged('alice', 'groups/roomy/theme/2.jpg', 'alice'));
    await assertFails(tagged('alice', 'groups/roomy/avatar/3.jpg', 'bob'));
    await assertFails(tagged('alice', 'groups/roomy/theme/3.jpg', 'bob'));
  });

  it('takes files up to 10 MB and refuses anything bigger', async () => {
    const tenMb = new Uint8Array(10 * MB);
    const tooBig = new Uint8Array(10 * MB + 1);
    await assertSucceeds(put('bob', 'groups/roomy/documents/d1/ok.pdf', tenMb, 'application/pdf'));
    await assertFails(put('bob', 'groups/roomy/documents/d2/big.pdf', tooBig, 'application/pdf'));
    await assertFails(put('bob', 'groups/roomy/messages/m2/0.jpg', tooBig));
    await assertFails(put('alice', 'groups/roomy/theme/2.jpg', tooBig));
  });
});
