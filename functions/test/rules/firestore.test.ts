// Security-rules tests (ARCH §6.3, SPEC ENG-7). Run against the emulator:
//   npm --prefix functions run emulators:test
//
// This is also M0 spike 5: membership checks from a query's groupId filter,
// one RSVP per event and player, and the message rate limit.
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

// Team A (adult) has alice (owner) and bob (member). Team B (youth) has
// carol (admin) and two guardians of player emma: dan and erin. Frank is a
// parent on team B with no player link.
const memberDoc = (groupId: string, uid: string, role: string, name: string) => ({
  groupId,
  uid,
  role,
  displayName: name,
  photoPath: null,
  notificationLevel: 'all',
  joinedAt: ts('2026-01-01T00:00:00Z'),
});

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const settings = {
      membersCanCreateEvents: false,
      membersCanCreatePolls: true,
      membersCanUploadDocs: true,
      membersCanInvite: true,
      allowMaybe: true,
      defaultReminderOffsets: [1440],
    };
    await db.doc('groups/teamA').set({
      name: 'Thunder', nameLower: 'thunder', sport: 'softball', color: '#2F5BEA',
      photoPath: null, teamType: 'adult', settings, memberCount: 2,
    });
    await db.doc('groups/teamB').set({ name: 'Lightning U10', teamType: 'youth', settings, memberCount: 4 });
    await db.doc('groupMembers/teamA_alice').set(memberDoc('teamA', 'alice', 'owner', 'Alice'));
    await db.doc('groupMembers/teamA_bob').set(memberDoc('teamA', 'bob', 'member', 'Bob'));
    await db.doc('groupMembers/teamB_carol').set(memberDoc('teamB', 'carol', 'admin', 'Carol'));
    await db.doc('groupMembers/teamB_dan').set(memberDoc('teamB', 'dan', 'member', 'Dan'));
    await db.doc('groupMembers/teamB_erin').set(memberDoc('teamB', 'erin', 'member', 'Erin'));
    await db.doc('groupMembers/teamB_frank').set(memberDoc('teamB', 'frank', 'member', 'Frank'));
    await db.doc('players/emma').set({ groupId: 'teamB', displayName: 'Emma', displayNameLower: 'emma', jerseyNumber: '7' });
    await db.doc('playerGuardians/emma_dan').set({ playerId: 'emma', groupId: 'teamB', uid: 'dan' });
    await db.doc('playerGuardians/emma_erin').set({ playerId: 'emma', groupId: 'teamB', uid: 'erin' });
    await db.doc('messages/m1').set({ groupId: 'teamA', authorId: 'alice', type: 'text', text: 'Hi', reactions: {} });
    await db.doc('messages/m2').set({ groupId: 'teamB', authorId: 'carol', type: 'text', text: 'Hi', reactions: {} });
    const event = (groupId: string, rsvpFor: string) => ({
      groupId,
      type: 'practice',
      title: 'Practice',
      rsvpEnabled: true,
      rsvpFor,
      startAt: ts('2030-06-01T18:00:00Z'),
      rsvpCounts: { going: 0, maybe: 0, notGoing: 0 },
    });
    await db.doc('events/eA').set(event('teamA', 'members'));
    await db.doc('events/eB').set(event('teamB', 'players'));
    await db.doc('events/eLate').set({ ...event('teamA', 'members'), rsvpDeadline: ts('2020-01-01T00:00:00Z') });
  });
}

const as = (uid: string): Db => env.authenticatedContext(uid).firestore();

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

describe('team isolation', () => {
  it('lets a member query their team by groupId', async () => {
    await assertSucceeds(as('bob').collection('messages').where('groupId', '==', 'teamA').limit(50).get());
  });

  it('blocks a member of team A from reading team B', async () => {
    await assertFails(as('bob').collection('messages').where('groupId', '==', 'teamB').limit(50).get());
    await assertFails(as('bob').doc('messages/m2').get());
    await assertFails(as('bob').doc('groups/teamB').get());
    await assertFails(as('bob').collection('groupMembers').where('groupId', '==', 'teamB').limit(50).get());
  });

  it('rejects queries without a groupId filter or a limit', async () => {
    await assertFails(as('bob').collection('messages').limit(50).get());
    await assertFails(as('bob').collection('messages').where('groupId', '==', 'teamA').get());
    await assertFails(as('bob').collection('messages').where('groupId', '==', 'teamA').limit(101).get());
  });

  it('lists only your own memberships for the team switcher', async () => {
    await assertSucceeds(as('dan').collection('groupMembers').where('uid', '==', 'dan').limit(100).get());
    await assertFails(as('dan').collection('groupMembers').where('uid', '==', 'alice').limit(100).get());
  });

  it('blocks everything for a signed-out visitor', async () => {
    const anon = env.unauthenticatedContext().firestore();
    await assertFails(anon.doc('groups/teamA').get());
    await assertFails(anon.collection('messages').where('groupId', '==', 'teamA').limit(50).get());
  });

  it('makes archived teams read-only', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('groups/teamA').update({ archivedAt: ts('2026-05-01T00:00:00Z') }),
    );
    await assertSucceeds(as('bob').doc('messages/m1').get());
    await assertFails(as('bob').doc('messages/m1').update({ 'reactions.bob': 'like' }));
    await assertFails(as('alice').doc('groups/teamA').update({ name: 'Renamed', nameLower: 'renamed' }));
  });

  it('blocks members of a suspended team', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('groups/teamA').update({ suspendedAt: ts('2026-05-01T00:00:00Z') }),
    );
    await assertFails(as('bob').doc('messages/m1').get());
  });
});

