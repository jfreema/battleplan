// Gaps found by the rules-coverage review (roadmap task 104,
// docs/rules-coverage.md): signed-out visitors against every collection and
// Storage folder, members of a suspended team, archived teams in Storage
// and on the roster, and listing blocks. Run with:
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
const START = '2030-06-01T23:00:00Z';

const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const anon = (): Db => env.unauthenticatedContext().firestore();
const root = (): Db => env.authenticatedContext('root', { superAdmin: true }).firestore();
const storageOf = (uid: string | null) =>
  uid === null ? env.unauthenticatedContext().storage() : env.authenticatedContext(uid).storage();
const put = (uid: string | null, path: string, contentType = 'image/jpeg') =>
  storageOf(uid).ref(path).put(jpeg, { contentType }).then(() => undefined);
const read = (uid: string | null, path: string) => storageOf(uid).ref(path).getMetadata();

/** One document of teamA in every collection, by the field a list filters on. */
const DOCS: [collection: string, id: string, field: string, value: string][] = [
  ['users', 'alice', 'displayNameLower', 'alice'],
  ['devices', 'abcdefghijklmnop1234', 'uid', 'alice'],
  ['userBlocks', 'alice_bob', 'uid', 'alice'],
  ['groups', 'teamA', 'nameLower', 'teama'],
  ['groupMembers', 'teamA_alice', 'groupId', 'teamA'],
  ['players', 'emma', 'groupId', 'teamA'],
  ['playerGuardians', 'emma_dan', 'groupId', 'teamA'],
  ['guardianRequests', 'emma_bob', 'groupId', 'teamA'],
  ['messages', 'm1', 'groupId', 'teamA'],
  ['polls', 'p1', 'groupId', 'teamA'],
  ['pollVotes', 'p1_alice', 'pollId', 'p1'],
  ['eventSeries', 's1', 'groupId', 'teamA'],
  ['events', 'e1', 'groupId', 'teamA'],
  ['rsvps', 'e1_alice', 'groupId', 'teamA'],
  ['groupDocuments', 'd1', 'groupId', 'teamA'],
  ['notifications', 'n1_alice', 'uid', 'alice'],
  ['reports', 'r1', 'groupId', 'teamA'],
  ['auditLogs', 'a1', 'groupId', 'teamA'],
  ['config', 'app', 'allowUserGroupCreation', 'true'],
  ['invites', 'K7XPM2QR', 'groupId', 'teamA'],
  ['rateLimits', 'alice_x', 'key', 'alice'],
];

/** The team-owned collections a member reads. */
const TEAM_COLLECTIONS = [
  'groupMembers', 'players', 'playerGuardians', 'messages', 'polls', 'eventSeries', 'events', 'rsvps', 'groupDocuments',
];

/** teamA's files, one in each Storage folder, plus alice's avatar. */
const FILES = [
  'groups/teamA/avatar/logo.jpg',
  'groups/teamA/theme/bg.jpg',
  'groups/teamA/messages/m1/0.jpg',
  'groups/teamA/documents/d1/a.jpg',
];

