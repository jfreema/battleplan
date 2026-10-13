// Rules tests for teams, members, players, guardian requests, invites, and
// team files (roadmap task 56), centered on cross-team isolation: nothing a
// member of one team does can read or change another team. Run with:
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

// Team A (adult): alice owns it, bob is a member. Team B (youth): carol is
// an admin, dan guards emma, frank is a parent waiting on a request for
// emma. Team C is full: its storage quota is used up.
const member = (groupId: string, uid: string, role = 'member') => ({
  groupId,
  uid,
  role,
  displayName: uid,
  notificationLevel: 'all',
});

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
    const settings = { membersCanUploadDocs: false };
    await db.doc('groups/teamA').set({ name: 'Thunder', teamType: 'adult', settings, storageBytes: 0, storageQuotaBytes: 5 * GB });
    await db.doc('groups/teamB').set({ name: 'Lightning', teamType: 'youth', settings, storageBytes: 0, storageQuotaBytes: 5 * GB });
    await db.doc('groups/teamC').set({ name: 'Full', teamType: 'adult', settings, storageBytes: 5 * GB, storageQuotaBytes: 5 * GB });
    await db.doc('groupMembers/teamA_alice').set(member('teamA', 'alice', 'owner'));
    await db.doc('groupMembers/teamA_bob').set(member('teamA', 'bob'));
    await db.doc('groupMembers/teamB_carol').set(member('teamB', 'carol', 'admin'));
    await db.doc('groupMembers/teamB_dan').set(member('teamB', 'dan'));
    await db.doc('groupMembers/teamB_frank').set(member('teamB', 'frank'));
    await db.doc('groupMembers/teamC_alice').set(member('teamC', 'alice', 'owner'));
    await db.doc('players/emma').set({ groupId: 'teamB', displayName: 'Emma', displayNameLower: 'emma' });
    await db.doc('playerGuardians/emma_dan').set({ playerId: 'emma', groupId: 'teamB', uid: 'dan' });
    await db.doc('guardianRequests/emma_frank').set({ playerId: 'emma', groupId: 'teamB', uid: 'frank', status: 'pending' });
    await db.doc('invites/K7XPM2QR').set({ groupId: 'teamA', type: 'link', useCount: 0 });
    await db.doc('auditLogs/a1').set({ groupId: 'teamA', action: 'createGroup' });
    await db.doc('reports/rep1').set({ groupId: 'teamB', reporterId: 'dan', subjectId: 'frank', teamVisible: true, status: 'open', reason: 'spam' });
    // About an admin: for super admins only (SAFE-1).
    await db.doc('reports/rep2').set({ groupId: 'teamB', reporterId: 'dan', subjectId: 'carol', teamVisible: false, status: 'open', reason: 'harassment' });
    // Filed while carol wasn't an admin yet: still never shown to her.
    await db.doc('reports/rep3').set({ groupId: 'teamB', reporterId: 'dan', subjectId: 'carol', teamVisible: true, status: 'open', reason: 'spam' });
    await db.doc('userBlocks/dan_frank').set({ uid: 'dan', blockedUid: 'frank', blockedName: 'Frank' });
  });
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const list = (db: Db, collection: string, field: string, value: string) =>
  db.collection(collection).where(field, '==', value).limit(50).get();

