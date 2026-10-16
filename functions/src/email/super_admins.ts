// Email to the people who run Battleplan, the super admins: report alerts
// (SAFE-4) and the platform alerts for new accounts and teams (ADMIN-9).
import { logger } from 'firebase-functions/v2';
import { HttpsError } from 'firebase-functions/v2/https';
import { auth, db } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { sendEmail, type Email } from './service.js';

/**
 * The super admins who hold the claim in Auth now and aren't disabled, by
 * their sign-in email. users.superAdmin only finds the candidates, as in
 * wouldLeaveNoSuperAdmin, so a stale flag never gets mail.
 */
export async function superAdminEmails(): Promise<string[]> {
  const flagged = await db()
    .collection(Collections.users)
    .where('superAdmin', '==', true)
    .select()
    .limit(Limits.queryLimitMax)
    .get();
  const emails: string[] = [];
  const ids = flagged.docs.map((d) => d.id);
  for (let i = 0; i < ids.length; i += 100) {
    const result = await auth().getUsers(ids.slice(i, i + 100).map((uid) => ({ uid })));
    for (const u of result.users) {
      if (u.customClaims?.superAdmin === true && !u.disabled && u.email) emails.push(u.email);
    }
  }
  return emails;
}

/**
 * Sends [make]'s email to every super admin. At most 50 alerts a day go
 * out, all kinds together (SAFE-5), so a flood of sign-ups or reports can't
 * use up the day's email for setup links and invites; past that they're
 * logged, and the daily report reminder still goes. Never throws: a failed
 * alert mustn't fail what it's about, so it's logged instead.
 */
export async function emailSuperAdmins(what: string, make: (to: string) => Email): Promise<void> {
  try {
    await consumeRateLimit('platform', 'superAdminEmail', Limits.superAdminEmailsPerDay);
  } catch (e) {
    if (e instanceof HttpsError && e.code === 'resource-exhausted') {
      logger.warn('super_admin_emails_capped', { what });
    } else {
      logger.error('super_admin_email_failed', { what, error: String(e) });
    }
    return;
  }
  try {
    for (const to of await superAdminEmails()) await sendEmail(make(to));
  } catch (e) {
    logger.error('super_admin_email_failed', { what, error: String(e) });
  }
}
