// Direct conversations (CHAT-19): opening one, its push, a renamed or
// deleted account, reports, and keeping conversations out of everything
// that lists teams. Runs against the Auth, Firestore, and Storage
// emulators with FCM faked:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import type { TokenMessage } from 'firebase-admin/messaging';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { deleteAccount } from '../../src/accounts/service.js';
import { adminGetTeam, adminListTeams, adminResolveReport } from '../../src/admin/handlers.js';
import { dashboard, getUser, listReports } from '../../src/admin/service.js';
import { deleteMessage, openDirectChat, pinMessage } from '../../src/chat/handlers.js';
import { onMessageCreated } from '../../src/chat/triggers.js';
import { reportContent } from '../../src/safety/handlers.js';
import { db } from '../../src/shared/admin.js';
import { Collections, Limits } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';
import { requireRoomForAnotherTeam, teamCountOf } from '../../src/shared/roles.js';
import { directChatId } from '../../src/teams/direct.js';
import { updateMemberSnapshots } from '../../src/teams/service.js';

const fcm = vi.hoisted(() => ({ batches: [] as TokenMessage[][] }));
vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({
    sendEach: async (messages: TokenMessage[]) => {
      fcm.batches.push(messages);
      return {
        responses: messages.map((m) => ({ success: true, messageId: `id-${m.token}` })),
        successCount: messages.length,
        failureCount: 0,
      };
    },
  }),
}));

const T = 'teamA';
const OTHER = 'teamB';
type CallRequest = Parameters<typeof openDirectChat.run>[0];
const call = (uid: string, data: object, token: object = {}) =>
  ({ data, auth: { uid, token }, rawRequest: {} }) as unknown as CallRequest;
const open = (uid: string, other: string) =>
  openDirectChat.run(call(uid, { uid: other })) as Promise<{ groupId: string }>;
const group = async (id: string) => (await db().collection(Collections.groups).doc(id).get()).data();
const membership = async (groupId: string, uid: string) =>
  (await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid)).get()).data();
const pushed = () => fcm.batches.flat();

async function person(uid: string, name: string, status = 'active'): Promise<void> {
  await db().collection(Collections.users).doc(uid).set({ displayName: name, photoPath: null, status, notificationPrefs: {} });
  await db().collection(Collections.devices).doc(`dev-${uid}`).set({
    uid, token: `tok-${uid}`, platform: 'ios', appVersion: '1.0.0', updatedAt: Timestamp.now(),
  });
}

async function onTeam(groupId: string, uid: string, role = 'member'): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid)).set({
    groupId, uid, role, displayName: uid, photoPath: null, notificationLevel: 'all',
  });
}

/** A message as the app writes it, then the trigger, as Firestore would run it. */
async function sendAndTrigger(id: string, groupId: string, authorId: string, authorName: string, fields: object = {}) {
  await db().collection(Collections.messages).doc(id).set({
    groupId, authorId, authorName, authorPhotoPath: null, authorPlayerSummary: null, type: 'text',
    text: 'See you at 6', attachments: [], reactions: {}, createdAt: Timestamp.now(), ...fields,
  });
  const snap = await db().collection(Collections.messages).doc(id).get();
  await onMessageCreated.run({ data: snap, params: { messageId: id } } as unknown as Parameters<
    typeof onMessageCreated.run
  >[0]);
}

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with npm run emulators:test');
});

beforeEach(async () => {
  const project = process.env.GCLOUD_PROJECT ?? 'demo-battleplan';
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  expect(res.ok).toBe(true);
  fcm.batches = [];
  for (const id of [T, OTHER]) {
    await db().collection(Collections.groups).doc(id).set({
      name: id === T ? 'Thunder' : 'Cyclone', kind: 'team', memberCount: 2, createdAt: Timestamp.now(),
    });
  }
  await person('coach', 'Andy Bernard');
  await person('mom', 'Claire Dunphy');
  await person('stranger', 'Pat Lee');
  await onTeam(T, 'coach', 'owner');
  await onTeam(T, 'mom');
  await onTeam(OTHER, 'stranger');
});

