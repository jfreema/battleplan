// Security rules for super admins (SPEC §3, ADMIN-3, ADMIN-6, ADMIN-7; ARCH
// §6.3): "View team" reads every team collection and Storage folder
// without joining, anonymous poll votes stay private, super admins can't
// post, vote, or RSVP in teams they haven't joined, and the audit log and
// settings are theirs alone. Run against the emulators:
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
const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
/** A super admin who isn't on any team. */
const root = (): Db => env.authenticatedContext('root', { superAdmin: true }).firestore();
const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);

/** Every team-owned collection View team reads, with a document of teamA in each. */
const TEAM_DOCS: [collection: string, id: string][] = [
  ['groupMembers', 'teamA_alice'],
  ['players', 'emma'],
  ['playerGuardians', 'emma_alice'],
  ['guardianRequests', 'emma_bob'],
  ['messages', 'm1'],
  ['polls', 'pOpen'],
  ['pollVotes', 'pOpen_alice'],
  ['events', 'e1'],
  ['rsvps', 'e1_alice'],
  ['eventSeries', 's1'],
  ['groupDocuments', 'd1'],
];

/** teamA's files, one in each Storage folder. */
const TEAM_FILES = [
  'groups/teamA/avatar/logo.jpg',
  'groups/teamA/theme/bg.jpg',
  'groups/teamA/messages/m1/photo.jpg',
  'groups/teamA/documents/d1/Schedule.pdf',
];

// teamA: alice owner, bob member. teamB: gina admin. root is a
// super admin on no team; bob is on teamA only.
async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const settings = { membersCanCreateEvents: true, membersCanCreatePolls: true, membersCanUploadDocs: true };
    for (const g of ['teamA', 'teamB']) {
      await db.doc(`groups/${g}`).set({
        name: g, nameLower: g.toLowerCase(), kind: 'team', settings, storageBytes: 0, storageQuotaBytes: 100 * MB,
        archivedAt: null, suspendedAt: null,
      });
    }
    const member = (g: string, uid: string, role: string) =>
      db.doc(`groupMembers/${g}_${uid}`).set({ groupId: g, uid, role, displayName: uid, photoPath: null, playerSummary: null });
    await member('teamA', 'alice', 'owner');
    await member('teamA', 'bob', 'member');
    await member('teamB', 'gina', 'admin');
    await db.doc('players/emma').set({ groupId: 'teamA', displayName: 'Emma', displayNameLower: 'emma' });
    await db.doc('playerGuardians/emma_alice').set({ groupId: 'teamA', playerId: 'emma', uid: 'alice' });
    await db.doc('guardianRequests/emma_bob').set({ groupId: 'teamA', playerId: 'emma', uid: 'bob', status: 'pending' });
    await db.doc('messages/m1').set({ groupId: 'teamA', authorId: 'alice', authorName: 'alice', type: 'text', text: 'Hi', reactions: {} });
    const poll = (id: string, anonymous: boolean) =>
      db.doc(`polls/${id}`).set({
        groupId: 'teamA', messageId: id, createdBy: 'alice', question: 'When?', anonymous, allowMultiple: false,
        options: [{ id: '0', text: 'Sat' }, { id: '1', text: 'Sun' }], closesAt: null, closedAt: null,
        voteCounts: {}, voterCount: 0,
      });
    await poll('pOpen', false);
    await poll('pAnon', true);
    for (const p of ['pOpen', 'pAnon']) {
      await db.doc(`pollVotes/${p}_alice`).set({ pollId: p, groupId: 'teamA', uid: 'alice', optionIds: ['0'] });
    }
    await db.doc('events/e1').set({
      groupId: 'teamA', type: 'practice', title: 'Practice', rsvpEnabled: true,
      startAt: ts('2027-01-01T18:00:00Z'), endAt: ts('2027-01-01T19:00:00Z'), createdBy: 'alice',
    });
    await db.doc('rsvps/e1_alice').set({ groupId: 'teamA', eventId: 'e1', participantType: 'member', participantId: 'alice', status: 'going' });
    await db.doc('eventSeries/s1').set({ groupId: 'teamA', createdBy: 'alice' });
    await db.doc('groupDocuments/d1').set({ groupId: 'teamA', kind: 'file', name: 'Schedule.pdf', uploadedBy: 'alice' });
    await db.doc('reports/r1').set({ groupId: 'teamA', status: 'open', teamVisible: true, reporterId: 'bob', createdAt: ts('2026-10-01T00:00:00Z') });
    await db.doc('auditLogs/a1').set({ actorId: 'root', action: 'viewGroup', groupId: 'teamA', createdAt: ts('2026-10-01T00:00:00Z') });
    await db.doc('config/app').set({ allowUserGroupCreation: true, maxGroupsCreatedPerUserPerDay: 5 });
    await db.doc('users/bob').set({
      displayName: 'Bob', displayNameLower: 'bob', photoPath: null, themeMode: 'system', notificationPrefs: {}, status: 'active',
    });
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    for (const path of TEAM_FILES) {
      const type = path.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg';
      await ctx.storage().ref(path).put(jpeg, { contentType: type }).then(() => undefined);
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

/** The bounded team query View team runs on [collection]. */
const teamQuery = (db: Db, collection: string, g = 'teamA') =>
  db.collection(collection).where('groupId', '==', g).limit(50).get();

describe('View team: super admins read any team without joining (ADMIN-3)', () => {
  it('gets a document of every team collection', async () => {
    for (const [collection, id] of TEAM_DOCS) {
      await assertSucceeds(root().doc(`${collection}/${id}`).get());
    }
    await assertSucceeds(root().doc('groups/teamA').get());
  });

  it('lists every team collection, a bounded page at a time', async () => {
    for (const [collection] of TEAM_DOCS) {
      if (collection === 'pollVotes') continue; // listed by poll, below
      await assertSucceeds(teamQuery(root(), collection));
      await assertFails(root().collection(collection).where('groupId', '==', 'teamA').get());
      await assertFails(root().collection(collection).where('groupId', '==', 'teamA').limit(101).get());
    }
    await assertSucceeds(root().collection('pollVotes').where('pollId', '==', 'pOpen').limit(50).get());
  });

  it("still reads a suspended team, which its own members can't", async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ suspendedAt: ts('2026-10-01T00:00:00Z') }));
    await assertSucceeds(root().doc('messages/m1').get());
    await assertSucceeds(teamQuery(root(), 'messages'));
    await assertFails(as('bob').doc('messages/m1').get());
    await assertSucceeds(env.authenticatedContext('root', { superAdmin: true }).storage().ref(TEAM_FILES[2]).getDownloadURL());
  });

  it('reads every Storage folder of the team', async () => {
    const storage = env.authenticatedContext('root', { superAdmin: true }).storage();
    for (const path of TEAM_FILES) await assertSucceeds(storage.ref(path).getDownloadURL());
  });

  it('keeps anonymous poll votes private, super admins included (POLL-3)', async () => {
    await assertFails(root().doc('pollVotes/pAnon_alice').get());
    await assertFails(root().collection('pollVotes').where('pollId', '==', 'pAnon').limit(50).get());
    // Teammates can't either; only the voter reads their own.
    await assertFails(as('bob').doc('pollVotes/pAnon_alice').get());
    await assertSucceeds(as('alice').doc('pollVotes/pAnon_alice').get());
  });
});

