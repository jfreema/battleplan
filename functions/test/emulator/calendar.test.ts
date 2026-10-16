// Calendar links on the server (SPEC SCHED-11, ARCH §6.15): setCalendarLink,
// the feed for one team or all of them, the cached copy per team and what
// refreshes it, and the cleanup when someone leaves or a team or account
// goes. Runs against the Firestore emulator:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { calendarFeed as feedHandler, setCalendarLink } from '../../src/calendar/handlers.js';
import {
  calendarFeed,
  deleteCalendarLinksOf,
  markTeamCalendarChanged,
} from '../../src/calendar/service.js';
import { parseIcs } from '../../src/imports/ics.js';
import { deleteGroupData } from '../../src/teams/service.js';
import { db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';

const G = 'thunder';
const Y = 'cyclone';
const HOUR = 3_600_000;
const DAY = 24 * HOUR;
const NOW = Date.now();

type CallRequest = Parameters<typeof setCalendarLink.run>[0];
const link = async (uid: string, groupId: string | null, action = 'make'): Promise<string | null> => {
  const req = { data: { groupId, action }, auth: { uid, token: {} }, rawRequest: {} } as unknown as CallRequest;
  return ((await setCalendarLink.run(req)) as { token: string | null }).token;
};
const linkDoc = (token: string) => db().collection(Collections.calendarLinks).doc(token).get();

async function team(id: string, name: string, extra: object = {}): Promise<void> {
  await db().collection(Collections.groups).doc(id).set({ name, kind: 'team', status: 'active', ...extra });
}
async function person(g: string, uid: string, role = 'member'): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(g, uid)).set({ groupId: g, uid, role });
  await db().collection(Collections.users).doc(uid).set({ displayName: uid, status: 'active' });
}
async function event(id: string, g: string, startMs: number, extra: object = {}): Promise<void> {
  await db().collection(Collections.events).doc(id).set({
    groupId: g,
    type: 'practice',
    title: 'Practice',
    description: '',
    location: { name: 'Riverside Park', address: '' },
    allDay: false,
    startAt: Timestamp.fromMillis(startMs),
    endAt: Timestamp.fromMillis(startMs + 90 * 60_000),
    timeZone: 'America/Chicago',
    canceledAt: null,
    updatedAt: Timestamp.fromMillis(NOW - DAY),
    ...extra,
  });
}
const feed = async (token: string, at = NOW) => {
  const out = await calendarFeed(`/cal/${token}.ics`, at);
  return { ...out, cal: out.status === 200 ? parseIcs(out.body) : null };
};

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
  await team(G, 'Thunder');
  await team(Y, 'Cyclone');
  await person(G, 'coach', 'owner');
  await person(Y, 'coach', 'admin');
  await person(G, 'pat');
  await db().collection(Collections.users).doc('stranger').set({ displayName: 'Stranger', status: 'active' });
  await event('soon', G, NOW + 2 * DAY);
  await event('game', G, NOW + 5 * DAY, { type: 'game', title: 'vs. Eagles', arriveMinutesBefore: 30 });
  await event('rainout', G, NOW + 3 * DAY, { canceledAt: Timestamp.fromMillis(NOW - HOUR) });
  await event('lastSeason', G, NOW - 90 * DAY);
  await event('nextYear', G, NOW + 400 * DAY);
  await event('cyclone', Y, NOW + DAY, { title: 'Cyclone practice' });
});

describe('making, resetting, and turning off a link', () => {
  it('makes one link per team, the same one each time, until it is reset', async () => {
    const first = await link('coach', G);
    expect(first).toMatch(/^[A-Za-z0-9_-]{43}$/);
    expect(await link('coach', G)).toBe(first);
    expect((await linkDoc(first!)).data()).toMatchObject({ uid: 'coach', groupId: G });

    const fresh = await link('coach', G, 'reset');
    expect(fresh).not.toBe(first);
    expect((await linkDoc(first!)).exists).toBe(false);
    expect((await feed(first!)).status).toBe(404);
    expect((await feed(fresh!)).status).toBe(200);

    expect(await link('coach', G, 'off')).toBeNull();
    expect((await linkDoc(fresh!)).exists).toBe(false);
  });

  it('keeps a link for all teams apart from each team link', async () => {
    const all = await link('coach', null);
    const thunder = await link('coach', G);
    expect(all).not.toBe(thunder);
    expect((await linkDoc(all!)).get('groupId')).toBeNull();
  });

  it("refuses a team you're not on, and a team that's archived", async () => {
    await expect(link('stranger', G)).rejects.toMatchObject({ code: 'permission-denied' });
    await team(G, 'Thunder', { archivedAt: Timestamp.now(), status: 'archived' });
    await expect(link('coach', G)).rejects.toMatchObject({ code: 'failed-precondition' });
  });
});

