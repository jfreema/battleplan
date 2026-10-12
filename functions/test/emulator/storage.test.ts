// Team storage end to end (SPEC §6.14 STORE-1 to STORE-6, ARCH §6.11): the
// warning levels and who hears about them (from the triggers and the daily
// recount), new teams' limit, Media's listing and deletes, and the
// super-admin limit, against the Firestore and Storage emulators with FCM
// faked. Run with:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import type { TokenMessage } from 'firebase-admin/messaging';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { adminSetGroupQuota, deleteTeamMedia, listTeamMedia } from '../../src/teams/handlers.js';
import { createGroup } from '../../src/teams/service.js';
import { reconcileAllStorage, updateStorageAlert } from '../../src/teams/storage.js';
import { onGroupFileAdded, onGroupFileRemoved } from '../../src/teams/triggers.js';
import { db, storage } from '../../src/shared/admin.js';
import { Collections, Limits } from '../../src/shared/constants.js';
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
const MB = 1024 * 1024;
const pushed = () => fcm.batches.flat();
const pushes = () => pushed().map((m) => `${m.token}:${m.notification?.body}`).sort();
const groupRef = () => db().collection(Collections.groups).doc(G);
const group = async () => (await groupRef().get()).data() ?? {};

async function person(uid: string, role: 'owner' | 'admin' | 'member' = 'member'): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(G, uid)).set({
    groupId: G, uid, role, displayName: uid, notificationLevel: 'all', mutedUntil: null,
  });
  await db().collection(Collections.users).doc(uid).set({ displayName: uid, status: 'active', notificationPrefs: {} });
  await db().collection(Collections.devices).doc(`dev-${uid}`).set({
    uid, token: `tok-${uid}`, platform: 'ios', appVersion: '1.0.0', updatedAt: Timestamp.now(),
  });
}

/** A file in the Storage emulator, [bytes] long. */
async function file(path: string, bytes = 4, contentType = 'image/jpeg'): Promise<void> {
  await storage().bucket().file(path).save(Buffer.alloc(bytes), { contentType, resumable: false });
}

async function fileExists(path: string): Promise<boolean> {
  const [exists] = await storage().bucket().file(path).exists();
  return exists;
}

/** Sets the team's usage, as the Storage triggers would, and runs the warning. */
async function useBytes(bytes: number) {
  await groupRef().update({ storageBytes: bytes });
  return updateStorageAlert(G);
}

type CallRequest = Parameters<typeof listTeamMedia.run>[0];
const call = (uid: string, data: object, token: object = {}) =>
  ({ data, auth: { uid, token }, rawRequest: {} }) as unknown as CallRequest;
const root = (data: object) => call('root', data, { superAdmin: true });

beforeAll(() => {
  // Never point these tests at a real project.
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
  delete process.env.FUNCTIONS_EMULATOR;
  await groupRef().set({
    name: 'Thunder',
    photoPath: null,
    storageBytes: 0,
    storageQuotaBytes: 100 * MB,
    storageAlert: 'none',
  });
  await person('pat', 'owner');
  await person('alex', 'admin');
  await person('sam');
});

