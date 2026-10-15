// Security rules for the schedule (ARCH §6.3; SPEC SCHED-3 to SCHED-7,
// PLAYER-6, Q12, Q14, STORE-4, TEAM-9).
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
const zeros = { going: 0, maybe: 0, notGoing: 0 };
const START = '2030-06-01T23:00:00Z';

/**
 * A whole event as stored, for seeding. [rsvpFor] is only on events made
 * before one team type (null leaves it out, as new events are).
 */
const stored = (groupId: string, rsvpFor: string | null, extra: object = {}) => ({
  groupId,
  type: 'practice',
  title: 'Practice',
  description: '',
  location: { name: 'Riverside Park', address: '' },
  allDay: false,
  startAt: ts(START),
  endAt: ts('2030-06-02T00:30:00Z'),
  startDate: null,
  endDate: null,
  timeZone: 'America/Chicago',
  arriveMinutesBefore: null,
  opponent: null,
  homeAway: null,
  rsvpEnabled: true,
  ...(rsvpFor ? { rsvpFor } : {}),
  rsvpDeadline: null,
  reminderOffsets: [60],
  notifyTeam: true,
  postToChat: true,
  seriesId: null,
  seriesDate: null,
  seriesOverrides: [],
  rsvpCounts: zeros,
  staffCounts: zeros,
  nextReminderAt: null,
  messageId: null,
  canceledAt: null,
  canceledBy: null,
  createdBy: 'bob',
  createdAt: ts('2026-10-01T00:00:00Z'),
  updatedAt: ts('2026-10-01T00:00:00Z'),
  ...extra,
});

// teamA: alice owner, bob member who is the player jared ('self').
// teamY (an old doc still saying teamType 'youth'): carol admin, dan
// guardian of emma, frank member who proposed the pending player pend.
// teamB: gina. Events: eA (by bob, an old one with rsvpFor 'members') and
// eS (a series event) on teamA, eY on teamY (new: no rsvpFor), eGone
// (canceled) on teamA.
async function seed(settings: object = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const s = { membersCanCreateEvents: false, membersCanCreatePolls: true, membersCanUploadDocs: true, ...settings };
    for (const g of ['teamA', 'teamY', 'teamB']) {
      const kind = g === 'teamY' ? { teamType: 'youth' } : { kind: 'team' };
      await db.doc(`groups/${g}`).set({ name: g, nameLower: g, ...kind, settings: s, storageBytes: 0, storageQuotaBytes: 100 });
    }
    const member = (g: string, uid: string, role: string) =>
      db.doc(`groupMembers/${g}_${uid}`).set({ groupId: g, uid, role, displayName: uid, photoPath: null });
    await member('teamA', 'alice', 'owner');
    await member('teamA', 'bob', 'member');
    await member('teamY', 'carol', 'admin');
    await member('teamY', 'dan', 'member');
    await member('teamY', 'frank', 'member');
    await member('teamB', 'gina', 'admin');
    await db.doc('players/emma').set({ groupId: 'teamY', displayName: 'Emma', displayNameLower: 'emma' });
    await db.doc('playerGuardians/emma_dan').set({ groupId: 'teamY', playerId: 'emma', uid: 'dan' });
    await db.doc('players/jared').set({ groupId: 'teamA', displayName: 'Jared', displayNameLower: 'jared', status: 'active' });
    await db.doc('playerGuardians/jared_bob').set({ groupId: 'teamA', playerId: 'jared', uid: 'bob', relation: 'self' });
    await db.doc('players/pend').set({
      groupId: 'teamY', displayName: 'Pending', displayNameLower: 'pending', status: 'pending', proposedBy: 'frank',
    });
    await db.doc('events/eA').set(stored('teamA', 'members'));
    await db.doc('events/eS').set(stored('teamA', 'members', { seriesId: 's1', seriesDate: '2030-06-01', createdBy: 'alice' }));
    await db.doc('events/eY').set(stored('teamY', null, { createdBy: 'carol' }));
    await db.doc('events/eGone').set(stored('teamA', 'members', { canceledAt: ts('2026-10-02T00:00:00Z'), canceledBy: 'alice' }));
    await db.doc('eventSeries/s1').set({ groupId: 'teamA', timeZone: 'America/Chicago', createdBy: 'alice' });
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

const archive = (g: string) =>
  env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc(`groups/${g}`).update({ archivedAt: ts('2026-10-01T00:00:00Z') }));
