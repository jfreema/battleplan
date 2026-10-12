// The notification pipeline end to end (ARCH §6.5, SPEC NOTIF-2, -3, -4,
// -10, -11): notify.send() and the chat hook against the Firestore
// emulator, with FCM faked. Covers who gets a push, who gets a center item,
// dedupe, and token cleanup. Run with:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import type { TokenMessage } from 'firebase-admin/messaging';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { eraseMessage, notifyNewMessage } from '../../src/chat/service.js';
import { onMessageCreated } from '../../src/chat/triggers.js';
import { reportContent } from '../../src/safety/handlers.js';
import { removeMember, updateGroupMember } from '../../src/teams/handlers.js';
import {
  pruneDevices,
  removeDevices,
  removeTeamNotifications,
  send,
  type NotifyInput,
} from '../../src/notify/service.js';
import { db } from '../../src/shared/admin.js';
import { Collections, Limits } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';

// FCM stand-in: records every batch and answers by token. Tokens with
// "dead" are unknown to FCM, "badarg" are refused; allInvalid makes the
// whole batch fail the way a bad payload does.
const fcm = vi.hoisted(() => ({ batches: [] as TokenMessage[][], allInvalid: false }));
vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({
    sendEach: async (messages: TokenMessage[]) => {
      fcm.batches.push(messages);
      const responses = messages.map((m) => {
        const code = fcm.allInvalid || m.token.includes('badarg')
          ? 'messaging/invalid-argument'
          : m.token.includes('dead')
            ? 'messaging/registration-token-not-registered'
            : null;
        return code ? { success: false, error: { code } } : { success: true, messageId: `id-${m.token}` };
      });
      const successCount = responses.filter((r) => r.success).length;
      return { responses, successCount, failureCount: responses.length - successCount };
    },
  }),
}));

const G = 'teamA';
const DAY = 86_400_000;
const pushed = () => fcm.batches.flat();
const pushedTokens = () => pushed().map((m) => m.token).sort();

interface Person {
  role?: 'owner' | 'admin' | 'member';
  level?: 'all' | 'important' | 'none';
  /** Mute ending this many ms from now (negative: already over). */
  mutedFor?: number;
  status?: 'active' | 'provisioned' | 'disabled';
  prefs?: Record<string, boolean>;
  device?: boolean;
}

async function person(uid: string, p: Person = {}, groupId = G): Promise<void> {
  await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid)).set({
    groupId,
    uid,
    role: p.role ?? 'member',
    displayName: uid,
    notificationLevel: p.level ?? 'all',
    mutedUntil: p.mutedFor === undefined ? null : Timestamp.fromMillis(Date.now() + p.mutedFor),
  });
  await db().collection(Collections.users).doc(uid).set({
    displayName: uid,
    status: p.status ?? 'active',
    notificationPrefs: p.prefs ?? {},
  });
  if (p.device !== false) await device(uid, `tok-${uid}`);
}

async function device(uid: string, token: string, updatedAt = Timestamp.now()): Promise<void> {
  await db().collection(Collections.devices).doc(`dev-${token}`).set({
    uid,
    token,
    platform: 'ios',
    appVersion: '1.0.0',
    updatedAt,
  });
}

async function exists(path: string): Promise<boolean> {
  return (await db().doc(path).get()).exists;
}

/** Who has a center item for [key], sorted. */
async function centerFor(key: string): Promise<string[]> {
  const snap = await db().collection(Collections.notifications).where('groupId', '==', G).get();
  return snap.docs
    .filter((d) => d.id === `${key}_${d.get('uid')}`)
    .map((d) => d.get('uid') as string)
    .sort();
}

const input = (over: Partial<NotifyInput>): NotifyInput => ({
  kind: 'message',
  groupId: G,
  recipients: { members: true },
  actor: { uid: 'alex', name: 'Alex' },
  target: { type: 'message', id: 'm1' },
  route: `/g/${G}/chat/m/m1`,
  params: {},
  body: 'Alex: Field 3 is open',
  dedupeKey: 'm1',
  ...over,
});

