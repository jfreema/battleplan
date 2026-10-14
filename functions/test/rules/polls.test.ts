// Security rules for polls and votes (ARCH §6.3; SPEC POLL-1 to POLL-4).
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
const now = () => firebase.firestore.FieldValue.serverTimestamp();
const ts = (iso: string) => firebase.firestore.Timestamp.fromDate(new Date(iso));
const as = (uid: string): Db => env.authenticatedContext(uid).firestore();

const options = (...texts: string[]) => texts.map((text, i) => ({ id: String(i), text }));

// Team A has alice (owner) and bob (member); team B has carol. Polls on
// team A: p1 open (one answer), p2 anonymous with several answers, p3
// closed, p4 past its close time.
async function seed(membersCanCreatePolls = true) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const settings = { membersCanCreatePolls, membersCanCreateEvents: false, membersCanUploadDocs: true };
    for (const [g, name] of [['teamA', 'Thunder'], ['teamB', 'Lightning']]) {
      await db.doc(`groups/${g}`).set({ name, nameLower: name.toLowerCase(), settings, storageBytes: 0, storageQuotaBytes: 1 });
    }
    const member = (g: string, uid: string, role: string, displayName: string) =>
      db.doc(`groupMembers/${g}_${uid}`).set({ groupId: g, uid, role, displayName, photoPath: null });
    await member('teamA', 'alice', 'owner', 'Alice');
    await member('teamA', 'bob', 'member', 'Bob');
    await member('teamB', 'carol', 'admin', 'Carol');
    const poll = (id: string, extra: object) =>
      db.doc(`polls/${id}`).set({
        groupId: 'teamA',
        messageId: id,
        createdBy: 'alice',
        question: 'Saturday or Sunday?',
        options: options('Saturday', 'Sunday'),
        allowMultiple: false,
        anonymous: false,
        closesAt: null,
        closedAt: null,
        voteCounts: {},
        voterCount: 0,
        ...extra,
      });
    await poll('p1', {});
    await poll('p2', { anonymous: true, allowMultiple: true, options: options('Pizza', 'Tacos', 'Burgers') });
    await poll('p3', { closedAt: ts('2026-01-01T00:00:00Z') });
    await poll('p4', { closesAt: ts('2026-01-01T00:00:00Z') });
    await db.doc('pollVotes/p1_alice').set({ pollId: 'p1', groupId: 'teamA', uid: 'alice', optionIds: ['0'] });
    await db.doc('pollVotes/p2_alice').set({ pollId: 'p2', groupId: 'teamA', uid: 'alice', optionIds: ['0', '2'] });
    await db.doc('pollVotes/p3_bob').set({ pollId: 'p3', groupId: 'teamA', uid: 'bob', optionIds: ['1'] });
  });
}

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-battleplan',
    firestore: { rules: readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed();
});

afterAll(async () => {
  await env?.cleanup();
});

