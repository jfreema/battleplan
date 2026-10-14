// Security rules for documents (ARCH §6.3; SPEC DOC-2 to DOC-5, TEAM-5,
// TEAM-9, STORE-1, STORE-4), in Firestore and Storage.
// Run against the emulator: npm --prefix functions run emulators:test
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
const root = (): Db => env.authenticatedContext('root', { superAdmin: true }).firestore();
const put = (uid: string, path: string, contentType = 'application/pdf') =>
  env
    .authenticatedContext(uid)
    .storage()
    .ref(path)
    .put(new Uint8Array([1, 2, 3, 4]), { contentType })
    .then(() => undefined);

/** A whole document as stored, for seeding. */
const stored = (id: string, groupId: string, uploadedBy: string, extra: object = {}) => ({
  groupId,
  kind: 'file',
  name: 'Schedule.pdf',
  nameLower: 'schedule.pdf',
  description: '',
  pinned: false,
  path: `groups/${groupId}/documents/${id}/Schedule.pdf`,
  contentType: 'application/pdf',
  size: 1000,
  uploadedBy,
  uploaderName: uploadedBy,
  notifyTeam: true,
  createdAt: ts('2026-10-01T00:00:00Z'),
  updatedAt: ts('2026-10-01T00:00:00Z'),
  ...extra,
});

