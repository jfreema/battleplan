// The §3 permission matrix on the server: callables refuse changes on a
// suspended team (to everyone on it) and an archived one (read-only,
// TEAM-9), the way the rules do; the 100-team limit on every path that
// adds a membership (TEAM-2); guardian links leaving with the person
// (TEAM-8); adding players and guardians (PLAYER-1, PLAYER-5); and the
// team link's options and revoke (INV-2, §3), and its preview (INV-5).
// Runs against the Auth, Firestore, and Storage emulators with email and
// FCM faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { deleteMessage } from '../../src/chat/handlers.js';
import type { Email } from '../../src/email/service.js';
import * as invites from '../../src/invites/handlers.js';
import { previewInvite } from '../../src/invites/service.js';
import * as players from '../../src/players/handlers.js';
import { resolveReport } from '../../src/safety/handlers.js';
import { auth, db, storage } from '../../src/shared/admin.js';
import { Collections, Limits } from '../../src/shared/constants.js';
import * as teams from '../../src/teams/handlers.js';

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
const VERIFIED = { email_verified: true };
const ROOT = { superAdmin: true, email_verified: true };

type Callable = { run: (request: never) => Promise<unknown> };
const run = <T = Record<string, unknown>>(fn: Callable, uid: string, data: object = {}, token: object = VERIFIED) =>
  fn.run({ data, auth: { uid, token }, rawRequest: { ip: '1.2.3.4' } } as never) as Promise<T>;

const groups = () => db().collection(Collections.groups);
const members = () => db().collection(Collections.groupMembers);
const isMember = async (g: string, uid: string) => (await members().doc(`${g}_${uid}`).get()).exists;

async function person(uid: string, name: string): Promise<void> {
  const email = `${uid}@example.com`;
  await auth().createUser({ uid, email, displayName: name, emailVerified: true });
  await db().collection(Collections.users).doc(uid).set({
    displayName: name, displayNameLower: name.toLowerCase(), email, emailLower: email, photoPath: null, status: 'active',
  });
}

async function team(id: string, extra: object = {}): Promise<void> {
  await groups().doc(id).set({
    name: id, nameLower: id, sport: 'soccer', teamType: 'youth', ownerId: 'pat', memberCount: 3, playerCount: 1,
    color: null, photoPath: null, archivedAt: null, suspendedAt: null, settings: { membersCanInvite: true },
    createdAt: Timestamp.now(), ...extra,
  });
  for (const [uid, role] of [['pat', 'owner'], ['ada', 'admin'], ['sam', 'member']]) {
    await members().doc(`${id}_${uid}`).set({ groupId: id, uid, role, displayName: uid, photoPath: null });
  }
  await db().collection(Collections.players).doc(`${id}-p1`).set({ groupId: id, displayName: 'Emma' });
}

async function guardian(groupId: string, playerId: string, uid: string): Promise<void> {
  await db().collection(Collections.playerGuardians).doc(`${playerId}_${uid}`).set({ groupId, playerId, uid });
}

/** Puts [uid] on [count] other teams. */
async function onTeams(uid: string, count: number): Promise<void> {
  const batch = db().batch();
  for (let i = 0; i < count; i++) batch.set(members().doc(`other${i}_${uid}`), { groupId: `other${i}`, uid, role: 'member' });
  await batch.commit();
}

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error('Run with npm run emulators:test');
  }
});

// open, suspended and archived: pat owns each, ada is an admin, sam a
// member. root is a super admin on none of them.
beforeEach(async () => {
  const clear = async (url: string) => expect((await fetch(url, { method: 'DELETE' })).ok).toBe(true);
  await clear(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project()}/databases/(default)/documents`);
  await clear(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${project()}/accounts`);
  mail.sent.length = 0;
  for (const [uid, name] of [['pat', 'Pat Owner'], ['ada', 'Ada Admin'], ['sam', 'Sam Rivera'], ['lee', 'Lee Kim'], ['root', 'Root']]) {
    await person(uid, name);
  }
  await team('open');
  await team('suspended', { suspendedAt: Timestamp.now() });
  await team('archived', { archivedAt: Timestamp.now() });
});

