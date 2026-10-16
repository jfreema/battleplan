// Platform alerts (ADMIN-9): super admins get an email when someone
// finishes signing up and when a team is created or deleted, unless
// Platform settings turn them off. Run with `npm run emulators:test`.
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { findOrProvisionUser } from '../../src/accounts/service.js';
import { ensureUserProfile } from '../../src/accounts/handlers.js';
import { adminDeleteGroup } from '../../src/admin/handlers.js';
import type { Email } from '../../src/email/service.js';
import { auth, db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { createGroup, deleteGroup } from '../../src/teams/handlers.js';

const mail = vi.hoisted(() => ({ sent: [] as Email[] }));
vi.mock('../../src/email/service.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/email/service.js')>()),
  sendEmail: async (email: Email) => {
    mail.sent.push(email);
    return true;
  },
}));
vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({ sendEach: async () => ({ responses: [], successCount: 0, failureCount: 0 }) }),
}));

const project = () => process.env.GCLOUD_PROJECT ?? 'demo-battleplan';

type Callable = { run: (request: never) => Promise<unknown> };
const run = <T = Record<string, unknown>>(fn: Callable, uid: string, data: object = {}, token: object = {}) =>
  fn.run({ data, auth: { uid, token: { email_verified: true, ...token } }, rawRequest: { ip: '1.2.3.4' } } as never) as Promise<T>;

/** Alerts to super admins, apart from the people's own emails. */
const alerts = () => mail.sent.filter((m) => m.to === 'root@example.com');
const setup = { displayName: 'Pat Lee', confirmAdult: true, acceptTerms: true };

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
  // root is the super admin who hears about it all.
  await auth().createUser({ uid: 'root', email: 'root@example.com', emailVerified: true });
  await auth().setCustomUserClaims('root', { superAdmin: true });
  await db().collection(Collections.users).doc('root').set({ displayName: 'Root', status: 'active', superAdmin: true });
  // pat signs up with an email and a password.
  await auth().createUser({ uid: 'pat', email: 'pat@example.com', password: 'longenough', emailVerified: true });
});

describe('a new account (ADMIN-9)', () => {
  it('emails super admins once, when setup is finished', async () => {
    await run(ensureUserProfile, 'pat');
    expect(alerts()).toEqual([]);
    await run(ensureUserProfile, 'pat', { setup });
    expect(alerts().map((m) => m.subject)).toEqual(['New account: Pat Lee']);
    expect(alerts()[0].text).toContain('Pat Lee (pat@example.com) finished signing up for Battleplan, with email.');
    expect(alerts()[0].text).toContain('/admin/users/pat');
    expect(alerts()[0].text).not.toContain('A team admin added them');
    // A save sent again isn't another account.
    await run(ensureUserProfile, 'pat', { setup });
    expect(alerts()).toHaveLength(1);
  });

  it('says when a team admin added them first', async () => {
    const kim = await findOrProvisionUser('kim@example.com', 'Kim Park');
    await run(ensureUserProfile, kim.uid);
    await run(ensureUserProfile, kim.uid, { setup: { ...setup, displayName: 'Kim Park' } });
    expect(alerts()).toHaveLength(1);
    expect(alerts()[0].text).toContain('A team admin added them first.');
  });
});

describe('teams (ADMIN-9)', () => {
  const create = async () => {
    await run(ensureUserProfile, 'pat', { setup });
    mail.sent.length = 0;
    const { groupId } = await run<{ groupId: string }>(createGroup, 'pat', {
      name: 'Thunder',
      sport: 'soccer',
      timeZone: 'America/Chicago',
    });
    return groupId;
  };

  it('emails super admins when a team is created and when its owner deletes it', async () => {
    const groupId = await create();
    expect(alerts().map((m) => m.subject)).toEqual(['New team: Thunder']);
    expect(alerts()[0].text).toContain('Pat Lee (pat@example.com) created Thunder, a soccer team.');
    expect(alerts()[0].text).toContain(`/admin/teams/${groupId}`);
    mail.sent.length = 0;
    await run(deleteGroup, 'pat', { groupId, confirmName: 'Thunder' });
    expect(alerts().map((m) => m.subject)).toEqual(['Team deleted: Thunder']);
    expect(alerts()[0].text).toContain('Pat Lee deleted Thunder, which had 1 member.');
    expect(alerts()[0].text).toContain(`/admin/audit?group=${groupId}`);
  });

  it('says when a super admin deleted it', async () => {
    const groupId = await create();
    mail.sent.length = 0;
    await run(adminDeleteGroup, 'root', { groupId, confirmName: 'Thunder' }, { superAdmin: true });
    expect(alerts()[0].text).toContain('Root, a super admin, deleted Thunder');
  });

  it('sends nothing while Platform settings turn the alerts off', async () => {
    await db().collection(Collections.config).doc('app').set({ emailAdminAlerts: false });
    const groupId = await create();
    await run(deleteGroup, 'pat', { groupId, confirmName: 'Thunder' });
    expect(alerts()).toEqual([]);
  });
});
