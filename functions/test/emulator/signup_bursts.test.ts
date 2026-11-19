// Sign-up spikes and Google Play's test accounts (ADMIN-9, #52): one email
// to super admins when 10 sign-ups finish within an hour, then none for 6
// hours; admin-added and likely Play test accounts don't count, and a Play
// test account's new-account email says what it is. Run with
// `npm run emulators:test`.
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { findOrProvisionUser } from '../../src/accounts/service.js';
import { ensureUserProfile } from '../../src/accounts/handlers.js';
import { noteSignUp, SPIKE_QUIET_MS, SPIKE_WINDOW_MS } from '../../src/admin/signup_bursts.js';
import type { Email } from '../../src/email/service.js';
import { auth, db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';

const mail = vi.hoisted(() => ({ sent: [] as Email[], fail: false }));
vi.mock('../../src/email/service.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/email/service.js')>()),
  sendEmail: async (email: Email) => {
    if (mail.fail) throw new Error('mail is down');
    mail.sent.push(email);
    return true;
  },
}));

const project = () => process.env.GCLOUD_PROJECT ?? 'demo-battleplan';

type Callable = { run: (request: never) => Promise<unknown> };
const run = (fn: Callable, uid: string, data: object = {}) =>
  fn.run({ data, auth: { uid, token: { email_verified: true } }, rawRequest: { ip: '1.2.3.4' } } as never);

/** Spike emails to the super admin. */
const spikes = () => mail.sent.filter((m) => m.to === 'root@example.com' && m.subject.startsWith('Sign-up spike'));

/** Someone makes an account and finishes setup. */
async function signUp(uid: string, email = `${uid}@example.com`, name = `Person ${uid}`): Promise<void> {
  await auth().createUser({ uid, email, password: 'longenough', emailVerified: true });
  await run(ensureUserProfile, uid, { setup: { displayName: name, confirmAdult: true, acceptTerms: true } });
}

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error('Run with npm run emulators:test');
  }
});

beforeEach(async () => {
  const clear = async (url: string) => expect((await fetch(url, { method: 'DELETE' })).ok).toBe(true);
  await clear(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project()}/databases/(default)/documents`);
  await clear(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${project()}/accounts`);
  mail.sent.length = 0;
  mail.fail = false;
  await auth().createUser({ uid: 'root', email: 'root@example.com', emailVerified: true });
  await auth().setCustomUserClaims('root', { superAdmin: true });
  await db().collection(Collections.users).doc('root').set({ displayName: 'Root', status: 'active', superAdmin: true });
});

describe("Google Play's test accounts (#52)", () => {
  it('get a labeled new-account email, and nothing else changes', async () => {
    await signUp('jane', 'jane.48213@gmail.com', 'Jane Doe');
    const alerts = mail.sent.filter((m) => m.to === 'root@example.com');
    expect(alerts.map((m) => m.subject)).toEqual(['New account (likely Google Play test): Jane Doe']);
    expect(alerts[0].text).toContain("This looks like one of Google Play's test accounts");
    // A normal account like any other.
    const user = await db().collection(Collections.users).doc('jane').get();
    expect(user.get('displayName')).toBe('Jane Doe');
    expect((await auth().getUser('jane')).disabled).toBe(false);
  });
});

describe('sign-up spikes (ADMIN-9, #52)', () => {
  it('emails super admins once when 10 finish setup within an hour', async () => {
    for (let i = 1; i <= 9; i++) await signUp(`u${i}`);
    expect(spikes()).toEqual([]);
    await signUp('u10');
    expect(spikes().map((m) => m.subject)).toEqual(['Sign-up spike: 10 new accounts in the last hour']);
    const text = spikes()[0].text;
    expect(text).toContain('Person u10 (u10@example.com)');
    expect(text).toContain('Person u1 (u1@example.com)');
    expect(text).toContain('/admin/users');
    // An 11th, and more: not again.
    await signUp('u11');
    await signUp('u12');
    expect(spikes()).toHaveLength(1);
  });

  it("doesn't count accounts an admin added or Google Play's test accounts", async () => {
    for (let i = 1; i <= 9; i++) await signUp(`u${i}`);
    for (let i = 1; i <= 3; i++) {
      const added = await findOrProvisionUser(`added${i}@example.com`, `Added ${i}`);
      await run(ensureUserProfile, added.uid, { setup: { displayName: `Added ${i}`, confirmAdult: true, acceptTerms: true } });
    }
    await signUp('play1', 'jane.48213@gmail.com');
    await signUp('play2', 'x@cloudtestlabaccounts.com');
    expect(spikes()).toEqual([]);
    await signUp('u10');
    expect(spikes()).toHaveLength(1);
  });

  it('counts only the last hour, and sends again after 6 quiet hours', async () => {
    const t0 = Date.UTC(2030, 0, 1, 9);
    const note = (uid: string, at: number) => noteSignUp({ uid, email: `${uid}@example.com`, addedByAdmin: false }, at);
    const minute = 60 * 1000;
    // Nine in the first minutes, then nine more over an hour later: never
    // ten within an hour, so no spike.
    for (let i = 1; i <= 9; i++) await note(`a${i}`, t0 + i * minute);
    for (let i = 1; i <= 9; i++) await note(`b${i}`, t0 + SPIKE_WINDOW_MS + 10 * minute + i * 1000);
    expect(spikes()).toEqual([]);
    // A tenth within that later hour: a spike.
    const alerted = t0 + SPIKE_WINDOW_MS + 11 * minute;
    await note('b10', alerted);
    expect(spikes().map((m) => m.subject)).toEqual(['Sign-up spike: 10 new accounts in the last hour']);
    // Ten more 5 hours later: still quiet.
    for (let i = 1; i <= 10; i++) await note(`c${i}`, alerted + 5 * 60 * minute + i * 1000);
    expect(spikes()).toHaveLength(1);
    // Six hours after the first email, the next burst sends again, once.
    for (let i = 1; i <= 10; i++) await note(`d${i}`, alerted + SPIKE_QUIET_MS + i * 1000);
    expect(spikes()).toHaveLength(2);
  });

  it('never fails the sign-up when the email does', async () => {
    mail.fail = true;
    for (let i = 1; i <= 10; i++) await signUp(`u${i}`);
    const user = await db().collection(Collections.users).doc('u10').get();
    expect(user.get('adultConfirmedAt')).toBeDefined();
    const counter = await db().collection(Collections.ops).doc('signupBursts').get();
    expect(counter.get('alertedAt')).toBeTypeOf('number');
  });
});
