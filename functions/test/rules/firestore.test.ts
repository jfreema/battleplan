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
import { CHAT_CANDY_COLORS } from '../../src/admin/inputs.js';
import { reactionValues, RETIRED_TEAM_COLORS, TEAM_COLORS } from '../../src/shared/constants.js';

type Db = firebase.firestore.Firestore;

let env: RulesTestEnvironment;
const now = () => firebase.firestore.FieldValue.serverTimestamp();
const ts = (iso: string) => firebase.firestore.Timestamp.fromDate(new Date(iso));

// Team A has alice (owner) and bob (member). Team B (an old doc that still
// says teamType 'youth') has carol (admin) and two guardians of player
// emma: dan and erin. Frank is on team B with no player link.
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
      photoPath: null, kind: 'team', settings, memberCount: 2,
    });
    await db.doc('groups/teamB').set({
      name: 'Lightning U10', nameLower: 'lightning u10', sport: 'soccer', color: null,
      photoPath: null, teamType: 'youth', settings, memberCount: 4,
    });
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
    // rsvpFor is only on events made before one team type.
    const event = (groupId: string, rsvpFor: string | null) => ({
      groupId,
      type: 'practice',
      title: 'Practice',
      rsvpEnabled: true,
      ...(rsvpFor ? { rsvpFor } : {}),
      startAt: ts('2030-06-01T18:00:00Z'),
      rsvpCounts: { going: 0, maybe: 0, notGoing: 0 },
    });
    await db.doc('events/eA').set(event('teamA', 'members'));
    await db.doc('events/eB').set(event('teamB', null));
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

describe('mentions, announcements, and pins (CHAT-14, CHAT-15)', () => {
  /** Posts as [uid], a while after their last message, so only [extra] decides. */
  const send = async (uid: string, name: string, id: string, extra: object, db: Db = as(uid)) => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc(`groupMembers/teamA_${uid}`).update({ lastPostedAt: ts('2026-01-01T00:00:00Z') }),
    );
    const batch = db.batch();
    batch.set(db.doc(`messages/${id}`), {
      groupId: 'teamA', authorId: uid, authorName: name, authorPhotoPath: null,
      type: 'text', text: '@Bob see you', createdAt: now(), ...extra,
    });
    batch.update(db.doc(`groupMembers/teamA_${uid}`), { lastPostedAt: now(), lastPostedMessageId: id });
    return batch.commit();
  };

  it('lets anyone name up to 20 people, on text and photos', async () => {
    await assertSucceeds(send('bob', 'Bob', 'n1', { mentions: ['alice'] }));
    await assertSucceeds(send('alice', 'Alice', 'n2', { mentions: Array.from({ length: 20 }, (_, i) => `u${i}`) }));
    const photo = { path: 'groups/teamA/messages/n6/0.jpg', width: 10, height: 10 };
    await assertSucceeds(send('bob', 'Bob', 'n6', { type: 'image', attachments: [photo], mentions: ['alice'] }));
  });

  it('refuses more than 20, and a list that is not a list', async () => {
    await assertFails(send('bob', 'Bob', 'n3', { mentions: Array.from({ length: 21 }, (_, i) => `u${i}`) }));
    await assertFails(send('bob', 'Bob', 'n4', { mentions: 'alice' }));
  });

  it('keeps @everyone for admins', async () => {
    await assertFails(send('bob', 'Bob', 'e1', { mentionsEveryone: true }));
    await assertSucceeds(send('bob', 'Bob', 'e2', { mentionsEveryone: false }));
    await assertSucceeds(send('alice', 'Alice', 'e3', { mentionsEveryone: true }));
    await assertFails(send('alice', 'Alice', 'e4', { mentionsEveryone: 'yes' }));
  });

  it('keeps announcements for admins, as text', async () => {
    await assertFails(send('bob', 'Bob', 'a1', { announcement: true }));
    await assertSucceeds(send('alice', 'Alice', 'a2', { announcement: true }));
    const photo = { path: 'groups/teamA/messages/a3/0.jpg', width: 10, height: 10 };
    await assertFails(send('alice', 'Alice', 'a3', { announcement: true, type: 'image', attachments: [photo] }));
    await assertFails(send('alice', 'Alice', 'a4', { announcement: 1 }));
  });

  it('lets a super admin on the team use @everyone and announcements (§3)', async () => {
    const root = env.authenticatedContext('bob', { superAdmin: true }).firestore();
    await assertSucceeds(send('bob', 'Bob', 's1', { mentionsEveryone: true }, root));
    await assertSucceeds(send('bob', 'Bob', 's2', { announcement: true }, root));
  });

  it("leaves a team's pins to pinMessage: not even admins write them", async () => {
    await assertFails(as('alice').doc('groups/teamA').update({ pinnedMessageIds: ['m1'] }));
    await assertFails(as('bob').doc('messages/m1').update({ pinnedAt: now() }));
  });
});

