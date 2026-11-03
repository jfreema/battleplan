// Starting a new season from a team (TEAM-16): who comes along and as what,
// the players with their links and details, the look and settings, the
// documents and plays when asked, the old team archived with a line in each
// chat, everyone told, an audit entry, and a retry that finishes an attempt
// that stopped partway. Runs against the Auth, Firestore, and Storage
// emulators with email and FCM faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { auth, db, storage } from '../../src/shared/admin.js';
import { Collections, Limits } from '../../src/shared/constants.js';
import * as teams from '../../src/teams/handlers.js';
import { copyTeamForSeason, seasonCopyId } from '../../src/teams/season.js';
import { teamIdFor } from '../../src/teams/service.js';

vi.mock('../../src/email/service.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/email/service.js')>()),
  sendEmail: async () => true,
}));
vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({ sendEach: async () => ({ responses: [], successCount: 0, failureCount: 0 }) }),
}));

const project = () => process.env.GCLOUD_PROJECT ?? 'demo-battleplan';
const VERIFIED = { email_verified: true };

type Callable = { run: (request: never) => Promise<unknown> };
const run = <T = { groupId: string; leftOut: number }>(fn: Callable, uid: string, data: object, token: object = VERIFIED) =>
  fn.run({ data, auth: { uid, token }, rawRequest: { ip: '1.2.3.4' } } as never) as Promise<T>;

const ALL = { players: true, staff: true, members: true, documents: true, plays: true };
const start = (data: object = {}, uid = 'pat') =>
  run(teams.startNewSeason, uid, { groupId: 'fall', name: 'Thunder Spring', ...ALL, ...data });

const groups = () => db().collection(Collections.groups);
const member = async (g: string, uid: string) => (await db().collection(Collections.groupMembers).doc(`${g}_${uid}`).get()).data();
const byTeam = async (collection: string, g: string) =>
  (await db().collection(collection).where('groupId', '==', g).get()).docs;
const fileExists = async (path: string) => (await storage().bucket().file(path).exists())[0];

async function person(uid: string, name: string, status = 'active'): Promise<void> {
  const email = `${uid}@example.com`;
  await auth().createUser({ uid, email, displayName: name, emailVerified: true });
  await db().collection(Collections.users).doc(uid).set({
    displayName: name, displayNameLower: name.toLowerCase(), email, emailLower: email, photoPath: null, status,
  });
}

async function file(path: string, contentType = 'image/jpeg'): Promise<void> {
  await storage().bucket().file(path).save(Buffer.from('bytes'), { contentType, resumable: false });
}

/**
 * Thunder Fall: pat owns it; ada is an admin; cole coaches; gia is an admin
 * and Emma's parent; sam is Emma's parent; lee is the player Lee; una is a
 * team parent with no player; pen was added by email and hasn't signed in.
 * Emma has details; sam's new player Max waits for approval.
 */