describe('opening a conversation (CHAT-19)', () => {
  it('makes one for two people who share a team, the same whoever opens it', async () => {
    const { groupId } = await open('mom', 'coach');
    expect(groupId).toBe(directChatId('coach', 'mom'));
    expect(groupId).not.toContain('_');
    expect(await open('coach', 'mom')).toEqual({ groupId });
    expect(await group(groupId)).toMatchObject({
      kind: 'direct',
      uids: ['coach', 'mom'],
      people: { coach: { name: 'Andy Bernard', photoPath: null }, mom: { name: 'Claire Dunphy', photoPath: null } },
      storageQuotaBytes: Limits.directChatStorageQuotaMb * 1024 * 1024,
      storageQuotaCustom: true,
      settings: { membersCanCreatePolls: false, membersCanUploadDocs: false, filterLanguage: true },
    });
    expect(await membership(groupId, 'mom')).toMatchObject({ role: 'participant', otherUid: 'coach', displayName: 'Claire Dunphy' });
    expect(await membership(groupId, 'coach')).toMatchObject({ role: 'participant', otherUid: 'mom' });
  });

  it('refuses someone with no team in common, oneself, and an account that never joined', async () => {
    await expect(open('mom', 'stranger')).rejects.toThrow('no-shared-team');
    await expect(open('mom', 'mom')).rejects.toThrow('self');
    await person('added', 'Kim Park', 'provisioned');
    await onTeam(T, 'added');
    await expect(open('mom', 'added')).rejects.toThrow('not-available');
    await expect(open('mom', 'nobody')).rejects.toThrow('not-available');
  });

  it("doesn't count a suspended team as one in common", async () => {
    await db().collection(Collections.groups).doc(T).update({ suspendedAt: Timestamp.now() });
    await expect(open('mom', 'coach')).rejects.toThrow('no-shared-team');
  });

  it("refuses someone I blocked, but not someone who blocked me, who isn't told (SAFE-2)", async () => {
    await db().collection(Collections.userBlocks).doc('mom_coach').set({ uid: 'mom', blockedUid: 'coach' });
    await expect(open('mom', 'coach')).rejects.toThrow('blocked');
    await expect(open('coach', 'mom')).resolves.toMatchObject({ groupId: directChatId('coach', 'mom') });
  });

  it('counts new conversations toward the daily limit, never reopening one', async () => {
    await open('mom', 'coach');
    await open('mom', 'coach');
    const used = await db().collection(Collections.rateLimits).where('count', '>=', 1).get();
    expect(used.docs.map((d) => [d.id.split('_')[1], d.get('count')])).toEqual([['openDirectChat', 1]]);
  });

  it('opens one again after the team in common is gone', async () => {
    const { groupId } = await open('mom', 'coach');
    await db().collection(Collections.groupMembers).doc(groupMemberId(T, 'mom')).delete();
    expect(await open('mom', 'coach')).toEqual({ groupId });
  });
});

describe("a conversation is nobody's team (CHAT-19)", () => {
  let dm = '';
  beforeEach(async () => {
    dm = (await open('mom', 'coach')).groupId;
  });

  it("isn't counted toward the 100 teams a person can be on (TEAM-2)", async () => {
    expect(await teamCountOf('mom')).toBe(1);
    for (let i = 0; i < Limits.groupsPerUserMax - 1; i++) await onTeam(`t${i}`, 'mom');
    await expect(requireRoomForAnotherTeam('mom', Limits.groupsPerUserMax)).rejects.toThrow('too-many-teams');
    await db().collection(Collections.groupMembers).doc(groupMemberId('t0', 'mom')).delete();
    await expect(requireRoomForAnotherTeam('mom', Limits.groupsPerUserMax)).resolves.toBeUndefined();
  });

  it("isn't in the admin panel's teams, totals, or a person's teams", async () => {
    const totals = await dashboard();
    expect(totals.teams).toBe(2);
    const rows = (await adminListTeams.run(call('root', { sort: 'created', limit: 50 }, { superAdmin: true }))) as {
      rows: { id: string }[];
    };
    expect(rows.rows.map((r) => r.id).sort()).toEqual([T, OTHER]);
    expect((await getUser('mom')).teams.map((t) => t.groupId)).toEqual([T]);
    await expect(adminGetTeam.run(call('root', { groupId: dm }, { superAdmin: true }))).rejects.toThrow('No such team');
  });

  it('takes no team actions: pins are for teams', async () => {
    await sendAndTrigger('d1', dm, 'mom', 'Claire Dunphy');
    await expect(pinMessage.run(call('root', { messageId: 'd1', pinned: true }, { superAdmin: true }))).rejects.toThrow(
      'No such team',
    );
  });
});

