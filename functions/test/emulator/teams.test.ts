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
import * as service from '../../src/players/service.js';
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

describe('a basic group has no players or guardians (TEAM-14)', () => {
  beforeEach(async () => {
    await team('club', { kind: 'group', sport: 'other', playerCount: 0 });
    await db().collection(Collections.players).doc('club-p1').delete();
  });

  it('refuses adding, claiming, and proposing players, and guardians', async () => {
    const refused = { code: 'failed-precondition', message: 'no-players' };
    await expect(run(players.addPlayers, 'pat', { groupId: 'club', players: [{ name: 'Leo', guardians: [] }] })).rejects
      .toMatchObject(refused);
    await expect(run(players.proposePlayer, 'sam', { groupId: 'club', displayName: 'Leo', relation: 'guardian' })).rejects
      .toMatchObject(refused);
    await expect(run(players.addPlayers, 'root', { groupId: 'club', players: [{ name: 'Leo', guardians: [] }] }, ROOT))
      .rejects.toMatchObject(refused);
    expect((await db().collection(Collections.players).where('groupId', '==', 'club').get()).empty).toBe(true);
  });

  it('has no coaches: an older app asking makes no change', async () => {
    await run(teams.updateGroupMember, 'pat', { groupId: 'club', uid: 'sam', coach: true });
    expect((await members().doc('club_sam').get()).get('coach')).toBeUndefined();
    // Its title still changes.
    await run(teams.updateGroupMember, 'pat', { groupId: 'club', uid: 'sam', title: 'Treasurer' });
    expect((await members().doc('club_sam').get()).get('title')).toBe('Treasurer');
  });

  it('its owner makes it a team, with a sport: one way, said in the chat, and audited', async () => {
    await members().doc('club_pat').update({ coach: false });
    await expect(run(teams.convertToTeam, 'ada', { groupId: 'club', sport: 'soccer' })).rejects
      .toMatchObject({ code: 'permission-denied' });
    await expect(run(teams.convertToTeam, 'pat', { groupId: 'club', sport: 'chess' })).rejects
      .toMatchObject({ code: 'invalid-argument' });
    await run(teams.convertToTeam, 'pat', { groupId: 'club', sport: 'soccer' });
    const club = await groups().doc('club').get();
    expect(club.get('kind')).toBe('team');
    expect(club.get('sport')).toBe('soccer');
    // The owner coaches now, as a team's does by default.
    expect((await members().doc('club_pat').get()).get('coach')).toBeUndefined();
    const lines = await db().collection(Collections.messages).where('groupId', '==', 'club').get();
    expect(lines.docs.map((d) => d.get('text'))).toContain('Pat Owner made this group a team');
    const audits = await db().collection(Collections.auditLogs).where('action', '==', 'convertToTeam').get();
    expect(audits.docs[0]?.get('after')).toEqual({ kind: 'team', sport: 'soccer' });
    // Now it takes players; and a team can't be made a team again.
    await run(players.addPlayers, 'pat', { groupId: 'club', players: [{ name: 'Leo', guardians: [] }] });
    await expect(run(teams.convertToTeam, 'pat', { groupId: 'club', sport: 'soccer' })).rejects
      .toMatchObject({ code: 'failed-precondition', message: 'not-a-group' });
    await expect(run(teams.convertToTeam, 'pat', { groupId: 'open', sport: 'soccer' })).rejects
      .toMatchObject({ message: 'not-a-group' });
  });

  it('a super admin can make one a team; an archived one waits to be restored', async () => {
    await run(teams.convertToTeam, 'root', { groupId: 'club', sport: 'baseball' }, ROOT);
    expect((await groups().doc('club').get()).get('kind')).toBe('team');
    await team('closed', { kind: 'group', sport: 'other', archivedAt: Timestamp.now() });
    await expect(run(teams.convertToTeam, 'pat', { groupId: 'closed', sport: 'soccer' })).rejects
      .toMatchObject({ message: 'team-archived' });
  });

  it("an invite's preview says it's a group", async () => {
    const link = await run<{ code: string }>(invites.getTeamInvite, 'pat', { groupId: 'club' });
    expect(await previewInvite(link.code)).toMatchObject({ name: 'club', kind: 'group' });
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
  });

  it('lets the member who is the player add a guardian, as any linked member can (PLAYER-5)', async () => {
    await members().doc('open_lee').set({ groupId: 'open', uid: 'lee', role: 'member', displayName: 'Lee' });
    await db().collection(Collections.playerGuardians).doc('open-p1_lee').set({ groupId: 'open', playerId: 'open-p1', uid: 'lee', relation: 'self' });
    expect(await run(players.inviteGuardian, 'lee', { groupId: 'open', playerId: 'open-p1', email: 'sam@example.com' }))
      .toEqual({ uid: 'sam', invited: false });
    expect(await link('open-p1', 'sam')).toMatchObject({ relation: 'guardian', via: 'guardian', addedBy: 'lee' });
  });
});

