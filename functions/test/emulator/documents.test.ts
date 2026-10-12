// Documents on the server (SPEC DOC-5, DOC-6, STORE-5, SAFE-1, AUTH-10):
// the groupDocuments triggers' work, Media's view and deletes of document
// files, the daily cleanup of uploads whose document was never created,
// reports of documents, and account deletion. Runs against the Firestore
// and Storage emulators with FCM faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import type { TokenMessage } from 'firebase-admin/messaging';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { anonymizeUploader, removeAllOrphanDocumentFiles } from '../../src/documents/service.js';
import { onDocumentCreated, onDocumentDeleted } from '../../src/documents/triggers.js';
import { auditDocumentDeleted, auditEventDeleted } from '../../src/audit/triggers.js';
import { reportContent, resolveReport } from '../../src/safety/handlers.js';
import { deleteTeamMedia, listTeamMedia } from '../../src/teams/handlers.js';
import { db, storage } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';

// FCM stand-in: records every batch and accepts every token.
const fcm = vi.hoisted(() => ({ batches: [] as TokenMessage[][] }));
vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({
    sendEach: async (messages: TokenMessage[]) => {
      fcm.batches.push(messages);
      return {
        responses: messages.map((m) => ({ success: true, messageId: `id-${m.token}` })),
        successCount: messages.length,
        failureCount: 0,
      };
    },
  }),
}));

const G = 'teamA';
const DAY = 86_400_000;
const pushes = () => fcm.batches.flat().map((m) => `${m.token}:${m.notification?.body}`).sort();

type CallRequest = Parameters<typeof listTeamMedia.run>[0];
const call = (uid: string, data: object, token: object = {}) =>
  ({ data, auth: { uid, token }, rawRequest: {} }) as unknown as CallRequest;

type CreatedEvent = Parameters<typeof onDocumentCreated.run>[0];
type DeletedEvent = Parameters<typeof onDocumentDeleted.run>[0];
/** A groupDocuments trigger event for [docId], as Firestore sends it. */
const event = (docId: string, data: object | undefined) =>
  ({ params: { docId }, data: data && { id: docId, data: () => data } }) as unknown;

async function person(uid: string, role = 'member', extra: object = {}): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(G, uid)).set({
    groupId: G, uid, role, displayName: uid[0].toUpperCase() + uid.slice(1), notificationLevel: 'all', mutedUntil: null, ...extra,
  });
  await db().collection(Collections.users).doc(uid).set({ displayName: uid, status: 'active', notificationPrefs: {} });
  await db().collection(Collections.devices).doc(`dev-${uid}`).set({
    uid, token: `tok-${uid}`, platform: 'ios', appVersion: '1.0.0', updatedAt: Timestamp.now(),
  });
}

/** A file document's record, as the app writes it. */
const fileDoc = (id: string, extra: object = {}) => ({
  groupId: G,
  kind: 'file',
  name: 'Fall roster.pdf',
  nameLower: 'fall roster.pdf',
  description: '',
  pinned: false,
  path: `groups/${G}/documents/${id}/Fall roster.pdf`,
  contentType: 'application/pdf',
  size: 4,
  uploadedBy: 'sam',
  uploaderName: 'Sam',
  notifyTeam: true,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
  ...extra,
});
const linkDoc = (extra: object = {}) => ({
  ...fileDoc('x'),
  kind: 'link',
  name: 'League site',
  nameLower: 'league site',
  path: null,
  contentType: null,
  size: null,
  url: 'https://league.example.com',
  ...extra,
});

async function file(path: string, bytes = 4, contentType = 'application/pdf'): Promise<void> {
  await storage().bucket().file(path).save(Buffer.alloc(bytes), { contentType, resumable: false });
}
async function fileExists(path: string): Promise<boolean> {
  const [exists] = await storage().bucket().file(path).exists();
  return exists;
}
const docRef = (id: string) => db().collection(Collections.groupDocuments).doc(id);
/** Who has a center item for [key], sorted. */
async function centerFor(key: string): Promise<string[]> {
  const snap = await db().collection(Collections.notifications).get();
  return snap.docs.filter((d) => d.id === `${key}_${d.get('uid')}`).map((d) => d.get('uid') as string).sort();
}

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
    throw new Error('Run with npm run emulators:test');
  }
});

