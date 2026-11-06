// Answering from an email on the server (SPEC SCHED-14, ARCH §6.15): who
// "Email people who haven't RSVP'd" emails, what each email asks (each
// player on their own, PLAYER-11), and the answer page its links open, from
// the form to the saved RSVPs. Runs
// against the Firestore emulator, with email captured:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { answerPage as pageHandler, emailRsvpReminder } from '../../src/answers/handlers.js';
import { answerLinkId, answerPage, emailRsvpReminder as emailService } from '../../src/answers/service.js';
import type { Email } from '../../src/email/service.js';
import { db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';

const outbox = vi.hoisted(() => [] as Email[]);
// Emails to an address in `refused` don't send, as when the provider is over
// its limit; to one in `broken`, the send throws, as on a network error.
const refused = vi.hoisted(() => new Set<string>());
const broken = vi.hoisted(() => new Set<string>());
vi.mock('../../src/email/service.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/email/service.js')>()),
  sendEmail: async (email: Email) => {
    if (refused.has(email.to)) return false;
    if (broken.has(email.to)) throw new Error('fetch failed');
    outbox.push(email);
    return true;
  },
}));

const G = 'thunder';
const HOUR = 3_600_000;
const NOW = Date.now();
type CallRequest = Parameters<typeof emailRsvpReminder.run>[0];
const send = async (uid: string, eventId = 'game', dryRun = false) => {
  const req = { data: { eventId, dryRun }, auth: { uid, token: {} }, rawRequest: {} } as unknown as CallRequest;
  return (await emailRsvpReminder.run(req)) as {
    people: number;
    players: number;
    unreachable: number;
    failed: number;
    skipped: number;
  };
};

async function person(uid: string, name: string, role = 'member', extra: object = {}): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(G, uid)).set({ groupId: G, uid, role, displayName: name });
  await db().collection(Collections.users).doc(uid).set({ displayName: name, email: `${uid}@example.com`, status: 'active', ...extra });
}
async function player(id: string, name: string, links: [string, 'self' | 'guardian'][], extra: object = {}): Promise<void> {
  await db().collection(Collections.players).doc(id).set({ groupId: G, displayName: name, status: 'active', ...extra });
  for (const [uid, relation] of links) {
    await db().collection(Collections.playerGuardians).doc(groupMemberId(id, uid)).set({ playerId: id, groupId: G, uid, relation });
  }
}
async function game(id: string, extra: object = {}): Promise<void> {
  await db().collection(Collections.events).doc(id).set({
    groupId: G,
    type: 'game',
    title: 'vs. Eagles',
    description: '',
    location: { name: 'Riverside Park', address: '' },
    allDay: false,
    startAt: Timestamp.fromMillis(NOW + 2 * 24 * HOUR),
    endAt: Timestamp.fromMillis(NOW + 2 * 24 * HOUR + 2 * HOUR),
    timeZone: 'America/Chicago',
    rsvpEnabled: true,
    rsvpDeadline: null,
    canceledAt: null,
    createdBy: 'coach',
    ...extra,
  });
}
const rsvp = (eventId: string, playerId: string) => db().collection(Collections.rsvps).doc(`${eventId}_${playerId}`).get();
/** The token in the email to [to]. */
const tokenFor = (to: string) => {
  const email = outbox.find((e) => e.to === to);
  return /\/a\/([A-Za-z0-9_-]{43})\?s=going/.exec(email?.text ?? '')?.[1] ?? '';
};

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with npm run emulators:test');
});

beforeEach(async () => {
  outbox.length = 0;
  refused.clear();
  broken.clear();
  const project = process.env.GCLOUD_PROJECT ?? 'demo-battleplan';
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  expect(res.ok).toBe(true);
  await db().collection(Collections.groups).doc(G).set({ name: 'Thunder', kind: 'team', status: 'active', settings: { allowMaybe: true } });
  await person('coach', 'Andy Bernard', 'owner');
  await person('maria', 'Maria Ruiz');
  await person('dan', 'Dan Ruiz');
  await person('sam', 'Sam Lee');
  await person('pat', 'Pat Kim');
  await person('gone', 'Gone Person', 'member', { status: 'disabled' });
  // Emma and Liam are Maria's; Dan is Emma's guardian too. Sam plays.
  // Ava has nobody linked. Liam has answered already.
  await player('emma', 'Emma Ruiz', [['maria', 'guardian'], ['dan', 'guardian'], ['gone', 'guardian']]);
  await player('liam', 'Liam Ruiz', [['maria', 'guardian']]);
  await player('sam-p', 'Sam Lee', [['sam', 'self']]);
  await player('ava', 'Ava Park', []);
  await player('newbie', 'New Kid', [['pat', 'guardian']], { status: 'pending' });
  await game('game');
  await db().collection(Collections.rsvps).doc('game_liam').set({ eventId: 'game', groupId: G, participantId: 'liam', status: 'going' });
});