describe('reactions (CHAT-6)', () => {
  it('lets a member set and clear only their own reaction', async () => {
    const db = as('bob');
    await assertSucceeds(db.doc('messages/m1').update({ 'reactions.bob': 'love' }));
    await assertSucceeds(db.doc('messages/m1').update({ 'reactions.bob': firebase.firestore.FieldValue.delete() }));
    await assertFails(db.doc('messages/m1').update({ 'reactions.alice': 'like' }));
    await assertFails(db.doc('messages/m1').update({ text: 'edited by bob' }));
  });

  it('allows all 16 reactions on every team, and nothing else', async () => {
    for (const r of reactionValues) {
      await assertSucceeds(as('bob').doc('messages/m1').update({ 'reactions.bob': r }));
    }
    await assertSucceeds(as('dan').doc('messages/m2').update({ 'reactions.dan': 'trophy' }));
    await assertSucceeds(as('carol').doc('messages/m2').update({ 'reactions.carol': 'basketball' }));
    await assertFails(as('bob').doc('messages/m1').update({ 'reactions.bob': 'skull' }));
    await assertFails(as('bob').doc('messages/m2').update({ 'reactions.bob': 'like' }));
  });
});

describe('editing messages (CHAT-15)', () => {
  const edit = (uid: string, id: string, text = 'Edited') =>
    as(uid).doc(`messages/${id}`).update({ text, editedAt: now() });

  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.doc('messages/gone').set({
        groupId: 'teamA', authorId: 'alice', type: 'text', text: '', reactions: {},
        deletedAt: ts('2026-05-01T00:00:00Z'),
      });
      await db.doc('messages/pic').set({
        groupId: 'teamA', authorId: 'bob', type: 'image', text: 'Team pic', reactions: {},
        attachments: [{ path: 'groups/teamA/messages/pic/0.jpg' }],
      });
      // An admin removed every photo in Media (STORE-5); the caption stayed.
      await db.doc('messages/bare').set({
        groupId: 'teamA', authorId: 'bob', type: 'image', text: 'Team pic', reactions: {}, attachments: [],
      });
    });
  });

  it('lets authors edit the text of their own messages on every team', async () => {
    await assertSucceeds(edit('alice', 'm1'));
    await assertSucceeds(edit('carol', 'm2'));
    await assertSucceeds(edit('bob', 'pic', ''));
  });

  it('refuses other people, deleted messages, other fields, and backdated edits', async () => {
    await assertFails(edit('bob', 'm1'));
    await assertFails(edit('carol', 'm1'));
    await assertFails(edit('alice', 'gone'));
    await assertFails(edit('alice', 'm1', 'x'.repeat(4001)));
    await assertFails(as('alice').doc('messages/m1').update({ text: 'x', editedAt: ts('2020-01-01T00:00:00Z') }));
    await assertFails(as('alice').doc('messages/m1').update({ text: 'x', editedAt: now(), authorName: 'Boss' }));
  });

  it('never empties a message with no photos', async () => {
    await assertFails(edit('alice', 'm1', ''));
    await assertFails(edit('bob', 'bare', ''));
  });
});

