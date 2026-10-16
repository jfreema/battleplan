// Rules tests for direct conversations (CHAT-19): only their two people
// read and write them, not even super admins; blocking someone stops you
// messaging them, while someone who blocked you never hears from you
// (SAFE-2); a conversation takes text and photos only; and team lists
// leave conversations out. Run with:
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
const now = () => firebase.firestore.FieldValue.serverTimestamp();
const ts = (iso: string) => firebase.firestore.Timestamp.fromDate(new Date(iso));
const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);
const DM = 'dmAliceBob';

const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const root = (): Db => env.authenticatedContext('root', { superAdmin: true }).firestore();

// Alice and Bob share teamA and have a conversation; Carol is on teamA too.
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
    await db.doc('groups/teamA').set({
      name: 'Thunder', nameLower: 'thunder', sport: 'softball', kind: 'team',
      settings: { membersCanCreatePolls: true, membersCanUploadDocs: true, defaultReminderOffsets: [1440] },
      storageBytes: 0, storageQuotaBytes: 200 * MB,
    });
    await db.doc(`groups/${DM}`).set({
      name: '', nameLower: '', sport: 'other', kind: 'direct', uids: ['alice', 'bob'],
      people: { alice: { name: 'Alice', photoPath: null }, bob: { name: 'Bob', photoPath: null } },
      settings: { membersCanCreatePolls: false, membersCanUploadDocs: false, filterLanguage: true, defaultReminderOffsets: [] },
      lastMessagePreview: { authorName: 'Alice', text: 'Private', type: 'text' },
      storageBytes: 0, storageQuotaBytes: 50 * MB, storageQuotaCustom: true,
    });
    const member = (groupId: string, uid: string, role: string, name: string, extra: object = {}) =>
      db.doc(`groupMembers/${groupId}_${uid}`).set({
        groupId, uid, role, displayName: name, photoPath: null, notificationLevel: 'all', ...extra,
      });
    await member('teamA', 'alice', 'owner', 'Alice');
    await member('teamA', 'bob', 'member', 'Bob');
    await member('teamA', 'carol', 'member', 'Carol');
    await member(DM, 'alice', 'participant', 'Alice', { otherUid: 'bob', lastMessageAt: ts('2030-01-01T00:00:00Z') });
    await member(DM, 'bob', 'participant', 'Bob', { otherUid: 'alice', lastMessageAt: ts('2030-01-01T00:00:00Z') });
    await db.doc('messages/d1').set({ groupId: DM, authorId: 'alice', authorName: 'Alice', type: 'text', text: 'Private', reactions: {} });
    await db.doc('messages/t1').set({ groupId: 'teamA', authorId: 'alice', authorName: 'Alice', type: 'text', text: 'Team', reactions: {} });
  });
});

afterAll(async () => {
  await env?.cleanup();
});

/** Sends as [uid] into [groupId] with the rate-limit update, so only [extra] decides. */
const send = (uid: string, name: string, id: string, extra: object = {}, groupId = DM) => {
  const db = as(uid);
  const batch = db.batch();
  batch.set(db.doc(`messages/${id}`), {
    groupId, authorId: uid, authorName: name, authorPhotoPath: null,
    type: 'text', text: 'See you at 6', createdAt: now(), ...extra,
  });
  batch.update(db.doc(`groupMembers/${groupId}_${uid}`), { lastPostedAt: now(), lastPostedMessageId: id });
  return batch.commit();
};

const block = (uid: string, blocked: string) =>
  env.withSecurityRulesDisabled((ctx) =>
    ctx.firestore().doc(`userBlocks/${uid}_${blocked}`).set({ uid, blockedUid: blocked, createdAt: now() }),
  );

describe('who reads a conversation (CHAT-19)', () => {
  it('its two people read it, its messages, and each other', async () => {
    for (const uid of ['alice', 'bob']) {
      await assertSucceeds(as(uid).doc(`groups/${DM}`).get());
      await assertSucceeds(as(uid).doc('messages/d1').get());
      await assertSucceeds(as(uid).collection('messages').where('groupId', '==', DM).limit(50).get());
      await assertSucceeds(as(uid).collection('groupMembers').where('groupId', '==', DM).limit(2).get());
    }
  });

  it('nobody else does, a teammate included', async () => {
    await assertFails(as('carol').doc(`groups/${DM}`).get());
    await assertFails(as('carol').doc('messages/d1').get());
    await assertFails(as('carol').collection('messages').where('groupId', '==', DM).limit(50).get());
    await assertFails(as('carol').doc(`groupMembers/${DM}_alice`).get());
  });

  it('nor a super admin, who still reads every team', async () => {
    await assertFails(root().doc(`groups/${DM}`).get());
    await assertFails(root().doc('messages/d1').get());
    await assertFails(root().collection('messages').where('groupId', '==', DM).limit(50).get());
    await assertFails(root().collection('groupMembers').where('groupId', '==', DM).limit(2).get());
    await assertSucceeds(root().doc('groups/teamA').get());
    await assertSucceeds(root().doc('messages/t1').get());
  });

  it('lists my conversations newest first, and my teams without them', async () => {
    await assertSucceeds(
      as('alice').collection('groupMembers').where('uid', '==', 'alice').where('role', '==', 'participant')
        .orderBy('lastMessageAt', 'desc').limit(100).get(),
    );
    await assertSucceeds(
      as('alice').collection('groupMembers').where('uid', '==', 'alice')
        .where('role', 'in', ['owner', 'admin', 'member']).limit(100).get(),
    );
    await assertFails(
      as('carol').collection('groupMembers').where('uid', '==', 'alice').where('role', '==', 'participant').limit(100).get(),
    );
  });
});

