// The one daily email budget (ARCH §6.7, #47): every email counts toward
// one total for the day, so no single kind of email, or one coach's
// roster, can use up the plan's day for everyone else.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { projectId } from '../shared/project.js';

/** What an email is about, which decides its tier. */
export type EmailKind =
  | 'setup'
  | 'accountSetup'
  | 'passwordReset'
  | 'securityNotice'
  | 'superAdminAlert'
  | 'invite'
  | 'addedToTeam'
  | 'rsvpReminder';

/**
 * Essential emails let people in or keep them safe: setup links, password
 * resets, security notices, and super admins' alerts; they may use the
 * whole budget. Bulk emails (invites, "added to team" notes, RSVP emails)
 * stop at [Limits.emailBulkPercent] of it, so the rest is always there for
 * the essential ones.
 */
export type EmailTier = 'essential' | 'bulk';

export function emailTier(kind: EmailKind): EmailTier {
  return kind === 'invite' || kind === 'addedToTeam' || kind === 'rsvpReminder' ? 'bulk' : 'essential';
}

/** How many bulk emails a day of [budget] allows: 63 of 90. */
export function bulkLimitOf(budget: number): number {
  return Math.floor((budget * Limits.emailBulkPercent) / 100);
}

/** The most emails [tier] may use of a day's [budget]. */
export function tierLimit(tier: EmailTier, budget: number): number {
  return tier === 'bulk' ? bulkLimitOf(budget) : budget;
}

/**
 * The counter for [now]'s day, which runs on UTC as the email provider's
 * does: `rateLimits/emailBudget_2026-11-19`, server only, gone after the
 * rateLimits TTL.
 */
export function emailBudgetDocId(now = new Date()): string {
  return `emailBudget_${now.toISOString().slice(0, 10)}`;
}

const counterRef = (now = new Date()) => db().collection(Collections.rateLimits).doc(emailBudgetDocId(now));

/** This project's default: 90 in prod and 10 in dev, which share the plan's 100. */
export function defaultEmailBudget(project = projectId()): number {
  return project === 'battleplan-prod' ? Limits.emailsPerDayProd : Limits.emailsPerDayDev;
}

/**
 * The day's budget: Platform settings' "Emails a day" (config/app
 * `emailsPerDay`, ADMIN-7), or this project's default when it isn't set.
 */
export async function dailyEmailBudget(): Promise<number> {
  const set = (await db().collection(Collections.config).doc('app').get()).get('emailsPerDay');
  return typeof set === 'number' && Number.isInteger(set) && set >= 1 && set <= Limits.emailsPerDayMax
    ? set
    : defaultEmailBudget();
}

/**
 * Takes one slot of the day's budget for a [kind] email, in a transaction:
 * false, counting nothing, when its tier has no room left. A slot is used on
 * the try, sent or not, as the provider counts.
 */
export async function takeEmailSlot(kind: EmailKind, now = new Date()): Promise<boolean> {
  const limit = tierLimit(emailTier(kind), await dailyEmailBudget());
  const ref = counterRef(now);
  return db().runTransaction(async (tx) => {
    const used = ((await tx.get(ref)).get('count') as number | undefined) ?? 0;
    if (used + 1 > limit) return false;
    tx.set(
      ref,
      {
        count: FieldValue.increment(1),
        expiresAt: Timestamp.fromMillis(now.getTime() + Limits.rateLimitTtlDays * 86_400_000),
      },
      { merge: true },
    );
    return true;
  });
}

/** Today's emails so far, the budget, and where bulk emails stop: the Dashboard's card. */
export async function emailsToday(now = new Date()): Promise<{ sent: number; budget: number; bulkLimit: number }> {
  const [budget, counter] = await Promise.all([dailyEmailBudget(), counterRef(now).get()]);
  return { sent: (counter.get('count') as number | undefined) ?? 0, budget, bulkLimit: bulkLimitOf(budget) };
}

/** How many more emails of [tier] fit today. */
export async function emailRoom(tier: EmailTier, now = new Date()): Promise<number> {
  const { sent, budget } = await emailsToday(now);
  return Math.max(0, tierLimit(tier, budget) - sent);
}
