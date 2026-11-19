// The notification retry job (ARCH §6.4 scheduled jobs, §6.5).
import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { retryDueNotifications } from './service.js';

/**
 * Every minute, finishes notifications whose send failed partway (#41):
 * the center items not written yet, and pushes to the people not pushed
 * yet, never twice. With none waiting, which is almost always, it's one
 * empty read and quiet.
 */
export const retryNotifications = onSchedule(
  { schedule: 'every 1 minutes', timeZone: 'America/Chicago', timeoutSeconds: 300 },
  async () => {
    const result = await retryDueNotifications();
    if (result.sent || result.gaveUp || result.waiting) logger.info('notify_retries', result);
  },
);
