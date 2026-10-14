// Player details on the server (PLAYER-12): they go wherever their player
// goes (removePlayer, a declined pending player, a deleted team, from the
// owner or the admin panel, and the pending players a leaving or deleted
// person proposed), and stay when only a link goes (removing a guardian,
// leaving, being removed, deleting an account): they belong to the player.
// Nothing of them reaches the audit log, notifications, or chat. Runs
// against the Auth, Firestore, and Storage emulators with email and FCM
// faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { deleteAccount } from '../../src/accounts/service.js';
import * as admin from '../../src/admin/handlers.js';
import type { Email } from '../../src/email/service.js';
import * as players from '../../src/players/handlers.js';
import { auth, db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
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

const details = () => db().collection(Collections.playerDetails);
const hasDetails = async (playerId: string) => (await details().doc(playerId).get()).exists;
const detailsOf = async (groupId: string) =>
  (await details().where('groupId', '==', groupId).get()).docs.map((d) => d.id).sort();

/** Sample details as the app saves them (never real medical data). */
const sample = (groupId: string, by: string) => ({
  groupId,
  dateOfBirth: '2016-04-01',
  emergencyContacts: [{ name: 'Sam Rivera', phone: '555-0100', relationship: 'Parent' }],
  medicalNotes: 'Peanut allergy',
  medicalConsentAt: Timestamp.now(),
  medicalConsentBy: by,
  notes: 'Wears glasses',
  updatedBy: by,
  updatedAt: Timestamp.now(),
});
/** Pieces of the sample that must never be copied anywhere else. */
const SECRETS = ['2016-04-01', '555-0100', 'Peanut allergy', 'Wears glasses'];

async function person(uid: string, name: string): Promise<void> {
  const email = `${uid}@example.com`;
  await auth().createUser({ uid, email, displayName: name, emailVerified: true });
  await db().collection(Collections.users).doc(uid).set({
    displayName: name, displayNameLower: name.toLowerCase(), email, emailLower: email, photoPath: null, status: 'active',
  });
}

/**
 * A team [id] that pat owns, with ada an admin, sam a member who is p1's
 * guardian, and lee a member who is the player p2. p1, p2, and p3 (no
 * links) have details.
 */
async function team(id: string): Promise<void> {
  await db().collection(Collections.groups).doc(id).set({
    name: id, nameLower: id, sport: 'soccer', kind: 'team', ownerId: 'pat', memberCount: 4, playerCount: 3,
    color: null, photoPath: null, archivedAt: null, suspendedAt: null, settings: { membersCanInvite: true },
    createdAt: Timestamp.now(),
  });
  for (const [uid, role] of [['pat', 'owner'], ['ada', 'admin'], ['sam', 'member'], ['lee', 'member']]) {
    await db().collection(Collections.groupMembers).doc(`${id}_${uid}`).set({
      groupId: id, uid, role, displayName: uid, photoPath: null, playerSummary: null,
    });
  }
  for (const [n, name] of [['p1', 'Emma'], ['p2', 'Lee'], ['p3', 'Kai']]) {
    await db().collection(Collections.players).doc(`${id}-${n}`).set({
      groupId: id, displayName: name, displayNameLower: name.toLowerCase(), status: 'active',
    });
  }
  const links = db().collection(Collections.playerGuardians);
  await links.doc(`${id}-p1_sam`).set({ groupId: id, playerId: `${id}-p1`, uid: 'sam', relation: 'guardian' });
  await links.doc(`${id}-p2_lee`).set({ groupId: id, playerId: `${id}-p2`, uid: 'lee', relation: 'self' });
  await details().doc(`${id}-p1`).set(sample(id, 'sam'));
  await details().doc(`${id}-p2`).set(sample(id, 'lee'));
  await details().doc(`${id}-p3`).set(sample(id, 'ada'));
}

/**
 * A pending player sam proposed on 'open', with details it can't really
 * have (the rules refuse them), to show every player delete clears them.
 */
async function pendingWithDetails(): Promise<void> {
  await db().collection(Collections.players).doc('open-pending').set({
    groupId: 'open', displayName: 'Liam', displayNameLower: 'liam', status: 'pending',
    proposedBy: 'sam', proposedRelation: 'guardian', decidedBy: null, decidedAt: null,
  });
  await details().doc('open-pending').set(sample('open', 'sam'));
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
  for (const [uid, name] of [['pat', 'Pat Owner'], ['ada', 'Ada Admin'], ['sam', 'Sam Rivera'], ['lee', 'Lee Kim'], ['root', 'Root']]) {
    await person(uid, name);
  }
  await team('open');
  await team('other');
});