describe('creating a poll (POLL-1)', () => {
  const goodPoll = (uid: string, g = 'teamA') => ({
    groupId: g,
    messageId: 'new',
    createdBy: uid,
    question: 'Team dinner?',
    options: options('Yes', 'No'),
    allowMultiple: false,
    anonymous: false,
    closesAt: null,
    closedAt: null,
    voteCounts: {},
    voterCount: 0,
    createdAt: now(),
  });

  /** The poll, its message, and the sender's rate-limit stamp, in one batch. */
  const create = (
    uid: string,
    name: string,
    poll: object = {},
    message: object = {},
    { g = 'teamA', withPoll = true, withMessage = true, superAdmin = false } = {},
  ) => {
    const db = superAdmin ? env.authenticatedContext(uid, { superAdmin: true }).firestore() : as(uid);
    const batch = db.batch();
    const p = { ...goodPoll(uid, g), ...poll } as Record<string, unknown>;
    if (withPoll) batch.set(db.doc('polls/new'), p);
    if (withMessage) {
      batch.set(db.doc('messages/new'), {
        groupId: g,
        authorId: uid,
        authorName: name,
        authorPhotoPath: null,
        type: 'poll',
        text: p.question,
        attachments: [],
        pollId: 'new',
        createdAt: now(),
        ...message,
      });
    }
    batch.update(db.doc(`groupMembers/${g}_${uid}`), { lastPostedAt: now(), lastPostedMessageId: 'new' });
    return batch.commit();
  };

  it('lets a member post a poll with its message', async () => {
    await assertSucceeds(create('bob', 'Bob'));
  });

  it("refuses mentions and announcements on a poll's message (CHAT-14, CHAT-15)", async () => {
    await assertFails(create('alice', 'Alice', {}, { mentions: ['bob'] }));
    await assertFails(create('alice', 'Alice', {}, { mentionsEveryone: true }));
    await assertFails(create('alice', 'Alice', {}, { announcement: true }));
  });

  it('takes 10 options, several answers, anonymity, and a close time', async () => {
    await assertSucceeds(
      create('alice', 'Alice', {
        options: options('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'),
        allowMultiple: true,
        anonymous: true,
        closesAt: firebase.firestore.Timestamp.fromMillis(Date.now() + 86_400_000),
      }),
    );
  });

  it('lets only admins post polls when members may not (TEAM-5)', async () => {
    await env.clearFirestore();
    await seed(false);
    await assertFails(create('bob', 'Bob'));
    await assertSucceeds(create('alice', 'Alice'));
  });

  it('lets a super admin on the team post polls when members may not (§3)', async () => {
    await env.clearFirestore();
    await seed(false);
    await assertSucceeds(create('bob', 'Bob', {}, {}, { superAdmin: true }));
    // Not on the team: polls are messages, which need membership.
    await assertFails(create('carol', 'Carol', {}, {}, { superAdmin: true }));
  });

  it('needs the poll and its message together', async () => {
    await assertFails(create('bob', 'Bob', {}, {}, { withMessage: false }));
    await assertFails(create('bob', 'Bob', {}, {}, { withPoll: false }));
    await assertFails(create('bob', 'Bob', {}, { pollId: 'other' }));
    await assertFails(create('bob', 'Bob', {}, { text: 'Something else' }));
  });

  it('refuses bad questions, options, settings, and counts', async () => {
    await assertFails(create('bob', 'Bob', { question: '' }));
    await assertFails(create('bob', 'Bob', { question: 'x'.repeat(201) }));
    await assertFails(create('bob', 'Bob', { options: options('Only one') }));
    await assertFails(create('bob', 'Bob', { options: options(...'ABCDEFGHIJK'.split('')) }));
    await assertFails(create('bob', 'Bob', { options: options('Yes', 'x'.repeat(81)) }));
    await assertFails(create('bob', 'Bob', { options: options('Yes', ' ') }));
    await assertFails(create('bob', 'Bob', { options: [{ id: '1', text: 'Yes' }, { id: '0', text: 'No' }] }));
    await assertFails(create('bob', 'Bob', { anonymous: 'yes' }));
    await assertFails(create('bob', 'Bob', { voteCounts: { 0: 5 } }));
    await assertFails(create('bob', 'Bob', { voterCount: 3 }));
    await assertFails(create('bob', 'Bob', { closedAt: now() }));
    await assertFails(create('bob', 'Bob', { closesAt: ts('2020-01-01T00:00:00Z') }));
    await assertFails(create('bob', 'Bob', { createdBy: 'alice' }));
    await assertFails(create('bob', 'Bob', { extra: true }));
  });

  it('refuses new polls on an archived team (TEAM-9)', async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ archivedAt: ts('2026-02-01T00:00:00Z') }));
    await assertFails(create('bob', 'Bob'));
  });

  it("refuses another team's members", async () => {
    await assertFails(create('carol', 'Carol'));
  });

  it('keeps tallies and closing to Functions', async () => {
    await assertFails(as('alice').doc('polls/p1').update({ voterCount: 9 }));
    await assertFails(as('alice').doc('polls/p1').update({ closedAt: now() }));
    await assertFails(as('alice').doc('polls/p1').delete());
  });

  it('keeps pollId off other messages', async () => {
    const db = as('bob');
    const batch = db.batch();
    batch.set(db.doc('messages/t1'), {
      groupId: 'teamA', authorId: 'bob', authorName: 'Bob', authorPhotoPath: null,
      type: 'text', text: 'hi', attachments: [], pollId: 'p1', createdAt: now(),
    });
    batch.update(db.doc('groupMembers/teamA_bob'), { lastPostedAt: now(), lastPostedMessageId: 't1' });
    await assertFails(batch.commit());
  });
});

