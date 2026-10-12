// The God admin panel's callables (SPEC §6.11 ADMIN-1 to ADMIN-8, SAFE-4,
// STORE-6, AUTH-6): super admins only, each action audited, the last super
// admin kept, and createGroup following the platform settings. Runs
// against the Auth, Firestore, and Storage emulators with email and FCM
// faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import type { TokenMessage } from 'firebase-admin/messaging';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import * as admin from '../../src/admin/handlers.js';
import type { Email } from '../../src/email/service.js';
import { auth, db, storage } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { archiveGroup, createGroup } from '../../src/teams/handlers.js';

// Email stand-in: records every email instead of sending it.
const mail = vi.hoisted(() => ({ sent: [] as Email[] }));
vi.mock('../../src/email/service.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/email/service.js')>()),
  sendEmail: async (email: Email) => {
    mail.sent.push(email);
    return true;
  },
}));

// FCM stand-in: accepts every token.
vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({
    sendEach: async (messages: TokenMessage[]) => ({
      responses: messages.map((m) => ({ success: true, messageId: `id-${m.token}` })),
      successCount: messages.length,
      failureCount: 0,
    }),
  }),
}));

const MB = 1024 * 1024;
const DAY = 86_400_000;
const ROOT = { superAdmin: true };
const project = () => process.env.GCLOUD_PROJECT ?? 'demo-battleplan';

type Callable = { run: (request: never) => Promise<unknown> };
/** Runs [fn] as [uid], with [token] claims. */
const run = <T = Record<string, unknown>>(fn: Callable, uid: string, data: object = {}, token: object = {}) =>
  fn.run({ data, auth: { uid, token }, rawRequest: {} } as never) as Promise<T>;
/** Runs [fn] as the super admin root. */
const asRoot = <T = Record<string, unknown>>(fn: Callable, data: object = {}) => run<T>(fn, 'root', data, ROOT);

const users = () => db().collection(Collections.users);
const groups = () => db().collection(Collections.groups);
const ago = (days: number) => Timestamp.fromMillis(Date.now() - days * DAY);

/** An account in Auth and its profile. */
async function person(
  uid: string,
  name: string,
  extra: { superAdmin?: boolean; status?: string; createdDaysAgo?: number; claims?: object } = {},
): Promise<void> {
  const email = `${uid}@example.com`;
  await auth().createUser({ uid, email, displayName: name, emailVerified: true });
  if (extra.superAdmin || extra.claims) {
    await auth().setCustomUserClaims(uid, { ...(extra.claims ?? {}), ...(extra.superAdmin ? { superAdmin: true } : {}) });
  }
  await users().doc(uid).set({
    displayName: name,
    displayNameLower: name.toLowerCase(),
    email,
    emailLower: email,
    photoPath: null,
    status: extra.status ?? 'active',
    signInMethods: ['password'],
    notificationPrefs: {},
    ...(extra.superAdmin ? { superAdmin: true } : {}),
    createdAt: ago(extra.createdDaysAgo ?? 30),
  });
  await db().collection(Collections.devices).doc(`dev-${uid}`).set({
    uid, token: `tok-${uid}`, platform: 'ios', appVersion: '1.0.0', updatedAt: Timestamp.now(),
  });
}

/** A team with [extra] fields. */
async function team(id: string, name: string, extra: object = {}): Promise<void> {
  await groups().doc(id).set({
    name,
    nameLower: name.toLowerCase(),
    sport: 'softball',
    teamType: 'adult',
    ownerId: '',
    memberCount: 0,
    lastMessageAt: null,
    storageBytes: 0,
    storageQuotaBytes: 500 * MB,
    archivedAt: null,
    suspendedAt: null,
    createdAt: ago(30),
    ...extra,
  });
}

async function member(groupId: string, uid: string, role = 'member', displayName = uid): Promise<void> {
  await db().collection(Collections.groupMembers).doc(`${groupId}_${uid}`).set({
    groupId, uid, role, displayName, photoPath: null, notificationLevel: 'all', mutedUntil: null, joinedAt: Timestamp.now(),
  });
}

/** The audit entries for [action], oldest first. */
async function audits(action: string): Promise<FirebaseFirestore.DocumentData[]> {
  const snap = await db().collection(Collections.auditLogs).where('action', '==', action).get();
  return snap.docs.map((d) => d.data()).sort((a, b) => a.createdAt.toMillis() - b.createdAt.toMillis());
}

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error('Run with npm run emulators:test');
  }
});

// thunder: pat owns it, sam and lee are members. hawks: sam owns it, and
// it's archived. root is a super admin on no team.
beforeEach(async () => {
  const clear = async (url: string) => expect((await fetch(url, { method: 'DELETE' })).ok).toBe(true);
  await clear(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project()}/databases/(default)/documents`);
  await clear(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${project()}/accounts`);
  await storage().bucket().deleteFiles({ prefix: 'groups/' });
  mail.sent.length = 0;
  await person('root', 'Root Admin', { superAdmin: true });
  await person('pat', 'Pat Owner');
  await person('sam', 'Sam Rivera', { createdDaysAgo: 2 });
  await person('lee', 'Lee Kim', { status: 'provisioned', createdDaysAgo: 1 });
  await team('thunder', 'Thunder', { ownerId: 'pat', memberCount: 3, storageBytes: 300 * MB, lastMessageAt: ago(1), createdAt: ago(2) });
  await team('hawks', 'Hawks U14', { ownerId: 'sam', memberCount: 1, storageBytes: 20 * MB, archivedAt: ago(5), createdAt: ago(20) });
  await member('thunder', 'pat', 'owner', 'Pat Owner');
  await member('thunder', 'sam', 'member', 'Sam Rivera');
  await member('thunder', 'lee', 'member', 'Lee Kim');
  await member('hawks', 'sam', 'owner', 'Sam Rivera');
});

