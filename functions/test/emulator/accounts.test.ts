// Accounts (SPEC §6.1): the contact email following a verified change
// (AUTH-8, AUTH-12), security notices (AUTH-7), the sign-in choice for
// added accounts (AUTH-6), signing out everywhere at once (AUTH-9), the
// owner's pick of a new owner (AUTH-10), and verified email for adding
// guardians by email (AUTH-3). Runs against the Auth, Firestore, and
// Storage emulators with email faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import * as accounts from '../../src/accounts/handlers.js';
import { deleteAccount, findOrProvisionUser, signOutEverywhere } from '../../src/accounts/service.js';
import type { Email } from '../../src/email/service.js';
import { addPlayers, inviteGuardian } from '../../src/players/handlers.js';
import { auth, db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';

// Email stand-in: records every email instead of sending it.
const mail = vi.hoisted(() => ({ sent: [] as Email[] }));
vi.mock('../../src/email/service.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/email/service.js')>()),
  sendEmail: async (email: Email) => {
    mail.sent.push(email);
    return true;
  },
}));

const project = () => process.env.GCLOUD_PROJECT ?? 'demo-battleplan';

type Callable = { run: (request: never) => Promise<unknown> };
/** Runs [fn] as [uid], with [token] claims. */
const run = <T = Record<string, unknown>>(fn: Callable, uid: string, data: object = {}, token: object = {}) =>
  fn.run({ data, auth: { uid, token }, rawRequest: {} } as never) as Promise<T>;

const users = () => db().collection(Collections.users);
const profile = async (uid: string) => (await users().doc(uid).get()).data() ?? {};

/** An account in Auth and its finished profile. */
async function person(uid: string, extra: object = {}): Promise<void> {
  const email = `${uid}@example.com`;
  await auth().createUser({ uid, email, password: 'longenough', displayName: uid, emailVerified: true });
  await users().doc(uid).set({
    displayName: uid,
    displayNameLower: uid,
    email,
    emailLower: email,
    photoPath: null,
    status: 'active',
    signInMethods: ['password'],
    notificationPrefs: {},
    adultConfirmedAt: Timestamp.now(),
    acceptedTermsAt: Timestamp.now(),
    createdAt: Timestamp.now(),
    ...extra,
  });
}

async function member(groupId: string, uid: string, role: string, joinedDaysAgo: number): Promise<void> {
  await db().collection(Collections.groupMembers).doc(`${groupId}_${uid}`).set({
    groupId,
    uid,
    role,
    displayName: uid,
    photoPath: null,
    joinedAt: Timestamp.fromMillis(Date.now() - joinedDaysAgo * 86_400_000),
  });
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
});

describe('the contact email follows a verified change (AUTH-8, AUTH-12)', () => {
  it('updates users.email and tells the old and new addresses', async () => {
    await person('sam');
    await auth().updateUser('sam', { email: 'sam.new@example.com', emailVerified: true });
    await run(accounts.ensureUserProfile, 'sam');
    const p = await profile('sam');
    expect(p.email).toBe('sam.new@example.com');
    expect(p.emailLower).toBe('sam.new@example.com');
    expect(mail.sent.map((m) => m.to).sort()).toEqual(['sam.new@example.com', 'sam@example.com']);
    expect(mail.sent[0].text).toContain('was changed to sam.new@example.com');

    // Once in step, signing in again sends nothing more.
    await run(accounts.ensureUserProfile, 'sam');
    expect(mail.sent).toHaveLength(2);
  });

  it('ignores an unverified email', async () => {
    await person('sam');
    await auth().updateUser('sam', { email: 'other@example.com', emailVerified: false });
    await run(accounts.ensureUserProfile, 'sam');
    expect((await profile('sam')).email).toBe('sam@example.com');
    expect(mail.sent).toHaveLength(0);
  });
});

describe('security notices (AUTH-7)', () => {
  it('a password change emails a notice even though the methods stay', async () => {
    await person('sam');
    await run(accounts.recordSignInMethodChange, 'sam', { passwordChanged: true });
    expect(mail.sent).toHaveLength(1);
    expect(mail.sent[0].to).toBe('sam@example.com');
    expect(mail.sent[0].text).toContain('password for your Battleplan account was changed');
  });

  it('nothing changed, nothing sent', async () => {
    await person('sam');
    await run(accounts.recordSignInMethodChange, 'sam');
    expect(mail.sent).toHaveLength(0);
  });
});

