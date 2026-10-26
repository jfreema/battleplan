// Security rules for assignments (SPEC SCHED-15): tasks on an event, each
// with at most one person. Everyone on the team reads them; admins, and
// super admins (§3), add, change, and remove them and put anyone on the team
// on one; any member takes an open one or gives up their own. Archived
// teams are read-only (TEAM-9).
// Run against the emulator: npm --prefix functions run emulators:test
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

type Db = firebase.firestore.Firestore;

let env: RulesTestEnvironment;
const now = () => firebase.firestore.FieldValue.serverTimestamp();
const ts = (iso: string) => firebase.firestore.Timestamp.fromDate(new Date(iso));
const OLD = ts('2026-10-01T00:00:00Z');
const as = (uid: string): Db => env.authenticatedContext(uid).firestore();
const root = (): Db => env.authenticatedContext('root', { superAdmin: true }).firestore();

/** A task as stored, for seeding. */
const stored = (extra: object = {}) => ({
  groupId: 'teamA',
  eventId: 'e1',
  kind: 'snacks',
  label: null,
  assigneeUid: null,
  assignedBy: null,
  createdBy: 'alice',
  createdAt: OLD,
  updatedAt: OLD,
  ...extra,
});

/** A new task as the app writes it, every field there. */
const task = (uid: string, extra: object = {}): Record<string, unknown> => ({
  ...stored({ createdBy: uid, createdAt: now(), updatedAt: now() }),
  ...extra,
});

const add = (db: Db, data: object) => db.collection('assignments').add(data);
/** An edit as the app makes it: only what changes, and the time. */
const change = (db: Db, id: string, changes: object) => db.doc(`assignments/${id}`).update({ updatedAt: now(), ...changes });
/** e1's tasks, as the event page lists them. */
const list = (db: Db) =>
  db.collection('assignments').where('groupId', '==', 'teamA').where('eventId', '==', 'e1').limit(100).get();

// teamA: alice owner, carol admin, bob and dan members. teamB: gina admin.
// Events e1 on teamA and eB on teamB. On e1: a1, snacks, open; a2, drinks
// ("Gatorade"), which dan volunteered for; a3, 'Field setup', which carol
// put bob on. root is a super admin on no team.
async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const g of ['teamA', 'teamB']) {
      await db.doc(`groups/${g}`).set({ name: g, nameLower: g, kind: 'team', settings: {}, storageBytes: 0, storageQuotaBytes: 1 });
    }
    const member = (g: string, uid: string, role: string) =>
      db.doc(`groupMembers/${g}_${uid}`).set({ groupId: g, uid, role, displayName: uid, photoPath: null });
    await member('teamA', 'alice', 'owner');
    await member('teamA', 'carol', 'admin');
    await member('teamA', 'bob', 'member');
    await member('teamA', 'dan', 'member');
    await member('teamB', 'gina', 'admin');
    await db.doc('events/e1').set({ groupId: 'teamA', type: 'practice', title: 'Practice', createdBy: 'alice' });
    await db.doc('events/eB').set({ groupId: 'teamB', type: 'game', title: 'Game', createdBy: 'gina' });
    await db.doc('assignments/a1').set(stored());
    await db.doc('assignments/a2').set(stored({ kind: 'drinks', label: 'Gatorade', assigneeUid: 'dan', assignedBy: 'dan' }));
    await db.doc('assignments/a3').set(stored({ kind: 'other', label: 'Field setup', assigneeUid: 'bob', assignedBy: 'carol' }));
  });
}

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-battleplan',
    firestore: { rules: readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed();
});

afterAll(async () => {
  await env?.cleanup();
});

const setTeam = (fields: object) =>
  env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc('groups/teamA').update(fields));

/** A task as stored now, read past the rules. */
async function storedTask(id: string): Promise<Record<string, unknown> | undefined> {
  let data: Record<string, unknown> | undefined;
  await env.withSecurityRulesDisabled(async (ctx) => {
    data = (await ctx.firestore().doc(`assignments/${id}`).get()).data();
  });
  return data;
}