beforeEach(async () => {
  const project = process.env.GCLOUD_PROJECT ?? 'demo-battleplan';
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  expect(res.ok).toBe(true);
  await storage().bucket().deleteFiles({ prefix: 'groups/' });
  fcm.batches.length = 0;
  await db().collection(Collections.groups).doc(G).set({
    name: 'Thunder', photoPath: null, storageBytes: 0, storageQuotaBytes: 100 * 1024 * 1024, storageAlert: 'none',
  });
  await person('pat', 'owner');
  await person('sam');
  await person('lee');
});

describe('a new document notifies the team (DOC-6)', () => {
  it('tells everyone but the uploader, with the file name', async () => {
    await onDocumentCreated.run(event('d1', fileDoc('d1')) as CreatedEvent);
    expect(pushes()).toEqual(['tok-lee:New document: Fall roster.pdf', 'tok-pat:New document: Fall roster.pdf']);
    const m = fcm.batches.flat()[0];
    expect(m.data).toMatchObject({ kind: 'documentAdded', groupId: G, route: `/g/${G}/documents/d/d1`, nkey: 'd1_added' });
    expect(m.android?.notification?.channelId).toBe('documents');
    expect(await centerFor('d1_added')).toEqual(['lee', 'pat']);
    const item = (await db().collection(Collections.notifications).doc('d1_added_pat').get()).data();
    expect(item).toMatchObject({ actorId: 'sam', targetType: 'document', targetId: 'd1', type: 'documentAdded' });
  });

  it('words links as links', async () => {
    await onDocumentCreated.run(event('l1', linkDoc()) as CreatedEvent);
    expect(pushes()).toEqual(['tok-lee:New link: League site', 'tok-pat:New link: League site']);
  });

  it('says nothing when Notify team is off', async () => {
    await onDocumentCreated.run(event('d1', fileDoc('d1', { notifyTeam: false })) as CreatedEvent);
    expect(pushes()).toEqual([]);
    expect(await centerFor('d1_added')).toEqual([]);
  });

  it('notifies once when the trigger runs twice', async () => {
    await onDocumentCreated.run(event('d1', fileDoc('d1')) as CreatedEvent);
    await onDocumentCreated.run(event('d1', fileDoc('d1')) as CreatedEvent);
    expect(pushes()).toHaveLength(2);
  });

  it('follows the Documents switch for pushes, and still writes center items', async () => {
    await db().collection(Collections.users).doc('lee').update({ notificationPrefs: { documents: false } });
    await onDocumentCreated.run(event('d1', fileDoc('d1')) as CreatedEvent);
    expect(pushes()).toEqual(['tok-pat:New document: Fall roster.pdf']);
    expect(await centerFor('d1_added')).toEqual(['lee', 'pat']);
  });
});

describe('deleting a document (DOC-5)', () => {
  it('removes its file, an earlier upload in its folder, and the center items about it', async () => {
    await file(`groups/${G}/documents/d1/Fall roster.pdf`);
    await file(`groups/${G}/documents/d1/old.pdf`);
    await file(`groups/${G}/documents/d2/keep.pdf`);
    await onDocumentCreated.run(event('d1', fileDoc('d1')) as CreatedEvent);
    expect(await centerFor('d1_added')).toEqual(['lee', 'pat']);

    await onDocumentDeleted.run(event('d1', fileDoc('d1')) as DeletedEvent);

    expect(await fileExists(`groups/${G}/documents/d1/Fall roster.pdf`)).toBe(false);
    expect(await fileExists(`groups/${G}/documents/d1/old.pdf`)).toBe(false);
    expect(await fileExists(`groups/${G}/documents/d2/keep.pdf`)).toBe(true);
    expect(await centerFor('d1_added')).toEqual([]);
    // A retry finds nothing left to do.
    await onDocumentDeleted.run(event('d1', fileDoc('d1')) as DeletedEvent);
  });

  it('removes the center items of a link', async () => {
    await onDocumentCreated.run(event('l1', linkDoc()) as CreatedEvent);
    await onDocumentDeleted.run(event('l1', linkDoc()) as DeletedEvent);
    expect(await centerFor('l1_added')).toEqual([]);
  });
});

