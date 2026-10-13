// The §3 permission matrix on the server: callables refuse changes on a
// suspended team (to everyone on it) and an archived one (read-only,
// TEAM-9), the way the rules do; the 100-team limit on every path that
// adds a membership (TEAM-2); player links leaving with the person
// (TEAM-8); adding players and guardians (PLAYER-1, PLAYER-5); claims and
// pending players (PLAYER-3, PLAYER-4); and the
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
import { setMemberRole } from '../../src/teams/service.js';

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
    name: id, nameLower: id, sport: 'soccer', kind: 'team', ownerId: 'pat', memberCount: 3, playerCount: 1,
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
    ['claimPlayer', players.claimPlayer, (g) => ({ playerId: `${g}-p1`, relation: 'self' })],
    ['proposePlayer', players.proposePlayer, (g) => ({ groupId: g, displayName: 'Leo', relation: 'guardian' })],
    ['resolvePlayerClaim', players.resolvePlayerClaim, (g) => ({ playerId: `${g}-p1`, uid: 'sam', approve: true })],
    ['resolvePendingPlayer', players.resolvePendingPlayer, (g) => ({ playerId: `${g}-p1`, approve: true })],
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

describe('leaving or being removed takes player links, claims, and pending players too (TEAM-8)', () => {
  beforeEach(async () => {
    await guardian('open', 'open-p1', 'sam');
    await db().collection(Collections.guardianRequests).doc('open-p2_sam').set({ groupId: 'open', playerId: 'open-p2', uid: 'sam', status: 'pending' });
    await guardian('archived', 'archived-p1', 'sam');
    await db().collection(Collections.players).doc('open-pending').set({
      groupId: 'open', displayName: 'Kai', status: 'pending', proposedBy: 'sam', proposedRelation: 'guardian',
    });
  });

  const left = async () => ({
    links: (await db().collection(Collections.playerGuardians).where('uid', '==', 'sam').get()).docs.map((d) => d.id),
    requests: (await db().collection(Collections.guardianRequests).where('uid', '==', 'sam').get()).size,
    pending: (await db().collection(Collections.players).doc('open-pending').get()).exists,
  });

  it('on leaving', async () => {
    await run(teams.leaveGroup, 'sam', { groupId: 'open' });
    expect(await left()).toEqual({ links: ['archived-p1_sam'], requests: 0, pending: false });
    // Players already on the roster stay.
    expect((await db().collection(Collections.players).doc('open-p1').get()).exists).toBe(true);
  });

  it('on removal', async () => {
    await run(teams.removeMember, 'ada', { groupId: 'open', uid: 'sam' });
    expect(await left()).toEqual({ links: ['archived-p1_sam'], requests: 0, pending: false });
  });

  it("an old claim never puts someone who left back on the team", async () => {
    await db().collection(Collections.players).doc('open-p2').set({ groupId: 'open', displayName: 'Leo' });
    await members().doc('open_sam').delete();
    const done = await run(players.resolvePlayerClaim, 'pat', { groupId: 'open', playerId: 'open-p2', uid: 'sam', approve: true });
    expect(done).toEqual({ ok: false });
    expect(await isMember('open', 'sam')).toBe(false);
  });
});

