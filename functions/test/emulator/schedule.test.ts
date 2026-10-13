// The schedule on the server (SPEC SCHED-3, SCHED-5 to SCHED-8, PLAYER-6,
// PLAYER-7, STORE-4, TEAM-9): saveEventSeries, the events and rsvps
// triggers' work, and reminders through the tick. Runs against the
// Firestore emulator with FCM faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { eraseMessage, notifyNewMessage } from '../../src/chat/service.js';
import { tick } from '../../src/ops/jobs.js';
import { saveEventSeries } from '../../src/schedule/handlers.js';
import { removePlayer } from '../../src/players/service.js';
import { dateInZone, wallTimeToMs } from '../../src/schedule/recurrence.js';
import { SaveSeriesInput, saveSeries } from '../../src/schedule/series.js';
import { eventView, followUpEventWrite, recountEventRsvps, settleNextReminder } from '../../src/schedule/service.js';
import { db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';

vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({ sendEach: async () => ({ responses: [], successCount: 0, failureCount: 0 }) }),
}));

const G = 'teamA';
const Y = 'teamY';
const CHI = 'America/Chicago';
const DAY = 86_400_000;
type CallRequest = Parameters<typeof saveEventSeries.run>[0];
const call = (uid: string, data: object, token: object = {}) =>
  ({ data, auth: { uid, token }, rawRequest: {} }) as unknown as CallRequest;
const save = (uid: string, data: object, token: object = {}) => saveEventSeries.run(call(uid, data, token));

/** The date in Chicago [days] from now. */
const day = (days: number) => dateInZone(Date.now() + days * DAY, CHI);

const template = (extra: object = {}) => ({
  type: 'practice',
  title: 'Practice',
  description: '',
  location: { name: 'Riverside Park', address: '' },
  allDay: false,
  startTime: '18:00',
  endTime: '19:30',
  timeZone: CHI,
  rsvpEnabled: true,
  reminderOffsets: [60],
  notifyTeam: true,
  postToChat: true,
  ...extra,
});
/** Every day for [days] days from [from] days out. */
const daily = (from: number, days: number) => ({
  freq: 'daily',
  interval: 1,
  byWeekday: [],
  startDate: day(from),
  untilDate: day(from + days - 1),
  count: null,
  skipDates: [],
});

async function person(g: string, uid: string, role = 'member'): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(g, uid)).set({
    groupId: g, uid, role, displayName: uid[0].toUpperCase() + uid.slice(1), photoPath: null, notificationLevel: 'all',
  });
  await db().collection(Collections.users).doc(uid).set({ displayName: uid, status: 'active', notificationPrefs: {} });
}

async function team(g: string, extra: object = {}): Promise<void> {
  await db().collection(Collections.groups).doc(g).set({
    name: g === G ? 'Thunder' : 'Tigers',
    kind: 'team',
    timeZone: CHI,
    settings: { membersCanCreateEvents: false, defaultReminderOffsets: [1440] },
    storageBytes: 0,
    storageQuotaBytes: 1_000_000,
    ...extra,
  });
}

const eventsOf = async (seriesId: string) =>
  (await db().collection(Collections.events).where('seriesId', '==', seriesId).orderBy('startAt').get()).docs;
const eventData = async (id: string) => (await db().collection(Collections.events).doc(id).get()).data();
const ms = (v: unknown) => (v as Timestamp).toMillis();

async function rsvp(eventId: string, participantId: string, status: string, participantType = 'member', g = G): Promise<void> {
  await db().collection(Collections.rsvps).doc(`${eventId}_${participantId}`).set({
    eventId, groupId: g, participantType, participantId, participantName: participantId, status, note: '', respondedBy: participantId,
    eventStartAt: (await eventData(eventId))?.startAt ?? Timestamp.now(),
  });
}

/** Who has a center item for [key], sorted. */
async function centerFor(key: string): Promise<string[]> {
  const snap = await db().collection(Collections.notifications).get();
  return snap.docs.filter((d) => d.id === `${key}_${d.get('uid')}`).map((d) => d.get('uid') as string).sort();
}
/** The notification sends logged for [kind]. */
async function sends(kind: string): Promise<string[]> {
  const snap = await db().collection(Collections.notifyLog).where('kind', '==', kind).get();
  return snap.docs.map((d) => d.id);
}
async function body(key: string, uid: string): Promise<string> {
  return String((await db().collection(Collections.notifications).doc(`${key}_${uid}`).get()).get('body'));
}
async function eventCards(): Promise<FirebaseFirestore.QueryDocumentSnapshot[]> {
  return (await db().collection(Collections.messages).where('type', '==', 'event').get()).docs;
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
  await team(G);
  await person(G, 'alex', 'owner');
  await person(G, 'pat');
  await person(G, 'sam');
  await person(G, 'lee');
  // Y is an old team doc that still says teamType 'youth'; nothing reads it.
  await team(Y, { teamType: 'youth' });
  await person(Y, 'coach', 'admin');
  await person(Y, 'maria');
  await person(Y, 'dan');
  await person(Y, 'aunt');
  for (const [id, name] of [['emma', 'Emma Ruiz'], ['liam', 'Liam Ruiz'], ['ava', 'Ava Lee']]) {
    await db().collection(Collections.players).doc(id).set({ groupId: Y, displayName: name });
  }
  for (const [playerId, uid] of [['emma', 'maria'], ['liam', 'maria'], ['ava', 'dan']]) {
    await db().collection(Collections.playerGuardians).doc(`${playerId}_${uid}`).set({ groupId: Y, playerId, uid });
  }
});