describe('a suspended team takes no changes from anyone on it (§3)', () => {
  const calls: [string, Callable, (g: string) => object][] = [
    ['updateGroupMember', teams.updateGroupMember, (g) => ({ groupId: g, uid: 'sam', role: 'admin' })],
    ['removeMember', teams.removeMember, (g) => ({ groupId: g, uid: 'sam' })],
    ['addMemberByEmail', teams.addMemberByEmail, (g) => ({ groupId: g, entries: [{ email: 'new@example.com' }] })],
    ['resendSetupEmail', teams.resendSetupEmail, (g) => ({ groupId: g, uid: 'sam' })],
    ['transferOwnership', teams.transferOwnership, (g) => ({ groupId: g, uid: 'ada' })],
    ['archiveGroup', teams.archiveGroup, (g) => ({ groupId: g, archived: true })],
    ['deleteGroup', teams.deleteGroup, (g) => ({ groupId: g, confirmName: g })],
    ['getTeamInvite', invites.getTeamInvite, (g) => ({ groupId: g })],
    ['resetGroupInvite', invites.resetGroupInvite, (g) => ({ groupId: g })],
    ['addPlayers', players.addPlayers, (g) => ({ groupId: g, players: [{ name: 'Leo', guardians: [] }] })],
    ['inviteGuardian', players.inviteGuardian, (g) => ({ groupId: g, playerId: `${g}-p1`, email: 'x@example.com' })],
  ];

  for (const [name, fn, data] of calls) {
    it(`refuses ${name} for the owner`, async () => {
      await expect(run(fn, 'pat', data('suspended'))).rejects.toMatchObject({ code: 'permission-denied', message: 'team-suspended' });
    });
  }

  it('refuses deleting a message, even your own, and resolving a report', async () => {
    await db().collection(Collections.messages).doc('m1').set({ groupId: 'suspended', authorId: 'sam', type: 'text' });
    await db().collection(Collections.reports).doc('r1').set({ groupId: 'suspended', status: 'open' });
    await expect(run(deleteMessage, 'sam', { messageId: 'm1' })).rejects.toMatchObject({ message: 'team-suspended' });
    await expect(run(resolveReport, 'pat', { reportId: 'r1', outcome: 'dismissed' })).rejects
      .toMatchObject({ message: 'team-suspended' });
    expect((await db().collection(Collections.messages).doc('m1').get()).exists).toBe(true);
  });

  it('still lets a super admin act on it', async () => {
    await run(teams.removeMember, 'root', { groupId: 'suspended', uid: 'sam' }, ROOT);
    expect(await isMember('suspended', 'sam')).toBe(false);
  });
});

describe('an archived team is read-only (TEAM-9)', () => {
  it('refuses roster and invite changes, even from a super admin', async () => {
    for (const [fn, data] of [
      [teams.updateGroupMember, { groupId: 'archived', uid: 'sam', title: 'Coach' }],
      [teams.removeMember, { groupId: 'archived', uid: 'sam' }],
      [teams.transferOwnership, { groupId: 'archived', uid: 'ada' }],
      [invites.getTeamInvite, { groupId: 'archived' }],
      [players.inviteGuardian, { groupId: 'archived', playerId: 'archived-p1', email: 'x@example.com' }],
    ] as [Callable, object][]) {
      await expect(run(fn, 'pat', data)).rejects.toMatchObject({ code: 'failed-precondition', message: 'team-archived' });
      await expect(run(fn, 'root', data, ROOT)).rejects.toMatchObject({ message: 'team-archived' });
    }
    expect(await isMember('archived', 'sam')).toBe(true);
  });

  it('can still be restored, deleted, and left', async () => {
    await run(teams.leaveGroup, 'sam', { groupId: 'archived' });
    expect(await isMember('archived', 'sam')).toBe(false);
    await run(teams.archiveGroup, 'pat', { groupId: 'archived', archived: false });
    expect((await groups().doc('archived').get()).get('archivedAt')).toBeNull();
  });

  it('lets a super admin, not a team admin, moderate it', async () => {
    await db().collection(Collections.messages).doc('m1').set({ groupId: 'archived', authorId: 'sam', type: 'text', attachments: [] });
    await expect(run(deleteMessage, 'pat', { messageId: 'm1' })).rejects.toMatchObject({ message: 'team-archived' });
    await run(deleteMessage, 'root', { messageId: 'm1' }, ROOT);
  });

  it('works as before on an open team', async () => {
    await run(teams.updateGroupMember, 'ada', { groupId: 'open', uid: 'sam', title: 'Coach' });
    expect((await members().doc('open_sam').get()).get('title')).toBe('Coach');
  });
});

