import { describe, expect, it } from 'vitest';
import {
  joinNames,
  parsePastedRoster,
  playerLabel,
  playerStatusOf,
  playerSummaryOf,
  relationOf,
} from '../../src/players/roster.js';
import { approvedBody, claimBody, pendingPlayerBody } from '../../src/players/handlers.js';

describe('parsePastedRoster (PLAYER-1)', () => {
  it('merges lines for the same player into one with several guardians', () => {
    const { players, problems } = parsePastedRoster(
      'Emma Rodriguez, Maria Rodriguez, maria@example.com\n' +
        'emma rodriguez, Luis Rodriguez, luis@example.com\n' +
        '\n' +
        'Arjun Shah, Priya Shah, priya@example.com\n' +
        'Noah Bennett\n',
    );
    expect(problems).toEqual([]);
    expect(players.map((p) => p.name)).toEqual(['Emma Rodriguez', 'Arjun Shah', 'Noah Bennett']);
    expect(players[0].guardians.map((g) => g.email)).toEqual(['maria@example.com', 'luis@example.com']);
    expect(players[2].guardians).toEqual([]);
  });

  it('reports bad emails and a fifth guardian', () => {
    const lines = ['Kid, A, a@x.com', 'Kid, B, b@x.com', 'Kid, C, c@x.com', 'Kid, D, d@x.com', 'Kid, E, e@x.com', 'Other, F, not-an-email'];
    const { players, problems } = parsePastedRoster(lines.join('\n'));
    expect(players[0].guardians).toHaveLength(4);
    expect(problems).toEqual(['Kid, E, e@x.com', 'Other, F, not-an-email']);
  });

  it('labels players by first name and number', () => {
    expect(playerLabel('Emma Rodriguez', '7')).toBe('Emma #7');
    expect(playerLabel('Noah Bennett', null)).toBe('Noah');
  });
});

describe('joinNames (NOTIF-5)', () => {
  it('lists players the way a sentence would', () => {
    expect(joinNames([])).toBe('');
    expect(joinNames(['Emma'])).toBe('Emma');
    expect(joinNames(['Emma', 'Liam'])).toBe('Emma and Liam');
    expect(joinNames(['Emma', 'Liam', 'Ava'])).toBe('Emma, Liam, and Ava');
  });
});

describe('player links and pending players (PLAYER-3, PLAYER-4)', () => {
  it('reads a missing relation as a guardian, and a missing status as active', () => {
    expect(relationOf({})).toBe('guardian');
    expect(relationOf(undefined)).toBe('guardian');
    expect(relationOf({ relation: 'self' })).toBe('self');
    expect(relationOf({ relation: 'bogus' })).toBe('guardian');
    expect(playerStatusOf({})).toBe('active');
    expect(playerStatusOf({ status: 'pending' })).toBe('pending');
  });

  it("builds Who's who: a guardian's players, a player's own number (PLAYER-8)", () => {
    expect(
      playerSummaryOf([
        { relation: 'guardian', name: 'Liam Rodriguez', jerseyNumber: '23' },
        { relation: 'guardian', name: 'Emma Rodriguez', jerseyNumber: '7' },
      ]),
    ).toBe('Emma #7, Liam #23');
    expect(playerSummaryOf([{ relation: 'self', name: 'Jared Freeman', jerseyNumber: '12' }])).toBe('#12');
    expect(playerSummaryOf([{ relation: 'self', name: 'Jared Freeman', jerseyNumber: null }])).toBeNull();
    expect(playerSummaryOf([])).toBeNull();
    expect(
      playerSummaryOf([
        { relation: 'guardian', name: 'Ava Freeman', jerseyNumber: null },
        { relation: 'self', name: 'Jared Freeman', jerseyNumber: '12' },
      ]),
    ).toBe('#12, Ava');
  });

  it('words claims, pending players, and approvals for admins and members (NOTIF-2)', () => {
    expect(claimBody('Maria R.', 'Emma', 'guardian')).toBe("Maria R. asked to be Emma's guardian");
    expect(claimBody('Jared F.', 'Jared Freeman', 'self')).toBe('Jared F. asked to be linked as the player Jared Freeman');
    expect(pendingPlayerBody('Maria R.', 'Emma', 'guardian')).toBe('Maria R. asked to add a player: Emma');
    expect(pendingPlayerBody('Jared F.', 'Jared Freeman', 'self')).toBe('Jared F. asked to join the roster as Jared Freeman');
    expect(approvedBody('Emma', 'guardian', false)).toBe("You're now Emma's guardian");
    expect(approvedBody('Emma', 'guardian', true)).toBe('Emma was added to the roster');
    expect(approvedBody('Jared Freeman', 'self', true)).toBe("You're now on the roster as Jared Freeman");
    expect(approvedBody('Jared Freeman', 'self', false)).toBe("You're now on the roster as Jared Freeman");
  });
});