describe('teams and memberships', () => {
  it('leaves creating and deleting teams to Functions', async () => {
    await assertFails(as('alice').doc('groups/new').set({ name: 'Mine', teamType: 'adult' }));
    await assertFails(as('alice').doc('groups/teamA').delete());
  });

  it('never lets anyone add, promote, or remove members directly', async () => {
    await assertFails(as('bob').doc('groupMembers/teamB_bob').set(member('teamB', 'bob')));
    await assertFails(as('alice').doc('groupMembers/teamA_zed').set(member('teamA', 'zed')));
    await assertFails(as('alice').doc('groupMembers/teamA_bob').update({ role: 'admin' }));
    await assertFails(as('alice').doc('groupMembers/teamA_bob').delete());
    await assertFails(as('bob').doc('groupMembers/teamA_bob').delete());
  });

  it("keeps each team's roster to its own members", async () => {
    await assertSucceeds(list(as('bob'), 'groupMembers', 'groupId', 'teamA'));
    await assertFails(list(as('bob'), 'groupMembers', 'groupId', 'teamB'));
    await assertFails(as('bob').doc('groupMembers/teamB_carol').get());
  });

  it("stops an admin of one team from editing another's", async () => {
    await assertFails(as('carol').doc('groups/teamA').update({ name: 'Taken', nameLower: 'taken' }));
    await assertFails(as('alice').doc('groups/teamB').update({ name: 'Taken', nameLower: 'taken' }));
  });
});

describe('players across teams', () => {
  it("hides a youth team's players and guardians from other teams", async () => {
    await assertSucceeds(as('frank').doc('players/emma').get());
    await assertFails(as('bob').doc('players/emma').get());
    await assertFails(list(as('bob'), 'players', 'groupId', 'teamB'));
    await assertSucceeds(list(as('frank'), 'playerGuardians', 'groupId', 'teamB'));
    await assertFails(list(as('bob'), 'playerGuardians', 'groupId', 'teamB'));
  });

  it('leaves guardian links to Functions', async () => {
    await assertFails(as('frank').doc('playerGuardians/emma_frank').set({ playerId: 'emma', groupId: 'teamB', uid: 'frank' }));
    await assertFails(as('dan').doc('playerGuardians/emma_dan').delete());
    await assertFails(as('carol').doc('playerGuardians/emma_frank').set({ playerId: 'emma', groupId: 'teamB', uid: 'frank' }));
  });
});

describe('guardian requests (PLAYER-3, PLAYER-4)', () => {
  it('lets the parent see their own request and admins see the queue', async () => {
    await assertSucceeds(as('frank').doc('guardianRequests/emma_frank').get());
    await assertSucceeds(
      as('frank').collection('guardianRequests').where('groupId', '==', 'teamB').where('uid', '==', 'frank').limit(50).get(),
    );
    await assertSucceeds(
      as('carol').collection('guardianRequests').where('groupId', '==', 'teamB').where('status', '==', 'pending').limit(50).get(),
    );
  });

  it('hides requests from other parents and other teams', async () => {
    await assertFails(as('dan').doc('guardianRequests/emma_frank').get());
    await assertFails(list(as('dan'), 'guardianRequests', 'groupId', 'teamB'));
    await assertFails(list(as('alice'), 'guardianRequests', 'groupId', 'teamB'));
  });

  it('never lets anyone approve or write a request directly', async () => {
    await assertFails(as('carol').doc('guardianRequests/emma_frank').update({ status: 'approved' }));
    await assertFails(as('frank').doc('guardianRequests/emma_frank').update({ status: 'approved' }));
    await assertFails(as('frank').doc('guardianRequests/emma_bob').set({ playerId: 'emma', groupId: 'teamB', uid: 'frank', status: 'pending' }));
  });
});

describe('invites and other server-only data', () => {
  it('keeps invites readable only through Functions', async () => {
    await assertFails(as('alice').doc('invites/K7XPM2QR').get());
    await assertFails(list(as('alice'), 'invites', 'groupId', 'teamA'));
    await assertFails(as('alice').doc('invites/NEWCODE2').set({ groupId: 'teamA', type: 'link' }));
    await assertFails(env.unauthenticatedContext().firestore().doc('invites/K7XPM2QR').get());
  });

  it('keeps audit logs and rate limits away from team members', async () => {
    await assertFails(as('alice').doc('auditLogs/a1').get());
    await assertFails(as('alice').doc('auditLogs/a2').set({ groupId: 'teamA' }));
    await assertFails(as('alice').doc('rateLimits/x').get());
  });
});