beforeAll(() => {
  // Never point these tests at a real project.
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with npm run emulators:test');
});

beforeEach(async () => {
  const project = process.env.GCLOUD_PROJECT ?? 'demo-battleplan';
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  expect(res.ok).toBe(true);
  fcm.batches.length = 0;
  fcm.allInvalid = false;
  delete process.env.FUNCTIONS_EMULATOR;
  await db().collection(Collections.groups).doc(G).set({ name: 'Thunder' });
  await person('alex', { role: 'admin' });
});

describe('who gets a push (NOTIF-2, NOTIF-3, NOTIF-4)', () => {
  it('a message reaches members whose level, mute, account, and switch allow it', async () => {
    await person('sam');
    await person('old', { mutedFor: -60_000 }); // a mute that has ended
    await person('pat', { level: 'important' });
    await person('lee', { level: 'none' });
    await person('kim', { mutedFor: 3_600_000 });
    await person('kit', { mutedFor: Limits.mutedForeverMs - Date.now() }); // until unmuted
    await person('dee', { status: 'disabled' });
    await person('mo', { prefs: { messages: false } });
    await person('jo');
    await db().collection(Collections.userBlocks).doc('jo_alex').set({ uid: 'jo', blockedUid: 'alex' });
    await person('newbie', { status: 'provisioned', device: false });
    await person('outsider', {}, 'teamB'); // on another team

    const to = await send(input({}));

    expect(pushedTokens()).toEqual(['tok-old', 'tok-sam']);
    expect(to.sort()).toEqual(['newbie', 'old', 'sam']); // newbie has no device yet
    expect(await centerFor('m1')).toEqual([]); // plain messages have no center items
    const m = pushed()[0];
    expect(m.notification).toEqual({ title: 'Thunder', body: 'Alex: Field 3 is open' });
    expect(m.data).toEqual({ route: `/g/${G}/chat/m/m1`, groupId: G, kind: 'message', nkey: 'm1' });
    expect(m.android?.notification?.channelId).toBe('messages');
  });

  it('center items land even when the push is muted or off; blocked and disabled get neither', async () => {
    await person('sam');
    await person('pat', { level: 'important' });
    await person('lee', { level: 'none' });
    await person('kim', { mutedFor: 3_600_000 });
    await person('dee', { status: 'disabled' });
    await person('jo');
    await db().collection(Collections.userBlocks).doc('jo_alex').set({ uid: 'jo', blockedUid: 'alex' });
    await person('outsider', {}, 'teamB');

    const uids = ['sam', 'pat', 'lee', 'kim', 'dee', 'jo', 'outsider', 'alex'];
    await send(input({ kind: 'addedToTeam', recipients: { uids }, dedupeKey: 'add1', body: 'Alex added you' }));

    // Important kinds push at Important only; Off and an active mute don't.
    expect(pushedTokens()).toEqual(['tok-pat', 'tok-sam']);
    // Not the actor, a blocker, a disabled account, or someone off the team.
    expect(await centerFor('add1')).toEqual(['kim', 'lee', 'pat', 'sam']);
    const item = await db().doc(`${Collections.notifications}/add1_kim`).get();
    expect(item.data()).toMatchObject({
      uid: 'kim',
      groupId: G,
      type: 'addedToTeam',
      title: 'Thunder',
      body: 'Alex added you',
      route: `/g/${G}/chat/m/m1`,
      actorId: 'alex',
      read: false,
    });
    expect((item.get('expiresAt') as Timestamp).toMillis()).toBeGreaterThan(Date.now() + 89 * DAY);
  });

  it('kinds with no switch ignore every global switch', async () => {
    const allOff = { messages: false, replies: false, polls: false, eventsNew: false, eventsChanged: false,
      reminders: false, documents: false, events: false };
    await person('sam', { prefs: allOff });
    await send(input({ kind: 'madeAdmin', recipients: { uids: ['sam'] }, dedupeKey: 'adm1' }));
    expect(pushedTokens()).toEqual(['tok-sam']);
  });

  it('a hidden actor (reports) skips the block check and leaves out who was excluded', async () => {
    await person('pat', { role: 'owner' });
    await person('jo', { role: 'admin' });
    await person('rep', { role: 'admin' }); // the reporter
    await person('sub', { role: 'admin' }); // the person reported
    await person('sam');
    await db().collection(Collections.userBlocks).doc('jo_rep').set({ uid: 'jo', blockedUid: 'rep' });

    await send(input({
      kind: 'contentReported',
      recipients: { admins: true },
      exclude: ['rep', 'sub'],
      actor: null,
      target: { type: 'report', id: 'r1' },
      dedupeKey: 'r1',
      body: 'A message was reported',
    }));

    expect(await centerFor('r1')).toEqual(['alex', 'jo', 'pat']);
    expect((await db().doc(`${Collections.notifications}/r1_jo`).get()).get('actorId')).toBeNull();
  });

  it('gives each person their own wording when the body is a function', async () => {
    await person('sam');
    await person('pat');
    await send(input({
      kind: 'addedToTeam',
      recipients: { uids: ['sam', 'pat'] },
      dedupeKey: 'per1',
      body: (uid) => `Hi ${uid}`,
    }));
    expect(pushed().map((m) => `${m.token}:${m.notification?.body}`).sort()).toEqual(['tok-pat:Hi pat', 'tok-sam:Hi sam']);
    expect((await db().doc(`${Collections.notifications}/per1_sam`).get()).get('body')).toBe('Hi sam');
  });
});

