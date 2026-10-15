// Importing GroupMe's history (SPEC IMPORT-9): messages as they were, with
// their photos and replies' quotes, shared files as documents, and events,
// none of it notifying anyone, and none of it twice. Runs against the
// Firestore and Storage emulators:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { onMessageCreated } from '../../src/chat/triggers.js';
import { importDocuments as importDocumentsCallable, importEvents as importEventsCallable, importMessages as importMessagesCallable } from '../../src/imports/handlers.js';
import { importDocuments, importedItemId, importMessages, type ImportedMessage } from '../../src/imports/messages.js';
import { importedEventId, importEvents } from '../../src/imports/service.js';
import { db, storage } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';

const sent: unknown[] = [];
vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({
    sendEach: async (m: unknown[]) => {
      sent.push(...m);
      return { responses: [], successCount: 0, failureCount: 0 };
    },
  }),
}));

const G = 'teamA';
const DAY = 86_400_000;
const T0 = Date.UTC(2025, 2, 3, 18);
const caller = (uid: string, superAdmin = false) => ({ uid, superAdmin });
const mid = (sourceId: string) => importedItemId(G, 'groupme', 'message', sourceId);
const did = (sourceId: string) => importedItemId(G, 'groupme', 'document', sourceId);

function gm(sourceId: string, extra: Partial<ImportedMessage> = {}): ImportedMessage {
  return { sourceId, authorSourceId: 'u1', authorName: 'Sam', text: `Message ${sourceId}`, createdAtMs: T0 + Number(sourceId) * 60_000, photos: [], ...extra };
}

async function person(uid: string, role = 'member'): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(G, uid)).set({
    groupId: G, uid, role, displayName: uid, photoPath: null, notificationLevel: 'all',
  });
  await db().collection(Collections.users).doc(uid).set({ displayName: uid, status: 'active', notificationPrefs: {} });
  await db().collection(Collections.devices).doc(`dev-${uid}`).set({ uid, token: `tok-${uid}`, platform: 'web' });
}

async function file(path: string, contentType = 'image/jpeg', bytes = 8): Promise<void> {
  await storage().bucket().file(path).save(Buffer.alloc(bytes), { contentType, resumable: false });
}

type Call = Parameters<typeof importMessagesCallable.run>[0];
const call = (fn: { run: (r: Call) => unknown }, data: object) =>
  fn.run({ data, auth: { uid: 'alex', token: {} }, rawRequest: {} } as unknown as Call);

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with npm run emulators:test');
});

beforeEach(async () => {
  const project = process.env.GCLOUD_PROJECT ?? 'demo-battleplan';
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  expect(res.ok).toBe(true);
  await storage().bucket().deleteFiles({ prefix: 'groups/' });
  sent.length = 0;
  await db().collection(Collections.groups).doc(G).set({
    name: 'Thunder', kind: 'team', timeZone: 'America/Chicago',
    settings: { defaultReminderOffsets: [60] },
    storageBytes: 0, storageQuotaBytes: 1_000_000,
  });
  await person('alex', 'owner');
  await person('pat');
});