describe('added accounts choose how to sign in next time (AUTH-6)', () => {
  it('asks after the setup link, until they choose', async () => {
    const lee = await findOrProvisionUser('lee@example.com', 'Lee Kim');
    expect((await profile(lee.uid)).chooseSignIn).toBe(true);
    // The setup link signs them in and verifies the email.
    await auth().updateUser(lee.uid, { emailVerified: true });
    await run(accounts.ensureUserProfile, lee.uid);
    let p = await profile(lee.uid);
    expect(p.status).toBe('active');
    expect(p.chooseSignIn).toBe(true);
    await run(accounts.ensureUserProfile, lee.uid, { signInChosen: true });
    p = await profile(lee.uid);
    expect(p.chooseSignIn).toBe(false);
  });

  it("Google for the same Gmail address already chose", async () => {
    const lee = await findOrProvisionUser('lee@gmail.com', 'Lee Kim');
    await auth().updateUser(lee.uid, {
      emailVerified: true,
      providerToLink: { providerId: 'google.com', uid: 'google-lee', email: 'lee@gmail.com' },
    });
    await run(accounts.ensureUserProfile, lee.uid);
    expect((await profile(lee.uid)).chooseSignIn).toBe(false);
  });
});

describe('sign out everywhere (AUTH-9)', () => {
  it('stamps sessionsRevokedAt, which every signed-in app watches', async () => {
    await person('sam');
    const before = Date.now();
    await signOutEverywhere('sam');
    const at = (await profile('sam')).sessionsRevokedAt as Timestamp;
    expect(at.toMillis()).toBeGreaterThanOrEqual(before - 1000);
  });

  it("doesn't fail without a profile", async () => {
    await auth().createUser({ uid: 'ghost', email: 'ghost@example.com' });
    await expect(signOutEverywhere('ghost')).resolves.toBeUndefined();
  });

  it('clients cannot set or clear it themselves', async () => {
    // users rules allow only the profile fields (see test/rules/users.test.ts);
    // this checks the server field exists for the app to read.
    await person('sam');
    await run(accounts.signOutEverywhere, 'sam');
    expect((await profile('sam')).sessionsRevokedAt).toBeDefined();
  });
});

describe('deleting an account hands each team to the owner\'s pick (AUTH-10)', () => {
  it('gives the team to the picked member, others to the longest-serving admin', async () => {
    await person('pat');
    for (const g of ['thunder', 'hawks']) {
      await db().collection(Collections.groups).doc(g).set({ name: g, ownerId: 'pat', memberCount: 3, archivedAt: null });
      await member(g, 'pat', 'owner', 30);
      await member(g, 'ana', 'admin', 20);
      await member(g, 'max', 'member', 10);
    }
    await deleteAccount('pat', { thunder: 'max' });
    const owner = async (g: string) => (await db().collection(Collections.groups).doc(g).get()).get('ownerId');
    expect(await owner('thunder')).toBe('max');
    expect(await owner('hawks')).toBe('ana');
    const role = async (id: string) => (await db().collection(Collections.groupMembers).doc(id).get()).get('role');
    expect(await role('thunder_max')).toBe('owner');
  });

  it('the callable takes the picks', async () => {
    await person('pat');
    await db().collection(Collections.groups).doc('thunder').set({ name: 'thunder', ownerId: 'pat', memberCount: 3, archivedAt: null });
    await member('thunder', 'pat', 'owner', 30);
    await member('thunder', 'ana', 'admin', 20);
    await member('thunder', 'max', 'member', 10);
    await run(accounts.deleteAccount, 'pat', { newOwners: { thunder: 'max' } }, { auth_time: Math.floor(Date.now() / 1000) });
    expect((await db().collection(Collections.groups).doc('thunder').get()).get('ownerId')).toBe('max');
  });
});

describe('adding guardians by email needs a verified email (AUTH-3)', () => {
  beforeEach(async () => {
    await person('pat');
    await db().collection(Collections.groups).doc('cubs').set({
      name: 'Cubs', teamType: 'youth', ownerId: 'pat', memberCount: 1, playerCount: 0, archivedAt: null,
    });
    await member('cubs', 'pat', 'owner', 30);
    await db().collection(Collections.players).doc('p1').set({ groupId: 'cubs', name: 'Emma' });
  });

  it('addPlayers with a guardian email', async () => {
    const data = {
      groupId: 'cubs',
      players: [{ name: 'Liam', guardians: [{ name: 'Ana', email: 'ana@example.com' }] }],
    };
    await expect(run(addPlayers, 'pat', data, { email_verified: false })).rejects.toThrow('email-not-verified');
  });

  it('inviteGuardian', async () => {
    const data = { groupId: 'cubs', playerId: 'p1', email: 'ana@example.com' };
    await expect(run(inviteGuardian, 'pat', data, { email_verified: false })).rejects.toThrow('email-not-verified');
  });
});