describe('message rate limit and create rule', () => {
  const send = (db: Db, uid: string, groupId: string, id: string, name: string, extra: object = {}) => {
    const batch = db.batch();
    batch.set(db.doc(`messages/${id}`), {
      groupId,
      authorId: uid,
      authorName: name,
      authorPhotoPath: null,
      type: 'text',
      text: 'On my way!',
      createdAt: now(),
      ...extra,
    });
    batch.update(db.doc(`groupMembers/${groupId}_${uid}`), {
      lastPostedAt: now(),
      lastPostedMessageId: id,
    });
    return batch.commit();
  };

  it('accepts a message with its lastPostedAt update', async () => {
    await assertSucceeds(send(as('bob'), 'bob', 'teamA', 'new1', 'Bob'));
  });

  it('rejects a second message within a second', async () => {
    await assertSucceeds(send(as('bob'), 'bob', 'teamA', 'new1', 'Bob'));
    await assertFails(send(as('bob'), 'bob', 'teamA', 'new2', 'Bob'));
  });

  it('accepts the next message once a second has passed', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('groupMembers/teamA_bob').update({ lastPostedAt: ts('2026-01-01T00:00:00Z') }),
    );
    await assertSucceeds(send(as('bob'), 'bob', 'teamA', 'new2', 'Bob'));
  });

  it('rejects several messages in one batch', async () => {
    const db = as('bob');
    const batch = db.batch();
    for (const id of ['x1', 'x2']) {
      batch.set(db.doc(`messages/${id}`), {
        groupId: 'teamA', authorId: 'bob', authorName: 'Bob', authorPhotoPath: null,
        type: 'text', text: 'spam', createdAt: now(),
      });
    }
    batch.update(db.doc('groupMembers/teamA_bob'), { lastPostedAt: now(), lastPostedMessageId: 'x2' });
    await assertFails(batch.commit());
  });

  it('rejects a message without the lastPostedAt update', async () => {
    await assertFails(as('bob').doc('messages/solo').set({
      groupId: 'teamA', authorId: 'bob', authorName: 'Bob', authorPhotoPath: null,
      type: 'text', text: 'hi', createdAt: now(),
    }));
  });

  it('rejects a forged author name or another author', async () => {
    await assertFails(send(as('bob'), 'bob', 'teamA', 'f1', 'Coach Alice'));
    await assertFails(send(as('bob'), 'bob', 'teamA', 'f2', 'Bob', { authorId: 'alice' }));
  });

  it('rejects server-only types and fields', async () => {
    await assertFails(send(as('bob'), 'bob', 'teamA', 's1', 'Bob', { type: 'system' }));
    await assertFails(send(as('bob'), 'bob', 'teamA', 's2', 'Bob', { reactions: { bob: 'like' } }));
    await assertFails(send(as('bob'), 'bob', 'teamA', 's3', 'Bob', {
      replyPreview: { authorName: 'Alice', text: 'fake quote' },
    }));
  });

  it('rejects text over 4,000 characters', async () => {
    await assertFails(send(as('bob'), 'bob', 'teamA', 'long', 'Bob', { text: 'x'.repeat(4001) }));
  });

  it('rejects posting into another team', async () => {
    await assertFails(send(as('bob'), 'bob', 'teamB', 'cross', 'Bob'));
  });

  it('accepts photos stored under the message, up to 10 (CHAT-3)', async () => {
    const photo = (id: string, n: number) => ({ path: `groups/teamA/messages/${id}/${n}.jpg`, width: 10, height: 10 });
    await assertSucceeds(
      send(as('bob'), 'bob', 'teamA', 'p1', 'Bob', { type: 'image', text: '', attachments: [photo('p1', 0), photo('p1', 1)] }),
    );
  });

  it("rejects photos from another message or team, empty photo messages, and more than 10", async () => {
    const photo = (path: string) => ({ path, width: 10, height: 10 });
    const db = as('bob');
    await assertFails(send(db, 'bob', 'teamA', 'p2', 'Bob', { type: 'image', attachments: [photo('groups/teamB/messages/p2/0.jpg')] }));
    await assertFails(send(db, 'bob', 'teamA', 'p3', 'Bob', { type: 'image', attachments: [photo('groups/teamA/messages/other/0.jpg')] }));
    await assertFails(send(db, 'bob', 'teamA', 'p4', 'Bob', { type: 'image', attachments: [] }));
    await assertFails(send(db, 'bob', 'teamA', 'p5', 'Bob', { type: 'text', attachments: [photo('groups/teamA/messages/p5/0.jpg')] }));
    const eleven = Array.from({ length: 11 }, (_, i) => photo(`groups/teamA/messages/p6/${i}.jpg`));
    await assertFails(send(db, 'bob', 'teamA', 'p6', 'Bob', { type: 'image', attachments: eleven }));
  });
});