// teamA (youth): alice owner, carol admin, bob member, dan guardian of emma.
// teamB: gina admin (the other team). root is a super admin on no team.
async function seed(group: object = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const settings = {
      membersCanCreateEvents: true, membersCanCreatePolls: true, membersCanUploadDocs: true,
      membersCanInvite: true, allowMaybe: true, defaultReminderOffsets: [1440],
    };
    for (const g of ['teamA', 'teamB']) {
      await db.doc(`groups/${g}`).set({
        name: g, nameLower: g.toLowerCase(), sport: 'soccer', color: null, photoPath: null, teamType: 'youth',
        settings, storageBytes: 0, storageQuotaBytes: 100 * MB, ...(g === 'teamA' ? group : {}),
      });
    }
    const member = (g: string, uid: string, role: string) =>
      db.doc(`groupMembers/${g}_${uid}`).set({
        groupId: g, uid, role, displayName: uid, photoPath: null, playerSummary: null, notificationLevel: 'all',
      });
    await member('teamA', 'alice', 'owner');
    await member('teamA', 'carol', 'admin');
    await member('teamA', 'bob', 'member');
    await member('teamA', 'dan', 'member');
    await member('teamB', 'gina', 'admin');
    await db.doc('users/alice').set({ displayName: 'alice', displayNameLower: 'alice', photoPath: null, themeMode: 'system', notificationPrefs: {} });
    await db.doc('devices/abcdefghijklmnop1234').set({ uid: 'alice', token: 't', platform: 'web', appVersion: '1', updatedAt: ts('2026-10-01T00:00:00Z') });
    await db.doc('userBlocks/alice_bob').set({ uid: 'alice', blockedUid: 'bob', blockedName: 'bob' });
    await db.doc('players/emma').set({ groupId: 'teamA', displayName: 'Emma', displayNameLower: 'emma', jerseyNumber: '7' });
    await db.doc('playerGuardians/emma_dan').set({ groupId: 'teamA', playerId: 'emma', uid: 'dan' });
    await db.doc('guardianRequests/emma_bob').set({ groupId: 'teamA', playerId: 'emma', uid: 'bob', status: 'pending' });
    await db.doc('messages/m1').set({ groupId: 'teamA', authorId: 'bob', authorName: 'bob', type: 'text', text: 'Hi', reactions: {} });
    await db.doc('polls/p1').set({
      groupId: 'teamA', messageId: 'p1', createdBy: 'alice', question: 'When?', anonymous: false, allowMultiple: false,
      options: [{ id: '0', text: 'Sat' }, { id: '1', text: 'Sun' }], closesAt: null, closedAt: null, voteCounts: {}, voterCount: 0,
    });
    await db.doc('pollVotes/p1_alice').set({ pollId: 'p1', groupId: 'teamA', uid: 'alice', optionIds: ['0'] });
    await db.doc('eventSeries/s1').set({ groupId: 'teamA', createdBy: 'alice' });
    await db.doc('events/e1').set({
      groupId: 'teamA', type: 'practice', title: 'Practice', description: '', location: null, allDay: false,
      startAt: ts(START), endAt: ts('2030-06-02T00:30:00Z'), timeZone: 'America/Chicago', rsvpEnabled: true,
      rsvpFor: 'players', reminderOffsets: [], notifyTeam: true, postToChat: true,
      rsvpCounts: { going: 0, maybe: 0, notGoing: 0 }, staffCounts: { going: 0, maybe: 0, notGoing: 0 },
      createdBy: 'bob', createdAt: ts('2026-10-01T00:00:00Z'), updatedAt: ts('2026-10-01T00:00:00Z'),
    });
    await db.doc('rsvps/e1_alice').set({ groupId: 'teamA', eventId: 'e1', participantType: 'member', participantId: 'alice', status: 'going' });
    await db.doc('groupDocuments/d1').set({ groupId: 'teamA', kind: 'link', name: 'Site', uploadedBy: 'bob' });
    await db.doc('notifications/n1_alice').set({ uid: 'alice', groupId: 'teamA', read: false });
    await db.doc('reports/r1').set({ groupId: 'teamA', status: 'open', teamVisible: true, reporterId: 'bob' });
    await db.doc('auditLogs/a1').set({ groupId: 'teamA', action: 'viewGroup' });
    await db.doc('config/app').set({ allowUserGroupCreation: true });
    await db.doc('invites/K7XPM2QR').set({ groupId: 'teamA', type: 'link' });
    await db.doc('rateLimits/alice_x').set({ key: 'alice', count: 1 });
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    for (const path of [...FILES, 'users/alice/avatar/a.jpg']) {
      await ctx.storage().ref(path).put(jpeg, { contentType: 'image/jpeg' }).then(() => undefined);
    }
  });
}

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
  await seed();
});