const allowMembers = () =>
  env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ 'settings.membersCanCreateEvents': true }));

describe('creating events (SCHED-3, Q12)', () => {
  /** A new one-off event as the app writes it. */
  const fresh = (uid: string, groupId = 'teamA', extra: object = {}) => {
    const e: Record<string, unknown> = {
      ...stored(groupId, null),
      createdBy: uid,
      createdAt: now(),
      updatedAt: now(),
      ...extra,
    };
    for (const k of ['seriesId', 'seriesDate', 'seriesOverrides', 'nextReminderAt', 'messageId', 'canceledAt', 'canceledBy']) {
      if (!(k in extra)) delete e[k];
    }
    return e;
  };
  const create = (uid: string, groupId = 'teamA', extra: object = {}) => as(uid).doc('events/new').set(fresh(uid, groupId, extra));

  it('lets admins create events, and members only when the team allows it', async () => {
    await assertSucceeds(create('alice'));
    await assertFails(as('bob').doc('events/new2').set(fresh('bob')));
    await allowMembers();
    await assertSucceeds(as('bob').doc('events/new2').set(fresh('bob')));
  });

  it('takes game fields, all-day dates, a deadline, and up to 6 reminders', async () => {
    await assertSucceeds(
      create('alice', 'teamA', {
        type: 'game',
        title: 'vs. Eagles',
        opponent: 'Eagles',
        homeAway: 'home',
        arriveMinutesBefore: 30,
        rsvpDeadline: ts('2030-06-01T12:00:00Z'),
        reminderOffsets: [15, 60, 120, 1440, 2880, 10080],
        seriesId: null,
        nextReminderAt: null,
      }),
    );
    await assertSucceeds(
      as('alice').doc('events/allday').set(
        fresh('alice', 'teamA', {
          allDay: true,
          startDate: '2030-06-01',
          endDate: '2030-06-02',
          startAt: ts('2030-06-01T05:00:00Z'),
          endAt: ts('2030-06-03T05:00:00Z'),
          location: null,
        }),
      ),
    );
  });

  it('refuses bad fields', async () => {
    const bad: object[] = [
      { title: '' },
      { title: 'x'.repeat(101) },
      { description: 'x'.repeat(2001) },
      { type: 'party' },
      { location: { name: '', address: '' } },
      { location: { name: 'x'.repeat(101), address: '' } },
      { location: { name: 'Park', address: 'x'.repeat(201) } },
      { endAt: ts(START) },
      { allDay: true },
      { startDate: '2030-06-01' },
      { opponent: 'Eagles' },
      { type: 'game', opponent: 'x'.repeat(61) },
      { type: 'game', arriveMinutesBefore: 241 },
      { type: 'game', homeAway: 'neutral' },
      { rsvpDeadline: ts('2030-06-02T00:00:00Z') },
      { reminderOffsets: [30] },
      { reminderOffsets: [60, 60] },
      { reminderOffsets: [15, 60, 120, 1440, 2880, 10080, 15] },
      { notifyTeam: 'yes' },
      { extra: true },
      { rsvpFor: 'players' },
      { rsvpCounts: { going: 3, maybe: 0, notGoing: 0 } },
      { staffCounts: { going: 1, maybe: 0, notGoing: 0 } },
      { seriesId: 's1' },
      { seriesDate: '2030-06-01' },
      { seriesOverrides: ['title'] },
      { nextReminderAt: ts(START) },
      { messageId: 'm1' },
      { canceledAt: now(), canceledBy: 'alice' },
      { createdBy: 'bob' },
      { updatedAt: ts('2026-01-01T00:00:00Z') },
    ];
    for (const extra of bad) await assertFails(create('alice', 'teamA', extra));
  });

  it('lets super admins create events on any team (§3), not archived ones', async () => {
    const sam = env.authenticatedContext('sam', { superAdmin: true }).firestore();
    await assertSucceeds(sam.doc('events/bySam').set(fresh('sam')));
    await assertFails(sam.doc('events/bySam2').set(fresh('bob')));
    await archive('teamA');
    await assertFails(sam.doc('events/bySam3').set(fresh('sam')));
  });

  it('takes no rsvpFor on new events: one team type, per-player RSVPs everywhere (SCHED-5)', async () => {
    await assertSucceeds(create('carol', 'teamY'));
    await assertFails(as('carol').doc('events/new3').set(fresh('carol', 'teamY', { rsvpFor: 'members' })));
    await assertFails(as('alice').doc('events/new3').set(fresh('alice', 'teamA', { rsvpFor: 'players' })));
  });

  it("leaves an old event's rsvpFor alone on edits", async () => {
    await assertSucceeds(as('alice').doc('events/eA').update({ title: 'Scrimmage', updatedAt: now() }));
  });

  it('refuses another team, archived teams, and full teams (TEAM-9, STORE-4)', async () => {
    await assertFails(create('gina'));
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ storageBytes: 100 }));
    await assertFails(create('alice'));
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ storageBytes: 99 }));
    await assertSucceeds(create('alice'));
    await archive('teamA');
    await assertFails(as('alice').doc('events/new4').set(fresh('alice')));
  });
});

