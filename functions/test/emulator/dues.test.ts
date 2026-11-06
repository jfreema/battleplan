// Dues on the server (SPEC DUES-1 to DUES-3): the saveDue and deleteDue
// callables create, edit, and delete a due with all its charges in one
// batch, for team admins and super admins only, and add people to a due;
// the names on charges follow renames; and Functions delete dues with
// their team (TEAM-9). Runs against the Firestore and Storage emulators:
//   npm --prefix functions run emulators:test
import { HttpsError } from 'firebase-functions/v2/https';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { deleteDue, saveDue } from '../../src/dues/handlers.js';
import { createDue, dueTerms } from '../../src/dues/service.js';
import { followUpPlayerUpdate } from '../../src/players/service.js';
import { db } from '../../src/shared/admin.js';
import { Collections, Limits } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';
import { deleteGroupData, updateMemberSnapshots } from '../../src/teams/service.js';

const project = () => process.env.GCLOUD_PROJECT ?? 'demo-battleplan';
const G = 'teamA';

type CallRequest = Parameters<typeof saveDue.run>[0];
const call = (uid: string | null, data: object, token: object = {}) =>
  ({ data, auth: uid ? { uid, token } : undefined, rawRequest: {} }) as unknown as CallRequest;
const save = (uid: string | null, data: object, token: object = {}) =>
  saveDue.run(call(uid, data, token)) as Promise<{ dueId: string }>;
const remove = (uid: string, dueId: string, token: object = {}) => deleteDue.run(call(uid, { dueId }, token));

const terms = { groupId: G, title: '  Uniform fee  ', amountCents: 4500, dueOn: '2026-11-30', note: 'Cash is fine' };

/** The HttpsError code a call refused with. */
async function refusal(p: Promise<unknown>): Promise<string> {
  try {
    await p;
  } catch (e) {
    if (e instanceof HttpsError) return e.code;
    throw e;
  }
  return 'ok';
}

async function member(g: string, uid: string, role: string, extra: object = {}): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(g, uid)).set({
    groupId: g, uid, role, displayName: uid[0].toUpperCase() + uid.slice(1), ...extra,
  });
}

const players = (n: number, g = G) =>
  Array.from({ length: n }, (_, i) => ({ id: `p${String(i).padStart(3, '0')}${g}`, g }));

const charges = async (dueId: string) =>
  (await db().collection(Collections.dueCharges).where('dueId', '==', dueId).get()).docs;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('Run with npm run emulators:test');
  }
});

beforeEach(async () => {
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project()}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  expect(res.ok).toBe(true);
  await db().collection(Collections.groups).doc(G).set({ name: 'Thunder', kind: 'team' });
  await db().collection(Collections.groups).doc('teamB').set({ name: 'Bolts', kind: 'team' });
  await db().collection(Collections.groups).doc('clubC').set({ name: 'Book club', kind: 'group' });
  await db().collection(Collections.groups).doc('dm1').set({ name: '', kind: 'direct' });
  await member(G, 'alice', 'owner');
  await member(G, 'carol', 'admin');
  await member(G, 'bob', 'member');
  await member('teamB', 'gina', 'admin');
  await member('clubC', 'hana', 'owner');
  await member('clubC', 'ivan', 'member');
  await member('clubC', 'jo', 'member', { pending: true });
  await member('dm1', 'alice', 'participant');
  const batch = db().batch();
  for (const p of [...players(Limits.duesChargesMax + 1), ...players(1, 'teamB')]) {
    batch.set(db().collection(Collections.players).doc(p.id), {
      groupId: p.g, displayName: `Kid ${p.id}`, jerseyNumber: '7', status: 'active',
    });
  }
  batch.set(db().collection(Collections.players).doc('newbie'), { groupId: G, displayName: 'New', status: 'pending' });
  await batch.commit();
});

