// One-time changes to data, each run once by the nightly job and recorded
// in ops/migrations (ARCH §6.4, #48).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';

/** Teams made before this kept the old default of a reminder the day before (#48). */
export const REMINDERS_OFF_BEFORE = new Date('2026-11-01T00:00:00-05:00');

/** The old default: one reminder, a day (1,440 minutes) before. */
const OLD_DEFAULT = [1440];

/** Who the audit log names for what Battleplan itself does. */
export const SYSTEM_ACTOR = 'Battleplan';

const migrations = () => db().collection(Collections.ops).doc('migrations');

function isOldDefault(value: unknown): boolean {
  return Array.isArray(value) && value.length === OLD_DEFAULT.length && value.every((v, i) => v === OLD_DEFAULT[i]);
}

/**
 * #48: teams made before Nov 1, 2026 still on the old default of a reminder
 * the day before get No reminders (`settings.defaultReminderOffsets: []`),
 * as new teams have had since the owner asked on Nov 1. Teams whose admins
 * picked anything else, newer teams, archived and deleted teams, and every
 * event already made are left alone. It runs once: the first run records
 * the teams it changed in `ops/migrations.reminderDefaultsOff`, and any
 * later run finds that and does nothing. One audit entry says what it did.
 * Returns the teams changed, or null when it had run before.
 */
export async function turnOffOldReminderDefaults(now = new Date()): Promise<string[] | null> {
  if ((await migrations().get()).get('reminderDefaultsOff') != null) return null;
  const candidates = await db()
    .collection(Collections.groups)
    .where('createdAt', '<', Timestamp.fromDate(REMINDERS_OFF_BEFORE))
    .get();
  const teams = candidates.docs.filter(
    (d) =>
      d.get('kind') !== 'direct' &&
      d.get('archivedAt') == null &&
      d.get('deletingAt') == null &&
      isOldDefault(d.get('settings.defaultReminderOffsets')),
  );
  const changed = teams.map((d) => d.id);
  // The marker first, in a transaction, so two runs at once can't both go
  // on; the teams after, each set only while it's still on the old default.
  const claimed = await db().runTransaction(async (tx) => {
    const snap = await tx.get(migrations());
    if (snap.get('reminderDefaultsOff') != null) return false;
    tx.set(
      migrations(),
      { reminderDefaultsOff: { ranAt: Timestamp.fromDate(now), count: changed.length, teamIds: changed } },
      { merge: true },
    );
    return true;
  });
  if (!claimed) return null;
  for (let i = 0; i < teams.length; i += 400) {
    const batch = db().batch();
    for (const d of teams.slice(i, i + 400)) {
      batch.update(d.ref, { 'settings.defaultReminderOffsets': [], updatedAt: FieldValue.serverTimestamp() });
    }
    await batch.commit();
  }
  await audit({
    actorId: SYSTEM_ACTOR,
    action: 'reminderDefaultsOff',
    targetType: 'platform',
    targetId: 'reminderDefaultsOff',
    after: {
      teams: changed.length,
      note:
        `Reminders turned off by default for ${changed.length} ${changed.length === 1 ? 'team' : 'teams'} ` +
        'made before Nov 1 (#48). Events already made keep theirs.',
    },
  });
  logger.info('reminder_defaults_off', { teams: changed.length });
  return changed;
}

/**
 * Puts back the reminder the day before on the teams #48 changed, where
 * they're still on No reminders, in case it ever needs undoing
 * (`tools/undo_reminder_defaults.sh`). Teams whose admins chose something
 * since are left as they are. Returns the teams put back.
 */
export async function undoReminderDefaultsOff(now = new Date()): Promise<string[]> {
  const ids = ((await migrations().get()).get('reminderDefaultsOff.teamIds') as string[] | undefined) ?? [];
  const back: string[] = [];
  for (const id of ids) {
    const ref = db().collection(Collections.groups).doc(id);
    const snap = await ref.get();
    const offsets = snap.get('settings.defaultReminderOffsets');
    if (!snap.exists || !Array.isArray(offsets) || offsets.length !== 0) continue;
    await ref.update({ 'settings.defaultReminderOffsets': OLD_DEFAULT, updatedAt: FieldValue.serverTimestamp() });
    back.push(id);
  }
  await migrations().set({ reminderDefaultsOffUndone: { at: Timestamp.fromDate(now), teamIds: back } }, { merge: true });
  logger.info('reminder_defaults_off_undone', { teams: back.length });
  return back;
}