describe('reports and blocks (SAFE-1, SAFE-2, SAFE-4)', () => {
  it("shows a team's reports to its admins only", async () => {
    await assertSucceeds(as('carol').doc('reports/rep1').get());
    await assertSucceeds(
      as('carol')
        .collection('reports')
        .where('groupId', '==', 'teamB')
        .where('status', '==', 'open')
        .where('teamVisible', '==', true)
        .limit(50)
        .get(),
    );
    await assertFails(as('dan').doc('reports/rep1').get());
    await assertFails(as('alice').doc('reports/rep1').get());
  });

  it('never shows a team admin a report about an admin, or who reported them (SAFE-1)', async () => {
    await assertFails(as('carol').doc('reports/rep2').get());
    await assertFails(as('carol').doc('reports/rep3').get());
    // A list must leave out the reports about admins.
    await assertFails(
      as('carol').collection('reports').where('groupId', '==', 'teamB').where('status', '==', 'open').limit(50).get(),
    );
  });

  it('leaves filing and closing reports to Functions', async () => {
    await assertFails(as('dan').doc('reports/new').set({ groupId: 'teamB', reporterId: 'dan', status: 'open' }));
    await assertFails(as('carol').doc('reports/rep1').update({ status: 'dismissed' }));
  });

  it('lets people manage only their own blocks', async () => {
    await assertSucceeds(as('dan').doc('userBlocks/dan_frank').get());
    await assertFails(as('frank').doc('userBlocks/dan_frank').get());
    await assertSucceeds(
      as('erin').doc('userBlocks/erin_frank').set({ uid: 'erin', blockedUid: 'frank', blockedName: 'Frank' }),
    );
    await assertFails(as('erin').doc('userBlocks/dan_carol').set({ uid: 'dan', blockedUid: 'carol' }));
    await assertFails(as('erin').doc('userBlocks/erin_erin').set({ uid: 'erin', blockedUid: 'erin' }));
    await assertFails(as('erin').doc('userBlocks/erin_bob').set({ uid: 'erin', blockedUid: 'bob', extra: 1 }));
    await assertFails(as('frank').doc('userBlocks/dan_frank').delete());
    await assertSucceeds(as('dan').doc('userBlocks/dan_frank').delete());
  });
});

describe('team files in Storage', () => {
  const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);
  const put = (uid: string, path: string, type = 'image/jpeg') =>
    env.authenticatedContext(uid).storage().ref(path).put(jpeg, { contentType: type }).then(() => undefined);

  it("lets members add chat photos to their own team only", async () => {
    await assertSucceeds(put('bob', 'groups/teamA/messages/m1/1.jpg'));
    await assertFails(put('bob', 'groups/teamB/messages/m1/1.jpg'));
    await assertFails(put('bob', 'groups/teamA/messages/m1/1.exe', 'application/octet-stream'));
  });

  it('keeps team logos to admins and team files to members', async () => {
    await assertSucceeds(put('alice', 'groups/teamA/avatar/logo.jpg'));
    await assertFails(put('bob', 'groups/teamA/avatar/logo.jpg'));
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.storage().ref('groups/teamB/messages/m2/kid.jpg').put(jpeg, { contentType: 'image/jpeg' }).then(() => undefined),
    );
    await assertSucceeds(env.authenticatedContext('dan').storage().ref('groups/teamB/messages/m2/kid.jpg').getDownloadURL());
    await assertFails(env.authenticatedContext('bob').storage().ref('groups/teamB/messages/m2/kid.jpg').getDownloadURL());
  });

  it("follows the team's document upload setting", async () => {
    await assertSucceeds(put('alice', 'groups/teamA/documents/d1/a.pdf', 'application/pdf'));
    await assertFails(put('bob', 'groups/teamA/documents/d1/b.pdf', 'application/pdf'));
  });

  it('stops uploads once the team is over its storage quota (D16)', async () => {
    await assertFails(put('alice', 'groups/teamC/messages/m1/1.jpg'));
    await assertFails(put('alice', 'groups/teamC/avatar/logo.jpg'));
  });
});