describe("a conversation's messages (CHAT-19)", () => {
  let dm = '';
  beforeEach(async () => {
    dm = (await open('mom', 'coach')).groupId;
  });

  it('pushes the other person, titled with the sender, and moves both Messages lists', async () => {
    await sendAndTrigger('d1', dm, 'mom', 'Claire Dunphy', { text: 'Is practice still on?' });
    expect(pushed().map((m) => [m.token, m.notification?.title, m.notification?.body, m.data?.kind, m.data?.route])).toEqual([
      ['tok-coach', 'Claire Dunphy', 'Is practice still on?', 'directMessage', `/messages/${dm}/m/d1`],
    ]);
    // No notification-center item: Messages shows what's unread.
    expect((await db().collection(Collections.notifications).get()).size).toBe(0);
    const at = (await db().collection(Collections.messages).doc('d1').get()).get('createdAt') as Timestamp;
    expect((await membership(dm, 'mom'))?.lastMessageAt).toEqual(at);
    expect((await membership(dm, 'coach'))?.lastMessageAt).toEqual(at);
    // Sending marks it read for the sender only (CHAT-9).
    expect((await membership(dm, 'mom'))?.lastReadAt).toEqual(at);
    expect((await membership(dm, 'coach'))?.lastReadAt).toBeNull();
    expect((await group(dm))?.lastMessagePreview).toEqual({
      authorName: 'Claire Dunphy', text: 'Is practice still on?', type: 'text', authorId: 'mom',
    });
  });

  it('says a photo was sent, and replies push once', async () => {
    await sendAndTrigger('d1', dm, 'mom', 'Claire Dunphy');
    fcm.batches = [];
    await sendAndTrigger('d2', dm, 'coach', 'Andy Bernard', {
      type: 'image', text: '', replyToId: 'd1', attachments: [{ path: `groups/${dm}/messages/d2/a.jpg` }, { path: `groups/${dm}/messages/d2/b.jpg` }],
    });
    expect(pushed().map((m) => [m.token, m.notification?.body, m.data?.kind])).toEqual([['tok-mom', 'Sent 2 photos', 'directMessage']]);
  });

  it('never reaches someone who blocked the sender (SAFE-2)', async () => {
    await db().collection(Collections.userBlocks).doc('coach_mom').set({ uid: 'coach', blockedUid: 'mom' });
    await sendAndTrigger('d1', dm, 'mom', 'Claire Dunphy');
    expect(pushed()).toEqual([]);
  });

  it('follows the switch and a mute (NOTIF-3, NOTIF-4)', async () => {
    await db().collection(Collections.users).doc('coach').update({ notificationPrefs: { directMessages: false } });
    await sendAndTrigger('d1', dm, 'mom', 'Claire Dunphy');
    expect(pushed()).toEqual([]);
    await db().collection(Collections.users).doc('coach').update({ notificationPrefs: {} });
    await db().collection(Collections.groupMembers).doc(groupMemberId(dm, 'coach')).update({
      mutedUntil: Timestamp.fromMillis(Date.now() + 3_600_000),
    });
    await sendAndTrigger('d2', dm, 'mom', 'Claire Dunphy');
    expect(pushed()).toEqual([]);
  });

  it('lets the author delete, and nobody else but a super admin', async () => {
    await sendAndTrigger('d1', dm, 'mom', 'Claire Dunphy');
    await expect(deleteMessage.run(call('coach', { messageId: 'd1' }))).rejects.toThrow('Only the author');
    await deleteMessage.run(call('mom', { messageId: 'd1' }));
    expect((await db().collection(Collections.messages).doc('d1').get()).get('deletedReason')).toBe('author');
  });
});

