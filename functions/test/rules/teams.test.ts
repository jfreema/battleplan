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

// Team A: alice owns it, bob is a member. Team B (an old doc that still
// says teamType 'youth'): carol is an admin, dan guards emma, frank is
// waiting on a claim for emma and proposed zoe, a pending player. Team C is
// full: its storage quota is used up.
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
    await db.doc('groups/teamA').set({ name: 'Thunder', kind: 'team', settings, storageBytes: 0, storageQuotaBytes: 5 * GB });
    await db.doc('groups/teamB').set({ name: 'Lightning', teamType: 'youth', settings, storageBytes: 0, storageQuotaBytes: 5 * GB });
    await db.doc('groups/teamC').set({ name: 'Full', kind: 'team', settings, storageBytes: 5 * GB, storageQuotaBytes: 5 * GB });
    await db.doc('groupMembers/teamA_alice').set(member('teamA', 'alice', 'owner'));
    await db.doc('groupMembers/teamA_bob').set(member('teamA', 'bob'));
    await db.doc('groupMembers/teamB_carol').set(member('teamB', 'carol', 'admin'));
    await db.doc('groupMembers/teamB_dan').set(member('teamB', 'dan'));
    await db.doc('groupMembers/teamB_frank').set(member('teamB', 'frank'));
    await db.doc('groupMembers/teamC_alice').set(member('teamC', 'alice', 'owner'));
    await db.doc('players/emma').set({ groupId: 'teamB', displayName: 'Emma', displayNameLower: 'emma' });
    await db.doc('playerGuardians/emma_dan').set({ playerId: 'emma', groupId: 'teamB', uid: 'dan' });
    await db.doc('guardianRequests/emma_frank').set({ playerId: 'emma', groupId: 'teamB', uid: 'frank', relation: 'guardian', status: 'pending' });
    await db.doc('players/zoe').set({
      groupId: 'teamB', displayName: 'Zoe', displayNameLower: 'zoe', jerseyNumber: null, position: null,
      status: 'pending', proposedBy: 'frank', proposedRelation: 'guardian', decidedBy: null, decidedAt: null,
    });
    await db.doc('players/liam').set({ groupId: 'teamB', displayName: 'Liam', displayNameLower: 'liam', status: 'active' });
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
    await assertFails(as('alice').doc('groups/new').set({ name: 'Mine', kind: 'team' }));
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

