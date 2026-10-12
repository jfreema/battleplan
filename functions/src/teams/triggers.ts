// Storage triggers and the daily job for team storage (ARCH §6.4, §6.11).
import { onObjectDeleted, onObjectFinalized } from 'firebase-functions/v2/storage';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import { addStorageBytes, groupIdFromPath, reconcileAllStorage, updateStorageAlert } from './storage.js';
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
 * stopped checking in, then recomputes every team's storage total from the
 * bucket and updates its warning. Expiring invites joins it with its
 * feature.
 */
export const dailyCleanup = onSchedule({ schedule: 'every day 04:00', timeZone: 'America/Chicago' }, async () => {
  // NOTIF-10: the app rewrites its device at least daily, so one untouched
  // for 60 days is abandoned. Pruned first, so today's pushes skip it.
  const devicesPruned = await pruneDevices().catch((e) => {
    logger.error('device_prune_failed', { error: String(e) });
    return 0;
  });
  const teams = await reconcileAllStorage();
  logger.info('daily_cleanup', { devicesPruned, teamsReconciled: teams });
});