describe('big teams', () => {
  it('reaches every member, past the 500 a single read returns', async () => {
    // In batches of 200 people (400 writes), under Firestore's 500.
    for (let start = 0; start < Limits.membersPerGroupMax + 5; start += 200) {
      const batch = db().batch();
      for (let i = start; i < Math.min(start + 200, Limits.membersPerGroupMax + 5); i++) {
        const uid = `m${String(i).padStart(4, '0')}`;
        batch.set(db().collection(Collections.groupMembers).doc(groupMemberId(G, uid)), {
          groupId: G, uid, role: 'member', displayName: uid, notificationLevel: 'all', mutedUntil: null,
        });
        batch.set(db().collection(Collections.users).doc(uid), { displayName: uid, status: 'active', notificationPrefs: {} });
      }
      await batch.commit();
    }
    await send(input({ kind: 'reply', dedupeKey: 'big', recipients: { members: true } }));
    // Everyone but the actor gets the center item.
    expect((await centerFor('big')).length).toBe(Limits.membersPerGroupMax + 5);
  });
});

describe('dedupe and delivery (ARCH §6.5 steps 0 and 4)', () => {
  it('sends once per dedupe key, so a retried trigger stays quiet', async () => {
    await person('sam');
    expect(await send(input({}))).toEqual(['sam']);
    expect(await send(input({ body: 'again' }))).toEqual([]);
    expect(fcm.batches).toHaveLength(1);
    expect(await exists(`${Collections.notifyLog}/m1`)).toBe(true);
  });

  it('logs instead of sending on the emulators, and still writes center items', async () => {
    await person('sam');
    process.env.FUNCTIONS_EMULATOR = 'true';
    await send(input({ kind: 'reply', recipients: { uids: ['sam'] }, dedupeKey: 'm1_reply' }));
    expect(fcm.batches).toHaveLength(0);
    expect(await centerFor('m1_reply')).toEqual(['sam']);
  });

  it('forgets dead tokens, and refused ones only when others went through', async () => {
    await person('sam');
    await device('sam', 'tok-sam-dead');
    await device('sam', 'tok-sam-badarg');
    await send(input({}));
    expect(pushedTokens()).toEqual(['tok-sam', 'tok-sam-badarg', 'tok-sam-dead']);
    expect(await exists(`${Collections.devices}/dev-tok-sam`)).toBe(true);
    expect(await exists(`${Collections.devices}/dev-tok-sam-dead`)).toBe(false);
    expect(await exists(`${Collections.devices}/dev-tok-sam-badarg`)).toBe(false);
  });

  it('keeps every device when a bad payload fails the whole batch', async () => {
    await person('sam');
    await person('pat');
    fcm.allInvalid = true;
    await send(input({}));
    expect(await exists(`${Collections.devices}/dev-tok-sam`)).toBe(true);
    expect(await exists(`${Collections.devices}/dev-tok-pat`)).toBe(true);
  });

  it('pushes once to a token two device docs share', async () => {
    await person('sam');
    await db().collection(Collections.devices).doc('dev-copy').set({
      uid: 'sam', token: 'tok-sam', platform: 'ios', appVersion: '1.0.0', updatedAt: Timestamp.now(),
    });
    await send(input({}));
    expect(pushedTokens()).toEqual(['tok-sam']);
  });
});

