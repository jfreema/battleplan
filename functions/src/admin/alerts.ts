// Platform alerts (ADMIN-9): an email to every super admin when someone
// finishes signing up and when a team is created or deleted, while
// config/app's emailAdminAlerts is on, as it is unless a super admin turns
// it off in Platform settings. They never fail what they're about.
import { logger } from 'firebase-functions/v2';
import { emailSuperAdmins } from '../email/super_admins.js';
import { newAccountEmail, teamCreatedEmail, teamDeletedEmail } from '../email/templates.js';
import type { Email } from '../email/service.js';
import { appUrl } from '../links/service.js';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';

/** Whether super admins get these emails: on unless config/app turns them off. */
async function alertsOn(): Promise<boolean> {
  const config = await db().collection(Collections.config).doc('app').get();
  return config.get('emailAdminAlerts') !== false;
}

async function alert(what: string, make: (to: string) => Email): Promise<void> {
  try {
    if (!(await alertsOn())) return;
  } catch (e) {
    logger.error('admin_alert_failed', { what, error: String(e) });
    return;
  }
  await emailSuperAdmins(what, make);
}

/** How someone signed in, as the email says it: "with Google". */
const METHOD_NAMES: Record<string, string> = { 'google.com': 'Google', 'apple.com': 'Apple', password: 'email' };

/** Someone finished first-run setup (AUTH-5): a new account. */
export async function alertNewAccount(account: {
  uid: string;
  name: string;
  email: string;
  providerIds: string[];
  addedByAdmin: boolean;
}): Promise<void> {
  const methods = [...new Set(account.providerIds.map((p) => METHOD_NAMES[p]).filter(Boolean))];
  await alert('newAccount', (to) =>
    newAccountEmail(
      to,
      { name: account.name, email: account.email, methods, addedByAdmin: account.addedByAdmin },
      appUrl(`/admin/users/${account.uid}`),
    ),
  );
}

/** Someone created a team (TEAM-1). */
export async function alertTeamCreated(team: {
  groupId: string;
  name: string;
  sport: string;
  ownerName: string;
  ownerEmail: string;
}): Promise<void> {
  await alert('teamCreated', (to) => teamCreatedEmail(to, team, appUrl(`/admin/teams/${team.groupId}`)));
}

/** A team was deleted (TEAM-9, ADMIN-3), by its owner or a super admin. */
export async function alertTeamDeleted(team: {
  groupId: string;
  name: string;
  memberCount: number;
  actorUid: string;
  bySuperAdmin: boolean;
}): Promise<void> {
  const actor = await db()
    .collection(Collections.users)
    .doc(team.actorUid)
    .get()
    .catch(() => null);
  const actorName = (actor?.get('displayName') as string | undefined) || 'Someone';
  await alert('teamDeleted', (to) =>
    teamDeletedEmail(
      to,
      { name: team.name, memberCount: team.memberCount, actorName, bySuperAdmin: team.bySuperAdmin },
      appUrl(`/admin/audit?group=${team.groupId}`),
    ),
  );
}