describe('editing, canceling, and deleting events (SCHED-6, SCHED-7)', () => {
  const edit = (uid: string, id: string, changes: object) =>
    as(uid).doc(`events/${id}`).update({ updatedAt: now(), ...changes });

  it('lets admins edit any one-off event', async () => {
    await assertSucceeds(edit('alice', 'eA', { title: 'Scrimmage', startAt: ts('2030-06-01T22:00:00Z') }));
    await assertSucceeds(edit('alice', 'eA', { location: null, description: 'Bring water' }));
  });

  it('lets the creator edit their own, even once members may no longer create events (§3)', async () => {
    await assertSucceeds(edit('bob', 'eA', { title: 'Scrimmage' }));
    await allowMembers();
    await assertSucceeds(edit('bob', 'eA', { title: 'Scrimmage 2' }));
    // Not someone else's.
    await assertFails(edit('bob', 'eS', { title: 'Scrimmage' }));
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('events/eA').update({ createdBy: 'alice' }));
    await assertFails(edit('bob', 'eA', { title: 'Scrimmage 3' }));
  });

  it('keeps computed, series, and fixed fields out of reach', async () => {
    for (const changes of [
      { rsvpCounts: { going: 9, maybe: 0, notGoing: 0 } },
      { staffCounts: { going: 9, maybe: 0, notGoing: 0 } },
      { nextReminderAt: ts(START) },
      { messageId: 'm1' },
      { seriesId: 's1' },
      { groupId: 'teamB' },
      { rsvpFor: 'players' },
      { createdBy: 'alice' },
      { notifyTeam: false },
      { postToChat: false },
      { title: '' },
    ]) {
      await assertFails(edit('alice', 'eA', changes));
    }
    await assertFails(as('alice').doc('events/eA').update({ title: 'No timestamp' }));
  });

  it('cancels once, as now, by the person canceling, and never uncancels', async () => {
    await assertFails(edit('alice', 'eA', { canceledAt: ts('2026-10-01T00:00:00Z'), canceledBy: 'alice' }));
    await assertFails(edit('alice', 'eA', { canceledAt: now(), canceledBy: 'bob' }));
    await assertSucceeds(edit('alice', 'eA', { canceledAt: now(), canceledBy: 'alice' }));
    await assertFails(edit('alice', 'eGone', { canceledAt: null, canceledBy: null }));
    await assertFails(edit('alice', 'eGone', { canceledAt: now(), canceledBy: 'alice' }));
  });

  it('leaves series events to saveEventSeries', async () => {
    await assertFails(edit('alice', 'eS', { title: 'Scrimmage' }));
    await assertFails(edit('alice', 'eS', { canceledAt: now(), canceledBy: 'alice' }));
    await assertFails(as('alice').doc('events/eS').delete());
  });

  it('lets admins delete, and the creator their own (§3 "own only")', async () => {
    await assertFails(as('frank').doc('events/eY').delete());
    await assertSucceeds(as('bob').doc('events/eA').delete());
    await assertSucceeds(as('alice').doc('events/eGone').delete());
    await assertFails(as('gina').doc('events/eY').delete());
  });

  it('lets super admins edit, cancel, and delete one-off events, as saveEventSeries does', async () => {
    const sam = env.authenticatedContext('sam', { superAdmin: true }).firestore();
    await assertSucceeds(sam.doc('events/eA').update({ title: 'Scrimmage', updatedAt: now() }));
    await assertSucceeds(sam.doc('events/eA').update({ canceledAt: now(), canceledBy: 'sam', updatedAt: now() }));
    await assertFails(sam.doc('events/eS').update({ title: 'Scrimmage', updatedAt: now() }));
    await assertSucceeds(sam.doc('events/eY').delete());
    await archive('teamA');
    await assertFails(sam.doc('events/eGone').delete());
  });

  it('makes archived teams read-only (TEAM-9)', async () => {
    await archive('teamA');
    await assertFails(edit('alice', 'eA', { title: 'Scrimmage' }));
    await assertFails(as('alice').doc('events/eA').delete());
    await assertSucceeds(as('bob').doc('events/eA').get());
  });
});