async function fall(extra: object = {}): Promise<void> {
  await groups().doc('fall').set({
    name: 'Thunder Fall', nameLower: 'thunder fall', description: 'U15 travel', sport: 'soccer', kind: 'team',
    color: '#1E88E5', photoPath: 'groups/fall/avatar/1.jpg', timeZone: 'America/Denver', ownerId: 'pat',
    settings: { membersCanInvite: false, allowMaybe: false, defaultReminderOffsets: [60, 1440] },
    chatTheme: { bubbleColor: '#E53935', background: 'photo', backgroundPath: 'groups/fall/theme/2.jpg' },
    memberCount: 8, playerCount: 2, storageBytes: 100, storageQuotaBytes: 500 * 1024 * 1024, storageQuotaCustom: true,
    lastMessageAt: Timestamp.now(), archivedAt: null, suspendedAt: null, status: 'active', createdAt: Timestamp.now(),
    ...extra,
  });
  const people: [string, object][] = [
    ['pat', { role: 'owner' }],
    ['ada', { role: 'admin', title: 'Manager' }],
    ['cole', { role: 'member', coach: true, title: 'Assistant coach' }],
    ['gia', { role: 'admin', title: 'Treasurer' }],
    ['sam', { role: 'member', notificationLevel: 'important', contactPhone: '555-0100' }],
    ['lee', { role: 'member' }],
    ['una', { role: 'member', title: 'Team parent' }],
    ['pen', { role: 'member', pending: true }],
  ];
  for (const [uid, fields] of people) {
    await db().collection(Collections.groupMembers).doc(`fall_${uid}`).set({
      groupId: 'fall', uid, displayName: uid, photoPath: null, notificationLevel: 'all', mutedUntil: null,
      playerSummary: 'old', joinedAt: Timestamp.now(), ...fields,
    });
  }
  const players = db().collection(Collections.players);
  await players.doc('emma').set({ groupId: 'fall', displayName: 'Emma', displayNameLower: 'emma', jerseyNumber: '7', walkUpSong: 'Thunderstruck', status: 'active' });
  await players.doc('lee').set({ groupId: 'fall', displayName: 'Lee', displayNameLower: 'lee', jerseyNumber: '12' });
  await players.doc('max').set({ groupId: 'fall', displayName: 'Max', displayNameLower: 'max', status: 'pending', proposedBy: 'sam' });
  const links = db().collection(Collections.playerGuardians);
  await links.doc('emma_sam').set({ groupId: 'fall', playerId: 'emma', uid: 'sam', relation: 'guardian', via: 'admin', addedBy: 'pat' });
  await links.doc('emma_gia').set({ groupId: 'fall', playerId: 'emma', uid: 'gia', relation: 'guardian', via: 'claim', addedBy: 'gia' });
  await links.doc('lee_lee').set({ groupId: 'fall', playerId: 'lee', uid: 'lee', relation: 'self', via: 'request', addedBy: 'pat' });
  await links.doc('max_sam').set({ groupId: 'fall', playerId: 'max', uid: 'sam', relation: 'guardian', via: 'proposal', addedBy: 'sam' });
  await db().collection(Collections.playerDetails).doc('emma').set({
    groupId: 'fall', dateOfBirth: '2011-04-09', emergencyContacts: [{ name: 'Grandma', phone: '555-0101' }], notes: 'Inhaler in bag',
    updatedBy: 'sam', updatedAt: Timestamp.now(),
  });
  const documents = db().collection(Collections.groupDocuments);
  await documents.doc('d1').set({
    groupId: 'fall', kind: 'file', name: 'Roster.pdf', nameLower: 'roster.pdf', description: '', pinned: true,
    path: 'groups/fall/documents/d1/Roster.pdf', contentType: 'application/pdf', size: 5,
    uploadedBy: 'ada', uploaderName: 'ada', notifyTeam: true, createdAt: Timestamp.fromMillis(1_700_000_000_000), updatedAt: Timestamp.now(),
  });
  await documents.doc('d2').set({
    groupId: 'fall', kind: 'link', name: 'League site', nameLower: 'league site', description: 'Standings', pinned: false,
    url: 'https://league.example.com', uploadedBy: 'sam', uploaderName: 'sam', notifyTeam: true, createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
  });
  // A document whose file is gone stays behind.
  await documents.doc('d3').set({
    groupId: 'fall', kind: 'file', name: 'Gone.pdf', nameLower: 'gone.pdf', description: '', pinned: false,
    path: 'groups/fall/documents/d3/Gone.pdf', contentType: 'application/pdf', size: 5,
    uploadedBy: 'ada', uploaderName: 'ada', notifyTeam: true, createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
  });
  await db().collection(Collections.plays).doc('play1').set({
    groupId: 'fall', board: 'soccer', variant: 'full', title: 'Corner kick', note: '', steps: [{ elements: [] }],
    createdBy: 'pat', createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
  });
  await file('groups/fall/avatar/1.jpg');
  await file('groups/fall/theme/2.jpg');
  await file('groups/fall/documents/d1/Roster.pdf', 'application/pdf');
}

