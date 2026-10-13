// Tests for the one-team-type migration (migrate-one-type.ts). The plans
// and the target check run anywhere; the end-to-end run needs the
// Firestore emulator and is skipped without it:
//   npm --prefix tools/seed run test:emulators
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import assert from 'node:assert/strict';
import { before, beforeEach, describe, it } from 'node:test';
import { DEV_PROJECT } from './demo-target.js';
import { countsOf, migrate, migrationTarget, planEvent, planGroup, planLink, planPlayer } from './migrate-one-type.js';

describe('migrationTarget', () => {
  const emu = { FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080' };

  it('takes the dev project, and a demo- project on the emulators', () => {
    assert.deepEqual(migrationTarget(['--project', DEV_PROJECT], {}), { projectId: DEV_PROJECT, emulators: false, dryRun: false });
    assert.deepEqual(migrationTarget(['--project', 'demo-battleplan', '--dry-run'], emu), {
      projectId: 'demo-battleplan',
      emulators: true,
      dryRun: true,
    });
  });

  it('refuses every other project, and mixed-up targets', () => {
    for (const [argv, env] of [
      [['--project', 'battleplan-prod'], {}],
      [['--project', 'battleplan-prod'], emu],
      [['--project', 'demo-battleplan'], {}],
      [['--project', DEV_PROJECT], emu],
      [['--project'], {}],
      [['--dry-run'], {}],
    ] as [string[], Record<string, string>][]) {
      assert.ok('error' in migrationTarget(argv, env), argv.join(' '));
    }
  });
});

describe('plans', () => {
  it('drops teamType and sets kind once', () => {
    assert.deepEqual(planGroup({ name: 'A', teamType: 'youth' }), { delete: ['teamType'], set: { kind: 'team' } });
    assert.deepEqual(planGroup({ name: 'A', teamType: 'adult', kind: 'team' }), { delete: ['teamType'], set: {} });
    assert.equal(planGroup({ name: 'A', kind: 'team' }), null);
  });

  it('drops rsvpFor, and sets status and relation only where missing', () => {
    assert.deepEqual(planEvent({ rsvpFor: 'members' }), { delete: ['rsvpFor'], set: {} });
    assert.equal(planEvent({ title: 'Practice' }), null);
    assert.deepEqual(planPlayer({ displayName: 'Emma' }), { delete: [], set: { status: 'active' } });
    assert.equal(planPlayer({ status: 'pending' }), null);
    assert.deepEqual(planLink({ uid: 'maria' }), { delete: [], set: { relation: 'guardian' } });
    assert.equal(planLink({ relation: 'self' }), null);
  });

  it('counts players apart from members answering for themselves', () => {
    assert.deepEqual(
      countsOf([
        { participantType: 'member', status: 'going' },
        { participantType: 'player', status: 'maybe' },
        { participantType: 'player', status: 'not_going' },
        { participantType: 'other', status: 'going' },
      ]),
      { rsvpCounts: { going: 0, maybe: 1, notGoing: 1 }, staffCounts: { going: 1, maybe: 0, notGoing: 0 } },
    );
  });
});

describe('migrate on the emulator', { skip: !process.env.FIRESTORE_EMULATOR_HOST && 'needs the Firestore emulator' }, () => {
  const project = process.env.GCLOUD_PROJECT ?? 'demo-battleplan';
  let db: Firestore;

  before(() => {
    db = getFirestore(initializeApp({ projectId: project }, 'migrate-one-type-test'));
  });

  beforeEach(async () => {
    const res = await fetch(
      `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project}/databases/(default)/documents`,
      { method: 'DELETE' },
    );
    assert.ok(res.ok);
    const zeros = { going: 0, maybe: 0, notGoing: 0 };
    await db.doc('groups/adult').set({ name: 'Thunder', teamType: 'adult', playerCount: 0 });
    await db.doc('groups/youth').set({ name: 'Lightning', teamType: 'youth', playerCount: 1 });
    await db.doc('groups/new').set({ name: 'New', kind: 'team' });
    await db.doc('events/eA').set({ groupId: 'adult', rsvpFor: 'members', rsvpCounts: { going: 2, maybe: 0, notGoing: 0 }, staffCounts: zeros });
    await db.doc('events/eY').set({ groupId: 'youth', rsvpFor: 'players', rsvpCounts: { going: 1, maybe: 0, notGoing: 0 }, staffCounts: { going: 1, maybe: 0, notGoing: 0 } });
    await db.doc('events/eNew').set({ groupId: 'new', rsvpCounts: zeros, staffCounts: zeros });
    await db.doc('rsvps/eA_pat').set({ eventId: 'eA', participantType: 'member', participantId: 'pat', status: 'going' });
    await db.doc('rsvps/eA_sam').set({ eventId: 'eA', participantType: 'member', participantId: 'sam', status: 'going' });
    await db.doc('rsvps/eY_emma').set({ eventId: 'eY', participantType: 'player', participantId: 'emma', status: 'going' });
    await db.doc('rsvps/eY_coach').set({ eventId: 'eY', participantType: 'member', participantId: 'coach', status: 'going' });
    await db.doc('players/emma').set({ groupId: 'youth', displayName: 'Emma' });
    await db.doc('players/zoe').set({ groupId: 'new', displayName: 'Zoe', status: 'pending', proposedBy: 'sam' });
    await db.doc('playerGuardians/emma_maria').set({ groupId: 'youth', playerId: 'emma', uid: 'maria' });
    await db.doc('playerGuardians/emma_ana').set({ groupId: 'youth', playerId: 'emma', uid: 'ana', relation: 'self' });
  });

  const data = async (path: string) => (await db.doc(path).get()).data()!;

  it('counts on a dry run and writes nothing', async () => {
    const report = await migrate(db, true);
    assert.deepEqual(report, {
      dryRun: true,
      groups: { scanned: 3, changed: 2 },
      events: { scanned: 3, changed: 2 },
      players: { scanned: 2, changed: 1 },
      playerLinks: { scanned: 2, changed: 1 },
    });
    assert.equal((await data('groups/adult')).teamType, 'adult');
    assert.equal((await data('events/eA')).rsvpFor, 'members');
    assert.equal((await data('players/emma')).status, undefined);
  });

  it('moves everything to one team type, and changes nothing the second time', async () => {
    await migrate(db, false);
    for (const g of ['adult', 'youth', 'new']) {
      const team = await data(`groups/${g}`);
      assert.equal(team.kind, 'team');
      assert.ok(!('teamType' in team), g);
    }
    const eA = await data('events/eA');
    assert.ok(!('rsvpFor' in eA));
    // The old members-only event's answers are members' own: "others".
    assert.deepEqual(eA.rsvpCounts, { going: 0, maybe: 0, notGoing: 0 });
    assert.deepEqual(eA.staffCounts, { going: 2, maybe: 0, notGoing: 0 });
    const eY = await data('events/eY');
    assert.ok(!('rsvpFor' in eY));
    assert.deepEqual(eY.rsvpCounts, { going: 1, maybe: 0, notGoing: 0 });
    assert.deepEqual(eY.staffCounts, { going: 1, maybe: 0, notGoing: 0 });
    assert.equal((await data('players/emma')).status, 'active');
    assert.equal((await data('players/zoe')).status, 'pending');
    assert.equal((await data('playerGuardians/emma_maria')).relation, 'guardian');
    assert.equal((await data('playerGuardians/emma_ana')).relation, 'self');

    const again = await migrate(db, false);
    for (const key of ['groups', 'events', 'players', 'playerLinks'] as const) assert.equal(again[key].changed, 0, key);
  });
});