describe('messages (IMPORT-9)', () => {
  it('are written as GroupMe had them: the name, the time, and where they came from', async () => {
    const res = await importMessages({ groupId: G, source: 'groupme', messages: [gm('1'), gm('2', { authorSourceId: 'u2', authorName: 'Riley', text: 'See you there' })] }, caller('alex'));
    expect(res).toEqual({ added: 2, alreadyImported: 0, photosMissing: 0 });
    const m2 = (await db().collection(Collections.messages).doc(mid('2')).get()).data()!;
    expect(m2).toMatchObject({
      groupId: G, authorId: 'groupme:u2', authorName: 'Riley', authorPhotoPath: null, type: 'text', text: 'See you there',
      attachments: [], reactions: {}, imported: { source: 'groupme', sourceId: '2', importedBy: 'alex' },
    });
    expect((m2.createdAt as Timestamp).toMillis()).toBe(T0 + 2 * 60_000);
    // The team list shows the newest.
    const team = (await db().collection(Collections.groups).doc(G).get()).data()!;
    expect((team.lastMessageAt as Timestamp).toMillis()).toBe(T0 + 2 * 60_000);
    expect(team.lastMessagePreview).toMatchObject({ authorName: 'Riley', text: 'See you there' });
  });

  it("notify no one, and leave the team's newer messages first in the list", async () => {
    await db().collection(Collections.groups).doc(G).update({ lastMessageAt: Timestamp.fromMillis(T0 + DAY), lastMessagePreview: { authorName: 'Pat', text: 'Newer', type: 'text' } });
    await importMessages({ groupId: G, source: 'groupme', messages: [gm('1', { text: '@Pat hello' })] }, caller('alex'));
    const snap = await db().collection(Collections.messages).doc(mid('1')).get();
    await onMessageCreated.run({ data: snap, params: { messageId: mid('1') } } as unknown as Parameters<typeof onMessageCreated.run>[0]);
    expect(sent).toEqual([]);
    expect((await db().collection(Collections.notifications).get()).size).toBe(0);
    expect((await db().collection(Collections.groups).doc(G).get()).get('lastMessagePreview.text')).toBe('Newer');
  });

  it('quote the message they reply to, from the same batch or an earlier one', async () => {
    await importMessages({ groupId: G, source: 'groupme', messages: [gm('1', { text: 'Field 3?\nOr 4' })] }, caller('alex'));
    await importMessages({ groupId: G, source: 'groupme', messages: [gm('2', { text: 'Yes', replyToSourceId: '1' }), gm('3', { text: 'Ok', replyToSourceId: '2' }), gm('4', { replyToSourceId: '99' })] }, caller('alex'));
    const doc = async (id: string) => (await db().collection(Collections.messages).doc(mid(id)).get()).data()!;
    expect(await doc('2')).toMatchObject({ replyToId: mid('1'), replyPreview: { authorName: 'Sam', text: 'Field 3?', type: 'text', deleted: false } });
    expect(await doc('3')).toMatchObject({ replyToId: mid('2'), replyPreview: { text: 'Yes', deleted: false } });
    // One that wasn't imported reads as gone.
    expect(await doc('4')).toMatchObject({ replyPreview: { deleted: true } });
  });

  it('keep only photos uploaded to their own folder', async () => {
    const own = `groups/${G}/messages/${mid('1')}/0.jpg`;
    await file(own);
    await file(`groups/${G}/messages/other/0.jpg`);
    const res = await importMessages(
      {
        groupId: G,
        source: 'groupme',
        messages: [
          gm('1', { text: '', photos: [{ path: own, width: 800, height: 600 }, { path: `groups/${G}/messages/other/0.jpg`, width: 1, height: 1 }] }),
          gm('2', { text: '', photos: [{ path: `groups/${G}/messages/${mid('2')}/0.jpg`, width: 1, height: 1 }] }),
        ],
      },
      caller('alex'),
    );
    expect(res).toEqual({ added: 1, alreadyImported: 0, photosMissing: 2 });
    const m1 = (await db().collection(Collections.messages).doc(mid('1')).get()).data()!;
    expect(m1).toMatchObject({ type: 'image', attachments: [{ path: own, contentType: 'image/jpeg', width: 800, height: 600, size: 8 }] });
    // A photo-only message whose photo never arrived isn't written.
    expect((await db().collection(Collections.messages).doc(mid('2')).get()).exists).toBe(false);
  });

  it('come in once, however often the import runs', async () => {
    const batch = { groupId: G, source: 'groupme' as const, messages: [gm('1'), gm('2')] };
    await importMessages(batch, caller('alex'));
    await db().collection(Collections.messages).doc(mid('1')).update({ 'reactions.pat': 'heart' });
    expect(await importMessages(batch, caller('alex'))).toEqual({ added: 0, alreadyImported: 2, photosMissing: 0 });
    expect((await db().collection(Collections.messages).where('groupId', '==', G).get()).size).toBe(2);
    expect((await db().collection(Collections.messages).doc(mid('1')).get()).get('reactions')).toEqual({ pat: 'heart' });
    // Another team importing the same group gets its own copies.
    expect(importedItemId('teamB', 'groupme', 'message', '1')).not.toBe(mid('1'));
  });

  it('can be checked first, so photos go up only for new ones', async () => {
    await importMessages({ groupId: G, source: 'groupme', messages: [gm('1')] }, caller('alex'));
    expect(await importMessages({ groupId: G, source: 'groupme', messages: [gm('1'), gm('2')], dryRun: true }, caller('alex'))).toEqual({
      added: 1,
      alreadyImported: 1,
      photosMissing: 0,
      existing: ['1'],
    });
    expect((await db().collection(Collections.messages).doc(mid('2')).get()).exists).toBe(false);
  });

  it('are for team admins and super admins, on open teams', async () => {
    const batch = { groupId: G, source: 'groupme' as const, messages: [gm('1')] };
    await expect(importMessages(batch, caller('pat'))).rejects.toMatchObject({ code: 'permission-denied' });
    expect(await importMessages(batch, caller('root', true))).toMatchObject({ added: 1 });
    await db().collection(Collections.groups).doc(G).update({ archivedAt: Timestamp.now() });
    await expect(importMessages(batch, caller('alex'))).rejects.toMatchObject({ message: 'team-archived' });
  });

  it('check the callable input', async () => {
    await expect(call(importMessagesCallable, { groupId: G, source: 'teamreach', messages: [gm('1')] })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call(importMessagesCallable, { groupId: G, source: 'groupme', messages: [] })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call(importMessagesCallable, { groupId: G, source: 'groupme', messages: [gm('../x')] })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call(importMessagesCallable, { groupId: G, source: 'groupme', messages: [gm('1', { createdAtMs: Date.now() + 7 * DAY })] })).rejects.toMatchObject({
      code: 'invalid-argument',
    });
    expect(await call(importMessagesCallable, { groupId: G, source: 'groupme', messages: [gm('1')] })).toMatchObject({ added: 1 });
  });
});

