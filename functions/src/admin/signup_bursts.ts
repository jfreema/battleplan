// Sign-up spikes (ADMIN-9, #52): one email to every super admin when 10 or
// more people finish first-run setup within an hour, then none for 6 hours,
// however many more arrive. Accounts an admin added (TEAM-7 adds up to 100
// at once) and likely Google Play test accounts don't count. It always
// sends, like report alerts (SAFE-4), whatever Platform settings say about
// new-account emails: it's a safety alert, and rare. App Check (SAFE-5) is
// what stops bots; this only says when something looks unusual.
//
// The count lives in ops/signupBursts, which only Functions read or write:
// the last hour's sign-ups (uid and when, nothing more) and when the last
// spike email went. Names and emails are read from users/{uid} when an
// email goes out.
import { logger } from 'firebase-functions/v2';
import { likelyPlayTestAccount } from '../accounts/play_test.js';
import { emailSuperAdmins } from '../email/super_admins.js';
import { SPIKE_NAMES_SHOWN, signupSpikeEmail } from '../email/templates.js';
import { appUrl } from '../links/service.js';
import { auth, db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';

/** Sign-ups within [SPIKE_WINDOW_MS] that make a spike. */
export const SPIKE_SIGNUPS = 10;
export const SPIKE_WINDOW_MS = 60 * 60 * 1000;

/** No second spike email for this long after one. */
export const SPIKE_QUIET_MS = 6 * 60 * 60 * 1000;

/** The most sign-ups the counter keeps, so a flood can't grow it past a document's size. */
const KEEP = 500;

type Recent = { uid: string; at: number };

/** ops/signupBursts. */
const counter = () => db().collection(Collections.ops).doc('signupBursts');

/**
 * Counts a finished first-run setup ([now] in ms) and, when it makes a
 * spike, emails super admins. Never throws: a failure is logged, and the
 * sign-up it's about goes on.
 */
export async function noteSignUp(
  account: { uid: string; email: string; addedByAdmin: boolean },
  now: number = Date.now(),
): Promise<void> {
  if (account.addedByAdmin || likelyPlayTestAccount(account.email)) return;
  let spike: Recent[] | null = null;
  try {
    spike = await db().runTransaction(async (tx) => {
      const snap = await tx.get(counter());
      const since = now - SPIKE_WINDOW_MS;
      const recent = ((snap.get('recent') as Recent[] | undefined) ?? [])
        .filter((r) => r.at > since && r.uid !== account.uid)
        .concat({ uid: account.uid, at: now })
        .slice(-KEEP);
      const alertedAt = snap.get('alertedAt') as number | undefined;
      const due = recent.length >= SPIKE_SIGNUPS && (alertedAt === undefined || now - alertedAt >= SPIKE_QUIET_MS);
      tx.set(counter(), { recent, ...(due ? { alertedAt: now } : {}) }, { merge: true });
      return due ? recent : null;
    });
  } catch (e) {
    logger.error('signup_spike_count_failed', { error: String(e) });
    return;
  }
  if (!spike) return;
  logger.warn('signup_spike', { count: spike.length });
  try {
    const people = await namesOf(spike.slice(-SPIKE_NAMES_SHOWN).reverse());
    // The Users page opens on the newest accounts first.
    await emailSuperAdmins('signupSpike', (to) =>
      signupSpikeEmail(to, { count: spike.length, people }, appUrl('/admin/users')),
    );
  } catch (e) {
    logger.error('signup_spike_email_failed', { error: String(e) });
  }
}

/** Each sign-up's name, from their profile, and email, from Auth. */
async function namesOf(recent: Recent[]): Promise<{ name: string; email: string }[]> {
  const snaps = await db().getAll(...recent.map((r) => db().collection(Collections.users).doc(r.uid)));
  const found = await auth().getUsers(recent.map((r) => ({ uid: r.uid })));
  const emails = new Map(found.users.map((u) => [u.uid, u.email ?? '']));
  return recent.map((r, i) => ({
    name: (snaps[i]?.get('displayName') as string | undefined) || 'Someone',
    email: emails.get(r.uid) ?? '',
  }));
}