describe('creating a series (SCHED-3)', () => {
  it('counts without writing on a dry run', async () => {
    const res = await save('alex', { action: 'create', groupId: G, recurrence: daily(3, 5), template: template(), dryRun: true });
    expect(res).toEqual({ seriesId: '', created: 5, updated: 0, removed: 0, removedRsvps: 0, canceled: 0 });
    expect((await db().collection(Collections.events).get()).size).toBe(0);
    expect((await db().collection(Collections.eventSeries).get()).size).toBe(0);
    expect(await eventCards()).toHaveLength(0);
  });

  it('writes the series and its events, with one card and one notification', async () => {
    const res = await save('alex', { action: 'create', groupId: G, recurrence: daily(3, 5), template: template() });
    expect(res.created).toBe(5);
    const series = await db().collection(Collections.eventSeries).doc(res.seriesId).get();
    expect(series.data()).toMatchObject({ groupId: G, createdBy: 'alex', timeZone: CHI, template: { title: 'Practice' } });
    const events = await eventsOf(res.seriesId);
    expect(events.map((e) => e.get('seriesDate'))).toEqual([day(3), day(4), day(5), day(6), day(7)]);
    for (const e of events) {
      expect(e.data()).toMatchObject({
        groupId: G, seriesOverrides: [], messageId: res.seriesId, canceledAt: null,
        rsvpCounts: { going: 0, maybe: 0, notGoing: 0 }, staffCounts: { going: 0, maybe: 0, notGoing: 0 },
      });
      expect(e.get('rsvpFor')).toBeUndefined();
      // 6 PM in Chicago, and the 1-hour reminder before it.
      expect(dateInZone(ms(e.get('startAt')), CHI)).toBe(e.get('seriesDate'));
      expect(ms(e.get('nextReminderAt'))).toBe(ms(e.get('startAt')) - 3_600_000);
    }
    const cards = await eventCards();
    expect(cards).toHaveLength(1);
    expect(cards[0].id).toBe(res.seriesId);
    expect(cards[0].data()).toMatchObject({ authorId: 'alex', authorName: 'Alex', seriesId: res.seriesId, eventId: events[0].id });
    expect(await sends('eventCreated')).toEqual([`${res.seriesId}_created`]);
    expect(await centerFor(`${res.seriesId}_created`)).toEqual(['lee', 'pat', 'sam']);
    expect(await body(`${res.seriesId}_created`, 'sam')).toMatch(/^New: Practice, daily at 6:00 PM, \w{3} \d+ – \w{3} \d+$/);
  });

  it('skips the card and the notification when asked', async () => {
    const res = await save('alex', {
      action: 'create', groupId: G, recurrence: daily(3, 2), template: template({ notifyTeam: false, postToChat: false }),
    });
    expect(await eventCards()).toHaveLength(0);
    expect(await sends('eventCreated')).toEqual([]);
    expect((await eventsOf(res.seriesId))[0].get('messageId')).toBeNull();
  });

  it('needs an admin unless members may create events (Q12)', async () => {
    const data = { action: 'create', groupId: G, recurrence: daily(3, 2), template: template() };
    await expect(save('pat', data)).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(save('stranger', data)).rejects.toMatchObject({ code: 'permission-denied' });
    await db().collection(Collections.groups).doc(G).update({ 'settings.membersCanCreateEvents': true });
    expect((await save('pat', data)).created).toBe(2);
    expect((await save('stranger', data, { superAdmin: true })).created).toBe(2);
  });

  it('refuses full teams, archived teams, and rules with no dates (STORE-4, TEAM-9)', async () => {
    const data = { action: 'create', groupId: G, recurrence: daily(3, 2), template: template() };
    await db().collection(Collections.groups).doc(G).update({ storageBytes: 1_000_000 });
    await expect(save('alex', data)).rejects.toMatchObject({ code: 'failed-precondition', message: 'storage-full' });
    await expect(save('alex', { ...data, dryRun: true })).rejects.toMatchObject({ message: 'storage-full' });
    await db().collection(Collections.groups).doc(G).update({ storageBytes: 0, archivedAt: Timestamp.now() });
    await expect(save('alex', data)).rejects.toMatchObject({ code: 'failed-precondition', message: 'team-archived' });
    await db().collection(Collections.groups).doc(G).update({ archivedAt: null });
    const allSkipped = { ...daily(3, 1), skipDates: [day(3)] };
    await expect(save('alex', { ...data, recurrence: allSkipped })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(save('alex', { ...data, template: { title: '' } })).rejects.toMatchObject({ code: 'invalid-argument' });
    expect((await db().collection(Collections.events).get()).size).toBe(0);
  });

  it('writes no rsvpFor on any team, an old youth one included: one team type (SCHED-5)', async () => {
    const res = await save('coach', { action: 'create', groupId: Y, recurrence: daily(3, 1), template: template() });
    expect((await eventsOf(res.seriesId))[0].data()).not.toHaveProperty('rsvpFor');
  });
});

/**
 * A daily series from 3 days ago to 7 days ahead, skipping today so the
 * clock can't move an event between past and upcoming: 3 past (days -3 to
 * -1) and 7 upcoming (days 1 to 7).
 */
async function runningSeries(createdBy = 'alex'): Promise<{ seriesId: string; past: string[]; upcoming: string[] }> {
  if (createdBy !== 'alex') await db().collection(Collections.groups).doc(G).update({ 'settings.membersCanCreateEvents': true });
  const res = await save(createdBy, { action: 'create', groupId: G, recurrence: { ...daily(-3, 11), skipDates: [day(0)] }, template: template() });
  if (createdBy !== 'alex') await db().collection(Collections.groups).doc(G).update({ 'settings.membersCanCreateEvents': false });
  const events = await eventsOf(res.seriesId);
  const now = Date.now();
  return {
    seriesId: res.seriesId,
    past: events.filter((e) => ms(e.get('startAt')) < now).map((e) => e.id),
    upcoming: events.filter((e) => ms(e.get('startAt')) >= now).map((e) => e.id),
  };
}

describe('"This event" (SCHED-6)', () => {
  it('changes only that event and records what it changed', async () => {
    const { seriesId, upcoming } = await runningSeries();
    const [target, other] = upcoming.slice(-2);
    await rsvp(target, 'pat', 'not_going');
    const res = await save('alex', { action: 'update', eventId: target, scope: 'this', template: template({ startTime: '18:30', endTime: '20:00', title: 'Scrimmage' }) });
    expect(res).toMatchObject({ seriesId, updated: 1, created: 0, removed: 0 });
    const changed = await eventData(target);
    expect(changed?.title).toBe('Scrimmage');
    expect(changed?.seriesOverrides).toEqual(['startAt', 'title']);
    expect((await eventData(other))?.title).toBe('Practice');
    // RSVPs follow the new time, and everyone but Not going hears it.
    const answer = await db().collection(Collections.rsvps).doc(`${target}_pat`).get();
    expect(ms(answer.get('eventStartAt'))).toBe(ms(changed?.startAt));
    const changes = await sends('eventChanged');
    expect(changes).toHaveLength(1);
    expect(await centerFor(changes[0])).toEqual(['lee', 'sam']);
    expect(await body(changes[0], 'sam')).toMatch(/^Scrimmage moved to \w{3}, \w{3} \d+ at 6:30 PM$/);
  });

  it('moves an event to another date, keeping its place in the series', async () => {
    const { upcoming } = await runningSeries();
    const target = upcoming[upcoming.length - 1];
    const before = await eventData(target);
    await save('alex', { action: 'update', eventId: target, scope: 'this', template: { ...template(), date: day(20) } });
    const after = await eventData(target);
    expect(after?.seriesDate).toBe(before?.seriesDate);
    expect(dateInZone(ms(after?.startAt), CHI)).toBe(day(20));
  });

  it('refuses members, and one-off events', async () => {
    const { upcoming, seriesId } = await runningSeries();
    await expect(save('pat', { action: 'update', eventId: upcoming[0], scope: 'this', template: template() })).rejects.toMatchObject({
      code: 'permission-denied',
    });
    await db().collection(Collections.events).doc('solo').set({ groupId: G, seriesId: null });
    await expect(save('alex', { action: 'update', eventId: 'solo', scope: 'this', template: template() })).rejects.toMatchObject({
      code: 'failed-precondition',
    });
    expect(seriesId).toBeTruthy();
  });

  it("lets the series' creator change it, even once members may no longer create events (§3 own only)", async () => {
    const { upcoming } = await runningSeries('pat');
    const edit = { action: 'update', eventId: upcoming[0], scope: 'this', template: template({ title: 'Mine' }) };
    expect((await save('pat', edit)).updated).toBe(1);
    await db().collection(Collections.groups).doc(G).update({ 'settings.membersCanCreateEvents': true });
    expect((await save('pat', { ...edit, template: template({ title: 'Mine again' }) })).updated).toBe(1);
  });
});

describe('"This and following" (SCHED-6)', () => {
  it('keeps events on dates the new rule still makes, with their RSVPs, and never touches the past', async () => {
    const { seriesId, past, upcoming } = await runningSeries();
    const from = upcoming[1];
    const fromDate = (await eventData(from))?.seriesDate as string;
    // Every other day from `from`: upcoming[1], [3], [5] stay; [2], [4], [6] go.
    const recurrence = { freq: 'daily', interval: 2, byWeekday: [], startDate: fromDate, untilDate: day(10), count: null, skipDates: [] };
    await rsvp(upcoming[2], 'sam', 'going');
    await rsvp(upcoming[4], 'lee', 'maybe');
    await rsvp(upcoming[4], 'sam', 'going');
    await rsvp(upcoming[3], 'pat', 'going');
    await rsvp(past[0], 'pat', 'going');
    const pastBefore = await eventData(past[0]);
    const edit = { action: 'update', eventId: from, scope: 'following', template: template({ title: 'Team practice' }), recurrence };

    const dry = await save('alex', { ...edit, dryRun: true });
    // Days 2, 4, 6 stay; 3, 5, 7 go; 8 and 10 are new.
    expect(dry).toMatchObject({ updated: 3, removed: 3, removedRsvps: 3, created: 2 });
    expect((await eventData(upcoming[2]))?.title).toBe('Practice');

    const res = await save('alex', edit);
    expect(res).toEqual({ ...dry, seriesId: res.seriesId });
    expect(res.seriesId).not.toBe(seriesId);
    for (const id of [upcoming[1], upcoming[3], upcoming[5]]) {
      expect(await eventData(id)).toMatchObject({ title: 'Team practice', seriesId: res.seriesId });
    }
    for (const id of [upcoming[2], upcoming[4], upcoming[6]]) expect(await eventData(id)).toBeUndefined();
    expect((await db().collection(Collections.rsvps).doc(`${upcoming[3]}_pat`).get()).exists).toBe(true);
    expect((await db().collection(Collections.rsvps).doc(`${upcoming[4]}_sam`).get()).exists).toBe(false);
    expect((await db().collection(Collections.rsvps).doc(`${upcoming[2]}_sam`).get()).exists).toBe(false);
    // Past events: same doc, same series, same RSVP.
    expect(await eventData(past[0])).toEqual(pastBefore);
    expect((await db().collection(Collections.rsvps).doc(`${past[0]}_pat`).get()).exists).toBe(true);
    // The old series ends the day before; the new one starts on the date.
    const old = await db().collection(Collections.eventSeries).doc(seriesId).get();
    expect(old.get('recurrence')).toMatchObject({ untilDate: dateBefore(fromDate), count: null });
    const fresh = await db().collection(Collections.eventSeries).doc(res.seriesId).get();
    expect(fresh.get('recurrence')).toMatchObject({ startDate: fromDate, interval: 2 });
    expect(fromDate).toBe(day(2));
    expect((await eventsOf(res.seriesId)).map((e) => e.get('seriesDate'))).toEqual([day(2), day(4), day(6), day(8), day(10)]);
    // One notification for all of it, and no new card.
    expect(await sends('eventChanged')).toHaveLength(1);
    expect(await eventCards()).toHaveLength(1);
  });

  it('keeps a "This event" change through a later series edit', async () => {
    const { upcoming } = await runningSeries();
    const moved = upcoming[3];
    await save('alex', { action: 'update', eventId: moved, scope: 'this', template: template({ startTime: '07:00', endTime: '08:00' }) });
    const time = ms((await eventData(moved))?.startAt);
    await save('alex', { action: 'update', eventId: upcoming[1], scope: 'following', template: template({ title: 'Late practice', startTime: '19:00', endTime: '20:30' }) });
    const after = await eventData(moved);
    expect(after?.title).toBe('Late practice');
    expect(ms(after?.startAt)).toBe(time);
    const plain = await eventData(upcoming[2]);
    expect(new Intl.DateTimeFormat('en-US', { timeZone: CHI, hour: 'numeric' }).format(ms(plain?.startAt))).toBe('7 PM');
  });

  it('updates the series in place when editing from its first event', async () => {
    const res = await save('alex', { action: 'create', groupId: G, recurrence: daily(3, 4), template: template() });
    const [first] = await eventsOf(res.seriesId);
    const out = await save('alex', { action: 'update', eventId: first.id, scope: 'following', template: template({ title: 'Camp' }) });
    expect(out).toMatchObject({ seriesId: res.seriesId, updated: 4, created: 0, removed: 0 });
    expect((await db().collection(Collections.eventSeries).get()).size).toBe(1);
  });
});

describe('"This and following" on a series that ends after N events (SCHED-6)', () => {
  /** Every day from 3 days out, ending after [count] events, as the app sends it. */
  const counted = (count: number, startDate = day(3), extra: object = {}) => ({
    freq: 'daily', interval: 1, byWeekday: [], startDate, untilDate: null, count, skipDates: [], ...extra,
  });
  const teamEvents = async () => (await db().collection(Collections.events).where('groupId', '==', G).get()).size;

  it('keeps 10 events when the app sends the total count from the 5th', async () => {
    const res = await save('alex', { action: 'create', groupId: G, recurrence: counted(10), template: template() });
    const events = await eventsOf(res.seriesId);
    expect(events).toHaveLength(10);
    const fifth = events[4];
    // The form loads the series' rule (count 10) and sends it from this event's date.
    const edit = {
      action: 'update', eventId: fifth.id, scope: 'following', template: template({ title: 'Team practice' }),
      recurrence: counted(10, fifth.get('seriesDate')),
    };
    const dry = await save('alex', { ...edit, dryRun: true });
    expect(dry).toMatchObject({ created: 0, updated: 6, removed: 0 });
    const out = await save('alex', edit);
    expect(out).toMatchObject({ created: 0, updated: 6, removed: 0 });
    expect(await teamEvents()).toBe(10);
    const fresh = await db().collection(Collections.eventSeries).doc(out.seriesId).get();
    expect(fresh.get('recurrence')).toMatchObject({ startDate: day(7), count: 6 });
    // A title-only change tells no one.
    expect(await sends('eventChanged')).toEqual([]);
  });

  it('applies what is left of the count to a new rule', async () => {
    const res = await save('alex', { action: 'create', groupId: G, recurrence: counted(10), template: template() });
    const fifth = (await eventsOf(res.seriesId))[4];
    // Every other day from day 7, 6 left: 7, 9, 11 stay; 8, 10, 12 go; 13, 15, 17 are new.
    const out = await save('alex', {
      action: 'update', eventId: fifth.id, scope: 'following', template: template(),
      recurrence: counted(10, day(7), { interval: 2 }),
    });
    expect(out).toMatchObject({ updated: 3, removed: 3, created: 3 });
    expect((await eventsOf(out.seriesId)).map((e) => e.get('seriesDate'))).toEqual([day(7), day(9), day(11), day(13), day(15), day(17)]);
    expect(await teamEvents()).toBe(10);
  });

  it('lowers the count when one event is deleted, so nothing grows back at the end', async () => {
    const res = await save('alex', { action: 'create', groupId: G, recurrence: counted(5), template: template() });
    const events = await eventsOf(res.seriesId);
    await save('alex', { action: 'delete', eventId: events[1].id, scope: 'this' });
    const series = await db().collection(Collections.eventSeries).doc(res.seriesId).get();
    expect(series.get('recurrence')).toMatchObject({ count: 4, skipDates: [day(4)] });
    // The app then sends the stored rule from the first event.
    const out = await save('alex', {
      action: 'update', eventId: events[0].id, scope: 'following', template: template({ title: 'Camp' }),
      recurrence: counted(4, day(3), { skipDates: [day(4)] }),
    });
    expect(out).toMatchObject({ created: 0, updated: 4, removed: 0 });
    expect(await teamEvents()).toBe(4);

    // Deleting the only event of a 1-event series ends it on that date.
    const one = await save('alex', { action: 'create', groupId: G, recurrence: counted(1), template: template() });
    await save('alex', { action: 'delete', eventId: (await eventsOf(one.seriesId))[0].id, scope: 'this' });
    const ended = await db().collection(Collections.eventSeries).doc(one.seriesId).get();
    expect(ended.get('recurrence')).toMatchObject({ count: null, untilDate: day(3), skipDates: [day(3)] });
  });
});

describe('series edits at a fixed time', () => {
  const at = (date: string, time: string) => wallTimeToMs(date, time, CHI);
  const run = (data: object, nowMs: number) => saveSeries(SaveSeriesInput.parse(data), { uid: 'alex', superAdmin: false }, nowMs);
  const june = { freq: 'daily', interval: 1, byWeekday: [], startDate: '2030-06-01', untilDate: '2030-06-07', count: null, skipDates: [] };

  it("doesn't add a second event on a date whose event already started", async () => {
    const res = await run({ action: 'create', groupId: G, recurrence: june, template: template({ startTime: '09:00', endTime: '10:00' }) }, Date.now());
    const third = (await eventsOf(res.seriesId))[2];
    // 10 AM on Jun 3: that day's 9 AM practice is past; move the rest to 6 PM.
    const out = await run(
      { action: 'update', eventId: third.id, scope: 'following', template: template(), recurrence: { ...june, startDate: '2030-06-03' } },
      at('2030-06-03', '10:00'),
    );
    expect(out).toMatchObject({ created: 0, updated: 4, removed: 0 });
    const all = (await db().collection(Collections.events).where('groupId', '==', G).get()).docs;
    expect(all).toHaveLength(7);
    expect(all.filter((e) => e.get('seriesDate') === '2030-06-03')).toHaveLength(1);
    expect(ms((await eventData(third.id))?.startAt)).toBe(at('2030-06-03', '09:00'));
  });

  it('keeps a reminder that fell due just before the edit', async () => {
    const res = await run({ action: 'create', groupId: G, recurrence: june, template: template() }, Date.now());
    const fifth = (await eventsOf(res.seriesId))[4];
    // The 1-hour reminder is due at 5:00 PM; the edit lands at 5:02, before the tick.
    await run({ action: 'update', eventId: fifth.id, scope: 'this', template: template({ title: 'Scrimmage' }) }, at('2030-06-05', '17:02'));
    expect(ms((await eventData(fifth.id))?.nextReminderAt)).toBe(at('2030-06-05', '17:00'));
    const sixth = (await eventsOf(res.seriesId))[5];
    await run({ action: 'update', eventId: sixth.id, scope: 'following', template: template({ title: 'Late' }) }, at('2030-06-06', '17:02'));
    expect(ms((await eventData(sixth.id))?.nextReminderAt)).toBe(at('2030-06-06', '17:00'));
  });
});

describe('the series card (CHAT-11)', () => {
  it('carries seriesId, and follows the new series when its event moves there', async () => {
    const { seriesId, upcoming } = await runningSeries();
    const card = await db().collection(Collections.messages).doc(seriesId).get();
    expect(card.data()).toMatchObject({ type: 'event', seriesId, eventId: upcoming[0] });
    const out = await save('alex', { action: 'update', eventId: upcoming[0], scope: 'following', template: template({ title: 'Camp' }) });
    expect(out.seriesId).not.toBe(seriesId);
    expect((await db().collection(Collections.messages).doc(seriesId).get()).get('seriesId')).toBe(out.seriesId);
  });
});

function dateBefore(date: string): string {
  const d = new Date(`${date}T00:00:00Z`);
  return new Date(d.getTime() - DAY).toISOString().slice(0, 10);
}

describe('a suspended team (§3)', () => {
  it('refuses its owner but lets a super admin change a series, as the rules do for one event', async () => {
    const { upcoming } = await runningSeries();
    await db().collection(Collections.groups).doc(G).update({ suspendedAt: Timestamp.now() });
    await expect(save('alex', { action: 'cancel', eventId: upcoming[0], scope: 'this' })).rejects
      .toMatchObject({ code: 'failed-precondition', message: 'team-suspended' });
    expect((await eventData(upcoming[0]))?.canceledAt).toBeNull();
    const out = await save('root', { action: 'cancel', eventId: upcoming[0], scope: 'this' }, { superAdmin: true });
    expect(out.canceled).toBe(1);
    expect((await eventData(upcoming[0]))?.canceledAt).toBeInstanceOf(Timestamp);
  });
});

describe('canceling and deleting in a series (SCHED-7)', () => {
  it('cancels one event, telling everyone but Not going, guardians included', async () => {
    const res = await save('coach', { action: 'create', groupId: Y, recurrence: daily(3, 3), template: template() });
    const [first, second] = await eventsOf(res.seriesId);
    await rsvp(first.id, 'ava', 'not_going', 'player', Y);
    const out = await save('coach', { action: 'cancel', eventId: first.id, scope: 'this' });
    expect(out.canceled).toBe(1);
    expect(await eventData(first.id)).toMatchObject({ canceledBy: 'coach', nextReminderAt: null });
    expect((await eventData(second.id))?.canceledAt).toBeNull();
    // Dan's only player said Not going; Maria hears for both of hers.
    expect(await centerFor(`${first.id}_canceled`)).toEqual(['aunt', 'maria']);
    expect(await body(`${first.id}_canceled`, 'maria')).toMatch(/^Emma, Liam: Canceled: Practice, /);
    // Canceling again does nothing.
    expect((await save('coach', { action: 'cancel', eventId: first.id, scope: 'this' })).canceled).toBe(0);
  });

  it('cancels the rest of a series once, leaving the past alone, with an audit entry for admins', async () => {
    const { past, upcoming } = await runningSeries('pat');
    const dry = await save('alex', { action: 'cancel', eventId: upcoming[2], scope: 'following', dryRun: true });
    expect(dry.canceled).toBe(5);
    expect((await eventData(upcoming[2]))?.canceledAt).toBeNull();
    await save('alex', { action: 'cancel', eventId: upcoming[2], scope: 'following' });
    for (const id of upcoming.slice(2)) expect((await eventData(id))?.canceledAt).toBeInstanceOf(Timestamp);
    for (const id of [...past, ...upcoming.slice(0, 2)]) expect((await eventData(id))?.canceledAt).toBeNull();
    const changes = await sends('eventChanged');
    expect(changes).toHaveLength(1);
    expect(await body(changes[0], 'sam')).toMatch(/^Canceled: Practice, 5 events from /);
    const audits = await db().collection(Collections.auditLogs).where('action', '==', 'cancelEventSeries').get();
    expect(audits.size).toBe(1);
  });

  it('deletes one event with its RSVPs and skips its date, without notifying', async () => {
    const { seriesId, upcoming } = await runningSeries();
    await rsvp(upcoming[0], 'sam', 'going');
    const date = (await eventData(upcoming[0]))?.seriesDate;
    const out = await save('alex', { action: 'delete', eventId: upcoming[0], scope: 'this' });
    expect(out).toMatchObject({ removed: 1, removedRsvps: 1 });
    expect(await eventData(upcoming[0])).toBeUndefined();
    expect((await db().collection(Collections.rsvps).doc(`${upcoming[0]}_sam`).get()).exists).toBe(false);
    expect((await db().collection(Collections.eventSeries).doc(seriesId).get()).get('recurrence.skipDates')).toEqual([day(0), date]);
    expect(await sends('eventChanged')).toEqual([]);
    expect(await db().collection(Collections.auditLogs).get()).toHaveProperty('size', 0);
  });

  it('deletes the rest of a series, ending it, or the whole series when nothing is left', async () => {
    const { seriesId, past, upcoming } = await runningSeries();
    const out = await save('alex', { action: 'delete', eventId: upcoming[3], scope: 'following' });
    expect(out.removed).toBe(4);
    expect(await eventsOf(seriesId)).toHaveLength(past.length + 3);
    const fromDate = dateBefore(day(4));
    expect((await db().collection(Collections.eventSeries).doc(seriesId).get()).get('recurrence.untilDate')).toBe(fromDate);

    const next = await save('alex', { action: 'create', groupId: G, recurrence: daily(3, 3), template: template() });
    const [first] = await eventsOf(next.seriesId);
    expect((await save('alex', { action: 'delete', eventId: first.id, scope: 'following' })).removed).toBe(3);
    expect((await db().collection(Collections.eventSeries).doc(next.seriesId).get()).exists).toBe(false);
  });
});

/** A one-off event as the app writes it, starting [inMs] from now. */
function oneOff(inMs: number, extra: object = {}): Record<string, unknown> {
  const start = Date.now() + inMs;
  return {
    groupId: G, type: 'practice', title: 'Practice', description: '', location: { name: 'Riverside Park', address: '' },
    allDay: false, startAt: Timestamp.fromMillis(start), endAt: Timestamp.fromMillis(start + 5_400_000), startDate: null, endDate: null,
    timeZone: CHI, arriveMinutesBefore: null, opponent: null, homeAway: null, rsvpEnabled: true, rsvpDeadline: null,
    reminderOffsets: [60, 1440], notifyTeam: true, postToChat: true, rsvpCounts: { going: 0, maybe: 0, notGoing: 0 },
    staffCounts: { going: 0, maybe: 0, notGoing: 0 }, createdBy: 'alex', createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    ...extra,
  };
}

/** Writes [data] to events/[id] and runs the trigger's work for it. */
async function writeEvent(id: string, data: Record<string, unknown> | null): Promise<void> {
  const ref = db().collection(Collections.events).doc(id);
  const before = (await ref.get()).data();
  if (data) await ref.set(data);
  else await ref.delete();
  await followUpEventWrite(id, before, data ?? undefined);
}

describe('the events trigger (ARCH §6.4)', () => {
  it('posts a card and tells the team about a new event, and sets the reminder', async () => {
    const data = oneOff(3 * DAY);
    await writeEvent('e1', data);
    const card = await db().collection(Collections.messages).doc('e1').get();
    expect(card.data()).toMatchObject({ type: 'event', eventId: 'e1', seriesId: null, authorId: 'alex', authorName: 'Alex' });
    expect(card.get('text')).toMatch(/^Practice · \w{3}, \w{3} \d+ at .+ · Riverside Park$/);
    const event = await eventData('e1');
    expect(event?.messageId).toBe('e1');
    expect(ms(event?.nextReminderAt)).toBe(ms(data.startAt) - 1440 * 60_000);
    expect(await centerFor('e1_created')).toEqual(['lee', 'pat', 'sam']);
    // A retried trigger posts no second card.
    await followUpEventWrite('e1', undefined, data);
    expect(await eventCards()).toHaveLength(1);
  });

  it('tells everyone but Not going about a move, and moves the RSVPs', async () => {
    const data = oneOff(3 * DAY, { messageId: 'e1' });
    await writeEvent('e1', data);
    await rsvp('e1', 'pat', 'not_going');
    await rsvp('e1', 'sam', 'going');
    const later = Timestamp.fromMillis(ms(data.startAt) + 1_800_000);
    await writeEvent('e1', { ...data, startAt: later, endAt: Timestamp.fromMillis(ms(later) + 3_600_000), updatedAt: Timestamp.now() });
    const changes = await sends('eventChanged');
    expect(changes).toHaveLength(1);
    // The trigger doesn't know who edited, so Alex hears too.
    expect(await centerFor(changes[0])).toEqual(['alex', 'lee', 'sam']);
    expect(await body(changes[0], 'sam')).toMatch(/^Practice moved to /);
    expect(ms((await db().collection(Collections.rsvps).doc('e1_sam').get()).get('eventStartAt'))).toBe(ms(later));
  });

  it('cancels with a notification and no more reminders', async () => {
    const data = oneOff(3 * DAY, { messageId: 'e1' });
    await writeEvent('e1', data);
    await writeEvent('e1', { ...(await eventData('e1')), canceledAt: Timestamp.now(), canceledBy: 'alex', updatedAt: Timestamp.now() });
    const changes = await sends('eventChanged');
    expect(changes).toHaveLength(1);
    expect(await centerFor(changes[0])).toEqual(['lee', 'pat', 'sam']);
    expect(await body(changes[0], 'pat')).toMatch(/^Canceled: Practice, /);
    expect((await eventData('e1'))?.nextReminderAt).toBeNull();
  });

  it('names players for guardians (PLAYER-7)', async () => {
    const data = oneOff(3 * DAY, { groupId: Y, createdBy: 'coach', messageId: 'y1' });
    await writeEvent('y1', data);
    await rsvp('y1', 'liam', 'not_going', 'player', Y);
    await writeEvent('y1', { ...data, location: { name: 'Field 3', address: '' }, updatedAt: Timestamp.now() });
    const [key] = await sends('eventChanged');
    expect(await centerFor(key)).toEqual(['aunt', 'coach', 'dan', 'maria']);
    expect(await body(key, 'maria')).toBe('Emma: Practice location changed: Field 3');
    expect(await body(key, 'aunt')).toBe('Practice location changed: Field 3');
  });

  it('exits early for Functions-only changes and series events, and clears RSVPs on delete', async () => {
    const data = oneOff(3 * DAY);
    await writeEvent('e1', data);
    const created = await sends('eventCreated');
    await writeEvent('e1', { ...(await eventData('e1')), rsvpCounts: { going: 3, maybe: 0, notGoing: 0 } });
    await writeEvent('s1', oneOff(3 * DAY, { seriesId: 'series' }));
    expect(await eventData('s1')).not.toHaveProperty('nextReminderAt');
    expect(await sends('eventCreated')).toEqual(created);
    expect(await sends('eventChanged')).toEqual([]);
    await rsvp('e1', 'sam', 'going');
    await writeEvent('e1', null);
    expect((await db().collection(Collections.rsvps).doc('e1_sam').get()).exists).toBe(false);
    // The card stays; the app shows the event as deleted.
    expect((await db().collection(Collections.messages).doc('e1').get()).exists).toBe(true);
  });
});

describe('reminder times from fresh data (SCHED-8)', () => {
  it('works the trigger out from the event as it is now, not a late snapshot', async () => {
    const data = oneOff(3 * DAY);
    await writeEvent('e1', data);
    // A later edit moved it a day on; this trigger run still carries an older title edit.
    const moved = Timestamp.fromMillis(ms(data.startAt) + DAY);
    const current = { ...(await eventData('e1')), startAt: moved, endAt: Timestamp.fromMillis(ms(moved) + 5_400_000) };
    await db().collection(Collections.events).doc('e1').set(current);
    await followUpEventWrite('e1', data, { ...data, title: 'Scrimmage', updatedAt: Timestamp.now() });
    expect(ms((await eventData('e1'))?.nextReminderAt)).toBe(ms(moved) - 1440 * 60_000);
  });

  it("leaves the tick's write to the edit that moved the event meanwhile", async () => {
    const data = oneOff(30 * 60_000, { reminderOffsets: [60], nextReminderAt: Timestamp.fromMillis(Date.now() - 60_000) });
    const ref = db().collection(Collections.events).doc('e1');
    await ref.set(data);
    const seen = eventView(data);
    // Moved to tomorrow, with the trigger's new reminder time, before the tick writes.
    const moved = Date.now() + DAY;
    await ref.update({ startAt: Timestamp.fromMillis(moved), endAt: Timestamp.fromMillis(moved + 3_600_000), nextReminderAt: Timestamp.fromMillis(moved - 3_600_000) });
    await settleNextReminder(ref, seen, Date.now(), 0);
    expect(ms((await eventData('e1'))?.nextReminderAt)).toBe(moved - 3_600_000);
    // Unchanged since the tick read it: moves on to the next one (none).
    await ref.set(data);
    await settleNextReminder(ref, seen, Date.now(), 0);
    expect((await eventData('e1'))?.nextReminderAt).toBeNull();
  });
});

describe('removing a player (PLAYER-2)', () => {
  it("deletes the player's answers to upcoming events, and keeps past ones", async () => {
    await db().collection(Collections.events).doc('y1').set(oneOff(DAY, { groupId: Y }));
    await db().collection(Collections.events).doc('y0').set(oneOff(-DAY, { groupId: Y }));
    await rsvp('y1', 'emma', 'going', 'player', Y);
    await rsvp('y1', 'liam', 'going', 'player', Y);
    await rsvp('y0', 'emma', 'going', 'player', Y);
    await removePlayer(Y, 'emma');
    expect((await db().collection(Collections.rsvps).doc('y1_emma').get()).exists).toBe(false);
    expect((await db().collection(Collections.rsvps).doc('y0_emma').get()).exists).toBe(true);
    // The RSVP trigger then recounts.
    await recountEventRsvps('y1');
    expect((await eventData('y1'))?.rsvpCounts).toEqual({ going: 1, maybe: 0, notGoing: 0 });
  });
});

describe('RSVP counts (SCHED-1, PLAYER-6)', () => {
  it("counts members' own answers apart, as others, on an old 'members' event too", async () => {
    await db().collection(Collections.events).doc('e1').set(oneOff(DAY, { rsvpFor: 'members' }));
    await rsvp('e1', 'pat', 'going');
    await rsvp('e1', 'sam', 'going');
    await rsvp('e1', 'lee', 'not_going');
    await recountEventRsvps('e1');
    expect(await eventData('e1')).toMatchObject({
      rsvpCounts: { going: 0, maybe: 0, notGoing: 0 },
      staffCounts: { going: 2, maybe: 0, notGoing: 1 },
    });
    await rsvp('e1', 'sam', 'maybe');
    await recountEventRsvps('e1');
    expect((await eventData('e1'))?.staffCounts).toEqual({ going: 1, maybe: 1, notGoing: 1 });
  });

  it('counts players, and everyone else apart, on every event (D34)', async () => {
    await db().collection(Collections.events).doc('y1').set(oneOff(DAY, { groupId: Y }));
    await rsvp('y1', 'emma', 'going', 'player', Y);
    await rsvp('y1', 'liam', 'maybe', 'player', Y);
    await rsvp('y1', 'coach', 'going', 'member', Y);
    await recountEventRsvps('y1');
    expect(await eventData('y1')).toMatchObject({
      rsvpCounts: { going: 1, maybe: 1, notGoing: 0 },
      staffCounts: { going: 1, maybe: 0, notGoing: 0 },
    });
  });

  it('does nothing for a deleted event', async () => {
    await rsvp('gone', 'sam', 'going');
    await expect(recountEventRsvps('gone')).resolves.toBeUndefined();
  });
});

describe('reminders on the tick (SCHED-8)', () => {
  const runTick = () => tick.run({ scheduleTime: new Date().toISOString() } as Parameters<typeof tick.run>[0]);

  it('reminds everyone but Not going, once, then moves on', async () => {
    const data = oneOff(30 * 60_000, { reminderOffsets: [60, 1440], nextReminderAt: Timestamp.fromMillis(Date.now() - 60_000) });
    await db().collection(Collections.events).doc('e1').set(data);
    await rsvp('e1', 'pat', 'not_going');
    await runTick();
    const [key] = await sends('eventReminder');
    expect(key).toBe(`e1_r60_${Math.floor(ms(data.startAt) / 1000)}`);
    expect(await centerFor(key)).toEqual(['alex', 'lee', 'sam']);
    expect(await body(key, 'sam')).toMatch(/^Reminder: Practice (today|tomorrow) at .+ · Riverside Park$/);
    expect((await eventData('e1'))?.nextReminderAt).toBeNull();
    await runTick();
    expect(await sends('eventReminder')).toHaveLength(1);
  });

  it('advances to the next reminder, and skips canceled and future ones', async () => {
    const soon = oneOff(2 * DAY - 60_000, { reminderOffsets: [60, 2880], nextReminderAt: Timestamp.fromMillis(Date.now() - 1000) });
    await db().collection(Collections.events).doc('soon').set(soon);
    await db().collection(Collections.events).doc('off').set(
      oneOff(30 * 60_000, { canceledAt: Timestamp.now(), nextReminderAt: Timestamp.fromMillis(Date.now() - 1000) }),
    );
    await db().collection(Collections.events).doc('later').set(oneOff(3 * DAY, { nextReminderAt: Timestamp.fromMillis(Date.now() + DAY) }));
    await runTick();
    expect(await sends('eventReminder')).toHaveLength(1);
    expect(ms((await eventData('soon'))?.nextReminderAt)).toBe(ms(soon.startAt) - 3_600_000);
    expect((await eventData('off'))?.nextReminderAt).toBeNull();
    expect((await eventData('later'))?.nextReminderAt).toBeInstanceOf(Timestamp);
  });

  it('reminds guardians of players still coming, and others by their own answer (PLAYER-7, Q14)', async () => {
    const data = oneOff(30 * 60_000, {
      groupId: Y, location: null, nextReminderAt: Timestamp.fromMillis(Date.now() - 1000),
    });
    await db().collection(Collections.events).doc('y1').set(data);
    await rsvp('y1', 'ava', 'not_going', 'player', Y);
    await rsvp('y1', 'emma', 'going', 'player', Y);
    await runTick();
    const [key] = await sends('eventReminder');
    // Dan's only player said Not going; the aunt isn't linked to a player and didn't answer.
    expect(await centerFor(key)).toEqual(['aunt', 'coach', 'maria']);
    expect(await body(key, 'maria')).toMatch(/^Emma, Liam: Practice (today|tomorrow) at [\d:]+ [AP]M$/);
    expect(await body(key, 'coach')).toMatch(/^Reminder: Practice /);
    expect(await body(key, 'aunt')).toMatch(/^Reminder: Practice /);
  });

  it("reminds a member who is the player by the player's answer, with no name (PLAYER-7)", async () => {
    await db().collection(Collections.players).doc('pat-p').set({ groupId: G, displayName: 'Pat Doe', status: 'active' });
    await db().collection(Collections.playerGuardians).doc('pat-p_pat').set({ groupId: G, playerId: 'pat-p', uid: 'pat', relation: 'self' });
    // A pending player isn't on the roster: its proposer goes by their own answer.
    await db().collection(Collections.players).doc('sam-p').set({ groupId: G, displayName: 'Sam', status: 'pending', proposedBy: 'sam' });
    const data = oneOff(30 * 60_000, { reminderOffsets: [60], nextReminderAt: Timestamp.fromMillis(Date.now() - 1000) });
    await db().collection(Collections.events).doc('e1').set(data);
    await rsvp('e1', 'pat', 'not_going');
    await rsvp('e1', 'lee', 'not_going');
    await runTick();
    const [key] = await sends('eventReminder');
    // Pat's own "member" answer doesn't matter: Pat answers on the player's row.
    expect(await centerFor(key)).toEqual(['alex', 'pat', 'sam']);
    expect(await body(key, 'pat')).toMatch(/^Reminder: Practice /);
    await db().collection(Collections.events).doc('e2').set({ ...data, reminderOffsets: [60] });
    await rsvp('e2', 'pat-p', 'not_going', 'player');
    await runTick();
    const e2 = (await sends('eventReminder')).find((k) => k.startsWith('e2_'))!;
    expect(await centerFor(e2)).toEqual(['alex', 'lee', 'sam']);
  });
});

describe('event cards in chat (CHAT-11)', () => {
  it('sends no message notification for a card, and deleting the card keeps the event', async () => {
    await writeEvent('e1', oneOff(3 * DAY));
    const card = (await db().collection(Collections.messages).doc('e1').get()).data()!;
    await notifyNewMessage('e1', card, 'Thunder', null);
    expect(await sends('message')).toEqual([]);
    await eraseMessage('e1', 'alex', 'author');
    expect((await db().collection(Collections.messages).doc('e1').get()).get('deletedAt')).toBeInstanceOf(Timestamp);
    expect(await eventData('e1')).toBeDefined();
  });
});
