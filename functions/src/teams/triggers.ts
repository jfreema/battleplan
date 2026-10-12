// Storage triggers, the rename line, and the daily job for teams (ARCH §6.4, §6.11).
import { onObjectDeleted, onObjectFinalized } from 'firebase-functions/v2/storage';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentUpdatedWithAuthContext } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { postRenamedLine, renamedLine } from '../chat/service.js';
import { addStorageBytes, groupIdFromPath, reconcileAllStorage, updateStorageAlert } from './storage.js';
import { removeAllOrphanDocumentFiles } from '../documents/service.js';
import { pruneDevices } from '../notify/service.js';

/**
 * A file landed under `groups/{g}/`: count it toward the team's limit, and
 * warn its admins if that crossed 90% or filled it (STORE-3, STORE-4).
 */
export const onGroupFileAdded = onObjectFinalized(async (event) => {
  const groupId = groupIdFromPath(event.data.name);
  if (!groupId) return;
  await addStorageBytes(groupId, Number(event.data.size ?? 0));
  await updateStorageAlert(groupId);
});

/**
 * A file under `groups/{g}/` was removed (or overwritten, which removes the
 * old version): stop counting it. Freeing space lowers the warning, so the
 * next rise notifies again.
 */
export const onGroupFileRemoved = onObjectDeleted(async (event) => {
  const groupId = groupIdFromPath(event.data.name);
  if (!groupId) return;
  await addStorageBytes(groupId, -Number(event.data.size ?? 0));
  await updateStorageAlert(groupId);
});

/**
 * Daily housekeeping (ARCH §6.4 scheduled jobs): prunes devices that
 * stopped checking in, removes document uploads whose document was never
 * created, then recomputes every team's storage total from the bucket and
 * updates its warning. Expiring invites joins it with its feature.
 */
export const dailyCleanup = onSchedule({ schedule: 'every day 04:00', timeZone: 'America/Chicago' }, async () => {
  // NOTIF-10: the app rewrites its device at least daily, so one untouched
  // for 60 days is abandoned. Pruned first, so today's pushes skip it.
  const devicesPruned = await pruneDevices().catch((e) => {
    logger.error('device_prune_failed', { error: String(e) });
    return 0;
  });
  // DOC-2: an upload whose document was never saved (the app closed, the
  // save failed) is gone after a day. Before the recount, so it counts.
  const orphanDocumentFiles = await removeAllOrphanDocumentFiles().catch((e) => {
    logger.error('orphan_document_cleanup_failed', { error: String(e) });
    return 0;
  });
  const teams = await reconcileAllStorage();
  logger.info('daily_cleanup', { devicesPruned, orphanDocumentFiles, teamsReconciled: teams });
});

/**
 * groups updated → the "renamed" line in the team's chat (CHAT-10). Team
 * admins rename a team by writing its doc directly; the writer's team name
 * names who did it. Exits early when the name didn't change, which is
 * every other update (the last-message preview, storage totals).
 */
export const onGroupUpdated = onDocumentUpdatedWithAuthContext('groups/{groupId}', async (event) => {
  const before = event.data?.before.get('name');
  const after = event.data?.after.get('name');
  if (renamedLine(before, after, null) === null) return;
  // A Functions write (a super admin's change) has no member behind it.
  const actor = event.authType === 'service_account' || event.authType === 'system' ? null : (event.authId ?? null);
  await postRenamedLine(event.params.groupId, before, after, actor, event.id);
});
