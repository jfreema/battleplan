// The abuse limits beyond the documented actions (SAFE-5, ARCH §6.9): web
// error reports by IP address, security notices per person, the day's cap
// on super-admin email, and the newest few profile photos per person. Run
// with `npm run emulators:test`.
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { pruneAvatars, recordSignInMethodChange } from '../../src/accounts/service.js';
import type { Email } from '../../src/email/service.js';
import { emailSuperAdmins } from '../../src/email/super_admins.js';
import { logClientError } from '../../src/ops/handlers.js';
import { auth, db, storage } from '../../src/shared/admin.js';
import { Collections, Limits } from '../../src/shared/constants.js';

const mail = vi.hoisted(() => ({ sent: [] as Email[] }));
vi.mock('../../src/email/service.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/email/service.js')>()),
  sendEmail: async (email: Email) => {
    mail.sent.push(email);
    return true;
  },
}));
const logged = vi.hoisted(() => ({ errors: 0 }));
vi.mock('../../src/ops/service.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/ops/service.js')>()),
  recordClientError: () => {
    logged.errors++;
  },
}));

const project = () => process.env.GCLOUD_PROJECT ?? 'demo-battleplan';
const tick = () => new Promise((r) => setTimeout(r, 15));

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
  logged.errors = 0;
});

describe('web error reports (SAFE-5)', () => {
  const report = (ip: string) =>
    logClientError.run({ data: { message: 'Boom' }, rawRequest: { ip } } as never) as Promise<{ ok: boolean }>;

  it('take 30 an hour from one address, then drop the rest quietly', async () => {
    for (let i = 0; i < Limits.clientErrorsPerIpPerHour; i++) await report('1.2.3.4');
    expect(logged.errors).toBe(Limits.clientErrorsPerIpPerHour);
    await expect(report('1.2.3.4')).resolves.toEqual({ ok: true });
    expect(logged.errors).toBe(Limits.clientErrorsPerIpPerHour);
    // Another address has its own.
    await report('5.6.7.8');
    expect(logged.errors).toBe(Limits.clientErrorsPerIpPerHour + 1);
  });
});

describe('security notices (SAFE-5)', () => {
  it('email 10 a day per person, and still record the change', async () => {
    await auth().createUser({ uid: 'pat', email: 'pat@example.com', password: 'longenough' });
    await db().collection(Collections.users).doc('pat').set({ email: 'pat@example.com', signInMethods: ['password'] });
    for (let i = 0; i < Limits.securityNoticesPerUserPerDay + 3; i++) await recordSignInMethodChange('pat', true);
    expect(mail.sent).toHaveLength(Limits.securityNoticesPerUserPerDay);
  });
});

describe('super-admin email (SAFE-5)', () => {
  it('sends at most 50 alerts a day, all kinds together', async () => {
    await auth().createUser({ uid: 'root', email: 'root@example.com' });
    await auth().setCustomUserClaims('root', { superAdmin: true });
    await db().collection(Collections.users).doc('root').set({ superAdmin: true });
    const alert = (i: number) => emailSuperAdmins('test', (to) => ({ to, subject: `Alert ${i}`, text: '', html: '' }));
    for (let i = 0; i < Limits.superAdminEmailsPerDay + 5; i++) await alert(i);
    expect(mail.sent).toHaveLength(Limits.superAdminEmailsPerDay);
  });
});

describe('profile photos (SAFE-5)', () => {
  it('keep the newest three and the one the profile uses', async () => {
    const bucket = storage().bucket();
    const names = ['a', 'b', 'c', 'd', 'e'].map((n) => `users/pat/avatar/${n}.jpg`);
    for (const name of names) {
      await bucket.file(name).save(Buffer.from('jpg'), { contentType: 'image/jpeg' });
      await tick();
    }
    await db().collection(Collections.users).doc('pat').set({ photoPath: names[0] });
    expect(await pruneAvatars(names[4])).toBe(1);
    const [left] = await bucket.getFiles({ prefix: 'users/pat/avatar/' });
    expect(left.map((f) => f.name).sort()).toEqual([names[0], names[2], names[3], names[4]]);
    // Someone else's files, and team files, are left alone.
    expect(await pruneAvatars('groups/g/avatar/logo.jpg')).toBe(0);
  });
});