describe('storage warnings (STORE-3, STORE-4)', () => {
  it('tells the admins once at 90% and once when full, and nobody else', async () => {
    expect(await useBytes(50 * MB)).toBeNull();
    expect(pushed()).toHaveLength(0);

    expect(await useBytes(90 * MB)).toBe('warn');
    expect(pushes()).toEqual([
      'tok-alex:Storage is 90% full. Free up space in Media.',
      'tok-pat:Storage is 90% full. Free up space in Media.',
    ]);
    const m = pushed()[0];
    expect(m.data).toMatchObject({ kind: 'storageWarning', groupId: G, route: `/g/${G}/media` });
    expect(m.android?.notification?.channelId).toBe('team');
    expect((await group()).storageAlert).toBe('warn');

    // Still at the same level: no second notification, even when rerun.
    expect(await useBytes(95 * MB)).toBeNull();
    expect(await updateStorageAlert(G)).toBeNull();
    expect(pushed()).toHaveLength(2);

    fcm.batches.length = 0;
    expect(await useBytes(100 * MB)).toBe('full');
    expect(pushes()).toEqual([
      'tok-alex:Storage is full. Uploads, attachments, and scheduling new events are disabled until storage is freed up.',
      'tok-pat:Storage is full. Uploads, attachments, and scheduling new events are disabled until storage is freed up.',
    ]);

    // Center items for the admins only, not naming anyone (actor null).
    const items = await db().collection(Collections.notifications).where('groupId', '==', G).get();
    expect(items.docs.map((d) => d.get('uid')).sort()).toEqual(['alex', 'alex', 'pat', 'pat']);
    expect(items.docs.every((d) => d.get('type') === 'storageWarning' && d.get('actorId') === null)).toBe(true);
    expect(items.docs.every((d) => d.get('targetType') === 'group' && d.get('targetId') === G)).toBe(true);
  });

  it('drops silently when space is freed, so the next rise notifies again', async () => {
    await useBytes(92 * MB);
    fcm.batches.length = 0;
    expect(await useBytes(40 * MB)).toBe('none');
    expect((await group()).storageAlert).toBe('none');
    expect(pushed()).toHaveLength(0);
    expect(await useBytes(92 * MB)).toBe('warn');
    expect(pushes()).toEqual([
      'tok-alex:Storage is 90% full. Free up space in Media.',
      'tok-pat:Storage is 90% full. Free up space in Media.',
    ]);
  });

  it('goes straight to full with one notification, and falls to warn without one', async () => {
    expect(await useBytes(120 * MB)).toBe('full');
    expect(pushed().map((m) => m.notification?.body)).toEqual([
      expect.stringContaining('Storage is full.'),
      expect.stringContaining('Storage is full.'),
    ]);
    fcm.batches.length = 0;
    expect(await useBytes(95 * MB)).toBe('warn');
    expect(pushed()).toHaveLength(0);
  });

  it('ignores a team that is gone', async () => {
    await groupRef().delete();
    expect(await updateStorageAlert(G)).toBeNull();
  });

  it('notifies once when several triggers see the same rise', async () => {
    await groupRef().update({ storageBytes: 91 * MB });
    const levels = await Promise.all([1, 2, 3, 4].map(() => updateStorageAlert(G)));
    expect(levels.filter((l) => l === 'warn')).toHaveLength(1);
    expect(pushed()).toHaveLength(2);
  });

  it('follows each file the Storage triggers count, and ignores files outside teams', async () => {
    type FileEvent = Parameters<typeof onGroupFileAdded.run>[0];
    const event = (name: string, size: number) => ({ data: { name, size } }) as unknown as FileEvent;
    await groupRef().update({ storageBytes: 80 * MB });

    await onGroupFileAdded.run(event(`groups/${G}/messages/m1/0.jpg`, 10 * MB));
    expect(await group()).toMatchObject({ storageBytes: 90 * MB, storageAlert: 'warn' });
    expect(pushed()).toHaveLength(2);

    await onGroupFileRemoved.run(event(`groups/${G}/messages/m1/0.jpg`, 10 * MB));
    expect(await group()).toMatchObject({ storageBytes: 80 * MB, storageAlert: 'none' });
    expect(pushed()).toHaveLength(2);

    await onGroupFileAdded.run(event('users/sam/avatar/1.jpg', 50 * MB));
    expect((await group()).storageBytes).toBe(80 * MB);
  });

  it('catches up in the daily recount', async () => {
    // The triggers missed a file: the recount finds it and warns once.
    await groupRef().update({ storageQuotaBytes: 1000, storageBytes: 0 });
    await file(`groups/${G}/messages/m1/0.jpg`, 950);
    await reconcileAllStorage();
    expect(await group()).toMatchObject({ storageBytes: 950, storageAlert: 'warn' });
    expect(pushed().map((m) => m.token).sort()).toEqual(['tok-alex', 'tok-pat']);
    await reconcileAllStorage();
    expect(pushed()).toHaveLength(2);
  });
});

describe('new teams (STORE-1)', () => {
  it('start with the 500 MB limit, no warning, and no plan', async () => {
    const id = await createGroup(
      'pat',
      { displayName: 'Pat', photoPath: null },
      { name: 'New', sport: 'soccer', teamType: 'adult', timeZone: 'America/Chicago' },
      Limits.defaultStorageQuotaMb,
    );
    const data = (await db().collection(Collections.groups).doc(id).get()).data() ?? {};
    expect(data).toMatchObject({ storageBytes: 0, storageQuotaBytes: 500 * MB, storageAlert: 'none' });
    expect(data).not.toHaveProperty('plan');
  });
});