describe('reading tasks (SCHED-15)', () => {
  it('is for the team, and super admins, a bounded list at a time', async () => {
    for (const uid of ['alice', 'carol', 'bob', 'dan']) {
      await assertSucceeds(as(uid).doc('assignments/a1').get());
      await assertSucceeds(list(as(uid)));
    }
    await assertSucceeds(root().doc('assignments/a2').get());
    await assertSucceeds(list(root()));
    await assertFails(as('bob').collection('assignments').where('groupId', '==', 'teamA').where('eventId', '==', 'e1').get());
  });

  it("is closed to other teams' people and the signed out, and a list must name the team", async () => {
    await assertFails(as('gina').doc('assignments/a1').get());
    await assertFails(list(as('gina')));
    await assertFails(env.unauthenticatedContext().firestore().doc('assignments/a1').get());
    await assertFails(list(env.unauthenticatedContext().firestore()));
    await assertFails(as('bob').collection('assignments').where('eventId', '==', 'e1').limit(100).get());
  });
});

describe('adding tasks (SCHED-15)', () => {
  it('is for admins and super admins, as themselves', async () => {
    await assertSucceeds(add(as('carol'), task('carol')));
    await assertSucceeds(add(as('alice'), task('alice', { kind: 'other', label: 'Field setup' })));
    await assertSucceeds(add(root(), task('root', { kind: 'scorekeeper' })));
    // Members don't, not even for themselves.
    await assertFails(add(as('bob'), task('bob')));
    await assertFails(add(as('bob'), task('bob', { assigneeUid: 'bob', assignedBy: 'bob' })));
    await assertFails(add(as('gina'), task('gina')));
    await assertFails(add(as('carol'), task('alice')));
  });

  it('can put someone on the team on it at once, as assigned by the writer', async () => {
    await assertSucceeds(add(as('carol'), task('carol', { assigneeUid: 'bob', assignedBy: 'carol' })));
    await assertSucceeds(add(as('carol'), task('carol', { assigneeUid: 'carol', assignedBy: 'carol' })));
    await assertSucceeds(add(root(), task('root', { assigneeUid: 'dan', assignedBy: 'root' })));
    // Not someone off the team, nor a super admin who isn't on it.
    await assertFails(add(as('carol'), task('carol', { assigneeUid: 'gina', assignedBy: 'carol' })));
    await assertFails(add(as('carol'), task('carol', { assigneeUid: 'nobody', assignedBy: 'carol' })));
    await assertFails(add(root(), task('root', { assigneeUid: 'root', assignedBy: 'root' })));
    // Who put them there is the writer, and an open task has nobody.
    await assertFails(add(as('carol'), task('carol', { assigneeUid: 'bob', assignedBy: 'bob' })));
    await assertFails(add(as('carol'), task('carol', { assigneeUid: 'bob', assignedBy: null })));
    await assertFails(add(as('carol'), task('carol', { assignedBy: 'carol' })));
  });

  it('checks what a task holds', async () => {
    const bad: object[] = [
      { kind: 'cookies' },
      { kind: null },
      // An 'other' task needs its name.
      { kind: 'other' },
      { kind: 'other', label: '   ' },
      { label: '' },
      { label: 'x'.repeat(41) },
      { label: 7 },
      { assigneeUid: 7, assignedBy: 'carol' },
      { extra: true },
      { createdAt: OLD },
      { updatedAt: OLD },
    ];
    for (const extra of bad) await assertFails(add(as('carol'), task('carol', extra)));
    // Every field is always there, null or not.
    for (const field of ['label', 'assigneeUid', 'assignedBy', 'updatedAt']) {
      const data = task('carol');
      delete data[field];
      await assertFails(add(as('carol'), data));
    }
    await assertSucceeds(add(as('carol'), task('carol', { label: 'x'.repeat(40) })));
    await assertSucceeds(add(as('carol'), task('carol', { kind: 'drinks', label: 'Halftime oranges' })));
  });

  it("goes only on one of the team's own events", async () => {
    await assertFails(add(as('carol'), task('carol', { eventId: 'eB' })));
    await assertFails(add(as('carol'), task('carol', { eventId: 'gone' })));
    await assertFails(add(as('gina'), task('gina', { groupId: 'teamB', eventId: 'e1' })));
    await assertFails(add(as('carol'), task('carol', { groupId: 'teamB', eventId: 'eB' })));
    await assertSucceeds(add(as('gina'), task('gina', { groupId: 'teamB', eventId: 'eB' })));
  });
});