describe('saveDue creates a due with its charges (DUES-1)', () => {
  it('charges 30 players in one go, names from the roster, all owed', async () => {
    const ids = players(30).map((p) => p.id);
    const { dueId } = await save('carol', { ...terms, participantIds: [...ids, ids[0]] });
    const due = (await db().collection(Collections.dues).doc(dueId).get()).data()!;
    expect(due).toMatchObject({ groupId: G, title: 'Uniform fee', amountCents: 4500, dueOn: '2026-11-30', note: 'Cash is fine', createdBy: 'carol' });
    const list = await charges(dueId);
    expect(list).toHaveLength(30);
    const first = list.find((d) => d.id === `${dueId}_${ids[0]}`)!.data();
    expect(first).toMatchObject({
      groupId: G, dueId, title: 'Uniform fee', amountCents: 4500, participantType: 'player',
      participantId: ids[0], participantName: 'Kid #7', status: 'owed', paidAt: null, updatedBy: 'carol',
      // The note reaches everyone who owes it (DUES-2).
      note: 'Cash is fine',
    });
  });

  it('a retry of the same add gets back the due it made, never a second one', async () => {
    const participantIds = players(3).map((p) => p.id);
    const add = { ...terms, participantIds, requestId: 'req-12345678' };
    const { dueId } = await save('carol', add);
    // The reply was lost, and the app tries again.
    expect((await save('carol', add)).dueId).toBe(dueId);
    expect((await db().collection(Collections.dues).get()).size).toBe(1);
    expect(await charges(dueId)).toHaveLength(3);
    // Two copies at the same moment: one makes it, the other gets it back.
    const both = await Promise.all([
      createDue(G, dueTerms(terms), participantIds, { uid: 'carol', superAdmin: false }, 'req-same-time'),
      createDue(G, dueTerms(terms), participantIds, { uid: 'carol', superAdmin: false }, 'req-same-time'),
    ]);
    expect(both[0]).toBe(both[1]);
    // Another attempt, or someone else's with the same ID, is a new due.
    expect((await save('carol', { ...add, requestId: 'req-87654321' })).dueId).not.toBe(dueId);
    expect((await save('alice', add)).dueId).not.toBe(dueId);
    expect((await db().collection(Collections.dues).get()).size).toBe(4);
  });

  it('charges up to duesChargesMax, and no more', async () => {
    const ids = players(Limits.duesChargesMax + 1).map((p) => p.id);
    const { dueId } = await save('alice', { ...terms, participantIds: ids.slice(0, Limits.duesChargesMax) });
    expect(await charges(dueId)).toHaveLength(Limits.duesChargesMax);
    expect(await refusal(save('alice', { ...terms, participantIds: ids }))).toBe('invalid-argument');
  });

  it('in a basic group, charges members who have joined', async () => {
    const { dueId } = await save('hana', { ...terms, groupId: 'clubC', participantIds: ['hana', 'ivan'] });
    const list = await charges(dueId);
    expect(list.map((d) => [d.get('participantType'), d.get('participantName')]).sort()).toEqual([
      ['member', 'Hana'], ['member', 'Ivan'],
    ]);
    // Jo hasn't joined yet; Emma is a player, and groups have none.
    expect(await refusal(save('hana', { ...terms, groupId: 'clubC', participantIds: ['jo'] }))).toBe('invalid-argument');
    expect(await refusal(save('hana', { ...terms, groupId: 'clubC', participantIds: [players(1)[0].id] }))).toBe('invalid-argument');
  });

  it("refuses another team's player, a pending one, someone missing, a member on a team, or no one", async () => {
    const [mine] = players(1).map((p) => p.id);
    const [theirs] = players(1, 'teamB').map((p) => p.id);
    for (const participantIds of [[mine, theirs], ['newbie'], ['ghost'], ['bob'], []]) {
      expect(await refusal(save('carol', { ...terms, participantIds }))).toBe('invalid-argument');
    }
    expect((await db().collection(Collections.dues).get()).size).toBe(0);
  });

  it('refuses bad terms', async () => {
    const participantIds = players(1).map((p) => p.id);
    for (const extra of [
      { amountCents: 0 },
      { amountCents: Limits.dueAmountMaxCents + 1 },
      { amountCents: 12.5 },
      { amountCents: '4500' },
      { title: '   ' },
      { dueOn: '12/01/2026' },
      { dueOn: '2026-13-01' },
    ]) {
      expect(await refusal(save('carol', { ...terms, ...extra, participantIds }))).toBe('invalid-argument');
    }
    // Long titles and notes are clipped.
    const { dueId } = await save('carol', {
      ...terms, title: 'x'.repeat(Limits.dueTitleMax + 5), note: 'y'.repeat(Limits.dueNoteMax + 5), dueOn: null, participantIds,
    });
    const due = (await db().collection(Collections.dues).doc(dueId).get()).data()!;
    expect(due.title).toHaveLength(Limits.dueTitleMax);
    expect(due.note).toHaveLength(Limits.dueNoteMax);
    expect(due.dueOn).toBeNull();
  });

  it('is for team admins and super admins only', async () => {
    const participantIds = players(1).map((p) => p.id);
    expect(await refusal(save(null, { ...terms, participantIds }))).toBe('unauthenticated');
    expect(await refusal(save('bob', { ...terms, participantIds }))).toBe('permission-denied');
    expect(await refusal(save('gina', { ...terms, participantIds }))).toBe('permission-denied');
    const { dueId } = await save('root', { ...terms, participantIds }, { superAdmin: true });
    expect(await charges(dueId)).toHaveLength(1);
  });

  it('refuses an archived team, a suspended one, and a direct conversation', async () => {
    const participantIds = players(1).map((p) => p.id);
    expect(await refusal(save('alice', { ...terms, groupId: 'dm1', participantIds: ['alice'] }))).toBe('permission-denied');
    expect(await refusal(save('root', { ...terms, groupId: 'dm1', participantIds: ['alice'] }, { superAdmin: true }))).toBe('not-found');
    await db().collection(Collections.groups).doc(G).update({ archivedAt: new Date() });
    expect(await refusal(save('alice', { ...terms, participantIds }))).toBe('failed-precondition');
    expect(await refusal(save('root', { ...terms, participantIds }, { superAdmin: true }))).toBe('failed-precondition');
    await db().collection(Collections.groups).doc(G).update({ archivedAt: null, suspendedAt: new Date() });
    expect(await refusal(save('alice', { ...terms, participantIds }))).toBe('permission-denied');
  });
});