describe("super admins don't take part in teams they haven't joined (SPEC §3)", () => {
  it("can't post, react, vote, or RSVP", async () => {
    const db = root();
    await assertFails(
      db.doc('messages/mRoot').set({
        groupId: 'teamA', authorId: 'root', authorName: 'Root', type: 'text', text: 'Hi', attachments: [], createdAt: now(),
      }),
    );
    await assertFails(db.doc('messages/m1').update({ reactions: { root: 'like' } }));
    await assertFails(
      db.doc('pollVotes/pOpen_root').set({ pollId: 'pOpen', groupId: 'teamA', uid: 'root', optionIds: ['1'], updatedAt: now() }),
    );
    await assertFails(
      db.doc('rsvps/e1_root').set({
        eventId: 'e1', groupId: 'teamA', participantType: 'member', participantId: 'root', participantName: 'Root',
        eventStartAt: ts('2027-01-01T18:00:00Z'), status: 'going', note: '', respondedBy: 'root', updatedAt: now(),
      }),
    );
  });

  it("can't add documents or events, edit the roster, or upload files", async () => {
    const db = root();
    await assertFails(
      db.doc('groupDocuments/dRoot').set({
        groupId: 'teamA', kind: 'link', name: 'Site', nameLower: 'site', description: '', pinned: false,
        url: 'https://example.com', uploadedBy: 'root', uploaderName: 'Root', notifyTeam: false, createdAt: now(), updatedAt: now(),
      }),
    );
    await assertFails(db.doc('players/emma').update({ displayName: 'Em', displayNameLower: 'em' }));
    await assertFails(db.doc('groupMembers/teamA_bob').update({ role: 'admin' }));
    await assertFails(db.doc('groupMembers/teamA_root').set({ groupId: 'teamA', uid: 'root', role: 'owner' }));
    const storage = env.authenticatedContext('root', { superAdmin: true }).storage();
    for (const path of ['groups/teamA/messages/m9/x.jpg', 'groups/teamA/documents/d9/x.jpg']) {
      await assertFails(storage.ref(path).put(jpeg, { contentType: 'image/jpeg' }).then(() => undefined));
    }
  });
});