// teamA: alice owner, bob member, cara member. teamB: gina admin. Documents:
// dBob (bob's file) and dAlice (alice's link) on teamA, dB on teamB.
async function seed(settings: object = {}, group: object = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const s = { membersCanCreateEvents: false, membersCanCreatePolls: true, membersCanUploadDocs: true, ...settings };
    for (const g of ['teamA', 'teamB']) {
      await db.doc(`groups/${g}`).set({ name: g, nameLower: g, settings: s, storageBytes: 0, storageQuotaBytes: 100 * MB, ...group });
    }
    const member = (g: string, uid: string, role: string) =>
      db.doc(`groupMembers/${g}_${uid}`).set({ groupId: g, uid, role, displayName: uid[0].toUpperCase() + uid.slice(1), photoPath: null });
    await member('teamA', 'alice', 'owner');
    await member('teamA', 'bob', 'member');
    await member('teamA', 'cara', 'member');
    await member('teamB', 'gina', 'admin');
    await db.doc('groupDocuments/dBob').set(stored('dBob', 'teamA', 'bob', { uploaderName: 'Bob' }));
    await db.doc('groupDocuments/dAlice').set(
      stored('dAlice', 'teamA', 'alice', {
        kind: 'link', name: 'League site', nameLower: 'league site', path: null, contentType: null, size: null,
        url: 'https://league.example.com', uploaderName: 'Alice',
      }),
    );
    await db.doc('groupDocuments/dB').set(stored('dB', 'teamB', 'gina', { uploaderName: 'Gina' }));
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

/** A new file document as the app writes it, after the upload. */
const file = (uid: string, name: string, extra: object = {}, id = 'new', g = 'teamA') => ({
  groupId: g,
  kind: 'file',
  name: 'Fall roster.pdf',
  nameLower: 'fall roster.pdf',
  description: '',
  pinned: false,
  path: `groups/${g}/documents/${id}/Fall roster.pdf`,
  contentType: 'application/pdf',
  size: 2 * MB,
  uploadedBy: uid,
  uploaderName: name,
  notifyTeam: true,
  createdAt: now(),
  updatedAt: now(),
  ...extra,
});
/** A new link document. */
const link = (uid: string, name: string, extra: object = {}, g = 'teamA') => ({
  groupId: g,
  kind: 'link',
  name: 'Sign-up form',
  nameLower: 'sign-up form',
  description: 'For the fall season',
  pinned: false,
  url: 'https://forms.example.com/fall',
  uploadedBy: uid,
  uploaderName: name,
  notifyTeam: false,
  createdAt: now(),
  updatedAt: now(),
  ...extra,
});
const create = (uid: string, data: object, id = 'new') => as(uid).doc(`groupDocuments/${id}`).set(data);

describe('adding documents (DOC-2, DOC-3, TEAM-5)', () => {
  it('lets admins and members add files and links', async () => {
    await assertSucceeds(create('alice', file('alice', 'Alice')));
    await assertSucceeds(create('bob', file('bob', 'Bob', {}, 'f2'), 'f2'));
    await assertSucceeds(create('cara', link('cara', 'Cara'), 'l1'));
    await assertSucceeds(create('alice', link('alice', 'Alice', { description: '' }), 'l2'));
  });

  it('lets only admins add when membersCanUploadDocs is off', async () => {
    await seed({ membersCanUploadDocs: false });
    await assertFails(create('bob', file('bob', 'Bob')));
    await assertFails(create('bob', link('bob', 'Bob'), 'l1'));
    await assertSucceeds(create('alice', file('alice', 'Alice')));
  });

  it('lets super admins on the team add when membersCanUploadDocs is off (§3)', async () => {
    await seed({ membersCanUploadDocs: false });
    const bobRoot = env.authenticatedContext('bob', { superAdmin: true }).firestore();
    await assertSucceeds(bobRoot.doc('groupDocuments/new').set(file('bob', 'Bob')));
    // Not on the team: adding needs membership.
    await assertFails(root().doc('groupDocuments/l1').set(link('root', 'Root')));
  });

  it("treats a team that never set membersCanUploadDocs as on (TEAM-5's default)", async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('groups/teamA').update({ 'settings.membersCanUploadDocs': firebase.firestore.FieldValue.delete() }),
    );
    await assertSucceeds(create('bob', file('bob', 'Bob')));
  });

  it("requires the uploader's own uid and membership name (a snapshot, like authorName)", async () => {
    await assertFails(create('bob', file('alice', 'Alice')));
    await assertFails(create('bob', file('bob', 'Alice')));
    await assertFails(create('bob', file('bob', 'bob')));
  });

  it("keeps a file in this document's own folder of this team", async () => {
    await assertFails(create('bob', file('bob', 'Bob', { path: 'groups/teamA/documents/other/Fall roster.pdf' })));
    await assertFails(create('bob', file('bob', 'Bob', { path: 'groups/teamB/documents/new/Fall roster.pdf' })));
    await assertFails(create('bob', file('bob', 'Bob', { path: 'groups/teamA/messages/new/Fall roster.pdf' })));
    await assertFails(create('bob', file('bob', 'Bob', { path: 'groups/teamA/documents/new/sub/a.pdf' })));
    await assertFails(create('bob', file('bob', 'Bob', { path: null })));
  });

  it('keeps files to a lowered platform upload limit (ADMIN-7), links unaffected', async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('config/app').set({ maxUploadMb: 2 }));
    await assertSucceeds(create('bob', file('bob', 'Bob', { size: 2 * MB })));
    await assertFails(create('bob', file('bob', 'Bob', { size: 2 * MB + 1 }, 'f2'), 'f2'));
    await assertSucceeds(create('bob', link('bob', 'Bob'), 'l1'));
    // A setting out of range falls back to 10 MB.
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('config/app').set({ maxUploadMb: 50 }));
    await assertSucceeds(create('bob', file('bob', 'Bob', { size: 10 * MB }, 'f3'), 'f3'));
    await assertFails(create('bob', file('bob', 'Bob', { size: 10 * MB + 1 }, 'f4'), 'f4'));
  });

  it('takes allowed types up to 10 MB, and refuses bad fields', async () => {
    await assertSucceeds(create('bob', file('bob', 'Bob', { contentType: 'image/png' })));
    await assertSucceeds(create('bob', file('bob', 'Bob', { size: 10 * MB }, 'f2'), 'f2'));
    for (const bad of [
      { contentType: 'application/zip' },
      { contentType: null },
      { size: 10 * MB + 1 },
      { size: '100' },
      { name: '' },
      { name: '   ', nameLower: '   ' },
      { name: 'x'.repeat(101), nameLower: 'x'.repeat(101) },
      { nameLower: 'Fall roster.pdf' },
      { description: 'x'.repeat(501) },
      { description: null },
      { url: 'https://example.com' },
      { notifyTeam: 'yes' },
      { createdAt: ts('2026-10-01T00:00:00Z') },
      { updatedAt: ts('2026-10-01T00:00:00Z') },
      { kind: 'folder' },
      { extra: 1 },
    ]) {
      await assertFails(create('bob', file('bob', 'Bob', bad, 'f3'), 'f3'));
    }
  });

  it('takes http(s) links up to 2,000 characters, with no file fields', async () => {
    await assertSucceeds(create('bob', link('bob', 'Bob', { url: 'http://example.com' }), 'l1'));
    await assertSucceeds(create('bob', link('bob', 'Bob', { url: 'HTTPS://EXAMPLE.COM/' + 'a'.repeat(1970) }), 'l2'));
    for (const bad of [
      { url: 'ftp://example.com' },
      { url: 'javascript:alert(1)' },
      { url: 'https://' },
      { url: 'https://example.com/' + 'a'.repeat(2000) },
      { url: null },
      { path: 'groups/teamA/documents/l3/a.pdf' },
      { size: 10 },
      { contentType: 'application/pdf' },
    ]) {
      await assertFails(create('bob', link('bob', 'Bob', bad), 'l3'));
    }
  });

  it('lets only admins add a pinned document', async () => {
    await assertFails(create('bob', file('bob', 'Bob', { pinned: true })));
    await assertSucceeds(create('alice', file('alice', 'Alice', { pinned: true })));
  });

  it('allows links when storage is full (STORE-4), since they store nothing', async () => {
    await seed({}, { storageBytes: 100 * MB });
    await assertSucceeds(create('bob', link('bob', 'Bob'), 'l1'));
  });

  it('refuses archived teams and other teams (TEAM-9)', async () => {
    await assertFails(create('gina', file('gina', 'Gina')));
    await assertFails(create('bob', file('bob', 'Bob', {}, 'new', 'teamB')));
    await seed({}, { archivedAt: ts('2026-10-01T00:00:00Z') });
    await assertFails(create('alice', file('alice', 'Alice')));
    await assertFails(create('alice', link('alice', 'Alice'), 'l1'));
  });
});

