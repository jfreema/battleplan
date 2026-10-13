// One team type (SPEC TEAM-1, PLAYER; ARCH §6.2): moves data written for
// adult and youth teams to the one model. Dev only: it refuses any project
// but the dev project and the local emulators (under a demo- project ID).
// Safe to run again: a second run finds nothing to change.
//
//   - groups: teamType deleted, kind 'team' set where missing
//   - events: rsvpFor deleted, and those events' counts redone the one way
//     (players in rsvpCounts, members' own answers in staffCounts, SCHED-5)
//   - players: status 'active' where missing
//   - playerGuardians (player links): relation 'guardian' where missing
//
// Dev, with your gcloud sign-in (gcloud auth application-default login):
//   npm --prefix tools/seed run migrate-one-type -- --project battleplan-dev-ecce4 --dry-run
//   npm --prefix tools/seed run migrate-one-type -- --project battleplan-dev-ecce4
// Emulators (firebase emulators:start --project demo-battleplan):
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix tools/seed run migrate-one-type -- --project demo-battleplan
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import {
  FieldPath,
  FieldValue,
  getFirestore,
  type DocumentData,
  type Firestore,
  type QueryDocumentSnapshot,
} from 'firebase-admin/firestore';
import { pathToFileURL } from 'node:url';
import { DEV_PROJECT } from './demo-target.js';

export interface MigrationTarget {
  projectId: string;
  emulators: boolean;
  dryRun: boolean;
}

/** Reads the target from the command line and environment, or says why not. */
export function migrationTarget(
  argv: readonly string[],
  env: Readonly<Record<string, string | undefined>>,
): MigrationTarget | { error: string } {
  const at = argv.indexOf('--project');
  const projectId = at >= 0 ? argv[at + 1] : undefined;
  const dryRun = argv.includes('--dry-run');
  if (!projectId || projectId.startsWith('--')) {
    return { error: `Usage: migrate-one-type --project ${DEV_PROJECT} [--dry-run] (or --project demo-battleplan with the emulators)` };
  }
  const emulators = Boolean(env.FIRESTORE_EMULATOR_HOST);
  if (projectId.startsWith('demo-')) {
    if (!emulators) return { error: 'A demo- project needs the emulators: set FIRESTORE_EMULATOR_HOST.' };
    return { projectId, emulators, dryRun };
  }
  if (projectId !== DEV_PROJECT) return { error: `Refusing ${projectId}: only ${DEV_PROJECT} or the emulators.` };
  if (emulators) return { error: `Refusing ${DEV_PROJECT} with FIRESTORE_EMULATOR_HOST set; unset it or use a demo- project.` };
  return { projectId, emulators, dryRun };
}

/** What one document needs: fields to delete and fields to set. Null when nothing. */
export interface Change {
  delete: string[];
  set: Record<string, unknown>;
}

const change = (del: string[], set: Record<string, unknown>): Change | null =>
  del.length || Object.keys(set).length ? { delete: del, set } : null;

/** A team: no teamType, kind 'team' (a missing kind reads as 'team', but new readers may filter on it). */
export function planGroup(d: DocumentData): Change | null {
  return change('teamType' in d ? ['teamType'] : [], d.kind == null ? { kind: 'team' } : {});
}

/** An event: no rsvpFor. Its counts are redone separately (recount). */
export function planEvent(d: DocumentData): Change | null {
  return change('rsvpFor' in d ? ['rsvpFor'] : [], {});
}

/** A player: status 'active' where missing (players before approvals were all on the roster). */
export function planPlayer(d: DocumentData): Change | null {
  return change([], d.status == null ? { status: 'active' } : {});
}

/** A player link: relation 'guardian' where missing (every link before claims was a guardian's). */
export function planLink(d: DocumentData): Change | null {
  return change([], d.relation == null ? { relation: 'guardian' } : {});
}

type Counts = { going: number; maybe: number; notGoing: number };