describe('only super admins (ADMIN-8)', () => {
  // Every callable, with input that would otherwise work.
  const calls: [string, Callable, object][] = [
    ['adminDashboard', admin.adminDashboard, {}],
    ['adminListTeams', admin.adminListTeams, {}],
    ['adminGetTeam', admin.adminGetTeam, { groupId: 'thunder' }],
    ['adminOpenGroup', admin.adminOpenGroup, { groupId: 'thunder' }],
    ['adminSetGroupSuspended', admin.adminSetGroupSuspended, { groupId: 'thunder', suspended: true }],
    ['adminArchiveGroup', admin.adminArchiveGroup, { groupId: 'thunder', archived: true }],
    ['adminDeleteGroup', admin.adminDeleteGroup, { groupId: 'thunder', confirmName: 'Thunder' }],
    ['adminListUsers', admin.adminListUsers, {}],
    ['adminGetUser', admin.adminGetUser, { uid: 'sam' }],
    ['adminCreateUser', admin.adminCreateUser, { email: 'new@example.com', displayName: 'New' }],
    ['adminUpdateUser', admin.adminUpdateUser, { uid: 'sam', displayName: 'Sammy' }],
    ['adminSetUserDisabled', admin.adminSetUserDisabled, { uid: 'sam', disabled: true }],
    ['adminRevokeSessions', admin.adminRevokeSessions, { uid: 'sam' }],
    ['adminSendPasswordReset', admin.adminSendPasswordReset, { uid: 'sam' }],
    ['adminDeleteUser', admin.adminDeleteUser, { uid: 'sam' }],
    ['adminSetSuperAdmin', admin.adminSetSuperAdmin, { uid: 'pat', superAdmin: true }],
    ['adminListReports', admin.adminListReports, {}],
    ['adminResolveReport', admin.adminResolveReport, { reportId: 'r1', action: 'dismiss', note: 'ok' }],
    ['adminUpdateConfig', admin.adminUpdateConfig, {}],
    ['adminUpdateGroup', admin.adminUpdateGroup, { groupId: 'thunder', name: 'Renamed' }],
    ['adminUpdatePlayer', admin.adminUpdatePlayer, { playerId: 'emma', displayName: 'Em' }],
  ];

  it.each(calls)('%s refuses team owners and anyone without the claim', async (_name, fn, data) => {
    await expect(run(fn, 'pat', data)).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(run(fn, 'pat', data, { superAdmin: 'true' })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(
      fn.run({ data, rawRequest: {} } as never),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('changed nothing and audited nothing for the refused calls', async () => {
    for (const [, fn, data] of calls) await run(fn, 'pat', data).catch(() => undefined);
    expect((await db().collection(Collections.auditLogs).get()).size).toBe(0);
    expect((await groups().doc('thunder').get()).get('suspendedAt')).toBeNull();
    expect((await auth().getUser('sam')).disabled).toBe(false);
    expect(mail.sent).toEqual([]);
  });
});

describe('dashboard (ADMIN-1)', () => {
  it('totals people, teams, activity, storage, and open reports', async () => {
    await team('old', 'Old Team', { createdAt: ago(60), lastMessageAt: ago(30), storageBytes: 5 * MB });
    const messages = db().collection(Collections.messages);
    await messages.add({ groupId: 'thunder', createdAt: ago(1) });
    await messages.add({ groupId: 'thunder', createdAt: ago(3) });
    await messages.add({ groupId: 'old', createdAt: ago(30) });
    const reports = db().collection(Collections.reports);
    await reports.add({ groupId: 'thunder', status: 'open', createdAt: ago(1) });
    await reports.add({ groupId: 'thunder', status: 'dismissed', createdAt: ago(2) });
    expect(await asRoot(admin.adminDashboard)).toEqual({
      users: 4,
      teams: 3,
      newTeams: 1,
      activeTeams: 1,
      messages: 2,
      storageBytes: 325 * MB,
      openReports: 1,
    });
    expect((await db().collection(Collections.auditLogs).get()).size).toBe(0);
  });
});

describe('teams (ADMIN-2)', () => {
  type TeamPage = { rows: { id: string; ownerName: string; status: string; createdAt: string }[]; nextCursor: string | null };
  const list = (data: object) => asRoot<TeamPage>(admin.adminListTeams, data);
  const ids = (page: TeamPage) => page.rows.map((r) => r.id);

  beforeEach(async () => {
    await team('bears', 'Bears', { ownerId: 'pat', memberCount: 12, storageBytes: 1 * MB, lastMessageAt: ago(3), createdAt: ago(10) });
    await team('banned', 'Bandits', { memberCount: 2, suspendedAt: ago(1), createdAt: ago(1) });
    await member('bears', 'pat', 'owner', 'Pat Owner');
  });

  it('sorts by created date, activity, members, or storage, newest or largest first', async () => {
    expect(ids(await list({}))).toEqual(['banned', 'thunder', 'bears', 'hawks']);
    expect(ids(await list({ sort: 'activity' })).slice(0, 2)).toEqual(['thunder', 'bears']);
    expect(ids(await list({ sort: 'members' }))).toEqual(['bears', 'thunder', 'banned', 'hawks']);
    expect(ids(await list({ sort: 'storage' }))).toEqual(['thunder', 'hawks', 'bears', 'banned']);
  });

  it('returns the table columns, with the owner by name', async () => {
    const row = (await list({ sort: 'storage', limit: 1 })).rows[0];
    expect(row).toMatchObject({
      id: 'thunder',
      name: 'Thunder',
      sport: 'softball',
      ownerId: 'pat',
      ownerName: 'Pat Owner',
      memberCount: 3,
      storageBytes: 300 * MB,
      storageQuotaBytes: 500 * MB,
      status: 'active',
    });
    expect(Date.parse(row.createdAt)).toBeGreaterThan(0);
  });

  it('pages with a cursor until there are no more', async () => {
    const first = await list({ limit: 3 });
    expect(ids(first)).toEqual(['banned', 'thunder', 'bears']);
    const second = await list({ limit: 3, cursor: first.nextCursor });
    expect(ids(second)).toEqual(['hawks']);
    expect(second.nextCursor).toBeNull();
    await expect(list({ cursor: 'nope' })).rejects.toMatchObject({ code: 'invalid-argument', message: 'bad-cursor' });
  });

  it('filters by Active, Archived, or Suspended', async () => {
    expect(ids(await list({ status: 'active' }))).toEqual(['thunder', 'bears']);
    expect(ids(await list({ status: 'archived' }))).toEqual(['hawks']);
    expect(ids(await list({ status: 'suspended' }))).toEqual(['banned']);
    const page = await list({ status: 'active', limit: 1 });
    expect(ids(page)).toEqual(['thunder']);
    expect(ids(await list({ status: 'active', limit: 1, cursor: page.nextCursor }))).toEqual(['bears']);
  });

  it('searches by the start of the name, in name order', async () => {
    // Bandits (banned) sorts before Bears.
    expect(ids(await list({ query: 'b' }))).toEqual(['banned', 'bears']);
    expect(ids(await list({ query: 'THU' }))).toEqual(['thunder']);
    expect(ids(await list({ query: 'b', status: 'suspended' }))).toEqual(['banned']);
    expect(ids(await list({ query: 'zz' }))).toEqual([]);
  });
});

describe('team detail and actions (ADMIN-3)', () => {
  it('shows the team, its people, invites, and counts', async () => {
    await db().collection(Collections.invites).doc('CODE1234').set({
      groupId: 'thunder', type: 'link', createdBy: 'pat', expiresAt: null, maxUses: null, useCount: 2, revokedAt: null, createdAt: ago(1),
    });
    await db().collection(Collections.invites).doc('OLD12345').set({
      groupId: 'thunder', type: 'link', createdBy: 'pat', revokedAt: ago(2), createdAt: ago(3),
    });
    await db().collection(Collections.events).add({ groupId: 'thunder' });
    await db().collection(Collections.groupDocuments).add({ groupId: 'thunder' });
    await db().collection(Collections.groupDocuments).add({ groupId: 'thunder' });
    const detail = await asRoot<{
      team: Record<string, unknown>;
      ownerName: string;
      members: { uid: string; role: string }[];
      players: unknown[];
      invites: { code: string; useCount: number }[];
      counts: object;
    }>(admin.adminGetTeam, { groupId: 'thunder' });
    expect(detail.team).toMatchObject({ id: 'thunder', name: 'Thunder', status: 'active', storageBytes: 300 * MB });
    expect(typeof detail.team.createdAt).toBe('string');
    expect(detail.ownerName).toBe('Pat Owner');
    expect(detail.members.map((m) => `${m.uid}:${m.role}`).sort()).toEqual(['lee:member', 'pat:owner', 'sam:member']);
    expect(detail.players).toEqual([]);
    expect(detail.invites).toEqual([expect.objectContaining({ code: 'CODE1234', useCount: 2 })]);
    expect(detail.counts).toEqual({ events: 1, documents: 2, polls: 0 });
    await expect(asRoot(admin.adminGetTeam, { groupId: 'nope' })).rejects.toMatchObject({ code: 'not-found' });
  });

  it('records each View team in the audit log', async () => {
    await asRoot(admin.adminOpenGroup, { groupId: 'thunder' });
    await asRoot(admin.adminOpenGroup, { groupId: 'thunder' });
    const entries = await audits('viewGroup');
    expect(entries).toHaveLength(2);
    expect(entries[0]).toMatchObject({ actorId: 'root', groupId: 'thunder', targetType: 'group', targetId: 'thunder' });
    await expect(asRoot(admin.adminOpenGroup, { groupId: 'nope' })).rejects.toMatchObject({ code: 'not-found' });
  });

  it('suspends and unsuspends a team, with the note in the audit log', async () => {
    await asRoot(admin.adminSetGroupSuspended, { groupId: 'thunder', suspended: true, note: 'Spam team' });
    expect((await groups().doc('thunder').get()).get('suspendedAt')).toBeInstanceOf(Timestamp);
    await asRoot(admin.adminSetGroupSuspended, { groupId: 'thunder', suspended: false });
    expect((await groups().doc('thunder').get()).get('suspendedAt')).toBeNull();
    const [on] = await audits('suspendGroup');
    expect(on).toMatchObject({ groupId: 'thunder', before: { suspended: false }, after: { suspended: true, note: 'Spam team' } });
    expect(await audits('unsuspendGroup')).toHaveLength(1);
  });

  it('archives and restores any team', async () => {
    await asRoot(admin.adminArchiveGroup, { groupId: 'thunder', archived: true });
    expect((await groups().doc('thunder').get()).get('archivedAt')).toBeInstanceOf(Timestamp);
    await asRoot(admin.adminArchiveGroup, { groupId: 'hawks', archived: false });
    expect((await groups().doc('hawks').get()).get('archivedAt')).toBeNull();
    expect(await audits('archiveGroup')).toHaveLength(1);
    expect(await audits('restoreGroup')).toHaveLength(1);
  });

  it('audits archive and restore with the state before and after (ADMIN-6), keeping the first archive date', async () => {
    const hawksArchivedAt = (await groups().doc('hawks').get()).get('archivedAt').toDate().toISOString();
    // hawks is already archived: archiving again changes nothing and says so.
    await asRoot(admin.adminArchiveGroup, { groupId: 'hawks', archived: true });
    expect((await groups().doc('hawks').get()).get('archivedAt').toDate().toISOString()).toBe(hawksArchivedAt);
    await asRoot(admin.adminArchiveGroup, { groupId: 'thunder', archived: true });
    expect((await audits('archiveGroup')).map((a) => [a.groupId, a.before, a.after])).toEqual([
      ['hawks', { archived: true, archivedAt: hawksArchivedAt }, { archived: true }],
      ['thunder', { archived: false, archivedAt: null }, { archived: true }],
    ]);
    await asRoot(admin.adminArchiveGroup, { groupId: 'hawks', archived: false });
    expect((await audits('restoreGroup'))[0]).toMatchObject({
      before: { archived: true, archivedAt: hawksArchivedAt },
      after: { archived: false },
    });
    // The owner's own Archive in Team settings is audited the same way.
    await run(archiveGroup, 'pat', { groupId: 'thunder', archived: false });
    expect((await audits('restoreGroup'))[1]).toMatchObject({
      actorId: 'pat',
      groupId: 'thunder',
      before: { archived: true, archivedAt: expect.any(String) },
      after: { archived: false },
    });
  });

  it('deletes a team only when its name is typed', async () => {
    await storage().bucket().file('groups/thunder/avatar/a.jpg').save(Buffer.alloc(4), { contentType: 'image/jpeg' });
    await expect(asRoot(admin.adminDeleteGroup, { groupId: 'thunder', confirmName: 'Thunderr' })).rejects.toMatchObject({
      code: 'invalid-argument',
      message: 'name-mismatch',
    });
    expect((await groups().doc('thunder').get()).exists).toBe(true);
    await asRoot(admin.adminDeleteGroup, { groupId: 'thunder', confirmName: ' Thunder ' });
    expect((await groups().doc('thunder').get()).exists).toBe(false);
    expect((await db().collection(Collections.groupMembers).where('groupId', '==', 'thunder').get()).size).toBe(0);
    const [exists] = await storage().bucket().file('groups/thunder/avatar/a.jpg').exists();
    expect(exists).toBe(false);
    expect((await audits('deleteGroup'))[0]).toMatchObject({ before: { name: 'Thunder', memberCount: 3 } });
  });
});

describe('editing a team the super admin is not on (ADMIN-3)', () => {
  const settings = {
    membersCanCreateEvents: false, membersCanCreatePolls: true, membersCanUploadDocs: true, membersCanInvite: true,
    allowMaybe: true, defaultReminderOffsets: [1440],
  };
  const upload = (path: string) => storage().bucket().file(path).save(Buffer.alloc(4), { contentType: 'image/jpeg' });

  beforeEach(async () => {
    await groups().doc('thunder').update({
      description: 'Old', color: '#2F5BEA', timeZone: 'America/Chicago', photoPath: null, settings,
      chatTheme: { bubbleColor: null, background: 'plain', backgroundPath: null },
    });
    await db().collection(Collections.players).doc('emma').set({
      groupId: 'thunder', displayName: 'Emma', displayNameLower: 'emma', jerseyNumber: '7', position: 'SS',
    });
  });

  it('changes the profile and settings, merging settings, and audits before and after', async () => {
    await asRoot(admin.adminUpdateGroup, {
      groupId: 'thunder', name: ' Thunder 12U ', description: 'New', color: '#0F8A5F', sport: 'baseball',
      timeZone: 'America/Denver', settings: { allowMaybe: false, defaultReminderOffsets: [60, 1440] },
    });
    const t = (await groups().doc('thunder').get()).data()!;
    expect(t).toMatchObject({
      name: 'Thunder 12U', nameLower: 'thunder 12u', description: 'New', color: '#0F8A5F', sport: 'baseball',
      timeZone: 'America/Denver', settings: { ...settings, allowMaybe: false, defaultReminderOffsets: [60, 1440] },
    });
    expect((await audits('updateGroup'))[0]).toMatchObject({
      actorId: 'root', groupId: 'thunder', targetType: 'group', targetId: 'thunder',
      before: { name: 'Thunder', description: 'Old', color: '#2F5BEA', sport: 'softball', timeZone: 'America/Chicago', settings },
      after: { name: 'Thunder 12U', description: 'New', color: '#0F8A5F', sport: 'baseball' },
    });
  });

  it('saves an uploaded logo and chat background', async () => {
    await upload('groups/thunder/avatar/1.jpg');
    await upload('groups/thunder/theme/1.jpg');
    await asRoot(admin.adminUpdateGroup, { groupId: 'thunder', photoPath: 'groups/thunder/avatar/1.jpg' });
    await asRoot(admin.adminUpdateGroup, { groupId: 'thunder', backgroundPath: 'groups/thunder/theme/1.jpg' });
    await asRoot(admin.adminUpdateGroup, { groupId: 'thunder', chatTheme: { bubbleColor: '#B91C1C', background: 'photo', backgroundPath: 'groups/thunder/theme/1.jpg' } });
    const t = (await groups().doc('thunder').get()).data()!;
    expect(t.photoPath).toBe('groups/thunder/avatar/1.jpg');
    expect(t.chatTheme).toEqual({ bubbleColor: '#B91C1C', background: 'photo', backgroundPath: 'groups/thunder/theme/1.jpg' });
    expect((await audits('updateGroup'))[1]).toMatchObject({
      before: { chatTheme: { backgroundPath: null } }, after: { chatTheme: { backgroundPath: 'groups/thunder/theme/1.jpg' } },
    });
  });

  it('refuses what the rules refuse, files that were never uploaded, and archived teams', async () => {
    await upload('groups/hawks/avatar/1.jpg');
    const bad = [
      { color: '#123456' }, { sport: 'cricket' }, { name: '' }, { name: 'x'.repeat(51) }, { description: 'x'.repeat(501) },
      { settings: { secret: true } }, { settings: { defaultReminderOffsets: [7] } },
      { chatTheme: { background: 'video' } }, { photoPath: 'groups/hawks/avatar/1.jpg' },
      { photoPath: 'groups/thunder/avatar/a/b.jpg' }, { backgroundPath: 'groups/thunder/avatar/1.jpg' }, {},
    ];
    for (const edit of bad) {
      await expect(asRoot(admin.adminUpdateGroup, { groupId: 'thunder', ...edit })).rejects.toMatchObject({ code: 'invalid-argument' });
    }
    await expect(asRoot(admin.adminUpdateGroup, { groupId: 'thunder', photoPath: 'groups/thunder/avatar/none.jpg' })).rejects.toMatchObject({
      message: 'no-such-file',
    });
    await expect(asRoot(admin.adminUpdateGroup, { groupId: 'hawks', name: 'Hawks' })).rejects.toMatchObject({ message: 'archived' });
    await expect(asRoot(admin.adminUpdateGroup, { groupId: 'nope', name: 'Nope' })).rejects.toMatchObject({ code: 'not-found' });
    expect((await groups().doc('thunder').get()).get('name')).toBe('Thunder');
    expect(await audits('updateGroup')).toHaveLength(0);
  });

  it('edits a player, a blank number or position clearing it, and audits it', async () => {
    await asRoot(admin.adminUpdatePlayer, { playerId: 'emma', displayName: ' Emma R ', jerseyNumber: ' ', position: 'CF' });
    expect((await db().collection(Collections.players).doc('emma').get()).data()).toMatchObject({
      displayName: 'Emma R', displayNameLower: 'emma r', jerseyNumber: null, position: 'CF',
    });
    expect((await audits('updatePlayer'))[0]).toMatchObject({
      actorId: 'root', groupId: 'thunder', targetType: 'player', targetId: 'emma',
      before: { displayName: 'Emma', jerseyNumber: '7', position: 'SS' },
      after: { displayName: 'Emma R', jerseyNumber: null, position: 'CF' },
    });
  });

  it("refuses a player edit validPlayer would, and players that don't exist", async () => {
    for (const edit of [{ displayName: '' }, { jerseyNumber: '12345' }, { position: 'x'.repeat(31) }, { groupId: 'hawks' }, {}]) {
      await expect(asRoot(admin.adminUpdatePlayer, { playerId: 'emma', ...edit })).rejects.toMatchObject({ code: 'invalid-argument' });
    }
    await expect(asRoot(admin.adminUpdatePlayer, { playerId: 'nope', displayName: 'X' })).rejects.toMatchObject({ code: 'not-found' });
    expect(await audits('updatePlayer')).toHaveLength(0);
  });
});

describe('users (ADMIN-4)', () => {
  type UserPage = { rows: { uid: string; status: string; superAdmin: boolean; disabled: boolean }[]; nextCursor: string | null };
  const list = (data: object) => asRoot<UserPage>(admin.adminListUsers, data);
  const uids = (page: UserPage) => page.rows.map((r) => r.uid);

  it('lists people newest first, a page at a time', async () => {
    const first = await list({ limit: 2 });
    expect(uids(first)).toEqual(['lee', 'sam']);
    const second = await list({ limit: 2, cursor: first.nextCursor });
    expect(uids(second).sort()).toEqual(['pat', 'root']);
  });

  it('filters by Added, Active, Disabled, or Super admin', async () => {
    await auth().updateUser('sam', { disabled: true });
    await users().doc('sam').update({ status: 'disabled' });
    expect(uids(await list({ filter: 'added' }))).toEqual(['lee']);
    expect(uids(await list({ filter: 'disabled' }))).toEqual(['sam']);
    expect(uids(await list({ filter: 'active' })).sort()).toEqual(['pat', 'root']);
    const supers = await list({ filter: 'superAdmin' });
    expect(supers.rows).toEqual([expect.objectContaining({ uid: 'root', superAdmin: true, disabled: false })]);
    expect((await list({ filter: 'disabled' })).rows[0]).toMatchObject({ disabled: true, status: 'disabled' });
  });

  it('searches the start of the name or the email', async () => {
    expect(uids(await list({ query: 'sam' }))).toEqual(['sam']);
    expect(uids(await list({ query: 'Pat@Ex' }))).toEqual(['pat']);
    expect(uids(await list({ query: 'l', filter: 'added' }))).toEqual(['lee']);
    expect((await list({ query: 'sam' })).nextCursor).toBeNull();
  });

  it('shows one person in full', async () => {
    const user = await asRoot<Record<string, unknown>>(admin.adminGetUser, { uid: 'sam' });
    expect(user).toMatchObject({
      uid: 'sam',
      displayName: 'Sam Rivera',
      email: 'sam@example.com',
      status: 'active',
      superAdmin: false,
      disabled: false,
      emailVerified: true,
    });
    expect((user.teams as { groupId: string; role: string; status: string }[]).map((t) => `${t.groupId}:${t.role}:${t.status}`).sort()).toEqual([
      'hawks:owner:archived',
      'thunder:member:active',
    ]);
    expect(Array.isArray(user.signInMethods)).toBe(true);
    await expect(asRoot(admin.adminGetUser, { uid: 'nobody' })).rejects.toMatchObject({ code: 'not-found' });
  });

  it('creates an added account and sends the setup email, never a password (AUTH-6)', async () => {
    const { uid } = await asRoot<{ uid: string }>(admin.adminCreateUser, { email: 'New@Example.com', displayName: 'Nia New' });
    const user = await auth().getUser(uid);
    expect(user.email).toBe('new@example.com');
    expect(user.passwordHash).toBeUndefined();
    expect((await users().doc(uid).get()).data()).toMatchObject({ displayName: 'Nia New', status: 'provisioned' });
    expect(mail.sent).toHaveLength(1);
    expect(mail.sent[0]).toMatchObject({ to: 'new@example.com', subject: 'Root Admin set up a Battleplan account for you' });
    expect((await audits('createUser'))[0]).toMatchObject({ targetId: uid, after: { email: 'new@example.com', groupId: null } });
    await expect(
      asRoot(admin.adminCreateUser, { email: 'new@example.com', displayName: 'Again' }),
    ).rejects.toMatchObject({ code: 'already-exists', message: 'user-exists' });
  });

  it('creates an account on a team, as an admin', async () => {
    const { uid } = await asRoot<{ uid: string }>(admin.adminCreateUser, {
      email: 'coach@example.com', displayName: 'Cory Coach', groupId: 'thunder', role: 'admin',
    });
    const membership = await db().collection(Collections.groupMembers).doc(`thunder_${uid}`).get();
    expect(membership.data()).toMatchObject({ role: 'admin', pending: true, displayName: 'Cory Coach' });
    expect((await groups().doc('thunder').get()).get('memberCount')).toBe(4);
    expect(mail.sent.map((m) => m.subject)).toEqual(['Root Admin added you to Thunder on Battleplan']);
    expect((await audits('createUser'))[0]).toMatchObject({ groupId: 'thunder', after: { role: 'admin' } });
  });

  it('renames someone everywhere and adds them to a team', async () => {
    await asRoot(admin.adminUpdateUser, { uid: 'sam', displayName: 'Samantha Rivera' });
    expect((await users().doc('sam').get()).data()).toMatchObject({
      displayName: 'Samantha Rivera',
      displayNameLower: 'samantha rivera',
    });
    expect((await db().collection(Collections.groupMembers).doc('thunder_sam').get()).get('displayName')).toBe('Samantha Rivera');
    expect((await audits('updateUser'))[0]).toMatchObject({
      before: { displayName: 'Sam Rivera' },
      after: { displayName: 'Samantha Rivera' },
    });

    await asRoot(admin.adminUpdateUser, { uid: 'pat', addToGroup: { groupId: 'hawks', role: 'admin' } });
    expect((await db().collection(Collections.groupMembers).doc('hawks_pat').get()).get('role')).toBe('admin');
    expect(mail.sent.map((m) => m.subject)).toEqual(["You're on Hawks U14 on Battleplan"]);
    await expect(
      asRoot(admin.adminUpdateUser, { uid: 'pat', addToGroup: { groupId: 'thunder' } }),
    ).rejects.toMatchObject({ code: 'failed-precondition', message: 'already-member' });
    await expect(
      asRoot(admin.adminUpdateUser, { uid: 'pat', addToGroup: { groupId: 'nope' } }),
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('disables (signing out everywhere) and enables an account, but not your own', async () => {
    await asRoot(admin.adminSetUserDisabled, { uid: 'sam', disabled: true });
    expect((await auth().getUser('sam')).disabled).toBe(true);
    expect((await users().doc('sam').get()).get('status')).toBe('disabled');
    expect((await db().collection(Collections.devices).doc('dev-sam').get()).exists).toBe(false);
    expect((await auth().getUser('sam')).tokensValidAfterTime).toBeTruthy();
    await asRoot(admin.adminSetUserDisabled, { uid: 'sam', disabled: false });
    expect((await auth().getUser('sam')).disabled).toBe(false);
    expect((await users().doc('sam').get()).get('status')).toBe('active');
    expect((await audits('disableUser'))[0]).toMatchObject({ targetId: 'sam', before: { status: 'active' } });
    expect(await audits('enableUser')).toHaveLength(1);
    // An added account that never signed in goes back to Added.
    await asRoot(admin.adminSetUserDisabled, { uid: 'lee', disabled: true });
    await users().doc('lee').update({ signInMethods: [] });
    await asRoot(admin.adminSetUserDisabled, { uid: 'lee', disabled: false });
    expect((await users().doc('lee').get()).get('status')).toBe('provisioned');
    await expect(asRoot(admin.adminSetUserDisabled, { uid: 'root', disabled: true })).rejects.toMatchObject({
      message: 'cannot-disable-self',
    });
  });

  it('signs someone out everywhere', async () => {
    await asRoot(admin.adminRevokeSessions, { uid: 'pat' });
    expect((await db().collection(Collections.devices).doc('dev-pat').get()).exists).toBe(false);
    expect((await audits('revokeSessions'))[0]).toMatchObject({ targetId: 'pat' });
    await expect(asRoot(admin.adminRevokeSessions, { uid: 'nobody' })).rejects.toMatchObject({ code: 'not-found' });
  });

  it('sends a password reset link by email and returns nothing secret', async () => {
    const result = await asRoot(admin.adminSendPasswordReset, { uid: 'pat' });
    expect(result).toEqual({ ok: true });
    expect(mail.sent).toHaveLength(1);
    expect(mail.sent[0]).toMatchObject({ to: 'pat@example.com', subject: 'Reset your Battleplan password' });
    expect(mail.sent[0].text).toMatch(/Choose a new password: http/);
    expect((await audits('sendPasswordReset'))[0]).toMatchObject({ targetId: 'pat' });
  });

  it('deletes an account as account deletion does, never your own', async () => {
    await expect(asRoot(admin.adminDeleteUser, { uid: 'root' })).rejects.toMatchObject({ message: 'cannot-delete-self' });
    await asRoot(admin.adminDeleteUser, { uid: 'pat' });
    await expect(auth().getUser('pat')).rejects.toMatchObject({ code: 'auth/user-not-found' });
    expect((await users().doc('pat').get()).exists).toBe(false);
    // Thunder passes to its longest-serving member (AUTH-10).
    expect((await groups().doc('thunder').get()).get('ownerId')).not.toBe('pat');
    expect((await audits('deleteUser'))[0]).toMatchObject({ targetId: 'pat', before: { displayName: 'Pat Owner' } });
  });
});

describe('super admins (ADMIN-4)', () => {
  it('grants the claim, keeping other claims, and lists them', async () => {
    await auth().setCustomUserClaims('pat', { beta: true });
    await asRoot(admin.adminSetSuperAdmin, { uid: 'pat', superAdmin: true });
    expect((await auth().getUser('pat')).customClaims).toEqual({ beta: true, superAdmin: true });
    expect((await users().doc('pat').get()).get('superAdmin')).toBe(true);
    expect((await audits('grantSuperAdmin'))[0]).toMatchObject({
      targetId: 'pat', before: { superAdmin: false }, after: { superAdmin: true },
    });
  });

  it('revokes the claim and the sessions that carried it', async () => {
    await person('boss', 'Boss', { superAdmin: true, claims: { beta: true } });
    await asRoot(admin.adminSetSuperAdmin, { uid: 'boss', superAdmin: false });
    const boss = await auth().getUser('boss');
    expect(boss.customClaims).toEqual({ beta: true });
    expect(boss.tokensValidAfterTime).toBeTruthy();
    expect((await users().doc('boss').get()).get('superAdmin')).toBe(false);
    expect(await audits('revokeSuperAdmin')).toHaveLength(1);
  });

  it('never removes the last super admin', async () => {
    await expect(asRoot(admin.adminSetSuperAdmin, { uid: 'root', superAdmin: false })).rejects.toMatchObject({
      code: 'failed-precondition',
      message: 'last-super-admin',
    });
    expect((await auth().getUser('root')).customClaims).toEqual({ superAdmin: true });
    // With another super admin, you may step down.
    await asRoot(admin.adminSetSuperAdmin, { uid: 'pat', superAdmin: true });
    await asRoot(admin.adminSetSuperAdmin, { uid: 'root', superAdmin: false });
    expect((await auth().getUser('root')).customClaims ?? {}).toEqual({});
  });

  it('counts a super admin made before users.superAdmin existed', async () => {
    // Made with tools/seed/set-super-admin.ts: the claim, no profile flag.
    await person('old', 'Old Admin', { claims: { superAdmin: true } });
    await run(admin.adminSetSuperAdmin, 'old', { uid: 'pat', superAdmin: true }, ROOT);
    expect((await users().doc('old').get()).get('superAdmin')).toBe(true);
  });

  it("doesn't count a disabled super admin as the one who's left", async () => {
    await person('boss', 'Boss', { superAdmin: true });
    await asRoot(admin.adminSetUserDisabled, { uid: 'boss', disabled: true });
    await expect(asRoot(admin.adminSetSuperAdmin, { uid: 'root', superAdmin: false })).rejects.toMatchObject({
      message: 'last-super-admin',
    });
    expect((await auth().getUser('root')).customClaims).toEqual({ superAdmin: true });
  });

  it("refuses a revoked super admin's old token, which can't mark them a super admin again", async () => {
    await person('boss', 'Boss', { superAdmin: true });
    await asRoot(admin.adminSetSuperAdmin, { uid: 'boss', superAdmin: false });
    // boss's ID token still carries the claim for up to an hour.
    await expect(run(admin.adminSetSuperAdmin, 'boss', { uid: 'pat', superAdmin: true }, ROOT)).rejects.toMatchObject({
      code: 'permission-denied',
    });
    expect((await users().doc('boss').get()).get('superAdmin')).toBe(false);
    expect((await auth().getUser('pat')).customClaims ?? {}).toEqual({});
    // So root is still the last one.
    await expect(asRoot(admin.adminSetSuperAdmin, { uid: 'root', superAdmin: false })).rejects.toMatchObject({
      message: 'last-super-admin',
    });
  });

  it('ignores a users.superAdmin flag without the claim behind it', async () => {
    await person('ghost', 'Ghost');
    await users().doc('ghost').update({ superAdmin: true });
    await expect(asRoot(admin.adminSetSuperAdmin, { uid: 'root', superAdmin: false })).rejects.toMatchObject({
      message: 'last-super-admin',
    });
  });

  it('lets only one of two super admins step down at the same time', async () => {
    await person('boss', 'Boss', { superAdmin: true });
    const results = await Promise.allSettled([
      asRoot(admin.adminSetSuperAdmin, { uid: 'root', superAdmin: false }),
      run(admin.adminSetSuperAdmin, 'boss', { uid: 'boss', superAdmin: false }, ROOT),
    ]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect(results.find((r) => r.status === 'rejected')).toMatchObject({ reason: { message: 'last-super-admin' } });
    const left = await Promise.all(['root', 'boss'].map(async (uid) => (await auth().getUser(uid)).customClaims?.superAdmin));
    expect(left.filter((c) => c === true)).toHaveLength(1);
    expect((await db().collection(Collections.config).doc('superAdmins').get()).get('lockedUntil')).toBeNull();
  });

  it('keeps the last super admin through account deletion too', async () => {
    await person('boss', 'Boss', { superAdmin: true });
    await asRoot(admin.adminDeleteUser, { uid: 'boss' });
    await expect(auth().getUser('boss')).rejects.toMatchObject({ code: 'auth/user-not-found' });
    expect((await auth().getUser('root')).customClaims).toEqual({ superAdmin: true });
  });
});

describe('reports (ADMIN-5, SAFE-4)', () => {
  type ReportPage = { rows: Record<string, unknown>[]; nextCursor: string | null };

  /** A report of [target] on thunder, filed by lee. */
  async function report(id: string, targetType: string, targetId: string, subjectId: string, extra: object = {}) {
    await db().collection(Collections.reports).doc(id).set({
      reporterId: 'lee', groupId: 'thunder', targetType, targetId, reason: 'spam', details: 'Again',
      subjectId, subjectName: subjectId, excerpt: 'Buy now', status: 'open', resolvedBy: null, resolution: null,
      createdAt: ago(1), ...extra,
    });
  }

  beforeEach(async () => {
    await db().collection(Collections.messages).doc('m1').set({
      groupId: 'thunder', authorId: 'sam', authorName: 'Sam Rivera', type: 'text', text: 'Buy now', attachments: [], reactions: {},
      createdAt: ago(1),
    });
    await db().collection(Collections.groupDocuments).doc('d1').set({ groupId: 'thunder', kind: 'link', name: 'Spam', uploadedBy: 'sam' });
    await report('r1', 'message', 'm1', 'sam');
    await report('r2', 'document', 'd1', 'sam', { createdAt: ago(2) });
    await report('r3', 'user', 'sam', 'sam', { createdAt: ago(3) });
    await report('r0', 'message', 'm1', 'sam', { status: 'dismissed', createdAt: ago(4) });
  });

  const resolve = (reportId: string, action: string, note = 'Handled') =>
    asRoot<{ resolution: string }>(admin.adminResolveReport, { reportId, action, note });

  it('lists open reports from every team with the preview, reporter, and team', async () => {
    const page = await asRoot<ReportPage>(admin.adminListReports, { limit: 2 });
    expect(page.rows.map((r) => r.id)).toEqual(['r1', 'r2']);
    expect(page.rows[0]).toMatchObject({
      groupName: 'Thunder', reporterName: 'Lee Kim', excerpt: 'Buy now', subjectName: 'sam', reason: 'spam', status: 'open',
    });
    const next = await asRoot<ReportPage>(admin.adminListReports, { limit: 2, cursor: page.nextCursor });
    expect(next.rows.map((r) => r.id)).toEqual(['r3']);
    const dismissed = await asRoot<ReportPage>(admin.adminListReports, { status: 'dismissed' });
    expect(dismissed.rows.map((r) => r.id)).toEqual(['r0']);
  });

  it('deletes reported content and closes the report with a note', async () => {
    await groups().doc('thunder').update({ lastMessagePreview: { authorName: 'Sam Rivera', text: 'Buy now', type: 'text' } });
    expect(await resolve('r1', 'deleteContent', 'Spam link')).toMatchObject({ resolution: 'deletedMessage' });
    const m1 = (await db().collection(Collections.messages).doc('m1').get()).data()!;
    expect(m1).toMatchObject({ deletedReason: 'admin', deletedBy: 'root', text: '' });
    // The copies of its text go too: the report's and the team switcher's (CHAT-8).
    expect((await db().collection(Collections.reports).doc('r1').get()).data()).toMatchObject({
      status: 'actioned', resolution: 'deletedMessage', note: 'Spam link', resolvedBy: 'root', excerpt: '',
    });
    expect((await groups().doc('thunder').get()).get('lastMessagePreview')).toBeNull();
    expect((await audits('actionReport'))[0]).toMatchObject({
      groupId: 'thunder', targetId: 'r1', after: { action: 'deleteContent', resolution: 'deletedMessage', note: 'Spam link' },
    });

    await resolve('r2', 'deleteContent');
    expect((await db().collection(Collections.groupDocuments).doc('d1').get()).exists).toBe(false);
    await expect(resolve('r3', 'deleteContent')).rejects.toMatchObject({ message: 'nothing-to-delete' });
  });

  it('removes the person from the team', async () => {
    await resolve('r3', 'removeMember');
    expect((await db().collection(Collections.groupMembers).doc('thunder_sam').get()).exists).toBe(false);
    expect((await groups().doc('thunder').get()).get('memberCount')).toBe(2);
  });

  it("won't remove the team's owner", async () => {
    await report('r9', 'user', 'pat', 'pat');
    await expect(resolve('r9', 'removeMember')).rejects.toMatchObject({ message: 'owner' });
    expect((await db().collection(Collections.reports).doc('r9').get()).data()).toMatchObject({
      status: 'open', resolution: null, resolvedBy: null, excerpt: 'Buy now',
    });
    expect((await audits('resolveReportRefused'))[0]).toMatchObject({
      actorId: 'root', targetId: 'r9', after: { action: 'removeMember', refused: 'owner' },
    });
  });

  it('acts once when two super admins resolve the same report together, and audits the refused one', async () => {
    await person('boss', 'Boss', { superAdmin: true });
    const results = await Promise.allSettled([
      resolve('r1', 'dismiss', 'Fine'),
      run(admin.adminResolveReport, 'boss', { reportId: 'r1', action: 'disableUser', note: 'Spammer' }, ROOT),
    ]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    const r1 = (await db().collection(Collections.reports).doc('r1').get()).data()!;
    // Whatever the report says was done is what was done, and nothing else.
    expect((await auth().getUser('sam')).disabled).toBe(r1.resolution === 'disabledUser');
    const done = [...(await audits('dismissReport')), ...(await audits('actionReport'))];
    expect(done).toHaveLength(1);
    expect(done[0].after).toMatchObject({ resolution: r1.resolution });
    expect((await audits('resolveReportRefused'))[0]).toMatchObject({ targetId: 'r1', after: { refused: 'already-resolved' } });
  });

  it("won't disable the last super admin who can sign in through a report", async () => {
    await person('boss', 'Boss', { superAdmin: true });
    await report('r8', 'user', 'boss', 'boss');
    await run(admin.adminSetSuperAdmin, 'boss', { uid: 'root', superAdmin: false }, ROOT);
    // root's token is stale now; boss is the only super admin.
    await expect(resolve('r8', 'disableUser')).rejects.toMatchObject({ code: 'permission-denied' });
    expect((await auth().getUser('boss')).disabled).toBe(false);
    expect((await db().collection(Collections.reports).doc('r8').get()).get('status')).toBe('open');
  });

  it('disables the person or suspends the team', async () => {
    expect(await resolve('r1', 'disableUser')).toMatchObject({ resolution: 'disabledUser' });
    expect((await auth().getUser('sam')).disabled).toBe(true);
    await resolve('r2', 'suspendTeam');
    expect((await groups().doc('thunder').get()).get('suspendedAt')).toBeInstanceOf(Timestamp);
  });

  it('dismisses, once', async () => {
    await resolve('r3', 'dismiss', 'Not a problem');
    expect((await db().collection(Collections.reports).doc('r3').get()).data()).toMatchObject({
      status: 'dismissed', resolution: 'none', note: 'Not a problem', excerpt: '',
    });
    expect(await audits('dismissReport')).toHaveLength(1);
    await expect(resolve('r3', 'dismiss')).rejects.toMatchObject({ message: 'already-resolved' });
    await expect(resolve('nope', 'dismiss')).rejects.toMatchObject({ code: 'not-found' });
    await expect(asRoot(admin.adminResolveReport, { reportId: 'r1', action: 'dismiss', note: '' })).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });
});

describe('platform settings (ADMIN-7) and createGroup', () => {
  const settings = (extra: object = {}) => ({
    allowUserGroupCreation: true,
    maxGroupsCreatedPerUserPerDay: 5,
    defaultStorageQuotaMb: 500,
    maxUploadMb: 10,
    supportEmail: 'support@getbattleplan.app',
    announcementBanner: null,
    ...extra,
  });
  const newTeam = (uid: string, token: object = {}) =>
    run<{ groupId: string }>(createGroup, uid, { name: 'New Team', sport: 'soccer', teamType: 'adult', timeZone: 'America/Chicago' }, token);
  const config = async () => (await db().collection(Collections.config).doc('app').get()).data()!;

  it('saves the settings and the banner, keeping other fields, and audits the change', async () => {
    await db().collection(Collections.config).doc('app').set({ maxImageMb: 10, supportEmail: 'old@example.com' });
    await asRoot(admin.adminUpdateConfig, settings({
      announcementBanner: { text: 'Down for maintenance Sunday', severity: 'warning', expiresAt: '2026-11-01T06:00:00Z' },
    }));
    const saved = await config();
    expect(saved).toMatchObject({ maxImageMb: 10, supportEmail: 'support@getbattleplan.app', maxUploadMb: 10 });
    expect(saved.announcementBanner).toMatchObject({ text: 'Down for maintenance Sunday', severity: 'warning' });
    expect((saved.announcementBanner.expiresAt as Timestamp).toDate().toISOString()).toBe('2026-11-01T06:00:00.000Z');
    const [entry] = await audits('updateConfig');
    expect(entry).toMatchObject({
      targetType: 'config',
      targetId: 'app',
      before: { supportEmail: 'old@example.com', announcementBanner: null },
      after: { supportEmail: 'support@getbattleplan.app', announcementBanner: { expiresAt: '2026-11-01T06:00:00.000Z' } },
    });
    await asRoot(admin.adminUpdateConfig, settings());
    expect((await config()).announcementBanner).toBeNull();
    await expect(asRoot(admin.adminUpdateConfig, settings({ maxUploadMb: 50 }))).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('turns team creation off for everyone but super admins', async () => {
    await asRoot(admin.adminUpdateConfig, settings({ allowUserGroupCreation: false }));
    await expect(newTeam('pat')).rejects.toMatchObject({ code: 'permission-denied', message: 'group-creation-off' });
    const { groupId } = await newTeam('root', ROOT);
    expect((await groups().doc(groupId).get()).get('ownerId')).toBe('root');
  });

  it('limits teams per person per day', async () => {
    await asRoot(admin.adminUpdateConfig, settings({ maxGroupsCreatedPerUserPerDay: 1 }));
    await newTeam('pat');
    await expect(newTeam('pat')).rejects.toMatchObject({ code: 'resource-exhausted' });
    await newTeam('sam');
  });

  it("gives new teams the default storage limit, and the built-in one when there's no setting", async () => {
    const first = await newTeam('pat');
    expect((await groups().doc(first.groupId).get()).get('storageQuotaBytes')).toBe(500 * MB);
    await asRoot(admin.adminUpdateConfig, settings({ defaultStorageQuotaMb: 2048 }));
    const second = await newTeam('pat');
    expect((await groups().doc(second.groupId).get()).get('storageQuotaBytes')).toBe(2048 * MB);
  });
});