afterAll(async () => {
  await env?.cleanup();
});

const setTeam = (fields: object) =>
  env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update(fields));

/** A message and its rate-limit stamp, as the app sends them. */
const send = (uid: string, id: string) => {
  const db = as(uid);
  const batch = db.batch();
  batch.set(db.doc(`messages/${id}`), {
    groupId: 'teamA', authorId: uid, authorName: uid, authorPhotoPath: null, authorPlayerSummary: null,
    type: 'text', text: 'Hi', createdAt: now(),
  });
  batch.update(db.doc(`groupMembers/teamA_${uid}`), { lastPostedAt: now(), lastPostedMessageId: id });
  return batch.commit();
};

describe('signed-out visitors', () => {
  it('read no document of any collection, by get or list', async () => {
    for (const [collection, id, field, value] of DOCS) {
      await assertFails(anon().doc(`${collection}/${id}`).get());
      await assertFails(anon().collection(collection).where(field, '==', value).limit(10).get());
    }
  });

  it('write nothing anywhere: create, update, or delete', async () => {
    for (const [collection, id] of DOCS) {
      await assertFails(anon().doc(`${collection}/new_${id}`).set({ groupId: 'teamA', uid: 'alice' }));
      await assertFails(anon().doc(`${collection}/${id}`).update({ updatedAt: now() }));
      await assertFails(anon().doc(`${collection}/${id}`).delete());
    }
  });

  it('read and upload no file', async () => {
    for (const path of [...FILES, 'users/alice/avatar/a.jpg']) {
      await assertFails(read(null, path));
      await assertFails(put(null, path.replace(/[^/]+$/, 'new.jpg')));
    }
  });
});

describe('a suspended team (ADMIN-3)', () => {
  beforeEach(() => setTeam({ suspendedAt: ts('2026-10-01T00:00:00Z') }));

  it("closes every team collection to its members, owner and guardians included", async () => {
    for (const uid of ['alice', 'carol', 'bob', 'dan']) {
      await assertFails(as(uid).doc('groups/teamA').get());
      for (const collection of TEAM_COLLECTIONS) {
        await assertFails(as(uid).collection(collection).where('groupId', '==', 'teamA').limit(10).get());
      }
    }
    await assertFails(as('alice').collection('reports').where('groupId', '==', 'teamA').limit(10).get());
    await assertFails(as('alice').collection('guardianRequests').where('groupId', '==', 'teamA').limit(10).get());
  });

  it('refuses every write a member could make', async () => {
    await assertFails(send('bob', 'mNew'));
    await assertFails(as('bob').doc('messages/m1').update({ 'reactions.bob': 'like' }));
    await assertFails(as('bob').doc('messages/m1').update({ text: 'Edited', editedAt: now() }));
    await assertFails(as('alice').doc('pollVotes/p1_alice').set({ pollId: 'p1', groupId: 'teamA', uid: 'alice', optionIds: ['1'], updatedAt: now() }));
    await assertFails(as('alice').doc('groups/teamA').update({ name: 'Renamed', nameLower: 'renamed' }));
    await assertFails(as('dan').doc('players/emma').update({ jerseyNumber: '8' }));
    await assertFails(as('alice').doc('events/e1').update({ title: 'Moved', updatedAt: now() }));
    await assertFails(
      as('dan').doc('rsvps/e1_emma').set({
        eventId: 'e1', groupId: 'teamA', participantType: 'player', participantId: 'emma', participantName: 'Emma',
        eventStartAt: ts(START), status: 'going', respondedBy: 'dan', updatedAt: now(),
      }),
    );
  });

  it('still shows people their own membership and notifications', async () => {
    await assertSucceeds(as('bob').doc('groupMembers/teamA_bob').get());
    await assertSucceeds(as('bob').collection('groupMembers').where('uid', '==', 'bob').limit(10).get());
    await assertSucceeds(as('alice').doc('notifications/n1_alice').get());
  });

  it("closes the team's files to its members, and takes no uploads", async () => {
    for (const uid of ['alice', 'bob']) {
      for (const path of FILES) await assertFails(read(uid, path));
    }
    await assertFails(put('bob', 'groups/teamA/messages/m2/0.jpg'));
    await assertFails(put('alice', 'groups/teamA/avatar/new.jpg'));
    await assertFails(put('alice', 'groups/teamA/theme/new.jpg'));
    await assertFails(put('bob', 'groups/teamA/documents/d2/a.pdf', 'application/pdf'));
    // Super admins still see it (View team).
    await assertSucceeds(env.authenticatedContext('root', { superAdmin: true }).storage().ref(FILES[2]).getMetadata());
  });

  it('opens again when unsuspended', async () => {
    await setTeam({ suspendedAt: null });
    await assertSucceeds(read('bob', FILES[2]));
    await assertSucceeds(put('bob', 'groups/teamA/messages/m2/0.jpg'));
  });
});