describe('a renamed or deleted account (CHAT-19, AUTH-10)', () => {
  let dm = '';
  beforeEach(async () => {
    dm = (await open('mom', 'coach')).groupId;
    await sendAndTrigger('d1', dm, 'coach', 'Andy Bernard', { text: 'Bring the bats' });
  });

  it("puts a new name and photo on the conversation and the person's membership", async () => {
    await updateMemberSnapshots('coach', 'Andy B.', 'users/coach/avatar/new.jpg');
    expect((await group(dm))?.people.coach).toEqual({ name: 'Andy B.', photoPath: 'users/coach/avatar/new.jpg' });
    expect(await membership(dm, 'coach')).toMatchObject({ displayName: 'Andy B.', photoPath: 'users/coach/avatar/new.jpg' });
    expect(await membership(T, 'coach')).toMatchObject({ displayName: 'Andy B.' });
  });

  it('leaves the other person the conversation, read-only, from "Deleted user"', async () => {
    await deleteAccount('coach');
    expect(await membership(dm, 'coach')).toBeUndefined();
    expect(await group(dm)).toMatchObject({
      people: { coach: { name: 'Deleted user', photoPath: null }, mom: { name: 'Claire Dunphy' } },
      status: 'archived',
      memberCount: 1,
      lastMessagePreview: { authorName: 'Deleted user', text: 'Bring the bats', type: 'text', authorId: 'coach' },
    });
    expect((await group(dm))?.archivedAt).toBeTruthy();
    expect((await db().collection(Collections.messages).doc('d1').get()).get('authorName')).toBe('Deleted user');
    await expect(open('mom', 'coach')).rejects.toThrow('not-available');
    // The author can still take back their own messages.
    await sendAndTrigger('d2', dm, 'mom', 'Claire Dunphy');
    await deleteMessage.run(call('mom', { messageId: 'd2' }));
  });

  it('deletes a conversation once nobody is left in it', async () => {
    await deleteAccount('coach');
    await deleteAccount('mom');
    expect(await group(dm)).toBeUndefined();
    expect((await db().collection(Collections.messages).where('groupId', '==', dm).get()).size).toBe(0);
  });
});

describe('reports from a conversation (CHAT-19, SAFE-1)', () => {
  let dm = '';
  beforeEach(async () => {
    dm = (await open('mom', 'coach')).groupId;
    await sendAndTrigger('d1', dm, 'coach', 'Andy Bernard', { text: 'Rude words' });
    fcm.batches = [];
  });

  it('go to super admins only, with no team to act on', async () => {
    const { reportId } = (await reportContent.run(
      call('mom', { groupId: dm, targetType: 'message', targetId: 'd1', reason: 'harassment' }),
    )) as { reportId: string };
    expect((await db().collection(Collections.reports).doc(reportId).get()).data()).toMatchObject({
      teamVisible: false,
      subjectId: 'coach',
      excerpt: 'Rude words',
    });
    // Nobody in the conversation is told.
    expect(pushed()).toEqual([]);
    const rows = await listReports({ status: 'open', limit: 50 });
    expect(rows.rows.map((r) => [r.id, r.direct, r.groupName])).toEqual([[reportId, true, '']]);
    for (const action of ['removeMember', 'suspendTeam']) {
      await expect(
        adminResolveReport.run(call('root', { reportId, action, note: 'Looked at it' }, { superAdmin: true })),
      ).rejects.toThrow('direct-message');
    }
    await adminResolveReport.run(call('root', { reportId, action: 'deleteContent', note: 'Removed' }, { superAdmin: true }));
    expect((await db().collection(Collections.messages).doc('d1').get()).get('deletedReason')).toBe('admin');
  });

  it('come only from its people', async () => {
    await expect(
      reportContent.run(call('stranger', { groupId: dm, targetType: 'message', targetId: 'd1', reason: 'spam' })),
    ).rejects.toThrow('Not a member');
  });
});
