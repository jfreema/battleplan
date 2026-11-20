// The one-time change to reminders for teams made before Nov 1 (#48),
// against the Firestore emulator: only the teams still on the old default
// change, once, with a record to undo it and one audit entry. And the
// one-time move of shared contacts off memberships (#45). Run with:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  REMINDERS_OFF_BEFORE,
  moveSharedContacts,
  turnOffOldReminderDefaults,
  undoReminderDefaultsOff,
} from '../../src/teams/migrations.js';
import { db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';

const DAY = 86_400_000;
const before = (days: number) => Timestamp.fromMillis(REMINDERS_OFF_BEFORE.getTime() - days * DAY);
const after = (days: number) => Timestamp.fromMillis(REMINDERS_OFF_BEFORE.getTime() + days * DAY);

async function team(id: string, createdAt: Timestamp, offsets: number[] | undefined, extra: object = {}) {
  await db()
    .collection(Collections.groups)
    .doc(id)
    .set({
      name: id,
      kind: 'team',
      createdAt,
      settings: offsets === undefined ? { filterLanguage: true } : { filterLanguage: true, defaultReminderOffsets: offsets },
      ...extra,
    });
}
const offsetsOf = async (id: string) =>
  (await db().collection(Collections.groups).doc(id).get()).get('settings.defaultReminderOffsets') as number[] | undefined;
const marker = async () => (await db().collection(Collections.ops).doc('migrations').get()).data() ?? {};

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
  await team('old', before(30), [1440]);
  await team('oldHour', before(30), [60]);
  await team('oldBoth', before(30), [1440, 60]);
  await team('oldNone', before(30), []);
  await team('oldUnset', before(30), undefined);
  await team('new', after(3), [1440]);
  await team('archived', before(60), [1440], { archivedAt: before(10) });
  await team('deleting', before(60), [1440], { deletingAt: before(1) });
  await db().collection(Collections.events).doc('e1').set({ groupId: 'old', title: 'Practice', reminderOffsets: [1440] });
});

describe('reminders off for teams made before Nov 1 (#48)', () => {
  it('turns off only the old default on old, open teams', async () => {
    expect(await turnOffOldReminderDefaults()).toEqual(['old']);
    expect(await offsetsOf('old')).toEqual([]);
    // Left alone: other choices, newer teams, archived and deleted ones.
    expect(await offsetsOf('oldHour')).toEqual([60]);
    expect(await offsetsOf('oldBoth')).toEqual([1440, 60]);
    expect(await offsetsOf('oldNone')).toEqual([]);
    expect(await offsetsOf('oldUnset')).toBeUndefined();
    expect(await offsetsOf('new')).toEqual([1440]);
    expect(await offsetsOf('archived')).toEqual([1440]);
    expect(await offsetsOf('deleting')).toEqual([1440]);
    // Events already made keep their reminders.
    expect((await db().collection(Collections.events).doc('e1').get()).get('reminderOffsets')).toEqual([1440]);
  });

  it('records what it changed, once, and writes one audit entry', async () => {
    await turnOffOldReminderDefaults(new Date('2026-11-20T10:00:00Z'));
    expect((await marker()).reminderDefaultsOff).toMatchObject({ count: 1, teamIds: ['old'] });
    const entries = await db().collection(Collections.auditLogs).where('action', '==', 'reminderDefaultsOff').get();
    expect(entries.size).toBe(1);
    expect(entries.docs[0].data()).toMatchObject({
      actorId: 'Battleplan',
      after: {
        teams: 1,
        note: 'Reminders turned off by default for 1 team made before Nov 1 (#48). Events already made keep theirs.',
      },
    });
    // A second night does nothing, even to a team back on the old default.
    await team('old', before(30), [1440]);
    expect(await turnOffOldReminderDefaults()).toBeNull();
    expect(await offsetsOf('old')).toEqual([1440]);
    expect((await db().collection(Collections.auditLogs).get()).size).toBe(1);
  });

  it('can be undone, for the recorded teams still on No reminders', async () => {
    await team('old2', before(5), [1440]);
    expect((await turnOffOldReminderDefaults())?.sort()).toEqual(['old', 'old2']);
    // An admin picked something else for one since.
    await db().collection(Collections.groups).doc('old2').update({ 'settings.defaultReminderOffsets': [60] });
    expect(await undoReminderDefaultsOff()).toEqual(['old']);
    expect(await offsetsOf('old')).toEqual([1440]);
    expect(await offsetsOf('old2')).toEqual([60]);
    expect((await marker()).reminderDefaultsOffUndone).toMatchObject({ teamIds: ['old'] });
  });
});

describe('shared contacts move off memberships (#45)', () => {
  const members = () => db().collection(Collections.groupMembers);
  const contacts = () => db().collection(Collections.memberContacts);
  beforeEach(async () => {
    await members().doc('old_sam').set({ groupId: 'old', uid: 'sam', role: 'member', contactPhone: '555 0100', contactEmail: 'sam@example.com' });
    await members().doc('old_una').set({ groupId: 'old', uid: 'una', role: 'member', contactEmail: ' una@example.com ' });
    await members().doc('old_pat').set({ groupId: 'old', uid: 'pat', role: 'owner' });
    // Already saved by a newer app, which wins over the old field.
    await members().doc('old_lee').set({ groupId: 'old', uid: 'lee', role: 'member', contactPhone: '555 0000' });
    await contacts().doc('old_lee').set({ groupId: 'old', uid: 'lee', phone: '555 0199', email: null });
  });

  it('moves each one to its own record and clears the membership, once', async () => {
    expect(await moveSharedContacts()).toBe(3);
    expect((await contacts().doc('old_sam').get()).data()).toMatchObject({
      groupId: 'old', uid: 'sam', phone: '555 0100', email: 'sam@example.com',
    });
    expect((await contacts().doc('old_una').get()).data()).toMatchObject({ uid: 'una', phone: null, email: 'una@example.com' });
    expect((await contacts().doc('old_lee').get()).data()).toMatchObject({ phone: '555 0199' });
    expect((await contacts().doc('old_pat').get()).exists).toBe(false);
    for (const id of ['old_sam', 'old_una', 'old_lee']) {
      const m = (await members().doc(id).get()).data()!;
      expect(m.contactPhone).toBeUndefined();
      expect(m.contactEmail).toBeUndefined();
    }
    expect((await marker()).sharedContactsMoved).toMatchObject({ count: 3 });
    const entries = await db().collection(Collections.auditLogs).where('action', '==', 'sharedContactsMoved').get();
    expect(entries.size).toBe(1);
    expect(entries.docs[0].get('actorId')).toBe('Battleplan');
    // A second night does nothing.
    await members().doc('old_pat').update({ contactPhone: '555 0123' });
    expect(await moveSharedContacts()).toBeNull();
    expect((await contacts().doc('old_pat').get()).exists).toBe(false);
  });
});