describe('saveDue edits a due and every charge (DUES-1)', () => {
  it("copies the new terms to all its charges, keeping who paid, and nobody else's", async () => {
    const ids = players(40).map((p) => p.id);
    const { dueId } = await save('carol', { ...terms, participantIds: ids });
    const { dueId: other } = await save('carol', { ...terms, title: 'Other', participantIds: ids.slice(0, 3) });
    await db().collection(Collections.dueCharges).doc(`${dueId}_${ids[5]}`).update({ status: 'paid', paidAt: new Date() });
    await save('alice', { groupId: G, dueId, title: 'Jerseys', amountCents: 5000, dueOn: null, note: '' });
    const due = (await db().collection(Collections.dues).doc(dueId).get()).data()!;
    expect(due).toMatchObject({ title: 'Jerseys', amountCents: 5000, dueOn: null, note: '', createdBy: 'carol' });
    const list = await charges(dueId);
    expect(list).toHaveLength(40);
    expect(list.every((d) => d.get('title') === 'Jerseys' && d.get('amountCents') === 5000 && d.get('dueOn') === null && d.get('note') === '')).toBe(true);
    expect(list.find((d) => d.id === `${dueId}_${ids[5]}`)!.get('status')).toBe('paid');
    expect((await charges(other)).every((d) => d.get('title') === 'Other')).toBe(true);
  });

  it('refuses members, other teams, and a due that is gone or elsewhere', async () => {
    const { dueId } = await save('carol', { ...terms, participantIds: players(2).map((p) => p.id) });
    const edit = { groupId: G, dueId, title: 'Mine', amountCents: 1, dueOn: null, note: '' };
    expect(await refusal(save('bob', edit))).toBe('permission-denied');
    expect(await refusal(save('gina', { ...edit, groupId: 'teamB' }))).toBe('not-found');
    expect(await refusal(save('carol', { ...edit, dueId: 'nope' }))).toBe('not-found');
    expect((await charges(dueId)).every((d) => d.get('title') === 'Uniform fee')).toBe(true);
  });
});