describe('managing documents (DOC-5)', () => {
  const edit = (uid: string, id: string, changes: object, db = as(uid)) =>
    db.doc(`groupDocuments/${id}`).update({ updatedAt: now(), ...changes });

  it('lets the uploader and admins rename and edit the description', async () => {
    await assertSucceeds(edit('bob', 'dBob', { name: 'Spring.pdf', nameLower: 'spring.pdf' }));
    await assertSucceeds(edit('bob', 'dBob', { description: 'Updated' }));
    await assertSucceeds(edit('alice', 'dBob', { description: 'Checked' }));
    await assertFails(edit('cara', 'dBob', { description: 'Mine now' }));
    await assertFails(edit('bob', 'dAlice', { name: 'Mine', nameLower: 'mine' }));
  });

  it('lets only admins pin and unpin', async () => {
    await assertFails(edit('bob', 'dBob', { pinned: true }));
    await assertSucceeds(edit('alice', 'dBob', { pinned: true }));
    await assertSucceeds(edit('alice', 'dBob', { pinned: false }));
  });

  it('lets super admins pin, rename, and edit on any team (§3), not only admins on theirs', async () => {
    const root = env.authenticatedContext('root', { superAdmin: true }).firestore();
    await assertSucceeds(edit('root', 'dBob', { pinned: true }, root));
    await assertSucceeds(edit('root', 'dBob', { pinned: false }, root));
    await assertSucceeds(edit('root', 'dBob', { name: 'Spring.pdf', nameLower: 'spring.pdf', description: 'Fixed' }, root));
  });

  it('keeps everything else fixed, and checks the new values', async () => {
    for (const changes of [
      { path: 'groups/teamA/documents/dBob/Other.pdf' },
      { size: 1 },
      { contentType: 'image/png' },
      { kind: 'link' },
      { groupId: 'teamB' },
      { uploadedBy: 'alice' },
      { uploaderName: 'Someone' },
      { notifyTeam: false },
      { createdAt: now() },
      { name: '', nameLower: '' },
      { name: 'New', nameLower: 'NEW' },
      { description: 'x'.repeat(501) },
    ]) {
      await assertFails(edit('alice', 'dBob', changes));
    }
    // updatedAt is the request time.
    await assertFails(edit('alice', 'dBob', { description: 'x', updatedAt: ts('2026-10-01T00:00:00Z') }));
  });

  it('lets the uploader, admins, and super admins delete', async () => {
    await assertFails(as('cara').doc('groupDocuments/dBob').delete());
    await assertFails(as('bob').doc('groupDocuments/dAlice').delete());
    await assertSucceeds(as('bob').doc('groupDocuments/dBob').delete());
    await assertSucceeds(as('alice').doc('groupDocuments/dAlice').delete());
    await assertSucceeds(root().doc('groupDocuments/dB').delete());
  });

  it('keeps an uploader who left out', async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groupMembers/teamA_bob').delete());
    await assertFails(edit('bob', 'dBob', { description: 'x' }));
    await assertFails(as('bob').doc('groupDocuments/dBob').delete());
  });

  it("refuses other teams' documents", async () => {
    await assertFails(edit('alice', 'dB', { description: 'x' }));
    await assertFails(as('alice').doc('groupDocuments/dB').delete());
    await assertFails(edit('gina', 'dBob', { pinned: true }));
  });

  it('makes archived teams read-only (TEAM-9)', async () => {
    await seed({}, { archivedAt: ts('2026-10-01T00:00:00Z') });
    await assertFails(edit('alice', 'dBob', { pinned: true }));
    await assertFails(edit('bob', 'dBob', { description: 'x' }));
    await assertFails(as('alice').doc('groupDocuments/dBob').delete());
    await assertFails(root().doc('groupDocuments/dBob').delete());
  });
});