describe('message hook (NOTIF-2, NOTIF-5, CHAT-13)', () => {
  const reply = { groupId: G, authorId: 'alex', authorName: 'Alex', type: 'text', text: 'Sounds good' };

  it('the person replied to gets only "replied to you"; everyone else gets the message', async () => {
    await person('sam', { level: 'important' });
    await person('pat');
    await notifyNewMessage('m1', reply, 'Thunder', 'sam');
    expect(pushed().map((m) => `${m.token}:${m.data?.kind}:${m.notification?.body}`).sort()).toEqual([
      'tok-pat:message:Alex: Sounds good',
      'tok-sam:reply:Alex replied to you: Sounds good',
    ]);
    expect(await centerFor('m1_reply')).toEqual(['sam']);
    expect(await centerFor('m1')).toEqual([]); // the plain message has none
  });

  it('with Replies off and Messages on, a reply still arrives as a message', async () => {
    await person('sam', { prefs: { replies: false, messages: true } });
    await notifyNewMessage('m1', reply, 'Thunder', 'sam');
    expect(pushed().map((m) => `${m.token}:${m.data?.kind}`)).toEqual(['tok-sam:message']);
    expect(await centerFor('m1_reply')).toEqual(['sam']); // the center item stays
  });

  it('system lines and event cards notify nothing here', async () => {
    await person('sam');
    await notifyNewMessage('m2', { ...reply, type: 'system', authorId: 'system' }, 'Thunder', null);
    await notifyNewMessage('m3', { ...reply, type: 'event' }, 'Thunder', null);
    expect(fcm.batches).toHaveLength(0);
  });
});