describe('voting (POLL-2)', () => {
  const vote = (uid: string, pollId: string, optionIds: unknown, extra: object = {}, id = `${pollId}_${uid}`) =>
    as(uid).doc(`pollVotes/${id}`).set({ pollId, groupId: 'teamA', uid, optionIds, updatedAt: now(), ...extra });

  it('takes one answer, or several on a multiple-answer poll', async () => {
    await assertSucceeds(vote('bob', 'p1', ['1']));
    await assertSucceeds(vote('bob', 'p1', ['0'])); // changed
    await assertSucceeds(vote('bob', 'p2', ['0', '1', '2']));
    await assertFails(vote('bob', 'p1', ['0', '1']));
  });

  it('refuses choices that are not options, repeats, and empty votes', async () => {
    await assertFails(vote('bob', 'p1', ['2']));
    await assertFails(vote('bob', 'p1', ['Saturday']));
    await assertFails(vote('bob', 'p2', ['1', '1']));
    await assertFails(vote('bob', 'p1', []));
    await assertFails(vote('bob', 'p1', '0'));
  });

  it('closes voting once closed or past the close time (POLL-4)', async () => {
    await assertFails(vote('alice', 'p3', ['0']));
    await assertFails(vote('alice', 'p4', ['0']));
    await assertFails(as('bob').doc('pollVotes/p3_bob').delete());
  });

  it('lets you remove your vote while the poll is open', async () => {
    await assertSucceeds(as('alice').doc('pollVotes/p1_alice').delete());
    await assertFails(as('bob').doc('pollVotes/p2_alice').delete());
  });

  it('refuses voting and removing a vote on an archived team (TEAM-9)', async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ archivedAt: ts('2026-02-01T00:00:00Z') }));
    await assertFails(vote('bob', 'p1', ['0']));
    await assertFails(as('alice').doc('pollVotes/p1_alice').delete());
  });

  it('refuses removing a vote after leaving the team', async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groupMembers/teamA_alice').delete());
    await assertFails(as('alice').doc('pollVotes/p1_alice').delete());
  });

  it('refuses votes in another name, under another ID, or from another team', async () => {
    await assertFails(vote('bob', 'p1', ['0'], { uid: 'alice' }));
    await assertFails(vote('bob', 'p1', ['0'], {}, 'p1_alice'));
    await assertFails(vote('bob', 'p1', ['0'], {}, 'p2_bob'));
    await assertFails(vote('bob', 'p1', ['0'], { groupId: 'teamB' }));
    await assertFails(vote('carol', 'p1', ['0']));
    await assertFails(vote('bob', 'p1', ['0'], { extra: 1 }));
  });
});

describe('who voted (POLL-3)', () => {
  const votesOf = (uid: string, pollId: string) =>
    as(uid).collection('pollVotes').where('pollId', '==', pollId).limit(100).get();

  it('shows teammates who chose what on regular polls', async () => {
    await assertSucceeds(as('bob').doc('pollVotes/p1_alice').get());
    await assertSucceeds(votesOf('bob', 'p1'));
    await assertFails(as('carol').doc('pollVotes/p1_alice').get());
    await assertFails(votesOf('carol', 'p1'));
  });

  it('shows nobody else your vote on an anonymous poll, admins included', async () => {
    await assertFails(as('bob').doc('pollVotes/p2_alice').get());
    await assertFails(votesOf('bob', 'p2'));
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('pollVotes/p2_bob').set({ pollId: 'p2', groupId: 'teamA', uid: 'bob', optionIds: ['1'] }),
    );
    await assertFails(as('alice').doc('pollVotes/p2_bob').get());
  });

  it('always lets you read your own vote, or find you have none', async () => {
    await assertSucceeds(as('alice').doc('pollVotes/p2_alice').get());
    await assertSucceeds(as('bob').doc('pollVotes/p2_bob').get());
    await assertSucceeds(
      as('alice').collection('pollVotes').where('pollId', '==', 'p2').where('uid', '==', 'alice').limit(1).get(),
    );
  });
});
