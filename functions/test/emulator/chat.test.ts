// Copies of a message outside the message itself (CHAT-8, AUTH-10): the
// team switcher's preview after a message is erased, and the quotes,
// previews, and notification-center items naming someone who deleted their
// account, and a report's copy of what was reported once a team admin
// resolves it. Runs against the Auth, Firestore, and Storage emulators with
// FCM faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { deleteAccount } from '../../src/accounts/service.js';
import {
  DELETED_USER_NAME,
  eraseMessage,
  lastMessagePreviewOf,
  postRenamedLine,
  removeAttachment,
} from '../../src/chat/service.js';
import { clearPendingMemberships } from '../../src/accounts/service.js';
import { pinMessage } from '../../src/chat/handlers.js';
import { resolveReport } from '../../src/safety/handlers.js';
import { db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';

vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({ sendEach: async () => ({ responses: [], successCount: 0, failureCount: 0 }) }),
}));

const G = 'teamA';
const H = 'teamB';
const messages = () => db().collection(Collections.messages);
const preview = async (groupId = G) =>
  (await db().collection(Collections.groups).doc(groupId).get()).get('lastMessagePreview') as unknown;
const at = (minute: number) => Timestamp.fromDate(new Date(Date.UTC(2030, 5, 1, 12, minute)));

/** A message in [groupId], [minute] minutes after noon, with the preview the trigger would leave. */
async function message(id: string, minute: number, fields: Record<string, unknown> = {}, groupId = G): Promise<void> {
  const data = {
    groupId, authorId: 'sam', authorName: 'Sam Rivera', authorPhotoPath: null, authorPlayerSummary: null,
    type: 'text', text: `Message ${id}`, attachments: [], reactions: {}, createdAt: at(minute), ...fields,
  };
  await messages().doc(id).set(data);
  await db().collection(Collections.groups).doc(groupId).set(
    {
      lastMessageAt: data.createdAt,
      lastMessagePreview: lastMessagePreviewOf(data),
    },
    { merge: true },
  );
}

/** A reply to [replyToId], with the quote writeReplyPreview would copy. */
async function reply(id: string, minute: number, replyToId: string, quoted: object): Promise<void> {
  await message(id, minute, {
    authorId: 'pat', authorName: 'Pat Lee', replyToId,
    replyPreview: { authorName: 'Sam Rivera', text: 'Quoted', type: 'text', deleted: false, ...quoted },
  });
}

async function centerItem(id: string, uid: string, actorId: string | null): Promise<void> {
  await db().collection(Collections.notifications).doc(id).set({
    uid, groupId: G, type: 'message', params: {}, title: 'Thunder', body: 'Sam Rivera: Hello', route: `/g/${G}`,
    actorId, targetType: 'message', targetId: 'm1', read: false, createdAt: at(0), expiresAt: at(59),
  });
}

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
  for (const groupId of [G, H]) {
    await db().collection(Collections.groups).doc(groupId).set({ name: groupId, ownerId: 'pat', memberCount: 2 });
    for (const [uid, role] of [['pat', 'owner'], ['sam', 'member']]) {
      await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid)).set({ groupId, uid, role });
    }
  }
  await db().collection(Collections.users).doc('sam').set({ displayName: 'Sam Rivera', status: 'active' });
});

describe("the team switcher's preview after a message is erased (CHAT-8)", () => {
  beforeEach(async () => {
    await message('m1', 1, { authorId: 'pat', authorName: 'Pat Lee', text: 'Field 3 is open' });
    await message('m2', 2, { text: 'My secret plan\nsecond line' });
  });

  it("falls back to the newest message left, and keeps the team's last-message time", async () => {
    await eraseMessage('m2', 'sam', 'author');
    expect(await preview()).toEqual({ authorName: 'Pat Lee', text: 'Field 3 is open', type: 'text' });
    expect((await db().collection(Collections.groups).doc(G).get()).get('lastMessageAt')).toEqual(at(2));
  });

  it('blanks it when every message is deleted', async () => {
    await eraseMessage('m2', 'sam', 'author');
    await eraseMessage('m1', 'root', 'admin');
    expect(await preview()).toBeNull();
  });

  it('leaves it alone when an older message is erased', async () => {
    await eraseMessage('m1', 'pat', 'author');
    expect(await preview()).toEqual({ authorName: 'Sam Rivera', text: 'My secret plan', type: 'text' });
  });

  it("rebuilds it when Media takes a message's last photo", async () => {
    const path = `groups/${G}/messages/m3/a.jpg`;
    await message('m3', 3, { type: 'image', text: '', attachments: [{ path, thumbPath: null }] });
    expect(await preview()).toMatchObject({ text: 'Photo' });
    expect(await removeAttachment(G, 'm3', path, 'pat')).toBe('erased');
    expect(await preview()).toEqual({ authorName: 'Sam Rivera', text: 'My secret plan', type: 'text' });
  });
});

