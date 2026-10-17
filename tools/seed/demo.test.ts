// The App Review demo seed (SPEC §10): where it may write, and what it writes.
//   npm --prefix tools/seed test
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { DEMO_PEOPLE, DEMO_TEAM, DEMO_YOUTH_TEAM, demoDocs } from './demo-data.js';
import { CONFIRM_FLAG, DEFAULT_DEMO_EMAIL, DEV_PROJECT, PROD_CONFIRM_FLAG, PROD_PROJECT, demoTarget } from './demo-target.js';

const emulators = { FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080', FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099' };
const longPassword = 'correct-horse-battery';

describe('demoTarget', () => {
  it('writes to dev only with the flag and a long password', () => {
    assert.deepEqual(demoTarget(['--project', DEV_PROJECT, CONFIRM_FLAG], { DEMO_PASSWORD: longPassword }), {
      projectId: DEV_PROJECT,
      emulators: false,
      email: DEFAULT_DEMO_EMAIL,
      password: longPassword,
    });
    assert.match(errorOf(demoTarget(['--project', DEV_PROJECT], { DEMO_PASSWORD: longPassword })), /--write-to-dev/);
    assert.match(errorOf(demoTarget(['--project', DEV_PROJECT, CONFIRM_FLAG], { DEMO_PASSWORD: 'short' })), /DEMO_PASSWORD/);
    assert.match(errorOf(demoTarget(['--project', DEV_PROJECT, CONFIRM_FLAG], {})), /DEMO_PASSWORD/);
    assert.match(
      errorOf(demoTarget(['--project', DEV_PROJECT, CONFIRM_FLAG], { ...emulators, DEMO_PASSWORD: longPassword })),
      /emulator hosts/,
    );
  });

  it('writes to prod only with its own flag, and never to any other project', () => {
    assert.match(errorOf(demoTarget(['--project', PROD_PROJECT, CONFIRM_FLAG], { DEMO_PASSWORD: longPassword })), /--write-to-prod/);
    assert.equal(
      (demoTarget(['--project', PROD_PROJECT, PROD_CONFIRM_FLAG], { DEMO_PASSWORD: longPassword }) as { projectId: string }).projectId,
      PROD_PROJECT,
    );
    const result = demoTarget(['--project', 'someone-else', CONFIRM_FLAG], { DEMO_PASSWORD: longPassword });
    assert.match(errorOf(result), /Refusing/);
    assert.match(errorOf(demoTarget([], {})), /Usage/);
    assert.match(errorOf(demoTarget(['--project', CONFIRM_FLAG], {})), /Usage/);
  });

  it('uses the emulators under a demo- project ID only when their hosts are set', () => {
    assert.deepEqual(demoTarget(['--project', 'demo-battleplan'], emulators), {
      projectId: 'demo-battleplan',
      emulators: true,
      email: DEFAULT_DEMO_EMAIL,
      password: 'password',
    });
    assert.match(errorOf(demoTarget(['--project', 'demo-battleplan'], {})), /emulators/);
  });

  it('takes another email from DEMO_EMAIL, and checks it', () => {
    const t = demoTarget(['--project', 'demo-battleplan'], { ...emulators, DEMO_EMAIL: ' Review@Example.com ' });
    assert.equal('error' in t ? '' : t.email, 'review@example.com');
    assert.match(errorOf(demoTarget(['--project', 'demo-battleplan'], { ...emulators, DEMO_EMAIL: 'nope' })), /Not an email/);
  });
});