/** An event's counts the one way (SCHED-5): players apart from members answering for themselves. */
export function countsOf(rsvps: DocumentData[]): { rsvpCounts: Counts; staffCounts: Counts } {
  const rsvpCounts = { going: 0, maybe: 0, notGoing: 0 };
  const staffCounts = { going: 0, maybe: 0, notGoing: 0 };
  for (const r of rsvps) {
    const c = r.participantType === 'player' ? rsvpCounts : r.participantType === 'member' ? staffCounts : null;
    if (!c) continue;
    if (r.status === 'going') c.going++;
    else if (r.status === 'maybe') c.maybe++;
    else if (r.status === 'not_going') c.notGoing++;
  }
  return { rsvpCounts, staffCounts };
}

export interface MigrationReport {
  dryRun: boolean;
  groups: { scanned: number; changed: number };
  events: { scanned: number; changed: number };
  players: { scanned: number; changed: number };
  playerLinks: { scanned: number; changed: number };
}

/** Every document of [collection], 300 to a page. */
async function forEachDoc(
  db: Firestore,
  collection: string,
  visit: (d: QueryDocumentSnapshot) => Promise<void>,
): Promise<number> {
  let last: QueryDocumentSnapshot | undefined;
  let scanned = 0;
  for (;;) {
    let q = db.collection(collection).orderBy(FieldPath.documentId()).limit(300);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    for (const d of page.docs) await visit(d);
    scanned += page.size;
    if (page.size < 300) return scanned;
    last = page.docs[page.docs.length - 1];
  }
}

/** Runs the migration on [db]; with [dryRun], only counts what it would change. */
export async function migrate(db: Firestore, dryRun: boolean): Promise<MigrationReport> {
  const report: MigrationReport = {
    dryRun,
    groups: { scanned: 0, changed: 0 },
    events: { scanned: 0, changed: 0 },
    players: { scanned: 0, changed: 0 },
    playerLinks: { scanned: 0, changed: 0 },
  };
  const apply = async (d: QueryDocumentSnapshot, c: Change, extra: Record<string, unknown> = {}) => {
    if (dryRun) return;
    await d.ref.update({
      ...Object.fromEntries(c.delete.map((f) => [f, FieldValue.delete()])),
      ...c.set,
      ...extra,
    });
  };
  const steps: [keyof Omit<MigrationReport, 'dryRun'>, string, (d: DocumentData) => Change | null][] = [
    ['groups', 'groups', planGroup],
    ['players', 'players', planPlayer],
    ['playerLinks', 'playerGuardians', planLink],
  ];
  for (const [key, collection, plan] of steps) {
    report[key].scanned = await forEachDoc(db, collection, async (d) => {
      const c = plan(d.data());
      if (!c) return;
      report[key].changed++;
      await apply(d, c);
    });
  }
  report.events.scanned = await forEachDoc(db, 'events', async (d) => {
    const c = planEvent(d.data());
    if (!c) return;
    report.events.changed++;
    if (dryRun) return;
    // An old 'members' event counted members in rsvpCounts; count them apart.
    const rsvps = await db.collection('rsvps').where('eventId', '==', d.id).get();
    await apply(d, c, countsOf(rsvps.docs.map((r) => r.data())));
  });
  return report;
}

async function main(): Promise<void> {
  const target = migrationTarget(process.argv.slice(2), process.env);
  if ('error' in target) {
    console.error(target.error);
    process.exit(1);
  }
  const app = initializeApp({
    projectId: target.projectId,
    ...(target.emulators ? {} : { credential: applicationDefault() }),
  });
  const report = await migrate(getFirestore(app), target.dryRun);
  console.log(`${target.dryRun ? 'Would change' : 'Changed'} in ${target.projectId}:`);
  for (const key of ['groups', 'events', 'players', 'playerLinks'] as const) {
    console.log(`  ${key}: ${report[key].changed} of ${report[key].scanned}`);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