describe('the feed', () => {
  it("serves the team's events in the window, canceled ones marked", async () => {
    const token = (await link('pat', G))!;
    const { status, cal, filename } = await feed(token);
    expect(status).toBe(200);
    expect(filename).toBe('thunder.ics');
    expect(cal!.name).toBe('Thunder');
    expect(cal!.events.map((e) => e.uid)).toEqual([
      'soon@getbattleplan.app',
      'rainout@getbattleplan.app',
      'game@getbattleplan.app',
    ]);
    const rainout = cal!.events[1];
    expect(rainout.summary).toBe('Canceled: Practice');
    expect(rainout.status).toBe('CANCELLED');
    expect(cal!.events[2].description).toContain('Arrive 30 minutes early.');
    expect(cal!.events[2].description).toContain('/app/g/thunder/schedule/e/game');
  });

  it('serves all teams with their names before the titles', async () => {
    const token = (await link('coach', null))!;
    const { cal } = await feed(token);
    expect(cal!.name).toBe('Battleplan');
    expect(cal!.events.map((e) => e.summary)).toEqual([
      'Cyclone · Cyclone practice',
      'Thunder · Practice',
      'Canceled: Thunder · Practice',
      'Thunder · vs. Eagles',
    ]);
  });

  it('serves a cached copy until an event changes', async () => {
    const token = (await link('pat', G))!;
    expect((await feed(token)).cal!.events).toHaveLength(3);
    expect((await db().collection(Collections.teamCalendars).doc(G).get()).get('groupId')).toBe(G);

    // Written straight to Firestore, as the app does; the trigger isn't
    // running here, so the copy is still the old one...
    await event('extra', G, NOW + 6 * DAY);
    expect((await feed(token)).cal!.events).toHaveLength(3);
    // ...until the trigger's mark, after which it's rebuilt.
    await markTeamCalendarChanged(G);
    expect((await feed(token)).cal!.events).toHaveLength(4);
    // And once it's over six hours old.
    await event('later', G, NOW + 7 * DAY);
    expect((await feed(token, NOW + 7 * HOUR)).cal!.events).toHaveLength(5);
  });

  it("marks a team's copy only while it has one", async () => {
    await markTeamCalendarChanged(G);
    expect((await db().collection(Collections.teamCalendars).doc(G).get()).exists).toBe(false);
  });

  it("empties a team you've left, and stops for a disabled account", async () => {
    const team = (await link('pat', G))!;
    const all = (await link('pat', null))!;
    await db().collection(Collections.groupMembers).doc(groupMemberId(G, 'pat')).delete();
    const left = await feed(team);
    expect(left.status).toBe(200);
    expect(left.cal!.name).toBe('Thunder');
    expect(left.cal!.events).toHaveLength(0);
    expect((await feed(all)).cal!.events).toHaveLength(0);

    await db().collection(Collections.users).doc('pat').update({ status: 'disabled' });
    expect((await feed(all)).status).toBe(404);
  });

  it('leaves out archived and suspended teams', async () => {
    const token = (await link('coach', null))!;
    await team(Y, 'Cyclone', { suspendedAt: Timestamp.now(), status: 'suspended' });
    expect((await feed(token)).cal!.events.every((e) => e.summary.includes('Thunder'))).toBe(true);
  });

  it('says when a calendar last checked, at most hourly', async () => {
    const token = (await link('pat', G))!;
    expect((await linkDoc(token)).get('fetchedAt')).toBeUndefined();
    await feed(token);
    const first = (await linkDoc(token)).get('fetchedAt') as Timestamp;
    expect(first).toBeInstanceOf(Timestamp);
    await feed(token, first.toMillis() + 10 * 60_000);
    expect(((await linkDoc(token)).get('fetchedAt') as Timestamp).isEqual(first)).toBe(true);
  });

  it('answers calendar apps over HTTP, and only GET or HEAD', async () => {
    const token = (await link('pat', G))!;
    const reply = async (method: string, path: string) => {
      const out = { status: 0, headers: {} as Record<string, string>, body: '' };
      const res = {
        status(code: number) {
          out.status = code;
          return res;
        },
        set(name: string, value: string) {
          out.headers[name.toLowerCase()] = value;
          return res;
        },
        type(value: string) {
          out.headers['content-type'] = value;
          return res;
        },
        send(body: string) {
          out.body = body;
          return res;
        },
      };
      await (feedHandler as unknown as (req: object, res: object) => Promise<void>)({ method, path }, res);
      return out;
    };
    const ok = await reply('GET', `/cal/${token}.ics`);
    expect(ok.status).toBe(200);
    expect(ok.headers['content-type']).toBe('text/calendar; charset=utf-8');
    expect(ok.headers['content-disposition']).toBe('inline; filename="thunder.ics"');
    expect(ok.headers['x-robots-tag']).toBe('noindex');
    expect(ok.body).toContain('BEGIN:VCALENDAR');
    expect((await reply('HEAD', `/cal/${token}.ics`)).body).toBe('');
    expect((await reply('GET', '/cal/nothing-here.ics')).status).toBe(404);
    expect((await reply('POST', `/cal/${token}.ics`)).status).toBe(405);
  });
});

describe('cleanup', () => {
  it("deletes a person's link to one team, or all of them", async () => {
    const thunder = (await link('coach', G))!;
    const cyclone = (await link('coach', Y))!;
    const all = (await link('coach', null))!;
    await deleteCalendarLinksOf('coach', G);
    expect((await linkDoc(thunder)).exists).toBe(false);
    expect((await linkDoc(cyclone)).exists).toBe(true);
    await deleteCalendarLinksOf('coach');
    expect((await linkDoc(cyclone)).exists).toBe(false);
    expect((await linkDoc(all)).exists).toBe(false);
  });

  it("deletes a team's cached copy and links to it with the team", async () => {
    const thunder = (await link('pat', G))!;
    const all = (await link('pat', null))!;
    await feed(thunder);
    await deleteGroupData(G);
    expect((await db().collection(Collections.teamCalendars).doc(G).get()).exists).toBe(false);
    expect((await linkDoc(thunder)).exists).toBe(false);
    expect((await linkDoc(all)).exists).toBe(true);
  });
});
