// Alerts that keep the promise to act on every report within 24 hours
// (SAFE-4, store checklist 1.8): a team's admins can't see a report about
// one of them, and a team may have no admin watching, so super admins hear
// about every report.
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { currentSuperAdminEmails } from '../admin/service.js';
import { sendEmail } from '../email/service.js';
import { openReportsEmail, reportAlertEmail } from '../email/templates.js';
import { appUrl } from '../links/service.js';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import type { ReportTarget } from './service.js';

/** Reports open longer than this are in the daily reminder. */
export const REPORT_REMINDER_HOURS = 12;

const HOUR = 3_600_000;

/** "a message", "a person", or "a document". */
export function reportedThing(targetType: ReportTarget): string {
  return targetType === 'user' ? 'a person' : targetType === 'document' ? 'a document' : 'a message';
}

/**
 * Emails every super admin about a new report. Never throws: a failed
 * email mustn't fail the report, so it's logged instead.
 */
export async function alertSuperAdmins(report: {
  groupId: string;
  targetType: ReportTarget;
  reason: string;
  teamVisible: boolean;
}): Promise<void> {
  try {
    const team = await db().collection(Collections.groups).doc(report.groupId).get();
    const teamName = (team.get('name') as string | undefined) ?? 'a team';
    const details = { teamName, what: reportedThing(report.targetType), reason: report.reason, teamVisible: report.teamVisible };
    for (const to of await currentSuperAdminEmails()) {
      await sendEmail(reportAlertEmail(to, details, appUrl('/admin/reports')));
    }
  } catch (e) {
    logger.error('report_alert_failed', { groupId: report.groupId, error: String(e) });
  }
}

/**
 * Emails every super admin once a day while any report has been open more
 * than REPORT_REMINDER_HOURS. Returns how many such reports there are.
 */
export async function remindOpenReports(nowMs = Date.now()): Promise<number> {
  const waiting = await db()
    .collection(Collections.reports)
    .where('status', '==', 'open')
    .where('createdAt', '<=', Timestamp.fromMillis(nowMs - REPORT_REMINDER_HOURS * HOUR))
    .orderBy('createdAt', 'desc')
    .get();
  if (waiting.empty) return 0;
  const oldest = waiting.docs[waiting.size - 1].get('createdAt') as Timestamp;
  const hours = Math.floor((nowMs - oldest.toMillis()) / HOUR);
  for (const to of await currentSuperAdminEmails()) {
    await sendEmail(openReportsEmail(to, waiting.size, hours, appUrl('/admin/reports')));
  }
  return waiting.size;
}
