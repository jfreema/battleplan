// Importing events (SPEC IMPORT-1 to IMPORT-5): previews write nothing,
// imports add each event once, quietly, with normal reminders. Runs against
// the Firestore emulator:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { importEvents as importEventsCallable } from '../../src/imports/handlers.js';
import { importEvents, importedEventId } from '../../src/imports/service.js';
import { followUpEventWrite } from '../../src/schedule/service.js';
import { db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';

vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({ sendEach: async () => ({ responses: [], successCount: 0, failureCount: 0 }) }),
}));

const G = 'teamA';
const CHI = 'America/Chicago';
const DAY = 86_400_000;

/** A calendar date [days] from now, as iCalendar writes it. */
const icsDate = (days: number) => new Date(Date.now() + days * DAY).toISOString().slice(0, 10).replaceAll('-', '');

/** Two games and a weekly practice, one game past. */
const feed = () =>
  [
    'BEGIN:VCALENDAR',
    'X-WR-TIMEZONE:America/Chicago',
    'BEGIN:VEVENT',
    'UID:g1',
    `DTSTART;TZID=America/Chicago:${icsDate(3)}T100000`,
    `DTEND;TZID=America/Chicago:${icsDate(3)}T120000`,
    'SUMMARY:Thunder vs. Eagles',
    'LOCATION:Riverside Park\\, 100 River Rd',
    'END:VEVENT',
    'BEGIN:VEVENT',
    'UID:g2',
    `DTSTART;TZID=America/Chicago:${icsDate(10)}T100000`,
    'SUMMARY:@ Comets',
    'END:VEVENT',
    'BEGIN:VEVENT',
    'UID:p1',
    `DTSTART;TZID=America/Chicago:${icsDate(2)}T180000`,
    `DTEND;TZID=America/Chicago:${icsDate(2)}T193000`,
    'RRULE:FREQ=WEEKLY;COUNT=3',
    'SUMMARY:Practice',
    'END:VEVENT',
    'BEGIN:VEVENT',
    'UID:old',
    `DTSTART;TZID=America/Chicago:${icsDate(-20)}T100000`,
    'SUMMARY:vs. Old Team',
    'END:VEVENT',
    'END:VCALENDAR',
  ].join('\r\n');

type CallRequest = Parameters<typeof importEventsCallable.run>[0];
const call = (uid: string, data: object, token: object = {}) =>
  importEventsCallable.run({ data, auth: { uid, token }, rawRequest: {} } as unknown as CallRequest);
const input = (extra: object = {}) => ({ groupId: G, source: 'gamechanger' as const, ics: feed(), includePast: false, dryRun: false, ...extra });
const caller = (uid: string, superAdmin = false) => ({ uid, superAdmin });

async function person(uid: string, role = 'member'): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(G, uid)).set({
    groupId: G, uid, role, displayName: uid, photoPath: null, notificationLevel: 'all',
  });
  await db().collection(Collections.users).doc(uid).set({ displayName: uid, status: 'active', notificationPrefs: {} });
}

const teamEvents = async () =>
  (await db().collection(Collections.events).where('groupId', '==', G).orderBy('startAt').get()).docs;

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
  await db().collection(Collections.groups).doc(G).set({
    name: 'Thunder', kind: 'team', timeZone: CHI,
    settings: { membersCanCreateEvents: false, defaultReminderOffsets: [1440, 60] },
    storageBytes: 0, storageQuotaBytes: 1_000_000,
  });
  await person('alex', 'owner');
  await person('pat');
});

describe('previewing an import (IMPORT-3)', () => {
  it('counts and samples the new events, and writes nothing', async () => {
    const res = await importEvents(input({ dryRun: true }), caller('alex'));
    expect(res).toMatchObject({ added: 5, alreadyImported: 0, past: 1, skippedCount: 0 });
    expect(res.sample.map((s) => s.title)).toEqual(['Practice', 'vs. Eagles', 'Practice', '@ Comets', 'Practice']);
    expect(res.sample[1]).toMatchObject({ type: 'game', place: 'Riverside Park, 100 River Rd', timeZone: CHI, allDay: false });
    expect(res.firstMs).toBe(res.sample[0].startMs);
    expect(res.lastMs).toBe(res.sample[4].startMs);
    expect(await teamEvents()).toHaveLength(0);
  });

  it('takes the calendar link through the fetcher', async () => {
    const seen: string[] = [];
    const res = await importEvents(
      { groupId: G, source: 'gamechanger', url: 'webcal://example.com/team.ics', includePast: true, dryRun: true },
      caller('alex'),
      Date.now(),
      async (url) => {
        seen.push(url);
        return feed();
      },
    );
    expect(seen).toEqual(['webcal://example.com/team.ics']);
    expect(res).toMatchObject({ added: 6, past: 0 });
  });

  it("says when what came back isn't a calendar", async () => {
    await expect(importEvents(input({ ics: '<html>Sign in</html>' }), caller('alex'))).rejects.toMatchObject({ message: 'not-a-calendar' });
  });
});