describe('Media (STORE-5)', () => {
  const message = (id: string, fields: object) =>
    db().collection(Collections.messages).doc(id).set({
      groupId: G, authorId: 'sam', authorName: 'Sam', reactions: { pat: 'love' }, createdAt: Timestamp.now(), ...fields,
    });
  const photo = (id: string, n: number) => ({ path: `groups/${G}/messages/${id}/${n}.jpg`, contentType: 'image/jpeg' });
  const messageData = async (id: string) => (await db().collection(Collections.messages).doc(id).get()).data() ?? {};

  it('lists every file largest first, with what uses it', async () => {
    await file(`groups/${G}/messages/m1/0.jpg`, 300);
    await file(`groups/${G}/avatar/new.jpg`, 200);
    await file(`groups/${G}/avatar/old.jpg`, 100);
    await file(`groups/${G}/theme/bg.jpg`, 400);
    await file(`groups/${G}/documents/d1/plan.pdf`, 50, 'application/pdf');
    await file(`groups/${G}/messages/gone/0.jpg`, 10);
    await file(`groups/teamB/avatar/x.jpg`, 999);
    await message('m1', { type: 'image', text: '', attachments: [photo('m1', 0)] });
    await groupRef().update({
      photoPath: `groups/${G}/avatar/new.jpg`,
      chatTheme: { bubbleColor: null, background: 'photo', backgroundPath: `groups/${G}/theme/bg.jpg` },
      storageBytes: 1060,
    });

    const res = await listTeamMedia.run(call('alex', { groupId: G }));

    expect(res.storageBytes).toBe(1060);
    expect(res.truncated).toBe(false);
    expect(res.storageQuotaBytes).toBe(100 * MB);
    expect(res.items.map((f) => [f.path.replace(`groups/${G}/`, ''), f.size, f.kind, f.current ?? null])).toEqual([
      ['theme/bg.jpg', 400, 'background', true],
      ['messages/m1/0.jpg', 300, 'chatPhoto', true],
      ['avatar/new.jpg', 200, 'logo', true],
      ['avatar/old.jpg', 100, 'logo', false],
      ['documents/d1/plan.pdf', 50, 'document', null],
      ['messages/gone/0.jpg', 10, 'chatPhoto', false],
    ]);
    const chat = res.items.find((f) => f.messageId === 'm1')!;
    expect(chat).toMatchObject({ authorName: 'Sam', contentType: 'image/jpeg' });
    expect(Date.parse(chat.createdAt!)).toBeGreaterThan(Date.now() - 60_000);
    expect(res.items.find((f) => f.messageId === 'gone')).not.toHaveProperty('authorName');
  });

  it('is for team admins and super admins only', async () => {
    await expect(listTeamMedia.run(call('sam', { groupId: G }))).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(deleteTeamMedia.run(call('sam', { groupId: G, path: `groups/${G}/avatar/a.jpg` }))).rejects.toMatchObject({
      code: 'permission-denied',
    });
    await expect(listTeamMedia.run(root({ groupId: G }))).resolves.toMatchObject({ items: [] });
  });

  it('removes a deleted photo from its message, and erases a message left empty', async () => {
    await file(`groups/${G}/messages/m1/0.jpg`);
    await file(`groups/${G}/messages/m1/1.jpg`);
    await message('m1', { type: 'image', text: '', attachments: [photo('m1', 0), photo('m1', 1)] });
    await message('r1', { type: 'text', text: 'Nice', replyToId: 'm1', replyPreview: { authorName: 'Sam', text: '', type: 'image', deleted: false } });
    await db().collection(Collections.notifications).doc('m1_reply_pat').set({
      uid: 'pat', groupId: G, type: 'reply', targetType: 'message', targetId: 'm1', read: false,
    });

    await deleteTeamMedia.run(call('alex', { groupId: G, path: `groups/${G}/messages/m1/0.jpg` }));
    expect((await messageData('m1')).attachments).toEqual([photo('m1', 1)]);
    expect((await messageData('m1')).deletedAt).toBeUndefined();
    expect(await fileExists(`groups/${G}/messages/m1/0.jpg`)).toBe(false);
    expect(await fileExists(`groups/${G}/messages/m1/1.jpg`)).toBe(true);

    await deleteTeamMedia.run(call('alex', { groupId: G, path: `groups/${G}/messages/m1/1.jpg` }));
    const erased = await messageData('m1');
    expect(erased).toMatchObject({ text: '', attachments: [], reactions: {}, deletedBy: 'alex', deletedReason: 'admin' });
    expect(erased.deletedAt).toBeInstanceOf(Timestamp);
    expect(await fileExists(`groups/${G}/messages/m1/1.jpg`)).toBe(false);
    expect((await messageData('r1')).replyPreview).toMatchObject({ deleted: true });
    expect((await db().doc(`${Collections.notifications}/m1_reply_pat`).get()).exists).toBe(false);

    const audits = await db().collection(Collections.auditLogs).where('action', '==', 'deleteTeamMedia').get();
    expect(audits.docs.map((d) => d.get('after').fixed).sort()).toEqual(['erased', 'removed']);
    expect(audits.docs.every((d) => d.get('actorId') === 'alex' && d.get('groupId') === G)).toBe(true);
  });

  it('keeps a photo message that has text, as a text message without the photo', async () => {
    await file(`groups/${G}/messages/m2/0.jpg`);
    await file(`groups/${G}/messages/m2/1.jpg`);
    await message('m2', { type: 'image', text: 'Team pic', attachments: [photo('m2', 0), photo('m2', 1)] });
    await deleteTeamMedia.run(call('pat', { groupId: G, path: `groups/${G}/messages/m2/0.jpg` }));
    expect(await messageData('m2')).toMatchObject({ type: 'image', attachments: [photo('m2', 1)] });
    await deleteTeamMedia.run(call('pat', { groupId: G, path: `groups/${G}/messages/m2/1.jpg` }));
    // `image` always has a photo, as the create rule requires.
    expect(await messageData('m2')).toMatchObject({
      type: 'text', text: 'Team pic', attachments: [], reactions: { pat: 'love' },
    });
    expect((await messageData('m2')).deletedAt).toBeUndefined();
  });

  it('lists and deletes files with any name a member could upload', async () => {
    // storage.rules let members pick the message folder and file name; one
    // odd name must neither break the list nor stay stuck holding space.
    const odd = ['messages/./0.jpg', 'messages/../1.jpg', 'messages/__x__/2.jpg', 'messages/m9/a..jpg', 'documents/d1/Roster..final.pdf'];
    for (const [i, name] of odd.entries()) await file(`groups/${G}/${name}`, 100 - i);

    const res = await listTeamMedia.run(call('alex', { groupId: G }));
    expect(res.items.map((f) => [f.path.replace(`groups/${G}/`, ''), f.kind])).toEqual([
      ['messages/./0.jpg', 'other'],
      ['messages/../1.jpg', 'other'],
      ['messages/__x__/2.jpg', 'other'],
      ['messages/m9/a..jpg', 'chatPhoto'],
      ['documents/d1/Roster..final.pdf', 'document'],
    ]);

    for (const name of odd) {
      await expect(deleteTeamMedia.run(call('alex', { groupId: G, path: `groups/${G}/${name}` }))).resolves.toMatchObject({ ok: true });
      expect(await fileExists(`groups/${G}/${name}`)).toBe(false);
    }
  });

  it('never follows a message to another team, or its unchecked thumbPath', async () => {
    await file(`groups/${G}/messages/x1/0.jpg`);
    await file(`groups/teamB/avatar/logo.jpg`);
    await db().collection(Collections.messages).doc('x1').set({
      groupId: 'teamB', authorId: 'zed', type: 'image', text: '',
      attachments: [{ path: `groups/teamB/messages/x1/0.jpg`, thumbPath: `groups/${G}/messages/x1/0.jpg` }],
    });
    await db().collection(Collections.messages).doc('x2').set({
      groupId: G, authorId: 'sam', type: 'image', text: 'hi',
      attachments: [{ path: `groups/${G}/messages/x2/0.jpg`, thumbPath: 'groups/teamB/avatar/logo.jpg' }],
    });
    await file(`groups/${G}/messages/x2/0.jpg`);

    await deleteTeamMedia.run(call('alex', { groupId: G, path: `groups/${G}/messages/x1/0.jpg` }));
    expect((await messageData('x1')).attachments).toHaveLength(1); // team B's message is untouched
    await deleteTeamMedia.run(call('alex', { groupId: G, path: `groups/${G}/messages/x2/0.jpg` }));
    expect((await messageData('x2')).attachments).toEqual([]);
    expect(await fileExists('groups/teamB/avatar/logo.jpg')).toBe(true);
  });

  it('resets the logo or background in use, and leaves them alone otherwise', async () => {
    await file(`groups/${G}/avatar/new.jpg`);
    await file(`groups/${G}/avatar/old.jpg`);
    await file(`groups/${G}/theme/bg.jpg`);
    await groupRef().update({
      photoPath: `groups/${G}/avatar/new.jpg`,
      chatTheme: { bubbleColor: '#0F8A5F', background: 'photo', backgroundPath: `groups/${G}/theme/bg.jpg` },
    });

    await deleteTeamMedia.run(call('alex', { groupId: G, path: `groups/${G}/avatar/old.jpg` }));
    expect((await group()).photoPath).toBe(`groups/${G}/avatar/new.jpg`);
    expect(await fileExists(`groups/${G}/avatar/old.jpg`)).toBe(false);

    await deleteTeamMedia.run(call('alex', { groupId: G, path: `groups/${G}/avatar/new.jpg` }));
    await deleteTeamMedia.run(call('alex', { groupId: G, path: `groups/${G}/theme/bg.jpg` }));
    const after = await group();
    expect(after.photoPath).toBeNull();
    expect(after.chatTheme).toEqual({ bubbleColor: '#0F8A5F', background: 'plain', backgroundPath: null });
    expect(await fileExists(`groups/${G}/theme/bg.jpg`)).toBe(false);
  });

  it("refuses paths outside the team's folder", async () => {
    await file('groups/teamB/avatar/logo.jpg');
    for (const path of ['groups/teamB/avatar/logo.jpg', `groups/${G}/../teamB/avatar/logo.jpg`, 'users/sam/avatar/1.jpg', `groups/${G}/`]) {
      await expect(deleteTeamMedia.run(call('alex', { groupId: G, path }))).rejects.toMatchObject({ code: 'invalid-argument' });
    }
    await expect(deleteTeamMedia.run(call('alex', { groupId: `${G}/x`, path: `groups/${G}/x/a.jpg` }))).rejects.toMatchObject({
      code: 'invalid-argument',
    });
    expect(await fileExists('groups/teamB/avatar/logo.jpg')).toBe(true);
  });
});