describe('saveDue adds people to a due (DUES-1)', () => {
  it('a player who joins later gets an owed share with the new terms; nobody is taken off', async () => {
    const ids = players(5).map((p) => p.id);
    const { dueId } = await save('carol', { ...terms, participantIds: ids.slice(0, 3) });
    await db().collection(Collections.dueCharges).doc(`${dueId}_${ids[0]}`).update({ status: 'paid', paidAt: new Date() });
    await save('alice', {
      groupId: G, dueId, title: 'Uniforms', amountCents: 5000, dueOn: null, note: 'Hat too',
      // ids[0] is already on it, and stays paid.
      participantIds: [ids[0], ids[3], ids[4], ids[4]],
    });
    const list = await charges(dueId);
    expect(list).toHaveLength(5);
    const added = list.find((d) => d.id === `${dueId}_${ids[3]}`)!.data();
    expect(added).toMatchObject({
      participantType: 'player', participantName: 'Kid #7', status: 'owed', paidAt: null,
      title: 'Uniforms', amountCents: 5000, dueOn: null, note: 'Hat too', updatedBy: 'alice',
    });
    expect(list.find((d) => d.id === `${dueId}_${ids[0]}`)!.get('status')).toBe('paid');
    // Editing without anyone to add leaves who's on it alone.
    await save('alice', { groupId: G, dueId, title: 'Uniforms', amountCents: 5000, dueOn: null, note: '' });
    expect(await charges(dueId)).toHaveLength(5);
  });

  it('refuses someone not on the team, a pending player, past the cap, and members', async () => {
    const ids = players(Limits.duesChargesMax + 1).map((p) => p.id);
    const { dueId } = await save('carol', { ...terms, participantIds: ids.slice(0, Limits.duesChargesMax - 1) });
    const edit = { groupId: G, dueId, title: 'Fee', amountCents: 100, dueOn: null, note: '' };
    for (const participantIds of [[players(1, 'teamB')[0].id], ['newbie'], ['bob'], ids.slice(Limits.duesChargesMax - 1)]) {
      expect(await refusal(save('carol', { ...edit, participantIds }))).toBe('invalid-argument');
    }
    expect(await refusal(save('bob', { ...edit, participantIds: [ids[Limits.duesChargesMax - 1]] }))).toBe('permission-denied');
    // Nothing changed: not the terms, and nobody added.
    const list = await charges(dueId);
    expect(list).toHaveLength(Limits.duesChargesMax - 1);
    expect(list.every((d) => d.get('title') === 'Uniform fee')).toBe(true);
    // One more fits.
    await save('carol', { ...edit, participantIds: [ids[Limits.duesChargesMax - 1]] });
    expect(await charges(dueId)).toHaveLength(Limits.duesChargesMax);
  });

  it('in a basic group, adds members who have joined', async () => {
    const { dueId } = await save('hana', { ...terms, groupId: 'clubC', participantIds: ['hana'] });
    const edit = { groupId: 'clubC', dueId, title: 'Snacks', amountCents: 500, dueOn: null, note: '' };
    expect(await refusal(save('hana', { ...edit, participantIds: ['jo'] }))).toBe('invalid-argument');
    await save('hana', { ...edit, participantIds: ['ivan'] });
    expect((await charges(dueId)).map((d) => [d.get('participantType'), d.get('participantName')]).sort()).toEqual([
      ['member', 'Hana'], ['member', 'Ivan'],
    ]);
  });
});

