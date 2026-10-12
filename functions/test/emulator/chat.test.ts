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
import { DELETED_USER_NAME, eraseMessage, lastMessagePreviewOf, removeAttachment } from '../../src/chat/service.js';
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