describe('an archived team (TEAM-9)', () => {
  beforeEach(() => setTeam({ archivedAt: ts('2026-10-01T00:00:00Z') }));

  it('takes no uploads from anyone, super admins included, and still shows its files', async () => {
    await assertFails(put('bob', 'groups/teamA/messages/m2/0.jpg'));
    await assertFails(put('alice', 'groups/teamA/avatar/new.jpg'));
    await assertFails(put('carol', 'groups/teamA/theme/new.jpg'));
    await assertFails(put('alice', 'groups/teamA/documents/d2/a.pdf', 'application/pdf'));
    const rootStorage = env.authenticatedContext('root', { superAdmin: true }).storage();
    await assertFails(rootStorage.ref('groups/teamA/avatar/new.jpg').put(jpeg, { contentType: 'image/jpeg' }).then(() => undefined));
    for (const path of FILES) await assertSucceeds(read('bob', path));
  });

  it('freezes the roster: guardians and admins edit no player', async () => {
    await assertFails(as('dan').doc('players/emma').update({ jerseyNumber: '8' }));
    await assertFails(as('carol').doc('players/emma').update({ jerseyNumber: '8' }));
    await assertFails(as('alice').doc('players/emma').update({ position: 'Keeper' }));
    await assertSucceeds(as('dan').doc('players/emma').get());
  });

  it('still lets people mute it and mark it read: their own preferences', async () => {
    await assertSucceeds(as('bob').doc('groupMembers/teamA_bob').update({ notificationLevel: 'none' }));
    await assertSucceeds(as('bob').doc('groupMembers/teamA_bob').update({ lastReadAt: now() }));
  });

  it('edits players again once restored', async () => {
    await setTeam({ archivedAt: null });
    await assertSucceeds(as('dan').doc('players/emma').update({ jerseyNumber: '8' }));
  });
});

