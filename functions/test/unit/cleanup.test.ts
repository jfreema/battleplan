// The nightly housekeeping (ARCH §6.4 dailyCleanup, #41): the report
// reminder goes first, a step that fails never stops the rest, and the
// night's log warns before the job's time runs out. Its time limit and
// the recount's own catches are in test/emulator/storage.test.ts.
import { describe, expect, it, vi } from 'vitest';
import { logger } from 'firebase-functions/v2';
import { CLEANUP_CUT_SHORT_MS, CLEANUP_SLOW_MS, runDailyCleanup, type CleanupSteps } from '../../src/teams/cleanup.js';

/** Steps that note when they ran, each taking [ms] of a fake clock. */
function steps(over: Partial<CleanupSteps> = {}, ms = 1_000) {
  let clock = 0;
  const ran: string[] = [];
  const step = (name: string, result: number) => async () => {
    ran.push(name);
    clock += ms;
    return result;
  };
  const all: CleanupSteps = {
    remindOpenReports: step('reports', 2),
    pruneDevices: step('devices', 3),
    removeAllOrphanDocumentFiles: step('documents', 4),
    removeAllOrphanMessageFiles: step('photos', 5),
    reconcileAllStorage: async ({ stopAtMs }) => {
      ran.push(`storage until ${stopAtMs}`);
      clock += ms;
      return { teams: 6, failed: 0, cutShort: false };
    },
    ...over,
  };
  return { all, ran, now: () => clock, advance: (n: number) => (clock += n) };
}

describe('dailyCleanup (ARCH §6.4, SAFE-4)', () => {
  it('reminds about open reports first, and the storage recount goes last, stopping at 8.5 minutes', async () => {
    const s = steps();
    const out = await runDailyCleanup(s.all, s.now);
    expect(s.ran).toEqual(['reports', 'devices', 'documents', 'photos', `storage until ${CLEANUP_CUT_SHORT_MS}`]);
    expect(out).toMatchObject({
      reportsWaiting: 2,
      devicesPruned: 3,
      orphanDocumentFiles: 4,
      orphanMessageFiles: 5,
      teamsReconciled: 6,
      teamsFailed: 0,
      cutShort: false,
      totalMs: 5_000,
      reportsMs: 1_000,
      storageMs: 1_000,
    });
  });

  it('keeps going when a step fails, the storage recount included', async () => {
    const error = vi.spyOn(logger, 'error').mockImplementation(() => undefined);
    const s = steps({
      pruneDevices: async () => {
        throw new Error('devices down');
      },
      reconcileAllStorage: async () => {
        throw new Error('bucket down');
      },
    });
    const out = await runDailyCleanup(s.all, s.now);
    expect(s.ran).toEqual(['reports', 'documents', 'photos']);
    expect(out).toMatchObject({ reportsWaiting: 2, devicesPruned: 0, teamsReconciled: 0 });
    expect(error.mock.calls.map((c) => c[0])).toEqual(['device_prune_failed', 'storage_reconcile_failed']);
    error.mockRestore();
  });

  it('runs the report reminder even when everything after it fails', async () => {
    vi.spyOn(logger, 'error').mockImplementation(() => undefined);
    const boom = async () => {
      throw new Error('down');
    };
    const s = steps({ pruneDevices: boom, removeAllOrphanDocumentFiles: boom, removeAllOrphanMessageFiles: boom });
    const out = await runDailyCleanup(s.all, s.now);
    expect(s.ran[0]).toBe('reports');
    expect(out.reportsWaiting).toBe(2);
    vi.restoreAllMocks();
  });

  it('warns past 7 minutes, and says when the recount was cut short', async () => {
    const warn = vi.spyOn(logger, 'warn').mockImplementation(() => undefined);
    const s = steps({
      reconcileAllStorage: async () => {
        s.advance(CLEANUP_SLOW_MS);
        return { teams: 40, failed: 1, cutShort: true };
      },
    });
    const out = await runDailyCleanup(s.all, s.now);
    expect(warn.mock.calls.map((c) => c[0])).toEqual(['daily_cleanup_cut_short', 'daily_cleanup_slow']);
    expect(out).toMatchObject({ teamsReconciled: 40, teamsFailed: 1, cutShort: true });
    warn.mockRestore();
  });

  it('stays quiet on a quick night', async () => {
    const warn = vi.spyOn(logger, 'warn').mockImplementation(() => undefined);
    const s = steps();
    await runDailyCleanup(s.all, s.now);
    expect(warn).not.toHaveBeenCalled();
    warn.mockRestore();
  });
});