describe('hooks (task 74)', () => {
  type CallRequest = Parameters<typeof reportContent.run>[0];
  const call = (uid: string, data: object) => ({ data, auth: { uid, token: {} }, rawRequest: {} }) as unknown as CallRequest;
  const message = (id: string, fields: object) =>
    db().collection(Collections.messages).doc(id).set({
      groupId: G, attachments: [], reactions: {}, createdAt: Timestamp.now(), ...fields,
    });

  it('deleting a message erases the notification-center items that quote it (CHAT-8)', async () => {
    await person('sam');
    await notifyNewMessage('m9', { groupId: G, authorId: 'alex', authorName: 'Alex', type: 'text', text: 'Rude words' }, 'Thunder', 'sam');
    expect(await centerFor('m9_reply')).toEqual(['sam']);
    await message('m9', { authorId: 'alex', authorName: 'Alex', type: 'text', text: 'Rude words', replyToId: 'm1' });
    await eraseMessage('m9', 'alex', 'author');
    expect(await centerFor('m9_reply')).toEqual([]);
  });

  it('the message trigger tells the quoted author and the rest of the team', async () => {
    await person('sam');
    await person('pat');
    await message('m1', { authorId: 'sam', authorName: 'sam', type: 'text', text: 'Field 3?' });
    await message('m2', { authorId: 'alex', authorName: 'Alex', type: 'text', text: 'Yes', replyToId: 'm1' });
    const snap = await db().collection(Collections.messages).doc('m2').get();
    await onMessageCreated.run({ data: snap, params: { messageId: 'm2' } } as unknown as Parameters<
      typeof onMessageCreated.run
    >[0]);
    expect(pushed().map((m) => `${m.token}:${m.data?.kind}`).sort()).toEqual(['tok-pat:message', 'tok-sam:reply']);
    expect(await centerFor('m2_reply')).toEqual(['sam']);
  });

  it('a report reaches the other admins and never names the reporter (SAFE-1)', async () => {
    await person('pat', { role: 'owner' });
    await person('sub', { role: 'admin' });
    await person('sam');
    await message('m1', { authorId: 'sam', authorName: 'sam', type: 'text', text: 'rude' });
    await reportContent.run(call('alex', { groupId: G, targetType: 'message', targetId: 'm1', reason: 'harassment' }));
    const items = await db().collection(Collections.notifications).get();
    // Admins only, minus the reporter (alex) and the person reported.
    expect(items.docs.map((d) => d.get('uid')).sort()).toEqual(['pat', 'sub']);
    expect(items.docs[0].get('actorId')).toBeNull();
    expect(JSON.stringify(items.docs.map((d) => d.data()))).not.toContain('alex');
    expect(pushedTokens().sort()).toEqual(['tok-pat', 'tok-sub']);
    expect(JSON.stringify(pushed())).not.toContain('alex');
  });

  it('a report about an admin goes to super admins only, so no team admin is told (SAFE-1)', async () => {
    await person('pat', { role: 'owner' });
    await person('sub', { role: 'admin' });
    await message('m1', { authorId: 'sub', authorName: 'sub', type: 'text', text: 'rude' });
    await reportContent.run(call('alex', { groupId: G, targetType: 'message', targetId: 'm1', reason: 'harassment' }));
    expect((await db().collection(Collections.notifications).get()).size).toBe(0);
    expect(pushed()).toEqual([]);
  });

  it('a new admin is told who made them one', async () => {
    await person('sam');
    await updateGroupMember.run(call('alex', { groupId: G, uid: 'sam', role: 'admin' }));
    expect(pushed().map((m) => `${m.token}:${m.data?.kind}:${m.notification?.body}`)).toEqual([
      'tok-sam:madeAdmin:alex made you an admin',
    ]);
  });

  it('someone removed loses that team\'s center items', async () => {
    await person('sam');
    await send(input({ kind: 'madeAdmin', recipients: { uids: ['sam'] }, dedupeKey: 'adm1' }));
    expect(await centerFor('adm1')).toEqual(['sam']);
    await removeMember.run(call('alex', { groupId: G, uid: 'sam' }));
    expect(await centerFor('adm1')).toEqual([]);
  });
});

describe('cleanup (ARCH §6.5 devices)', () => {
  it('removes a person\'s devices when they sign out everywhere', async () => {
    await person('sam');
    await device('sam', 'tok-sam-2');
    expect(await removeDevices('sam')).toBe(2);
    expect(await exists(`${Collections.devices}/dev-tok-alex`)).toBe(true);
  });

  it('prunes devices not updated in 60 days', async () => {
    await device('sam', 'tok-stale', Timestamp.fromMillis(Date.now() - (Limits.deviceStaleDays + 1) * DAY));
    await device('sam', 'tok-fresh', Timestamp.fromMillis(Date.now() - (Limits.deviceStaleDays - 1) * DAY));
    expect(await pruneDevices()).toBe(1);
    expect(await exists(`${Collections.devices}/dev-tok-stale`)).toBe(false);
    expect(await exists(`${Collections.devices}/dev-tok-fresh`)).toBe(true);
  });

  it('removes only that team\'s center items when someone leaves', async () => {
    const item = (id: string, uid: string, groupId: string) =>
      db().collection(Collections.notifications).doc(id).set({ uid, groupId, type: 'reply', read: false });
    await item('a', 'sam', G);
    await item('b', 'sam', 'teamB');
    await item('c', 'pat', G);
    expect(await removeTeamNotifications(G, 'sam')).toBe(1);
    expect(await exists(`${Collections.notifications}/a`)).toBe(false);
    expect(await exists(`${Collections.notifications}/b`)).toBe(true);
    expect(await exists(`${Collections.notifications}/c`)).toBe(true);
  });
});