describe('claims and pending players (PLAYER-3, PLAYER-4)', () => {
  const link = async (playerId: string, uid: string) => (await db().collection(Collections.playerGuardians).doc(`${playerId}_${uid}`).get()).data();
  const player = async (id: string) => (await db().collection(Collections.players).doc(id).get()).data();
  const summary = async (uid: string) => (await members().doc(`open_${uid}`).get()).get('playerSummary');
  /** Center items of [kind]: who got one, and what it said. */
  const items = async (kind: string) =>
    (await db().collection(Collections.notifications).where('type', '==', kind).get()).docs
      .map((d) => `${d.get('uid')}: ${d.get('body')}`)
      .sort();

  it("takes a member's claim to the admins, and links them as a guardian when approved", async () => {
    expect(await run(players.claimPlayer, 'sam', { playerId: 'open-p1', relation: 'guardian' })).toEqual({ status: 'requested' });
    expect(await link('open-p1', 'sam')).toBeUndefined();
    const claim = (await db().collection(Collections.guardianRequests).doc('open-p1_sam').get()).data();
    expect(claim).toMatchObject({ groupId: 'open', uid: 'sam', relation: 'guardian', status: 'pending' });
    expect(await items('guardianRequest')).toEqual([
      "ada: Sam Rivera asked to be Emma's guardian",
      "pat: Sam Rivera asked to be Emma's guardian",
    ]);
    // Only admins decide.
    await expect(run(players.resolvePlayerClaim, 'lee', { playerId: 'open-p1', uid: 'sam', approve: true }))
      .rejects.toMatchObject({ code: 'permission-denied' });
    expect(await run(players.resolvePlayerClaim, 'ada', { playerId: 'open-p1', uid: 'sam', approve: true })).toEqual({ ok: true });
    expect(await link('open-p1', 'sam')).toMatchObject({ relation: 'guardian', via: 'request', addedBy: 'ada' });
    expect(await summary('sam')).toBe('Emma');
    expect(await items('guardianApproved')).toEqual(["sam: You're now Emma's guardian"]);
    expect((await db().collection(Collections.guardianRequests).doc('open-p1_sam').get()).get('status')).toBe('approved');
  });

  it('links "I am this player" as self, showing their number in Who\'s who (PLAYER-8)', async () => {
    await db().collection(Collections.players).doc('open-p1').update({ displayName: 'Sam Rivera', jerseyNumber: '12' });
    await run(players.claimPlayer, 'sam', { groupId: 'open', playerId: 'open-p1', relation: 'self' });
    expect(await items('guardianRequest')).toContain('pat: Sam Rivera asked to be linked as the player Sam Rivera');
    await run(players.resolvePlayerClaim, 'pat', { playerId: 'open-p1', uid: 'sam', approve: true });
    expect(await link('open-p1', 'sam')).toMatchObject({ relation: 'self' });
    expect(await summary('sam')).toBe('#12');
    expect(await items('guardianApproved')).toEqual(["sam: You're now on the roster as Sam Rivera"]);
  });

  it("approves an admin's own claim at once, with no request", async () => {
    expect(await run(players.claimPlayer, 'ada', { playerId: 'open-p1', relation: 'self' })).toEqual({ status: 'linked' });
    expect(await link('open-p1', 'ada')).toMatchObject({ relation: 'self', via: 'claim' });
    expect((await db().collection(Collections.guardianRequests).doc('open-p1_ada').get()).exists).toBe(false);
    expect(await items('guardianRequest')).toEqual([]);
  });

  it('keeps one self link per player and one player per member on a team', async () => {
    await run(players.claimPlayer, 'ada', { playerId: 'open-p1', relation: 'self' });
    await expect(run(players.claimPlayer, 'sam', { playerId: 'open-p1', relation: 'self' }))
      .rejects.toMatchObject({ code: 'failed-precondition', message: 'player-already-claimed' });
    await db().collection(Collections.players).doc('open-p2').set({ groupId: 'open', displayName: 'Leo', status: 'active' });
    await expect(run(players.claimPlayer, 'ada', { playerId: 'open-p2', relation: 'self' }))
      .rejects.toMatchObject({ message: 'already-a-player' });
    // Already linked to this one.
    await expect(run(players.claimPlayer, 'ada', { playerId: 'open-p1', relation: 'guardian' }))
      .rejects.toMatchObject({ message: 'already-linked' });
    // A guardian claim on a player who has a self link is fine.
    expect(await run(players.claimPlayer, 'sam', { playerId: 'open-p1', relation: 'guardian' })).toEqual({ status: 'requested' });
  });

  it("checks the limits again on approval, and leaves the claim for a decline", async () => {
    await run(players.claimPlayer, 'sam', { playerId: 'open-p1', relation: 'self' });
    await run(players.claimPlayer, 'ada', { playerId: 'open-p1', relation: 'self' });
    await expect(run(players.resolvePlayerClaim, 'pat', { playerId: 'open-p1', uid: 'sam', approve: true }))
      .rejects.toMatchObject({ message: 'player-already-claimed' });
    expect((await db().collection(Collections.guardianRequests).doc('open-p1_sam').get()).get('status')).toBe('pending');
    expect(await run(players.resolvePlayerClaim, 'pat', { playerId: 'open-p1', uid: 'sam', approve: false })).toEqual({ ok: true });
    expect(await link('open-p1', 'sam')).toBeUndefined();
    expect(await items('guardianApproved')).toEqual([]);
  });

  it("allows 4 guardians, not counting the player's own link", async () => {
    for (const uid of ['g1', 'g2', 'g3']) await guardian('open', 'open-p1', uid);
    await db().collection(Collections.playerGuardians).doc('open-p1_ada').set({ groupId: 'open', playerId: 'open-p1', uid: 'ada', relation: 'self' });
    expect(await run(players.claimPlayer, 'sam', { playerId: 'open-p1', relation: 'guardian' })).toEqual({ status: 'requested' });
    await guardian('open', 'open-p1', 'g4');
    await expect(run(players.claimPlayer, 'pat', { playerId: 'open-p1', relation: 'guardian' }))
      .rejects.toMatchObject({ message: 'too-many-guardians' });
    await expect(run(players.resolvePlayerClaim, 'pat', { playerId: 'open-p1', uid: 'sam', approve: true }))
      .rejects.toMatchObject({ message: 'too-many-guardians' });
  });

  it('refuses claims from non-members, on pending players, and with a mismatched team', async () => {
    await expect(run(players.claimPlayer, 'lee', { playerId: 'open-p1', relation: 'guardian' })).rejects.toMatchObject({ code: 'permission-denied' });
    await db().collection(Collections.players).doc('open-pending').set({ groupId: 'open', displayName: 'Kai', status: 'pending', proposedBy: 'ada' });
    await expect(run(players.claimPlayer, 'sam', { playerId: 'open-pending', relation: 'guardian' })).rejects.toMatchObject({ code: 'not-found' });
    await expect(run(players.claimPlayer, 'sam', { groupId: 'archived', playerId: 'open-p1', relation: 'guardian' }))
      .rejects.toMatchObject({ code: 'not-found' });
    await expect(run(players.claimPlayer, 'sam', { playerId: 'nope', relation: 'guardian' })).rejects.toMatchObject({ code: 'not-found' });
  });

  it("holds a member's new player for approval, unseen on the roster, and links them on approval", async () => {
    const res = await run<{ playerId: string; status: string }>(players.proposePlayer, 'sam', {
      groupId: 'open', displayName: 'Leo Rivera', jerseyNumber: '9', relation: 'guardian',
    });
    expect(res.status).toBe('pending');
    expect(await player(res.playerId)).toMatchObject({
      status: 'pending', proposedBy: 'sam', proposedRelation: 'guardian', decidedBy: null, jerseyNumber: '9',
    });
    // No link until it's approved, so the roster's links never show it.
    expect(await link(res.playerId, 'sam')).toBeUndefined();
    expect((await groups().doc('open').get()).get('playerCount')).toBe(1);
    expect(await items('guardianRequest')).toEqual([
      'ada: Sam Rivera asked to add a player: Leo Rivera',
      'pat: Sam Rivera asked to add a player: Leo Rivera',
    ]);
    await expect(run(players.resolvePendingPlayer, 'sam', { playerId: res.playerId, approve: true }))
      .rejects.toMatchObject({ code: 'permission-denied' });
    expect(await run(players.resolvePendingPlayer, 'pat', { playerId: res.playerId, approve: true })).toEqual({ ok: true, linked: true });
    expect(await player(res.playerId)).toMatchObject({ status: 'active', decidedBy: 'pat' });
    expect(await link(res.playerId, 'sam')).toMatchObject({ relation: 'guardian', via: 'proposal' });
    expect(await summary('sam')).toBe('Leo #9');
    expect((await groups().doc('open').get()).get('playerCount')).toBe(2);
    expect(await items('guardianApproved')).toEqual(['sam: Leo Rivera was added to the roster']);
    // Decided once.
    expect(await run(players.resolvePendingPlayer, 'pat', { playerId: res.playerId, approve: true })).toEqual({ ok: false, linked: false });
  });

  it('deletes a declined player, quietly', async () => {
    const res = await run<{ playerId: string }>(players.proposePlayer, 'sam', { groupId: 'open', displayName: 'Sam Rivera', relation: 'self' });
    expect(await items('guardianRequest')).toContain('pat: Sam Rivera asked to join the roster as Sam Rivera');
    expect(await run(players.resolvePendingPlayer, 'ada', { playerId: res.playerId, approve: false })).toEqual({ ok: true, linked: false });
    expect(await player(res.playerId)).toBeUndefined();
    expect(await items('guardianApproved')).toEqual([]);
  });

  it("makes an admin's new player active at once, linked as they said", async () => {
    const res = await run<{ playerId: string; status: string }>(players.proposePlayer, 'ada', {
      groupId: 'open', displayName: 'Ada Admin', jerseyNumber: '3', relation: 'self',
    });
    expect(res.status).toBe('active');
    expect(await link(res.playerId, 'ada')).toMatchObject({ relation: 'self' });
    expect(await summary('ada')).toBe('#3');
    expect((await groups().doc('open').get()).get('playerCount')).toBe(2);
    expect(await items('guardianRequest')).toEqual([]);
  });

  it('lets a member be one player per team, pending or not', async () => {
    await run(players.proposePlayer, 'sam', { groupId: 'open', displayName: 'Sam Rivera', relation: 'self' });
    await expect(run(players.proposePlayer, 'sam', { groupId: 'open', displayName: 'Sam R', relation: 'self' }))
      .rejects.toMatchObject({ message: 'already-a-player' });
    // Adding their child is fine.
    expect((await run<{ status: string }>(players.proposePlayer, 'sam', { groupId: 'open', displayName: 'Leo', relation: 'guardian' })).status)
      .toBe('pending');
  });

  it("skips the proposer's self link on approval when they became a player meanwhile", async () => {
    const res = await run<{ playerId: string }>(players.proposePlayer, 'sam', { groupId: 'open', displayName: 'Sam Rivera', relation: 'self' });
    await db().collection(Collections.playerGuardians).doc('open-p1_sam').set({ groupId: 'open', playerId: 'open-p1', uid: 'sam', relation: 'self' });
    expect(await run(players.resolvePendingPlayer, 'pat', { playerId: res.playerId, approve: true })).toEqual({ ok: true, linked: false });
    expect((await player(res.playerId))?.status).toBe('active');
    expect(await items('guardianApproved')).toEqual([]);
  });

  it('counts pending players toward the 200-player limit (PLAYER-1)', async () => {
    const batch = db().batch();
    for (let i = 1; i < Limits.playersPerGroupMax; i++) {
      batch.set(db().collection(Collections.players).doc(`bulk${i}`), { groupId: 'open', displayName: `P${i}`, status: 'pending', proposedBy: 'lee' });
    }
    await batch.commit();
    await expect(run(players.proposePlayer, 'sam', { groupId: 'open', displayName: 'Leo', relation: 'guardian' }))
      .rejects.toMatchObject({ message: 'too-many-players' });
    await expect(run(players.addPlayers, 'pat', { groupId: 'open', players: [{ name: 'Leo', guardians: [] }] }))
      .rejects.toMatchObject({ message: 'too-many-players' });
  });

  it("won't make the player their own guardian by email", async () => {
    await db().collection(Collections.playerGuardians).doc('open-p1_lee').set({ groupId: 'open', playerId: 'open-p1', uid: 'lee', relation: 'self' });
    await expect(run(players.inviteGuardian, 'pat', { groupId: 'open', playerId: 'open-p1', email: 'lee@example.com' }))
      .rejects.toMatchObject({ message: 'already-linked' });
    // The player themselves doesn't add guardians either.
    await members().doc('open_lee').set({ groupId: 'open', uid: 'lee', role: 'member', displayName: 'Lee' });
    await expect(run(players.inviteGuardian, 'lee', { groupId: 'open', playerId: 'open-p1', email: 'x@example.com' }))
      .rejects.toMatchObject({ code: 'permission-denied' });
  });
});

