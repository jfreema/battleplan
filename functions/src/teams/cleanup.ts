// The nightly housekeeping behind dailyCleanup (ARCH §6.4 scheduled jobs).
import { logger } from 'firebase-functions/v2';
import { removeAllOrphanMessageFiles } from '../chat/service.js';
import { removeAllOrphanDocumentFiles } from '../documents/service.js';
import { pruneDevices } from '../notify/service.js';
import { remindOpenReports } from '../safety/alerts.js';
import { turnOffOldReminderDefaults } from './migrations.js';
import { reconcileAllStorage, type RecountResult } from './storage.js';

const MINUTE_MS = 60_000;

/** Past this, the night's log warns that the job is nearing its 9 minutes (#41). */
export const CLEANUP_SLOW_MS = 7 * MINUTE_MS;

/** The storage recount stops here, cleanly, and the next night goes on from where it stopped. */
export const CLEANUP_CUT_SHORT_MS = 8.5 * MINUTE_MS;

/** The night's steps, in the order they run. Tests pass their own. */
export interface CleanupSteps {
  remindOpenReports: () => Promise<number>;
  /** One-time changes to data, each run once (ops/migrations, #48). */
  runMigrations: () => Promise<number>;
  pruneDevices: () => Promise<number>;
  removeAllOrphanDocumentFiles: () => Promise<number>;
  removeAllOrphanMessageFiles: () => Promise<number>;
  reconcileAllStorage: (options: { stopAtMs: number }) => Promise<RecountResult>;
}

const STEPS: CleanupSteps = {
  remindOpenReports: () => remindOpenReports(),
  // #48: old teams' default reminders off; a no-op after its first night.
  runMigrations: async () => (await turnOffOldReminderDefaults())?.length ?? 0,
  pruneDevices: () => pruneDevices(),
  removeAllOrphanDocumentFiles,
  removeAllOrphanMessageFiles,
  reconcileAllStorage,
};

/**
 * Daily housekeeping (ARCH §6.4): first reminds super admins of reports
 * open more than 12 hours (SAFE-4), the step that matters most and one
 * quick query; then runs any one-time change to data not run yet (#48);
 * then prunes devices that stopped checking in, removes
 * document uploads whose document was never created and chat photos no
 * message shows, and last recomputes every team's storage total from the
 * bucket. Each step catches its own failure, so none stops the rest, and
 * each one's time is in the night's `daily_cleanup` log.
 */
export async function runDailyCleanup(steps: CleanupSteps = STEPS, now: () => number = Date.now) {
  const start = now();
  const timings: Record<string, number> = {};
  async function step<T>(name: string, failure: string, fallback: T, fn: () => Promise<T>): Promise<T> {
    const began = now();
    try {
      return await fn();
    } catch (e) {
      logger.error(failure, { error: String(e) });
      return fallback;
    } finally {
      timings[`${name}Ms`] = now() - began;
    }
  }
  // SAFE-4: super admins get one email while any report has been open more
  // than 12 hours, so none passes 24 hours unseen.
  const reportsWaiting = await step('reports', 'report_reminder_failed', 0, steps.remindOpenReports);
  // One-time changes to data, each run on the first night after its
  // release and recorded so it never runs again (#48).
  const migrated = await step('migrations', 'migration_failed', 0, steps.runMigrations);
  // NOTIF-10: the app rewrites its device at least daily, so one untouched
  // for 60 days is abandoned.
  const devicesPruned = await step('devices', 'device_prune_failed', 0, steps.pruneDevices);
  // DOC-2: an upload whose document was never saved (the app closed, the
  // save failed) is gone after a day. Before the recount, so it counts.
  const orphanDocumentFiles = await step(
    'orphanDocuments',
    'orphan_document_cleanup_failed',
    0,
    steps.removeAllOrphanDocumentFiles,
  );
  // CHAT-3 (#26): photos wait in the tray and upload before Send, so one
  // taken out, or a tray never sent, is gone after a day. Before the
  // recount too.
  const orphanMessageFiles = await step(
    'orphanPhotos',
    'orphan_message_cleanup_failed',
    0,
    steps.removeAllOrphanMessageFiles,
  );
  // STORE-3: every team's total from the bucket, one team at a time, so it
  // goes last, and stops before the job's time runs out.
  const recount = await step(
    'storage',
    'storage_reconcile_failed',
    { teams: 0, failed: 0, cutShort: false } as RecountResult,
    () => steps.reconcileAllStorage({ stopAtMs: start + CLEANUP_CUT_SHORT_MS }),
  );
  const totalMs = now() - start;
  if (recount.cutShort) logger.warn('daily_cleanup_cut_short', { teamsReconciled: recount.teams, totalMs });
  if (totalMs > CLEANUP_SLOW_MS) logger.warn('daily_cleanup_slow', { totalMs, ...timings });
  const summary = {
    reportsWaiting,
    migrated,
    devicesPruned,
    orphanDocumentFiles,
    orphanMessageFiles,
    teamsReconciled: recount.teams,
    teamsFailed: recount.failed,
    cutShort: recount.cutShort,
    totalMs,
    ...timings,
  };
  logger.info('daily_cleanup', summary);
  return summary;
}