describe('document files in Media (STORE-5)', () => {
  it("lists a document file with its document's name and uploader", async () => {
    await file(`groups/${G}/documents/d1/Fall roster.pdf`, 50);
    await file(`groups/${G}/documents/d1/old.pdf`, 40);
    await file(`groups/${G}/documents/gone/x.pdf`, 30);
    await file(`groups/teamB/documents/dB/b.pdf`, 20);
    await docRef('d1').set(fileDoc('d1'));
    // Another team's record never names this team's file.
    await docRef('gone').set({ ...fileDoc('gone'), groupId: 'teamB', path: `groups/teamB/documents/gone/x.pdf` });

    const res = await listTeamMedia.run(call('pat', { groupId: G }));

    expect(res.items.map((f) => [f.path.replace(`groups/${G}/`, ''), f.kind, f.documentId, f.documentName ?? null, f.authorName ?? null, f.current])).toEqual([
      ['documents/d1/Fall roster.pdf', 'document', 'd1', 'Fall roster.pdf', 'Sam', true],
      ['documents/d1/old.pdf', 'document', 'd1', 'Fall roster.pdf', 'Sam', false],
      ['documents/gone/x.pdf', 'document', 'gone', null, null, false],
    ]);
  });

  it('deletes the document with its file, and audits it', async () => {
    await file(`groups/${G}/documents/d1/Fall roster.pdf`);
    await docRef('d1').set(fileDoc('d1'));

    const res = await deleteTeamMedia.run(call('pat', { groupId: G, path: `groups/${G}/documents/d1/Fall roster.pdf` }));

    expect(res).toEqual({ ok: true, kind: 'document', fixed: 'deletedDocument' });
    expect((await docRef('d1').get()).exists).toBe(false);
    expect(await fileExists(`groups/${G}/documents/d1/Fall roster.pdf`)).toBe(false);
    const audit = await db().collection(Collections.auditLogs).where('action', '==', 'deleteTeamMedia').get();
    expect(audit.docs[0].get('before')).toMatchObject({ kind: 'document', documentId: 'd1' });
  });

  it("leaves the document when the file isn't the one it points at", async () => {
    await file(`groups/${G}/documents/d1/old.pdf`);
    await docRef('d1').set(fileDoc('d1'));
    const res = await deleteTeamMedia.run(call('pat', { groupId: G, path: `groups/${G}/documents/d1/old.pdf` }));
    expect(res.fixed).toBe('none');
    expect((await docRef('d1').get()).exists).toBe(true);
    expect(await fileExists(`groups/${G}/documents/d1/old.pdf`)).toBe(false);
  });
});

describe('uploads whose document was never created (dailyCleanup)', () => {
  it('removes them after a day, and keeps every file a document uses', async () => {
    await file(`groups/${G}/documents/d1/Fall roster.pdf`);
    await file(`groups/${G}/documents/d1/retry.pdf`);
    await file(`groups/${G}/documents/never/a.pdf`);
    await file(`groups/${G}/messages/m1/0.jpg`, 4, 'image/jpeg');
    await docRef('d1').set(fileDoc('d1'));

    // Files just uploaded are left alone: their document may be on its way.
    expect(await removeAllOrphanDocumentFiles()).toBe(0);
    expect(await fileExists(`groups/${G}/documents/never/a.pdf`)).toBe(true);

    expect(await removeAllOrphanDocumentFiles(Date.now() + 2 * DAY)).toBe(2);
    expect(await fileExists(`groups/${G}/documents/d1/Fall roster.pdf`)).toBe(true);
    expect(await fileExists(`groups/${G}/documents/d1/retry.pdf`)).toBe(false);
    expect(await fileExists(`groups/${G}/documents/never/a.pdf`)).toBe(false);
    expect(await fileExists(`groups/${G}/messages/m1/0.jpg`)).toBe(true);
  });
});

describe('reporting a document (SAFE-1)', () => {
  it("files the document's name and uploader for the admins", async () => {
    await docRef('d1').set(fileDoc('d1'));
    const { reportId } = await reportContent.run(
      call('lee', { groupId: G, targetType: 'document', targetId: 'd1', reason: 'inappropriate' }) as never,
    );
    const report = (await db().collection(Collections.reports).doc(reportId).get()).data();
    expect(report).toMatchObject({
      targetType: 'document', targetId: 'd1', subjectId: 'sam', subjectName: 'Sam', excerpt: 'Fall roster.pdf', teamVisible: true,
    });
    // The admins hear about it; the reporter and the uploader don't.
    expect(pushes()).toEqual(['tok-pat:A document was reported']);
  });

  it("refuses another team's document", async () => {
    await docRef('dB').set({ ...fileDoc('dB'), groupId: 'teamB' });
    await expect(
      reportContent.run(call('lee', { groupId: G, targetType: 'document', targetId: 'dB', reason: 'spam' }) as never),
    ).rejects.toMatchObject({ code: 'not-found' });
  });
});