describe('adding someone already on the team as a guardian (PLAYER-5)', () => {
  const link = async (uid: string) => (await db().collection(Collections.playerGuardians).doc(`open-p1_${uid}`).get()).data();
  const approvals = async () =>
    (await db().collection(Collections.notifications).where('type', '==', 'guardianApproved').get()).docs.map(
      (d) => `${d.get('uid')}: ${d.get('body')}`,
    );
  const byUid = (uid: string) => ({ groupId: 'open', playerId: 'open-p1', uid });
  const join = (uid: string) => members().doc(`open_${uid}`).set({ groupId: 'open', uid, role: 'member', displayName: uid });

  it('links them with no email and no verified email needed, and tells them', async () => {
    expect(await run(players.inviteGuardian, 'pat', byUid('sam'), {})).toEqual({ uid: 'sam', invited: false });
    expect(await link('sam')).toMatchObject({ relation: 'guardian', via: 'guardian', addedBy: 'pat' });
    expect((await members().doc('open_sam').get()).get('playerSummary')).toBeTruthy();
    expect(await approvals()).toEqual(["sam: You're now Emma's guardian"]);
    expect(mail.sent).toEqual([]);
    // Again changes nothing and tells no one twice.
    await run(players.inviteGuardian, 'pat', byUid('sam'));
    expect(await approvals()).toHaveLength(1);
  });

  it('lets a linked member pick, and keeps other members to their own players', async () => {
    await join('lee');
    await expect(run(players.inviteGuardian, 'lee', byUid('sam'))).rejects.toMatchObject({ code: 'permission-denied' });
    await guardian('open', 'open-p1', 'sam');
    await run(players.inviteGuardian, 'sam', byUid('lee'));
    expect(await link('lee')).toMatchObject({ relation: 'guardian', addedBy: 'sam' });
  });

  it("refuses someone who isn't on the team, and the member who is the player", async () => {
    await expect(run(players.inviteGuardian, 'pat', byUid('lee'))).rejects.toMatchObject({ code: 'not-found', message: 'no-member' });
    expect(await isMember('open', 'lee')).toBe(false);
    await join('lee');
    await db().collection(Collections.playerGuardians).doc('open-p1_lee').set({ groupId: 'open', playerId: 'open-p1', uid: 'lee', relation: 'self' });
    await expect(run(players.inviteGuardian, 'pat', byUid('lee'))).rejects.toMatchObject({ message: 'already-linked' });
  });

  it('takes an email or a uid, not both or neither', async () => {
    await expect(run(players.inviteGuardian, 'pat', { ...byUid('sam'), email: 'sam@example.com' }))
      .rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(run(players.inviteGuardian, 'pat', { groupId: 'open', playerId: 'open-p1' }))
      .rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

describe('more claims and player emails (PLAYER-1, PLAYER-3, PLAYER-4, PLAYER-6, PLAYER-8)', () => {
  const links = () => db().collection(Collections.playerGuardians);
  const link = async (playerId: string, uid: string) => (await links().doc(`${playerId}_${uid}`).get()).data();
  const linksOf = async (playerId: string) =>
    (await links().where('playerId', '==', playerId).get()).docs.map((d) => `${d.get('uid')}:${d.get('relation') ?? 'guardian'}`).sort();
  const summary = async (uid: string) => (await members().doc(`open_${uid}`).get()).get('playerSummary');
  const addPlayer = (id: string, extra: object = {}) =>
    db().collection(Collections.players).doc(id).set({ groupId: 'open', displayName: id, status: 'active', ...extra });
  const claim = (playerId: string, uid: string, relation: string) =>
    db().collection(Collections.guardianRequests).doc(`${playerId}_${uid}`).set({ groupId: 'open', playerId, uid, relation, status: 'pending' });
  const join = (uid: string, role = 'member') => members().doc(`open_${uid}`).set({ groupId: 'open', uid, role, displayName: uid });
  /** Runs [calls] at the same time; how many went through, and the refusals' messages. */
  const together = async (calls: Promise<unknown>[]) => {
    const settled = await Promise.allSettled(calls);
    return {
      ok: settled.filter((r) => r.status === 'fulfilled').length,
      refused: settled.flatMap((r) => (r.status === 'rejected' ? [(r.reason as Error).message] : [])),
    };
  };

  // Two transactions that read and write the same player or membership
  // deadlock on the emulator, which aborts both after a few seconds and
  // retries them; production Firestore settles this at once.
  describe('keeps the limits when approvals run at the same time (PLAYER-3)', { timeout: 45_000 }, () => {
    it('two "I am this player" claims on one player: one link', async () => {
      await join('lee');
      await claim('open-p1', 'sam', 'self');
      await claim('open-p1', 'lee', 'self');
      const result = await together([
        run(players.resolvePlayerClaim, 'pat', { playerId: 'open-p1', uid: 'sam', approve: true }),
        run(players.resolvePlayerClaim, 'ada', { playerId: 'open-p1', uid: 'lee', approve: true }),
      ]);
      expect(result).toEqual({ ok: 1, refused: ['player-already-claimed'] });
      expect((await linksOf('open-p1')).filter((l) => l.endsWith(':self'))).toHaveLength(1);
    });

    it("one member's self claims on two players: self for one", async () => {
      await addPlayer('open-p2');
      await claim('open-p1', 'sam', 'self');
      await claim('open-p2', 'sam', 'self');
      const result = await together([
        run(players.resolvePlayerClaim, 'pat', { playerId: 'open-p1', uid: 'sam', approve: true }),
        run(players.resolvePlayerClaim, 'ada', { playerId: 'open-p2', uid: 'sam', approve: true }),
      ]);
      expect(result).toEqual({ ok: 1, refused: ['already-a-player'] });
      expect((await links().where('uid', '==', 'sam').get()).size).toBe(1);
    });

    it('two guardian claims on a player with 3 guardians: 4 guardians, not 5', async () => {
      for (const uid of ['g1', 'g2', 'g3']) await guardian('open', 'open-p1', uid);
      await join('lee');
      await claim('open-p1', 'sam', 'guardian');
      await claim('open-p1', 'lee', 'guardian');
      const result = await together([
        run(players.resolvePlayerClaim, 'pat', { playerId: 'open-p1', uid: 'sam', approve: true }),
        run(players.resolvePlayerClaim, 'ada', { playerId: 'open-p1', uid: 'lee', approve: true }),
      ]);
      expect(result).toEqual({ ok: 1, refused: ['too-many-guardians'] });
      expect(await linksOf('open-p1')).toHaveLength(4);
    });

    it("two admins' own claims at once (approved at once): one self link", async () => {
      const result = await together([
        run(players.claimPlayer, 'pat', { playerId: 'open-p1', relation: 'self' }),
        run(players.claimPlayer, 'ada', { playerId: 'open-p1', relation: 'self' }),
      ]);
      expect(result).toEqual({ ok: 1, refused: ['player-already-claimed'] });
      expect(await linksOf('open-p1')).toHaveLength(1);
    });

    it("an admin adding themselves twice at once: one player, no unlinked duplicate", async () => {
      const result = await together([
        run(players.proposePlayer, 'ada', { groupId: 'open', displayName: 'Ada Admin', relation: 'self' }),
        run(players.proposePlayer, 'ada', { groupId: 'open', displayName: 'Ada A', relation: 'self' }),
      ]);
      expect(result).toEqual({ ok: 1, refused: ['already-a-player'] });
      expect((await db().collection(Collections.players).where('proposedBy', '==', 'ada').get()).size).toBe(1);
      expect((await links().where('uid', '==', 'ada').get()).size).toBe(1);
    });

    it("never puts someone who left back on the team, checked in the link's transaction", async () => {
      await expect(
        service.linkGuardian('open', 'open-p1', { uid: 'lee', displayName: 'Lee', photoPath: null }, 'pat', 'request', 'guardian', {
          requireMember: true,
        }),
      ).rejects.toMatchObject({ message: 'left-team' });
      expect(await isMember('open', 'lee')).toBe(false);
      expect(await link('open-p1', 'lee')).toBeUndefined();
    });
  });

  describe("adding players with the player's own email (PLAYER-1)", () => {
    it('links an existing account as the player, and gives a new email an added account linked as the player', async () => {
      const result = await run(players.addPlayers, 'pat', {
        groupId: 'open',
        players: [
          { name: 'Lee Kim', jerseyNumber: '12', email: 'lee@example.com', guardians: [] },
          { name: 'Nia Park', jerseyNumber: '4', email: 'nia@example.com', guardians: [{ name: 'Ola Park', email: 'ola@example.com' }] },
        ],
      });
      expect(result).toMatchObject({ playersAdded: 2, selfLinked: 1, selfInvited: 1, guardiansInvited: 1, problems: [] });
      expect(result.invitedEmails).toEqual(['nia@example.com', 'ola@example.com']);
      const lee = (await links().where('uid', '==', 'lee').get()).docs[0];
      expect(lee.data()).toMatchObject({ relation: 'self', via: 'admin' });
      expect(await summary('lee')).toBe('#12');
      const nia = await auth().getUserByEmail('nia@example.com');
      const niaLink = (await links().where('uid', '==', nia.uid).get()).docs[0];
      expect(niaLink.get('relation')).toBe('self');
      expect(niaLink.get('playerId')).not.toBe(lee.get('playerId'));
      expect((await members().doc(`open_${nia.uid}`).get()).data()).toMatchObject({ pending: true, playerSummary: '#4' });
      // Setup emails go to both new people (AUTH-6).
      expect(mail.sent.map((m) => m.to).sort()).toEqual(['nia@example.com', 'ola@example.com']);
    });

    it("keeps the self limits, and won't take the player's email as their guardian's too", async () => {
      await join('lee');
      await db().collection(Collections.playerGuardians).doc('open-p1_lee').set({ groupId: 'open', playerId: 'open-p1', uid: 'lee', relation: 'self' });
      const result = await run(players.addPlayers, 'pat', {
        groupId: 'open',
        players: [
          { name: 'Leo', email: 'lee@example.com', guardians: [] },
          { name: 'Sam Rivera', email: 'sam@example.com', guardians: [{ email: 'sam@example.com' }] },
        ],
      });
      expect(result.problems).toEqual(['Leo: lee@example.com (already-a-player)', 'Sam Rivera: sam@example.com (already-linked)']);
      expect(result).toMatchObject({ playersAdded: 2, selfLinked: 1, guardiansLinked: 0 });
      expect((await links().where('uid', '==', 'sam').get()).docs.map((d) => d.get('relation'))).toEqual(['self']);
    });

    it("needs a verified email for a player's own email too (AUTH-3)", async () => {
      const data = { groupId: 'open', players: [{ name: 'Lee', email: 'lee@example.com', guardians: [] }] };
      await expect(run(players.addPlayers, 'pat', data, {})).rejects.toMatchObject({ message: 'email-not-verified' });
    });

    it("saves every added player as active, one or several, so the roster's status query finds them", async () => {
      await run(players.addPlayers, 'pat', { groupId: 'open', players: [{ name: 'Leo', guardians: [] }] });
      await run(players.addPlayers, 'pat', {
        groupId: 'open',
        players: [{ name: 'Mia', guardians: [{ name: 'Ana', email: 'ana@example.com' }] }, { name: 'Noah', guardians: [] }],
      });
      const added = await db().collection(Collections.players).where('groupId', '==', 'open').where('status', '==', 'active').get();
      expect(added.docs.map((d) => d.get('displayName')).sort()).toEqual(['Leo', 'Mia', 'Noah']);
    });
  });

  describe("a member's own answers when they become the player (PLAYER-6)", () => {
    const rsvps = () => db().collection(Collections.rsvps);
    const soon = Timestamp.fromMillis(Date.now() + 86_400_000);
    async function event(id: string, startAt: Timestamp): Promise<void> {
      await db().collection(Collections.events).doc(id).set({
        groupId: 'open', title: id, startAt, rsvpEnabled: true,
        rsvpCounts: { going: 0, maybe: 0, notGoing: 0 }, staffCounts: { going: 1, maybe: 0, notGoing: 0 },
      });
    }
    const answer = (eventId: string, participantId: string, participantType: string, status: string, startAt = soon) =>
      rsvps().doc(`${eventId}_${participantId}`).set({
        eventId, groupId: 'open', participantId, participantType, participantName: participantId, status,
        note: '', guests: 0, respondedBy: participantId === 'open-p1' ? 'pat' : participantId, eventStartAt: startAt,
      });

    it("moves each upcoming answer to the player's empty row, drops it where the player has one, and recounts", async () => {
      const past = Timestamp.fromMillis(Date.now() - 86_400_000);
      await event('e1', soon);
      await event('e2', soon);
      await event('e0', past);
      await answer('e1', 'sam', 'member', 'going');
      await answer('e2', 'sam', 'member', 'going');
      await answer('e2', 'open-p1', 'player', 'not_going');
      await answer('e0', 'sam', 'member', 'going', past);
      await claim('open-p1', 'sam', 'self');
      await run(players.resolvePlayerClaim, 'pat', { playerId: 'open-p1', uid: 'sam', approve: true });

      expect((await rsvps().doc('e1_sam').get()).exists).toBe(false);
      expect((await rsvps().doc('e1_open-p1').get()).data()).toMatchObject({
        participantType: 'player', participantId: 'open-p1', participantName: 'Emma', status: 'going', respondedBy: 'sam',
      });
      expect((await rsvps().doc('e2_sam').get()).exists).toBe(false);
      expect((await rsvps().doc('e2_open-p1').get()).get('status')).toBe('not_going');
      // Past answers stay.
      expect((await rsvps().doc('e0_sam').get()).exists).toBe(true);
      const counts = async (id: string) => {
        const e = await db().collection(Collections.events).doc(id).get();
        return { players: e.get('rsvpCounts'), others: e.get('staffCounts') };
      };
      expect(await counts('e1')).toEqual({ players: { going: 1, maybe: 0, notGoing: 0 }, others: { going: 0, maybe: 0, notGoing: 0 } });
      expect(await counts('e2')).toEqual({ players: { going: 0, maybe: 0, notGoing: 1 }, others: { going: 0, maybe: 0, notGoing: 0 } });
    });

    it("moves an admin's own answer too: an admin who is the player answers on the player's row", async () => {
      await event('e1', soon);
      await answer('e1', 'ada', 'member', 'going');
      await run(players.claimPlayer, 'ada', { playerId: 'open-p1', relation: 'self' });
      expect((await rsvps().doc('e1_ada').get()).exists).toBe(false);
      expect((await rsvps().doc('e1_open-p1').get()).data()).toMatchObject({ participantType: 'player', status: 'going' });
    });

    it("leaves a guardian's own answer", async () => {
      await event('e1', soon);
      await answer('e1', 'sam', 'member', 'going');
      await claim('open-p1', 'sam', 'guardian');
      await run(players.resolvePlayerClaim, 'pat', { playerId: 'open-p1', uid: 'sam', approve: true });
      expect((await rsvps().doc('e1_sam').get()).exists).toBe(true);
    });
  });

  describe('super admins on the team act as admins (§3)', () => {
    it('claims are linked at once, and new players are active at once', async () => {
      await join('root');
      expect(await run(players.claimPlayer, 'root', { playerId: 'open-p1', relation: 'guardian' }, ROOT)).toEqual({ status: 'linked' });
      expect(await link('open-p1', 'root')).toMatchObject({ relation: 'guardian', via: 'claim' });
      expect(await db().collection(Collections.guardianRequests).where('uid', '==', 'root').get()).toHaveProperty('size', 0);
      const added = await run<{ playerId: string; status: string }>(players.proposePlayer, 'root', {
        groupId: 'open', displayName: 'Rae Root', relation: 'self',
      }, ROOT);
      expect(added.status).toBe('active');
      expect(await link(added.playerId, 'root')).toMatchObject({ relation: 'self' });
    });

    it("still can't claim on a team they're not on: a claim links the caller", async () => {
      await expect(run(players.claimPlayer, 'root', { playerId: 'open-p1', relation: 'guardian' }, ROOT))
        .rejects.toMatchObject({ code: 'permission-denied' });
    });
  });

  describe("players updated → labels follow the name and number (PLAYER-8, ARCH §6.4)", () => {
    it("refreshes linked members' Who's who and upcoming RSVP names", async () => {
      await join('lee');
      await db().collection(Collections.players).doc('open-p1').update({ displayName: 'Sam Rivera', jerseyNumber: '12', status: 'active' });
      await claim('open-p1', 'sam', 'self');
      await run(players.resolvePlayerClaim, 'pat', { playerId: 'open-p1', uid: 'sam', approve: true });
      await run(players.inviteGuardian, 'pat', { groupId: 'open', playerId: 'open-p1', email: 'lee@example.com' });
      expect([await summary('sam'), await summary('lee')]).toEqual(['#12', 'Sam #12']);
      const soon = Timestamp.fromMillis(Date.now() + 86_400_000);
      const past = Timestamp.fromMillis(Date.now() - 86_400_000);
      await db().collection(Collections.rsvps).doc('e1_open-p1').set({ eventId: 'e1', participantId: 'open-p1', participantName: 'Sam Rivera', eventStartAt: soon });
      await db().collection(Collections.rsvps).doc('e0_open-p1').set({ eventId: 'e0', participantId: 'open-p1', participantName: 'Sam Rivera', eventStartAt: past });

      const ref = db().collection(Collections.players).doc('open-p1');
      const before = (await ref.get()).data();
      await ref.update({ displayName: 'Samuel Rivera', displayNameLower: 'samuel rivera', jerseyNumber: '21' });
      await service.followUpPlayerUpdate('open-p1', before, (await ref.get()).data());
      expect([await summary('sam'), await summary('lee')]).toEqual(['#21', 'Samuel #21']);
      expect((await db().collection(Collections.rsvps).doc('e1_open-p1').get()).get('participantName')).toBe('Samuel Rivera');
      expect((await db().collection(Collections.rsvps).doc('e0_open-p1').get()).get('participantName')).toBe('Sam Rivera');
    });

    it('exits early when neither the name nor the number changed, and for a pending player', async () => {
      await guardian('open', 'open-p1', 'sam');
      await members().doc('open_sam').update({ playerSummary: 'stale' });
      const before = { groupId: 'open', displayName: 'Emma', jerseyNumber: '7', status: 'active' };
      await service.followUpPlayerUpdate('open-p1', before, { ...before, position: 'Keeper', linksUpdatedAt: Timestamp.now() });
      await service.followUpPlayerUpdate('open-p1', before, { ...before, jerseyNumber: '8', status: 'pending' });
      expect(await summary('sam')).toBe('stale');
      await service.followUpPlayerUpdate('open-p1', before, { ...before, jerseyNumber: '8' });
      expect(await summary('sam')).toBe('Emma');
    });
  });

  describe('proposals linked as the player (PLAYER-3, PLAYER-4)', () => {
    it("approving a member's \"add me\" links them as the player", async () => {
      const res = await run<{ playerId: string }>(players.proposePlayer, 'sam', {
        groupId: 'open', displayName: 'Sam Rivera', jerseyNumber: '12', relation: 'self',
      });
      expect(await run(players.resolvePendingPlayer, 'pat', { playerId: res.playerId, approve: true })).toEqual({ ok: true, linked: true });
      expect(await link(res.playerId, 'sam')).toMatchObject({ relation: 'self', via: 'proposal', addedBy: 'pat' });
      expect(await summary('sam')).toBe('#12');
      expect((await groups().doc('open').get()).get('playerCount')).toBe(2);
      const approved = await db().collection(Collections.notifications).where('type', '==', 'guardianApproved').get();
      expect(approved.docs.map((d) => `${d.get('uid')}: ${d.get('body')}`)).toEqual(["sam: You're now on the roster as Sam Rivera"]);
    });

    it('refuses "add me" from an admin or a member who is already a player, adding no player', async () => {
      await addPlayer('open-p2');
      await db().collection(Collections.playerGuardians).doc('open-p1_ada').set({ groupId: 'open', playerId: 'open-p1', uid: 'ada', relation: 'self' });
      await db().collection(Collections.playerGuardians).doc('open-p2_sam').set({ groupId: 'open', playerId: 'open-p2', uid: 'sam', relation: 'self' });
      for (const uid of ['ada', 'sam']) {
        await expect(run(players.proposePlayer, uid, { groupId: 'open', displayName: 'Me Again', relation: 'self' }))
          .rejects.toMatchObject({ message: 'already-a-player' });
      }
      expect((await db().collection(Collections.players).where('displayName', '==', 'Me Again').get()).size).toBe(0);
    });
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

  it("gives link previews the team's name and logo, and sends people on (task 140)", async () => {
    const path = 'groups/open/logo.jpg';
    await storage().bucket().file(path).save(Buffer.from('logo'), {
      contentType: 'image/jpeg',
      metadata: { metadata: { firebaseStorageDownloadTokens: 'tok' } },
    });
    await groups().doc('open').update({ photoPath: path, name: 'Thunder U14' });
    const link = await run<{ code: string }>(invites.getTeamInvite, 'ada', { groupId: 'open' });
    const open = async (url: string, agent: string, method = 'GET') => {
      const out = { status: 0, headers: {} as Record<string, string>, body: '', location: '' };
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
        redirect(code: number, location: string) {
          out.status = code;
          out.location = location;
          return res;
        },
      };
      const [pathname] = url.split('?');
      await (invites.joinPage as unknown as (req: object, res: object) => Promise<void>)(
        { method, path: pathname, originalUrl: url, ip: '203.0.113.9', get: (h: string) => (h === 'user-agent' ? agent : undefined) },
        res,
      );
      return out;
    };
    // A person goes on to the app's join page, the query kept.
    const person = await open(`/join/${link.code}?via=qr`, 'Mozilla/5.0 (iPhone) Safari/604.1');
    expect(person.status).toBe(302);
    expect(person.location).toBe(`/app/join/${link.code}?via=qr`);
    expect(person.headers['cache-control']).toBe('no-store');
    expect(person.headers.vary).toBe('User-Agent');
    // A preview gets the team.
    const preview = await open(`/join/${link.code}`, 'facebookexternalhit/1.1');
    expect(preview.status).toBe(200);
    expect(preview.headers['content-type']).toBe('text/html; charset=utf-8');
    expect(preview.body).toContain('<meta property="og:title" content="Join Thunder U14 on Battleplan">');
    expect(preview.body).toContain('Ada Admin invited you');
    expect(preview.body).toMatch(/og:image" content="[^"]*tok/);
    expect((await open(`/join/${link.code}`, 'WhatsApp/2', 'HEAD')).body).toBe('');
    // A link that doesn't work, or no code: Battleplan's own preview.
    await run(invites.revokeGroupInvite, 'ada', { groupId: 'open' });
    const revoked = await open(`/join/${link.code}`, 'Twitterbot/1.0');
    expect(revoked.body).toContain('Join your team on Battleplan');
    expect(revoked.body).not.toContain('Thunder');
    expect((await open('/join/', 'Twitterbot/1.0')).body).toContain('images/og.png');
    expect((await open('/join/', 'Mozilla/5.0')).location).toBe('/app/join');
  });
});