describe('every role, spot checks the other files leave out', () => {
  it('lists only your own blocks', async () => {
    await assertSucceeds(as('alice').collection('userBlocks').where('uid', '==', 'alice').limit(10).get());
    await assertFails(as('bob').collection('userBlocks').where('uid', '==', 'alice').limit(10).get());
    await assertFails(root().collection('userBlocks').where('uid', '==', 'alice').limit(10).get());
  });

  it("treats the owner and an admin alike on the team's own writes", async () => {
    for (const uid of ['alice', 'carol']) {
      await assertSucceeds(as(uid).doc('players/emma').update({ position: `By ${uid}` }));
      await assertSucceeds(as(uid).doc('groups/teamA').update({ description: `By ${uid}` }));
      await assertSucceeds(as(uid).doc('reports/r1').get());
    }
    await assertFails(as('bob').doc('groups/teamA').update({ description: 'By bob' }));
    await assertFails(as('gina').doc('players/emma').update({ position: 'By gina' }));
  });

  it("gives a guardian their player, and nothing more than a member otherwise", async () => {
    await assertSucceeds(as('dan').doc('players/emma').update({ position: 'Wing' }));
    await assertFails(as('bob').doc('players/emma').update({ position: 'Wing' }));
    await assertFails(as('dan').doc('groups/teamA').update({ description: 'By dan' }));
    await assertFails(as('dan').doc('reports/r1').get());
  });

  it('lets members and guardians read the team, and nobody list teams', async () => {
    for (const uid of ['bob', 'dan', 'carol']) await assertSucceeds(as(uid).doc('groups/teamA').get());
    await assertFails(as('bob').collection('groups').where('nameLower', '==', 'teama').limit(10).get());
    await assertFails(root().collection('groups').where('nameLower', '==', 'teama').limit(10).get());
    await assertSucceeds(as('bob').doc('polls/p1').get());
    await assertSucceeds(as('bob').doc('rsvps/e1_alice').get());
    await assertSucceeds(as('dan').doc('playerGuardians/emma_dan').get());
  });

  it('leaves removing players, links, requests, and messages to Functions, admins included', async () => {
    await assertFails(as('carol').doc('players/emma').delete());
    await assertFails(as('carol').doc('playerGuardians/emma_dan').update({ uid: 'bob' }));
    await assertFails(as('bob').doc('guardianRequests/emma_bob').delete());
    await assertFails(as('carol').doc('guardianRequests/emma_bob').delete());
    await assertFails(as('bob').doc('messages/m1').delete());
    await assertFails(as('alice').doc('messages/m1').delete());
    await assertFails(root().doc('messages/m1').delete());
  });

  it("never lets an owner edit someone else's message text", async () => {
    await assertFails(as('alice').doc('messages/m1').update({ text: 'Edited by the owner', editedAt: now() }));
    await assertSucceeds(as('bob').doc('messages/m1').update({ text: 'Edited', editedAt: now() }));
  });

  it("stops super admins creating events and other teams' admins editing them", async () => {
    const event = (uid: string) => ({
      groupId: 'teamA', type: 'practice', title: 'Extra', description: '', location: null, allDay: false,
      startAt: ts(START), endAt: ts('2030-06-02T00:30:00Z'), timeZone: 'America/Chicago', rsvpEnabled: true,
      rsvpFor: 'players', reminderOffsets: [], notifyTeam: false, postToChat: false,
      rsvpCounts: { going: 0, maybe: 0, notGoing: 0 }, staffCounts: { going: 0, maybe: 0, notGoing: 0 },
      createdBy: uid, createdAt: now(), updatedAt: now(),
    });
    await assertFails(root().doc('events/eRoot').set(event('root')));
    await assertSucceeds(as('alice').doc('events/eAlice').set(event('alice')));
    await assertFails(as('gina').doc('events/e1').update({ title: 'Taken', updatedAt: now() }));
  });

  it("keeps people's own records their own, super admins included", async () => {
    await assertFails(root().doc('users/alice').update({ themeMode: 'dark' }));
    await assertFails(root().doc('userBlocks/alice_bob').delete());
    await assertFails(
      root().doc('userBlocks/alice_carol').set({ uid: 'alice', blockedUid: 'carol', blockedName: 'Carol' }),
    );
    await assertFails(as('bob').doc('users/alice').update({ themeMode: 'dark' }));
  });

  it('keeps invites, rate limits, and series away from super admins too', async () => {
    await assertFails(root().doc('invites/K7XPM2QR').get());
    await assertFails(root().doc('rateLimits/alice_x').get());
    await assertFails(root().doc('eventSeries/s1').update({ createdBy: 'root' }));
    await assertFails(root().doc('devices/abcdefghijklmnop1234').get());
    await assertFails(root().doc('devices/abcdefghijklmnop1234').delete());
    await assertFails(root().doc('notifications/n1_alice').get());
    await assertFails(root().collection('notifications').where('uid', '==', 'alice').limit(10).get());
  });
});