describe('demoDocs', () => {
  const demo = { uid: 'demo-appreview', email: DEFAULT_DEMO_EMAIL };
  const docs = demoDocs(demo, new Date('2026-10-12T15:00:00Z'));
  const byPath = new Map(docs.map((d) => [d.path, d.data]));
  const inCollection = (c: string) => docs.filter((d) => d.path.startsWith(`${c}/`));

  it('touches only demo- documents and the demo account', () => {
    for (const d of docs) {
      const id = d.path.split('/')[1];
      assert.ok(id.startsWith('demo-') || id === demo.uid, d.path);
    }
    assert.equal(new Set(docs.map((d) => d.path)).size, docs.length, 'no path twice');
  });

  it('gives the demo account a finished profile, an owned team, and a player', () => {
    const me = byPath.get(`users/${demo.uid}`)!;
    assert.equal(me.email, DEFAULT_DEMO_EMAIL);
    assert.ok(me.acceptedTermsAt instanceof Date);
    assert.ok(me.adultConfirmedAt instanceof Date);
    assert.equal(byPath.get(`groupMembers/${DEMO_TEAM}_${demo.uid}`)!.role, 'owner');
    assert.equal(byPath.get(`groups/${DEMO_TEAM}`)!.ownerId, demo.uid);
    assert.equal(byPath.get(`groupMembers/${DEMO_YOUTH_TEAM}_${demo.uid}`)!.role, 'member');
    assert.ok(byPath.has(`playerGuardians/demo-riley_${demo.uid}`));
    for (const p of DEMO_PEOPLE) assert.ok(byPath.has(`users/${p.uid}`));
  });

  it('keeps the cached counts and author snapshots true (ARCH §6.2)', () => {
    for (const team of [DEMO_TEAM, DEMO_YOUTH_TEAM]) {
      const group = byPath.get(`groups/${team}`)!;
      const members = inCollection('groupMembers').filter((d) => d.data.groupId === team);
      const players = inCollection('players').filter((d) => d.data.groupId === team && d.data.status === 'active');
      assert.equal(group.memberCount, members.length);
      assert.equal(group.playerCount, players.length);
    }
    for (const m of inCollection('messages')) {
      const member = byPath.get(`groupMembers/${m.data.groupId}_${m.data.authorId}`);
      assert.ok(member, `${m.path} is by a member`);
      assert.equal(m.data.authorName, member.displayName);
      assert.equal(m.data.authorPlayerSummary, member.playerSummary);
    }
    for (const e of inCollection('events')) {
      const answers = inCollection('rsvps').filter((r) => r.data.eventId === e.path.split('/')[1]);
      const total = (c: unknown) => Object.values(c as Record<string, number>).reduce((a, b) => a + b, 0);
      const players = answers.filter((r) => r.data.participantType === 'player').length;
      assert.equal(total(e.data.rsvpCounts), players, e.path);
      assert.equal(total(e.data.staffCounts), answers.length - players, e.path);
      assert.ok((e.data.startAt as Date).getTime() > Date.parse('2026-10-12T15:00:00Z'), 'upcoming');
    }
  });
});

describe('demo data: one team type (TEAM-1, PLAYER-3, PLAYER-4)', () => {
  const docs = demoDocs({ uid: 'demo-appreview', email: DEFAULT_DEMO_EMAIL }, new Date('2026-10-12T15:00:00Z'));
  const inCollection = (c: string) => docs.filter((d) => d.path.startsWith(`${c}/`));

  it('writes kind team and no teamType or rsvpFor', () => {
    for (const g of inCollection('groups')) {
      assert.equal(g.data.kind, 'team');
      assert.ok(!('teamType' in g.data), g.path);
    }
    for (const e of inCollection('events')) assert.ok(!('rsvpFor' in e.data), e.path);
  });

  it('gives every player a status and every link a relation, with a player on the adult team', () => {
    for (const p of inCollection('players')) assert.ok(['active', 'pending'].includes(p.data.status as string), p.path);
    for (const l of inCollection('playerGuardians')) assert.ok(['self', 'guardian'].includes(l.data.relation as string), l.path);
    const self = inCollection('playerGuardians').find((l) => l.data.relation === 'self');
    assert.equal(self?.data.groupId, DEMO_TEAM);
    const pending = inCollection('players').filter((p) => p.data.status === 'pending');
    assert.equal(pending.length, 1);
    assert.ok(pending[0].data.proposedBy);
    // No link until it's approved.
    assert.ok(!inCollection('playerGuardians').some((l) => l.data.playerId === pending[0].path.split('/')[1]));
  });
});

describe('demo data: player details (PLAYER-12)', () => {
  const docs = demoDocs({ uid: 'demo-appreview', email: DEFAULT_DEMO_EMAIL }, new Date('2026-10-12T15:00:00Z'));
  const byPath = new Map(docs.map((d) => [d.path, d.data]));
  const details = docs.filter((d) => d.path.startsWith('playerDetails/'));

  it('writes them as the rules take them, for active players, on their team', () => {
    assert.ok(details.length >= 1);
    const keys = ['groupId', 'dateOfBirth', 'emergencyContacts', 'medicalNotes', 'medicalConsentAt', 'medicalConsentBy',
      'notes', 'updatedBy', 'updatedAt'];
    for (const d of details) {
      const player = byPath.get(`players/${d.path.split('/')[1]}`);
      assert.equal(player?.status, 'active', d.path);
      assert.equal(d.data.groupId, player?.groupId, d.path);
      for (const k of Object.keys(d.data)) assert.ok(keys.includes(k), `${d.path}: ${k}`);
      assert.match(d.data.dateOfBirth as string, /^\d{4}-\d{2}-\d{2}$/);
      assert.ok(Date.parse(d.data.dateOfBirth as string) < Date.parse('2026-10-12T00:00:00Z'), 'in the past');
      const contacts = d.data.emergencyContacts as { name: string; phone: string }[];
      assert.ok(contacts.length <= 2 && contacts.every((c) => c.name && c.phone), d.path);
      // Medical notes carry consent (PLAYER-12).
      if (d.data.medicalNotes) assert.ok(d.data.medicalConsentAt instanceof Date && d.data.medicalConsentBy, d.path);
    }
  });
});

function errorOf(result: ReturnType<typeof demoTarget>): string {
  return 'error' in result ? result.error : '';
}
