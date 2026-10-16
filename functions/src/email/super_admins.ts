// Email to the people who run Battleplan, the super admins: report alerts
// (SAFE-4) and the platform alerts for new accounts and teams (ADMIN-9).
import { logger } from 'firebase-functions/v2';
import { auth, db } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
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
 * Sends [make]'s email to every super admin. Never throws: a failed alert
 * mustn't fail what it's about, so it's logged instead.
 */
export async function emailSuperAdmins(what: string, make: (to: string) => Email): Promise<void> {
  try {
    for (const to of await superAdminEmails()) await sendEmail(make(to));
  } catch (e) {
    logger.error('super_admin_email_failed', { what, error: String(e) });
  }
}
