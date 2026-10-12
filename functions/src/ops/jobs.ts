// Frequent scheduled work (ARCH §6.4 scheduled jobs).
import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { closeDuePolls } from '../polls/service.js';

/**
 * Every 5 minutes: close polls whose close time has passed and tell their
 * voters (POLL-4). Event reminders join this job with M6. Each step reads
 * only what's due, so a quiet tick costs one empty query per step.
 */
export const tick = onSchedule({ schedule: 'every 5 minutes', timeZone: 'America/Chicago' }, async () => {
  const pollsClosed = await closeDuePolls().catch((e) => {
    logger.error('tick_polls_failed', { error: String(e) });
    return 0;
  });
  if (pollsClosed) logger.info('tick', { pollsClosed });
});