describe('deleting an account takes the name off copies of it (AUTH-10)', () => {
  beforeEach(async () => {
    await message('m1', 1, { text: 'Hello' });
    await message('m2', 2, { text: 'Gone now', deletedAt: at(3) });
    await reply('r1', 4, 'm1', {});
    await reply('r2', 5, 'm2', { authorName: '', text: '', deleted: true });
    await reply('r3', 6, 'other', { authorName: 'Lee Kim' });
    // In the other team, sam wrote the newest message.
    await message('h1', 1, { authorId: 'pat', authorName: 'Pat Lee', text: 'Earlier' }, H);
    await message('h2', 2, { text: 'Last word' }, H);
    await centerItem('n_pat_from_sam', 'pat', 'sam');
    await centerItem('n_pat_from_lee', 'pat', 'lee');
    await centerItem('n_pat_system', 'pat', null);
    await centerItem('n_sam', 'sam', 'pat');
  });

  const quote = async (id: string) => (await messages().doc(id).get()).get('replyPreview') as unknown;
  const centerItems = async () => (await db().collection(Collections.notifications).get()).docs.map((d) => d.id).sort();

  it('rewrites the quote on replies to their messages, and only those', async () => {
    await deleteAccount('sam');
    expect(await quote('r1')).toEqual({ authorName: DELETED_USER_NAME, text: 'Quoted', type: 'text', deleted: false });
    expect(await quote('r2')).toEqual({ authorName: '', text: '', type: 'text', deleted: true });
    expect(await quote('r3')).toMatchObject({ authorName: 'Lee Kim' });
  });

  it("rewrites a team's preview when they wrote its newest message, and only then", async () => {
    await deleteAccount('sam');
    expect(await preview(H)).toEqual({ authorName: DELETED_USER_NAME, text: 'Last word', type: 'text' });
    expect(await preview(G)).toMatchObject({ authorName: 'Pat Lee' });
  });

  it("removes other people's notification-center items about them, with their own", async () => {
    await deleteAccount('sam');
    expect(await centerItems()).toEqual(['n_pat_from_lee', 'n_pat_system']);
  });

  it('finishes the job when run again after stopping partway', async () => {
    // As if a first run renamed one message and stopped before the rest.
    await messages().doc('m2').update({ authorName: DELETED_USER_NAME });
    await deleteAccount('sam');
    await deleteAccount('sam');
    expect(await quote('r1')).toMatchObject({ authorName: DELETED_USER_NAME });
    expect(await preview(H)).toMatchObject({ authorName: DELETED_USER_NAME });
    const sams = await messages().where('authorId', '==', 'sam').get();
    expect(sams.docs.map((d) => d.get('authorName'))).toEqual(sams.docs.map(() => DELETED_USER_NAME));
  });
});

describe("a report's copy of what was reported (SAFE-4)", () => {
  type CallRequest = Parameters<typeof resolveReport.run>[0];
  const call = (uid: string, data: object) => ({ data, auth: { uid, token: {} }, rawRequest: {} }) as unknown as CallRequest;
  const report = () => db().collection(Collections.reports).doc('rep1');

  beforeEach(async () => {
    await message('m1', 1, { text: 'Buy now at spam.example' });
    await report().set({
      reporterId: 'pat', groupId: G, targetType: 'message', targetId: 'm1', reason: 'spam', details: null,
      subjectId: 'sam', subjectName: 'Sam Rivera', excerpt: 'Buy now at spam.example', status: 'open',
      resolvedBy: null, resolution: null, createdAt: at(2),
    });
  });

  it('keeps it while the report is open, even after the message is deleted', async () => {
    await eraseMessage('m1', 'sam', 'author');
    expect((await report().get()).get('excerpt')).toBe('Buy now at spam.example');
  });

  it('erases it when a team admin resolves the report', async () => {
    await eraseMessage('m1', 'pat', 'admin');
    await resolveReport.run(call('pat', { reportId: 'rep1', outcome: 'actioned', resolution: 'deletedMessage' }));
    expect((await report().get()).data()).toMatchObject({ status: 'actioned', resolvedBy: 'pat', excerpt: '' });
  });
});