describe('reactions', () => {
  it('lets a member set and clear only their own reaction', async () => {
    const db = as('bob');
    await assertSucceeds(db.doc('messages/m1').update({ 'reactions.bob': 'love' }));
    await assertSucceeds(db.doc('messages/m1').update({ 'reactions.bob': firebase.firestore.FieldValue.delete() }));
    await assertFails(db.doc('messages/m1').update({ 'reactions.alice': 'like' }));
    await assertFails(db.doc('messages/m1').update({ 'reactions.bob': 'fire' }));
    await assertFails(db.doc('messages/m1').update({ text: 'edited by bob' }));
  });
});

describe('one RSVP per event and participant', () => {
  const rsvp = (db: Db, eventId: string, participantType: string, participantId: string, uid: string, status: string) =>
    db.doc(`rsvps/${eventId}_${participantId}`).set({
      eventId,
      groupId: eventId === 'eB' ? 'teamB' : 'teamA',
      participantType,
      participantId,
      participantName: participantId,
      eventStartAt: ts('2030-06-01T18:00:00Z'),
      status,
      guests: 0,
      respondedBy: uid,
      updatedAt: now(),
    });

  it('lets adult members answer for themselves only', async () => {
    await assertSucceeds(rsvp(as('bob'), 'eA', 'member', 'bob', 'bob', 'going'));
    await assertFails(rsvp(as('bob'), 'eA', 'member', 'alice', 'bob', 'going'));
  });

  it('lets admins answer for any member', async () => {
    await assertSucceeds(rsvp(as('alice'), 'eA', 'member', 'bob', 'alice', 'maybe'));
  });

  it('has both guardians write the same record, latest answer winning', async () => {
    await assertSucceeds(rsvp(as('dan'), 'eB', 'player', 'emma', 'dan', 'going'));
    await assertSucceeds(rsvp(as('erin'), 'eB', 'player', 'emma', 'erin', 'not_going'));
    await env.withSecurityRulesDisabled(async (ctx) => {
      const docs = await ctx.firestore().collection('rsvps').where('eventId', '==', 'eB').get();
      if (docs.size !== 1) throw new Error(`expected 1 RSVP, found ${docs.size}`);
      const d = docs.docs[0].data();
      if (d.status !== 'not_going' || d.respondedBy !== 'erin') throw new Error('latest answer should win');
    });
  });

  it('rejects a parent who is not the player’s guardian', async () => {
    await assertFails(rsvp(as('frank'), 'eB', 'player', 'emma', 'frank', 'going'));
  });

  it('lets a youth-team admin answer for a player', async () => {
    await assertSucceeds(rsvp(as('carol'), 'eB', 'player', 'emma', 'carol', 'maybe'));
  });

  it('rejects a mismatched document ID', async () => {
    const db = as('dan');
    await assertFails(db.doc('rsvps/eB_dan').set({
      eventId: 'eB', groupId: 'teamB', participantType: 'player', participantId: 'emma',
      participantName: 'Emma', eventStartAt: ts('2030-06-01T18:00:00Z'), status: 'going',
      guests: 0, respondedBy: 'dan', updatedAt: now(),
    }));
  });

  it('lets youth-team admins RSVP for themselves, but not parents (Q14)', async () => {
    await assertSucceeds(rsvp(as('carol'), 'eB', 'member', 'carol', 'carol', 'going'));
    await assertFails(rsvp(as('dan'), 'eB', 'member', 'dan', 'dan', 'going'));
    await assertFails(rsvp(as('carol'), 'eB', 'member', 'dan', 'carol', 'going'));
  });

  it('rejects answers given in someone else’s name', async () => {
    await assertFails(rsvp(as('dan'), 'eB', 'player', 'emma', 'erin', 'going'));
  });

  it('closes RSVPs after the deadline, except for admins', async () => {
    await assertFails(rsvp(as('bob'), 'eLate', 'member', 'bob', 'bob', 'going'));
    await assertSucceeds(rsvp(as('alice'), 'eLate', 'member', 'bob', 'alice', 'going'));
  });

  it('blocks other teams from answering', async () => {
    await assertFails(rsvp(as('bob'), 'eB', 'player', 'emma', 'bob', 'going'));
  });
});

