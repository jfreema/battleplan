// Frequent scheduled work (ARCH §6.4 scheduled jobs).
import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { backfillSearchWords } from '../chat/search.js';
import { closeDuePolls } from '../polls/service.js';
import { sendDueReminders } from '../schedule/service.js';

/**
 * Every 5 minutes: close polls whose close time has passed and tell their
 * voters (POLL-4), send the event reminders that are due (SCHED-8), and
 * give messages from before chat search their words, a page at a time
 * until all have them (CHAT-20). Each step reads only what's due, so a
 * quiet tick costs one empty query or read per step, and one step failing
 * doesn't stop the others.
 */
export const tick = onSchedule({ schedule: 'every 5 minutes', timeZone: 'America/Chicago' }, async () => {
  const [pollsClosed, remindersSent, messagesIndexed] = await Promise.all([
    closeDuePolls().catch((e) => {
      logger.error('tick_polls_failed', { error: String(e) });
      return 0;
    }),
    sendDueReminders().catch((e) => {
      logger.error('tick_reminders_failed', { error: String(e) });
      return 0;
    }),
    backfillSearchWords().catch((e) => {
      logger.error('tick_search_words_failed', { error: String(e) });
      return 0;
    }),
  ]);
  if (pollsClosed || remindersSent || messagesIndexed) {
    logger.info('tick', { pollsClosed, remindersSent, messagesIndexed });
  }
});