describe("Email people who haven't RSVP'd", () => {
  it('counts first, then emails each person once, about their players', async () => {
    expect(await send('coach', 'game', true)).toEqual({ people: 3, players: 2, unreachable: 1, failed: 0, skipped: 0 });
    expect(outbox).toHaveLength(0);
    expect((await db().collection(Collections.answerLinks).get()).size).toBe(0);

    expect(await send('coach')).toEqual({ people: 3, players: 2, unreachable: 1, failed: 0, skipped: 0 });
    expect(outbox.map((e) => e.to).sort()).toEqual(['dan@example.com', 'maria@example.com', 'sam@example.com']);
    const maria = outbox.find((e) => e.to === 'maria@example.com')!;
    expect(maria.subject).toMatch(/^Thunder: RSVP for vs\. Eagles, \w{3}, \w{3} \d+ at \d+:\d\d [AP]M$/);
    expect(maria.text).toContain('Is Emma going?');
    expect(maria.text).toContain("Andy Bernard sent this to everyone who hasn't RSVP'd.");
    expect(outbox.find((e) => e.to === 'sam@example.com')!.text).toContain('Are you going?');
    // The links are kept hashed, never the token itself.
    const links = await db().collection(Collections.answerLinks).get();
    expect(links.size).toBe(3);
    expect(links.docs.map((d) => d.id)).toContain(answerLinkId(tokenFor('maria@example.com')));
    expect(links.docs.every((d) => (d.get('expiresAt') as Timestamp).toMillis() === NOW + 2 * 24 * HOUR)).toBe(true);
  });

  it('emails each person once a week per event, counting first too', async () => {
    await game('later', { startAt: Timestamp.fromMillis(NOW + 30 * 24 * HOUR), endAt: Timestamp.fromMillis(NOW + 30 * 24 * HOUR + HOUR) });
    const coach = { uid: 'coach', superAdmin: false };
    await emailService('later', coach, false, NOW);
    const thisWeek = { code: 'resource-exhausted', message: 'emailed-this-week' };
    await expect(emailService('later', coach, true, NOW + HOUR)).rejects.toMatchObject(thisWeek);
    await expect(emailService('later', coach, false, NOW + 6 * 24 * HOUR)).rejects.toMatchObject(thisWeek);
    // Someone new to email that week gets theirs; the others don't again.
    await person('kim', 'Kim Park');
    await player('ava', 'Ava Park', [['kim', 'guardian']]);
    outbox.length = 0;
    expect((await emailService('later', coach, false, NOW + 2 * HOUR)).people).toBe(1);
    expect(outbox.map((e) => e.to)).toEqual(['kim@example.com']);
    // A week after each person's email, they're due again: Kim, emailed later, a little after the rest.
    expect((await emailService('later', coach, false, NOW + 7 * 24 * HOUR)).people).toBe(3);
    expect((await emailService('later', coach, false, NOW + 7 * 24 * HOUR + 2 * HOUR)).people).toBe(1);
  });

  it("an email that didn't send doesn't count: they can be emailed again, and the limits get it back", async () => {
    const coach = { uid: 'coach', superAdmin: false };
    refused.add('maria@example.com');
    expect(await emailService('game', coach, false, NOW)).toMatchObject({ people: 3, failed: 1 });
    const day = new Date(NOW).toISOString().slice(0, 10);
    const counter = (key: string) => db().collection(Collections.rateLimits).doc(`${key}_rsvpEmail_${day}`).get();
    expect((await counter(G)).get('count')).toBe(2);
    expect((await counter('all')).get('count')).toBe(2);
    refused.clear();
    outbox.length = 0;
    expect(await emailService('game', coach, false, NOW + HOUR)).toMatchObject({ people: 1, failed: 0 });
    expect(outbox.map((e) => e.to)).toEqual(['maria@example.com']);
  });

  it('a send that throws is a failure too, and given back', async () => {
    const coach = { uid: 'coach', superAdmin: false };
    broken.add('dan@example.com');
    expect(await emailService('game', coach, false, NOW)).toMatchObject({ people: 3, failed: 1 });
    broken.clear();
    outbox.length = 0;
    expect(await emailService('game', coach, false, NOW + HOUR)).toMatchObject({ people: 1 });
    expect(outbox.map((e) => e.to)).toEqual(['dan@example.com']);
  });

  it("keeps a week's record from before per-person times", async () => {
    const coach = { uid: 'coach', superAdmin: false };
    // As the first version wrote it: one start, and who was emailed.
    await db().collection(Collections.rateLimits).doc('game_eventRsvpEmail_week').set({
      firstAt: Timestamp.fromMillis(NOW - 24 * HOUR),
      emailed: ['maria', 'dan'],
    });
    expect(await emailService('game', coach, false, NOW)).toMatchObject({ people: 1 });
    expect(outbox.map((e) => e.to)).toEqual(['sam@example.com']);
    await expect(emailService('game', coach, false, NOW + HOUR)).rejects.toMatchObject({ message: 'emailed-this-week' });
  });

  it("15 a day per team and 80 in all; the rest go another day (SCHED-14)", async () => {
    const coach = { uid: 'coach', superAdmin: false };
    const day = (ms: number) => new Date(ms).toISOString().slice(0, 10);
    const counter = (key: string, ms = NOW) => db().collection(Collections.rateLimits).doc(`${key}_rsvpEmail_${day(ms)}`);
    await counter(G).set({ count: 14 });
    expect(await emailService('game', coach, true, NOW)).toMatchObject({ people: 1, skipped: 2 });
    expect(await emailService('game', coach, false, NOW)).toMatchObject({ people: 1, skipped: 2 });
    expect(outbox).toHaveLength(1);
    expect((await counter(G).get()).get('count')).toBe(15);
    expect((await counter('all').get()).get('count')).toBe(1);
    const limit = { code: 'resource-exhausted', message: 'email-limit' };
    await expect(emailService('game', coach, true, NOW)).rejects.toMatchObject(limit);
    await expect(emailService('game', coach, false, NOW)).rejects.toMatchObject(limit);
    // Tomorrow, the two left out, and only them.
    const tomorrow = NOW + 24 * HOUR;
    await counter('all', tomorrow).set({ count: 79 });
    expect(await emailService('game', coach, false, tomorrow)).toMatchObject({ people: 1, skipped: 1 });
    await expect(emailService('game', coach, false, tomorrow)).rejects.toMatchObject(limit);
    await counter('all', tomorrow).set({ count: 0 });
    expect(await emailService('game', coach, false, tomorrow)).toMatchObject({ people: 1, skipped: 0 });
    expect(new Set(outbox.map((e) => e.to)).size).toBe(3);
    await expect(emailService('game', coach, false, tomorrow)).rejects.toMatchObject({ message: 'emailed-this-week' });
  });

  it('is for team admins and whoever made the event', async () => {
    await expect(send('pat')).rejects.toMatchObject({ code: 'permission-denied' });
    await game('pats', { createdBy: 'pat' });
    expect((await send('pat', 'pats', true)).people).toBe(3);
  });

  it('not on a canceled or started event, or after the deadline', async () => {
    await game('canceled', { canceledAt: Timestamp.now() });
    await expect(send('coach', 'canceled')).rejects.toMatchObject({ code: 'failed-precondition' });
    await game('started', { startAt: Timestamp.fromMillis(NOW - HOUR) });
    await expect(send('coach', 'started')).rejects.toMatchObject({ code: 'failed-precondition' });
    await game('closed', { rsvpDeadline: Timestamp.fromMillis(NOW - HOUR) });
    await expect(send('coach', 'closed')).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('links expire at the deadline when it comes first', async () => {
    await game('early', { rsvpDeadline: Timestamp.fromMillis(NOW + 3 * HOUR) });
    await send('coach', 'early');
    const links = await db().collection(Collections.answerLinks).get();
    expect(links.docs.every((d) => (d.get('expiresAt') as Timestamp).toMillis() === NOW + 3 * HOUR)).toBe(true);
  });
});

describe('the answer page', () => {
  it('shows the tapped answer, and saves only on Send', async () => {
    await send('coach');
    const token = tokenFor('maria@example.com');
    const shown = await answerPage(`/a/${token}`, 'GET', { s: 'going' }, {});
    expect(shown.status).toBe(200);
    expect(shown.html).toContain('Is Emma going?');
    expect(shown.html).toContain('name="status-0" value="going" required checked');
    expect(shown.html).toContain('Answering as Maria Ruiz.');
    expect((await rsvp('game', 'emma')).exists).toBe(false);

    const sent = await answerPage(`/a/${token}`, 'POST', {}, { 'status-0': 'maybe', 'note-0': '  Late from school ' });
    expect(sent.status).toBe(200);
    expect(sent.html).toContain('Thanks! Emma might go.');
    const saved = (await rsvp('game', 'emma')).data()!;
    expect(saved).toMatchObject({
      eventId: 'game',
      groupId: G,
      participantType: 'player',
      participantId: 'emma',
      participantName: 'Emma Ruiz',
      status: 'maybe',
      note: 'Late from school',
      guests: 0,
      respondedBy: 'maria',
    });
    // Changed from the same link.
    await answerPage(`/a/${token}`, 'POST', {}, { 'status-0': 'not_going', 'note-0': 'Late from school' });
    expect((await rsvp('game', 'emma')).get('status')).toBe('not_going');
    // Opened again, it shows the saved answer and note.
    const again = await answerPage(`/a/${token}`, 'GET', {}, {});
    expect(again.html).toContain('name="status-0" value="not_going" required checked');
    expect(again.html).toContain('>Late from school</textarea>');
    // Send with nothing picked saves nothing, and says so.
    const empty = await answerPage(`/a/${token}`, 'POST', {}, {});
    expect(empty.status).toBe(400);
    expect(empty.html).toContain('Pick an answer, then Send.');
    expect((await rsvp('game', 'emma')).get('status')).toBe('not_going');
  });

  it("asks about each of a guardian's players on their own, and answers each alone (PLAYER-11)", async () => {
    await db().collection(Collections.rsvps).doc('game_liam').delete();
    await send('coach');
    const email = outbox.find((e) => e.to === 'maria@example.com')!;
    expect(email.text).toContain('Is Emma going?');
    expect(email.text).toContain('Is Liam going?');
    expect(email.text).not.toContain('Emma and Liam');
    const token = tokenFor('maria@example.com');
    expect(email.text).toContain(`/a/${token}?s=going&p=0`);
    expect(email.text).toContain(`/a/${token}?s=not_going&p=1`);

    // Liam's Not going picks Liam's alone.
    const shown = await answerPage(`/a/${token}`, 'GET', { s: 'not_going', p: '1' }, {});
    expect(shown.html).toContain('<legend>Is Emma going?</legend>');
    expect(shown.html).toContain('<legend>Is Liam going?</legend>');
    expect(shown.html).toContain('name="status-1" value="not_going" checked');
    expect(shown.html).not.toMatch(/name="status-0" value="\w+" checked/);
    expect(shown.html).not.toContain(' required');

    // Sent with only Liam's answer: Liam's is saved, Emma's left alone.
    const sent = await answerPage(`/a/${token}`, 'POST', {}, { 'status-1': 'not_going', 'note-1': ' Sick ', 'note-0': '' });
    expect(sent.status).toBe(200);
    expect(sent.html).toContain('Thanks! Liam isn&#39;t going.');
    expect((await rsvp('game', 'liam')).data()).toMatchObject({ status: 'not_going', note: 'Sick', respondedBy: 'maria' });
    expect((await rsvp('game', 'emma')).exists).toBe(false);

    // Each with their own answer.
    const both = await answerPage(`/a/${token}`, 'POST', {}, { 'status-0': 'going', 'status-1': 'maybe', 'note-1': 'Sick' });
    expect(both.html).toContain('Thanks! Emma is going. Liam might go.');
    expect((await rsvp('game', 'emma')).get('status')).toBe('going');
    expect((await rsvp('game', 'liam')).data()).toMatchObject({ status: 'maybe', note: 'Sick' });

    // Opened again, each shows their own saved answer and note.
    const again = await answerPage(`/a/${token}`, 'GET', {}, {});
    expect(again.html).toContain('name="status-0" value="going" checked');
    expect(again.html).toContain('name="status-1" value="maybe" checked');
    expect(again.html).toContain('>Sick</textarea>');

    // Nothing picked saves nothing.
    const empty = await answerPage(`/a/${token}`, 'POST', {}, { 'note-0': 'x' });
    expect(empty.status).toBe(400);
    expect(empty.html).toContain('Pick an answer for at least one of them, then Send.');
    expect((await rsvp('game', 'emma')).get('note')).toBe('');
  });

  it('answers for a player who is the person', async () => {
    await send('coach');
    await answerPage(`/a/${tokenFor('sam@example.com')}`, 'POST', {}, { 'status-0': 'going' });
    expect((await rsvp('game', 'sam-p')).get('respondedBy')).toBe('sam');
  });

  it('takes only the answers the team allows', async () => {
    await send('coach');
    await db().collection(Collections.groups).doc(G).update({ 'settings.allowMaybe': false });
    const token = tokenFor('dan@example.com');
    expect((await answerPage(`/a/${token}`, 'GET', { s: 'maybe' }, {})).html).not.toContain('value="maybe"');
    expect((await answerPage(`/a/${token}`, 'POST', {}, { 'status-0': 'maybe' })).status).toBe(400);
    expect((await rsvp('game', 'emma')).exists).toBe(false);
  });

  it('stops for a link that is unknown, late, canceled, or no longer theirs', async () => {
    await send('coach');
    const token = tokenFor('maria@example.com');
    expect((await answerPage(`/a/${'A'.repeat(43)}`, 'GET', {}, {})).status).toBe(404);
    expect((await answerPage(`/a/${token}`, 'GET', {}, {}, NOW + 3 * 24 * HOUR)).status).toBe(410);

    await db().collection(Collections.events).doc('game').update({ rsvpDeadline: Timestamp.fromMillis(NOW - 1000) });
    expect((await answerPage(`/a/${token}`, 'POST', {}, { 'status-0': 'going' })).status).toBe(410);
    await db().collection(Collections.events).doc('game').update({ rsvpDeadline: null, canceledAt: Timestamp.now() });
    const canceled = await answerPage(`/a/${token}`, 'GET', {}, {});
    expect(canceled.status).toBe(410);
    expect(canceled.html).toContain('This event was canceled');

    await db().collection(Collections.events).doc('game').update({ canceledAt: null });
    await db().collection(Collections.playerGuardians).doc(groupMemberId('emma', 'maria')).delete();
    const unlinked = await answerPage(`/a/${token}`, 'POST', {}, { 'status-0': 'going' });
    expect(unlinked.status).toBe(403);
    expect((await rsvp('game', 'emma')).exists).toBe(false);
  });

  it('slows down after many tries', async () => {
    await send('coach');
    const token = tokenFor('dan@example.com');
    for (let i = 0; i < 20; i++) {
      expect((await answerPage(`/a/${token}`, 'POST', {}, { 'status-0': 'going' })).status).toBe(200);
    }
    expect((await answerPage(`/a/${token}`, 'POST', {}, { 'status-0': 'going' })).status).toBe(429);
  });

  it('serves the page privately, and only to GET and POST', async () => {
    await send('coach');
    const token = tokenFor('maria@example.com');
    const reply = async (method: string, body: object = {}) => {
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
        send(text: string) {
          out.body = text;
          return res;
        },
      };
      await (pageHandler as unknown as (req: object, res: object) => Promise<void>)(
        { method, path: `/a/${token}`, query: { s: 'going' }, body },
        res,
      );
      return out;
    };
    const page = await reply('GET');
    expect(page.status).toBe(200);
    expect(page.headers['content-type']).toBe('text/html; charset=utf-8');
    expect(page.headers['cache-control']).toBe('no-store');
    expect(page.headers['referrer-policy']).toBe('no-referrer');
    expect(page.headers['content-security-policy']).toContain("default-src 'none'");
    expect(page.body).toContain('Is Emma going?');
    expect((await reply('POST', { 'status-0': 'going' })).body).toContain('Thanks! Emma is going.');
    expect((await reply('DELETE')).status).toBe(405);
  });
});