describe('writing in a conversation (CHAT-19)', () => {
  it('takes text and photos from its people', async () => {
    await assertSucceeds(send('alice', 'Alice', 'n1'));
    const photo = { path: `groups/${DM}/messages/n2/0.jpg`, width: 10, height: 10 };
    await assertSucceeds(send('bob', 'Bob', 'n2', { type: 'image', attachments: [photo] }));
  });

  it('refuses everyone else, a teammate included', async () => {
    await assertFails(send('carol', 'Carol', 'n3'));
  });

  it('takes no polls, @mentions, @everyone, or announcements', async () => {
    await assertFails(send('alice', 'Alice', 'n4', { mentions: ['bob'] }));
    await assertFails(send('alice', 'Alice', 'n5', { mentionsEveryone: true }));
    await assertFails(send('alice', 'Alice', 'n6', { announcement: true }));
    await assertFails(send('alice', 'Alice', 'n7', { type: 'poll', pollId: 'n7' }));
  });

  it('stops me messaging someone I blocked', async () => {
    await block('alice', 'bob');
    await assertFails(send('alice', 'Alice', 'n8'));
  });

  it("lets someone I blocked send, unknowing: it never reaches me (SAFE-2)", async () => {
    await block('alice', 'bob');
    await assertSucceeds(send('bob', 'Bob', 'n9'));
  });

  it('keeps blocks out of team chat, where they only hide (SAFE-2)', async () => {
    await block('alice', 'bob');
    await assertSucceeds(send('alice', 'Alice', 'n10', {}, 'teamA'));
  });

  it("reacts, edits my own, and reads the other person's membership but changes only mine", async () => {
    await assertSucceeds(as('bob').doc('messages/d1').update({ 'reactions.bob': 'love' }));
    await assertSucceeds(as('alice').doc('messages/d1').update({ text: 'Private!', editedAt: now() }));
    await assertFails(as('bob').doc('messages/d1').update({ text: 'Forged', editedAt: now() }));
    await assertSucceeds(as('bob').doc(`groupMembers/${DM}_bob`).update({ lastReadAt: now() }));
    await assertFails(as('bob').doc(`groupMembers/${DM}_alice`).update({ lastReadAt: now() }));
    // Its order in Messages is the server's.
    await assertFails(as('bob').doc(`groupMembers/${DM}_bob`).update({ lastMessageAt: now() }));
  });

  it('goes read-only once archived (the other person deleted their account)', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc(`groups/${DM}`).update({ archivedAt: ts('2030-01-02T00:00:00Z') }),
    );
    await assertSucceeds(as('alice').doc('messages/d1').get());
    await assertFails(send('alice', 'Alice', 'n11'));
  });

  it("isn't a team: no events, documents, or settings", async () => {
    await assertFails(as('alice').doc('groupDocuments/x').set({
      groupId: DM, kind: 'link', name: 'Link', nameLower: 'link', description: '', pinned: false,
      url: 'https://example.com', uploadedBy: 'alice', uploaderName: 'Alice', notifyTeam: false,
      createdAt: now(), updatedAt: now(),
    }));
    await assertFails(as('alice').doc(`groups/${DM}`).update({ name: 'Us', nameLower: 'us' }));
  });
});

describe("a conversation's photos (CHAT-19)", () => {
  const storageOf = (uid: string, superAdmin = false) =>
    env.authenticatedContext(uid, superAdmin ? { superAdmin: true } : {}).storage();
  const path = `groups/${DM}/messages/m1/0.jpg`;

  it('its people add and see them; nobody else sees them, super admins included', async () => {
    await assertSucceeds(storageOf('alice').ref(path).put(jpeg, { contentType: 'image/jpeg' }).then(() => undefined));
    await assertSucceeds(storageOf('bob').ref(path).getMetadata());
    await assertFails(storageOf('carol').ref(path).getMetadata());
    await assertFails(storageOf('root', true).ref(path).getMetadata());
    await assertFails(
      storageOf('carol').ref(`groups/${DM}/messages/m2/0.jpg`).put(jpeg, { contentType: 'image/jpeg' }).then(() => undefined),
    );
  });
});