/** Puts [uid] on [count] other teams. */
async function onTeams(uid: string, count: number): Promise<void> {
  const batch = db().batch();
  for (let i = 0; i < count; i++) {
    batch.set(db().collection(Collections.groupMembers).doc(`other${i}_${uid}`), { groupId: `other${i}`, uid, role: 'member' });
  }
  await batch.commit();
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
  await storage().bucket().deleteFiles({ prefix: 'groups/' });
  for (const uid of ['pat', 'ada', 'cole', 'gia', 'sam', 'lee', 'una', 'root']) await person(uid, `${uid[0].toUpperCase()}${uid.slice(1)}`);
  await person('pen', 'Pen', 'provisioned');
  await fall();
});

describe('starting a new season (TEAM-16)', () => {
  it('brings everyone, as they were, with the players, their links and details, and the look', async () => {
    const { groupId, leftOut } = await start();
    expect(leftOut).toBe(0);
    const team = (await groups().doc(groupId).get()).data()!;
    expect(team).toMatchObject({
      name: 'Thunder Spring', nameLower: 'thunder spring', description: 'U15 travel', sport: 'soccer', kind: 'team',
      color: '#1E88E5', timeZone: 'America/Denver', ownerId: 'pat', createdBy: 'pat', previousSeasonId: 'fall',
      memberCount: 8, playerCount: 2, storageBytes: 0, storageQuotaBytes: 500 * 1024 * 1024, storageQuotaCustom: true,
      archivedAt: null, status: 'active',
      photoPath: `groups/${groupId}/avatar/1.jpg`,
      chatTheme: { bubbleColor: '#E53935', background: 'photo', backgroundPath: `groups/${groupId}/theme/2.jpg` },
    });
    // The team's own settings, the default reminders among them; the rest default.
    expect(team.settings).toMatchObject({ membersCanInvite: false, allowMaybe: false, defaultReminderOffsets: [60, 1440], filterLanguage: true });
    expect(await fileExists(`groups/${groupId}/avatar/1.jpg`)).toBe(true);
    expect(await fileExists(`groups/${groupId}/theme/2.jpg`)).toBe(true);

    expect(await member(groupId, 'pat')).toMatchObject({ role: 'owner', title: null, playerSummary: null, addedBy: 'pat' });
    expect((await member(groupId, 'pat'))!.coach).toBeUndefined();
    expect(await member(groupId, 'ada')).toMatchObject({ role: 'admin', title: 'Manager' });
    expect(await member(groupId, 'cole')).toMatchObject({ role: 'member', coach: true, title: 'Assistant coach' });
    expect(await member(groupId, 'gia')).toMatchObject({ role: 'admin', title: 'Treasurer', playerSummary: 'Emma #7' });
    // Their own choices for the team carry on.
    expect(await member(groupId, 'sam')).toMatchObject({ role: 'member', playerSummary: 'Emma #7', notificationLevel: 'important', contactPhone: '555-0100' });
    expect(await member(groupId, 'lee')).toMatchObject({ playerSummary: '#12' });
    expect(await member(groupId, 'una')).toMatchObject({ role: 'member', title: 'Team parent', playerSummary: null });
    expect(await member(groupId, 'pen')).toMatchObject({ pending: true });

    // Active players only, under new IDs, with their links: parents keep answering.
    const players = await byTeam(Collections.players, groupId);
    expect(players.map((p) => p.get('displayName')).sort()).toEqual(['Emma', 'Lee']);
    const emma = seasonCopyId(groupId, 'emma');
    expect((await db().collection(Collections.players).doc(emma).get()).data()).toMatchObject({
      groupId, displayName: 'Emma', jerseyNumber: '7', walkUpSong: 'Thunderstruck', status: 'active', createdBy: 'pat',
    });
    const links = await byTeam(Collections.playerGuardians, groupId);
    expect(links.map((l) => l.id).sort()).toEqual([`${emma}_gia`, `${emma}_sam`, `${seasonCopyId(groupId, 'lee')}_lee`].sort());
    expect((await db().collection(Collections.playerGuardians).doc(`${emma}_sam`).get()).data()).toMatchObject({
      groupId, playerId: emma, uid: 'sam', relation: 'guardian', via: 'admin', addedBy: 'pat',
    });
    expect((await db().collection(Collections.playerDetails).doc(emma).get()).data()).toMatchObject({
      groupId, dateOfBirth: '2011-04-09', notes: 'Inhaler in bag', updatedBy: 'sam',
    });

    // The old team is archived and points to the new one; each chat says so.
    const old = (await groups().doc('fall').get()).data()!;
    expect(old.archivedAt).not.toBeNull();
    expect(old).toMatchObject({ status: 'archived', nextSeasonId: groupId });
    expect((await byTeam(Collections.messages, 'fall')).map((m) => m.get('text'))).toEqual(['Pat started the next season: Thunder Spring']);
    const lines = await byTeam(Collections.messages, groupId);
    expect(lines.map((m) => m.data())).toMatchObject([
      { type: 'system', text: 'Pat started this season from Thunder Fall', systemEvent: { kind: 'newSeason', actorId: 'pat', targetId: 'fall' } },
    ]);

    // Everyone it brought is told, the owner isn't; it's audited.
    const told = await byTeam(Collections.notifications, groupId);
    expect(told.map((n) => n.get('uid')).sort()).toEqual(['ada', 'cole', 'gia', 'lee', 'pen', 'sam', 'una']);
    expect(told[0].data()).toMatchObject({ type: 'addedToTeam', title: 'Thunder Spring', body: "Pat started the new season, and you're on the team", route: `/g/${groupId}/chat` });
    const logs = await db().collection(Collections.auditLogs).where('action', '==', 'startNewSeason').get();
    expect(logs.docs.map((d) => d.data())).toMatchObject([
      { actorId: 'pat', groupId: 'fall', targetId: groupId, after: { name: 'Thunder Spring', members: 8, players: 2, documents: 2, plays: 1, leftOut: 0 } },
    ]);
  });

  it('copies documents into their own folders, quietly, and plays, only when asked', async () => {
    const { groupId } = await start();
    const docs = await byTeam(Collections.groupDocuments, groupId);
    expect(docs.map((d) => d.get('name')).sort()).toEqual(['League site', 'Roster.pdf']);
    const roster = seasonCopyId(groupId, 'd1');
    expect((await db().collection(Collections.groupDocuments).doc(roster).get()).data()).toMatchObject({
      kind: 'file', path: `groups/${groupId}/documents/${roster}/Roster.pdf`, pinned: true, notifyTeam: false, uploaderName: 'ada',
      createdAt: Timestamp.fromMillis(1_700_000_000_000),
    });
    expect(await fileExists(`groups/${groupId}/documents/${roster}/Roster.pdf`)).toBe(true);
    expect((await db().collection(Collections.groupDocuments).doc(seasonCopyId(groupId, 'd2')).get()).data()).toMatchObject({
      kind: 'link', url: 'https://league.example.com', notifyTeam: false,
    });
    expect((await byTeam(Collections.plays, groupId)).map((p) => p.get('title'))).toEqual(['Corner kick']);

    // Without them, a fresh team.
    await groups().doc('fall').update({ archivedAt: null, status: 'active' });
    const second = await start({ name: 'Thunder Summer', documents: false, plays: false });
    expect(await byTeam(Collections.groupDocuments, second.groupId)).toHaveLength(0);
    expect(await byTeam(Collections.plays, second.groupId)).toHaveLength(0);
  });

  it('leaves the staff behind when asked: a coach who is a parent comes as a parent', async () => {
    const { groupId } = await start({ staff: false, members: false });
    const uids = (await byTeam(Collections.groupMembers, groupId)).map((m) => m.get('uid')).sort();
    expect(uids).toEqual(['gia', 'lee', 'pat', 'sam']);
    expect(await member(groupId, 'gia')).toMatchObject({ role: 'member', title: null, playerSummary: 'Emma #7' });
    expect((await groups().doc(groupId).get()).get('memberCount')).toBe(4);
  });

  it('without the players, their parents stay behind, and nobody shows a player', async () => {
    const { groupId } = await start({ players: false });
    const uids = (await byTeam(Collections.groupMembers, groupId)).map((m) => m.get('uid')).sort();
    expect(uids).toEqual(['ada', 'cole', 'gia', 'pat', 'pen', 'una']);
    expect(await member(groupId, 'gia')).toMatchObject({ role: 'admin', playerSummary: null });
    expect(await byTeam(Collections.players, groupId)).toHaveLength(0);
    expect(await byTeam(Collections.playerDetails, groupId)).toHaveLength(0);
    expect((await groups().doc(groupId).get()).get('playerCount')).toBe(0);
  });

  it('leaves out someone on 100 teams, and their links, and says how many (TEAM-2)', async () => {
    await onTeams('sam', Limits.groupsPerUserMax);
    const { groupId, leftOut } = await start();
    expect(leftOut).toBe(1);
    expect(await member(groupId, 'sam')).toBeUndefined();
    expect((await byTeam(Collections.playerGuardians, groupId)).map((l) => l.get('uid')).sort()).toEqual(['gia', 'lee']);
  });

  it('a group brings no players or plays, even when asked (TEAM-14)', async () => {
    await groups().doc('fall').update({ kind: 'group', sport: 'other' });
    const { groupId } = await start();
    expect((await groups().doc(groupId).get()).data()).toMatchObject({ kind: 'group', sport: 'other', playerCount: 0 });
    expect(await byTeam(Collections.players, groupId)).toHaveLength(0);
    expect(await byTeam(Collections.plays, groupId)).toHaveLength(0);
    // Its parents are just members.
    expect((await byTeam(Collections.groupMembers, groupId)).map((m) => m.get('uid')).sort()).toEqual(
      ['ada', 'cole', 'gia', 'lee', 'pat', 'pen', 'sam', 'una'],
    );
  });

  it('is only for the owner, on an open team, held to the checks for a new team', async () => {
    await expect(start({}, 'ada')).rejects.toMatchObject({ code: 'permission-denied' });
    // A super admin isn't the owner: the new team would be theirs.
    await expect(run(teams.startNewSeason, 'root', { groupId: 'fall', name: 'X', ...ALL }, { superAdmin: true, email_verified: true }))
      .rejects.toMatchObject({ code: 'permission-denied' });
    await expect(start({ name: ' ' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await onTeams('pat', Limits.groupsPerUserMax);
    await expect(start()).rejects.toMatchObject({ code: 'failed-precondition', message: 'too-many-teams' });
    await groups().doc('fall').update({ archivedAt: Timestamp.now() });
    await expect(start()).rejects.toMatchObject({ code: 'failed-precondition', message: 'team-archived' });
    expect((await groups().where('previousSeasonId', '==', 'fall').get()).size).toBe(0);
  });

  it('a retry finishes an attempt that stopped partway, and gets back the team of one that finished', async () => {
    const requestId = 'season-attempt-1';
    const groupId = teamIdFor('pat', requestId);
    // The first attempt copied the team and stopped before archiving.
    await copyTeamForSeason('fall', groupId, 'pat', 'Thunder Spring', ALL, 200);
    await db().collection(Collections.groupMembers).doc('fall_una').delete();
    expect((await start({ requestId })).groupId).toBe(groupId);
    const old = (await groups().doc('fall').get()).data()!;
    expect(old).toMatchObject({ status: 'archived', nextSeasonId: groupId });
    // Una left meanwhile; the count is of who's there.
    expect((await groups().doc(groupId).get()).get('memberCount')).toBe(8);
    expect((await byTeam(Collections.players, groupId)).length).toBe(2);

    expect(await start({ requestId })).toEqual({ groupId, leftOut: 0 });
    expect(await byTeam(Collections.messages, groupId)).toHaveLength(1);
    expect(await byTeam(Collections.messages, 'fall')).toHaveLength(1);
    expect((await db().collection(Collections.auditLogs).where('action', '==', 'startNewSeason').get()).size).toBe(1);
    // A new attempt can't reuse it for something else.
    await expect(run(teams.startNewSeason, 'pat', { groupId: 'other', name: 'X', ...ALL, requestId })).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