describe('super admins edit a team they are not on through adminUpdateGroup (ADMIN-3)', () => {
  const upload = (path: string, data = jpeg, contentType = 'image/jpeg') =>
    env.authenticatedContext('root', { superAdmin: true }).storage().ref(path).put(data, { contentType }).then(() => undefined);

  it('uploads a new logo and chat background, which the callable then saves', async () => {
    await assertSucceeds(upload('groups/teamA/avatar/new.jpg'));
    await assertSucceeds(upload('groups/teamA/theme/new.jpg'));
  });

  it('only images, up to 10 MB, while the team has room (STORE-4)', async () => {
    await assertFails(upload('groups/teamA/avatar/new.pdf', jpeg, 'application/pdf'));
    await assertFails(upload('groups/teamA/theme/big.jpg', new Uint8Array(10 * MB + 1)));
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ storageBytes: 100 * MB }));
    await assertFails(upload('groups/teamA/avatar/new.jpg'));
  });

  it("doesn't let regular people outside the team upload them, nor super admins write the team directly", async () => {
    const gina = env.authenticatedContext('gina').storage();
    await assertFails(gina.ref('groups/teamA/avatar/new.jpg').put(jpeg, { contentType: 'image/jpeg' }).then(() => undefined));
    await assertFails(gina.ref('groups/teamA/theme/new.jpg').put(jpeg, { contentType: 'image/jpeg' }).then(() => undefined));
    await assertFails(root().doc('groups/teamA').update({ name: 'Renamed', nameLower: 'renamed', updatedAt: now() }));
  });
});

describe('regular people still see only their own teams', () => {
  it("can't read another team's collections or files", async () => {
    for (const [collection, id] of TEAM_DOCS) {
      if (collection === 'pollVotes') continue;
      await assertFails(as('gina').doc(`${collection}/${id}`).get());
      await assertFails(teamQuery(as('gina'), collection));
    }
    await assertFails(as('gina').collection('pollVotes').where('pollId', '==', 'pOpen').limit(50).get());
    const storage = env.authenticatedContext('gina').storage();
    for (const path of TEAM_FILES) await assertFails(storage.ref(path).getDownloadURL());
  });

  it('reads their own team as before', async () => {
    await assertSucceeds(as('bob').doc('messages/m1').get());
    await assertSucceeds(teamQuery(as('bob'), 'events'));
    await assertSucceeds(as('bob').collection('pollVotes').where('pollId', '==', 'pOpen').limit(50).get());
    await assertSucceeds(env.authenticatedContext('bob').storage().ref(TEAM_FILES[3]).getDownloadURL());
  });

  it("can't claim to be a super admin through their profile", async () => {
    await assertFails(as('bob').doc('users/bob').update({ superAdmin: true }));
  });
});

describe('the audit log, reports, and settings (ADMIN-5 to ADMIN-7)', () => {
  it('lets only super admins read the audit log, a page at a time', async () => {
    await assertSucceeds(root().doc('auditLogs/a1').get());
    await assertSucceeds(root().collection('auditLogs').orderBy('createdAt', 'desc').limit(50).get());
    await assertSucceeds(
      root().collection('auditLogs').where('groupId', '==', 'teamA').orderBy('createdAt', 'desc').limit(50).get(),
    );
    await assertFails(root().collection('auditLogs').orderBy('createdAt', 'desc').get());
    await assertFails(as('alice').doc('auditLogs/a1').get());
    await assertFails(as('alice').collection('auditLogs').limit(50).get());
    await assertFails(root().doc('auditLogs/a2').set({ actorId: 'root', action: 'x' }));
    await assertFails(root().doc('auditLogs/a1').delete());
  });

  it('lists reports from every team for super admins, bounded, and only their team for team admins', async () => {
    await assertSucceeds(root().collection('reports').where('status', '==', 'open').limit(50).get());
    await assertFails(root().collection('reports').where('status', '==', 'open').get());
    await assertSucceeds(
      as('alice')
        .collection('reports')
        .where('groupId', '==', 'teamA')
        .where('status', '==', 'open')
        .where('teamVisible', '==', true)
        .limit(50)
        .get(),
    );
    await assertFails(as('bob').collection('reports').where('groupId', '==', 'teamA').limit(50).get());
    await assertFails(root().doc('reports/r1').update({ status: 'dismissed' }));
  });

  it('lets everyone signed in read the settings, and nobody write them directly', async () => {
    await assertSucceeds(as('bob').doc('config/app').get());
    await assertFails(env.unauthenticatedContext().firestore().doc('config/app').get());
    // Super admins save settings through adminUpdateConfig, which audits it.
    await assertFails(root().doc('config/app').update({ allowUserGroupCreation: false }));
    await assertFails(as('bob').doc('config/app').update({ allowUserGroupCreation: false }));
  });

  it("keeps the other config docs (the super-admin lock) to Functions", async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('config/superAdmins').set({ lockedBy: 'root' }));
    await assertFails(as('bob').doc('config/superAdmins').get());
    await assertFails(root().doc('config/superAdmins').get());
  });
});