describe('chat look (CHAT-18)', () => {
  const look = (uid: string, g: string, theme: object) => as(uid).doc(`groups/${g}`).update({ chatTheme: theme });
  const good = { bubbleColor: '#0F8A5F', background: 'pattern', backgroundPath: null };

  it("lets every team's admins set it", async () => {
    await assertSucceeds(look('alice', 'teamA', good));
    await assertSucceeds(look('carol', 'teamB', { bubbleColor: null, background: 'photo', backgroundPath: 'groups/teamB/theme/1.jpg' }));
  });

  it('refuses members, other teams, and bad values', async () => {
    await assertFails(look('bob', 'teamA', good));
    await assertFails(look('dan', 'teamB', good));
    await assertFails(look('alice', 'teamB', good));
    await assertFails(look('alice', 'teamA', { ...good, bubbleColor: '#FFFFFF' }));
    await assertFails(look('alice', 'teamA', { ...good, background: 'video' }));
    await assertFails(look('alice', 'teamA', { ...good, backgroundPath: 'groups/teamB/theme/1.jpg' }));
    await assertFails(look('alice', 'teamA', { ...good, extra: true }));
  });

  // The rules list the palette by hand; this keeps them in step with
  // shared/constants.json (TEAM-1).
  it('accepts every palette color as the team color and the bubble color', async () => {
    for (const color of TEAM_COLORS) {
      await assertSucceeds(look('alice', 'teamA', { ...good, bubbleColor: color }));
      await assertSucceeds(as('alice').doc('groups/teamA').update({ color }));
    }
    // And every Gumdrop candy as the bubble color (CHAT-18).
    for (const color of CHAT_CANDY_COLORS) {
      await assertSucceeds(look('alice', 'teamA', { ...good, bubbleColor: color }));
    }
    // A retired color (TEAM-5) still validates, so an old team can save
    // its other fields.
    for (const color of Object.keys(RETIRED_TEAM_COLORS)) {
      await assertSucceeds(look('alice', 'teamA', { ...good, bubbleColor: color }));
      await assertSucceeds(as('alice').doc('groups/teamA').update({ color }));
      await assertSucceeds(as('alice').doc('groups/teamA').update({ description: 'Still here' }));
    }
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

  it("lets a team admin answer for a player", async () => {
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

  it('lets every member RSVP for themselves next to the players, and admins for them (SCHED-5, Q14)', async () => {
    await assertSucceeds(rsvp(as('carol'), 'eB', 'member', 'carol', 'carol', 'going'));
    await assertSucceeds(rsvp(as('dan'), 'eB', 'member', 'dan', 'dan', 'going'));
    await assertSucceeds(rsvp(as('carol'), 'eB', 'member', 'frank', 'carol', 'going'));
    await assertFails(rsvp(as('frank'), 'eB', 'member', 'dan', 'frank', 'going'));
  });

  it("takes player answers on an old 'members' event (rsvpFor is ignored)", async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('players/ace').set({ groupId: 'teamA', displayName: 'Ace', displayNameLower: 'ace' }),
    );
    await assertSucceeds(rsvp(as('alice'), 'eA', 'player', 'ace', 'alice', 'going'));
    await assertFails(rsvp(as('bob'), 'eA', 'player', 'ace', 'bob', 'going'));
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

describe('one team type (TEAM-1)', () => {
  it('has no type to switch: admins set neither teamType nor kind', async () => {
    await assertFails(as('alice').doc('groups/teamA').update({ teamType: 'youth', updatedAt: now() }));
    await assertFails(as('alice').doc('groups/teamA').update({ kind: 'group', updatedAt: now() }));
    await assertFails(as('bob').doc('groups/teamA').update({ teamType: 'youth' }));
  });

  it("still lets admins edit an old team that says teamType, which stays as it is", async () => {
    await assertSucceeds(as('carol').doc('groups/teamB').update({ name: 'Lightning', nameLower: 'lightning', updatedAt: now() }));
    await assertFails(as('carol').doc('groups/teamB').update({ teamType: 'adult', updatedAt: now() }));
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
    // Who sees the roster's people (TEAM-3): a yes or no, from admins.
    await assertSucceeds(db.doc('groups/teamA').update({ 'settings.membersCanSeePeople': false }));
    await assertFails(db.doc('groups/teamA').update({ 'settings.membersCanSeePeople': 'admins' }));
    await assertFails(as('bob').doc('groups/teamA').update({ 'settings.membersCanSeePeople': true }));
    // The language filter (SAFE-7): a yes or no, from admins.
    await assertSucceeds(db.doc('groups/teamA').update({ 'settings.filterLanguage': false }));
    await assertFails(db.doc('groups/teamA').update({ 'settings.filterLanguage': 'strict' }));
    await assertFails(as('bob').doc('groups/teamA').update({ 'settings.filterLanguage': true }));
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

  it('lets a guardian or an admin edit name, number, position, and walk-up song', async () => {
    await assertSucceeds(as('dan').doc('players/emma').update(edit));
    await assertSucceeds(as('carol').doc('players/emma').update({ jerseyNumber: null }));
    // The walk-up song (PLAYER-2): up to 100 characters, or none.
    await assertSucceeds(as('dan').doc('players/emma').update({ walkUpSong: 'Thunderstruck, AC/DC' }));
    await assertSucceeds(as('carol').doc('players/emma').update({ walkUpSong: null }));
    await assertFails(as('dan').doc('players/emma').update({ walkUpSong: 'x'.repeat(101) }));
    await assertFails(as('dan').doc('players/emma').update({ walkUpSong: 7 }));
    await assertFails(as('frank').doc('players/emma').update({ walkUpSong: 'Jump Around' }));
  });

  it('blocks other parents and other teams', async () => {
    await assertFails(as('frank').doc('players/emma').update(edit));
    await assertFails(as('alice').doc('players/emma').update(edit));
  });

  it('never lets a player record hold more than a name, number, position, and walk-up song', async () => {
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
