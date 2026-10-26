// Assignments on the server (SPEC SCHED-15). The app writes them under the
// rules; Functions clean up after them: they go with their event (deleted
// by hand, through saveEventSeries, or with the team, TEAM-9), and a
// person's open again when they leave a team or are removed from it
// (TEAM-3, TEAM-8) or delete their account (AUTH-10). Runs against the
// Auth, Firestore, and Storage emulators with FCM faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { deleteAccount } from '../../src/accounts/service.js';
import { clearAssignmentsOf, deleteEventAssignments } from '../../src/schedule/assignments.js';
import { dateInZone } from '../../src/schedule/recurrence.js';
import { SaveSeriesInput, saveSeries } from '../../src/schedule/series.js';
import { followUpEventWrite } from '../../src/schedule/service.js';
import { db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';
import * as teams from '../../src/teams/handlers.js';
import { deleteGroupData } from '../../src/teams/service.js';

vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({ sendEach: async () => ({ responses: [], successCount: 0, failureCount: 0 }) }),
}));

const G = 'teamA';
const Y = 'teamY';
const CHI = 'America/Chicago';
const project = () => process.env.GCLOUD_PROJECT ?? 'demo-battleplan';

type Callable = { run: (request: never) => Promise<unknown> };
const run = (fn: Callable, uid: string, data: object) =>
  fn.run({ data, auth: { uid, token: {} }, rawRequest: { ip: '1.2.3.4' } } as never);

const tasks = () => db().collection(Collections.assignments);
const ALEX = { uid: 'alex', superAdmin: false };