describe('sharing contact info with the team (TEAM-10, #45)', () => {
  const contact = (groupId: string, uid: string, fields: object = {}) => ({
    groupId,
    uid,
    phone: '+1 (555) 010-0199',
    email: `${uid}@example.com`,
    updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    ...fields,
  });
  const share = (uid: string, groupId: string, fields: object = {}) =>
    as(uid).doc(`memberContacts/${groupId}_${uid}`).set(contact(groupId, uid, fields));
  const stop = (uid: string, groupId: string) => as(uid).doc(`memberContacts/${groupId}_${uid}`).delete();
  const read = (who: Db, groupId: string, uid: string) => who.doc(`memberContacts/${groupId}_${uid}`).get();
  const root = () => env.authenticatedContext('root', { superAdmin: true }).firestore();
  const setTeam = (groupId: string, fields: object) =>
    env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc(`groups/${groupId}`).update(fields));
  const setMember = (id: string, fields: object) =>
    env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc(`groupMembers/${id}`).set(fields, { merge: true }));

  it('lets a member share a phone and email in their own record, which the team reads', async () => {
    await assertSucceeds(share('bob', 'teamA'));
    const card = await assertSucceeds(read(as('alice'), 'teamA', 'bob'));
    if (card.get('email') !== 'bob@example.com') throw new Error('not shared');
    await assertSucceeds(read(as('bob'), 'teamA', 'bob'));
    await assertSucceeds(read(root(), 'teamA', 'bob'));
    // Other teams never see it.
    await assertFails(read(as('carol'), 'teamA', 'bob'));
    // Nothing shared yet reads as not found for the team, not refused.
    const none = await assertSucceeds(read(as('bob'), 'teamA', 'alice'));
    if (none.exists) throw new Error('expected none');
  });

  it('no longer takes contacts on the membership, which every member reads, but still clears old ones', async () => {
    const member = (fields: object) => as('bob').doc('groupMembers/teamA_bob').update(fields);
    await assertFails(member({ contactPhone: '555 0100' }));
    await assertFails(member({ contactEmail: 'bob@example.com' }));
    await setMember('teamA_bob', { contactPhone: '555 0100', contactEmail: 'bob@example.com' });
    await assertSucceeds(member({ contactPhone: null }));
    await assertSucceeds(member({ contactEmail: firebase.firestore.FieldValue.delete() }));
    // An older app's stop still works on an archived team.
    await setMember('teamA_bob', { contactPhone: '555 0100' });
    await setTeam('teamA', { archivedAt: firebase.firestore.Timestamp.now() });
    await assertSucceeds(member({ contactPhone: null }));
  });

  it("refuses sharing in someone else's record, even for the owner, and on teams I'm not on", async () => {
    await assertFails(as('alice').doc('memberContacts/teamA_bob').set(contact('teamA', 'bob')));
    await assertFails(as('alice').doc('memberContacts/teamA_bob').set(contact('teamA', 'alice')));
    await assertFails(share('bob', 'teamB'));
    await assertFails(as('bob').doc('memberContacts/teamA_bob').set(contact('teamB', 'bob')));
    await assertSucceeds(share('bob', 'teamA'));
    await assertFails(as('alice').doc('memberContacts/teamA_bob').delete());
  });

  it('checks the phone, the email, and the fields', async () => {
    await assertFails(share('bob', 'teamA', { phone: 'call me' }));
    await assertFails(share('bob', 'teamA', { phone: '5'.repeat(31) }));
    await assertFails(share('bob', 'teamA', { phone: 5550100 }));
    await assertFails(share('bob', 'teamA', { email: 'bob' }));
    await assertFails(share('bob', 'teamA', { email: 'bob@example' }));
    await assertFails(share('bob', 'teamA', { email: `${'b'.repeat(250)}@x.co` }));
    await assertFails(share('bob', 'teamA', { note: 'hi' }));
    await assertFails(share('bob', 'teamA', { updatedAt: firebase.firestore.Timestamp.now() }));
    await assertSucceeds(share('bob', 'teamA', { phone: '5'.repeat(30), email: null }));
    await assertSucceeds(share('bob', 'teamA', { phone: null }));
  });

  it('lets anyone stop sharing, but share nothing new, on an archived or suspended team', async () => {
    await assertSucceeds(share('bob', 'teamA'));
    await setTeam('teamA', { archivedAt: firebase.firestore.Timestamp.now() });
    await assertFails(share('bob', 'teamA', { phone: '555 0199' }));
    await assertSucceeds(stop('bob', 'teamA'));
    await setTeam('teamA', { archivedAt: null, suspendedAt: firebase.firestore.Timestamp.now() });
    await assertFails(share('bob', 'teamA'));
    // Stopping with nothing shared is no error.
    await assertSucceeds(stop('bob', 'teamA'));
  });

  describe('with "Everyone can see who\'s on the team" off (#45)', () => {
    beforeEach(async () => {
      await setMember('teamA_zed', { groupId: 'teamA', uid: 'zed', role: 'member', displayName: 'zed', notificationLevel: 'all' });
      await setMember('teamA_kim', { groupId: 'teamA', uid: 'kim', role: 'member', displayName: 'kim', notificationLevel: 'all', coach: true });
      for (const uid of ['alice', 'bob', 'kim']) await assertSucceeds(share(uid, 'teamA'));
      await setTeam('teamA', { 'settings.membersCanSeePeople': false });
    });

    it("hides members' contacts from other members, as the roster hides them", async () => {
      await assertFails(read(as('zed'), 'teamA', 'bob'));
      // Admins, super admins, and the person still read them.
      await assertSucceeds(read(as('alice'), 'teamA', 'bob'));
      await assertSucceeds(read(root(), 'teamA', 'bob'));
      await assertSucceeds(read(as('bob'), 'teamA', 'bob'));
      // On again, the team reads them again.
      await setTeam('teamA', { 'settings.membersCanSeePeople': true });
      await assertSucceeds(read(as('zed'), 'teamA', 'bob'));
    });

    it("still shows coaches' contacts, as the roster still shows coaches", async () => {
      await assertSucceeds(read(as('zed'), 'teamA', 'kim'));
      // The owner counts as a coach until the admins say otherwise.
      await assertSucceeds(read(as('zed'), 'teamA', 'alice'));
      await setMember('teamA_alice', { coach: false });
      await assertFails(read(as('zed'), 'teamA', 'alice'));
    });

    it("lists only my own, or a team's for its admins", async () => {
      const list = (who: Db, field: string, value: string) =>
        who.collection('memberContacts').where(field, '==', value).limit(50).get();
      await assertSucceeds(list(as('bob'), 'uid', 'bob'));
      await assertFails(list(as('zed'), 'groupId', 'teamA'));
      await assertSucceeds(list(as('alice'), 'groupId', 'teamA'));
      await assertFails(list(as('carol'), 'groupId', 'teamA'));
    });

    it('refuses the contact of someone no longer on the team', async () => {
      await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groupMembers/teamA_bob').delete());
      await assertFails(read(as('alice'), 'teamA', 'bob'));
    });
  });
});

