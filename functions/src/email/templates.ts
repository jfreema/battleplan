// The emails Battleplan sends from Functions (ARCH §6.7).
import { layout, type Email } from './service.js';

/** AUTH-6: an admin added someone who has no account yet. */
export function setupEmail(to: string, teamName: string, addedBy: string, link: string): Email {
  return {
    to,
    subject: `${addedBy} added you to ${teamName} on Battleplan`,
    ...layout(
      [
        `${addedBy} added you to ${teamName} on Battleplan, the app your team uses for chat, schedules, and RSVPs.`,
        'Tap the button to set up your account. You can sign in with Google, Apple, or a password after that. The link works once and expires soon; ask your team admin for a new one if it does.',
      ],
      { label: 'Set up my account', url: link },
    ),
  };
}

/** ADMIN-4: a super admin set up an account for someone, without a team. */
export function accountSetupEmail(to: string, addedBy: string, link: string): Email {
  return {
    to,
    subject: `${addedBy} set up a Battleplan account for you`,
    ...layout(
      [
        `${addedBy} set up a Battleplan account for you. Battleplan is the app teams use for chat, schedules, and RSVPs.`,
        'Tap the button to finish setting it up. You can sign in with Google, Apple, or a password after that. The link works once and expires soon.',
      ],
      { label: 'Set up my account', url: link },
    ),
  };
}

/**
 * ADMIN-4, AUTH-6: a super admin sent a password reset. The link lets the
 * person choose a new password themselves; nobody else ever sees or sets it.
 */
export function passwordResetEmail(to: string, link: string): Email {
  return {
    to,
    subject: 'Reset your Battleplan password',
    ...layout(
      [
        'Battleplan support sent you a link to choose a new password.',
        "If you sign in with Google or Apple, you don't need a password. If you didn't ask for this, you can ignore this email.",
      ],
      { label: 'Choose a new password', url: link },
    ),
  };
}

/** TEAM-7: someone with an account was added to a team. */
export function addedToTeamEmail(to: string, teamName: string, addedBy: string, url: string): Email {
  return {
    to,
    subject: `You're on ${teamName} on Battleplan`,
    ...layout([`${addedBy} added you to ${teamName}.`], { label: `Open ${teamName}`, url }),
  };
}

/** INV-4: an email invite with a single-use link. */
export function inviteEmail(to: string, teamName: string, invitedBy: string, url: string, note?: string): Email {
  return {
    to,
    subject: `${invitedBy} invited you to join ${teamName} on Battleplan`,
    ...layout(
      [
        `${invitedBy} invited you to join ${teamName} on Battleplan.`,
        ...(note ? [`"${note}"`] : []),
        'This link works once and expires in 14 days.',
      ],
      { label: `Join ${teamName}`, url },
    ),
  };
}

/** AUTH-7: a sign-in method was added or removed. */
export function securityNoticeEmail(to: string, change: string): Email {
  return {
    to,
    subject: 'A change to how you sign in to Battleplan',
    ...layout([change, "If this wasn't you, contact support@getbattleplan.app right away."]),
  };
}

/**
 * SAFE-4: someone filed a report, for every super admin. It names the team,
 * what was reported, and why, but never who reported it or what was said.
 */
export function reportAlertEmail(
  to: string,
  report: { teamName: string; what: string; reason: string; teamVisible: boolean },
  url: string,
): Email {
  return {
    to,
    subject: `New report on ${report.teamName}: ${report.what}`,
    ...layout(
      [
        `Someone on ${report.teamName} reported ${report.what} (${report.reason}).`,
        report.teamVisible
          ? "The team's admins can act on it too."
          : "It's about one of the team's admins, so only super admins see it.",
        'Battleplan promises to act on every report within 24 hours.',
      ],
      { label: 'Open reports', url },
    ),
  };
}

/** SAFE-4: the daily reminder of reports still open after 12 hours. */
export function openReportsEmail(to: string, count: number, oldestHours: number, url: string): Email {
  const reports = count === 1 ? '1 report is' : `${count} reports are`;
  return {
    to,
    subject: `${reports} waiting on Battleplan`,
    ...layout(
      [
        `${reports} still open; the oldest was filed ${oldestHours} hours ago.`,
        'Battleplan promises to act on every report within 24 hours.',
      ],
      { label: 'Open reports', url },
    ),
  };
}

/** Readable names for sign-in methods. */
export function methodName(id: string): string {
  return ({ 'google.com': 'Google', 'apple.com': 'Apple', password: 'Password' } as Record<string, string>)[id] ?? id;
}

