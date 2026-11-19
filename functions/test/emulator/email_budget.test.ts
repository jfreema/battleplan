// The one daily email budget (ARCH §6.7, #47), against the Firestore and
// Auth emulators with the email provider faked: every email counts toward
// one total per UTC day, bulk emails stop at 70% of the budget so the rest
// is kept for setup links and the like, email invites send what fits, and
// Add people by email adds everyone and says whose setup email waits.
// Run with:
//   npm --prefix functions run emulators:test
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  bulkLimitOf,
  dailyEmailBudget,
  defaultEmailBudget,
  emailBudgetDocId,
  emailRoom,
  emailTier,
  takeEmailSlot,
  type EmailKind,
} from '../../src/email/budget.js';
import { sendEmail, type Email } from '../../src/email/service.js';
import { resendEmailInvite, sendEmailInvites } from '../../src/invites/handlers.js';
import { addMembersByEmail } from '../../src/teams/service.js';
import { db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';

const G = 'thunder';
const realFetch = globalThis.fetch;
/** What reached the provider, by address. */
const delivered: string[] = [];

const mail = (to: string): Email => ({ to, subject: 'Hi', text: 'Hi', html: '<p>Hi</p>' });
const counter = async (now = new Date()) =>
  ((await db().collection(Collections.rateLimits).doc(emailBudgetDocId(now)).get()).get('count') as number | undefined) ??
  0;
const setBudget = (emailsPerDay: number) =>
  db().collection(Collections.config).doc('app').set({ emailsPerDay }, { merge: true });
/** Today's counter at [count], as if that many emails went out already. */
const used = (count: number) =>
  db().collection(Collections.rateLimits).doc(emailBudgetDocId()).set({ count });

type CallRequest = Parameters<typeof sendEmailInvites.run>[0];
const call = <T>(fn: { run: (r: CallRequest) => unknown }, uid: string, data: object) =>
  fn.run({ data, auth: { uid, token: { email_verified: true } }, rawRequest: {} } as unknown as CallRequest) as Promise<T>;

beforeAll(() => {
  // Never point these tests at a real project.
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with npm run emulators:test');
  // A key, so sendEmail really sends, to a provider that accepts all.
  process.env.RESEND_API_KEY = 're_test';
  vi.stubGlobal('fetch', async (url: string | URL | Request, init?: RequestInit) => {
    if (String(url).startsWith('https://api.resend.com/')) {
      delivered.push((JSON.parse(String(init?.body)) as { to: string }).to);
      return new Response('{"id":"x"}', { status: 200 });
    }
    return realFetch(url, init);
  });
});

afterAll(() => {
  delete process.env.RESEND_API_KEY;
  vi.unstubAllGlobals();
});

beforeEach(async () => {
  const project = process.env.GCLOUD_PROJECT ?? 'demo-battleplan';
  const res = await realFetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  expect(res.ok).toBe(true);
  delivered.length = 0;
  delete process.env.FUNCTIONS_EMULATOR;
});

describe('one counter for every email', () => {
  const kinds: EmailKind[] = [
    'setup',
    'accountSetup',
    'passwordReset',
    'securityNotice',
    'superAdminAlert',
    'invite',
    'addedToTeam',
    'rsvpReminder',
  ];

  it('counts every kind toward the same day, on the try', async () => {
    await setBudget(100);
    for (const kind of kinds) expect(await sendEmail(mail(`${kind}@example.com`), kind)).toBe(true);
    expect(await counter()).toBe(kinds.length);
    expect(delivered).toHaveLength(kinds.length);
  });

  it('sorts the kinds into essential and bulk', () => {
    expect(kinds.filter((k) => emailTier(k) === 'bulk')).toEqual(['invite', 'addedToTeam', 'rsvpReminder']);
  });

  it('stops bulk emails at 70%, and essential ones at 100%, counting nothing it refuses', async () => {
    await setBudget(10);
    expect(bulkLimitOf(10)).toBe(7);
    for (let i = 0; i < 7; i++) expect(await sendEmail(mail(`i${i}@example.com`), 'invite')).toBe(true);
    // Bulk is full; the reserve is for setup links and the like.
    expect(await sendEmail(mail('late@example.com'), 'rsvpReminder')).toBe(false);
    expect(await emailRoom('bulk')).toBe(0);
    expect(await emailRoom('essential')).toBe(3);
    for (let i = 0; i < 3; i++) expect(await sendEmail(mail(`s${i}@example.com`), 'setup')).toBe(true);
    // The day is full: nothing more goes out, and nothing more is counted.
    expect(await sendEmail(mail('reset@example.com'), 'passwordReset')).toBe(false);
    expect(await counter()).toBe(10);
    expect(delivered).toHaveLength(10);
  });

  it('keeps a counter per UTC day', async () => {
    await setBudget(1);
    const monday = new Date('2026-11-16T23:59:00Z');
    const tuesday = new Date('2026-11-17T00:01:00Z');
    expect(await takeEmailSlot('setup', monday)).toBe(true);
    expect(await takeEmailSlot('setup', monday)).toBe(false);
    expect(await takeEmailSlot('setup', tuesday)).toBe(true);
    expect(await counter(monday)).toBe(1);
    expect(await counter(tuesday)).toBe(1);
  });

  it("doesn't count on the emulators, which send nothing", async () => {
    process.env.FUNCTIONS_EMULATOR = 'true';
    expect(await sendEmail(mail('a@example.com'), 'setup')).toBe(false);
    expect(await counter()).toBe(0);
    expect(delivered).toHaveLength(0);
  });

  it('takes the budget from Platform settings, else 90 in prod and 10 in dev', async () => {
    expect(defaultEmailBudget('battleplan-prod')).toBe(90);
    expect(defaultEmailBudget('battleplan-dev-ecce4')).toBe(10);
    expect(await dailyEmailBudget()).toBe(10);
    await setBudget(250);
    expect(await dailyEmailBudget()).toBe(250);
    // Nothing sensible set: the default.
    await setBudget(0);
    expect(await dailyEmailBudget()).toBe(10);
  });
});

describe('where people send email', () => {
  beforeEach(async () => {
    await db().collection(Collections.groups).doc(G).set({ name: 'Thunder', settings: {} });
    await db().collection(Collections.groupMembers).doc(groupMemberId(G, 'coach')).set({
      groupId: G,
      uid: 'coach',
      role: 'owner',
      displayName: 'Coach Kim',
    });
    await db().collection(Collections.users).doc('coach').set({ displayName: 'Coach Kim', status: 'active' });
    await setBudget(10);
  });

  it('email invites send what fits and give back the rest, uncounted', async () => {
    await used(5); // bulk room: 7 - 5 = 2
    const emails = ['a@example.com', 'b@example.com', 'c@example.com', 'd@example.com'];
    const result = await call<{ invited: number; sent: number; notSent: string[] }>(sendEmailInvites, 'coach', {
      groupId: G,
      emails,
    });
    expect(result).toEqual({ invited: 2, sent: 2, notSent: ['c@example.com', 'd@example.com'] });
    expect(delivered).toEqual(['a@example.com', 'b@example.com']);
    // Only the invites that went out were made.
    const invites = await db().collection(Collections.invites).where('groupId', '==', G).get();
    expect(invites.docs.map((d) => d.get('email')).sort()).toEqual(['a@example.com', 'b@example.com']);
  });

  it('with no room, sends nothing and makes nothing', async () => {
    await used(7);
    const result = await call<{ invited: number; sent: number; notSent: string[] }>(sendEmailInvites, 'coach', {
      groupId: G,
      emails: ['a@example.com'],
    });
    expect(result).toEqual({ invited: 0, sent: 0, notSent: ['a@example.com'] });
    expect(delivered).toHaveLength(0);
    expect((await db().collection(Collections.invites).get()).size).toBe(0);
  });

  it('a resent invite past the limit says so', async () => {
    await call(sendEmailInvites, 'coach', { groupId: G, emails: ['a@example.com'] });
    const code = (await db().collection(Collections.invites).get()).docs[0].id;
    await used(7);
    await expect(call(resendEmailInvite, 'coach', { code })).rejects.toThrow('email-limit');
  });

  it('Add people by email adds everyone, and lists the setup emails the day had no room for', async () => {
    await used(9); // one essential email left
    const result = await addMembersByEmail(G, { uid: 'coach', name: 'Coach Kim' }, [
      { name: 'Ann Lee', email: 'ann.budget@example.com' },
      { name: 'Bo Diaz', email: 'bo.budget@example.com' },
    ]);
    expect(result.invited).toBe(2);
    expect(result.emailFailed).toEqual(['bo.budget@example.com']);
    expect(result.emailLimited).toEqual(['bo.budget@example.com']);
    expect(delivered).toEqual(['ann.budget@example.com']);
    // Both are on the team, waiting to set up their accounts.
    const members = await db().collection(Collections.groupMembers).where('groupId', '==', G).get();
    expect(members.size).toBe(3);
  });
});
