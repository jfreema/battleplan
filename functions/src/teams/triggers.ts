// Storage triggers and the daily job for team storage (ARCH §6.5, §6.6).
import { onObjectDeleted, onObjectFinalized } from 'firebase-functions/v2/storage';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import { addStorageBytes, groupIdFromPath, reconcileAllStorage } from './storage.js';
import { resendApiKey, sendEmail } from '../email/service.js';
import { planReminderEmail } from '../email/templates.js';
import { teamUrl } from '../links/service.js';
import { pruneDevices, trySend } from '../notify/service.js';
import { endExpiredPlans, takeDueReminders } from '../plans/service.js';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';

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
 * Daily housekeeping (ARCH §6.4 scheduled jobs): prunes devices that
 * stopped checking in, ends lapsed Plus plans and sends their reminders,
 * then recomputes every team's storage total from the bucket. Expiring
 * invites joins it with its feature.
 */
export const dailyCleanup = onSchedule(
  { schedule: 'every day 04:00', timeZone: 'America/Chicago', secrets: [resendApiKey] },
  async () => {
    // NOTIF-10: the app rewrites its device at least daily, so one untouched
    // for 60 days is abandoned. Pruned first, so today's pushes skip it.
    const devicesPruned = await pruneDevices().catch((e) => {
      logger.error('device_prune_failed', { error: String(e) });
      return 0;
    });
    // Plus (PLAN-5): end lapsed plans (which also resets the storage quota),
    // then remind holders and admins 30 and 7 days ahead, by email and
    // notification.
    const plansEnded = await endExpiredPlans();
    const reminders = await takeDueReminders();
    for (const r of reminders) {
      const group = await db().collection(Collections.groups).doc(r.groupId).get();
      const teamName = (group.get('name') as string | undefined) ?? 'Your team';
      const endsOn = r.endsAt.toLocaleDateString('en-US', { dateStyle: 'long', timeZone: 'America/Chicago' });
      for (const uid of r.uids) {
        const user = await db().collection(Collections.users).doc(uid).get();
        const email = user.get('email') as string | undefined;
        if (email) await sendEmail(planReminderEmail(email, teamName, endsOn, r.days, teamUrl(r.groupId)));
      }
      await trySend({
        kind: 'planReminder',
        groupId: r.groupId,
        recipients: { uids: r.uids },
        actor: null,
        target: { type: 'license', id: r.licenseId },
        route: `/g/${r.groupId}/settings`,
        params: { endsOn },
        body: `Plus ends on ${endsOn}`,
        // One per license and reminder, so a rerun of the job can't send it twice.
        dedupeKey: `planReminder_${r.licenseId}_${r.which}`,
        teamName,
      });
    }
    const teams = await reconcileAllStorage();
    logger.info('daily_cleanup', { plansEnded, reminders: reminders.length, devicesPruned, teamsReconciled: teams });
  },
);
