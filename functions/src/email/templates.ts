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
  report: { teamName: string; what: string; reason: string; teamVisible: boolean; direct?: boolean },
  url: string,
): Email {
  // A direct conversation (CHAT-19) has no team or admins: only super admins act.
  if (report.direct) {
    return {
      to,
      subject: `New report in a direct message: ${report.what}`,
      ...layout(
        [
          `Someone reported ${report.what} in a direct message (${report.reason}).`,
          'Direct messages have no team admins, so only super admins see it.',
          'Battleplan promises to act on every report within 24 hours.',
        ],
        { label: 'Open reports', url },
      ),
    };
  }
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

/** "a soccer team", "an other team" never: just "a team". */
function aTeam(sport: string): string {
  if (!sport || sport === 'other') return 'a team';
  return `${/^[aeiou]/i.test(sport) ? 'an' : 'a'} ${sport} team`;
}

/** ADMIN-9: someone finished signing up, for every super admin. */
export function newAccountEmail(
  to: string,
  account: { name: string; email: string; methods: string[]; addedByAdmin: boolean },
  url: string,
): Email {
  const how = account.methods.length ? `, with ${account.methods.join(' and ')}` : '';
  return {
    to,
    subject: `New account: ${account.name}`,
    ...layout(
      [
        `${account.name} (${account.email}) finished signing up for Battleplan${how}.`,
        ...(account.addedByAdmin ? ['A team admin added them first.'] : []),
      ],
      { label: 'Open in the admin panel', url },
    ),
  };
}

/** ADMIN-9: someone created a team, for every super admin. */
export function teamCreatedEmail(
  to: string,
  team: { name: string; sport: string; ownerName: string; ownerEmail: string },
  url: string,
): Email {
  const owner = team.ownerEmail ? `${team.ownerName} (${team.ownerEmail})` : team.ownerName;
  return {
    to,
    subject: `New team: ${team.name}`,
    ...layout([`${owner} created ${team.name}, ${aTeam(team.sport)}.`], { label: 'Open in the admin panel', url }),
  };
}

/** ADMIN-9: a team was deleted, for every super admin. */
export function teamDeletedEmail(
  to: string,
  team: { name: string; memberCount: number; actorName: string; bySuperAdmin: boolean },
  url: string,
): Email {
  const members = team.memberCount === 1 ? '1 member' : `${team.memberCount} members`;
  const who = team.bySuperAdmin ? `${team.actorName}, a super admin,` : team.actorName;
  return {
    to,
    subject: `Team deleted: ${team.name}`,
    ...layout([`${who} deleted ${team.name}, which had ${members}. Everything in it is gone.`], {
      label: 'Open the audit log',
      url,
    }),
  };
}

/** Readable names for sign-in methods. */
export function methodName(id: string): string {
  return ({ 'google.com': 'Google', 'apple.com': 'Apple', password: 'Password' } as Record<string, string>)[id] ?? id;
}