describe('reports about someone promoted (SAFE-1)', () => {
  const report = (id: string, subjectId: string, status = 'open') =>
    db().collection(Collections.reports).doc(id).set({
      groupId: 'open', subjectId, reporterId: 'lee', status, teamVisible: true, createdAt: Timestamp.now(),
    });
  const visible = async (id: string) => (await db().collection(Collections.reports).doc(id).get()).get('teamVisible');

  it('go to the super-admin queue when a member is made an admin', async () => {
    await report('r1', 'sam');
    await report('r2', 'sam', 'dismissed');
    await report('r3', 'lee');
    await run(teams.updateGroupMember, 'pat', { groupId: 'open', uid: 'sam', role: 'admin' });
    expect(await visible('r1')).toBe(false);
    // Closed reports and reports about others stay as they were.
    expect(await visible('r2')).toBe(true);
    expect(await visible('r3')).toBe(true);
  });

  it('go to the super-admin queue when a member is handed the team', async () => {
    await report('r1', 'sam');
    await run(teams.transferOwnership, 'pat', { groupId: 'open', uid: 'sam' });
    expect(await visible('r1')).toBe(false);
  });

  it('go to the super-admin queue when the admin panel adds them as an admin (ADMIN-4)', async () => {
    await report('r1', 'sam');
    await setMemberRole('open', 'sam', 'admin');
    expect(await visible('r1')).toBe(false);
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

  it('stays off when revoked by code from the admin panel (ADMIN-3), and only admins can', async () => {
    const link = await run<{ code: string }>(invites.getTeamInvite, 'sam', { groupId: 'open' });
    // Sam opened the link first, but it is the team's: only admins turn it off.
    await expect(run(invites.revokeInvite, 'sam', { code: link.code })).rejects.toMatchObject({ code: 'permission-denied' });
    await run(invites.revokeInvite, 'root', { code: link.code }, ROOT);
    expect(await previewInvite(link.code)).toBe('revoked');
    await expect(run(invites.getTeamInvite, 'sam', { groupId: 'open' })).rejects.toMatchObject({ message: 'link-off' });
    await expect(run(invites.getTeamInvite, 'ada', { groupId: 'open' })).rejects.toMatchObject({ message: 'link-off' });
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