describe('reading documents (DOC-1)', () => {
  it('shows documents to members only, in bounded queries', async () => {
    const q = (uid: string, g: string) =>
      as(uid).collection('groupDocuments').where('groupId', '==', g).orderBy('pinned', 'desc').orderBy('createdAt', 'desc').limit(50).get();
    await assertSucceeds(q('bob', 'teamA'));
    await assertSucceeds(as('bob').collection('groupDocuments').where('groupId', '==', 'teamA').orderBy('nameLower').limit(50).get());
    await assertSucceeds(as('bob').doc('groupDocuments/dBob').get());
    await assertFails(q('gina', 'teamA'));
    await assertFails(as('gina').doc('groupDocuments/dBob').get());
    await assertFails(as('bob').collection('groupDocuments').where('groupId', '==', 'teamA').get());
  });
});

describe('document files in Storage (DOC-2, STORE-1, STORE-4)', () => {
  it('lets members upload allowed types to a document folder, and only admins when members may not', async () => {
    await assertSucceeds(put('bob', 'groups/teamA/documents/d1/a.pdf'));
    await assertSucceeds(put('bob', 'groups/teamA/documents/d2/b.csv', 'text/csv'));
    await assertFails(put('bob', 'groups/teamA/documents/d3/c.zip', 'application/zip'));
    await assertFails(put('gina', 'groups/teamA/documents/d4/d.pdf'));
    await seed({ membersCanUploadDocs: false });
    await assertFails(put('bob', 'groups/teamA/documents/d5/e.pdf'));
    await assertSucceeds(put('alice', 'groups/teamA/documents/d6/f.pdf'));
    // Super admins on the team, whatever the switch (§3); not off it.
    const upload = (uid: string, path: string) =>
      env.authenticatedContext(uid, { superAdmin: true }).storage().ref(path)
        .put(new Uint8Array([1, 2, 3, 4]), { contentType: 'application/pdf' })
        .then(() => undefined);
    await assertSucceeds(upload('bob', 'groups/teamA/documents/d7/g.pdf'));
    await assertFails(upload('root', 'groups/teamA/documents/d8/h.pdf'));
  });

  it("follows TEAM-5's default when the team never set the switch", async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('groups/teamA').update({ 'settings.membersCanUploadDocs': firebase.firestore.FieldValue.delete() }),
    );
    await assertSucceeds(put('bob', 'groups/teamA/documents/d1/a.pdf'));
  });

  it('refuses uploads when storage is full', async () => {
    await seed({}, { storageBytes: 100 * MB });
    await assertFails(put('alice', 'groups/teamA/documents/d1/a.pdf'));
  });

  it('never lets clients delete document files', async () => {
    await assertSucceeds(put('bob', 'groups/teamA/documents/d1/a.pdf'));
    await assertFails(env.authenticatedContext('bob').storage().ref('groups/teamA/documents/d1/a.pdf').delete());
    await assertFails(env.authenticatedContext('alice').storage().ref('groups/teamA/documents/d1/a.pdf').delete());
  });
});