/** The date in Chicago [days] calendar days from today. */
const day = (days: number) => {
  const d = new Date(`${dateInZone(Date.now(), CHI)}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
};

/** Every day for [days] days from [from] days out. */
const daily = (from: number, days: number, interval = 1) => ({
  freq: 'daily', interval, byWeekday: [], startDate: day(from), untilDate: day(from + days - 1), count: null, skipDates: [],
});

const template = {
  type: 'practice', title: 'Practice', description: '', location: null, allDay: false, startTime: '18:00',
  endTime: '19:30', timeZone: CHI, rsvpEnabled: true, reminderOffsets: [], notifyTeam: false, postToChat: false,
};

const save = (data: object) => saveSeries(SaveSeriesInput.parse(data), ALEX);

async function team(g: string): Promise<void> {
  await db().collection(Collections.groups).doc(g).set({
    name: g, nameLower: g, kind: 'team', ownerId: 'alex', timeZone: CHI, memberCount: 3, archivedAt: null, suspendedAt: null,
    settings: { membersCanCreateEvents: false, defaultReminderOffsets: [1440] }, storageBytes: 0, storageQuotaBytes: 1_000_000,
  });
}

async function person(g: string, uid: string, role = 'member'): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(g, uid)).set({
    groupId: g, uid, role, displayName: uid, photoPath: null, notificationLevel: 'all',
  });
  await db().collection(Collections.users).doc(uid).set({ displayName: uid, status: 'active', notificationPrefs: {} });
}

/** A task on [eventId] as the app writes it: [holder] volunteered for it, or it's open. */
async function task(id: string, eventId: string, holder: string | null, g = G): Promise<void> {
  await tasks().doc(id).set({
    groupId: g, eventId, kind: 'snacks', label: null, assigneeUid: holder, assignedBy: holder,
    createdBy: 'alex', createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
  });
}

const taskIds = async () => (await tasks().get()).docs.map((d) => d.id).sort();
/** Who has task [id], and who put them there. */
const holderOf = async (id: string) => {
  const d = await tasks().doc(id).get();
  return [d.get('assigneeUid'), d.get('assignedBy')];
};
const seriesEvents = async (seriesId: string) =>
  (await db().collection(Collections.events).where('seriesId', '==', seriesId).orderBy('startAt').get()).docs.map((d) => d.id);

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error('Run with npm run emulators:test');
  }
});

// teamA: alex owner, sam and pat members. teamY: alex owner, sam member.
beforeEach(async () => {
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project()}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  expect(res.ok).toBe(true);
  await team(G);
  await team(Y);
  await person(G, 'alex', 'owner');
  await person(G, 'sam');
  await person(G, 'pat');
  await person(Y, 'alex', 'owner');
  await person(Y, 'sam');
});

describe("deleting events takes their tasks (SCHED-15)", () => {
  it('deletes every task of the events, more than 30 events at once, and no others', async () => {
    const ids = Array.from({ length: 35 }, (_, i) => `e${i}`);
    for (const id of ids) await task(`${id}-t`, id, null);
    await task('e0-t2', 'e0', 'sam');
    await task('keep-t', 'keep', 'pat');
    expect(await deleteEventAssignments(ids)).toBe(36);
    expect(await taskIds()).toEqual(['keep-t']);
    expect(await deleteEventAssignments([])).toBe(0);
  });

  it('when a one-off event is deleted (the events trigger)', async () => {
    const start = Date.now() + 3 * 86_400_000;
    const event = {
      groupId: G, type: 'practice', title: 'Practice', description: '', location: null, allDay: false,
      startAt: Timestamp.fromMillis(start), endAt: Timestamp.fromMillis(start + 5_400_000), timeZone: CHI,
      rsvpEnabled: true, reminderOffsets: [], notifyTeam: false, postToChat: false, createdBy: 'alex',
    };
    await db().collection(Collections.events).doc('e1').set(event);
    await task('t1', 'e1', 'sam');
    await task('t2', 'e1', null);
    await task('t3', 'e2', 'pat');
    await db().collection(Collections.events).doc('e1').delete();
    await followUpEventWrite('e1', event, undefined);
    expect(await taskIds()).toEqual(['t3']);
  });

  it('when saveEventSeries deletes one event, or the rest of the series', async () => {
    const { seriesId } = await save({ action: 'create', groupId: G, recurrence: daily(3, 5), template });
    const events = await seriesEvents(seriesId);
    expect(events).toHaveLength(5);
    for (const id of events) await task(`${id}-t`, id, 'sam');
    await save({ action: 'delete', eventId: events[0], scope: 'this' });
    expect(await taskIds()).toEqual(events.slice(1).map((id) => `${id}-t`).sort());
    await save({ action: 'delete', eventId: events[3], scope: 'following' });
    expect(await taskIds()).toEqual(events.slice(1, 3).map((id) => `${id}-t`).sort());
  });

  it('when "This and following" drops dates, and only on the events that went', async () => {
    const { seriesId } = await save({ action: 'create', groupId: G, recurrence: daily(3, 4), template });
    const events = await seriesEvents(seriesId);
    for (const id of events) await task(`${id}-t`, id, 'pat');
    // Every other day from the first: the 2nd and 4th dates go.
    const out = await save({
      action: 'update', eventId: events[0], scope: 'following', template, recurrence: daily(3, 4, 2),
    });
    expect(out).toMatchObject({ removed: 2, updated: 2, created: 0 });
    expect(await taskIds()).toEqual([`${events[0]}-t`, `${events[2]}-t`].sort());
    expect(await holderOf(`${events[2]}-t`)).toEqual(['pat', 'pat']);
  });
});

describe("a person's tasks open again when they go (SCHED-15)", () => {
  beforeEach(async () => {
    await task('mine1', 'e1', 'sam');
    await task('mine2', 'e2', 'sam');
    await task('elsewhere', 'y1', 'sam', Y);
    await task('theirs', 'e1', 'pat');
    await task('open', 'e1', null);
  });

  it('opens them on one team, or on every team, and no one else\'s', async () => {
    const before = (await tasks().doc('mine1').get()).get('updatedAt') as Timestamp;
    expect(await clearAssignmentsOf('sam', G)).toBe(2);
    expect(await holderOf('mine1')).toEqual([null, null]);
    expect(await holderOf('mine2')).toEqual([null, null]);
    expect(((await tasks().doc('mine1').get()).get('updatedAt') as Timestamp).toMillis()).toBeGreaterThanOrEqual(before.toMillis());
    expect(await holderOf('elsewhere')).toEqual(['sam', 'sam']);
    expect(await holderOf('theirs')).toEqual(['pat', 'pat']);
    // The task stays, as it was otherwise.
    expect((await tasks().doc('mine1').get()).data()).toMatchObject({ groupId: G, eventId: 'e1', kind: 'snacks', createdBy: 'alex' });
    expect(await clearAssignmentsOf('sam')).toBe(1);
    expect(await holderOf('elsewhere')).toEqual([null, null]);
    expect(await clearAssignmentsOf('sam')).toBe(0);
    expect(await taskIds()).toHaveLength(5);
  });

  it('a page at a time, past the first page', async () => {
    const batch = db().batch();
    for (let i = 0; i < 401; i++) {
      batch.set(tasks().doc(`many${String(i).padStart(3, '0')}`), {
        groupId: G, eventId: 'e9', kind: 'drinks', label: null, assigneeUid: 'pat', assignedBy: 'alex',
        createdBy: 'alex', createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      });
    }
    await batch.commit();
    expect(await clearAssignmentsOf('pat', G)).toBe(402);
    expect((await tasks().where('assigneeUid', '==', 'pat').get()).size).toBe(0);
  });

  it('when they are removed from the team (TEAM-3), on that team only', async () => {
    await run(teams.removeMember, 'alex', { groupId: G, uid: 'sam' });
    expect(await holderOf('mine1')).toEqual([null, null]);
    expect(await holderOf('mine2')).toEqual([null, null]);
    expect(await holderOf('elsewhere')).toEqual(['sam', 'sam']);
    expect(await holderOf('theirs')).toEqual(['pat', 'pat']);
  });

  it('when they leave the team (TEAM-8), on that team only', async () => {
    await run(teams.leaveGroup, 'sam', { groupId: G });
    expect((await db().collection(Collections.groupMembers).doc(groupMemberId(G, 'sam')).get()).exists).toBe(false);
    expect(await holderOf('mine1')).toEqual([null, null]);
    expect(await holderOf('mine2')).toEqual([null, null]);
    expect(await holderOf('elsewhere')).toEqual(['sam', 'sam']);
  });

  it('when they delete their account (AUTH-10), on every team', async () => {
    await deleteAccount('sam', {});
    for (const id of ['mine1', 'mine2', 'elsewhere']) expect(await holderOf(id)).toEqual([null, null]);
    expect(await holderOf('theirs')).toEqual(['pat', 'pat']);
    expect(await taskIds()).toHaveLength(5);
  });
});

describe('deleting a team takes its tasks (TEAM-9)', () => {
  it("every one of the team's, no other team's", async () => {
    await task('t1', 'e1', 'sam');
    await task('t2', 'e2', null);
    await task('y1', 'y1', 'sam', Y);
    await deleteGroupData(G);
    expect(await taskIds()).toEqual(['y1']);
  });
});
