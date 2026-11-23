// Polls on the server (SPEC POLL-2, POLL-4, POLL-5): tallies, closing early
// and on time with the "Poll closed" notification, deleting with the
// message, and the "created a poll" notification. Runs against the
// Firestore emulator with FCM faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { eraseMessage, notifyNewMessage } from '../../src/chat/service.js';
import { closePoll, votePollForPlayers } from '../../src/polls/handlers.js';
import { closeDuePolls, recountPoll, removePlayerPollVotes } from '../../src/polls/service.js';
import { removePlayer } from '../../src/players/service.js';
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

  it('refuses the creator and admins on a suspended team, but not a super admin (§3)', async () => {
    await poll('p1');
    await db().collection(Collections.groups).doc(G).update({ suspendedAt: Timestamp.now() });
    for (const uid of ['pat', 'alex']) {
      await expect(closePoll.run(call(uid, { pollId: 'p1' }))).rejects
        .toMatchObject({ code: 'permission-denied', message: 'team-suspended' });
    }
    expect((await pollData('p1'))?.closedAt).toBeNull();
    await closePoll.run(call('root', { pollId: 'p1' }, { superAdmin: true }));
    expect((await pollData('p1'))?.closedAt).toBeInstanceOf(Timestamp);
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

describe('one vote per player (#96)', () => {
  const vote = (uid: string, votes: Record<string, string[]>, pollId = 'pp') =>
    votePollForPlayers.run(call(uid, { pollId, votes }) as Parameters<typeof votePollForPlayers.run>[0]);
  const playerVote = async (playerId: string, pollId = 'pp') =>
    (await db().collection(Collections.pollPlayerVotes).doc(`${pollId}_${playerId}`).get()).data();
  /** What [uid] was told about replaced votes, newest last. */
  const toldTo = async (uid: string) =>
    (await db().collection(Collections.notifications).where('uid', '==', uid).where('type', '==', 'pollVoteReplaced').get()).docs
      .map((d) => d.get('body') as string)
      .sort();

  beforeEach(async () => {
    // Luke and Alex are Sam's; Luke is Lee's too; Pat is the player Pat.
    for (const [id, name] of [['luke', 'Luke Dunphy'], ['alex', 'Alex Dunphy'], ['pat-p', 'Pat Kim'], ['emma', 'Emma Other']]) {
      await db().collection(Collections.players).doc(id).set({ groupId: id === 'emma' ? 'teamB' : G, displayName: name, status: 'active' });
    }
    const link = (playerId: string, uid: string, relation = 'guardian', groupId = G) =>
      db().collection(Collections.playerGuardians).doc(`${playerId}_${uid}`).set({ playerId, groupId, uid, relation });
    await link('luke', 'sam');
    await link('alex', 'sam');
    await link('luke', 'lee');
    await link('pat-p', 'pat', 'self');
    await link('emma', 'sam', 'guardian', 'teamB');
    await poll('pp', { perPlayer: true, allowMultiple: false });
  });

  it("votes for each of a guardian's players, counts players, and takes it back", async () => {
    expect(await vote('sam', { luke: ['1'], alex: ['1'] })).toEqual({ ok: true, replaced: 0 });
    expect(await playerVote('luke')).toMatchObject({ pollId: 'pp', groupId: G, playerId: 'luke', optionIds: ['1'], uid: 'sam' });
    expect(await vote('pat', { 'pat-p': ['0'] })).toEqual({ ok: true, replaced: 0 });
    expect(await pollData('pp')).toMatchObject({ voteCounts: { 0: 1, 1: 2, 2: 0 }, voterCount: 3 });
    // Taking Alex's back.
    await vote('sam', { alex: [] });
    expect(await playerVote('alex')).toBeUndefined();
    expect(await pollData('pp')).toMatchObject({ voteCounts: { 0: 1, 1: 1 }, voterCount: 2 });
    // Nobody's regular vote counts on it.
    await db().collection(Collections.pollVotes).doc('pp_alex').set({ pollId: 'pp', groupId: G, uid: 'alex', optionIds: ['2'] });
    await recountPoll('pp');
    expect(await pollData('pp')).toMatchObject({ voterCount: 2 });
  });

  it("tells the other guardian when their vote is replaced, naming who and what, once for siblings", async () => {
    await vote('lee', { luke: ['0'] });
    // The same answer replaces nothing, and Luke's vote stays Lee's.
    expect(await vote('sam', { luke: ['0'], alex: ['0'] })).toEqual({ ok: true, replaced: 0 });
    expect((await playerVote('luke'))?.uid).toBe('lee');
    expect(await toldTo('lee')).toEqual([]);
    // A different one does, and Lee hears it.
    expect(await vote('sam', { luke: ['1'] })).toEqual({ ok: true, replaced: 1 });
    expect(await playerVote('luke')).toMatchObject({ optionIds: ['1'], uid: 'sam' });
    expect(await toldTo('lee')).toEqual(['Sam voted Sunday for Luke on “Saturday or Sunday?”, replacing your vote (Saturday)']);
    const item = (await db().collection(Collections.notifications).where('uid', '==', 'lee').get()).docs[0];
    expect(item.get('route')).toBe(`/g/${G}/chat/m/pp`);
    // Changing your own vote tells nobody.
    await vote('sam', { luke: ['0'] });
    expect(await toldTo('lee')).toHaveLength(1);
    // Taking back someone else's vote says so.
    await vote('lee', { luke: ['1'] });
    await vote('sam', { luke: [] });
    expect(await toldTo('lee')).toContain('Sam took back the vote for Luke on “Saturday or Sunday?” (yours was Sunday)');
  });

  it("refuses players who aren't theirs, other teams', bad choices, and regular polls", async () => {
    await expect(vote('lee', { alex: ['0'] })).rejects.toMatchObject({ code: 'permission-denied', message: 'not-your-player' });
    await expect(vote('sam', { emma: ['0'] })).rejects.toMatchObject({ code: 'permission-denied', message: 'not-your-player' });
    await expect(vote('alex', { luke: ['0'] })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(vote('sam', { luke: ['0', '1'] })).rejects.toMatchObject({ code: 'invalid-argument', message: 'one-choice' });
    await expect(vote('sam', { luke: ['9'] })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(vote('sam', {})).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(vote('sam', { 'a_b': ['0'] })).rejects.toMatchObject({ code: 'invalid-argument' });
    await poll('regular');
    await expect(vote('sam', { luke: ['0'] }, 'regular')).rejects.toMatchObject({ code: 'failed-precondition', message: 'not-per-player' });
    await expect(vote('sam', { luke: ['0'] }, 'nope')).rejects.toMatchObject({ code: 'not-found' });
    expect(await playerVote('luke')).toBeUndefined();
  });

  it('refuses a closed poll, and an archived or suspended team', async () => {
    await poll('closed', { perPlayer: true, closedAt: Timestamp.now() });
    await expect(vote('sam', { luke: ['0'] }, 'closed')).rejects.toMatchObject({ code: 'failed-precondition', message: 'poll-closed' });
    await poll('past', { perPlayer: true, closesAt: Timestamp.fromMillis(Date.now() - 1000) });
    await expect(vote('sam', { luke: ['0'] }, 'past')).rejects.toMatchObject({ message: 'poll-closed' });
    await db().collection(Collections.groups).doc(G).update({ archivedAt: Timestamp.now() });
    await expect(vote('sam', { luke: ['0'] })).rejects.toMatchObject({ code: 'failed-precondition', message: 'team-archived' });
    await db().collection(Collections.groups).doc(G).update({ archivedAt: null, suspendedAt: Timestamp.now() });
    await expect(vote('sam', { luke: ['0'] })).rejects.toMatchObject({ code: 'permission-denied', message: 'team-suspended' });
  });

  it('tells whoever cast a vote when it closes, once each', async () => {
    await vote('sam', { luke: ['0'], alex: ['0'] });
    await vote('pat', { 'pat-p': ['1'] });
    await closePoll.run(call('alex', { pollId: 'pp' }));
    expect(await centerFor('pp_closed')).toEqual(['pat', 'sam']);
  });

  it("drops a removed player's votes on open polls, keeping closed polls' results", async () => {
    await vote('sam', { luke: ['0'], alex: ['0'] });
    await poll('old', { perPlayer: true });
    await vote('sam', { luke: ['1'] }, 'old');
    await db().collection(Collections.polls).doc('old').update({ closedAt: Timestamp.now() });
    await removePlayer(G, 'luke');
    expect(await playerVote('luke')).toBeUndefined();
    expect(await pollData('pp')).toMatchObject({ voteCounts: { 0: 1 }, voterCount: 1 });
    expect(await playerVote('luke', 'old')).toMatchObject({ optionIds: ['1'] });
    await expect(removePlayerPollVotes('nobody')).resolves.toBeUndefined();
  });

  it('deletes its players\' votes with the poll', async () => {
    await vote('sam', { luke: ['0'] });
    const message = { groupId: G, authorId: 'pat', authorName: 'Pat', type: 'poll', text: 'Saturday or Sunday?', pollId: 'pp' };
    await db().collection(Collections.messages).doc('pp').set({ ...message, attachments: [], reactions: {}, createdAt: Timestamp.now() });
    await eraseMessage('pp', 'pat', 'author');
    expect(await playerVote('luke')).toBeUndefined();
  });
});
