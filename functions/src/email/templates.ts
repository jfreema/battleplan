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

/** Readable names for sign-in methods. */
export function methodName(id: string): string {
  return ({ 'google.com': 'Google', 'apple.com': 'Apple', password: 'Password' } as Record<string, string>)[id] ?? id;
}

