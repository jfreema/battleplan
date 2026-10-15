// Super admins hear about every report (SAFE-4, store checklist 1.8): an
// email when one is filed, and a reminder from dailyCleanup while any has
// been open more than 12 hours. Run with `npm run emulators:test`.
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import type { Email } from '../../src/email/service.js';
import { remindOpenReports } from '../../src/safety/alerts.js';
import { reportContent } from '../../src/safety/handlers.js';
import { auth, db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';

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
const G = 'thunder';
const HOUR = 3_600_000;

type Callable = { run: (request: never) => Promise<unknown> };
const run = (fn: Callable, uid: string, data: object) =>
  fn.run({ data, auth: { uid, token: { email_verified: true } }, rawRequest: { ip: '1.2.3.4' } } as never);

/** An account; [superAdmin] sets the claim and the profile flag, [flagOnly] just the flag. */
async function account(uid: string, opts: { superAdmin?: boolean; flagOnly?: boolean; disabled?: boolean } = {}) {
  await auth().createUser({ uid, email: `${uid}@example.com`, displayName: uid, disabled: opts.disabled ?? false });
  if (opts.superAdmin) await auth().setCustomUserClaims(uid, { superAdmin: true });
  await db()
    .collection(Collections.users)
    .doc(uid)
    .set({ displayName: uid, status: 'active', superAdmin: opts.superAdmin === true || opts.flagOnly === true });
}

const member = (uid: string, role: string) =>
  db().collection(Collections.groupMembers).doc(`${G}_${uid}`).set({ groupId: G, uid, role, displayName: uid });

const report = (id: string, hoursAgo: number, status = 'open') =>
  db().collection(Collections.reports).doc(id).set({
    groupId: G, targetType: 'message', targetId: 'm1', reason: 'harassment', status,
    createdAt: Timestamp.fromMillis(Date.now() - hoursAgo * HOUR),
  });

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
  // root and rae are super admins; ex lost the claim, off is disabled.
  await account('root', { superAdmin: true });
  await account('rae', { superAdmin: true });
  await account('ex', { flagOnly: true });
  await account('off', { superAdmin: true, disabled: true });
  await db().collection(Collections.groups).doc(G).set({ name: 'Thunder', archivedAt: null, suspendedAt: null });
  await member('pat', 'owner');
  await member('sam', 'member');
  await member('lee', 'member');
  await db().collection(Collections.messages).doc('m1').set({
    groupId: G, authorId: 'sam', authorName: 'sam', type: 'text', text: 'Something nasty', createdAt: Timestamp.now(),
  });
  await db().collection(Collections.messages).doc('m2').set({
    groupId: G, authorId: 'pat', authorName: 'pat', type: 'text', text: 'Something else', createdAt: Timestamp.now(),
  });
});

describe('a new report (SAFE-4)', () => {
  it('emails every current super admin, without who reported or what was said', async () => {
    await run(reportContent, 'lee', { groupId: G, targetType: 'message', targetId: 'm1', reason: 'harassment' });
    expect(mail.sent.map((m) => m.to).sort()).toEqual(['rae@example.com', 'root@example.com']);
    const [email] = mail.sent;
    expect(email.subject).toBe('New report on Thunder: a message');
    expect(email.text).toContain('(harassment)');
    expect(email.text).toContain("The team's admins can act on it too.");
    expect(email.text).toContain('/admin/reports');
    expect(email.text).not.toContain('lee');
    expect(email.text).not.toContain('nasty');
  });

  it('says when only super admins see it, for a report about a team admin', async () => {
    await run(reportContent, 'lee', { groupId: G, targetType: 'message', targetId: 'm2', reason: 'inappropriate' });
    expect(mail.sent[0].text).toContain("It's about one of the team's admins, so only super admins see it.");
  });
});

describe('the daily reminder (SAFE-4)', () => {
  it('lists reports open more than 12 hours, with the oldest', async () => {
    await report('r1', 13);
    await report('r2', 20);
    await report('r3', 2);
    await report('r4', 30, 'dismissed');
    expect(await remindOpenReports()).toBe(2);
    expect(mail.sent.map((m) => m.to).sort()).toEqual(['rae@example.com', 'root@example.com']);
    expect(mail.sent[0].subject).toBe('2 reports are waiting on Battleplan');
    expect(mail.sent[0].text).toContain('the oldest was filed 20 hours ago');
  });

  it('sends nothing when every report is newer or closed', async () => {
    await report('r1', 2);
    await report('r2', 30, 'actioned');
    expect(await remindOpenReports()).toBe(0);
    expect(mail.sent).toEqual([]);
  });
});