describe('the super-admin limit (STORE-6)', () => {
  it('is for super admins only, team owners included', async () => {
    await expect(adminSetGroupQuota.run(call('pat', { groupId: G, quotaMb: 2048 }))).rejects.toMatchObject({
      code: 'permission-denied',
    });
    expect((await group()).storageQuotaBytes).toBe(100 * MB);
  });

  it('sets one team to a whole number of MB within the maximum, audited', async () => {
    await db().collection(Collections.groups).doc('teamB').set({ name: 'Other', storageBytes: 0, storageQuotaBytes: 500 * MB });
    await expect(adminSetGroupQuota.run(root({ groupId: G, quotaMb: 2048 }))).resolves.toEqual({ storageQuotaBytes: 2048 * MB });
    expect((await group()).storageQuotaBytes).toBe(2048 * MB);
    expect((await db().collection(Collections.groups).doc('teamB').get()).get('storageQuotaBytes')).toBe(500 * MB);
    const audit = (await db().collection(Collections.auditLogs).where('action', '==', 'setGroupQuota').get()).docs[0];
    expect(audit.data()).toMatchObject({
      actorId: 'root',
      groupId: G,
      before: { storageQuotaBytes: 100 * MB },
      after: { storageQuotaBytes: 2048 * MB },
    });

    for (const quotaMb of [0, 1.5, 51_201]) {
      await expect(adminSetGroupQuota.run(root({ groupId: G, quotaMb }))).rejects.toMatchObject({ code: 'invalid-argument' });
    }
    await expect(adminSetGroupQuota.run(root({ groupId: 'nope', quotaMb: 10 }))).rejects.toMatchObject({ code: 'not-found' });
  });

  it('moves the warning with the new limit', async () => {
    await useBytes(100 * MB);
    fcm.batches.length = 0;
    await adminSetGroupQuota.run(root({ groupId: G, quotaMb: 2048 }));
    expect((await group()).storageAlert).toBe('none');
    expect(pushed()).toHaveLength(0);
    await adminSetGroupQuota.run(root({ groupId: G, quotaMb: 50 }));
    expect((await group()).storageAlert).toBe('full');
    expect(pushed().map((m) => m.token).sort()).toEqual(['tok-alex', 'tok-pat']);
  });
});