describe('players across teams', () => {
  it("hides a team's players and player links from other teams", async () => {
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

describe('pending players (PLAYER-3, PLAYER-4)', () => {
  const players = (db: Db) => db.collection('players').where('groupId', '==', 'teamB');

  it('shows a pending player to admins, super admins, and its proposer only', async () => {
    await assertSucceeds(as('frank').doc('players/zoe').get());
    await assertSucceeds(as('carol').doc('players/zoe').get());
    await assertSucceeds(env.authenticatedContext('sam', { superAdmin: true }).firestore().doc('players/zoe').get());
    await assertFails(as('dan').doc('players/zoe').get());
    await assertFails(as('bob').doc('players/zoe').get());
  });

  it('lets members list the roster by status, and admins and proposers see pending ones', async () => {
    await assertSucceeds(players(as('dan')).where('status', '==', 'active').limit(100).get());
    await assertFails(players(as('dan')).limit(100).get());
    await assertFails(players(as('dan')).where('status', '==', 'pending').limit(100).get());
    await assertSucceeds(players(as('carol')).limit(100).get());
    await assertSucceeds(players(as('frank')).where('proposedBy', '==', 'frank').limit(100).get());
    await assertFails(players(as('dan')).where('proposedBy', '==', 'frank').limit(100).get());
    await assertSucceeds(as('dan').doc('players/liam').get());
    // Old players without a status are active.
    await assertSucceeds(as('dan').doc('players/emma').get());
  });

  it('leaves status and decisions to Functions; admins still fix the name', async () => {
    await assertFails(as('carol').doc('players/zoe').update({ status: 'active' }));
    await assertFails(as('frank').doc('players/zoe').update({ status: 'active' }));
    await assertFails(as('frank').doc('players/zoe').update({ displayName: 'Zoey', displayNameLower: 'zoey' }));
    await assertFails(as('carol').doc('players/zoe').update({ proposedBy: 'carol' }));
    await assertSucceeds(as('carol').doc('players/zoe').update({ displayName: 'Zoey', displayNameLower: 'zoey' }));
    await assertFails(as('frank').doc('players/new').set({ groupId: 'teamB', displayName: 'X', displayNameLower: 'x', status: 'active' }));
  });

  it("a basic group's stray player can't be changed (TEAM-14)", async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamB').update({ kind: 'group' }));
    await assertFails(as('carol').doc('players/zoe').update({ displayName: 'Zoey', displayNameLower: 'zoey' }));
  });

  it("lets a member who is the player edit their own details, not their link's relation", async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('playerGuardians/liam_frank').set({ playerId: 'liam', groupId: 'teamB', uid: 'frank', relation: 'self' }),
    );
    await assertSucceeds(as('frank').doc('players/liam').update({ jerseyNumber: '12' }));
    await assertFails(as('frank').doc('playerGuardians/liam_frank').update({ relation: 'guardian' }));
  });
});

describe('player claims (PLAYER-3, PLAYER-4)', () => {
  it('lets the claimer see their own claim and admins see the queue', async () => {
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
