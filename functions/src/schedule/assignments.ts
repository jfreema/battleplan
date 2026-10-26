// Event assignments (SCHED-15): tasks on an event, such as snacks, drinks,
// or scorekeeper, each with at most one person. The app writes them
// directly under the rules; Functions only clean up after them. They go
// with their event (deleted by hand, by saveEventSeries, or with the team),
// and a person's are opened again when they leave a team or are removed
// from it (that team's) or delete their account (every team's).
import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { chunk } from '../notify/service.js';
import { db } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections } from '../shared/constants.js';

/** Deletes the assignments of [eventIds] (the events were deleted). Returns how many went. */
export async function deleteEventAssignments(eventIds: string[]): Promise<number> {
  let total = 0;
  // A query takes up to 30 values for 'in'.
  for (const part of chunk(eventIds, 30)) {
    total += await forEachPage(db().collection(Collections.assignments).where('eventId', 'in', part), (b, d) =>
      b.delete(d.ref),
    );
  }
  return total;
}

/**
 * Opens every task [uid] has, on team [groupId], or on every team when
 * it's left out: nobody has them, and nobody put anyone there. Each page
 * leaves the query as it's written, so this never loops. Returns how many
 * it opened.
 */
export async function clearAssignmentsOf(uid: string, groupId?: string): Promise<number> {
  let query = db().collection(Collections.assignments).where('assigneeUid', '==', uid);
  if (groupId !== undefined) query = query.where('groupId', '==', groupId);
  return forEachPage(query, (b, d) =>
    b.update(d.ref, { assigneeUid: null, assignedBy: null, updatedAt: FieldValue.serverTimestamp() }),
  );
}

/**
 * clearAssignmentsOf for one team that only logs if it fails, for callers
 * mid-way through taking someone off it: the membership is already gone,
 * so a retry wouldn't get this far again, and an admin can still open the
 * task by hand.
 */
export async function tryClearAssignmentsOf(uid: string, groupId: string): Promise<void> {
  await clearAssignmentsOf(uid, groupId).catch((e) =>
    logger.warn('assignments_cleanup_failed', { uid, groupId, error: String(e) }),
  );
}