describe('documents (IMPORT-9)', () => {
  it('are added quietly, named for who shared them in GroupMe', async () => {
    const path = `groups/${G}/documents/${did('f1')}/rules.pdf`;
    await file(path, 'application/pdf', 20);
    const res = await importDocuments(
      {
        groupId: G,
        source: 'groupme',
        documents: [
          { sourceId: 'f1', name: 'rules.pdf', path, sharedByName: 'Riley', sharedAtMs: T0 },
          { sourceId: 'f2', name: 'lost.pdf', path: `groups/${G}/documents/${did('f2')}/lost.pdf`, sharedByName: 'Riley', sharedAtMs: T0 },
        ],
      },
      caller('alex'),
    );
    expect(res).toEqual({ added: 1, alreadyImported: 0, missing: 1 });
    const d = (await db().collection(Collections.groupDocuments).doc(did('f1')).get()).data()!;
    expect(d).toMatchObject({
      groupId: G, kind: 'file', name: 'rules.pdf', nameLower: 'rules.pdf', description: '', pinned: false, path,
      contentType: 'application/pdf', size: 20, uploadedBy: 'alex', uploaderName: 'Riley', notifyTeam: false,
    });
    expect((d.createdAt as Timestamp).toMillis()).toBe(T0);
    expect(await importDocuments({ groupId: G, source: 'groupme', documents: [{ sourceId: 'f1', name: 'rules.pdf', path, sharedByName: 'Riley', sharedAtMs: T0 }] }, caller('alex'))).toEqual({
      added: 0,
      alreadyImported: 1,
      missing: 0,
    });
  });

  it("aren't added to a full team, or from outside their own folder", async () => {
    const path = `groups/${G}/documents/${did('f1')}/rules.pdf`;
    await file(path, 'application/pdf');
    await file(`groups/${G}/documents/elsewhere/rules.pdf`, 'application/pdf');
    expect(
      await importDocuments({ groupId: G, source: 'groupme', documents: [{ sourceId: 'f1', name: 'x', path: `groups/${G}/documents/elsewhere/rules.pdf`, sharedByName: 'R', sharedAtMs: T0 }] }, caller('alex')),
    ).toEqual({ added: 0, alreadyImported: 0, missing: 1 });
    await db().collection(Collections.groups).doc(G).update({ storageBytes: 1_000_000 });
    await expect(
      importDocuments({ groupId: G, source: 'groupme', documents: [{ sourceId: 'f1', name: 'x', path, sharedByName: 'R', sharedAtMs: T0 }] }, caller('alex')),
    ).rejects.toMatchObject({ message: 'storage-full' });
    await expect(call(importDocumentsCallable, { groupId: G, source: 'groupme', documents: [] })).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

describe("GroupMe's events (IMPORT-9)", () => {
  const listed = (extra: object = {}) => ({
    sourceId: 'e1', title: 'Thunder vs. Eagles', description: 'Bring water', location: 'Riverside Park, 100 River Rd',
    allDay: false, startMs: Date.now() + 3 * DAY, endMs: Date.now() + 3 * DAY + 7_200_000, timeZone: 'America/Denver', canceled: false, ...extra,
  });

  it('come in like a calendar import: games, places, zones, and all-day dates', async () => {
    const res = await importEvents(
      {
        groupId: G,
        source: 'groupme',
        events: [
          listed(),
          listed({ sourceId: 'e2', title: 'Team party', allDay: true, startMs: Date.UTC(2031, 5, 6, 5), endMs: Date.UTC(2031, 5, 8, 5), timeZone: null }),
          listed({ sourceId: 'e3', canceled: true }),
          listed({ sourceId: 'e4', startMs: Date.now() - 9 * DAY, endMs: Date.now() - 9 * DAY + 3_600_000 }),
        ],
        includePast: false,
        dryRun: false,
      },
      caller('alex'),
    );
    expect(res).toMatchObject({ added: 2, past: 1, skippedCount: 1 });
    const game = (await db().collection(Collections.events).doc(importedEventId(G, 'groupme', 'e1')).get()).data()!;
    expect(game).toMatchObject({ type: 'game', title: 'vs. Eagles', opponent: 'Eagles', homeAway: 'home', timeZone: 'America/Denver', location: { name: 'Riverside Park', address: '100 River Rd' }, notifyTeam: false, postToChat: false });
    const party = (await db().collection(Collections.events).doc(importedEventId(G, 'groupme', 'e2')).get()).data()!;
    // In the team's zone: June 6 and 7, 2031.
    expect(party).toMatchObject({ type: 'social', allDay: true, startDate: '2031-06-06', endDate: '2031-06-07', timeZone: 'America/Chicago' });
  });

  it('need the list, and calendar apps need a link or file', async () => {
    await expect(call(importEventsCallable, { groupId: G, source: 'groupme', url: 'https://example.com/a.ics' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call(importEventsCallable, { groupId: G, source: 'teamreach', events: [listed()] })).rejects.toMatchObject({ code: 'invalid-argument' });
    expect(await call(importEventsCallable, { groupId: G, source: 'groupme', events: [listed()] })).toMatchObject({ added: 1 });
  });
});