describe('the names on charges follow renames (DUES-2)', () => {
  it("a player's new name or number, on every due, paid ones too", async () => {
    const [id] = players(1).map((p) => p.id);
    const { dueId } = await save('carol', { ...terms, participantIds: [id] });
    const { dueId: other } = await save('carol', { ...terms, title: 'Photos', participantIds: [id] });
    await db().collection(Collections.dueCharges).doc(`${other}_${id}`).update({ status: 'paid' });
    const before = { groupId: G, displayName: `Kid ${id}`, jerseyNumber: '7', status: 'active' };
    await followUpPlayerUpdate(id, before, { ...before, jerseyNumber: '12' });
    for (const d of [dueId, other]) {
      expect((await db().collection(Collections.dueCharges).doc(`${d}_${id}`).get()).get('participantName')).toBe('Kid #12');
    }
    await followUpPlayerUpdate(id, { ...before, jerseyNumber: '12' }, { ...before, displayName: 'Emma Stone', jerseyNumber: '12' });
    expect((await db().collection(Collections.dueCharges).doc(`${dueId}_${id}`).get()).get('participantName')).toBe('Emma #12');
  });

  it("a member's new name, on their own shares", async () => {
    const { dueId } = await save('hana', { ...terms, groupId: 'clubC', participantIds: ['hana', 'ivan'] });
    await updateMemberSnapshots('ivan', 'Ivan Petrov', null, null);
    const list = await charges(dueId);
    expect(Object.fromEntries(list.map((d) => [d.get('participantId'), d.get('participantName')]))).toEqual({
      hana: 'Hana', ivan: 'Ivan Petrov',
    });
  });
});

describe('deleteDue removes a due and every charge (DUES-1)', () => {
  it('takes all its charges, and leaves other dues alone', async () => {
    const ids = players(40).map((p) => p.id);
    const { dueId } = await save('carol', { ...terms, participantIds: ids });
    const { dueId: other } = await save('carol', { ...terms, participantIds: ids.slice(0, 2) });
    expect(await refusal(remove('bob', dueId))).toBe('permission-denied');
    expect(await refusal(remove('gina', dueId))).toBe('permission-denied');
    await remove('alice', dueId);
    expect((await db().collection(Collections.dues).doc(dueId).get()).exists).toBe(false);
    expect(await charges(dueId)).toHaveLength(0);
    expect(await charges(other)).toHaveLength(2);
    expect(await refusal(remove('alice', dueId))).toBe('not-found');
    // Someone else's due: audited, with its title and nothing owed.
    const logs = (await db().collection(Collections.auditLogs).where('targetId', '==', dueId).get()).docs;
    expect(logs.map((d) => [d.get('action'), d.get('actorId'), d.get('before')])).toEqual([
      ['deleteDue', 'alice', { title: 'Uniform fee', createdBy: 'carol' }],
    ]);
    await remove('carol', other);
    expect((await db().collection(Collections.auditLogs).where('targetId', '==', other).get()).size).toBe(0);
  });

  it('refuses an archived team; super admins delete on an open one', async () => {
    const { dueId } = await save('carol', { ...terms, participantIds: players(2).map((p) => p.id) });
    await db().collection(Collections.groups).doc(G).update({ archivedAt: new Date() });
    expect(await refusal(remove('alice', dueId))).toBe('failed-precondition');
    await db().collection(Collections.groups).doc(G).update({ archivedAt: null });
    await remove('root', dueId, { superAdmin: true });
    expect(await charges(dueId)).toHaveLength(0);
  });
});

describe('deleting a team takes its dues (TEAM-9)', () => {
  it("removes the team's dues, charges and how to pay, and no one else's", async () => {
    for (const g of ['teamA', 'teamY']) {
      await db().collection(Collections.groups).doc(g).set({ name: g, kind: 'team' });
      await db().collection(Collections.dues).doc(`${g}-d`).set({ groupId: g, title: 'Fee' });
      await db().collection(Collections.dueCharges).doc(`${g}-d_p`).set({ groupId: g, dueId: `${g}-d` });
      await db().collection(Collections.duesPayments).doc(g).set({ groupId: g, venmo: '@x' });
    }
    await deleteGroupData('teamA');
    const ids = async (c: string) =>
      (await db().collection(c).get()).docs.map((d) => d.id).filter((id) => id.startsWith('teamA') || id.startsWith('teamY'));
    expect(await ids(Collections.dues)).toEqual(['teamY-d']);
    expect(await ids(Collections.dueCharges)).toEqual(['teamY-d_p']);
    expect(await ids(Collections.duesPayments)).toEqual(['teamY']);
  });
});