describe('importing (IMPORT-4, IMPORT-5)', () => {
  it('adds each event as the app would, quietly, with the team reminders', async () => {
    const res = await importEvents(input(), caller('alex'));
    expect(res.added).toBe(5);
    const events = await teamEvents();
    expect(events.map((e) => e.get('title'))).toEqual(['Practice', 'vs. Eagles', 'Practice', '@ Comets', 'Practice']);
    const eagles = events.find((e) => e.id === importedEventId(G, 'gamechanger', 'g1'))!;
    expect(eagles.data()).toMatchObject({
      groupId: G, type: 'game', opponent: 'Eagles', homeAway: 'home', allDay: false, timeZone: CHI,
      location: { name: 'Riverside Park', address: '100 River Rd' },
      rsvpEnabled: true, reminderOffsets: [60, 1440], notifyTeam: false, postToChat: false,
      rsvpCounts: { going: 0, maybe: 0, notGoing: 0 }, seriesId: null, canceledAt: null, createdBy: 'alex',
    });
    expect((eagles.get('endAt') as Timestamp).toMillis() - (eagles.get('startAt') as Timestamp).toMillis()).toBe(2 * 3_600_000);
    // The day-before reminder is the next one due.
    expect((eagles.get('nextReminderAt') as Timestamp).toMillis()).toBe((eagles.get('startAt') as Timestamp).toMillis() - DAY);
    // The events trigger's follow-up: no chat card, no "new event" notification.
    for (const e of events) await followUpEventWrite(e.id, undefined, e.data());
    expect((await db().collection(Collections.messages).get()).size).toBe(0);
    expect((await db().collection(Collections.notifyLog).get()).size).toBe(0);
    // An audit entry says who imported what.
    const audits = await db().collection(Collections.auditLogs).where('action', '==', 'importEvents').get();
    expect(audits.docs.map((d) => d.get('after'))).toEqual([
      { source: 'gamechanger', from: 'file', added: 5, alreadyImported: 0, past: 1, skipped: 0 },
    ]);
  });

  it('adds nothing twice, and leaves events it brought in before as they are', async () => {
    await importEvents(input(), caller('alex'));
    const eagles = db().collection(Collections.events).doc(importedEventId(G, 'gamechanger', 'g1'));
    await eagles.update({ title: 'vs. Eagles (moved)' });
    const again = await importEvents(input(), caller('alex'));
    expect(again).toMatchObject({ added: 0, alreadyImported: 5 });
    expect(await teamEvents()).toHaveLength(5);
    expect((await eagles.get()).get('title')).toBe('vs. Eagles (moved)');
    // Past events too, when asked, and only those are new.
    expect(await importEvents(input({ includePast: true }), caller('alex'))).toMatchObject({ added: 1, alreadyImported: 5 });
  });

  it("keeps each team's imports apart", async () => {
    expect(importedEventId('teamA', 'gamechanger', 'g1')).not.toBe(importedEventId('teamB', 'gamechanger', 'g1'));
  });
});

describe('who may import (IMPORT-1)', () => {
  it('is for team admins, and super admins', async () => {
    await expect(importEvents(input({ dryRun: true }), caller('pat'))).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(importEvents(input({ dryRun: true }), caller('stranger'))).rejects.toMatchObject({ code: 'permission-denied' });
    expect(await importEvents(input({ dryRun: true }), caller('root', true))).toMatchObject({ added: 5 });
  });

  it('refuses archived teams, and full ones when adding', async () => {
    await db().collection(Collections.groups).doc(G).update({ storageBytes: 1_000_000 });
    expect(await importEvents(input({ dryRun: true }), caller('alex'))).toMatchObject({ added: 5 });
    await expect(importEvents(input(), caller('alex'))).rejects.toMatchObject({ message: 'storage-full' });
    await db().collection(Collections.groups).doc(G).update({ storageBytes: 0, archivedAt: Timestamp.now() });
    await expect(importEvents(input({ dryRun: true }), caller('alex'))).rejects.toMatchObject({ message: 'team-archived' });
  });

  it('checks the callable input: a link or a file, not both', async () => {
    await expect(call('alex', { groupId: G, source: 'gamechanger' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call('alex', { groupId: G, source: 'gamechanger', url: 'https://example.com/a.ics', ics: feed() })).rejects.toMatchObject({
      code: 'invalid-argument',
    });
    await expect(call('alex', { groupId: G, source: 'teamsnap', ics: feed() })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call('alex', { groupId: G, source: 'gamechanger', url: 'http://example.com/a.ics' })).rejects.toMatchObject({
      message: 'bad-link',
    });
    // Previews are the default; every calendar app reads the same way.
    expect(await call('alex', { groupId: G, source: 'gamechanger', ics: feed() })).toMatchObject({ added: 5 });
    expect(await call('alex', { groupId: G, source: 'teamreach', ics: feed() })).toMatchObject({ added: 5 });
    expect(await call('alex', { groupId: G, source: 'google', ics: feed() })).toMatchObject({ added: 5 });
    expect(await teamEvents()).toHaveLength(0);
  });
});