describe('player details go with the player (PLAYER-12)', () => {
  it('on removePlayer, leaving every other player’s', async () => {
    await run(players.removePlayer, 'ada', { groupId: 'open', playerId: 'open-p1' });
    expect(await hasDetails('open-p1')).toBe(false);
    expect((await db().collection(Collections.players).doc('open-p1').get()).exists).toBe(false);
    expect(await detailsOf('open')).toEqual(['open-p2', 'open-p3']);
    expect(await detailsOf('other')).toEqual(['other-p1', 'other-p2', 'other-p3']);
  });

  it('on declining a pending player', async () => {
    await pendingWithDetails();
    expect(await run(players.resolvePendingPlayer, 'pat', { playerId: 'open-pending', approve: false }))
      .toEqual({ ok: true, linked: false });
    expect((await db().collection(Collections.players).doc('open-pending').get()).exists).toBe(false);
    expect(await hasDetails('open-pending')).toBe(false);
    expect(await detailsOf('open')).toEqual(['open-p1', 'open-p2', 'open-p3']);
  });

  it("on deleting the team, from Team settings: every one of the team's, no other team's", async () => {
    await pendingWithDetails();
    await run(teams.deleteGroup, 'pat', { groupId: 'open', confirmName: 'open' });
    expect(await detailsOf('open')).toEqual([]);
    expect((await db().collection(Collections.players).where('groupId', '==', 'open').get()).size).toBe(0);
    expect(await detailsOf('other')).toEqual(['other-p1', 'other-p2', 'other-p3']);
  });

  it('on deleting the team from the admin panel (ADMIN-3)', async () => {
    await run(admin.adminDeleteGroup, 'root', { groupId: 'open', confirmName: 'open' }, ROOT);
    expect(await detailsOf('open')).toEqual([]);
    expect(await detailsOf('other')).toEqual(['other-p1', 'other-p2', 'other-p3']);
  });
});

describe('player details stay when only a link goes (PLAYER-12)', () => {
  it('when an admin removes the guardian, or the player unlinks themselves', async () => {
    await run(players.removeGuardian, 'ada', { groupId: 'open', playerId: 'open-p1', uid: 'sam' });
    await run(players.removeGuardian, 'lee', { groupId: 'open', playerId: 'open-p2', uid: 'lee' });
    expect(await detailsOf('open')).toEqual(['open-p1', 'open-p2', 'open-p3']);
  });

  it('when the guardian leaves, though the pending player they proposed goes with its details', async () => {
    await pendingWithDetails();
    await run(teams.leaveGroup, 'sam', { groupId: 'open' });
    expect((await db().collection(Collections.playerGuardians).doc('open-p1_sam').get()).exists).toBe(false);
    expect(await detailsOf('open')).toEqual(['open-p1', 'open-p2', 'open-p3']);
  });

  it('when the guardian is removed from the team', async () => {
    await pendingWithDetails();
    await run(teams.removeMember, 'ada', { groupId: 'open', uid: 'sam' });
    expect(await detailsOf('open')).toEqual(['open-p1', 'open-p2', 'open-p3']);
  });

  it("when the guardian or the player deletes their account (AUTH-10)", async () => {
    await pendingWithDetails();
    await deleteAccount('sam', {});
    await deleteAccount('lee', {});
    expect(await hasDetails('open-pending')).toBe(false);
    expect(await detailsOf('open')).toEqual(['open-p1', 'open-p2', 'open-p3']);
    expect(await detailsOf('other')).toEqual(['other-p1', 'other-p2', 'other-p3']);
  });
});

