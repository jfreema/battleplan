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

/**
 * #45: the phone and email members shared with a team (TEAM-10) move from
 * their membership, which everyone on the team can read, to
 * `memberContacts` under the same ID, which the rules show only to the
 * people the roster shows that person to. Each membership with either old
 * field gets a record (unless it already has one, saved since by a newer
 * app, which wins) and loses the old fields, in one batch, so nobody's
 * contact is ever in neither place. It runs once, recorded in
 * `ops/migrations.sharedContactsMoved`; one audit entry says how many
 * moved. Returns how many memberships it changed, or null when it had
 * run before.
 */
export async function moveSharedContacts(now = new Date()): Promise<number | null> {
  if ((await migrations().get()).get('sharedContactsMoved') != null) return null;
  const claimed = await db().runTransaction(async (tx) => {
    const snap = await tx.get(migrations());
    if (snap.get('sharedContactsMoved') != null) return false;
    tx.set(migrations(), { sharedContactsMoved: { startedAt: Timestamp.fromDate(now) } }, { merge: true });
    return true;
  });
  if (!claimed) return null;
  // Memberships with either field, each once.
  const members = db().collection(Collections.groupMembers);
  const [phones, emails] = await Promise.all([
    members.where('contactPhone', '!=', null).get(),
    members.where('contactEmail', '!=', null).get(),
  ]);
  const docs = new Map([...phones.docs, ...emails.docs].map((d) => [d.id, d]));
  const all = [...docs.values()];
  const text = (v: unknown) => (typeof v === 'string' && v.trim() ? v.trim() : null);
  for (let i = 0; i < all.length; i += 200) {
    const part = all.slice(i, i + 200);
    const contacts = part.map((d) => db().collection(Collections.memberContacts).doc(d.id));
    const existing = await db().getAll(...contacts);
    const batch = db().batch();
    part.forEach((d, j) => {
      const phone = text(d.get('contactPhone'));
      const email = text(d.get('contactEmail'));
      if (!existing[j].exists && (phone || email)) {
        batch.set(contacts[j], {
          groupId: d.get('groupId'),
          uid: d.get('uid'),
          phone,
          email,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
      batch.update(d.ref, { contactPhone: FieldValue.delete(), contactEmail: FieldValue.delete() });
    });
    await batch.commit();
  }
  await migrations().set(
    { sharedContactsMoved: { ranAt: Timestamp.fromDate(now), count: all.length } },
    { merge: true },
  );
  await audit({
    actorId: SYSTEM_ACTOR,
    action: 'sharedContactsMoved',
    targetType: 'platform',
    targetId: 'sharedContactsMoved',
    after: {
      members: all.length,
      note:
        `Shared phone numbers and emails moved to private records for ${all.length} ` +
        `${all.length === 1 ? 'membership' : 'memberships'} (#45), so a hidden roster hides them too.`,
    },
  });
  logger.info('shared_contacts_moved', { members: all.length });
  return all.length;
}
