// Polls on the server (SPEC POLL-2, POLL-4, POLL-5): tallies, closing early
// and on time with the "Poll closed" notification, deleting with the
// message, and the "created a poll" notification. Runs against the
// Firestore emulator with FCM faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { eraseMessage, notifyNewMessage } from '../../src/chat/service.js';
import { closePoll } from '../../src/polls/handlers.js';
import { closeDuePolls, recountPoll } from '../../src/polls/service.js';
import { db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';

vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({ sendEach: async () => ({ responses: [], successCount: 0, failureCount: 0 }) }),
}));

const G = 'teamA';
type CallRequest = Parameters<typeof closePoll.run>[0];
const call = (uid: string, data: object, token: object = {}) =>
  ({ data, auth: { uid, token }, rawRequest: {} }) as unknown as CallRequest;

async function person(uid: string, role = 'member'): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(G, uid)).set({
    groupId: G, uid, role, displayName: uid[0].toUpperCase() + uid.slice(1), notificationLevel: 'all',
  });
  await db().collection(Collections.users).doc(uid).set({ displayName: uid, status: 'active', notificationPrefs: {} });
}

async function poll(id: string, fields: object = {}): Promise<void> {
  await db().collection(Collections.polls).doc(id).set({
    groupId: G,
    messageId: id,
    createdBy: 'pat',
    question: 'Saturday or Sunday?',
    options: [{ id: '0', text: 'Saturday' }, { id: '1', text: 'Sunday' }, { id: '2', text: 'Either' }],
    allowMultiple: true,
    anonymous: false,
    closesAt: null,
    closedAt: null,
    voteCounts: {},
    voterCount: 0,
    createdAt: Timestamp.now(),
    ...fields,
  });
}

async function vote(pollId: string, uid: string, optionIds: unknown[]): Promise<void> {
  await db().collection(Collections.pollVotes).doc(`${pollId}_${uid}`).set({ pollId, groupId: G, uid, optionIds });
}

const pollData = async (id: string) => (await db().collection(Collections.polls).doc(id).get()).data();

/** Who has a center item for [key], sorted. */
async function centerFor(key: string): Promise<string[]> {
  const snap = await db().collection(Collections.notifications).where('groupId', '==', G).get();
  return snap.docs.filter((d) => d.id === `${key}_${d.get('uid')}`).map((d) => d.get('uid') as string).sort();
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
  await db().collection(Collections.groups).doc(G).set({ name: 'Thunder' });
  await person('alex', 'admin');
  await person('pat');
  await person('sam');
  await person('lee');
});

describe('tallies (POLL-2)', () => {
  it('counts each option and each voter, ignoring choices that are not options', async () => {
    await poll('p1');
    await vote('p1', 'alex', ['0', '2']);
    await vote('p1', 'sam', ['0']);
    await vote('p1', 'lee', ['7']);
    await recountPoll('p1');
    expect(await pollData('p1')).toMatchObject({ voteCounts: { 0: 2, 1: 0, 2: 1 }, voterCount: 2 });

    await db().collection(Collections.pollVotes).doc('p1_alex').delete();
    await recountPoll('p1');
    expect(await pollData('p1')).toMatchObject({ voteCounts: { 0: 1, 1: 0, 2: 0 }, voterCount: 1 });
  });

  it('does nothing for a deleted poll', async () => {
    await vote('gone', 'sam', ['0']);
    await expect(recountPoll('gone')).resolves.toBeUndefined();
  });
});