describe('volunteering and giving up (SCHED-15)', () => {
  it('lets any member take an open task for themselves', async () => {
    await assertSucceeds(change(as('bob'), 'a1', { assigneeUid: 'bob', assignedBy: 'bob' }));
    expect(await storedTask('a1')).toMatchObject({ assigneeUid: 'bob', assignedBy: 'bob', label: null, kind: 'snacks' });
    // Once it's taken, nobody else takes it.
    await assertFails(change(as('dan'), 'a1', { assigneeUid: 'dan', assignedBy: 'dan' }));
  });

  it('refuses a task someone has, and putting anyone else on one', async () => {
    await assertFails(change(as('bob'), 'a2', { assigneeUid: 'bob', assignedBy: 'bob' }));
    await assertFails(change(as('bob'), 'a1', { assigneeUid: 'dan', assignedBy: 'bob' }));
    await assertFails(change(as('bob'), 'a1', { assigneeUid: 'dan', assignedBy: 'dan' }));
    await assertFails(change(as('bob'), 'a1', { assigneeUid: 'bob', assignedBy: 'carol' }));
    await assertFails(change(as('gina'), 'a1', { assigneeUid: 'gina', assignedBy: 'gina' }));
    await assertFails(change(env.unauthenticatedContext().firestore(), 'a1', { assigneeUid: 'bob', assignedBy: 'bob' }));
  });

  it('lets the person who has a task give it up, and nobody else clear it', async () => {
    await assertFails(change(as('bob'), 'a2', { assigneeUid: null, assignedBy: null }));
    await assertSucceeds(change(as('dan'), 'a2', { assigneeUid: null, assignedBy: null }));
    // One an admin put them on, too.
    await assertSucceeds(change(as('bob'), 'a3', { assigneeUid: null, assignedBy: null }));
    expect(await storedTask('a3')).toMatchObject({ assigneeUid: null, assignedBy: null, label: 'Field setup' });
  });

  it('changes nothing else, and stamps the time', async () => {
    await assertFails(change(as('bob'), 'a1', { assigneeUid: 'bob', assignedBy: 'bob', label: 'Mine' }));
    await assertFails(change(as('bob'), 'a3', { label: 'Setup and cleanup' }));
    await assertFails(change(as('bob'), 'a3', { kind: 'snacks', label: null }));
    await assertFails(change(as('bob'), 'a3', { assigneeUid: null, assignedBy: null, label: 'Gone' }));
    // Giving up opens it all the way.
    await assertFails(change(as('dan'), 'a2', { assigneeUid: null }));
    await assertFails(as('bob').doc('assignments/a1').update({ assigneeUid: 'bob', assignedBy: 'bob' }));
    await assertFails(change(as('bob'), 'a1', { assigneeUid: 'bob', assignedBy: 'bob', updatedAt: OLD }));
    await assertFails(change(as('bob'), 'a1', { assigneeUid: 'bob', assignedBy: 'bob', createdBy: 'bob' }));
  });
});

