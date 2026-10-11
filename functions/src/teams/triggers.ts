// Storage triggers and the daily job for team storage (ARCH §6.5, §6.6).
import { onObjectDeleted, onObjectFinalized } from 'firebase-functions/v2/storage';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import { addStorageBytes, groupIdFromPath, reconcileAllStorage } from './storage.js';

/** A file landed under `groups/{g}/`: count it toward the team's quota. */
export const onGroupFileAdded = onObjectFinalized(async (event) => {
  const groupId = groupIdFromPath(event.data.name);
  if (groupId) await addStorageBytes(groupId, Number(event.data.size ?? 0));
});

/**
 * A file under `groups/{g}/` was removed (or overwritten, which removes the
 * old version): stop counting it.
 */
export const onGroupFileRemoved = onObjectDeleted(async (event) => {
  const groupId = groupIdFromPath(event.data.name);
  if (groupId) await addStorageBytes(groupId, -Number(event.data.size ?? 0));
});

/**
 * Daily housekeeping (ARCH §6.6). For now it recomputes every team's
 * storage total from the bucket; expiring invites and pruning device tokens
 * join it with their features.
 */
export const dailyCleanup = onSchedule({ schedule: 'every day 04:00', timeZone: 'America/Chicago' }, async () => {
  const teams = await reconcileAllStorage();
  logger.info('daily_cleanup', { teamsReconciled: teams });
});