describe('cache and server-only fields', () => {
  it('rejects members editing team cache fields or other people’s memberships', async () => {
    await assertFails(as('alice').doc('groups/teamA').update({ memberCount: 99 }));
    await assertSucceeds(as('alice').doc('groups/teamA').update({ name: 'Thunder FC', nameLower: 'thunder fc' }));
    await assertFails(as('bob').doc('groups/teamA').update({ name: 'Bob’s team' }));
    await assertFails(as('bob').doc('groupMembers/teamA_bob').update({ role: 'admin' }));
    await assertFails(as('bob').doc('groupMembers/teamA_alice').update({ lastReadAt: now() }));
    await assertSucceeds(as('bob').doc('groupMembers/teamA_bob').update({ lastReadAt: now() }));
  });

  it('validates team settings edits (TEAM-5)', async () => {
    const db = as('alice');
    await assertSucceeds(db.doc('groups/teamA').update({ name: 'Thunder FC', nameLower: 'thunder fc' }));
    await assertSucceeds(db.doc('groups/teamA').update({ 'settings.membersCanCreateEvents': true }));
    await assertSucceeds(db.doc('groups/teamA').update({ photoPath: 'groups/teamA/avatar/1.jpg' }));
    await assertFails(db.doc('groups/teamA').update({ name: 'Thunder FC', nameLower: 'other' }));
    await assertFails(db.doc('groups/teamA').update({ color: '#123456' }));
    await assertFails(db.doc('groups/teamA').update({ sport: 'chess' }));
    await assertFails(db.doc('groups/teamA').update({ 'settings.canDelete': true }));
    await assertFails(db.doc('groups/teamA').update({ photoPath: 'groups/teamB/avatar/1.jpg' }));
  });

  it('keeps lastPostedAt at the request time', async () => {
    await assertFails(as('bob').doc('groupMembers/teamA_bob').update({ lastPostedAt: ts('2020-01-01T00:00:00Z') }));
  });

  it('keeps invites and rate limits server-only', async () => {
    await assertFails(as('alice').doc('invites/K7XPM2QR').get());
    await assertFails(as('alice').doc('rateLimits/alice_send_1').set({ count: 0 }));
  });
});

describe("kids' privacy (PLAYER-10)", () => {
  const edit = { displayName: 'Emma R', displayNameLower: 'emma r', jerseyNumber: '8', position: 'Keeper' };

  it('lets a guardian or an admin edit name, number, and position', async () => {
    await assertSucceeds(as('dan').doc('players/emma').update(edit));
    await assertSucceeds(as('carol').doc('players/emma').update({ jerseyNumber: null }));
  });

  it('blocks other parents and other teams', async () => {
    await assertFails(as('frank').doc('players/emma').update(edit));
    await assertFails(as('alice').doc('players/emma').update(edit));
  });

  it('never lets a player record hold more than a name, number, and position', async () => {
    await assertFails(as('dan').doc('players/emma').update({ birthdate: '2016-04-01' }));
    await assertFails(as('dan').doc('players/emma').update({ photoPath: 'x.jpg' }));
    await assertFails(as('dan').doc('players/emma').update({ jerseyNumber: '12345' }));
    await assertFails(as('dan').doc('players/emma').update({ displayName: '', displayNameLower: '' }));
    await assertFails(as('dan').doc('players/emma').update({ displayName: 'Emma', displayNameLower: 'someone else' }));
  });

  it('leaves creating players to Functions', async () => {
    await assertFails(as('carol').doc('players/new').set({ groupId: 'teamB', displayName: 'Liam', displayNameLower: 'liam' }));
  });
});