describe('the 100-team limit on every way in (TEAM-2)', () => {
  it('skips someone on 100 teams when adding by email, and lists who was added', async () => {
    await onTeams('lee', Limits.groupsPerUserMax);
    const result = await run(teams.addMemberByEmail, 'pat', {
      groupId: 'open',
      entries: [{ email: 'lee@example.com' }, { name: 'Nia Park', email: 'nia@example.com' }],
    });
    expect(result.problems).toEqual(['lee@example.com (too-many-teams)']);
    expect(result.invitedPeople).toEqual([{ name: 'Nia Park', email: 'nia@example.com' }]);
    expect(await isMember('open', 'lee')).toBe(false);
  });

  it('lists people who already had an account as added', async () => {
    const result = await run(teams.addMemberByEmail, 'pat', { groupId: 'open', entries: [{ email: 'lee@example.com' }] });
    expect(result.addedPeople).toEqual([{ name: 'Lee Kim', email: 'lee@example.com' }]);
  });

  it('refuses a guardian on 100 teams, from addPlayers and inviteGuardian', async () => {
    await onTeams('lee', Limits.groupsPerUserMax);
    const result = await run(players.addPlayers, 'pat', {
      groupId: 'open',
      players: [{ name: 'Leo', guardians: [{ email: 'lee@example.com' }] }],
    });
    expect(result.problems).toEqual(['Leo: lee@example.com (too-many-teams)']);
    await expect(run(players.inviteGuardian, 'pat', { groupId: 'open', playerId: 'open-p1', email: 'lee@example.com' }))
      .rejects.toMatchObject({ message: 'too-many-teams' });
    expect(await isMember('open', 'lee')).toBe(false);
  });
});