describe('admins managing tasks (SCHED-15)', () => {
  it('assign anyone on the team, reassign, and open a task again', async () => {
    await assertSucceeds(change(as('carol'), 'a1', { assigneeUid: 'bob', assignedBy: 'carol' }));
    await assertSucceeds(change(as('alice'), 'a1', { assigneeUid: 'dan', assignedBy: 'alice' }));
    await assertSucceeds(change(as('alice'), 'a1', { assigneeUid: 'alice', assignedBy: 'alice' }));
    await assertSucceeds(change(as('carol'), 'a1', { assigneeUid: null, assignedBy: null }));
    // Someone else on a task a member volunteered for.
    await assertSucceeds(change(as('carol'), 'a2', { assigneeUid: 'bob', assignedBy: 'carol' }));
    expect(await storedTask('a2')).toMatchObject({ assigneeUid: 'bob', assignedBy: 'carol', label: 'Gatorade' });
  });

  it('assign only people on the team, as themselves', async () => {
    await assertFails(change(as('carol'), 'a1', { assigneeUid: 'gina', assignedBy: 'carol' }));
    await assertFails(change(as('carol'), 'a1', { assigneeUid: 'nobody', assignedBy: 'carol' }));
    await assertFails(change(as('carol'), 'a1', { assigneeUid: 'bob', assignedBy: 'bob' }));
    await assertFails(change(as('carol'), 'a1', { assigneeUid: 'bob', assignedBy: null }));
    await assertFails(change(as('carol'), 'a1', { assignedBy: 'carol' }));
    await assertFails(change(as('gina'), 'a1', { assigneeUid: 'bob', assignedBy: 'gina' }));
  });

  it('rename and change a task someone volunteered for, who keeps it', async () => {
    await assertSucceeds(change(as('carol'), 'a2', { label: 'Water' }));
    await assertSucceeds(change(as('alice'), 'a2', { kind: 'other', label: 'Water and ice' }));
    expect(await storedTask('a2')).toMatchObject({ kind: 'other', label: 'Water and ice', assigneeUid: 'dan', assignedBy: 'dan' });
    await assertSucceeds(change(as('carol'), 'a3', { kind: 'scorekeeper', label: null }));
    for (const [id, changes] of [
      ['a1', { kind: 'other' }],
      ['a2', { label: null }],
      ['a2', { label: '  ' }],
      ['a2', { label: 'x'.repeat(41) }],
      ['a1', { kind: 'cookies' }],
      ['a1', { extra: true }],
    ] as [string, object][]) {
      await assertFails(change(as('carol'), id, changes));
    }
  });

  it('never move a task or change who made it and when', async () => {
    for (const changes of [{ groupId: 'teamB' }, { eventId: 'eB' }, { createdBy: 'carol' }, { createdAt: now() }]) {
      await assertFails(change(as('carol'), 'a1', changes));
    }
    await assertFails(as('carol').doc('assignments/a1').update({ label: 'No time' }));
    await assertFails(change(as('carol'), 'a1', { label: 'Old time', updatedAt: OLD }));
  });

  it('delete tasks, and members never do', async () => {
    await assertFails(as('bob').doc('assignments/a3').delete());
    await assertFails(as('dan').doc('assignments/a2').delete());
    await assertFails(as('gina').doc('assignments/a1').delete());
    await assertSucceeds(as('carol').doc('assignments/a1').delete());
    await assertSucceeds(as('alice').doc('assignments/a2').delete());
  });
});

describe('super admins (§3)', () => {
  it("manage any team's tasks, and never take one on a team they're not on", async () => {
    await assertSucceeds(change(root(), 'a1', { assigneeUid: 'bob', assignedBy: 'root' }));
    await assertSucceeds(change(root(), 'a2', { label: 'Water' }));
    await assertFails(change(root(), 'a3', { assigneeUid: 'root', assignedBy: 'root' }));
    await assertFails(change(root(), 'a1', { assigneeUid: 'dan', assignedBy: 'dan' }));
    await assertSucceeds(root().doc('assignments/a3').delete());
  });

  it('still manage them on a suspended team, which is closed to everyone on it', async () => {
    await setTeam({ suspendedAt: OLD });
    await assertFails(as('bob').doc('assignments/a1').get());
    await assertFails(list(as('alice')));
    await assertFails(change(as('bob'), 'a1', { assigneeUid: 'bob', assignedBy: 'bob' }));
    await assertFails(change(as('dan'), 'a2', { assigneeUid: null, assignedBy: null }));
    await assertFails(add(as('carol'), task('carol')));
    await assertFails(as('alice').doc('assignments/a1').delete());
    await assertSucceeds(list(root()));
    await assertSucceeds(change(root(), 'a1', { assigneeUid: 'bob', assignedBy: 'root' }));
  });
});

describe('an archived team (TEAM-9)', () => {
  beforeEach(() => setTeam({ archivedAt: OLD }));

  it('takes no task changes from anyone, super admins included, and still shows them', async () => {
    await assertFails(add(as('alice'), task('alice')));
    await assertFails(add(root(), task('root')));
    await assertFails(change(as('carol'), 'a1', { assigneeUid: 'bob', assignedBy: 'carol' }));
    await assertFails(change(as('carol'), 'a2', { label: 'Water' }));
    await assertFails(change(as('bob'), 'a1', { assigneeUid: 'bob', assignedBy: 'bob' }));
    await assertFails(change(as('dan'), 'a2', { assigneeUid: null, assignedBy: null }));
    await assertFails(change(root(), 'a1', { assigneeUid: 'bob', assignedBy: 'root' }));
    await assertFails(as('alice').doc('assignments/a1').delete());
    await assertFails(root().doc('assignments/a1').delete());
    await assertSucceeds(as('bob').doc('assignments/a1').get());
    await assertSucceeds(list(as('dan')));
  });

  it('takes them again once restored', async () => {
    await setTeam({ archivedAt: null });
    await assertSucceeds(change(as('bob'), 'a1', { assigneeUid: 'bob', assignedBy: 'bob' }));
    await assertSucceeds(add(as('alice'), task('alice')));
  });
});