describe('system lines (CHAT-10)', () => {
  const lines = async () =>
    (await messages().where('groupId', '==', G).where('type', '==', 'system').get()).docs.map((d) => d.get('text') as string);

  it('posts one rename line naming the admin, even when the trigger runs twice', async () => {
    await db().collection(Collections.groupMembers).doc(groupMemberId(G, 'pat')).update({ displayName: 'Pat Lee' });
    expect(await postRenamedLine(G, 'Thunder', 'Thunder 12U', 'pat', 'evt1')).toBe(true);
    expect(await postRenamedLine(G, 'Thunder', 'Thunder 12U', 'pat', 'evt1')).toBe(true);
    expect(await postRenamedLine(G, 'Thunder 12U', 'Thunder 12U', 'pat', 'evt2')).toBe(false);
    expect(await lines()).toEqual(['Pat Lee renamed the team to "Thunder 12U"']);
  });

  it('leaves the name out when nobody on the team made the change', async () => {
    await postRenamedLine(G, 'Thunder', 'Storm', 'functions@example.iam.gserviceaccount.com', 'evt3');
    expect(await lines()).toEqual(['The team was renamed to "Storm"']);
  });

  it('says an added account joined when it first signs in', async () => {
    await db().collection(Collections.groupMembers).doc(groupMemberId(G, 'kim')).set({
      groupId: G, uid: 'kim', role: 'member', displayName: 'Kim Park', pending: true,
    });
    await clearPendingMemberships('kim');
    expect(await lines()).toEqual(['Kim Park joined']);
    expect((await db().collection(Collections.groupMembers).doc(groupMemberId(G, 'kim')).get()).get('pending')).toBe(false);
  });
});

describe('pinning messages (CHAT-15)', () => {
  type CallRequest = Parameters<typeof pinMessage.run>[0];
  const call = (uid: string, data: object, token: object = {}) =>
    ({ data, auth: { uid, token }, rawRequest: {} }) as unknown as CallRequest;
  const pin = (uid: string, messageId: string, pinned = true, token: object = {}) =>
    pinMessage.run(call(uid, { messageId, pinned }, token));
  const pins = async (groupId = G) =>
    ((await db().collection(Collections.groups).doc(groupId).get()).get('pinnedMessageIds') as string[] | undefined) ?? [];

  beforeEach(async () => {
    for (const [id, minute] of [['m1', 1], ['m2', 2], ['m3', 3], ['m4', 4]] as const) await message(id, minute);
  });

  it('team admins pin up to three, oldest pin first, and unpin; each change is audited', async () => {
    for (const id of ['m1', 'm2', 'm3']) await pin('pat', id);
    expect(await pins()).toEqual(['m1', 'm2', 'm3']);
    await expect(pin('pat', 'm4')).rejects.toMatchObject({ code: 'failed-precondition', message: 'too-many-pins' });
    // Pinning a pinned message again changes nothing, and isn't audited.
    await pin('pat', 'm2');
    await pin('pat', 'm2', false);
    expect(await pins()).toEqual(['m1', 'm3']);
    await pin('pat', 'm4');
    expect(await pins()).toEqual(['m1', 'm3', 'm4']);
    const audited = await db().collection(Collections.auditLogs).where('actorId', '==', 'pat').get();
    expect(audited.docs.map((d) => `${d.get('action')} ${d.get('targetId')}`).sort()).toEqual([
      'pinMessage m1',
      'pinMessage m2',
      'pinMessage m3',
      'pinMessage m4',
      'unpinMessage m2',
    ]);
  });

  it('members, other teams, system lines, and deleted messages are refused', async () => {
    await expect(pin('sam', 'm1')).rejects.toMatchObject({ code: 'permission-denied' });
    await message('h1', 5, {}, H);
    await db().collection(Collections.groupMembers).doc(groupMemberId(H, 'pat')).delete();
    await expect(pin('pat', 'h1')).rejects.toMatchObject({ code: 'permission-denied' });
    await message('sys', 6, { type: 'system', authorId: 'system' });
    await expect(pin('pat', 'sys')).rejects.toMatchObject({ code: 'failed-precondition', message: 'not-pinnable' });
    await eraseMessage('m1', 'sam', 'author');
    await expect(pin('pat', 'm1')).rejects.toMatchObject({ code: 'failed-precondition', message: 'not-pinnable' });
    await expect(pin('pat', 'nope')).rejects.toMatchObject({ code: 'not-found' });
    expect(await pins()).toEqual([]);
  });

  it('deleting a pinned message takes it off the bar', async () => {
    await pin('pat', 'm1');
    await pin('pat', 'm2');
    await eraseMessage('m1', 'sam', 'author');
    expect(await pins()).toEqual(['m2']);
  });

  it('archived teams are read-only; super admins pin on any open team', async () => {
    await db().collection(Collections.groups).doc(G).update({ archivedAt: Timestamp.now() });
    await expect(pin('pat', 'm1')).rejects.toMatchObject({ code: 'failed-precondition', message: 'team-archived' });
    await db().collection(Collections.groups).doc(G).update({ archivedAt: null });
    await pin('boss', 'm1', true, { superAdmin: true });
    expect(await pins()).toEqual(['m1']);
  });
});