describe('adding players (PLAYER-1) and guardians (PLAYER-5, §3)', () => {
  it('counts 200 lines, one per guardian, not 200 players', async () => {
    const pair = [{ email: 'a@example.com' }, { email: 'b@example.com' }];
    const list = Array.from({ length: 101 }, (_, i) => ({ name: `P${i}`, guardians: pair }));
    await expect(run(players.addPlayers, 'pat', { groupId: 'open', players: list })).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('lists guardians given a name and no email instead of dropping them', async () => {
    const result = await run(players.addPlayers, 'pat', {
      groupId: 'open',
      players: [{ name: 'Leo', guardians: [{ name: 'Maria R.' }] }],
    });
    expect(result.guardiansWithoutEmail).toEqual(['Leo: Maria R.']);
    expect(result.playersAdded).toBe(1);
  });

  it('needs a verified email to add guardians by email', async () => {
    const data = { groupId: 'open', players: [{ name: 'Leo', guardians: [{ email: 'lee@example.com' }] }] };
    await expect(run(players.addPlayers, 'pat', data, {})).rejects.toMatchObject({ message: 'email-not-verified' });
    await expect(run(players.inviteGuardian, 'pat', { groupId: 'open', playerId: 'open-p1', email: 'lee@example.com' }, {}))
      .rejects.toMatchObject({ message: 'email-not-verified' });
  });

  it('lets a super admin not on the team add a guardian', async () => {
    await run(players.inviteGuardian, 'root', { groupId: 'open', playerId: 'open-p1', email: 'lee@example.com' }, ROOT);
    expect((await db().collection(Collections.playerGuardians).doc('open-p1_lee').get()).exists).toBe(true);
  });

  it('still keeps members to their own players', async () => {
    await expect(run(players.inviteGuardian, 'sam', { groupId: 'open', playerId: 'open-p1', email: 'lee@example.com' }))
      .rejects.toMatchObject({ code: 'permission-denied' });
  });
});

describe('leaving or being removed takes guardian links and requests too (TEAM-8)', () => {
  beforeEach(async () => {
    await guardian('open', 'open-p1', 'sam');
    await db().collection(Collections.guardianRequests).doc('open-p2_sam').set({ groupId: 'open', playerId: 'open-p2', uid: 'sam', status: 'pending' });
    await guardian('archived', 'archived-p1', 'sam');
  });

  const left = async () => ({
    links: (await db().collection(Collections.playerGuardians).where('uid', '==', 'sam').get()).docs.map((d) => d.id),
    requests: (await db().collection(Collections.guardianRequests).where('uid', '==', 'sam').get()).size,
  });

  it('on leaving', async () => {
    await run(teams.leaveGroup, 'sam', { groupId: 'open' });
    expect(await left()).toEqual({ links: ['archived-p1_sam'], requests: 0 });
  });

  it('on removal', async () => {
    await run(teams.removeMember, 'ada', { groupId: 'open', uid: 'sam' });
    expect(await left()).toEqual({ links: ['archived-p1_sam'], requests: 0 });
  });

  it("an old request never puts someone who left back on the team", async () => {
    await db().collection(Collections.players).doc('open-p2').set({ groupId: 'open', displayName: 'Leo' });
    await members().doc('open_sam').delete();
    const done = await run(players.resolveGuardianLink, 'pat', { groupId: 'open', playerId: 'open-p2', uid: 'sam', approve: true });
    expect(done).toEqual({ ok: false });
    expect(await isMember('open', 'sam')).toBe(false);
  });
});

describe("the team's link (INV-2, §3)", () => {
  it('sets an expiry and use limit keeping the code', async () => {
    const link = await run<{ code: string }>(invites.getTeamInvite, 'ada', { groupId: 'open' });
    const updated = await run<{ code: string; maxUses: number; expiresAt: string }>(invites.updateGroupInvite, 'ada', {
      groupId: 'open', expiresInDays: 7, maxUses: 20,
    });
    expect(updated.code).toBe(link.code);
    expect(updated.maxUses).toBe(20);
    expect(Date.parse(updated.expiresAt) - Date.now()).toBeGreaterThan(6 * 86_400_000);
    const cleared = await run<{ maxUses: number | null; expiresAt: string | null }>(invites.updateGroupInvite, 'ada', { groupId: 'open' });
    expect(cleared).toMatchObject({ maxUses: null, expiresAt: null });
  });

  it('turns it off until an admin turns a new one on', async () => {
    const link = await run<{ code: string }>(invites.getTeamInvite, 'ada', { groupId: 'open' });
    await expect(run(invites.revokeGroupInvite, 'sam', { groupId: 'open' })).rejects.toMatchObject({ code: 'permission-denied' });
    await run(invites.revokeGroupInvite, 'ada', { groupId: 'open' });
    expect(await previewInvite(link.code)).toBe('revoked');
    await expect(run(invites.getTeamInvite, 'sam', { groupId: 'open' })).rejects.toMatchObject({ message: 'link-off' });
    await expect(run(invites.updateGroupInvite, 'ada', { groupId: 'open', maxUses: 5 })).rejects.toMatchObject({ message: 'link-off' });
    const fresh = await run<{ code: string }>(invites.resetGroupInvite, 'ada', { groupId: 'open' });
    expect(fresh.code).not.toBe(link.code);
    expect((await run<{ code: string }>(invites.getTeamInvite, 'sam', { groupId: 'open' })).code).toBe(fresh.code);
  });

  it("shows the team's logo in the preview (INV-5)", async () => {
    const path = 'groups/open/logo.jpg';
    await storage().bucket().file(path).save(Buffer.from('logo'), {
      contentType: 'image/jpeg',
      metadata: { metadata: { firebaseStorageDownloadTokens: 'tok' } },
    });
    await groups().doc('open').update({ photoPath: path });
    const link = await run<{ code: string }>(invites.getTeamInvite, 'ada', { groupId: 'open' });
    const preview = (await previewInvite(link.code)) as { logoUrl: string | null };
    expect(preview.logoUrl).toContain('tok');
    await groups().doc('open').update({ photoPath: null });
    expect(((await previewInvite(link.code)) as { logoUrl: string | null }).logoUrl).toBeNull();
  });
});