describe('closing (POLL-4)', () => {
  it('lets the creator close early, and tells the other voters the result', async () => {
    await poll('p1');
    await vote('p1', 'alex', ['0']);
    await vote('p1', 'sam', ['0', '1']);
    await vote('p1', 'pat', ['0']);
    await closePoll.run(call('pat', { pollId: 'p1' }));
    const closed = await pollData('p1');
    expect(closed?.closedAt).toBeInstanceOf(Timestamp);
    expect(closed).toMatchObject({ closedBy: 'pat', voteCounts: { 0: 3, 1: 1, 2: 0 }, voterCount: 3 });
    // Lee didn't vote; Pat closed it.
    expect(await centerFor('p1_closed')).toEqual(['alex', 'sam']);
    const item = await db().collection(Collections.notifications).doc('p1_closed_sam').get();
    expect(item.get('body')).toBe('Poll closed: Saturday or Sunday? Saturday (3 votes)');
    expect(item.get('route')).toBe(`/g/${G}/chat/m/p1`);
  });

  it('lets admins close anyone’s poll, with an audit entry, and never reopens', async () => {
    await poll('p1');
    await closePoll.run(call('alex', { pollId: 'p1' }));
    const first = (await pollData('p1'))?.closedAt as Timestamp;
    const audits = await db().collection(Collections.auditLogs).where('action', '==', 'closePoll').get();
    expect(audits.size).toBe(1);
    await closePoll.run(call('pat', { pollId: 'p1' }));
    expect(((await pollData('p1'))?.closedAt as Timestamp).isEqual(first)).toBe(true);
  });

  it('refuses other members, other teams, and archived teams', async () => {
    await poll('p1');
    await expect(closePoll.run(call('sam', { pollId: 'p1' }))).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(closePoll.run(call('stranger', { pollId: 'p1' }))).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(closePoll.run(call('sam', { pollId: 'nope' }))).rejects.toMatchObject({ code: 'not-found' });
    await db().collection(Collections.groups).doc(G).update({ archivedAt: Timestamp.now() });
    await expect(closePoll.run(call('pat', { pollId: 'p1' }))).rejects.toMatchObject({ code: 'failed-precondition' });
    expect((await pollData('p1'))?.closedAt).toBeNull();
  });

  it('closes polls past their close time on the tick, and only those', async () => {
    const past = Timestamp.fromMillis(Date.now() - 60_000);
    await poll('due', { closesAt: past });
    await poll('later', { closesAt: Timestamp.fromMillis(Date.now() + 3_600_000) });
    await poll('open', {});
    await poll('done', { closesAt: past, closedAt: past });
    await vote('due', 'sam', ['1']);
    expect(await closeDuePolls()).toBe(1);
    expect((await pollData('due'))?.closedAt).toBeInstanceOf(Timestamp);
    expect((await pollData('due'))?.closedBy).toBeNull();
    expect((await pollData('later'))?.closedAt).toBeNull();
    expect((await pollData('open'))?.closedAt).toBeNull();
    expect(await centerFor('due_closed')).toEqual(['sam']);
    expect(await closeDuePolls()).toBe(0);
  });
});

describe('creating and deleting (POLL-1, POLL-5)', () => {
  const pollMessage = { groupId: G, authorId: 'pat', authorName: 'Pat', type: 'poll', text: 'Saturday or Sunday?', pollId: 'p1' };

  it("tells the team about a new poll, but not its creator", async () => {
    await notifyNewMessage('p1', pollMessage, 'Thunder', null);
    expect(await centerFor('p1')).toEqual(['alex', 'lee', 'sam']);
    const item = await db().collection(Collections.notifications).doc('p1_sam').get();
    expect(item.get('type')).toBe('pollCreated');
    expect(item.get('body')).toBe('Pat created a poll: Saturday or Sunday?');
  });

  it('deleting the poll’s message deletes the poll, its votes, and its notifications', async () => {
    await poll('p1');
    await vote('p1', 'sam', ['0']);
    await db().collection(Collections.messages).doc('p1').set({ ...pollMessage, attachments: [], reactions: {}, createdAt: Timestamp.now() });
    await notifyNewMessage('p1', pollMessage, 'Thunder', null);
    await eraseMessage('p1', 'pat', 'author');
    expect(await pollData('p1')).toBeUndefined();
    expect((await db().collection(Collections.pollVotes).doc('p1_sam').get()).exists).toBe(false);
    expect(await centerFor('p1')).toEqual([]);
  });
});