describe('a report about a team admin (SAFE-1)', () => {
  it('goes to super admins only: not shown to the team, nobody told, and closed only by a super admin', async () => {
    await docRef('d1').set(fileDoc('d1', { uploadedBy: 'pat', uploaderName: 'Pat' }));
    const { reportId } = await reportContent.run(
      call('lee', { groupId: G, targetType: 'document', targetId: 'd1', reason: 'harassment' }) as never,
    );
    const ref = db().collection(Collections.reports).doc(reportId);
    expect((await ref.get()).data()).toMatchObject({ subjectId: 'pat', teamVisible: false, status: 'open' });
    expect(pushes()).toEqual([]);
    await expect(
      resolveReport.run(call('pat', { reportId, outcome: 'dismissed', resolution: 'none' }) as never),
    ).rejects.toMatchObject({ code: 'permission-denied' });
    expect((await ref.get()).get('status')).toBe('open');
    await resolveReport.run(call('root', { reportId, outcome: 'dismissed', resolution: 'none' }, { superAdmin: true }) as never);
    expect((await ref.get()).get('status')).toBe('dismissed');
  });

  it("covers a report about a person who's an admin", async () => {
    await person('ash', 'admin');
    const { reportId } = await reportContent.run(
      call('lee', { groupId: G, targetType: 'user', targetId: 'ash', reason: 'spam' }) as never,
    );
    expect((await db().collection(Collections.reports).doc(reportId).get()).get('teamVisible')).toBe(false);
  });
});

describe('deletes made in the app (ADMIN-6, ADMIN-8)', () => {
  type DocDeleted = Parameters<typeof auditDocumentDeleted.run>[0];
  type EventDeleted = Parameters<typeof auditEventDeleted.run>[0];
  /** A delete trigger event, with who made the write. */
  const deleted = (param: string, id: string, data: object, authType: string, authId?: string) =>
    ({ params: { [param]: id }, data: { id, data: () => data }, authType, authId }) as unknown;
  const audits = async () =>
    (await db().collection(Collections.auditLogs).get()).docs.map((d) => d.data());

  it("audits an admin deleting someone else's document or event", async () => {
    await auditDocumentDeleted.run(deleted('docId', 'd1', fileDoc('d1'), 'app_user', 'pat') as DocDeleted);
    await auditEventDeleted.run(
      deleted('eventId', 'e1', { groupId: G, title: 'Practice', type: 'practice', createdBy: 'sam' }, 'app_user', 'root') as EventDeleted,
    );
    const entries = (await audits()).sort((a, b) => String(a.action).localeCompare(String(b.action)));
    expect(entries).toEqual([
      expect.objectContaining({
        actorId: 'pat', action: 'deleteDocument', groupId: G, targetType: 'document', targetId: 'd1',
        before: { name: 'Fall roster.pdf', kind: 'file', uploadedBy: 'sam' },
      }),
      expect.objectContaining({
        actorId: 'root', action: 'deleteEvent', groupId: G, targetType: 'event', targetId: 'e1',
        before: { title: 'Practice', type: 'practice', createdBy: 'sam' },
      }),
    ]);
  });

  it('leaves out deletes by the author and by Functions, which audit their own', async () => {
    await auditDocumentDeleted.run(deleted('docId', 'd1', fileDoc('d1'), 'app_user', 'sam') as DocDeleted);
    await auditDocumentDeleted.run(deleted('docId', 'd2', fileDoc('d2'), 'service_account', 'functions@example') as DocDeleted);
    await auditEventDeleted.run(
      deleted('eventId', 'e1', { groupId: G, title: 'Game', createdBy: 'pat' }, 'app_user', 'pat') as EventDeleted,
    );
    await auditEventDeleted.run(deleted('eventId', 'e2', { groupId: G, title: 'Game', createdBy: 'pat' }, 'system') as EventDeleted);
    expect(await audits()).toEqual([]);
  });
});

describe('a deleted account (AUTH-10)', () => {
  it('keeps its documents, added by "Deleted user"', async () => {
    await docRef('d1').set(fileDoc('d1'));
    await docRef('d2').set(fileDoc('d2', { uploadedBy: 'lee', uploaderName: 'Lee' }));
    await anonymizeUploader('sam');
    expect((await docRef('d1').get()).data()).toMatchObject({ uploadedBy: 'sam', uploaderName: 'Deleted user' });
    expect((await docRef('d2').get()).get('uploaderName')).toBe('Lee');
  });
});
