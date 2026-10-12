// Thin entry points for the schedule domain (ARCH §6.4).
import { onCall } from 'firebase-functions/v2/https';
import { requireAuth } from '../shared/guards.js';
import { parse } from '../shared/validate.js';
import { SaveSeriesInput, saveSeries } from './series.js';

/**
 * Creates, edits, cancels, or deletes a repeating series, or one event in
 * it (SCHED-3, SCHED-6, SCHED-7). Creating needs the same permission as
 * creating an event (Q12) and room on the team (STORE-4); changes need a
 * team admin, or the series' creator while members may create events. With
 * dryRun it writes nothing and returns the same counts. One chat card and
 * one notification per call, never one per event.
 */
export const saveEventSeries = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(SaveSeriesInput, request.data);
  return saveSeries(input, { uid, superAdmin: request.auth?.token.superAdmin === true });
});