describe('player details are never copied elsewhere (PLAYER-12)', () => {
  it('not into the audit log, notifications, or chat, through every path that touches a player', async () => {
    await pendingWithDetails();
    await run(players.resolvePendingPlayer, 'pat', { playerId: 'open-pending', approve: false });
    await run(players.removeGuardian, 'ada', { groupId: 'open', playerId: 'open-p1', uid: 'sam' });
    await run(players.removePlayer, 'ada', { groupId: 'open', playerId: 'open-p2' });
    await run(teams.removeMember, 'ada', { groupId: 'open', uid: 'lee' });
    await run(teams.deleteGroup, 'pat', { groupId: 'other', confirmName: 'other' });
    expect((await db().collection(Collections.auditLogs).get()).size).toBeGreaterThanOrEqual(4);
    for (const collection of [Collections.auditLogs, Collections.notifications, Collections.messages]) {
      const docs = (await db().collection(collection).get()).docs;
      for (const d of docs) {
        const text = JSON.stringify(d.data());
        for (const secret of SECRETS) expect(text, `${collection}/${d.id}`).not.toContain(secret);
      }
    }
    expect(mail.sent.map((m) => m.text).join('\n')).not.toContain('Peanut');
  });
});

describe('a date of birth given when a player is added (PLAYER-12)', () => {
  const playersOf = async (name: string) =>
    (await db().collection(Collections.players).where('groupId', '==', 'open').where('displayName', '==', name).get()).docs;

  it("an admin's new player starts its details with it, and only it", async () => {
    await run(players.addPlayers, 'pat', {
      groupId: 'open',
      players: [{ name: 'Mia', dateOfBirth: '2015-06-02', guardians: [] }, { name: 'Noah', guardians: [] }],
    });
    const [mia] = await playersOf('Mia');
    const d = (await details().doc(mia.id).get()).data();
    expect(d).toMatchObject({ groupId: 'open', dateOfBirth: '2015-06-02', updatedBy: 'pat' });
    expect(Object.keys(d ?? {}).sort()).toEqual(['dateOfBirth', 'groupId', 'updatedAt', 'updatedBy']);
    // Never on the roster record everyone sees (PLAYER-10).
    expect(mia.get('dateOfBirth')).toBeUndefined();
    const [noah] = await playersOf('Noah');
    expect(await hasDetails(noah.id)).toBe(false);
  });

  it("a member's pending player keeps it, and a decline takes it away", async () => {
    const { playerId } = await run<{ playerId: string }>(players.proposePlayer, 'sam', {
      groupId: 'open', displayName: 'Ava', relation: 'guardian', dateOfBirth: '2017-01-31',
    });
    expect((await details().doc(playerId).get()).get('dateOfBirth')).toBe('2017-01-31');
    await run(players.resolvePendingPlayer, 'pat', { groupId: 'open', playerId, approve: false });
    expect(await hasDetails(playerId)).toBe(false);
  });

  it('refuses a day that is not real, today or later, or over 100 years ago', async () => {
    const tomorrow = new Date(Date.now() + 86_400_000).toISOString().slice(0, 10);
    const today = new Date().toISOString().slice(0, 10);
    for (const dateOfBirth of ['2016-02-30', '2016-4-1', tomorrow, today, '1900-01-01']) {
      await expect(
        run(players.addPlayers, 'pat', { groupId: 'open', players: [{ name: 'Zed', dateOfBirth, guardians: [] }] }),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
    }
    expect(await playersOf('Zed')).toHaveLength(0);
  });
});