describe('reading the schedule', () => {
  it('shows events and series to members only', async () => {
    await assertSucceeds(as('bob').doc('events/eA').get());
    await assertSucceeds(as('bob').collection('events').where('groupId', '==', 'teamA').orderBy('startAt').limit(50).get());
    await assertFails(as('bob').collection('events').where('groupId', '==', 'teamA').get());
    await assertFails(as('gina').doc('events/eA').get());
    await assertSucceeds(as('bob').doc('eventSeries/s1').get());
    await assertFails(as('gina').doc('eventSeries/s1').get());
  });

  it('never lets clients write series', async () => {
    await assertFails(as('alice').doc('eventSeries/s1').update({ timeZone: 'Europe/London' }));
    await assertFails(as('alice').doc('eventSeries/s2').set({ groupId: 'teamA', createdBy: 'alice' }));
    await assertFails(as('alice').doc('eventSeries/s1').delete());
  });
});

describe('RSVPs (SCHED-5, PLAYER-6, Q14)', () => {
  const answer = (uid: string, eventId: string, participantType: string, participantId: string, extra: object = {}) =>
    as(uid)
      .doc(`rsvps/${eventId}_${participantId}`)
      .set({
        eventId,
        groupId: eventId === 'eY' ? 'teamY' : 'teamA',
        participantType,
        participantId,
        participantName: participantId,
        eventStartAt: ts(START),
        status: 'going',
        note: '',
        guests: 0,
        respondedBy: uid,
        updatedAt: now(),
        ...extra,
      });

  it('takes a note up to 200 characters', async () => {
    await assertSucceeds(answer('bob', 'eA', 'member', 'bob', { note: 'x'.repeat(200) }));
    await assertFails(answer('bob', 'eA', 'member', 'bob', { note: 'x'.repeat(201) }));
    await assertFails(answer('bob', 'eA', 'member', 'bob', { note: 5 }));
  });

  it('takes no guests yet (SCHED-12 is v1.1), and works without the field', async () => {
    await assertFails(answer('bob', 'eA', 'member', 'bob', { guests: 2 }));
    const db = as('bob');
    await assertSucceeds(
      db.doc('rsvps/eA_bob').set({
        eventId: 'eA', groupId: 'teamA', participantType: 'member', participantId: 'bob', participantName: 'Bob',
        eventStartAt: ts(START), status: 'maybe', respondedBy: 'bob', updatedAt: now(),
      }),
    );
  });

  it('lets adults answer for themselves and admins for anyone', async () => {
    await assertSucceeds(answer('bob', 'eA', 'member', 'bob'));
    await assertSucceeds(answer('alice', 'eA', 'member', 'bob', { status: 'not_going' }));
    await assertFails(answer('bob', 'eA', 'member', 'alice'));
  });

  it('players on every team: their guardians and admins answer, other members don\'t', async () => {
    await assertSucceeds(answer('dan', 'eY', 'player', 'emma'));
    await assertSucceeds(answer('carol', 'eY', 'player', 'emma', { status: 'maybe' }));
    await assertSucceeds(answer('carol', 'eY', 'member', 'carol'));
    await assertFails(answer('frank', 'eY', 'player', 'emma'));
  });

  it('lets any member answer for themselves, linked or not (SCHED-5)', async () => {
    await assertSucceeds(answer('dan', 'eY', 'member', 'dan'));
    await assertSucceeds(answer('frank', 'eY', 'member', 'frank'));
    await assertFails(answer('frank', 'eY', 'member', 'dan'));
  });

  it("lets a member who is the player answer on the player's row, on an old 'members' event too", async () => {
    await assertSucceeds(answer('bob', 'eA', 'player', 'jared'));
    await assertSucceeds(answer('alice', 'eA', 'player', 'jared', { status: 'not_going' }));
    // A player of another team can't be answered for here.
    await assertFails(answer('alice', 'eA', 'player', 'emma'));
  });

  it('takes no answers for a pending player, even from admins or its proposer (PLAYER-4)', async () => {
    await assertFails(answer('carol', 'eY', 'player', 'pend'));
    await assertFails(answer('frank', 'eY', 'player', 'pend'));
    const sam = env.authenticatedContext('sam', { superAdmin: true }).firestore();
    await assertFails(
      sam.doc('rsvps/eY_pend').set({
        eventId: 'eY', groupId: 'teamY', participantType: 'player', participantId: 'pend', participantName: 'P',
        eventStartAt: ts(START), status: 'going', note: '', guests: 0, respondedBy: 'sam', updatedAt: now(),
      }),
    );
  });

  it('refuses an unknown participant type', async () => {
    await assertFails(answer('bob', 'eA', 'guest', 'bob'));
  });

  it('closes after the deadline except for admins, and on canceled events', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('events/eA').update({ rsvpDeadline: ts('2026-01-01T00:00:00Z') }),
    );
    await assertFails(answer('bob', 'eA', 'member', 'bob'));
    await assertSucceeds(answer('alice', 'eA', 'member', 'bob'));
    await assertFails(answer('alice', 'eGone', 'member', 'alice'));
  });

  it('refuses answers on archived teams and a stale event time', async () => {
    await assertFails(answer('bob', 'eA', 'member', 'bob', { eventStartAt: ts('2030-06-02T23:00:00Z') }));
    await archive('teamA');
    await assertFails(answer('bob', 'eA', 'member', 'bob'));
  });

  it('takes a participant name up to 60 characters', async () => {
    await assertSucceeds(answer('bob', 'eA', 'member', 'bob', { participantName: 'x'.repeat(60) }));
    await assertFails(answer('bob', 'eA', 'member', 'bob', { participantName: 'x'.repeat(61) }));
    await assertFails(answer('bob', 'eA', 'member', 'bob', { participantName: 7 }));
  });

  it('lets an answer change after the event moved, with the new time only', async () => {
    await assertSucceeds(answer('bob', 'eA', 'member', 'bob'));
    const moved = ts('2030-06-02T00:00:00Z');
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('events/eA').update({ startAt: moved, endAt: ts('2030-06-02T01:30:00Z') }),
    );
    await assertFails(answer('bob', 'eA', 'member', 'bob', { status: 'not_going' }));
    await assertSucceeds(answer('bob', 'eA', 'member', 'bob', { status: 'not_going', eventStartAt: moved }));
  });

  it('keeps working when storage is full (STORE-4)', async () => {
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ storageBytes: 100 }));
    await assertSucceeds(answer('bob', 'eA', 'member', 'bob'));
  });

  it('lets super admins answer for any member or player, never for themselves (§3)', async () => {
    const sam = env.authenticatedContext('sam', { superAdmin: true }).firestore();
    const by = (eventId: string, type: string, id: string, extra: object = {}) =>
      sam.doc(`rsvps/${eventId}_${id}`).set({
        eventId, groupId: eventId === 'eY' ? 'teamY' : 'teamA', participantType: type, participantId: id,
        participantName: id, eventStartAt: ts(START), status: 'going', note: '', guests: 0, respondedBy: 'sam',
        updatedAt: now(), ...extra,
      });
    await assertSucceeds(by('eA', 'member', 'bob'));
    await assertSucceeds(by('eY', 'player', 'emma'));
    await assertFails(by('eA', 'member', 'sam'));
    await assertFails(by('eA', 'member', 'gina'));
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('events/eA').update({ rsvpDeadline: ts('2026-01-01T00:00:00Z') }),
    );
    await assertSucceeds(by('eA', 'member', 'bob', { status: 'not_going' }));
  });

  it('takes no new Maybe when the team turned Maybe off (TEAM-5, SCHED-5)', async () => {
    await assertSucceeds(answer('bob', 'eA', 'member', 'bob', { status: 'maybe' }));
    await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update({ 'settings.allowMaybe': false }));
    // One given before stays while the note changes; new ones are refused.
    await assertSucceeds(answer('bob', 'eA', 'member', 'bob', { status: 'maybe', note: 'Late' }));
    await assertFails(answer('alice', 'eA', 'member', 'alice', { status: 'maybe' }));
    await assertSucceeds(answer('alice', 'eA', 'member', 'alice', { status: 'going' }));
    await assertSucceeds(answer('bob', 'eA', 'member', 'bob', { status: 'not_going' }));
    await assertFails(answer('bob', 'eA', 'member', 'bob', { status: 'maybe' }));
  });

  it('lets whoever may give an answer clear it, and nobody else (SCHED-5)', async () => {
    await assertSucceeds(answer('bob', 'eA', 'member', 'bob'));
    await assertSucceeds(answer('dan', 'eY', 'player', 'emma'));
    // Not from another team, nor a player you don't answer for.
    await assertFails(as('gina').doc('rsvps/eA_bob').delete());
    await assertFails(as('frank').doc('rsvps/eY_emma').delete());
    await assertSucceeds(as('bob').doc('rsvps/eA_bob').delete());
    await assertSucceeds(as('dan').doc('rsvps/eY_emma').delete());
    // Admins clear anyone's.
    await assertSucceeds(answer('dan', 'eY', 'player', 'emma'));
    await assertSucceeds(as('carol').doc('rsvps/eY_emma').delete());
  });

  it('keeps answers after the deadline except for admins, and on canceled events', async () => {
    await assertSucceeds(answer('bob', 'eA', 'member', 'bob'));
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc('events/eA').update({ rsvpDeadline: ts('2026-01-01T00:00:00Z') });
      await ctx.firestore().doc('rsvps/eGone_alice').set({
        eventId: 'eGone', groupId: 'teamA', participantType: 'member', participantId: 'alice',
        participantName: 'alice', eventStartAt: ts(START), status: 'going', note: '', guests: 0,
        respondedBy: 'alice', updatedAt: ts('2026-10-01T00:00:00Z'),
      });
    });
    await assertFails(as('bob').doc('rsvps/eA_bob').delete());
    await assertFails(as('alice').doc('rsvps/eGone_alice').delete());
    await assertSucceeds(as('alice').doc('rsvps/eA_bob').delete());
  });
});
